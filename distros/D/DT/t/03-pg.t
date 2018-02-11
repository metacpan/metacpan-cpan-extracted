use Test::More;

use DT;
eval "use DateTime::Format::Pg";

if ( $@ ) {
    plan skip_all => "DateTime::Format::Pg is required";
    exit 0;
}

plan tests => 7;

eval { DT->import(':pg') };
is $@, '', "import :pg no exception";

my $dt = eval { DT->new('2018-02-07 21:22:09.58343-08') };
is $@, '', "new with timestamp_tz no exception";
is $dt->epoch, 1518067329, "pg timestamp_tz value";

my $timestamp_notz = eval { $dt->pg_timestamp_notz };

is $@, '', "pg_timestamp_notz() no exception";
is $timestamp_notz, '2018-02-07 21:22:09.583430000', "pg_timestamp_notz() value";

my $timestamp_tz = eval { $dt->pg_timestamp_tz };
is $@, '', "pg_timestamp_tz() no exception";
is $timestamp_tz, '2018-02-07 21:22:09.583430000-0800', "pg_timestamp_tz() value";
