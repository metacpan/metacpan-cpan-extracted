package Business::LCCN;
use 5.6.1;
use Carp qw( carp );
use Moose;
use Moose::Util::TypeConstraints;
use Scalar::Util qw( blessed );
use URI;
use strict;
use warnings;

=head1 NAME

Business::LCCN - Work with Library of Congress Control Number (LCCN) codes

=head1 VERSION

Version 1.01

=cut

our $VERSION = '1.01';

=head1 SYNOPSIS

Work with Library of Congress Control Number (LCCN) codes.

    use Business::LCCN;

    my $lccn = Business::LCCN->new('he 68001993 /HE/r692');
    if ($lccn) {

      # parse LCCN (common fields)
      print 'Prefix ',         $lccn->prefix,         "\n"; # "he"
      print 'Prefix field ',   $lccn->prefix_encoded, "\n"; # "he "
      print 'Year cataloged ', $lccn->year_cataloged, "\n"; # 1968
      print 'Year field ',     $lccn->year_encoded,   "\n"; # "68"
      print 'Serial ',         $lccn->serial,         "\n"; # "001993"

      # stringify LCCN:

      # canonical format: "he 68001993 /HE/r692"
      print 'Canonical ',     $lccn->canonical,    "\n";

      # simple normalized format: "he68001993"
      print 'Normalized ', $lccn->normalized,"\n";

      # info: URI: "info:lccn:he68001993"
      print 'Info URI ',   $lccn->info_uri,  "\n";

      # lccn.loc.gov permalink: "http://lccn.loc.gov/he68001993"
      print 'Permalink ',  $lccn->permalink,"\n";

      # parse LCCN (uncommon fields)
      print 'LCCN Type ',     $lccn->lccn_structure, "\n"; # "A" or "B"
      print 'Suffix field ',  $lccn->suffix_encoded,  \n"; # "/HE"
      print 'Suffix parts ',  $lccn->suffix_alphabetic_identifiers,
                                                     "\n"; # ("HE")
      print 'Rev year',       $lccn->revision_year,  "\n"; # 1969
      print 'Rev year field ',$lccn->revision_year_encoded,
                                                     "\n"; # "69"
      print 'Rev number ',    $lccn->revision_number,"\n"; # 2

    } else {
        print " Error : Invalid LCCN \n ";
    }

=cut

use overload
    '==' => \&_overload_equality,
    'eq' => \&_overload_equality,
    '""' => \&_overload_string;

subtype 'LCCN_Year'   => as 'Int' => where { $_ >= 1898 };
subtype 'LCCN_Serial' => as 'Str' => where {m/^\d{6}$/};
enum 'LCCN_Structure' => qw( A B );

# normalize syntax at http://www.loc.gov/marc/lccn-namespace.html
subtype 'LCCN_Normalized' => as 'Str' =>
    where {m/^(?:[a-z](?:[a-z](?:[a-z]|\d{2})?|\d\d)?|\d\d)?\d{8}$/};
subtype 'URI' => as 'Object' => where { $_->isa('URI') };
coerce 'URI' => from 'Str' => via { URI->new($_) };

has 'original' => ( is => 'ro', isa => 'Maybe[Str]', required => 1 );
has 'lccn_structure' =>
    ( is => 'ro', isa => 'LCCN_Structure', required => 1 );
has 'year_encoded' => ( is => 'ro', isa => 'Str', required => 1 );
has 'year_cataloged' =>
    ( is => 'ro', isa => 'Maybe[LCCN_Year]', required => 0 );
has 'prefix'         => ( is => 'ro', isa => 'Str',         required => 1 );
has 'prefix_encoded' => ( is => 'ro', isa => 'Str',         required => 1 );
has 'serial'         => ( is => 'ro', isa => 'LCCN_Serial', required => 1 );
has 'suffix_encoded' =>
    ( is => 'ro', isa => 'Str', required => 1, default => '' );
