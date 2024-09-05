##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Selector.pm
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
package CSS::Object::Selector;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Element );
    our $VERSION = 'v0.2.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{name}       = '';
    $self->{format}     = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

## Inherited
## sub format

sub add_to
{
    my $self = shift( @_ );
    my $rule = shift( @_ ) || return( $self->error( "No rule object was provided to add our selctor to it." ) );
    return( $self->error( "Rule object provided (", overload::StrVal( $rule ), ") is not actually a CSS::Object::Rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
    $self->format->indent( $rule->format->indent );
    $rule->add_selector( $self );
    return( $self );
}

sub as_string { return( shift->name ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

CSS::Object::Selector - CSS Object Oriented Selector

=head1 SYNOPSIS

    use CSS::Object::Selector;
    my $sel = CSS::Object::Selector->new(
        name => $css_selector,
        debug => 3,
        format => $format_object
    ) || die( CSS::Object::Selector->error );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<CSS::Object::Selector> is a class to contain the name of a selector. For any given css rule, there can be multiple selectors.

Selector objects can be accessed with L<CSS::Object::Rule/selectors> which is an L<Module::Generic::Array> object.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Selector> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=item I<name>

This is the selector's name. When provided, this calls the method L</name> to store the value.

=back

=head1 METHODS

=head2 add_to

Provided with a L<CSS::Object::Rule> object, and this will add our selector object to it by calling L<CSS::Object::Rule/add_selector>

It returns our selector object to allow chaining.

=head2 as_string

This returns the selector's name.

Maybe, this should be changed to calling a method B<selector_as_string> in the L<CSS::Object::Format>, but the reasons for modifying a selector's name are limited.

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 name

Sets or gets the selector's name. The name stored here becomes a L<Module::Generic::Scalar> and thus all its object methods can be used

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
