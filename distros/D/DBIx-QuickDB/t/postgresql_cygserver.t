use Test2::V0 -target => 'DBIx::QuickDB::Driver::PostgreSQL';

# The real probe only means something on Cygwin; the lab covers that. Here the
# probe is mocked to check viable() reports it on Cygwin and nowhere else.
my $has_shm;
my $mock = mock $CLASS => (override => [_cygwin_has_shm => sub { $has_shm }]);

sub reasons {
    my ($os) = @_;
    local $^O = $os;
    my ($ok, $why) = $CLASS->viable({bootstrap => 1});
    return $why // '';
}

$has_shm = 0;
like(reasons('cygwin'), qr/cygserver/, 'Cygwin without shared memory names cygserver');
unlike(reasons('linux'), qr/cygserver/, 'other platforms never run the probe');

$has_shm = 1;
unlike(reasons('cygwin'), qr/cygserver/, 'Cygwin with shared memory is not refused for it');

done_testing;
