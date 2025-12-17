use Test2::V0;
use App::CpanDak::Specials;

subtest 'with env variable' => sub {
    local $ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';
    my $s = App::CpanDak::Specials->new();

    ok $s->match_for({ dist => 'Dak-Test' }, '.configure.env.yml'),
        'should find';
};

subtest 'with explicit argument' => sub {
    my $s = App::CpanDak::Specials->new('t/specials');

    ok $s->match_for({ dist => 'Dak-Test' }, '.configure.env.yml'),
        'should find';
};

subtest 'without anything' => sub {
    delete local $ENV{PERL_CPANDAK_SPECIALS_PATH};
    
    my $s = App::CpanDak::Specials->new();

    ok ! $s->match_for({ dist => 'Dak-Test' }, '.configure.env.yml'),
        'should not find';
};

done_testing;
