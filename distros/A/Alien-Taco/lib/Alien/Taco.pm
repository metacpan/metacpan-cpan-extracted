# Taco Perl client module.
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

Alien::Taco - Taco Perl client module

=head1 SYNOPSIS

    use Alien::Taco;

    my $taco = new Alien::Taco(lang => 'perl');
    $taco->call_function('CORE::sleep', args => [10]);

=head1 DESCRIPTION

This is the Taco client module for Perl.

=cut

package Alien::Taco;

use IPC::Open2;
use Scalar::Util qw/blessed/;

use Alien::Taco::Object;
use Alien::Taco::Transport;

use strict;

our $VERSION = '0.002';

=head1 METHODS

=head2 Constructor

=over 4

=item new(lang => 'language' | script => 'server_script')

Connect to a Taco server instance.  The server script can either
be specified explicitly, or the language can be given.  In that 
case the server script will be assumed to be named taco-I<language>
and installed in your executable search path (C<$PATH>).

The server script will be launched in a subprocess, and a
L<Alien::Taco::Transport> object will be attached to it.

=cut

sub new {
    my $class = shift;
    my %opts = @_;

    my $serv = undef;
    if (exists $opts{'script'}) {
        $serv = $opts{'script'};
    }
    elsif (exists $opts{'lang'}) {
        $serv = 'taco-' . $opts{'lang'};
    }
    else {
        die 'languange or script not specified';
    }

    my ($serv_in, $serv_out);
    my $pid = open2($serv_out, $serv_in, $serv);

    my $self = bless {}, $class;

    $self->{'xp'} = $self->_construct_transport($serv_out, $serv_in);

    return $self;
}

# _construct_transport()

sub _construct_transport {
    my $self = shift;
    my $in = shift;
    my $out = shift;

    return new Alien::Taco::Transport(
            in => $in,
            out => $out,
            filter_single => ['_Taco_Object_' =>  sub {
                return new Alien::Taco::Object($self, shift);
            }],
    );
}

# _interact(\%message)
#
# General interaction method.  This is the internal method used to
# implement the main Taco methods.
#
# The given message is filtered for objects and then sent using the
# Alien::Taco::Transport.  If the response is a result then it is
# returned.  If the response is an exception, then an exception is
# raised.

sub _interact {
    my $self = shift;
    my $message = shift;
    my $xp = $self->{'xp'};

    $xp->write($message);

    my $res = $xp->read();
    my $act = $res->{'action'};

    if ($act eq 'result') {
        return @{$res->{'result'}}
            if wantarray and 'ARRAY' eq ref $res->{'result'};

        return $res->{'result'};
    }
    elsif ($act eq 'exception') {
        die 'received exception: ' . $res->{'message'};
    }
    else {
        die 'received unknown action: ' . $act;
    }
}

=back

=head2 Taco Methods

The methods in this section allow the corresponding Taco actions to be sent.

=over 4

=item call_class_method('class_name', 'function_name',
      [args => \@args], [kwargs => \%kwargs])

Invoke a class method call within the Taco server script, returning the
result of that method. The context (void / scalar / list)
is detected and sent as a parameter.  Since Perl subroutine arguments
are expanded into a list, the I<arguments> and I<keyword arguments>
must be given separately.

=cut

sub call_class_method {
    my $self = shift;
    my $class = shift;
    my $name = shift;
    my %opts = @_;

    return $self->_interact({
        action => 'call_class_method',
        class => $class,
        name => $name,
        args => $opts{'args'},
        kwargs => $opts{'kwargs'},
        context => (defined wantarray ? (wantarray?'list':'scalar') : 'void'),
    });
}

=item call_function('function_name', [args => \@args], [kwargs => \%kwargs])

Invoke a function call within the Taco server script, returning the
result of that function. The context (void / scalar / list)
is detected and sent as a parameter.  Since Perl subroutine arguments
are expanded into a list, the I<arguments> and I<keyword arguments>
must be given separately.

=cut

sub call_function {
    my $self = shift;
    my $name = shift;
    my %opts = @_;

    return $self->_interact({
        action => 'call_function',
        name => $name,
        args => $opts{'args'},
        kwargs => $opts{'kwargs'},
        context => (defined wantarray ? (wantarray?'list':'scalar') : 'void'),
    });
}

# _call_method($number, 'method', [args => \@args], [kwargs => \%kwargs])
#
# Internal method invoked by Alien::Taco::Object instances.

