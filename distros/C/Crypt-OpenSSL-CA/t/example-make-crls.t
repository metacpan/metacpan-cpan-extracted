#!perl -w

use strict;
use warnings;
use Math::BigInt;

=head1 NAME

example-make-crls.t - Checks that L<examples/make-crls.t>
works and produces an RFC3280-valid certificate revocation lists.

=cut

use Test2::V0;

use Crypt::OpenSSL::CA::Test qw(run_perl_script_ok run_thru_openssl
                                dumpasn1_available run_dumpasn1
                                like_bigint certificate_chain_ok);

use File::Spec::Functions qw(catfile);

my $stdout = "";
run_perl_script_ok(catfile("examples", "make-crls.pl"),
                   \$stdout, "make-cert-chain.pl runs without errors");

my @crls =   $stdout =~ m/(-+BEGIN\ X509\ CRL-+$
                 .*?
                 ^-+END\ X509\ CRL-+$)/gmsx;
is(scalar(@crls), 2, "make-crls.pl produced 2 CRLs on standard output")
  or die "No point in testing anything else...";
my ($crlv2, $deltacrl) = @crls;

my $crl_serial = Math::BigInt->from_hex("deadbeef" x 5);

=head1 DESCRIPTION

In order for this test to succeed, the various decorations we set up
for the CRL must show up in C<openssl crl> or C<dumpasn1>.

=cut

{
  my ($crldump, $err) =
    run_thru_openssl($crlv2, qw(crl -noout -text));
  is($?, 0, "``openssl crl'' ran successfully")
    or die $err;

  like($crldump, qr/last update:.*2007/i);
  like($crldump, qr/next update:.*2057/i);
  like_bigint($crldump, $crl_serial);
  like($crldump, qr/CRL Number.*critical/i);
  # Right now OpenSSL cannot parse freshest CRL indicator:
  like($crldump, qr/deltacrl\.crl/);

  my %crlentries = parse_crl_entries($crldump);
  like($crlentries{"10"}, qr/Feb 12/, "revocation dates");
  like($crlentries{"11"}, qr/unspecified/i);
  like($crlentries{"12"}, qr/key.*compromise/i);
  like($crlentries{"12"}, qr/Invalidity Date/i);
  like($crlentries{"42"}, qr/hold/i);
}

=pod

=head2 Delta CRL tests

=cut

{
  my ($crldump, $err) =
    run_thru_openssl($deltacrl, qw(crl -noout -text));
  is($?, 0, "``openssl crl'' ran successfully on delta-CRL")
    or die $err;

  like($crldump, qr/last update:.*2007/i);
  like($crldump, qr/next update:.*2057/i);

  fail "CRL Number not found" unless $crldump =~ qr/CRL Number:.*critical.*\n\s*([0-9a-fx:]+)/i;
  like_bigint($1, $crl_serial + 1);
  fail "delta CRL not found" unless $crldump =~ qr/delta CRL.*critical.*\n\s*([0-9a-fx:]+)/i;
  like_bigint($1, $crl_serial);

  my %crlentries = parse_crl_entries($crldump);

  # As of version 0.9.8c, OpenSSL doesn't know about
  # reason "remove" (which is 8 in RFC3280 section 5.3.1):
  like($crlentries{"42"}, qr/remove|8/i);
  like($crlentries{"DEADBEEFDEAFF00F"}, qr/2007/i);
}

done_testing;

=head1 HELPER FUNCTIONS

=cut

sub parse_crl_entries {
  my ($crldump) = @_;
  my @crlentries = split m/Serial Number: /, $crldump;
  shift(@crlentries); # Leading garbage
  my %crlentries;
  for(@crlentries) {
    if (! m/^([0-9A-F]+)(.*)$/si) {
      fail("Incorrect CRL entry\n$_\n");
      next;
    }
    $crlentries{uc($1)} = $2;
  }
  return %crlentries;
}
