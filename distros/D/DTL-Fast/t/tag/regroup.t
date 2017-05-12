#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({
    'cities' => 
    [
        {'name' => 'Mumbai', 'population' => '19,000,000', 'country' => 'India'},
        {'name' => 'Calcutta', 'population' => '15,000,000', 'country' => 'India'},
        {'name' => 'New York', 'population' => '20,000,000', 'country' => 'USA'},
        {'name' => 'Chicago', 'population' => '7,000,000', 'country' => 'USA'},
        {'name' => 'Tokyo', 'population' => '33,000,000', 'country' => 'Japan'},
    ]
});


$template = DTL::Fast::Template->new( << '_EOT_' );
{% regroup cities by country as country_list %}{% for country in country_list %}
-{{ country.grouper }}
{% for item in country.list %} -{{ item.name }}: {{ item.population }}
{% endfor %}{% endfor %}
_EOT_

$test_string = <<'_EOT_';

-India
 -Mumbai: 19,000,000
 -Calcutta: 15,000,000

-USA
 -New York: 20,000,000
 -Chicago: 7,000,000

-Japan
 -Tokyo: 33,000,000

_EOT_

is( $template->render($context), $test_string, 'Simple regrouping');

$context = DTL::Fast::Context->new({
    'cities' => 
    [
        {'name' => 'Mumbai', 'population' => '19,000,000', 'country' => ['India', 'Europe']},
        {'name' => 'Calcutta', 'population' => '15,000,000', 'country' => ['India', 'Europe']},
        {'name' => 'New York', 'population' => '20,000,000', 'country' => ['USA', 'America']},
        {'name' => 'Chicago', 'population' => '7,000,000', 'country' => ['USA', 'America']},
        {'name' => 'Tokyo', 'population' => '33,000,000', 'country' => ['Japan', 'Asia']},
    ]
});


$template = DTL::Fast::Template->new( << '_EOT_' );
{% regroup cities by country.1 as country_list %}{% for country in country_list %}
-{{ country.grouper }}
{% for item in country.list %} -{{ item.name }}: {{ item.population }}
{% endfor %}{% endfor %}
_EOT_

$test_string = <<'_EOT_';

-Europe
 -Mumbai: 19,000,000
 -Calcutta: 15,000,000

-America
 -New York: 20,000,000
 -Chicago: 7,000,000

-Asia
 -Tokyo: 33,000,000

_EOT_

is( $template->render($context), $test_string, 'Regrouping with traversing');


done_testing();
