use strict;
use warnings;
package CPAN::Testers::Common::Utils;
# ABSTRACT: Utility functions for CPAN Testers modules

our $VERSION = '0.003';

use Exporter ();
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw(
  nntp_to_guid
  guid_to_nntp
);
our %EXPORT_TAGS = (
  all => [@EXPORT_OK]
);

#--------------------------------------------------------------------------#
# NNTP <-> GUID
#--------------------------------------------------------------------------#

# Base GUID generated with:
# Data::UUID->new->create_from_name_str(
#   NameSpace_URL, "http://nntp.x.perl.org/group/perl.cpan.testers"
# );

# Lower case is canonical
my $base_guid = "ed372d00-b19f-3f77-b713-d32bba55d77f";

# strip leading zeros on extraction
my $nntp_re = qr{\A0*([0-9]{1,7})-b19f-3f77-b713-d32bba55d77f$};

sub nntp_to_guid {
  my ($nntp_id) = @_;
  my $guid = $base_guid;
  substr($guid, 0, 8, sprintf("%08d",$nntp_id)); # zero padded
  return $guid;
}

sub guid_to_nntp {
  my ($guid) = @_;
  my ($nntp_id) = $guid =~ $nntp_re;
  return $nntp_id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Testers::Common::Utils - Utility functions for CPAN Testers modules

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use CPAN::Testers::Common::Utils ':all';

    # NNTP ID <=> GUID mapping
    $guid    = nntp_to_guid( $nntp_id );
    $nntp_id = guid_to_nntp( $guid    );

=head1 DESCRIPTION

This module contains common utility functions for use by other CPAN Testers
modules

=head1 USAGE

=head2 Mapping NNTP IDs to GUIDs

Legacy CPAN Testers reports were sent via email and made available via an
NNTP group, C<perl.cpan.testers>.  Reports were 'indexed' by their NNTP ID.
The next generation of CPAN Testers uses a GUID URN to identify reports.

Old reports with an NNTP ID are mapped to GUIDs by replacing the first 8
hex characters of a common 'base GUID' with a zero-padded decimal
representation of the NNTP ID.

  XXXXXXXX-b19f-3f77-b713-d32bba55d77f

Such GUID URNs are visually distinctive and have the nice feature of
sorting earlier than second-generated report GUIDs based on a timestamp.

Two translation functions are provided for convenience.

=head3 nntp_to_guid

    $guid    = nntp_to_guid( $nntp_id );

Given a numeric NNTP ID, returns a standard string-form GUID.  (No range
checking is done.) Examples:

  nntp_to_guid( 51432   );  # 00051432-b19f-3f77-b713-d32bba55d77f
  nntp_to_guid( 6171265 );  # 06171265-b19f-3f77-b713-d32bba55d77f

=head3 guid_to_nntp

    $guid    = nntp_to_guid( $nntp_id );

Given a GUID string of the form described above, returns the decimal number
in the first 8 characters.  Examples:

  guid_to_nntp( '00051432-b19f-3f77-b713-d32bba55d77f' ); # 51432
  guid_to_nntp( '06171265-b19f-3f77-b713-d32bba55d77f' ); # 6171265

If the GUID string is not derived from the base GUID, this function 
returns C<undef>.

=head1 SEE ALSO

=over 4

=item *

L<Data::GUID::Any>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/cpan-testers/CPAN-Testers-Common-Utils/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/cpan-testers/CPAN-Testers-Common-Utils>

  git clone https://github.com/cpan-testers/CPAN-Testers-Common-Utils.git

=head1 AUTHOR

David A Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯

Lars Dɪᴇᴄᴋᴏᴡ 迪拉斯 <daxim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David A Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
