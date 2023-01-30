##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes/NewLine.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/12/08
## Modified 2022/12/08
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes::NewLine;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{nl} = "\n";
    $self->{raw} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $raw = $self->raw;
    $self->message( 4, "Raw new line was '", ( $raw // '' ), "'" );
    if( defined( $raw ) && $raw->defined )
    {
        return( $raw );
    }
    else
    {
        my $nl = $self->nl // "\n";
        return( $self->new_scalar( "$nl" ) );
    }
}

sub line { return( shift->_set_get_number( 'line', @_ ) ); }

sub nl { return( shift->_set_get_scalar_as_object( 'nl', @_ ) ); }

sub raw { return( shift->_set_get_scalar_as_object( 'raw', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes::NewLine - New Line Class

=head1 SYNOPSIS

    use Changes::NewLine;
    my $nl = Changes::NewLine->new(
        nl => "\n",
        line => 12,
        raw => "\t\n",
    ) || die( Changes::NewLine->error, "\n" );
    say $nl->as_string;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class represents a new line in the C<Changes> file.

=head1 CONSTRUCTOR

=head2 new

This takes an hash or an hash reference of following options, and instantiate a new L<Changes::NewLine> object and returns it.

If an error occurred, it returns an L<error|Module::Generic/error>

=over 4

=item * C<line>

The line number where this new line was found in the C<Changes> file.

=item * C<nl>

The format of the new line to use with L</as_string>

=item * C<raw>

The raw initial value such as it is found when parsing the C<Changes> file with L<Changes/parse>

=back

=head1 METHODS

=head2 as_string

Returns a string representation of the new line. If C<raw> is defined with L</raw>, then that initial value will be used and returned, otherwise, it will use whatever value is set with L</nl>.

Returns a L<scalar object|Module::Generic::Scalar>

=head2 line

Sets or gets the line number at which this new line appeared in the C<Changed> file. This is set by L<Changes/parse>

Returns a L<number object|Module::Generic::Number>

=head2 nl

Sets or gets the new line sequence. For example C<\n>, or C<\r\n>, or C<\015\012> (same as previous, but more portable), etc.

Returns a L<scalar object|Module::Generic::Scalar>

=head2 raw

Sets or gets the initial new line value. This is set upon parsing by L<Changes/parse>

Returns a L<scalar object|Module::Generic::Scalar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes>, L<Changes::Release>, L<Changes::Group>, L<Changes::Changes>, L<Changes::Version>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
