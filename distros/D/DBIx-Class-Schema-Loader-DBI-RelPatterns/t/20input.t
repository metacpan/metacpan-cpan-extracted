use strict;
use warnings;
use Test::More tests => 2 * 9 + 2;
use Test::Exception;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

foreach my $arg (qw/rel_constraint rel_exclude/) {
    lives_ok {
        make_schema(loader_class => 1, quiet => 1, $arg => []);
    } "no exception thrown when empty arrayref is provided for $arg";
    
    lives_ok {
        make_schema(loader_class => 1, quiet => 1, $arg => [ '' => '' ]);
    } "no exception thrown when empty scalar is provided for $arg\'s element";
    
    lives_ok {
        make_schema(loader_class => 1, quiet => 1, $arg => [ [] => [] ]);
    } "no exception thrown when empty arrayref is provided for $arg\'s element";
    
    lives_ok {
        make_schema(loader_class => 1, quiet => 1, $arg => [ {} => {} ]);
    } "no exception thrown when empty hashref is provided for $arg\'s element";
    
    throws_ok {
        make_schema(loader_class => 1, $arg => qr/(.+)id$/);
    } qr/Invalid type Regexp/, "exception thrown when invalid type Regexp is provided for $arg";
    
    throws_ok {
        make_schema(loader_class => 1, $arg => {});
    } qr/Invalid type HASH/, "exception thrown when invalid type HASH is provided for $arg";
    
    throws_ok {
        make_schema(loader_class => 1, $arg => sub {});
    } qr/Invalid type CODE/, "exception thrown when invalid type CODE is provided for $arg";

    throws_ok {
        make_schema(loader_class => 1, $arg => [ {} => sub {} ]);
    } qr/Invalid type CODE/, "exception thrown when invalid type CODE is provided for $arg\'s element";
    
    throws_ok {
        make_schema(loader_class => 1, $arg => [ qr/(.+)id$/ ]);
    } qr/odd number of elements/, "exception thrown when number of elements provided for $arg is odd";
}

throws_ok {
    make_schema(loader_class => 1, rel_constraint => [ {type=>'similar'} => {} ]);
} qr/right-hand side/, "exception thrown when 'type' is on the wrong side";

throws_ok {
    make_schema(loader_class => 1, rel_constraint => [ {diag=>1} => {} ]);
} qr/right-hand side/, "exception thrown when 'diag' is on the wrong side";
