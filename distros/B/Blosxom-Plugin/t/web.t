use strict;
use parent 'Blosxom::Plugin::Web';
use Test::More tests => 18;

my $class = __PACKAGE__;

isa_ok $class, 'Blosxom::Plugin';

can_ok $class, qw(
    request req
    get_data_section merge_data_section_into
);

my $req = $class->req;
isa_ok $req, 'Blosxom::Plugin::Web::Request';

my $request = $class->request;
isa_ok $request, 'Blosxom::Plugin::Web::Request';

is $req, $request;

SKIP: {
    skip 'Plugin.pm implements end()', 13;

    my @reserved_methods = qw(
        start       template entries filter skip
        interpolate head     sort    date   story
        foot        end      last
    );

    for my $method ( @reserved_methods ) {
        ok !$class->can( $method ), "'$method' is reserved";
    }
}

$class->end;
