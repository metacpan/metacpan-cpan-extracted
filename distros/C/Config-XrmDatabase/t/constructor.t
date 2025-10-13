#! perl

use Test2::V0;

use Config::XrmDatabase;
use Config::XrmDatabase::Util ':constants';

my $db = Config::XrmDatabase->new(
    insert => {
        '*b.d' => 'v1',
        '*b'   => 'v1',
    },
);

is(
    $db->TO_HASH->{db},
    hash {
        field q{*} => hash {
            field 'b' => hash {
                field VALUE()       => 'v1';
                field MATCH_COUNT() => 0;
                field 'd'           => hash {
                    field VALUE()       => 'v1';
                    field MATCH_COUNT() => 0;
                    end;
                };
                end;
            };
            end;
        }
    },
);


done_testing;
