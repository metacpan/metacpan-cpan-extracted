# Taco Perl server module.
# Copyright (C) 2013-2014 Graham Bell
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

Alien::Taco::Server - Taco Perl server module

=head1 SYNOPSIS

    use Alien::Taco::Server;
    my $server = new Alien::Taco::Server();
    $server->run();

=head1 DESCRIPTION

This module provides a Perl implementation of the actions
required of a Taco server.

=cut

package Alien::Taco::Server;

use Scalar::Util qw/blessed/;

use Alien::Taco::Transport;
use Alien::Taco::Util qw/filter_struct/;

use strict;

our $VERSION = '0.002';

=head1 SUBROUTINES

=head2 Main Methods

=over 4

=item new()

Set up a L<Alien::Taco::Transport> object communicating via
C<STDIN> and C<STDOUT>.

C<STDERR> is selected as the current stream to try to avoid
any subroutine or method calls printing to C<STDOUT> which would
corrupt communications with the client.

=cut

sub new {
    my $class = shift;

    # Create cache of objects held on the server side for which an
    # object number is passed to the client.

    my $self = bless {
        nobject => 0,
        objects => {},
    }, $class;

    # Select STDERR as current file handle so that if a function is
    # called which in turn prints something, it doesn't go into the
    # transport stream.
    select(STDERR);

    $self->{'xp'} = $self->_construct_transport(*STDIN, *STDOUT);

    return $self;
}

# _construct_transport
#
# Implements construction of the Alien::Taco::Transport object.

sub _construct_transport {
    my $self = shift;
    my $in = shift;
    my $out = shift;

    return new Alien::Taco::Transport(in => $in, out => $out,
            filter_single => ['_Taco_Object_' =>  sub {
                return $self->_get_object(shift);
            }],
    );
}

=item run()

Enter the message handling loop, which exits on failure to read from
the transport.

=cut

sub run {
    my $self = shift;
    my $xp = $self->{'xp'};

    while (1) {
        my $message = $xp->read();
        last unless defined $message;

        my $act = $message->{'action'};
        my $res = undef;

        if ($act !~ /^_/ and $self->can($act)) {
            $res = eval {$self->$act($message)};

            $res = {
                action => 'exception',
                message => 'exception caught: ' . $@,
            } unless defined $res;
        }
        else {
            $res = {
                action => 'exception',
                message => 'unknown action: ' . $act,
            };
        }

        $self->_replace_objects($res);
        $xp->write($res);
    }
}

# _get_param(\%message)
#
# Read subroutine / method parameters from a Taco message and
# return them as a list suitable for passing to Perl subroutines.

sub _get_param {
    my $message = shift;

    my @param = ();

    if (defined $message->{'args'}) {
        @param = @{$message->{'args'}};
    }

    if (defined $message->{'kwargs'}) {
        @param = (@param, %{$message->{'kwargs'}});
    }

    return @param;
}

# _make_result($value)
#
# Construct a Taco result message containing the given value.

sub _make_result {
    return  {
        action => 'result',
        result => shift,
    };
}

my $null_result = _make_result(undef);

# _replace_objects(\%message)
#
# Replace objects in the given message with Taco object number references.

sub _replace_objects {
    my $self = shift;
    filter_struct(shift, sub {
        my $x = shift;
        blessed($x) and not JSON::is_bool($x);
    },
    sub {
        my $nn = my $n = ++ $self->{'nobject'};
        $self->{'objects'}->{$nn} = shift;
        return {_Taco_Object_ => $n};
    });
}

# _delete_object($number)
#
# Delete an object from the cache.

sub _delete_object {
    my $self = shift;
    my $n = shift;
    delete $self->{'objects'}->{$n};
}

# _get_object($number)
#
# Fetch an object from the cache.

sub _get_object {
    my $self = shift;
    my $n = shift;
    return $self->{'objects'}->{$n};
}

=back

=head2 Taco Action Handlers

=over 4

=item call_class_method($message)

Call the class method specified in the message, similarly to
C<call_function>.

=cut

sub call_class_method {
    my $self = shift;
    my $message = shift;

    my $c = $message->{'class'};
    my $f = $message->{'name'};
    my @param = _get_param($message);

    my $result = undef;
    unless (defined $message->{'context'}
                and $message->{'context'} ne 'scalar') {
        $result = $c->$f(@param);
    }
    elsif ($message->{'context'} eq 'list') {
        my @result = $c->$f(@param);
        $result = \@result;
    }
    elsif ($message->{'context'} eq 'map') {
        my %result = $c->$f(@param);
        $result = \%result;
    }
    elsif ($message->{'context'} eq 'void') {
        $c->$f(@param);
    }
    else {
        die 'unknown context: ' . $message->{'context'};
    }

    return _make_result($result);
}



=item call_function($message)

Call the function specified in the message.  The function is called
in the requested context (void / scalar / list) if specified.  A
context of "map" can also be specified to avoid the client having
to convert a list to a hash in cases where the function returns
a hash directly.

The function is called with an argument list consisting of the
I<args> followed by the I<kwargs> in list form.  To supply a
hash reference to the function, a hash should be placed inside
one of the arguments paramters of the message.

=cut

sub call_function {
    my $self = shift;
    my $message = shift;

    my $f = \&{$message->{'name'}};
    my @param = _get_param($message);

    my $result = undef;
    unless (defined $message->{'context'}
                and $message->{'context'} ne 'scalar') {
        $result = $f->(@param);
    }
    elsif ($message->{'context'} eq 'list') {
        my @result = $f->(@param);
        $result = \@result;
    }
    elsif ($message->{'context'} eq 'map') {
        my %result = $f->(@param);
        $result = \%result;
    }
    elsif ($message->{'context'} eq 'void') {
        $f->(@param);
    }
    else {
        die 'unknown context: ' . $message->{'context'};
    }

    return _make_result($result);
}

