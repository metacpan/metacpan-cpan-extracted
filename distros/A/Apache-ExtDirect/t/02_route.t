use strict;
use warnings FATAL => 'all';
no  warnings 'uninitialized';

use Test::More tests => 25;

use LWP::UserAgent;

BEGIN { use_ok 'Apache::ExtDirect::Router'; }

my $dfile = 't/data/extdirect/route';
my $tests = eval do { local $/; open my $fh, '<', $dfile; <$fh> } ## no critic
    or die "Can't eval $dfile: '$@'";

for my $test ( @$tests ) {
    my $name            = $test->{name};
    my $url             = $test->{plack_url};
    my $method          = lc $test->{method};
    my $upload          = $test->{upload};
    my $input_content   = $test->{input_content} || '';
    my $http_status_exp = $test->{http_status};
    my $content_regex   = $test->{content_type};
    my $expected_output = $test->{expected_content};

    my $ua = LWP::UserAgent->new(requests_redirectable => []);
    
    my $res = $ua->$method($url, @$input_content);

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

sub raw_post {
    my ($uri, $content) = @_;

    return [ content => $content ];
}

sub form_post {
    my ($uri, %fields) = @_;

    return [ [ %fields ] ];
}

sub form_upload {
    my ($uri, $files_ref, %fields) = @_;

    delete @fields{ qw/action method/ };

    my @files = map {;
                upload =>
                [
                    "t/data/files/$_", $_,
                    'Content-Type' => 'application/octet-stream',
                ]
              } @$files_ref;

    return [
        Content_Type => 'form-data',
        Content      => [
            %fields,
            @files,
        ],
    ];
}

