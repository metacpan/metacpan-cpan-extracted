##----------------------------------------------------------------------------
## Changes file management - ~/lib/Changes/Change.pm
## Version v0.1.1
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/11/23
## Modified 2023/09/19
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Changes::Change;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    # use Nice::Try;
    our $VERSION = 'v0.1.1';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{line}       = undef;
    $self->{marker}     = undef;
    $self->{max_width}  = 0;
    $self->{nl}         = "\n";
    $self->{raw}        = undef;
    $self->{spacer1}    = undef;
    $self->{spacer2}    = undef;
    $self->{text}       = undef;
    $self->{wrapper}    = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_reset} = 1;
    $self->{_reset_normalise} = 1;
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    if( !exists( $self->{_reset} ) || 
        !defined( $self->{_reset} ) ||
        !CORE::length( $self->{_reset} ) )
    {
        if( exists( $self->{_cache_value} ) &&
            defined( $self->{_cache_value} ) &&
            length( $self->{_cache_value} ) )
        {
            return( $self->{_cache_value} );
        }
        elsif( defined( $self->{raw} ) && length( "$self->{raw}" ) )
        {
            return( $self->{raw} );
        }
    }
    my $nl = $self->nl;
    my $str = $self->new_scalar( ( $self->spacer1 // '' ) . ( $self->marker // '-' ) . ( $self->spacer2 // '' ) );
    my $max = $self->max_width;
    if( $max > 0 && ( $self->normalise->length + $str->length ) > $max )
    {
        my $text;
        my @spaces = map{ $_ eq "\t" ? "\t" : ' ' } split( //, "$str" );
        my $sep = join( '', @spaces );
        my $wrapper = $self->wrapper;
        if( $self->_is_code( $wrapper ) )
        {
            # try-catch
            local $@;
            $text = eval
            {
                $wrapper->( $self->normalise->scalar, ( $max - $str->length ) );
            };
            if( $@ )
            {
                warn( "Warning only: an error occurred while calling the wrapper calback with ", $self->normalise->length, " bytes of change text and a maximum width of ", ( $max - $str->length ), " characters: $@\n" ) if( $self->_warnings_is_enabled );
            }
        }
        elsif( $self->_load_class( 'Text::Wrap' ) )
        {
            # Silence the use of $Text::Wrap::columns used once
            no warnings 'once';
            # We need to reduce $max by as much indentation there is
            local $Text::Wrap::columns = ( $max - $str->length );
            $text = Text::Wrap::wrap( '', '', $self->normalise->scalar );
        }
        elsif( $self->_load_class( 'Text::Format' ) )
        {
            my $fmt = Text::Format->new({
                columns => ( $max - $str->length ),
                extraSpace => 0,
                firstIndent => 0,
            });
            $text = $fmt->format( $self->normalise->scalar );
        }
        
        if( defined( $text ) && length( "$text" ) )
        {
            $str->append( join( "\n$sep", split( /\r?\n/, "$text" ) ) );
        }
    }
    else
    {
        $str->append( $self->normalise );
    }
    $str->append( $nl );
    $self->{_cache_value} = $str;
    CORE::delete( $self->{_reset} );
    return( $str );
}

sub freeze
{
    my $self = shift( @_ );
    CORE::delete( @$self{qw( _reset _reset_normalise )} );
    return( $self );
}

sub line { return( shift->reset(@_)->_set_get_number( 'line', @_ ) ); }

sub marker { return( shift->reset(@_)->_set_get_scalar_as_object( 'marker', @_ ) ); }

sub max_width { return( shift->_set_get_number( 'max_width', @_ ) ); }

sub nl { return( shift->reset(@_)->_set_get_scalar_as_object( 'nl', @_ ) ); }

sub normalise
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset_normalise} ) || 
            !defined( $self->{_reset_normalise} ) ||
            !CORE::length( $self->{_reset_normalise} )
        ) && exists( $self->{_normalised} ) && 
             $self->_is_a( $self->{_normalised} => 'Module::Generic::Scalar' ) )
    {
        return( $self->{_normalised} );
    }
    my $str = $self->text->clone;
    return( $str ) if( $str->is_empty );
    if( $str->index( "\n" ) != -1 )
    {
        $str->replace( qr/[[:blank:]\h]*\n[[:blank:]\h]*/ => ' ' );
    }
    $self->{_normalised} = $str;
    CORE::delete( $self->{_reset_normalise} );
    return( $str );
}

