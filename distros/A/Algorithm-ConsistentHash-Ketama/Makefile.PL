use inc::Module::Install;

name 'Algorithm-ConsistentHash-Ketama';
all_from 'lib/Algorithm/ConsistentHash/Ketama.pm';
auto_set_repository;

if (! cc_available()) {
    warn "no compiler available";
    exit 1;
}

test_requires 'Test::More', 0.84;
test_requires 'Test::Requires';
use_ppport;
cc_warnings;
cc_src_paths 'xs';

author_tests 'xt';

WriteAll;