use strict;
use warnings;
use inc::Module::Install 0.91;

name 'Catalyst-Plugin-Cache-HTTP-Preempt';
all_from 'lib/Catalyst/Plugin/Cache/HTTP/Preempt.pm';

requires 'Catalyst::Utils';
requires 'DateTime';
requires 'English';
requires 'HTTP::Headers::ETag';
requires 'HTTP::Status' => 6.03;
requires 'List::Util';
requires 'Moose::Role';
requires 'Readonly';
requires 'version' => 0.77;

recommends 'Readonly::XS';

test_requires 'Catalyst::Runtime';
test_requires 'DateTime::Format::HTTP';
test_requires 'Digest::MD5';
test_requires 'FindBin';
test_requires 'HTTP::Request::Common';
test_requires 'ok';
test_requires 'Test::WWW::Mechanize::Catalyst';
test_requires 'Test::More' => '0.88';
test_requires 'URI';

tests_recursive 't';

# resources repository => 'git://somewhere.com/myproject.git';

# If inc/.author directory exists...

if ($Module::Install::AUTHOR) {

    requires 'File::Find';
    requires 'Perl::MinimumVersion';
    requires 'Pod::Readme';
    requires 'Test::CheckManifest';
    requires 'Test::Perl::Critic';
    requires 'Test::Pod::Coverage' => '1.04';
    requires 'Test::Pod' => '1.14';
    requires 'Test::PureASCII';
    requires 'Test::Synopsis';

    tests_recursive 'xt';

    system("pod2readme lib/Catalyst/Plugin/Cache/HTTP/Preempt.pm")
        and die $!;
}

WriteAll();
