use Test::Most;

use lib 't/lib';

use_ok 'Test::Schema';

my $dsn    = "dbi:SQLite::memory:";
my $schema = Test::Schema->deploy_or_connect($dsn);

ok my $rs = $schema->resultset('A'), 'resultset';

ok my $row =
  $rs->create( { id => 1, foo => 'good', bar => 'ugly', baz => 'bad' } ),
  'create';

can_ok $row, qw/ is_good is_bad is_ugly good_bar coyote
   baz_est_bien baz_est_mal /;

ok $row->$_, $_ for (qw/ is_good coyote baz_est_mal /);
ok !$row->$_, $_ for (qw/ is_bad is_ugly good_bar baz_est_bien is_success is_fail /);

{
    local $@;
    eval slurp($INC{'Test/Schema/Result/A.pm'});
    is(my $exn = $@, '', 'reload a result class');
}

sub slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "Can't open $file for reading: $!\n";
    local $/;
    return <$fh>;
}

done_testing;
