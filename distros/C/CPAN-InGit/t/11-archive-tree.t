use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use File::Temp;
use Git::Raw;
use CPAN::InGit;
use CPAN::InGit::ArchiveTree;
use v5.36;

#subtest version_checks => sub {
#   for (
#      [ '1'                  => [ '>=', '1' ] ],
#      [ '1.1'                => [ '>=', '1.1' ] ],
#      [ '1.01_01'            => [ '>=', '1.01_01' ] ],
#      [ '>1'                 => [ '>',  '1' ] ],
#      [ '<2'                 => [ '<',  '2' ] ],
#      [ '==20200101.1'       => [ '==', '20200101.1' ] ],
#      [ '>2,!=2.002,!=2.004' => [ '>', '2', '!=', '2.002', '!=', '2.004' ] ],
#   ) {
#      my ($str, $spec)= @$_;
#      is( CPAN::InGit::ArchiveTree->parse_version_requirement($str), $spec, "parse $str" );
#   }
#   
#   for (
#      [ '>1,>2'            => [ '>', '2' ] ],
#      [ '>=10.1,>=4.5,6'   => [ '>=', '10.1' ] ],
#      [ '==5.01_01,5,>4'   => [ '==', '5.01_01' ] ],
#   ) {
#      my ($str, $spec)= @$_;
#      is( CPAN::InGit::ArchiveTree->combine_version_requirements($str), $spec, "combine $str" );
#   }
#};

my $package_details_txt= <<'END';
File:         02packages.details.txt
URL:          http://www.cpan.org/modules/02packages.details.txt
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   PAUSE version 1.005
Line-Count:   9
Last-Updated: Wed, 19 Nov 2025 23:29:01 GMT

A1z::Html                          0.04  C/CE/CEEJAY/A1z-Html-0.04.tar.gz
A1z::HTML5::Template               0.22  C/CE/CEEJAY/A1z-HTML5-Template-0.22.tar.gz
A_Third_Package                   undef  C/CL/CLEMBURG/Test-Unit-0.13.tar.gz
AAA::Demo                         undef  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
AAA::eBay                         undef  J/JW/JWACH/Apache-FastForward-1.1.tar.gz
AAAA                              undef  P/PR/PRBRENAN/Data-Table-Text-20210818.tar.gz
AAAA::Crypt::DH                    0.06  B/BI/BINGOS/AAAA-Crypt-DH-0.06.tar.gz
AAAA::Mail::SpamAssassin          0.002  S/SC/SCHWIGON/AAAA-Mail-SpamAssassin-0.002.tar.gz
AAAAAAAAA                          1.01  M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz
END
my $AAAAAAAAA_meta= <<'END';
---
abstract: 'Aaaaaa aaaaa aa aaaaaa Aaaaa aaaa'
author:
  - 'Aaaaaaa A Aaaaaaa <schwern@pobox.com>'
build_requires: {}
configure_requires:
  A_Third_Package: 0.13
dynamic_config: 1
generated_by: 'Module::Build version 0.38, CPAN::Meta::Converter version 2.110930'
license: perl
meta-spec:
  url: http://module-build.sourceforge.net/META-spec-v1.4.html
  version: 1.4
name: AAAAAAAAA
provides:
  AAAAAAAAA:
    file: aaa/AAAAAAAAA.pm
    version: 1.00
resources:
  license: http://dev.perl.org/licenses/
version: 1.00
END

