use Test::More;
use DB::CouchDB;

plan tests => 8;

my $module = 'DB::CouchDB::Iter';

can_ok($module, qw/new count data offset
                   err errstr
                   next/);

is($module->new(mk_result())->count(), 3,
    'count matches');
is($module->new(mk_result())->offset(), 0,
    'offset matches');
is_deeply($module->new(mk_result())->data(), mk_rows(),
    'data matches');

is_deeply($module->new(mk_result())->next(), mk_rows()->[0]{value}[0],
    'next returns first result');

is_deeply($module->new(mk_result())->next_for_key('bar'), mk_rows()->[1]{value}[0],
    'next_for_key returns first bar result');

is_deeply($module->new(mk_err())->err(), mk_err()->{error},
    'errors have an error');
is_deeply($module->new(mk_err())->errstr(), mk_err()->{reason},
    'errors have an errstr');

sub mk_result {
    return {total_rows => 3,
            offset     => 0,
            rows       => mk_rows()
           };
}

sub mk_rows {
    return [
            {id => 1, key => 'foo', value => [{foo => 'bar'},
                                              {bar => 'bar'},
                                              {bleh => 'blah'},
                                             ]},
            {id => 1, key => 'bar', value => [{foo1 => 'bar1'},
                                              {bar1 => 'bar1'},
                                              {bleh1 => 'blah1'},
                                             ]},
           ];
}

sub mk_err {
    return {error => 'foo error',
            reason => 'Ack!!! I just faked an error!',
           };
}