sub _call_method {
    my $self = shift;
    my $number = shift;
    my $name = shift;
    my %opts = @_;

    return $self->_interact({
        action => 'call_method',
        number => $number,
        name => $name,
        args => $opts{'args'},
        kwargs => $opts{'kwargs'},
        context => (defined wantarray ? (wantarray?'list':'scalar') : 'void'),
    });
}

=item construct_object('class', [args => \@args], [kwargs => \%kwargs])

Invoke an object constructor.  If successful, this should return
an L<Alien::Taco::Object> instance which references the new object.
The given arguments are passed to the object constructor.

=cut

sub construct_object {
    my $self = shift;
    my $class = shift;
    my %opts = @_;

    return $self->_interact({
        action => 'construct_object',
        class => $class,
        args => $opts{'args'},
        kwargs => $opts{'kwargs'},
    });
}

# _destroy_object($number)
#
# Internal method invoked by Alien::Taco::Object instances.

sub _destroy_object {
    my $self = shift;
    my $number = shift;

    $self->_interact({
        action => 'destroy_object',
        number => $number,
    });
}

# _get_attribute($number, 'attribute_name')
#
# Internal method invoked by Alien::Taco::Object instances.

sub _get_attribute {
    my $self = shift;
    my $number = shift;
    my $name = shift;

    return $self->_interact({
        action => 'get_attribute',
        number => $number,
        name => $name,
    });
}

=item get_class_attribute('Class::Name', 'attribute_name')

Request the value of a static attribute of a class.

=cut

sub get_class_attribute {
    my $self = shift;
    my $class = shift;
    my $name = shift;

    return $self->_interact({
        action => 'get_class_attribute',
        class => $class,
        name => $name,
    });
}

=item get_value('variable_name')

Request the value of the given variable.

=cut

sub get_value {
    my $self = shift;
    my $name = shift;

    return $self->_interact({
        action => 'get_value',
        name => $name,
    });
}

=item import_module('Module::Name', [args => \@args], [kwargs => \%kwargs])

Instruct the server to load the specified module.  The interpretation
of the arguments depends on the language of the Taco server implementation.

=cut

sub import_module {
    my $self = shift;
    my $name = shift;
    my %opts = @_;

    $self->_interact({
        action => 'import_module',
        name => $name,
        args => $opts{'args'},
        kwargs => $opts{'kwargs'},
    });
}

# _set_attribute($number, 'attribute_name', $value)
#
# Internal method invoked by Alien::Taco::Object instances.

sub _set_attribute {
    my $self = shift;
    my $number = shift;
    my $name = shift;
    my $value = shift;

    $self->_interact({
        action => 'set_attribute',
        number => $number,
        name => $name,
        value => $value,
    });
}

=item set_class_attribute('Class::Name', 'attribute_name', $value)

Set the value of a static attribute of a class.

=cut

sub set_class_attribute {
    my $self = shift;
    my $class = shift;
    my $name = shift;
    my $value = shift;

    $self->_interact({
        action => 'set_class_attribute',
        class => $class,
        name => $name,
        value => $value,
    });
}

=item set_value('attribute_name', $value)

Set the value of the given variable.

=cut

sub set_value {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    $self->_interact({
        action => 'set_value',
        name => $name,
        value => $value,
    });
}

=back

=head2 Convenience Methods

The methods in this section additional methods for convenience.

=over 4

=item function('function_name')

Return a subroutine reference which calls the given function
with plain arguments only. The following example is equivalent
to that given in the L</SYNOPSIS>.

    my $sleep = $taco->function('CORE::sleep');
    $sleep->(10);

=cut

sub function {
    my $self = shift;
    my $name = shift;

    return sub {
        $self->call_function($name, args => \@_);
    };
}

=item constructor('ClassName')

Return a subroutine reference to call the constructor for the
specified class, with plain arguments.  For example, to
allow multiple L<DateTime> objects to be constructed easily,
a constructor can be used:

    my $datetime = $taco->constructor('DateTime');
    my $afd = $datetime->(year => 2000, month => 4, day => 1);

This is equivalent to calling the L</construct_object>
method:

    my $afd = $taco->construct_object('DateTime',
        kwargs => {year => 2000, month => 4, day => 1});

=cut

sub constructor {
    my $self = shift;
    my $class = shift;

    return sub {
        $self->construct_object($class, args => \@_);
    };
}

1;

__END__

=back

=cut
