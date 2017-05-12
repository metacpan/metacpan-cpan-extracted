#; -*- mode: CPerl;-*-
use Test::More tests => 22;
use Try::Tiny;

use Config::Cmd;

sub test_input {
    my $c = shift;
    my @opts = @_;

    my $opts = join ' ', @opts;

    $opts =~ s/ *= */ /g;
    $opts =~ s/sss //g; # keys without dash are ignored
    is $c->set_silent(\@opts), 1, "set_silent $opts";
    is $c->get, $opts, "get $opts";
}

my $c = Config::Cmd->new;
is ref($c), 'Config::Cmd', 'new';
is $c->section, undef, 'section';
try {
    test_input($c, qw'-a b');
} catch {
    like $_, qr/Set section/, 'missing section value';
};

is $c->section('test'), 'test', 'section';
is $c->section, 'test', 'section';

test_input($c, qw'-a b');
test_input($c, qw'-a b -c');
test_input($c, qw'-a b -c --dd ee');
test_input($c, qw'-a b -c --dd=ee');
test_input($c, qw'-a=b -ccc --dd = ee');
test_input($c, qw'sss -a b -c --dd = ee');
test_input($c, qw'-c -a b --dd ee');

$c->filename('a_test.conf');
test_input($c, qw'-cc');
ok -e 'a_test.conf' , 'filename';

END {
    unlink 'test_conf.yaml';
    unlink 'a_test.conf';
}
