#!perl -T

=pod

Tests our translation (mapping) of CPAN names to package names.
Tests CPAN version to package version translation.

=cut

use warnings;
use strict;

use Test::More;

BEGIN {
    use_ok( 'CPANPLUS::Dist::Arch', qw(:all) );
}

my %pkgname_of =
    ( '-Crazy-CPAN_Name-'  => 'perl-crazy-cpan-name',
      'AT-END-IS-PERL'    => 'perl-at-end-is-perl',
      'Perl-At-Beginning' => 'perl-perl-at-beginning',
      'Middle-Perl-Here'  => 'perl-middle-perl-here',

      'crazy~!@#$%^&*()_+{}|/\<>:"/' => 'perl-crazy',
      'Many-!!-$$-Hyphens'           => 'perl-many-hyphens',
      '-!_?-Leading-Hyphens'         => 'perl-leading-hyphens',

      # Make sure real names work, too...
      'CPANPLUS-Dist-Arch'       => 'perl-cpanplus-dist-arch',
      'SWIFT-Factory-Tag-Tag17A' => 'perl-swift-factory-tag-tag17a',
      'Data-Dumper'              => 'perl-data-dumper',

      # An interesting conflict, mentioned by xenoterracide...
      'Perl-Version'             => 'perl-perl-version',
      'version'                  => 'perl-version',

      # Test overridden names
      'libwww-perl'       => 'perl-libwww',
      'mod_perl'          => 'mod_perl',
      'glade-perl-two'    => 'perl-glade-two',
      'aceperl'           => 'perl-ace',
      'Perl-Critic'       => 'perl-critic',
      'Perl-Tidy'         => 'perl-tidy',

      # You probably shouldn't use dist_pkgname for perl itself...
      'perl'              => 'perl',
     );

for my $cpan_name ( keys %pkgname_of ) {
    is( dist_pkgname($cpan_name),
        $pkgname_of{$cpan_name},
        "CPAN to pacman name translation of $cpan_name" );
}

my %pkgver_of =
    ( '1234-5678'  => '1234.5678',
      # Everything after the last underscore is removed.
      '!1_@23-45'  => '1',
      '98 65 AB.2' => '9865.2',
      '1~!@#$%^&*() 2+= - 3\][{}|;":,_ . 4/?><' => '12.3',
      '1234-ABCDE.fghi' => '1234',
      '1.14_02'    => '1.14',
      '12ABCD_ABCD1' => '12',
      '10.01.07.b610f5f' => '10.01.07.6105', # real!
     );

for my $cpan_ver ( keys %pkgver_of ) {
    is( dist_pkgver($cpan_ver),
        $pkgver_of{$cpan_ver},
        "CPAN to pacman version translation of $cpan_ver" );
}

# Also test conversion of decimal perl version strings.

my %perlpkgver_of =
    ( '5.006001' => '5.6.1',
      '5.6.1'    => '5.6.1',
      '5.012001' => '5.12.1',
      '5.01234'      => '5.12.340',   # accept missing trailing zeros
      '5.0123456789' => 5.0123456789, # not 6 decimals? pass through
      '.012345'  => '.012345',        # must have a major ver number
      'v5.8.0'   => '5.8.0',
      '5.v8.0'   => '5.v8.0'
     );

*_perl_ver = *CPANPLUS::Dist::Arch::_transperlver;

while ( my ($decimal, $dotdecimal) = each %perlpkgver_of ) {
    is( _perl_ver( $decimal ), $dotdecimal,
        "Conversion of perl version $decimal" );
}

done_testing
