package Config::Maker::Option;

use utf8;
use warnings;
use strict;

use Carp;

use Config::Maker;
use Config::Maker::Type;
use Config::Maker::Path;

use overload
    'cmp' => \&Config::Maker::truecmp,
    '<=>' => \&Config::Maker::truecmp,
    '""' => sub { $_[0]->{-value}; },
    '/' => sub { 
	croak "Can't \"divide by\" option" if $_[2];
	$_[0]->get($_[1]);
    },
    '&{}' => sub {
	my $self = $_[0];
	sub { $self->get(@_); };
    },
    fallback => 1;

sub _ref(\%$;$) {
    my ($hash, $key, $default) = @_;
    if(exists $hash->{$key}) {
	my $rv = $hash->{$key};
	delete $hash->{$key};
	return $rv;
    } elsif(@_ == 3) {
	return $default;
    } else {
	croak "Mandatory argument $key not specified";
    }
}

sub _flatten {
    map {
	ref($_) eq 'ARRAY' ?
	    _flatten(@$_) :
	    $_;
    } @_;
}

sub new {
    my ($class, %args) = @_;
    my $type = _ref(%args, '-type');

    my $self = {
	-type => $type,
	-value => _ref(%args, '-value', ''),
	-children => _ref(%args, '-children', []),
    };
    croak "Unknown arguments: " . join(', ', keys %args)
	if %args;
    bless $self, $class;

    $self->{-children} = [_flatten(@{$self->{-children}})];

    foreach my $child (@{$self->{-children}}) {
	$child->{-parent} = $self;
    }

    foreach my $check (@{$type->{checks}}) {
	&$check($self);
    }

    foreach my $action (@{$type->{actions}}) {
	&$action($self);
    }

    DBG("Instantiated $type");
    $self;
}

sub get {
    my ($self, $path) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    return wantarray ? @$res : $res->[0];
}

sub get1 {
    my ($self, $path) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    Carp::croak "$path should have exactly one result" if $#$res;
    return $res->[0];
}

sub getval {
    my ($self, $path, $default) = @_;
    $path = Config::Maker::Path->make($path);
    my $res = $path->find($self);
    Carp::croak "$path should have at most one result" if @$res > 1;
    @$res ? $res->[0]->{-value} : $default;
}

sub type {
    $_[0]->{-type};
}

sub id {
    "$_[0]->{-type}:$_[0]->{-value}";
}

1;

__END__

=head1 NAME

Config::Maker::Option - One configuration element.

=head1 SYNOPSIS

  use Config::Maker

  # Only constructed from the config parser
  
  $option->type
  $option->id
  "$option"

  $option->get($path)
  $option->get1($path)
  $option->getval($path, $default)

=head1 DESCRIPTION

C<Config::Maker::Option> objects represent individual elements of the
configuration.

Each C<Config::Maker::Option> object has three attributes. The C<-type>, which
is a C<Config::Maker::Type> object, the C<-value>, which is a string and the
C<-children> which is a list of C<Config::Maker::Option> objects.

The type can be accessed via the C<type> method (read-only), and the C<value>
may be accessed by simple stringification. The C<id> method is useful for
reporting option in errors.

In addition to basic access, there are several convenience methods for doing
path lookups. They are esentialy reversed C<Config::Maker::Path::find> method,
but they can construct the path from a string.

=over 4

=item get

This is the simplest one. It is just calls C<Config::Maker::Path::find> with
invocant as a starting element, constructing the path with
C<Config::Maker::Path::make> if it get's a string. See L<Config::Maker::Path>.

Unlike C<find>, which returns an arrayref, this returns a list in list context
and first match in scalar context.

=item get1

This is like C<get> above, but it signal an error unless the path matches
exactly one element.

=item getval

This method takes an extra argument, a default. If the path does not match, it
returns the default. If it matches once, it returns the match. If it matches
more than once, it signals an error.

=back

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: b5642443-d4c6-4cb5-9420-cf16eca27cac
