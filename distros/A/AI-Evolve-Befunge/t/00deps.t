#!/usr/bin/perl
use strict;
use warnings;
my $num_tests;
BEGIN { $num_tests = 0; };
use Test::More;

# main script deps
require_ok('Algorithm::Evolutionary::Wheel');
require_ok('aliased');
require_ok('base');
require_ok('Carp');
require_ok('Class::Accessor::Fast');
require_ok('Cwd');
require_ok('File::Basename');
require_ok('File::Temp');
require_ok('IO::File');
require_ok('Language::Befunge');
require_ok('Language::Befunge::Storage::Generic::Vec::XS');
require_ok('Language::Befunge::Vector::XS');
require_ok('LWP::UserAgent');
require_ok('Parallel::Iterator');
require_ok('Perl6::Export::Attrs');
require_ok('Task::Weaken');
require_ok('strict');
require_ok('Test::Exception');
require_ok('Test::Harness');
require_ok('Test::MockRandom');
require_ok('Test::More');
require_ok('Test::Output');
require_ok('UNIVERSAL::require');
require_ok('warnings');
BEGIN { $num_tests += 24 };

# migration deps
require_ok('IO::Select');
require_ok('IO::Socket::INET');
require_ok('POSIX');
BEGIN { $num_tests += 3 };

# web dependencies
#require_ok('Catalyst');
#require_ok('Catalyst::Controller');
#require_ok('Catalyst::Helper');
#require_ok('Catalyst::View::MicroMason');
#require_ok('Catalyst::Test');
#require_ok('File::Find');
#require_ok('File::Path');
#require_ok('HTML::Entities');
#require_ok('WebService::Validator::HTML::W3C');
#require_ok('XML::XPath');
#BEGIN { $num_tests += 10 };


BEGIN { plan tests => $num_tests };
