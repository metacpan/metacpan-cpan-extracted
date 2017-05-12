use strict;
use warnings FATAL => 'all';
no  warnings 'uninitialized';

use Test::More tests => 5;

use Apache::TestRequest qw(GET POST);

BEGIN { use_ok 'Apache::ExtDirect::API'; }

my $dfile = 't/data/extdirect/api';
my $tests = eval do { local $/; open my $fh, '<', $dfile; <$fh> } ## no critic
    or die "Can't eval $dfile: '$@'";

for my $test ( @$tests ) {
    my $name            = $test->{name};
    my $url             = $test->{plack_url};
    my $method          = $test->{method};
    my $input_content   = $test->{input_content} || '';
    my $http_status_exp = $test->{http_status};
    my $content_regex   = $test->{content_type};
    my $expected_output = $test->{expected_content};

    my $res = $method eq 'GET'  ? GET($url)
            : $method eq 'POST' ? POST($url, $input_content)
            :                     die "Unsupported method"
            ;

    if ( ok $res, "$name not empty" ) {
        my $content_type = $res->content_type();
        my $http_status  = $res->code;

        like $content_type, $content_regex,   "$name content type";
        is   $http_status,  $http_status_exp, "$name HTTP status";

        my $http_output  = $res->content();
        $http_output     =~ s/\s//g;
        $expected_output =~ s/\s//g;

        is $http_output, $expected_output, "$name content";
    };
};

