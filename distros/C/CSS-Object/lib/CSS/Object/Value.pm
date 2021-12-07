##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Value.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Value;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Element );
    use CSS::Object::Comment;
    use CSS::Object::Format;
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
    my $val;
    $val = shift( @_ ) if( ( scalar( @_ ) % 2 ) );
    $self->{format}     = '';
    $self->{value}      = '';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    $self->value( $val ) if( defined( $val ) );
    # $self->message( 3, "Returning value object for value '", $self->value, "'." );
    return( $self );
}

## Inherited
## sub format

sub as_string
{
    my $self = shift( @_ );
    return( '' ) if( !$self->format );
    return( $self->format->value_as_string( $self ) );
#     return(
#         $self->comment_before->map(sub{ $_->as_string })->scalar . ( $self->comment_before->length ? ' ' : '' ) . 
#         $self->format->value_as_string( $self ) . 
#         ( $self->comment_after->length ? ' ' : '' ) . $self->comment_after->map(sub{ $_->as_string })->scalar
#     );
}

sub comment { return( shift->_set_get_object_array_object( 'comment_after', 'CSS::Object::Comment', @_ ) ); }

sub comment_after { return( shift->_set_get_object_array_object( 'comment_after', 'CSS::Object::Comment', @_ ) ); }

sub comment_before { return( shift->_set_get_object_array_object( 'comment_before', 'CSS::Object::Comment', @_ ) ); }

sub value
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $val = shift( @_ );
        if( $self->_is_a( $val, 'CSS::Object::Value' ) )
        {
            ## If the value object provided has some comments attached to it
            ## Make sure each data stored is an object, or else we create an object before adding it
            if( $val->comment_after->length )
            {
                $val->comment_after->foreach(sub
                {
                    my $cmt = $self->_comment_data_to_object( $_ );
                    $self->comment_after->push( $cmt ) if( defined( $cmt ) );
                });
            }
            if( $val->comment_before->length )
            {
                $val->comment_before->foreach(sub
                {
                    my $cmt = $self->_comment_data_to_object( $_ );
                    $self->comment_before->push( $cmt ) if( defined( $cmt ) );
                });
            }
            $val = $val->value->scalar;
        }
        else
        {
            while( $val =~ s/^[[:blank:]\h]*\/\*[[:blank:]\h]*(.*?)[[:blank:]\h]*\*\///s )
            {
                $self->message( 3, "Adding comment found before value: '$1'." );
                my $cmt = CSS::Object::Comment->new( [split( /\r\n/, $1 )] ) ||
                    return( $self->error( "Cannot create comment object: ", CSS::Object::Comment->error ) );
                $self->comment_before->push( $cmt );
            }
            while( $val =~ s/[[:blank:]\h]*\/\*[[:blank:]\h]*(.*?)[[:blank:]\h]*\*\/$//s )
            {
                $self->message( 3, "Adding comment found after value: '$1'." );
                my $cmt = CSS::Object::Comment->new( [split( /\r\n/, $1 )] ) ||
                    return( $self->error( "Cannot create comment object: ", CSS::Object::Comment->error ) );
                $self->comment_after->push( $cmt );
            }
            $val =~ s/^[[:blank:]\h]*|[[:blank:]\h]*$//gs;
        }
        return( $self->_set_get_scalar_as_object( 'value', $val ) );
    }
    return( $self->_set_get_scalar_as_object( 'value' ) );
}

sub with_comment
{
    my $self = shift( @_ );
    my $opts = {};
    $opts = shift( @_ ) if( $self->_is_hash( $_[0] ) );
    if( $opts->{before} )
    {
        my $cmt = $self->_comment_data_to_object( $opts->{before} );
        defined( $cmt ) || return( $self->pass_error );
        $self->comment_before->push( $cmt ) if( defined( $cmt ) && CORE::length( $cmt ) );
    }
    if( $opts->{after} )
    {
        my $cmt = $self->_comment_data_to_object( $opts->{after} );
        defined( $cmt ) || return( $self->pass_error );
        $self->comment_after->push( $cmt ) if( defined( $cmt ) && CORE::length( $cmt ) );
    }
    return( $self );
}

sub _comment_data_to_object
{
    my $self = shift( @_ );
    # No data received, we silently return false
    my $this = shift( @_ ) || return( '' );
    if( $self->_is_a( $this, 'CSS::Objet::Comment' ) )
    {
        return( $this );
    }
    elsif( $self->_is_array( $this ) || !ref( $this ) )
    {
        my $cmt = CSS::Object::Comment->new( $this, debug => $self->debug ) ||
            return( $self->error( "Cannot create a new comment from array provided in this property value: ", CSS::Object::Comment->error ) );
        return( $cmt );
    }
    else
    {
        return( $self->error( "I do not know what to do with comment data \"$this\"." ) );
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Value - CSS Object Oriented Value

=head1 SYNOPSIS

    use CSS::Object::Value;
    # For font-size property for example
    my $val = CSS::Object::Value->new( '1.2rem',
        debug => 3,
        format => $format_object,
    ) || die( CSS::Object::Value->error );

    # Adding value with comment inside
    my $val = CSS::Object::Value->new( '1.2rem', with_comment =>
    {
        before => 'This is 12px',
        after => ["Might want to change this", "to something else"],
    }) || die( "Cannot add value with comments: ", CSS::Object::Value->error );
    
    my $val = CSS::Object::Value->new( '/* Might need to change this */ 1.2rem /* Maybe move this to px instead? */',
        debug => 3,
        format => $format_object,
    ) || die( CSS::Object::Value->error );

    # or
    $val->comment_before->push( $css->new_comment( "More comment before value" ));
    #val->comment_after->push( $css->new_comment( "Another comment after too" ));

    # or
    $val->with_comment({
        before => 'This is 12px',
        after => ["Might want to change this", "to something else"],
    }) || die( $val->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Value> is a module to contain the CSS properties' value.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Value> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=item I<value>

The property value, which can also be called as the sole argument:

    # For display property for example
    my $val = CSS::Object::Value->new( 'none' );

=item I<with_comment>

This parameter must be an hash reference with 2 possible properties: I<before> and I<after>. Each of thoe properties can contain either a simple string, an array reference of string, or an L<CSS::Object::Comment> object.

It returns our object

=back

=head1 METHODS

=head2 as_string

This calls the L</format> and its method L<CSS::Object::Format/value_as_string>

It returns the css string produce or undef and sets an L<Module::Generic::Exception> upon error.

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 value

Sets or gets the value for this property value. The value stored here becomes a L<Module::Generic::Scalar> and thus all its object methods can be used

Alternatively, it accepts a L<CSS::Object::Value> and will call its L</value> method to get the actual string to store.

It returns the value currently stored.

=head2 with_comment

This method takes an hash reference with 2 possible properties: I<before> and I<after>. Each of thoe properties can contain either a simple string, an array reference of string, or an L<CSS::Object::Comment> object.

It returns the object used to call this method, or undef if there was an error.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
