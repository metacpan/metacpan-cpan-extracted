#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::License;
use CPANPLUS::Dist::Debora::Package;

use open ':std', ':encoding(utf8)';
use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 9;
}

use lib 't/inc';
use MockModule;
use MockPackage;

my $real_package
    = new_ok 'CPANPLUS::Dist::Debora::Package' => [module => MockModule->new];

my $package = MockPackage->new($real_package);
my $holder  = 'Ian Fraser Kilmister';

my $license = new_ok 'CPANPLUS::Dist::Debora::License' => [{
    package => $package,
    holder  => $holder,
}];

isnt $license->name,            q{}, 'name is not empty';
isnt $license->meta_name,       q{}, 'meta_name is not empty';
isnt $license->meta2_name,      q{}, 'meta2_name is not empty';
isnt $license->spdx_expression, q{}, 'spdx_expression is not empty';
isnt $license->license,         q{}, 'license is not empty';

ok !defined $license->url, 'url is not defined';
like $license->notice, qr{\b\Q$holder\E\b}xms, 'notice contains holder';
