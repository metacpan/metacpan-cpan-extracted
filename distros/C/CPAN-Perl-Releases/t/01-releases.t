use strict;
use warnings;
use Test::More qw[no_plan];
use CPAN::Perl::Releases qw[perl_tarballs perl_versions perl_pumpkins];

my $perl = '5.14.0';

my $expected = {
 "tar.bz2" => "J/JE/JESSE/perl-5.14.0.tar.bz2",
 "tar.gz" => "J/JE/JESSE/perl-5.14.0.tar.gz"
};

{
  my $got = perl_tarballs( $perl );
  is_deeply( $got, $expected, 'Imported function' );
}

{
  my $got = CPAN::Perl::Releases::perl_tarballs( $perl );
  is_deeply( $got, $expected, 'Package Function' );
}

{
  my $got = CPAN::Perl::Releases->perl_tarballs( $perl );
  is_deeply( $got, $expected, 'Class method' );
}

{
  my $got = perl_tarballs( '6.0.0' );
  ok( !$got, 'Should not have this release' );
}

my @versions = perl_versions();

ok (grep(/^5.6.1$/, @versions), "has 5.6.1");
ok (grep(/^5.18.0$/, @versions), "has 5.18.0");
ok (grep(/^5.19.0$/, @versions), "has 5.19.0");

my @pumpkins = perl_pumpkins();

ok (grep(/^BINGOS$/, @pumpkins), "has BINGOS");
ok (grep(/^JESSE$/, @pumpkins), "has JESSE");
ok (!grep(/^LWALL$/, @pumpkins), "canz delegatez");