subtest package_details => sub {
   my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
   my $git_repo= Git::Raw::Repository->init($repodir, 1); # new bare repo in tmpdir
   note "repo at $repodir";

   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   $mtree->set_path('modules/02packages.details.txt', \$package_details_txt);
   $mtree->set_path('cpan_ingit.json', \q{{"corelist_perl_version":"5.016","default_import_sources":[]}});
   $mtree->commit("Add Package List", create_branch => 'test');
   
   my $atree= CPAN::InGit::ArchiveTree->new(
      parent => $cpan_repo,
      branch => Git::Raw::Branch->lookup($git_repo, 'test', 1),
   );
   is( $atree, object {
      call config => { corelist_perl_version => '5.016', default_import_sources => [] };
      call corelist_perl_version  => '5.016';
      call default_import_sources => [];
      call package_details => {
         last_update => object { call epoch => 1763594941; },
         by_module   => {
            'A1z::Html'                => ['A1z::Html'               ,  '0.04',  'C/CE/CEEJAY/A1z-Html-0.04.tar.gz' ],
            'A1z::HTML5::Template'     => ['A1z::HTML5::Template'    ,  '0.22',  'C/CE/CEEJAY/A1z-HTML5-Template-0.22.tar.gz' ],
            'A_Third_Package'          => ['A_Third_Package'         ,  undef ,  'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' ],
            'AAA::Demo'                => ['AAA::Demo'               ,  undef ,  'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' ],
            'AAA::eBay'                => ['AAA::eBay'               ,  undef ,  'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' ],
            'AAAA'                     => ['AAAA'                    ,  undef ,  'P/PR/PRBRENAN/Data-Table-Text-20210818.tar.gz' ],
            'AAAA::Crypt::DH'          => ['AAAA::Crypt::DH'         ,  '0.06',  'B/BI/BINGOS/AAAA-Crypt-DH-0.06.tar.gz' ],
            'AAAA::Mail::SpamAssassin' => ['AAAA::Mail::SpamAssassin',  '0.002', 'S/SC/SCHWIGON/AAAA-Mail-SpamAssassin-0.002.tar.gz' ],
            'AAAAAAAAA'                => ['AAAAAAAAA'               ,  '1.01',  'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' ],
         },
         by_dist     => {
            'C/CE/CEEJAY/A1z-Html-0.04.tar.gz' => [
               ['A1z::Html'               ,  '0.04',  'C/CE/CEEJAY/A1z-Html-0.04.tar.gz' ],
            ],
            'C/CE/CEEJAY/A1z-HTML5-Template-0.22.tar.gz' => [
               ['A1z::HTML5::Template'    ,  '0.22',  'C/CE/CEEJAY/A1z-HTML5-Template-0.22.tar.gz' ],
            ],
            'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' => [
               ['A_Third_Package'         ,  undef ,  'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' ],
            ],
            'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' => [
               ['AAA::Demo'               ,  undef ,  'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' ],
               ['AAA::eBay'               ,  undef ,  'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' ],
            ],
            'P/PR/PRBRENAN/Data-Table-Text-20210818.tar.gz' => [
               ['AAAA'                    ,  undef ,  'P/PR/PRBRENAN/Data-Table-Text-20210818.tar.gz' ],
            ],
            'B/BI/BINGOS/AAAA-Crypt-DH-0.06.tar.gz' => [
               ['AAAA::Crypt::DH'         ,  '0.06',  'B/BI/BINGOS/AAAA-Crypt-DH-0.06.tar.gz' ],
            ],
            'S/SC/SCHWIGON/AAAA-Mail-SpamAssassin-0.002.tar.gz' => [
               ['AAAA::Mail::SpamAssassin',  '0.002', 'S/SC/SCHWIGON/AAAA-Mail-SpamAssassin-0.002.tar.gz' ],
            ],
            'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' => [
               ['AAAAAAAAA'               ,  '1.01',  'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' ],
            ]
         },
      };
      call [ get_module_version => 'AAAAAAAAA' ] => '1.01';
      call [ get_module_version => 'AAAA' ]      => '20210818';
      call [ get_module_version => 'AAA' ]       => F;
      call [ has_module => 'AAAAAAAAA' ]      => T;
      call [ has_module => 'AAAAAAAAA', 1 ]   => T;
      call [ has_module => 'AAAAAAAAA', 2 ]   => F;
      call [ has_module => 'AAAA' ]           => T;
      call [ has_module => 'AAAA', 0 ]        => T;
      call [ has_module => 'AAAA', 99999999 ] => F;
      call [ has_module => 'AAA' ]            => F;
   }, 'ArchiveTree' );
};

subtest import_modules => sub {
   my $repodir= File::Temp->newdir(CLEANUP => $ENV{TEST_CPAN_MIRROR_INGIT_CLEANUP} // 1);
   my $git_repo= Git::Raw::Repository->init($repodir, 1); # new bare repo in tmpdir
   note "repo at $repodir";

   my $cpan_repo= CPAN::InGit->new(repo => $git_repo);
   my $mtree= CPAN::InGit::MutableTree->new(parent => $cpan_repo);
   $mtree->set_path('modules/02packages.details.txt', \$package_details_txt);
   $mtree->set_path('cpan_ingit.json', \'{}');
   $mtree->set_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz', \'Pretend this is a TAR archive');
   $mtree->set_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.meta',   \$AAAAAAAAA_meta);
   $mtree->set_path('authors/id/C/CL/CLEMBURG/Test-Unit-0.13.tar.gz', \'Pretend this is also a TAR archive');
   $mtree->commit("Mock CPAN mirror", create_branch => 'www_cpan_org');

   $cpan_repo->create_archive_tree('my_app', default_import_sources => ['www_cpan_org']);
   my $atree= $cpan_repo->get_archive_tree('my_app');
   is( $atree->package_details,
      {
         last_update => T,
         by_module   => {},
         by_dist     => {},
      },
      'initial package-less tree'
   );
   
   $atree->import_modules({ AAAAAAAAA => '>=1'});
   is( $atree->get_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz'),
      [ object { call content => 'Pretend this is a TAR archive'; }, 0100644 ],
      'Imported AAAAAAAAA-1.01.tar.gz'
   );
   ok( $atree->get_path('authors/id/M/MS/MSCHWERN/AAAAAAAAA-1.01.meta'),
      'Imported AAAAAAAAA-1.01.meta'
   );
   is( $atree->get_path('authors/id/C/CL/CLEMBURG/Test-Unit-0.13.tar.gz'),
      [ object { call content => 'Pretend this is also a TAR archive'; }, 0100644 ],
      'Imported C/CL/CLEMBURG/Test-Unit-0.13.tar.gz'
   );
   is( $atree->package_details,
      {
         last_update => T,
         by_module   => {
            'A_Third_Package'          => ['A_Third_Package'         ,  undef ,  'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' ],
            'AAAAAAAAA'                => ['AAAAAAAAA'               ,  '1.01',  'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' ],
         },
         by_dist     => {
            'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' => [
               ['A_Third_Package'         ,  undef ,  'C/CL/CLEMBURG/Test-Unit-0.13.tar.gz' ],
            ],
            'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' => [
               ['AAAAAAAAA'               ,  '1.01',  'M/MS/MSCHWERN/AAAAAAAAA-1.01.tar.gz' ],
            ]
         },
      },
      'package_details'
   );
};

done_testing;
