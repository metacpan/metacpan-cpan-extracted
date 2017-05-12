use strict;
use warnings;

use Test::More tests => 3;
use App::PAUSE::Comaint::PackageScanner;

my $scanner = App::PAUSE::Comaint::PackageScanner->new('http://cpanmetadb.plackperl.org');

my @packages = $scanner->find('App::PAUSE::Comaint');
is @packages, 2;
is_deeply \@packages, [qw/App::PAUSE::Comaint App::PAUSE::Comaint::PackageScanner/];

@packages = $scanner->find('NotExistModule');
is @packages, 0;
