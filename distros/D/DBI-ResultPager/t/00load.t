use Test;

BEGIN {plan tests => 3}

eval { require DBI::ResultPager; return 1; };
ok($@, '');
croak() if $@;

eval { require CGI; return 1; };
ok($@, '');
croak() if $@;

eval { require DBI; return 1; };
ok($@, '');
croak() if $@;