has 'suffix_alphabetic_identifiers' => (
                        is      => 'ro',
                        isa     => 'ArrayRef[Str]',
                        lazy    => 1,
                        default => sub { _suffix_alphabetic_identifiers(@_) },
);
has 'revision_year' => ( is => 'ro', isa => 'Maybe[Int]', required => 0 );
has 'revision_year_encoded' =>
    ( is => 'ro', isa => 'Str', required => 1, default => '' );
has 'revision_number' => ( is => 'ro', isa => 'Maybe[Int]', required => 0 );
has 'canonical' => ( is      => 'ro',
                     isa     => 'Str',
                     lazy    => 1,
                     default => sub { _canonical(@_) },
);
has 'normalized' => ( is      => 'ro',
                      isa     => 'LCCN_Normalized',
                      lazy    => 1,
                      default => sub { _normalized(@_) },
);
has 'permalink' => ( is      => 'ro',
                     isa     => 'URI',
                     lazy    => 1,
                     default => sub { _permalink(@_) }
);
has 'info_uri' => ( is      => 'ro',
                    isa     => 'URI',
                    lazy    => 1,
                    default => sub { _info_uri(@_) }
);

around 'new' => sub {
    my ( $next, $self, $input, $options ) = @_;

    unless ( $options and ref $options and ref $options eq 'HASH' ) {
        $options = {};
    }
    my $emit_warnings = !$options->{no_warnings};

    if ( !defined $input ) {
        carp q{Received an undefined value as LCCN input.} if $emit_warnings;
        return;
    } elsif ( !length $input ) {
        carp q{Received an empty string as LCCN input.} if $emit_warnings;
        return;
    } else {
        my %out = ( original => $input );

        # clean up any leading or trailing whitespace
        $input =~ s/^\s+|\s+$//g;

        # accept permalinks
        $input =~ s{^http://lccn.loc.gov/}{};

        # accept info: uris
        $input =~ s{^info:lccn/}{};

        # try LCCN structure B
        if ($input =~ m{
            ^
              ([a-zA-Z\s]{0,2})  # 2-letter alphabetic prefix
              \s?                # space, not officially allowed
              ([2-9]\d\d\d)      # 4-letter year
              (?:
                -(\d{1,6})         # hyphen plus 1-6 digit serial number
                |                #   or...
                (\d{6})            # 6 digit serial number
              )
            $ }x
            ) {
            $out{lccn_structure} = 'B';
            $out{prefix_encoded} = $1;
            $out{year_encoded}   = $2;
            $out{serial}         = ( defined $3 ? $3 : $4 );

            $out{year_cataloged} = $out{year_encoded};

            # try LCCN structure A
        } elsif (
            $input =~ m{
            ^
              ([a-zA-Z\s]{0,3})      # 3-letter alphabetic prefix
              (\d\d)                 # 2-letter year
              (?:
                -(\d{1,6})           # hyphen plus 1-6 digit serial number
                |                    #   or...
                (\d{6})              # 6 digit serial number
              )
              (?:
                (?:\s|(?!\d))        # blank for supplement
                (/[A-Z]{1,3})*       # suffix/alphabetic identifiers
                (?://?
                    r(\d\d) # revision year encoded
                    (\d*))? # revision number
              )?
            $ }x
            ) {

            $out{lccn_structure}        = 'A';
            $out{prefix_encoded}        = $1;
            $out{year_encoded}          = $2;
            $out{serial}                = ( defined $3 ? $3 : $4 );
            $out{suffix_encoded}        = ( defined($5) ? $5 : '' );
            $out{revision_year_encoded} = $6;
            $out{revision_number}       = ( $7 || undef );

            # per http://www.loc.gov/marc/marbi/dp/dp84.html and
            # http://en.wikipedia.org/wiki/Library_of_Congress_Control_Number,
            # the first LCCNs were assigned in 1898, and there were fewer than
            # 8000 LCCns issued each of those years

            if ( $out{year_encoded} eq '98' ) {
                if ( $out{serial} < 3000 ) {
                    $out{year_cataloged} = 1898;
                } else {
                    $out{year_cataloged} = 1998;
                }
            } elsif ( $out{year_encoded} eq '99' ) {
                if ( $out{serial} < 6000 ) {
                    $out{year_cataloged} = 1899;
                } else {
                    $out{year_cataloged} = 1999;
                }
            } elsif ( $out{year_encoded} eq '00' ) {
                if ( $out{serial} < 8000 ) {
                    $out{year_cataloged} = 1900;
                } else {
                    $out{year_cataloged} = 2000;
                }
            } elsif ( $out{year_encoded} eq '50' ) {
                $out{lccn_externally_created_flag} = 1;    # zzz
            } elsif ( $out{year_encoded} =~ m/^7\d$/ ) {
                if ( _verify_7_checksum( $out{year_encoded}, $out{serial} ) )
                {
                    $out{lccn_structure_series} = 7;
                } else {
                    $out{year_cataloged} = $out{year_encoded} + 1900;
                }
            } else {
                $out{year_cataloged} = $out{year_encoded} + 1900;
            }

            if ( defined $out{revision_year_encoded}
                 and length $out{revision_year_encoded} ) {
                if (    $out{revision_year_encoded} == 98
                     or $out{revision_year_encoded} == 99 ) {
                    $out{revision_year} = $out{revision_year_encoded} + 1800;
                } else {
                    $out{revision_year} = $out{revision_year_encoded} + 1900;
                }
            }

        } else {
            if ( $input !~ m/\d\d/ ) {
                carp
                    qq{LCCN input "$input" doesn't contain enough numbers. Please check the input and try again.}
                    if $emit_warnings;
            } elsif ( $input =~ m/^\s*(0(?:01|10))\b/ ) {
                carp
                    qq{LCCN input "$input" starts with "$1", suggesting you've copied in part of a MARC record. Please remove MARC record formatting from the LCCN.}
                    if $emit_warnings;
            } elsif ( $input =~ m/^\s*(\$[ab])\b/ ) {
                carp
                    qq{LCCN $input "input" starts with "$1", suggesting you've copied in part of a MARC record. Please remove MARC record formatting from the LCCN.}
                    if $emit_warnings;
            } elsif ( $input =~ m/#/ ) {
                carp
                    qq{LCCN input "$input" contains "#" characters, which are sometimes used as placeholders for spaces Please remove the "#" characters from the LCCN input.}
                    if $emit_warnings;
            } elsif ( $input =~ m/^\s*(_[a-z])\b\s*/ ) {
                carp
                    qq{LCCN input "$input" starts with "$1", which may be MARC formatting. Please remove any such formatting from the LCCN.}
                    if $emit_warnings;
            } else {
                carp qq{LCCN input "$input" cannot be parsed.}
                    if $emit_warnings;
            }

            return;
        }

        my $req_prefix_length = ( $out{lccn_structure} eq 'A' ? 3 : 2 );

        # fixup serial
        $out{serial} = sprintf '%06i', $out{serial};

        # fixup prefix
        if ( defined $out{prefix_encoded} ) {
            $out{prefix_encoded} =~ s/^\s+|\s+$//;
            $out{prefix_encoded} = lc $out{prefix_encoded};
            unless ( length $out{prefix_encoded} == $req_prefix_length ) {
                $out{prefix_encoded} .= ' '
                    x ( $req_prefix_length - length $out{prefix_encoded} );
            }

            $out{prefix} = $out{prefix_encoded};
            $out{prefix} =~ s/\s+//g;
        }

        # fixup suffix
        if ( !defined $out{suffix_encoded} ) {
            $out{suffix_encoded} = '';
        }

        # fixup revision year
        if ( !defined $out{revision_year_encoded} ) {
            $out{revision_year_encoded} = '';
        }

        $next->( $self, \%out );
    }
};

sub _canonical {
    my $self = shift;
    if ( $self->lccn_structure eq 'B' ) {
        return
            sprintf( "%- 2s%4i%06i",
                     $self->prefix, $self->year_encoded, $self->serial );
    } elsif ( $self->lccn_structure eq 'A' ) {
        my $string =
            sprintf( "%- 3s%02i%06i %s",
                     $self->prefix, $self->year_encoded,
                     $self->serial, $self->suffix_encoded
            );

        if ( length $self->revision_year_encoded ) {
            if ( !length $self->suffix_encoded ) {
                $string .= '/';
            }
            $string .= '/r' . $self->revision_year_encoded;
            if ( $self->revision_number ) {
                $string .= $self->revision_number;
            }
        }

        return $string;
    } else {    # should never get here
        return '';
    }
}

no Moose;       # remove Moose keywords

# normalize documented at http://www.loc.gov/marc/lccn-namespace.html
# and http://lccn.loc.gov/lccnperm-faq.html
sub _normalized {
    my $self = shift;
    my $string = join '', $self->prefix, $self->year_encoded, $self->serial;
    $string =~ s/[\s-]//g;
    return $string;
}

# permalink syntax documented at http://lccn.loc.gov/lccnperm-faq.html
sub _permalink {
    my $self = shift;
    return URI->new( 'http://lccn.loc.gov/' . $self->normalized );
}

# info: uri syntax documented at http://www.loc.gov/standards/uri/info.html
sub _info_uri {
    my $self = shift;
    return URI->new( 'info:lccn/' . $self->normalized );
}

sub _overload_string {
    my $self = shift;
    return $self->canonical;
}

sub _overload_equality {
    my ( $self, $other ) = @_;

    my $other_lccn;
    if ( ref($other) and blessed($other) and $other->isa('Business::LCCN') ) {
        $other_lccn = $other;
    } else {
        $other_lccn = new Business::LCCN($other);
    }

    if ( !defined $other_lccn ) {
        return 0;
    } else {
        return ( $self->normalized eq $other_lccn->normalized );
    }
}

# returns a list of all the suffix alphabetic identifiers
sub _suffix_alphabetic_identifiers {
    my $self = shift;
    if ( length $self->{suffix_encoded} ) {
        my @identifiers = $self->suffix_encoded =~ m{\b([A-Z]+)\b};
        return \@identifiers;
    } else {
        return [];
    }
}

sub _verify_7_checksum {
    my ( $year_encoded, $serial ) = @_;
    unless (     $year_encoded =~ m/^\d{2}$/
             and $serial =~ m/^\d{6}$/ ) {
        return 0;
    }

    my @year_digits   = split //, $year_encoded;
    my @serial_digits = split //, $serial;

    my $product
        = $year_digits[0] * 7 
        + $year_digits[1] * 8 
        + $serial_digits[0] * 4
        + $serial_digits[1] * 6
        + $serial_digits[2] * 3
        + $serial_digits[3] * 5
        + $serial_digits[4] * 2
        + $serial_digits[5] * 1;

    if ( $product % 11 == 0 ) {
        return 1;
    } else {
        return 0;
    }
}

=head1 INTERFACE

=head2 Methods

=head3 C<new>

The new method takes a single encoded LCCN string, in a variety of
formats -- with or without hyphens, with proper spacing or without.
Examples:

    "89-1234", "89-001234", "89001234", "2002-1234", "2002-001234",
    "2002001234", "   89001234 ", "  2002001234", "a89-1234",
    "a89-001234", "a89001234", "a2002-1234", "a2002-001234",
    "a2002001234", "a  89001234 ", "a 2002001234", "ab98-1234",
    "ab98-001234", "ab98001234", "ab2002-1234", "ab2002-001234",
    "ab2002001234", "ab 98001234 ", "ab 2002001234", "abc89-1234",
    "abc89-001234", "abc89001234", "abc89001234 ", permalinks URLs
    like "http://lccn.loc.gov/2002001234" and info URIs like
    "info:lccn/2002001234"

Returns a Business::LCCN object, or undef if the string can't be
parsed as a valid LCCN. If the string can't be parsed, C<new> will
warn with a diagnostic message explaining why the string was invalid.

C<new> can also take an optional hashref of options as a second
parameter. The only option supported is C<no_warnings>, which will
disable any diagnostic warnings explaining why a candidate LCCN string
was invalid:

    # returns undef, issues warning about input not containing any digits
    $foo = LCCN->new('x');

    # returns undef, but does not issue any additional warning
    $bar = LCCN->new( 'x', { no_warnings => 1 } );

=head3 LCCN attributes

=head3 C<lccn_structure>

LCCN structure type, either "A" (issued 1898-2000) or "B" (issued
2001-).

=head3 C<prefix>

LCCN's alphabetic prefix, 1-3 characters long. Returns an empty string
if LCCN has no prefix.

=head3 C<prefix_encoded>

The prefix as encoded, either two (structure A) or three (structure B)
characters long, space-padded.

=head3 C<year_cataloged>

The year a book was cataloged. Returns an undef in cases where the
cataloging year in unclear. For example, LCCN S<"   75425165 //r75">
has a cataloged year of 1975.

=head3 C<year_encoded>

A two (structure A) or four (structure B) digit string typically
representing the year the book was cataloged, but sometimes serving as
a checksum, or a source code. For example, LCCN S<"   75425165 //r75">
has an encoded year field of S<"75">.

=head3 C<serial>

A six-digit number zero-padded serial number. For example, LCCN
S<"   75425165 //r75"> has a serial number of S<"425165">.

=head3 C<suffix_alphabetic_identifiers>

Structure A LCCNs can include one or more 1-3 character
suffix/alphabetic identifiers. Returns a list of all identifiers
present. For example, for LCCN S<"   79139101 /AC/MN">,
suffix_alphabetic_identifiers returns ('AC', 'MN').

=head3 C<suffix_encoded>

The LCCN's suffix/alphabetic identifier field, as encoded in the LCCN.
Returns an empty string if no suffix present.

=head3 C<revision_year>

Structure A LCCNs can include a revision date in their
bibliographic records. Returns the four-digit year the record was
revised, or undef if not present. For example, LCCN
S<"   75425165 //r75"> has a revision year of 1975.

=head3 C<revision_year_encoded>

The two-letter revision date, as encoded in structure A LCCNs. Returns
an empty string if no revision year present. For example, LCCN
S<"   75425165 //r75"> has a revision year of C<"75">.

=head3 C<revision_number>

Some structure A LCCNs have a revision year and number,
representing the number of times the record has been revised. For
example, LCCN S<"   75425165 //r752"> has revision_number 2. Returns
undef if not present.

=head3 LCCN representations

=head3 C<canonical>

Returns the canonical 12+ character default representation of an
LCCN. For example, S<"   85000002 "> is the canonical representation of
S<"85000002">, S<"85-000002">, S<"85-2">, S<"   85000002">.

=head3 C<normalized>

Returns the normalized 9-12 character representation of an LCCN.
Normalized LCCNs are often used in URIs and Internet-era
representations. For example, S<"n2001050268"> is the normalized
representation of S<"n  85-000002 ">, S<"n85-2">, S<"n  85-0000002">.

=head3 C<info_uri>

Returns the info: URI for an LCCN. For example, the URI for LCCN
S<"n  85-000002 "> is S<"info:lccn/n85000002">.

=head3 C<original>

Returns the original representation of the LCCN, as passed to C<new>.

=head3 C<permalink>

Returns the Library of Congress permalink URL for an LCCN. For
example, the permalink URL for LCCN S<"n 85-000002 "> is
S<"http://lccn.loc.gov/n85000002">.

=head2 Operator overloading

=head3 C<"">

In string context, Business::LCCN objects stringify as the
canonical representation of the LCCN.

=head3 C<eq>, C<==>

Business::LCCN objects can be compared to other Business::LCCN
objects or LCCN strings.

=head1 SEE ALSO

L<Business::ISBN>, L<http://www.loc.gov/marc/lccn_structure.html>,
L<http://lccn.loc.gov/>,
L<http://www.loc.gov/standards/uri/info.html>,
L<http://en.wikipedia.org/wiki/Library_of_Congress_Control_Number>

=head1 DIAGNOSTICS

Running C<new> on invalid input may generate warnings, unless the
C<no_warnings> option is set.

=head1 AUTHOR

Anirvan Chatterjee, C<< <anirvan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-business-lccn at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-LCCN>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::LCCN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-LCCN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-LCCN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-LCCN>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-LCCN>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Anirvan Chatterjee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Business::LCCN

# Local Variables:
# mode: perltidy
# End:
