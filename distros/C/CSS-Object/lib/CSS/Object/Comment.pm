##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Comment.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.local>
## Created 2020/06/21
## Modified 2020/06/21
## 
##----------------------------------------------------------------------------
package CSS::Object::Comment;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Element );
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
    my $this = shift( @_ );
    if( CORE::length( $this ) && $self->_is_array( $this ) )
    {
        $self->values->push( @$this );
    }
    else
    {
        $self->values->push( $this );
    }
    $self->SUPER::init( @_ );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->format->comment_as_string( $self ) );
}

sub values { return( shift->_set_get_object_array_object( 'values', 'CSS::Object::Value', @_ ) ); }

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Comment - CSS Object Oriented Comment

=head1 SYNOPSIS

    use CSS::Object::Comment;
    my $cmt = CSS::Object::Comment->new( "No comment" ) ||
        die( CSS::Object::Comment->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Comment> represent a comment inside a style sheet.

Comments can appear anywhere between rules or inside rules between properties.

=head1 CONSTRUCTOR

=head2 new

It take either a string or an array reference of string representing comment data.

It also takes the following optional arguments.

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=item I<format>

This is a L<CSS::Object::Format> object or one of its child modules.

=back

=head1 METHODS

=head2 as_string

This stringify the comment, formatting it propertly

=head2 format

This is a L<CSS::Object::Format> object or one of its child modules.

=head2 values

This sets or returns the array object containing the comment lines. This is a L<Module::Generic::Array> object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
