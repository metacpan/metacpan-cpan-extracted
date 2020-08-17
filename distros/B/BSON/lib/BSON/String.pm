use 5.010001;
use strict;
use warnings;

package BSON::String;
# ABSTRACT: BSON type wrapper for strings

use version;
our $VERSION = 'v1.12.2';

use Moo;

#pod =attr value
#pod
#pod A scalar value, which will be stringified during construction.  The default
#pod is the empty string.
#pod
#pod =cut

has 'value' => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

sub BUILDARGS {
    my $class = shift;
    my $n     = scalar(@_);

    my %args;
    if ( $n == 0 ) {
        $args{value} = '';
    }
    elsif ( $n == 1 ) {
        $args{value} = shift;
    }
    elsif ( $n % 2 == 0 ) {
        %args = @_;
        $args{value} = '' unless defined $args{value};
    }
    else {
        croak("Invalid number of arguments ($n) to BSON::String::new");
    }

    # normalize all to internal PV type
    $args{value} = "$args{value}";

    return \%args;
}

#pod =method TO_JSON
#pod
#pod Returns value as a string.
#pod
#pod =cut

sub TO_JSON { return "$_[0]->{value}" }

use overload (
    # Unary
    q{bool} => sub { !! $_[0]->{value} },
    q{""} => sub { $_[0]->{value} },
    q{0+} => sub { 0+ $_[0]->{value} },
    q{~}  => sub { ~( $_[0]->{value} ) },
    # Binary
    ( map { $_ => eval "sub { return \$_[0]->{value} $_ \$_[1] }" } qw( + * ) ), ## no critic
    (
        map {
            $_ => eval ## no critic
              "sub { return \$_[2] ? \$_[1] $_ \$_[0]->{value} : \$_[0]->{value} $_ \$_[1] }"
        } qw( - / % ** << >> x <=> cmp & | ^ )
    ),
    (
        map { $_ => eval "sub { return $_(\$_[0]->{value}) }" } ## no critic
          qw( cos sin exp log sqrt int )
    ),
    q{atan2} => sub {
        return $_[2] ? atan2( $_[1], $_[0]->{value} ) : atan2( $_[0]->{value}, $_[1] );
    },

    # Special
    fallback => 1,
);

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::String - BSON type wrapper for strings

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_string( $string );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a string value.

Since Perl does not distinguish between numbers and strings, this module
provides an explicit string type for a scalar value.

=head1 ATTRIBUTES

=head2 value

A scalar value, which will be stringified during construction.  The default
is the empty string.

=head1 METHODS

=head2 TO_JSON

Returns value as a string.

=for Pod::Coverage BUILDARGS

=head1 OVERLOADING

The stringification operator (C<"">) is overloaded to return the C<value>,
the full "minimal set" of overloaded operations is provided (per L<overload>
documentation) and fallback overloading is enabled.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
