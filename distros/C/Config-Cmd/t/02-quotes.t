#; -*- mode: CPerl;-*-
use Test::More tests => 4;
use Try::Tiny;

use Config::Cmd;


my $c = Config::Cmd->new(section=>'test');

is $c->quote, "'", 'default quote';
is $c->quote('"'), '"', 'double quote';

my @opts = ('-c', '-a', 'b', '--dd', 'ee ff');
is $c->set_silent(\@opts), 1, "set opts with white space". join ' ', @opts;
is $c->get(), '-c -a b --dd "ee ff"', "get with white space in opts";


END {
    unlink 'test_conf.yaml';
}
