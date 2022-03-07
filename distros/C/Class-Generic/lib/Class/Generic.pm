##----------------------------------------------------------------------------
## Class Bundle - ~/lib/Class/Generic.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/07
## Modified 2022/03/07
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Class::Generic;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.1.0';
};

1;

__END__

=encoding utf-8

=head1 NAME

Class::Generic - Class Generic

=head1 SYNOPSIS

    use parent qw( Class::Generic )

    sub init
    {
        my $self = shift( @_ );
        return( $self->SUPER::init( @_ ) );
    }

    my $array = Class::Array->new( $something );
    my $array = Class::Array->new( [$something] );
    my $hash  = Class::Assoc->new;
    my $bool  = Class::Boolean->new;
    my $ex    = Class::Exception->new( message => "Oh no", code => 500 );
    my $file  = Class::File->new( '/some/where/file.txt' );
    my $finfo = Class::Finfo->new( '/some/where/file.txt' );
    my $null  = Class::NullChain->new;
    my $num   = Class::Number->new( 10 );
    my $str   = Class::Scalar->new( 'Some string' );

    # For details on the api provided, please check each of the module documentation.

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This package inherits all its features from L<Module::Generic> and provides a generic framework of methods to inherit from and speed up development.

=head1 METHODS

See L<Module::Generic>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Class::Generic>, L<Class::Array>, L<Class::Scalar>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
