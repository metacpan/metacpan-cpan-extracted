use strict;
use warnings;
use Test::More tests => 13;
use lib 't/lib';
use DSCTest;

BEGIN { use_ok('DBIx::Class::DynamicSubclass') };

SKIP: {
    skip "requires DBD::SQLite && SQL::Translator for testing.", 12
        unless eval { require DBD::SQLite; require SQL::Translator; 1 };
    do_tests();
}

sub do_tests {

my $schema = DSCTest->init;
my $rss    = $schema->resultset('SourceStatic');
my $rsd    = $schema->resultset('SourceDynamic');

foreach my $row ([$rss, 'Static subclassing'], [$rsd, 'Dynamic subclassing']) {
    my ($rs, $what) = @$row;
    my $base = $rs->result_class;

    my $obj = $rs->new({type => undef});
    is ref($obj), "$base", "$what: new base";

    $obj = $rs->new({type => 1});
    is ref($obj), "$base\::Type1", "$what: new subclass";

    $obj->type(2);
    is ref($obj), "$base\::Type2", "$what: change type subclass";

    $obj->type(undef);
    is ref($obj), "$base", "$what: change type base";

    $obj->insert;

    $obj = $rs->single({id => $obj->id});
    is ref($obj), "$base", "$what: inflate_result base";

    $obj->update({type => 1});

    $obj = $rs->single({id => $obj->id});
    is ref($obj), "$base\::Type1", "$what: inflate_result subclass";
}

}

1;
