use strict;
use warnings;
no  warnings 'uninitialized';

use Test::More tests => 21;

use LWP::UserAgent;

BEGIN { use_ok 'Apache::ExtDirect::EventProvider'; }

my $dfile = 't/data/extdirect/poll';
my $tests = eval do { local $/; open my $fh, '<', $dfile; <$fh> } ## no critic
    or die "Can't eval $dfile: '$@'";

for my $test ( @$tests ) {
    my $name            = $test->{name};
    my $url             = $test->{plack_url};
    my $method          = lc $test->{method};
    my $input_content   = $test->{input_content};
    my $http_status_exp = $test->{http_status};
    my $content_regex   = $test->{content_type};
    my $expected_output = $test->{expected_content};
    my $password        = $test->{password};

    my $password_file = '/tmp/apache-extdirect-password';

    if ( $password ) {
    
        open my $fh, '>', $password_file
            or BAIL_OUT "Can't open $password_file: $!\n";

        print $fh $password;
        close $fh;
    };

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

        is $http_output, $expected_output, "$name content"
            or diag explain $res;
    };

    unlink $password_file if $password;
};

exit 0;

sub raw_post {
    my $input = shift;

    use bytes;
    my $cgi_input = CGI::Test::Input::URL->new();
    $cgi_input->add_field('POSTDATA', $input);

    return $cgi_input;
}

sub form_post {
    my (%fields) = @_;

    use bytes;
    my $cgi_input = CGI::Test::Input::URL->new();
    for my $field ( keys %fields ) {
        my $value = $fields{ $field };
        $cgi_input->add_field($field, $value);
    };

    return $cgi_input;
}

sub form_upload {
    my ($files, %fields) = @_;

    my $cgi_input = CGI::Test::Input::Multipart->new();

    for my $field ( keys %fields ) {
        my $value = $fields{ $field };
        $cgi_input->add_field($field, $value);
    };

    for my $file ( @$files ) {
        $cgi_input->add_file_now("upload", "t/data/cgi-data/$file");
    };

    return $cgi_input;
}
