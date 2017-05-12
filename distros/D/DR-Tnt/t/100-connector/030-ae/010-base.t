#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib t/lib);

use Test::More tests    => 35;
use Encode qw(decode encode);


BEGIN {
    use_ok 'DR::Tnt::Client::AE';
    use_ok 'DR::Tnt::Test';
    use_ok 'AnyEvent';
    tarantool_version_check(1.6);
}


my $ti = start_tarantool
    -lua    => 't/100-connector/lua/easy.lua';
isa_ok $ti => DR::Tnt::Test::TntInstance::, 'tarantool';

diag $ti->log unless
    ok $ti->is_started, 'test tarantool started';

sub LOGGER {
    my ($level, $message) = @_;
    return unless $ENV{DEBUG};
    my $now = POSIX::strftime '%F %T', localtime;
    note "$now [$level] $message";
}

my $c = DR::Tnt::Client::AE->new(
    host            => 'localhost',
    port            => $ti->port,
    user            => 'testrwe',
    password        => 'test',
    logger          => \&LOGGER,
    hashify_tuples  => 1,
);

isa_ok $c => DR::Tnt::Client::AE::, 'connector created';
for (+note 'ping') {

    for my $cv (AE::cv) {
        $cv->begin;
        $c->ping(sub {
            my ($res) = @_;
            is $res => 1, 'ping';
            $cv->end;
        });

        $cv->recv;
    }
}
for (+note 'select and get') {

    for my $cv (AE::cv) {
        $cv->begin;
        
        $c->get('_space', 'primary', 280, sub {
            my ($tuple) = @_;
            isa_ok $tuple => "HASH", 'one tuple';
            is $tuple->{id}, 280, 'id';
            is $tuple->{name}, '_space', 'name';
            $cv->end;
        });
        
        $cv->recv;
    }


    for my $cv (AE::cv) {
        $cv->begin;
        
        $c->select('_space', 'primary', 280, sub {
            my ($tuples) = @_;
            is @$tuples, 1, 'one tuple';
            is $tuples->[0]{id}, 280, 'id';
            is $tuples->[0]{name}, '_space', 'name';
            $cv->end;
        });
        
        $cv->recv;
    }
}

for (+note 'insert') {
    for my $cv (AE::cv) {
        $cv->begin;
        
        $c->insert('test', [ 'ivan', 'petrov' ], sub {
            my ($tuple) = @_;
            isa_ok $tuple => 'HASH', 'tuple inserted';
            is_deeply $tuple => { name => 'ivan', value => 'petrov', tail => [] },
                'tuple';
            $cv->end;
        });
        
        $cv->recv;
    }
}


for (+note 'replace') {
    for my $cv (AE::cv) {
        $cv->begin;
        
        $c->replace('test', [ 'ivan', 'sidorov', 123 ], sub {
            my ($tuple) = @_;
            isa_ok $tuple => 'HASH', 'tuple inserted';
            is_deeply $tuple =>
                { name => 'ivan', value => 'sidorov', tail => [ 123 ] },
                'tuple';
            $cv->end;
        });
        
        $cv->recv;
    }
    
    for my $cv (AE::cv) {
        $cv->begin;
        
        $c->replace('test', [ 'vasya', 'sidorov' ], sub {
            my ($tuple) = @_;
            isa_ok $tuple => 'HASH', 'tuple replaced';
            is_deeply $tuple =>
                { name => 'vasya', value => 'sidorov', tail => [] },
                'tuple';
            $cv->end;
        });
        
        $cv->recv;
    }
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->get('test', 'name', 'vasya', sub {
            my ($tuple) = @_;

            isa_ok $tuple => 'HASH', 'tuple received';
            is_deeply $tuple =>
                { name => 'vasya', value => 'sidorov', tail => [] },
                'tuple';
            
            $cv->end;
        });
        
        $cv->recv;
    }
}

for (+note 'update') {

    for my $cv (AE::cv) {
        $cv->begin;
        $c->update('test', 'ivan', [ [ '=', 1, 'ivanov' ] ], sub {

            my ($tuple) = @_;

            isa_ok $tuple => 'HASH', 'tuple updated';
            is_deeply $tuple =>
                { name => 'ivan', value => 'ivanov', tail => [123] },
                'tuple';
            
            $cv->end;
        });
        
        $cv->recv;
    }


    for my $cv (AE::cv) {
        $cv->begin;
        $c->get('test', 'name', 'ivan', sub {
            my ($tuple) = @_;
            isa_ok $tuple => 'HASH', 'tuple received';
            is_deeply $tuple => { name => 'ivan', value => 'ivanov', tail => [123] },
                'tuple';
                
                $cv->end;
        });
        
        $cv->recv;
    }
}


for (+note 'call_lua') {

    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->call_lua('rettest', sub {
            my ($tuples) = @_;
            isa_ok $tuples => 'ARRAY', 'tuple returned';
            is_deeply $tuples => [[ 'test' ]], 'tuples';
                
            $cv->end;
        });
        
        $cv->recv;
    }
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->call_lua([ 'rettest' => 'test' ], sub {
            my ($tuples) = @_;
            isa_ok $tuples => 'ARRAY', 'tuple returned';
            is_deeply $tuples => [{ name => 'test', value => undef, tail => [] }], 'tuples';
                
            $cv->end;
        });
        
        $cv->recv;
    }
    
    for my $cv (AE::cv) {
        $cv->begin;
        $c->call_lua([ 'rettest' => 'test123' ], sub {
            my ($tuples) = @_;
            is $tuples => undef, 'unknown space';
            is $c->last_error->[0], 'ER_NOSPACE', 'ERROR CODE';
            $cv->end;
        });
        
        $cv->recv;
    }
    
}

for (+ note 'eval lua') {
    for my $cv (AE::cv) {
        $cv->begin;
    
        $c->eval_lua('return {"abc"}', sub {
            my ($tuples) = @_;
            isa_ok $tuples => 'ARRAY', 'tuple returned';
            is_deeply $tuples => [[ 'abc' ]], 'tuples';
            $cv->end;
        });
        $cv->recv;
    }
    for my $cv (AE::cv) {
        $cv->begin;
    
        $c->eval_lua(['return {"abc"}' => 'test'], sub {
            my ($tuples) = @_;
            isa_ok $tuples => 'ARRAY', 'tuple returned';
            is_deeply $tuples =>
                [{ name => 'abc', value => undef, tail => [] }], 'tuples';
            $cv->end;
        });
        $cv->recv;
    }
    
}
