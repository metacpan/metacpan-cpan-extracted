package Mock::Basic::Schema;
use DBIx::Skinny::Schema;
use DBIx::Skinny::Schema::ProxyTableRule;

install_table 'access_log' => schema {
    proxy_table_rule 'strftime', 'access_log_%Y%m';

    pk 'id';
    columns qw/
        id
        accessed_on
        count
    /;
};

install_table 'error_log' => schema {
    proxy_table_rule 'sprintf', 'error_log_%s';

    pk 'id';
    columns qw/
        id
        errored_on
        count
    /;
};

install_table 'hogehoge_log' => schema {
    proxy_table_rule 'named_strftime', 'hogehoge_log_%Y%m', 'hogehoged_on';

    pk 'id';
    columns qw/
        id
        hogehoged_on
        count
    /;
};

install_table 'fugafuga_log' => schema {
    proxy_table_rule('keyword', 'fugafuga_log_<%04d:year><%02d:month>');

    pk 'id';
    columns qw/
        id
        hogehoged_on
        count
    /;
};

sub ranking_rule {
    my ($base, $type,) = @_;
    if ( $type !~ /^(daily|weekly|monthly)$/ ) {
        die "invalid type";
    }
    return "${base}_${type}";
}

install_table 'ranking' => schema {
    proxy_table_rule \&ranking_rule, "ranking";

    pk 'id';
    columns qw/
        id
        rank
        count
        ranked_on
    /;
};

1;
