##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Parser.pm
## Version v0.2.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/06/21
## Modified 2024/09/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package CSS::Object::Parser;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    our $VERSION = 'v0.2.0';
};

sub init
{
    my $self = shift( @_ );
    my $css  = shift( @_ ) ||
    return( $self->error( "No CSS object provided." ) );
    return( $self->error( "CSS object provded is actually not a CSS::Object object." ) ) if( !$self->_is_a( $css, 'CSS::Object' ) );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->css( $css ) || return( $self->pass_error );
    return( $self );
}

sub css { return( shift->_set_get_object( 'css', 'CSS::Object', @_ ) ); }

sub parse_string { return( shift->error( "You cannot use this class directly. Please use one of the Parser subclasses." ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

CSS::Object::Parser - CSS Object Oriented Parser

=head1 SYNOPSIS

    use CSS::Object::Parser;
    my $parser = CSS::Object::Parser->new( debug => 3 );
    my $rules = $parser->parse_string( $css_text_data ) ||
        die( CSS::Object::Parser->error );
    printf( "Found %d rules\n", $rules->length );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<CSS::Object::Parser> is base CSS parser for L<CSS::Object>

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Parser> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=back

=head1 METHODS

=head2 css

This sets or gets a L<CSS::Object> object. This object is used to create css elements and store them with the L<CSS::Object/add_element> method.

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 parse_string

In this base module, this method does nothing but trigger an error that it should not be called directly, but instead use this module sub classes.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
