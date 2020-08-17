##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Rule.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Rule::At;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Rule );
    use Devel::Confess;
    use overload (
        '""' => 'as_string',
        fallback => 1,
    );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self->error( "No css object was shared with us." ) ) if( !$self->css );
    return( $self );
}

sub css { return( shift->_set_get_object( 'css', 'CSS::Object', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

## e.g. keyframe
sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }


1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Rule::At - CSS Object Oriented At-Rule

=head1 SYNOPSIS

    use CSS::Object::Rule::At;
    my $rule = CSS::Object::Rule::At->new( debug => 3, format => $format_object ) ||
        die( CSS::Object::Rule::At->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Rule::At> is a base class for at-rule type of objects, such as C<@counter-style>, C<@document>, C<@font-face>, C<@font-feature-values>, C<@import>, C<@keyframes>, C<media>, C<@namespace>, C<@page>, C<supports>, C<@viewport> and some other experimental ones such as C<@annotation>, C<@character-variant>, C<@ornaments>, C<@stylistic>, C<@styleset>, C<@swash>, 

See here for more information: L<https://developer.mozilla.org/en-US/docs/Web/CSS/At-rule>

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Rule::At> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=back

=head1 METHODS

=head2 name

Sets or gets the name of this at-rule. It returns a L<Module::Generic::Scalar>

=head2 value

Sets or gets this at-rule's value. It returns a L<Module::Generic::Scalar>

head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
