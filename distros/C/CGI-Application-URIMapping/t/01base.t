#! /usr/bin/perl

use Test::More tests => 20;

use strict;
use warnings;

BEGIN {
    use_ok('CGI::Application::URIMapping', ':all');
};

package T::URIMapping;

use base qw/CGI::Application::URIMapping/;

package T::App;

use base qw/CGI::Application/;

package T::App::Page1;

use base qw/T::App/;

T::URIMapping->register('page1');

package main;

my $dt_target = $CGI::Application::URIMapping::dispatch_table{'T::URIMapping'};
my $dt_expected = {
    '*' => [],
};

push @{$dt_expected->{'*'}},
    page1 => {
        app => 'T::App::Page1',
        rm  => 'page1',
    };

is_deeply($dt_target, $dt_expected);
undef $@;
eval {
    is(ref(T::App::Page1->uri_mapping()), 'HASH');
};
ok(! $@);
is(T::App::Page1->build_uri(),
   'http://localhost/page1');
is(T::App::Page1->build_uri({ protocol => 'https' }),
   'https://localhost/page1');
is(T::App::Page1->new(QUERY => CGI->new(''))->validate_uri(),
   URI_IS_PERMALINK);
is(T::App::Page1->new(QUERY => CGI->new('a='))->validate_uri(),
   URI_UNKNOWN_PARAM);

package T::App::Page2;

use base qw/T::App/;

T::URIMapping->register({
    protocol => 'https',
    path     => 'page2',
    query    => [ qw/n1 n2/ ],
});

package main;

push @{$dt_expected->{'*'}},
    page2 => {
        app => 'T::App::Page2',
        rm  => 'page2',
    };
is_deeply($dt_target, $dt_expected);
is(T::App::Page2->build_uri(),
   'https://localhost/page2');
is(T::App::Page2->build_uri([ CGI->new('n3=c&n2=b&n1=a') ]),
   'https://localhost/page2?n1=a&n2=b');
is(T::App::Page2->build_uri([ { n1 => 'test&get' } ]),
   'https://localhost/page2?n1=test%26get');

package T::App::Page3;

use base qw/T::App/;

T::URIMapping->register({
    path  => 'page3/:p1/:p2?/:p3?',
    query => [
        qw/q1 q2/,
        { name => 'q3', omit => 'd3' },
    ],
});

package main;

push @{$dt_expected->{'*'}},
    'page3/:p1/:p2?/:p3?' => {
        app => 'T::App::Page3',
        rm  => 'page3',
    };
is_deeply($dt_target, $dt_expected);
undef $@;
eval {
    T::App::Page3->build_uri();
};
ok($@);
is(T::App::Page3->build_uri([ { p1 => 'pone' } ]),
   'http://localhost/page3/pone');
is(T::App::Page3->build_uri([ { p1 => 'pone', p2 => 'ptwo', q1 => 'abc', bogus => 'hoge' } ]),
   'http://localhost/page3/pone/ptwo?q1=abc');
is(T::App::Page3->new(QUERY => CGI->new('q1=a&q2=b&q3=c'))->validate_uri(),
   URI_IS_PERMALINK);
is(T::App::Page3->new(QUERY => CGI->new('p2=a'))->validate_uri(),
   URI_PATH_PARAM_IN_QUERY);
is(T::App::Page3->new(QUERY => CGI->new('q3=c&q2=b&q1=a'))->validate_uri(),
   URI_PARAM_NOT_IN_ORDER);
is(T::App::Page3->new(QUERY => CGI->new('q1=a&q2=b&q3=d3'))->validate_uri(),
   URI_OMITTABLE_PARAM);
