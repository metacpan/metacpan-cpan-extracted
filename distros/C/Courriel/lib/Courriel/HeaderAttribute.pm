package Courriel::HeaderAttribute;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.44';

use Courriel::HeaderAttribute;
use Courriel::Helpers qw( quote_and_escape_attribute_value );
use Courriel::Types qw( Maybe NonEmptyStr Str );
use Encode qw( encode );

use Moose;
use MooseX::StrictConstructor;

with 'Courriel::Role::Streams';

has name => (
    is       => 'ro',
    isa      => NonEmptyStr,
    required => 1,
);

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has charset => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => 'us-ascii',
);

has language => (
    is      => 'ro',
    isa     => Maybe [NonEmptyStr],
    default => undef,
);

override BUILDARGS => sub {
    my $class = shift;

    my $p = super();

    return $p unless defined $p->{value};

    $p->{charset} = 'UTF-8' if $p->{value} =~ /[^\p{ASCII}]/;

    return $p;
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _stream_to {
    my $self   = shift;
    my $output = shift;

    $output->( $self->_as_string );
}
## use critic

{
    my $non_attribute_char = qr{
                                   $Courriel::Helpers::TSPECIALS
                               |
                                   [ \*\%]           # space, *, %
                               |
                                   [^\p{ASCII}]      # anything that's not ascii
                               |
                                   [\x00-\x1f\x7f]   # ctrl chars
                           }x;

    sub _as_string {
        my $self = shift;

        my $value = $self->value;

        my $transport_method = '_simple_parameter';

        if (   $value =~ /[\x00-\x1f]|\x7f|[^\p{ASCII}]/
            || defined $self->language
            || $self->charset ne 'us-ascii' ) {

            $value = encode( 'utf-8', $value );
            $value
                =~ s/($non_attribute_char)/'%' . uc sprintf( '%02x', ord($1) )/eg;

            $transport_method = '_encoded_parameter';
        }
        elsif ( $value =~ /$non_attribute_char/ ) {
            $transport_method = '_quoted_parameter';
        }

        # XXX - hard code 78 as the max line length may not be right. Should
        # this account for the length that the parameter name takes up (as
        # well as encoding information, etc.)?

        my @pieces;
        while ( length $value ) {
            my $last_percent = rindex( $value, '%', 78 );

            my $size
                = $last_percent >= 76 ? $last_percent
                : length $value > 78  ? 78
                :                       length $value;

            push @pieces, substr( $value, 0, $size, q{} );
        }

        if ( @pieces == 1 ) {
            return $self->$transport_method( undef, $pieces[0] );
        }
        else {
            return join q{ },
                map { $self->$transport_method( $_, $pieces[$_] ) }
                0 .. $#pieces;
        }
    }
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _simple_parameter {
    my $self  = shift;
    my $order = shift;
    my $value = shift;

    my $param = $self->name;
    $param .= q{*} . $order if defined $order;
    $param .= q{=};
    $param .= $value;

    return $param;
}

sub _quoted_parameter {
    my $self  = shift;
    my $order = shift;
    my $value = shift;

    my $param = $self->name;
    $param .= q{*} . $order if defined $order;
    $param .= q{=};

    $value =~ s/\"/\\\"/g;

    $param .= q{"} . $value . q{"};

    return $param;
}

sub _encoded_parameter {
    my $self  = shift;
    my $order = shift;
    my $value = shift;

    my $param = $self->name;
    $param .= q{*} . $order if defined $order;
    $param .= q{*=};

    # XXX (1) - does it makes sense to just say everything is utf-8? in theory
    # someone could pass through binary data in another encoding.
    unless ($order) {
        $param .= 'UTF-8' . q{'} . ( $self->language // q{} ) . q{'};
    }

    $param .= $value;

    return $param;
}
## use critic;

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: A single attribute belonging to a header

__END__

=pod

=encoding UTF-8

=head1 NAME

Courriel::HeaderAttribute - A single attribute belonging to a header

=head1 VERSION

version 0.44

=head1 SYNOPSIS

  my $ct = $headers->get('Content-Type');
  print $ct->get_attribute('charset')->value;

=head1 DESCRIPTION

This class represents a single attribute belonging to a header. An attribute
consists of a name and value, with optional charset and language information.

=head1 API

This class supports the following methods:

=head1 Courriel::HeaderAttribute->new( ... )

This method creates a new object. It accepts the following parameters:

=over 4

=item * name

The name of the attribute. This should be a non-empty string.

=item * value

The value of the attribute. This can be empty.

=item * charset

The charset for the value. If the value contains any non-ASCII data, this will
always be "UTF-8", otherwise the default is "us-ascii".

=item * language

The language for the attribute's value. It should be a valid ISO language code
like "en-us" or "zh". This is optional.

=back

=head2 $attribute->name()

The attribute name as passed to the constructor.

=head2 $attribute->value()

The attribute value as passed to the constructor.

=head2 $attribute->charset()

The attribute's charset.

=head2 $attribute->language()

The attribute's language.

=head2 $attribute->as_string()

This returns the attribute in a form suitable for putting in an email. This
may involve escaping, quoting, splitting up, and otherwise messing with the
value.

If the value needs to be split across continuations, each name/value pair is
returned separate by a space, but not folded across multiple lines.

=head2 $attribute->stream_to( output => $output )

This method will send the stringified attribute to the specified output. The
output can be a subroutine reference, a filehandle, or an object with a
C<print()> method. The output may be sent as a single string, as a list of
strings, or via multiple calls to the output.

=head1 ROLES

This class does the C<Courriel::Role::Streams> role.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Courriel>
(or L<bug-courriel@rt.cpan.org|mailto:bug-courriel@rt.cpan.org>).

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
