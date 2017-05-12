use Test::More;

# make sure "grep -r" is available on the system
eval "qx{grep -r -n -i foo *}";
plan skip_all => "System 'grep -r' required for FIXME search" if $@;
plan tests => 1;

my @fixme =
    grep { $_->[0] !~ m{(/fixme\.t|/.svn/|blib/|MANIFEST)} }
    map { [ split /:/, $_ ] }
    qx/grep -r -n -i xxx */,
    qx/grep -r -n -i fixme */;

is( scalar(@fixme), 0 ) or do {
    diag "found FIXME, file '$_->[0]', line $_->[1]" for @fixme;
};

