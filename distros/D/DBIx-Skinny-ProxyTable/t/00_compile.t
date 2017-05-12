use strict;
use Test::LoadAllModules;

BEGIN {
    all_uses_ok(
        search_path => "DBIx::Skinny::ProxyTable",
        except => [],
    );
}
