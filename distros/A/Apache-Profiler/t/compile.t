use strict;
use Test::More;

if (eval { require mod_perl }) {
    plan tests => 1;
    use_ok 'Apache::Profiler';
}
elsif (eval { require mod_perl2 }) {
    plan tests => 1;
    use_ok 'Apache2::Profiler';
}
else {
    plan skip_all => 'could not load mod_perl';
}
