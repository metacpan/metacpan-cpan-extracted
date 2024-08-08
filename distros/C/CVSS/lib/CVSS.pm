package CVSS;

use feature ':5.10';
use strict;
use utf8;
use warnings;

use Carp     ();
use Exporter qw(import);

use constant DEBUG => $ENV{CVSS_DEBUG};

use CVSS::v2 ();
use CVSS::v3 ();
use CVSS::v4 ();

our @EXPORT = qw(encode_cvss decode_cvss cvss_to_xml);

our $VERSION = '1.12';
$VERSION =~ tr/_//d;    ## no critic

my $CVSS_CLASSES = {'2.0' => 'CVSS::v2', '3.0' => 'CVSS::v3', '3.1' => 'CVSS::v3', '4.0' => 'CVSS::v4'};

sub encode_cvss { __PACKAGE__->new(@_)->to_string }
sub decode_cvss { __PACKAGE__->from_vector_string(shift) }

sub cvss_to_xml { @_ > 1 ? __PACKAGE__->new(@_)->to_xml : __PACKAGE__->from_vector_string(shift)->to_xml }

sub new {

    my ($class, %params) = @_;
    Carp::croak 'Missing CVSS version' unless $params{version};

    my $cvss_class = $CVSS_CLASSES->{$params{version}} or Carp::croak 'Unknown CVSS version';
    return $cvss_class->new(%params);

}

sub from_vector_string {

    my ($class, $vector_string) = @_;

    my %metrics    = split /[\/:]/, $vector_string;
    my $version    = delete $metrics{CVSS} || '2.0';
    my $cvss_class = $CVSS_CLASSES->{$version} or Carp::croak 'Unknown CVSS version';

    DEBUG and say STDERR "-- CVSS v$version -- Vector String: $vector_string";

    return $cvss_class->new(version => sprintf('%.1f', $version), metrics => \%metrics,
        vector_string => $vector_string);

}

1;

__END__
=head1 NAME

CVSS - Perl extension for CVSS (Common Vulnerability Scoring System) 2.0/3.x/4.0

=head1 SYNOPSIS

  use CVSS;

  # OO-interface

  # Method 1 - Use params

  $cvss = CVSS->new(
    version => '3.1',
    metrics => {
        AV => 'A',
        AC => 'L',
        PR => 'L',
        UI => 'R',
        S => 'U',
        C => 'H',
        I => 'H',
        A => 'H',
    }
  );


  # Method 2 - Decode and parse the vector string

  use CVSS;

  $cvss = CVSS->from_vector_string('CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H');

  say $cvss->base_score; # 7.4


  # Method 3 - Builder

  use CVSS 

  $cvss = CVSS->new(version => '3.1');
  $cvss->attackVector('ADJACENT_NETWORK');
  $cvss->attackComplexity('LOW');
  $cvss->privilegesRequired('LOW');
  $cvss->userInteraction('REQUIRED');
  $cvss->scope('UNCHANGED');
  $cvss->confidentialityImpact('HIGH');
  $cvss->integrityImpact('HIGH');
  $cvss->availabilityImpact('HIGH');

  $cvss->calculate_score;


  # Common methods

  # Convert the CVSS object in "vector string"
  say $cvss; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H

  # Get metric value
  say $cvss->AV; # A
  say $cvss->attackVector; # ADJACENT_NETWORK

  # Get the base score
  say $cvss->base_score; # 7.4

  # Get all scores
  say Dumper($cvss->scores);

  # { "base"           => "7.4",
  #   "exploitability" => "1.6",
  #   "impact"         => "5.9" }

  # Get the base severity
  say $cvss->base_severity # HIGH

  # Convert CVSS in XML in according of CVSS XML Schema Definition
  $xml = $cvss->to_xml;

  # Convert CVSS in JSON in according of CVSS JSON Schema
  $json = encode_json($cvss);


  # exported functions

  use CVSS qw(decode_cvss encode_cvss)

  $cvss = decode_cvss('CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H');
  say $cvss->base_score;  # 7.4

  $vector_string = encode_cvss(version => '3.1', metrics => {...});
  say $cvss_string; # CVSS:3.1/AV:A/AC:L/PR:L/UI:R/S:U/C:H/I:H/A:H


=head1 DESCRIPTION

This module calculates the CVSS (Common Vulnerability Scoring System) scores
(basic, temporal, and environmental), convert the "vector string" and returns
the L<CVSS> object in JSON or XML.

The Common Vulnerability Scoring System (CVSS) provides a way to capture the
principal characteristics of a vulnerability and produce a numerical score
reflecting its severity. The numerical score can then be translated into a
qualitative representation (such as low, medium, high, and critical) to help
organizations properly assess and prioritize their vulnerability management
processes.

L<https://www.first.org/cvss/>


=head2 FUNCTIONAL INTERFACE

They are exported by default:

=over

=item $vector_string = encode_cvss(%params)

Converts the given CVSS params to "vector string". Croaks on error.

This function call is functionally identical to:

    $vector_string = CVSS->new(%params)->to_string;

=item $cvss = decode_cvss($vector_string)

Converts the given "vector string" to L<CVSS>. Croaks on error.

This function call is functionally identical to:

    $cvss = CVSS->from_vector_string($vector_string);

=item $xml = cvss_to_xml($vector_string)

Convert the given "vector string" to XML. Croaks on error.

This function call is functionally identical to:

    $xml = $cvss->to_xml;

=back

=head2 OBJECT-ORIENTED INTERFACE

=over

=item $cvss = CVSS->new(%params)

Creates a new L<CVSS> instance using the provided parameters (B<version>, B<metric>
or B<vector_string>) and returns the CVSS subclass that matches the selected CVSS
version (C<2.0>, C<3.0>, C<3.1> or C<4.0>):

  +--------------+----------+
  | CVSS version | Class    |
  +--------------+----------+
  | 2.0          | CVSS::v2 |
  | 3.0          | CVSS::v3 |
  | 3.1          | CVSS::v3 |
  | 4.0          | CVSS::v4 |
  +--------------+----------+

=item $cvss = CVSS->from_vector_string($vector_string);

Converts the given "vector string" to L<CVSS>. Croaks on error

=back

=head1 SEE ALSO

L<CVSS::Base>, L<CVSS::v2>, L<CVSS::v3>, L<CVSS::v4>

=over 4

=item [FIRST] CVSS Data Representations (L<https://www.first.org/cvss/data-representations>)

=item [FIRST] CVSS v4.0 Specification (L<https://www.first.org/cvss/v4.0/specification-document>)

=item [FIRST] CVSS v3.1 Specification (L<https://www.first.org/cvss/v3.1/specification-document>)

=item [FIRST] CVSS v3.0 Specification (L<https://www.first.org/cvss/v3.0/specification-document>)

=item [FIRST] CVSS v2.0 Complete Guide (L<https://www.first.org/cvss/v2/guide>)

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CVSS/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CVSS>

    git clone https://github.com/giterlizzi/perl-CVSS.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