=item call_method($message)

Call an object method, similarly to C<call_function>.

=cut

sub call_method {
    my $self = shift;
    my $message = shift;

    my $number = $message->{'number'};
    my $name = $message->{'name'};
    my @param = _get_param($message);

    my $object = $self->_get_object($number);

    my $result = undef;
    unless (defined $message->{'context'}
                and $message->{'context'} ne 'scalar') {
        $result = $object->$name(@param);
    }
    elsif ($message->{'context'} eq 'list') {
        my @result = $object->$name(@param);
        $result = \@result;
    }
    elsif ($message->{'context'} eq 'map') {
        my %result = $object->$name(@param);
        $result = \%result;
    }
    elsif ($message->{'context'} eq 'void') {
        $object->$name(@param);
    }
    else {
        die 'unknown context: ' . $message->{'context'};
    }

    return _make_result($result);
}

=item construct_object($message)

Call an object constructor.

=cut

sub construct_object {
    my $self = shift;
    my $message = shift;

    my $c = $message->{'class'};
    my @param = _get_param($message);

    return _make_result($c->new(@param));
}

=item destroy_object($message)

Remove an object from the cache.

=cut

sub destroy_object {
    my $self = shift;
    my $message = shift;

    my $n = $message->{'number'};
    $self->_delete_object($n);

    return $null_result;
}

=item get_attribute($message)

Attempt to read an object attribute, but this depends on the object
being a blessed HASH reference.  If so then the named HASH entry
is returned.  Typically, however, Perl object values will be
accessed by calling the corresponding method on the object instead.

=cut

sub get_attribute {
    my $self = shift;
    my $message = shift;

    my $number = $message->{'number'};
    my $name = $message->{'name'};

    my $object = $self->_get_object($number);

    die 'object is not a hash' unless $object->isa('HASH');

    return _make_result($object->{$name});
}

=item get_class_attribute($message)

Attempt the read a variable from the given class's package.
The attribute name should begin with the appropriate sigil
(C<$> / C<@> / C<%>).

=cut

sub get_class_attribute {
    my $self = shift;
    my $message = shift;

    my $name = $message->{'name'};

    # Construct full name from sigil + class + '::' + attribute.
    return $self->_get_attr_or_value(
        substr($name, 0, 1) . $message->{'class'} . '::' . substr($name, 1));
}

=item get_value($message)

Try to read the given variable.  The variable name should begin
with the appropriate sigil (C<$> / C<@> / C<%>).

=cut

sub get_value {
    my $self = shift;
    my $message = shift;

    return $self->_get_attr_or_value($message->{'name'});
}

# _get_attr_or_value($name)
#
# Internal method to get a value based on its sigil.

sub _get_attr_or_value {
    my $self = shift;
    my $name = shift;

    no strict 'refs';
    if ($name =~ s/^\$//) {
        return _make_result($$name);
    }
    elsif ($name =~ s/^\@//) {
        return _make_result(\@{$name});
    }
    elsif ($name =~ s/^\%//) {
        return _make_result(\%{$name});
    }
    else {
        die 'unknown sigil';
    }
}

=item import_module($message)

Convert the supplied module name to a path by replacing C<::> with C</>
and appending C<.pm>.  Then require the resulting module file and
call its C<import> subroutine.  Any parameters provided are passed
to C<import>.

=cut

sub import_module {
    my $self = shift;
    my $message = shift;
    my @param = _get_param($message);

    my $m = $message->{'name'};
    my $f = $m; $f =~ s/::/\//g;

    require $f . '.pm';
    $m->import(@param);

    return $null_result;
}

=item set_attribute($message)

Attempt to set an attribute of an object, but see the notes for
C<get_attribute> above.

=cut

sub set_attribute {
    my $self = shift;
    my $message = shift;

    my $number = $message->{'number'};
    my $name = $message->{'name'};
    my $value = $message->{'value'};

    my $object = $self->_get_object($number);

    die 'object is not a hash' unless $object->isa('HASH');

    $object->{$name} = $value;

    return $null_result;
}

=item set_class_attribute($message)

Attempt to set a variable in the given class's package.
The attribute name should begin with the appropriate sigil
(C<$> / C<@> / C<%>).

=cut

sub set_class_attribute {
    my $self = shift;
    my $message = shift;

    my $name = $message->{'name'};

    # Construct full name from sigil + class + '::' + attribute.
    $self->_set_attr_or_value(
        substr($name, 0, 1) . $message->{'class'} . '::' . substr($name, 1),
        $message->{'value'});

    return $null_result;
}

=item set_value($message)

Assign to the given variable.  The variable name should begin
with the appropriate sigil (C<$> / C<@> / C<%>).

=cut

sub set_value {
    my $self = shift;
    my $message = shift;

    $self->_set_attr_or_value($message->{'name'}, $message->{'value'});

    return $null_result;
}

# _set_attr_or_value($name, $value)
#
# Internal method to set a value based on its sigil.

sub _set_attr_or_value {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    no strict 'refs';
    if ($name =~ s/^\$//) {
        $$name = $value;
    }
    elsif ($name =~ s/^\@//) {
        @$name = @$value;
    }
    elsif ($name =~ s/^\%//) {
        %{$name} = %$value;
    }
    else {
        die 'unknown sigil';
    }
}

1;

=back

=cut
