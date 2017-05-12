use 5.008000;
use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new
  (
   module_name => 'Crypt::Skip32',
   license  => 'perl',
   dist_author => 'Eric Hammond <eric-cpan-2@thinksome.com>',
   abstract => '32-bit block cipher based on Skipjack',
   requires => {
                'perl'               => '5.8.0',
               },
   build_requires => {
                'Test::More'         => '0.62',
                'Test::NoWarnings'   => '0.084',
               },
   recommends => {
                'Crypt::Skip32::XS' => 0,
                'Test::Distribution' => 0,
                'Crypt::CBC'         => '2.22',
               },
   create_readme => 1,
   create_makefile_pl => 'traditional',
   sign => 1,
   dynamic_config => 0,
   keywords => [
                'cryptography',
                'encryption',
                'decryption',
               ],
   resources => {
            BasedOn => 'http://www.qualcomm.com.au/PublicationsDocs/skip32.c',
                },
  );
$build->create_build_script;
