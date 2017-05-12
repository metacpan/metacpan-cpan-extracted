# t/06-cfgexp.t
#
# vim: syntax=perl

BEGIN {
    use vars qw( $req_cm_err );
    eval 'require Config::Merge;';
    $req_cm_err = $@;
}

use Test::More tests => 3;

use strict;
use warnings;

my $cfgexp     = "$^X -Ilib bin/cfgver export";
my $gittestdir = qw( t/01-initdb.git );
my $gittestdir2 = qw( t/05-config-merge.git );
my $ver1 = '7dd8415a7e1cd131fba134c1da4c603ecf4974e2';
my $ver2 = 'a573e9bbcaeed0be9329b25e2831a930f5b656ca';
my $ver3 = '3b5047486706e55528a2684daef195bb4f9d0923';

if ( not -d $gittestdir ) {
    die "Test repo not found - did you run 01-initdb.t already?";
}

my $out_text_v1   = <<EOF;
group1.ldap.password:  secret
group1.ldap.uri:  ldaps://example.org
group1.ldap.user:  openxpki
group1.ldap1.password:  secret1
group1.ldap1.uri:  ldaps://example1.org
group1.ldap1.user:  openxpki1
group2.ldap.password:  secret
group2.ldap.uri:  ldaps://example.org
group2.ldap.user:  openxpki
group2.ldap2.password:  secret2
group2.ldap2.uri:  ldaps://example2.org
group2.ldap2.user:  openxpki2
EOF

my $out_text_v3   = <<EOF;
group1.ldap1.password:  secret1
group1.ldap1.uri:  ldaps://example1.org
group1.ldap1.user:  openxpki1
group2.ldap2.password:  secret2
group2.ldap2.uri:  ldaps://example2.org
group2.ldap2.user:  openxpkiA
group3.ldap.password:  secret3
group3.ldap.uri:  ldaps://example3.org
group3.ldap.user:  openxpki3
EOF

my $out_text_t2_v1 = <<EOF;
0
1
EOF

is( `$cfgexp --dbpath $gittestdir`,
    $out_text_v3, 'output of text format' );

is( `$cfgexp --dbpath $gittestdir --format text --version $ver1`,
    $out_text_v1, 'output of initial text' );

SKIP: {
    skip "Config::Merge not installed", 1 if $req_cm_err;
is( `$cfgexp --dbpath $gittestdir2 --format text db.hosts`,
    $out_text_t2_v1, 'output of array' );
}
