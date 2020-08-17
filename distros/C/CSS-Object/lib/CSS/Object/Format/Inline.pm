##----------------------------------------------------------------------------
## CSS Object Oriented - ~/lib/CSS/Object/Format/Inline.pm
## Version v0.1.0
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2020/08/09
## Modified 2020/08/09
## 
##----------------------------------------------------------------------------
package CSS::Object::Format::Inline;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( CSS::Object::Format );
    use Devel::Confess;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{new_line} = "\n";
    $self->{open_brace_on_new_line} = 0;
    $self->{close_brace_on_new_line} = 0;
    $self->{open_brace_and_new_line} = 0;
    $self->{indent} = '';
    $self->{property_separator} = ' ';
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ );
    return( $self );
}

sub comment_as_string
{
    my( $self, $elem ) = @_;
    no overloading;
    return( $self->error( "No comment object was provided." ) ) if( !$elem );
    return( $self->error( "Comment object provied is not a CSS::Object::Comment object." ) ) if( !$self->_is_a( $elem, 'CSS::Object::Comment' ) );
    ## Because this is inline, there is no carriage returns
    return( '/* ' . $elem->values->join( ' ' )->scalar . ' */' );
}

sub copy_parameters_from
{
    my $self = shift( @_ );
    my $fmt  = shift( @_ ) || return( $self->error( "No formatter object was provided to copy the parameters from." ) );
    return( $self->error( "Formatter object provided is actually not a formatter object." ) ) if( !$self->_is_a( $fmt, 'CSS::Object::Format' ) );
    # my( $p, $f, $l ) = caller();
    # $self->message( 3, "copy_parameters_from called from package $p at line $l in file $f to set indent from '", $self->indent->scalar, "' to '", $fmt->indent->scalar, "'." );
    ## We only copy the property separator, and ignore all other possible parameters
    my @ok_params = qw(
        property_separator
    );
    for( @ok_params )
    {
        $self->$_( $fmt->$_ ) if( $fmt->can( $_ ) );
    }
    return( $self );
}

sub elements_as_string
{
    my( $self, $elems ) = @_;
    no overloading;
    ## Make a backup of parameters and we'll restore them after
    my $backup = $self->backup_parameters;
    ## new_array() from Module::Generic
    my $all = $backup->{elements} = $self->new_array;
    $elems->foreach(sub
    {
        $all->push( $_->format->backup_parameters );
        $_->format->indent( '' );
        $_->format->property_separator( ' ' );
    });
    
    $self->property_separator( ' ' );
    $self->indent( '' );
    my $res = $self->SUPER::elements_as_string( $elems );
    $self->restore_parameters( $backup );
    $elems->for(sub
    {
        my( $i, $this ) = @_;
        $this->format->restore_parameters( $all->get( $i ) );
    });
    return( $res );
}

sub rule_as_string
{
	my( $self, $rule ) = @_;
	no overloading;
	# $self->message( 3, "Stringifying rule for inline style" );
	return( $self->error( "No rule object was provided." ) ) if( !$rule );
	return( $self->error( "Rule object provided (", overload::Overloaded( $rule ) ? overload::StrVal( $rule ) : $rule ,") is not an actual rule object." ) ) if( !$self->_is_a( $rule, 'CSS::Object::Rule' ) );
	return( $rule->elements_as_string );
}

1;

__END__

=encoding utf-8

=head1 NAME

CSS::Object::Format - CSS Object Oriented Stringificator for Inline CSS

=head1 SYNOPSIS

    use CSS::Object::Format::Inline;
    my $format = CSS::Object::Format::Inline->new( debug => 3 ) ||
        die( CSS::Object::Format::Inline->error );
    my $prop = CSS::Object::Property->new(
        format => $format,
        debug => 3,
        name => 'display',
        value => 'inline-block',
    ) || die( CSS::Object::Property->error );
    print( $prop->as_string );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<CSS::Object::Format> is a object oriented CSS parser and manipulation interface to write properties suitable to be added inline, i.e. inside an html element attribute C<style>. This package inherits from L<CSS::Object::Format>

Because it is designed to be inline, there cannot be multiple rules. There is only rule and is implicit and used solely to hold all the properties.

=head1 CONSTRUCTOR

=head2 new

To instantiate a new L<CSS::Object::Format> object, pass an hash reference of following parameters:

=over 4

=item I<debug>

This is an integer. The bigger it is and the more verbose is the output.

=back

=head1 METHODS

=head2 rule_as_string

Provided with a L<CSS::Object::Rule> object and this will format it and return its string representation suitable for inline use in an HTML element.

    my $css = CSS::Object->new(
        debug => 3,
        format => CSS::Object::Format::Inline->new( debug => 3 )
    );
    my $rule = $css->add_rule( $css->new_rule );
    $rule->add_property( $css->new_property(
        name => 'display',
        value => 'none',
    ));
    $rule->add_property( $css->new_property(
        name => 'font-size',
        value => '1.2rem',
    ));
    $rule->add_property( $css->new_property(
        name => 'text-align',
        value => 'center',
    ));
    print( '<div style="%s"></div>', $rule->as_string );

=head2 comment_as_string

This returns a formatted comment string.

=head2 rule_as_string

This returns a css rule as string.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<CSS::Object>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
