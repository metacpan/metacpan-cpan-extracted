package Mock::BasicPlus::Schema;
use DBIx::Skinny::Schema;
use DBIx::Skinny::Schema::ProxyTableRule;

install_table 'used_log' => schema {
    proxy_table_rule 'strftime', 'used_log_%Y%m';
    pk 'id';
    columns qw/
        id
        used_on
        count
    /;
};

1;
