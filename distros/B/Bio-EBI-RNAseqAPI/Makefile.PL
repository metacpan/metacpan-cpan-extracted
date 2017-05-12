use strict;
use warnings;
use 5.10.0;

use inc::Module::Install;

all_from 'lib/Bio/EBI/RNAseqAPI.pm';

requires 'Moose'             => '2.1402';
requires 'MooseX::FollowPBP' => '0.05';
requires 'LWP::UserAgent'    => '6.06';
requires 'Log::Log4perl'     => '1.46';
requires 'JSON::Parse'       => '0.32';

auto_install;

WriteAll;

