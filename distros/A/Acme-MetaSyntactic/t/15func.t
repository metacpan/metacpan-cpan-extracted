use Test::More;
use strict;
use lib 't/lib';
use NoLang;
use Acme::MetaSyntactic;

plan tests => 2;

# the default list
no warnings;
my @names = metaname();
my %seen = map { $_ => 1 } @{$Acme::MetaSyntactic::foo::MultiList{en}};
ok( exists $seen{$names[0]}, "metaname" );

is_deeply(
    [ sort grep { /^meta\w+$/ } keys %:: ],
    [qw( metaname )],
    "Default exported function"
);

