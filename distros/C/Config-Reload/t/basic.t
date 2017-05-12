use v5.10;
use warnings;
use Test::More;
use Config::Reload;

my $c = Config::Reload->new( file => 't/data/valid.pl' );

if ($^O =~ /bsd$/) { # CPANT repots error on BSD systems
    use Data::Dumper;
    diag Dumper($c->load);
    diag $c->error;
}
is_deeply $c->load, { foo => 'bar' }, 'valid';
ok $c->loaded, 'has been loaded';
cmp_ok $c->checked, '<=', $c->loaded, 'has been checked';


# trigger an error
$c = Config::Reload->new( file => 't/data/invalid.pl' );

is_deeply $c->load, { }, 'empty hash reference on error';
is $c->loaded, undef, 'not loaded after error';
ok $c->error, 'error on load';

done_testing;
