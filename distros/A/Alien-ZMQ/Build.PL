use warnings FATAL => 'all';
use strict;

use lib 'inc';
use File::Path qw/make_path/;
use My::Build;

# prevent warnings about missing share directory
make_path("share");

my $builder = My::Build->new(
      'build_requires' => {
    'Module::Build' => '0.40',
    'Test::More' => '0'
  },
  'configure_requires' => {
    'Archive::Tar' => '1.00',
    'ExtUtils::CBuilder' => '0.280205',
    'IPC::Run' => '0',
    'LWP::Simple' => '0',
    'Module::Build' => '0.40'
  },
  'requires' => {
    'String::ShellQuote' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
      'dist_abstract' => 'find and install libzmq, the core zeromq library',
  'dist_name' => 'Alien-ZMQ',
  'license' => 'perl',
      'dist_author' => [
    'Charles McGarvey <ccm@cpan.org>'
  ],
    dist_version_from => "lib/Alien/ZMQ.pm",
    share_dir => "share",
);
$builder->notes('zmq-version', '3.2.4');
$builder->notes('zmq-sha1', '08303259f08edd1faeac2e256f5be3899377135e');

$builder->create_build_script;
