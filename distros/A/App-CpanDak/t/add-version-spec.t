BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;
use App::CpanDak;

subtest 'module matching' => sub {
    is(App::CpanDak->_match_module('Foo','==1'),
        '==1',
        'string should always match');

    is(App::CpanDak->_match_module('Foo',{'*'=>'==1'}),
        '==1',
        'star should always match');

    is(App::CpanDak->_match_module('Foo',{'Foo'=>'==1'}),
        '==1',
        'module name should match');

    is(App::CpanDak->_match_module('Foo',{'Bar'=>'==1'}),
        undef,
        'different module name should not match');
};

my @diags;

my $mock = mock 'App::CpanDak' => (
    override => [
        _diag => sub { push @diags, $_[1] },
    ],
);

sub search_it {
    my $c = App::CpanDak->new();
    $c->parse_options();
    $c->setup_home;
    $c->init_tools;

    return $c->search_module(@_);
}

subtest 'no specials' => sub {
    @diags=();
    my $dist = search_it('App::CpanDak');

    like(
        $dist,
        { version => !string '0.0.1' },
        'should return the latest version',
    );

    is(\@diags, [], 'should not log diagnostics');
};

subtest 'with specials, no version' => sub {
    @diags=();
    local $ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';
    my $dist = search_it('App::CpanDak');

    like(
        $dist,
        { version => '0.0.1' },
        'should return the forced version',
    );

    is(\@diags, [
        match(qr{\bsearching again\b}),
    ], 'should log that it searches again');
};

subtest 'with specials, and version' => sub {
    @diags=();
    local $ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';
    my $dist = search_it('App::CpanDak','< 1.0.0');

    like(
        $dist,
        { version => '0.0.1' },
        'should return the forced version',
    );

    is(\@diags, [
        match(qr{\bsearching again\b}),
    ], 'should log that it searches again');
};

subtest 'with specials, and same version' => sub {
    @diags=();
    local $ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';
    my $dist = search_it('App::CpanDak','< 0.0.2');

    like(
        $dist,
        { version => '0.0.1' },
        'should return the forced version',
    );

    is(\@diags, [
        match(qr{\bno need to search\b}),
    ], 'should log that it will not search again');
};

subtest 'empty set' => sub {
    @diags=();
    local $ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';

    like dies { search_it('App::CpanDak','> 0.0.2') },
        match(qr{\billegal requirements\b}i),
        'should fail to find any acceptable version';

    # `satisfy_version` dies before we search again
    is(\@diags, [
        match(qr{\bchecking\b.+\bfailed\b}),
    ], 'should log that it failed');
};

done_testing;

