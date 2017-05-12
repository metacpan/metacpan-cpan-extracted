use Test::More;
use strict;
use warnings;
use Scalar::Util qw(blessed);

BEGIN {
    if (eval 'use XML::Simple; 1'){
        plan tests => 5;
    } else {
        plan skip_all => 'XML::Simple not available';
        exit;
    }
}

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( VARS => {}, FILES => [qw(t/datasource.t)]);

$App::Mowyw::config{default}{include} = 't/';
$App::Mowyw::config{default}{postfix} = '';

is parse_str('[% bind a type:xml file:sample.xml root:item %]', \%meta),
    '',
    'bind returns empty string';

ok blessed $meta{VARS}{a}, 'Bound variable is a blessed ref';

my $reader = q{[% for i in a %]![%readvar i.foo%][%endfor%]};

is parse_str($reader, \%meta), '!bar1!bar2!bar3', 'retrieved data';
is parse_str($reader, \%meta), '!bar1!bar2!bar3', 'The same works again';

