use strict;
use warnings;
use 5.20.0;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DateTime;
use experimental qw/postderef signatures/;

BEGIN {
    eval "use Test::mysqld"; if($@) {
        plan skip_all => 'Test::mysqld not installed';
    }
}

use Test::DBIx::Class
    -config_path => [qw/t etc test_fixtures/],
    -traits=>['Testmysqld'];

my $mysqld = Test::mysqld->new(auto_start => undef) or plan skip_all => $Test::mysqld::errstr;

fixtures_ok 'basic';

my $tests = [
    {
        name => 'not in',
        test => Book->except_titles('Silmarillion'),
        expected => ['me.title' => { -not_in => ['Silmarillion']}],
    },
    {
        name => 'column in relation',
        test => Author->_smooth__prepare_for_filter(country__name => 'Sweden'),
        expected => ['country.name' => 'Sweden'],
    },
    {
        name => "column in relation's relation",
        test => Book->_smooth__prepare_for_filter(book_authors__author__country__name => 'Sweden'),
        expected => ['country.name' => 'Sweden'],
    },
    {
        name => 'substring',
        test => Book->_smooth__prepare_for_filter('book_authors__author__country__name__substring(2, 4)' => 'wede'),
        expected => [ \[ 'SUBSTRING(country.name, 2, 4) =  ? ', 'wede' ] ],
    },
    {
        name => 'substring substring',
        test => Book->_smooth__prepare_for_filter('book_authors__author__country__name__substring(2, 4)__substring(1, 2)' => 'we'),
        expected => [ \[ 'SUBSTRING(SUBSTRING(country.name, 2, 4), 1, 2) =  ? ', 'we' ] ],
    },
    {
        name => 'lt',
        test => Book->_smooth__prepare_for_filter(book_authors__author__country__created_date_time__lt => '2020-01-01'),
        expected => [ 'country.created_date_time' => { '<' => '2020-01-01' } ],
    },
    {
        name => 'ident',
        test => Book->_smooth__prepare_for_filter(book_authors__author__country__name__ident => 'me.title'),
        expected => [ 'country.name' => { -ident => 'me.title' } ],
    }
];


for my $test (@{ $tests }) {
    my $got = $test->{'test'};
    my $expected = $test->{'expected'};
    my $name = $test->{'name'};

    if ($test->{'sub'}) {
        $test->{'sub'}->($name, $expected);
    }
    else {
        is_deeply $got, $expected, $name or diag explain $got;
    }
}

subtest substring => sub {
    my $filter = Country->filter('name__substring(2, 5)__substring(2, 2)' => 'ed');
    is $filter->count, 1, or diag explain $filter->as_query;
};

subtest datetime => sub {
    my $datetime = DateTime->new(year => 2020, month => 8, day => 20, hour => 12, minute => 32, second => 42, time_zone => 'UTC');

    my $got = Country->filter(created_date_time => $datetime)->count;
    is $got, 1, 'flatten datetime eq';

    $got = Country->filter(created_date_time__gt => $datetime)->count;
    is $got, 1, 'flatten datetime gt';

    $got = Country->filter(created_date_time__lte => $datetime)->count;
    is $got, 1, 'flatten datetime lte';

    $got = Country->filter(created_date_time__year => 2020)->count;
    is $got, 2, 'lookup year, exists';

    $got = Country->filter(created_date_time__year => 2019)->count;
    is $got, 0, 'lookup year, not exists';

    $got = Country->filter(created_date_time__year__gt => 2019)->count;
    is $got, 2, 'lookup year gt, exists';

    my $filter = Country->search({}, {
        '+select' => [{ year => 'me.created_date_time', -as => 'created_year' }],
        '+as' => ['created_year'],
        having => { created_year => 2020 },
    });
    my $as_query = $filter->as_query;
    #$got = $filter->count;
    is $filter->first->get_column('created_year'), 2020, 'search for year' or diag explain $as_query;

    #Country->filter(created_date_time__year => Column('created_year'))->count;
    #Country->annotate(created_year => Year('created_date_time'));
    #Country->search(undef, { '+columns' => [{ created_year => { year => 'created_date_time'}}]})
};

subtest like => sub {
    my $got = Country->filter(name__like => 'wede')->first->name;
    is $got, 'Sweden', 'like, exists';

    $got = Country->filter(name__like => 'Wede')->count;
    is $got, 0, 'like, not found with bad casing';

    my $filter = Country->filter('name__substring(2, 2)__like' => 'we');
    is $filter->count, 1, 'like and substring' or diag explain $filter->as_query;
};


#Book->annotate(country_year => Year('country.created_date_time'), 'country_created_date_time');
#Book->annotate(country_year => Func(Year => 'country.created_date_time'));

done_testing;
