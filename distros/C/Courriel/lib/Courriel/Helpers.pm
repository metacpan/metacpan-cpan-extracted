package Courriel::Helpers;

use strict;
use warnings;

our $VERSION = '0.45';

use Encode qw( decode );
use Exporter qw( import );
use List::AllUtils qw( first );

our @EXPORT_OK = qw(
    fold_header
    parse_header_with_attributes
    quote_and_escape_attribute_value
    unique_boundary
);

our $CRLF = "\x0d\x0a";

# from Email::Simple
our $LINE_SEP_RE = qr/(?:\x0a\x0d|\x0d\x0a|\x0a|\x0d)/;

sub fold_header {
    my $line = shift;

    my $folded = q{};

    # Algorithm stolen from Email::Simple::Header
    while ( length $line ) {
        if ( $line =~ s/^(.{0,76})(\s|\z)// ) {
            $folded .= $1 . $CRLF;
            $folded .= q{  } if length $line;
        }
        else {

            # Basically nothing we can do. :(
            $folded .= $line . $CRLF;
            last;
        }
    }

    return $folded;
}

sub quote_and_escape_attribute_value {
    my $val = shift;

    return $val unless $val =~ /[^a-zA-Z0-9\-]/;

    $val =~ s/(\\|")/\\$1/g;

    return qq{"$val"};
}

sub parse_header_with_attributes {
    my $text = shift;

    return unless defined $text;

    my ($val) = $text =~ /([^\s;]+)(?:\s*;\s*(.*))?\z/s;

    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
    return (
        $val,
        _parse_attributes($2),
    );
}

our $TSPECIALS = qr{\Q()<>@,;:\"/[]?=};

my $extract_quoted = qr/
                           (?:
                               \"
                               (?<quoted_value>
                                   [^\\\"]*
                                   (?:
                                       \\.[^\\\"]*
                                   )*
                               )
                               \"
                           |
                               \'
                               (?<quoted_value>
                                   [^\\\']*
                                   (?:
                                       \\.[^\\\']*
                                   )*
                               )
                               \'
                           )
                       /x;

# This is a very loose regex. RFC 2231 has a much tighter definition of what
# can go in an attribute name, but this parser is designed to accept all the
# crap the internet throws at it.
my $attr_re = qr/
                    (?<name>[^\s=\*]+)     # names cannot include spaces, "=", or "*"
                    (?:
                        \*(?<order>[\d+])
                    )?
                    (?<is_encoded>\*)?
                    =
                    (?:
                        $extract_quoted
                    |
                        (?<value>[^\s;]+)  # unquoted values cannot contain spaces
                    )
                    (\s*;\s*)?
                /xs;

sub _parse_attributes {
    my $attr_text = shift;

    return {} unless defined $attr_text && length $attr_text;

    my $attrs = {};

    while ( $attr_text =~ /\G$attr_re/g ) {
        my $name = $+{name};

        my $value;
        my $charset;
        my $language;

        my $order = $+{order} || 0;

        if ( $+{is_encoded} ) {
            if ($order) {
                $value = _decode_raw_value(
                    $+{value},
                    $attrs->{$name}[$order]{charset},
                );
            }
            else {
                ( $charset, $language, my $raw ) = split /\'/, $+{value}, 3;
                $language = undef unless length $language;

                $value = _decode_raw_value( $raw, $charset );
            }
        }
        elsif ( defined $+{quoted_value} ) {
            ( $value = $+{quoted_value} ) =~ s/\G(.*?)\\(.)/$1$2/g;
        }
        else {
            $value = $+{value};
        }

        $attrs->{$name}[$order] = {
            value    => $value,
            charset  => $charset,
            language => $language,
        };
    }

    return {
        map { $_ => _inflate_attribute( $_, $attrs->{$_} ) }
            keys %{$attrs}
    };
}

sub _decode_raw_value {
    my $raw     = shift;
    my $charset = shift;

    $raw =~ s/%([\da-fA-F]{2})/chr(hex($1))/eg;

    return $raw unless defined $charset;

    return decode( $charset, $raw );
}

sub _inflate_attribute {
    my $name     = shift;
    my $raw_data = shift;

    my $value = join q{}, grep {defined} map { $_->{value} } @{$raw_data};

    my %p = (
        name  => $_,
        value => $value,
    );

    for my $key (qw( charset language )) {
        $p{$key} = $raw_data->[0]{$key}
            if defined $raw_data->[0]{$key};
    }

    return Courriel::HeaderAttribute->new(%p);
}

sub unique_boundary {
    return Email::MessageID->new->user;
}

# Courriel::HeaderAttribute requires that $TSPECIALS be defined
require Courriel::HeaderAttribute;

1;
