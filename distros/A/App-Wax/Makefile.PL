use strict;
use warnings;

use lib '.';
use inc::Module::Install;

name           'App-Wax';
author         'chocolateboy <chocolate@cpan.org>';
license        'perl';
all_from       'lib/App/Wax.pm';
install_script 'bin/wax';
perl_version   '5.008008'; # LWP's minimum
repository     'https://github.com/chocolateboy/App-Wax';
bugtracker     'https://github.com/chocolateboy/App-Wax/issues';

requires 'Digest::SHA';
requires 'File::BaseDir'              => '0.07';
requires 'File::Slurp'                => '9999.19';
requires 'HTTP::Message'              => '6.11';
requires 'IPC::System::Simple'        => '1.25';
requires 'LWP'                        => '6.26';
requires 'Method::Signatures::Simple' => '1.07';
requires 'MIME::Types'                => '2.13';
requires 'Mouse'                      => 'v2.4.9';
requires 'Parallel::parallel_map'     => '0.02';
requires 'Try::Tiny'                  => '0.28';
requires 'URI'                        => '1.71';

recommends 'Sereal' => '3.015';

test_requires 'Test::Differences' => '0.64';
test_requires 'Test::Fatal'       => '0.014';

# the latest version (0.05) is not available:
# https://github.com/sukria/Test-TinyMocker/issues/8
test_requires 'Test::TinyMocker'  => '0.03';

WriteAll;
