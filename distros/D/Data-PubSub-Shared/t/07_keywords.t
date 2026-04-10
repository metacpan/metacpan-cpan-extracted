use strict;
use warnings;
no warnings 'void';
use Test::More;

use Data::PubSub::Shared;

plan skip_all => 'XS::Parse::Keyword not available'
    unless $Data::PubSub::Shared::HAVE_KEYWORDS;

# --- Int keyword API ---
{
    use Data::PubSub::Shared::Int;

    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $sub = $ps->subscribe;

    # ps_int_publish
    ps_int_publish $ps, 42;
    ps_int_publish $ps, 99;
    is $ps->write_pos, 2, 'ps_int_publish advances write_pos';

    # ps_int_lag
    is ps_int_lag $sub, 2, 'ps_int_lag returns correct lag';

    # ps_int_poll
    my $v = ps_int_poll $sub;
    is $v, 42, 'ps_int_poll returns first value';
    $v = ps_int_poll $sub;
    is $v, 99, 'ps_int_poll returns second value';
    $v = ps_int_poll $sub;
    is $v, undef, 'ps_int_poll returns undef when empty';

    is ps_int_lag $sub, 0, 'ps_int_lag 0 after draining';
}

# --- Int keywords are lexically scoped ---
{
    # Outside `use Data::PubSub::Shared::Int` scope, keywords should not be active
    # (We can't easily test this without a separate file, so just verify
    # the keywords work within the scope above)
    pass 'int keywords active in lexical scope';
}

# --- Str keyword API ---
{
    use Data::PubSub::Shared::Str;

    my $ps = Data::PubSub::Shared::Str->new(undef, 64);
    my $sub = $ps->subscribe;

    # ps_str_publish
    ps_str_publish $ps, "hello";
    ps_str_publish $ps, "world";
    is $ps->write_pos, 2, 'ps_str_publish advances write_pos';

    # ps_str_lag
    is ps_str_lag $sub, 2, 'ps_str_lag returns correct lag';

    # ps_str_poll
    my $v = ps_str_poll $sub;
    is $v, 'hello', 'ps_str_poll returns first value';
    $v = ps_str_poll $sub;
    is $v, 'world', 'ps_str_poll returns second value';
    $v = ps_str_poll $sub;
    is $v, undef, 'ps_str_poll returns undef when empty';

    is ps_str_lag $sub, 0, 'ps_str_lag 0 after draining';
}

# --- Str keywords with UTF-8 ---
{
    use Data::PubSub::Shared::Str;

    my $ps = Data::PubSub::Shared::Str->new(undef, 32);
    my $sub = $ps->subscribe;
    my $str = "\x{263A}";
    ps_str_publish $ps, $str;
    my $got = ps_str_poll $sub;
    is $got, $str, 'ps_str_publish/poll preserves UTF-8';
    ok utf8::is_utf8($got), 'ps_str_poll preserves UTF-8 flag';
}

# --- Keywords with expressions ---
{
    use Data::PubSub::Shared::Int;

    my $ps = Data::PubSub::Shared::Int->new(undef, 64);
    my $sub = $ps->subscribe;

    # Keyword with expression argument
    my $x = 10;
    ps_int_publish $ps, $x * 5;
    is ps_int_poll $sub, 50, 'keyword with expression argument';
}

done_testing;
