##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Element.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Element;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use CSS::Object::Format;
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{format} = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    unless( $self->_is_a( $self->{format}, 'CSS::Object::Format' ) )
    {
        my $format = CSS::Object::Format->new(
            debug => $self->debug
        );
        $self->format( $format );
    }
    return( $self );
}

sub add_to
{
    my $self = shift( @_ );
    my $css  = shift( @_ ) || return( $self->error( "No css object was provided to add our element to it." ) );
    return( $self->error( "CSS object provided (", overload::StrVal( $css ), ") is not actually a CSS::Object object." ) ) if( !$self->_is_a( $css, 'CSS::Object' ) );
    $self->format->indent( $css->format->indent );
    $css->add_element( $self );
    return( $self );
}

sub as_string { return( shift->error( "This method has not been implemented in this class." ) ); }

sub class { return( ref( $_[0] ) ); }

sub format
{
	my $self = shift( @_ );
	my $format;
	if( @_ )
	{
	    # $format = $self->_set_get_object( 'format', 'CSS::Object::Format', @_ ) || return;
        my $val = shift( @_ );
        # $self->message( 3, "Setting new formatter '$val' for our class '", $self->class, "'." );
        my $format;
        if( $self->_is_a( $val, 'CSS::Object::Format' ) )
        {
            my $clone = $val->clone;
            ## Make a copy for ourself
            if( $self->format )
            {
                my( $p, $f, $l ) = caller();
                # $self->message( 3, "New formatter provided for our class '", $self->class, "' called from package $p at line $l in file $f to set indent from '", $self->format->indent->scalar, "' to '", $clone->indent->scalar, "'." );
                $clone->copy_parameters_from( $self->format );
            }
            $format = $self->_set_get_object( 'format', 'CSS::Object::Format', $clone ) || return;
            # die( "Provided value (", overload::StrVal( $val ), " and stored value (", overload::StrVal( $format ), ") are the same. It should have been cloned.\n" ) if( overload::StrVal( $val ) eq overload::StrVal( $format ) );
        }
        ## format as a class name
        elsif( !ref( $val ) && CORE::index( $val, '::' ) != -1 )
        {
            $self->_load_class( $val ) || return;
            $format = $val->new( debug => $self->debug ) || return( $self->pass_error( $val->error ) );
            $self->_set_get_object( 'format', 'CSS::Object::Format', $format );
        }
        else
        {
            return( $self->error( "Unknown format \"$val\". I do not know what to do with it." ) );
        }
	    return( $format );
	}
	return( $self->_set_get_object( 'format', 'CSS::Object::Format' ) );
}

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Element - CSS Object Oriented Element

=head1 SYNOPSIS

    package CSS::Object::Comment;
    use parent qw( CSS::Object::Element );
    my $cmt = CSS::Object::Comment->new( "No comment" ) ||
        die( CSS::Object::Comment->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Element> is a base class for all L<CSS::Object> elements that get added to the style sheet.

=head1 CONSTRUCTOR

=head2 new

This is the base method to instantiate object. It takes by default the following arguments and instantiate an L<CSS::Object::Format> object if none was provided.

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=back

=head1 METHODS

=head2 add_to

Provided with a L<CSS::Object> and this add our object to the css object array of elements by calling L<CSS::Object/add_element>. Elements here are top level elements which are css rules.

=head2 as_string

This method must be overridden by the child class.

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