sub prefix
{
    my $self = shift( @_ );
    my $s = ( $self->spacer1 // '' ) . ( $self->marker // '' ) . ( $self->spacer2 // '' );
    return( $self->new_scalar( \$s ) );
}

sub raw { return( shift->_set_get_scalar_as_object( 'raw', @_ ) ); }

sub reset
{
    my $self = shift( @_ );
    if( (
            !exists( $self->{_reset} ) ||
            !defined( $self->{_reset} ) ||
            !CORE::length( $self->{_reset} ) 
        ) && scalar( @_ ) )
    {
        $self->{_reset} = scalar( @_ );
        $self->{_reset_normalise} = 1;
    }
    return( $self );
}

# space before the marker
sub spacer1 { return( shift->reset(@_)->_set_get_scalar_as_object( 'spacer1', @_ ) ); }

# space after the marker
sub spacer2 { return( shift->reset(@_)->_set_get_scalar_as_object( 'spacer2', @_ ) ); }

sub text { return( shift->reset(@_)->_set_get_scalar_as_object( 'text', @_ ) ); }

# We do not use the reset here, because just setting a wrap callback has no direct impact on the output
sub wrapper { return( shift->_set_get_code( 'wrapper', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Changes::Change - Changes object class

=head1 SYNOPSIS

    use Changes::Change;
    my $this = Changes::Change->new(
        line => 12,
        marker => '-',
        max_width => 68,
        spacer1 => "\t",
        # Defaults to just one space
        spacer2 => undef,
        text => "This is a change note",
        wrapper => sub
        {
            my( $text, $width ) = @_;
            require Text::Wrap;
            local $Text::Wrap::columns = $width;
            my $result = Text::Wrap::wrap( '', '', "$text" );
            return( $result );
        }
    ) || die( Changes::Change->error, "\n" );

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

This represents a change line within a release. A change line is usually represented by some indentation spaces, followed by a marker such as a dash, a space and a text:

    - This is a change note

A change text can be written on a very long line or broken into lines of C<max_width>. You can change this value with L</max_width> and by default it is 0, which means it will be all on one line.

=head1 METHODS

=head2 as_string

Returns a L<scalar object|Module::Generic::Scalar> of the change line. This information is cached unless other information has been changed.

Also, if nothing was changed and L</raw> is set with a value, that value will be returned instead.

If L</wrapper> is defined, the perl code reference set will be called by providing it the text of the change and the adjusted width to use. The actual width is the width of the change text with any leading spaces and characters as specified with L</spacer1>, L</spacer2> and L</marker>.

If the callback dies, this exception will be caught and displayed as a warning if C<use warnings> is enabled.

If no callback is specified, it will attempt to load L<Text::Wrap> (a perl core module) and L<Text::Format> in this order.

If none of it is possible, the change text will simply not be wrapped.

If an error occurred, it returns an L<error|Module::Generic/error>

The resulting string is terminated by the carriage return sequence defined with L</nl>

It returns a L<scalar object|Module::Generic::Scalar>

=for Pod::Coverage freeze

=head2 line

Sets or gets an integer representing the line number where this line containing the change information was found in the original C<Changes> file. If this object was instantiated separately, then obviously this value will be C<undef>

=head2 marker

Sets or gets the character representing the marker preceding the text of the change. This is usually a dash.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 max_width

Sets or gets the change line maximum width. The line width includes any spaces and characters at the beginning of the line, as set with L</spacer1>, L</spacer2> and L</marker> and not just the text of the change itself.

It returns a L<number object|Module::Generic::Number>

=head2 nl

Sets or gets the new line character, which defaults to C<\n>

It returns a L<number object|Module::Generic::Number>

=head2 normalise

This returns a "normalised" version of the change text, which means that if the change text is wrapped and has new lines with possibly preceding and trailing spaces, those will be replaced by a single space.

It does not modify the original change text.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 prefix

Read-only. This returns what precedes the text of the change, which is an optional leading space, and a marker such as a dash.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 raw

Sets or gets the raw version of the line as found in the C<Changes> file. If set and nothing has been changed, this will be returned by L</as_string> instead of computing the formatting of the change.

It returns a L<scalar object|Module::Generic::Scalar>

=for Pod::Coverage reset

=head2 spacer1

Sets or gets the leading space, if any, found before the marker.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 spacer2

Sets or gets the space found after the marker and before the text of the change.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 text

Sets or gets the text o the change. If the text is broken into multiple lines in the C<Changes> file, it will be collected as on L<scalar object|Module::Generic::Scalar> here.

It returns a L<scalar object|Module::Generic::Scalar>

=head2 wrapper

Sets or gets a code reference as a callback mechanism to return a properly wrapped change text. This allows flexibility beyond the default use of L<Text::Wrap> and L<Text::Format>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Changes>, L<Changes::Release>, L<Changes::Group>, L<Changes::Version>, L<Changes::NewLine>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
