package App::PAIA::Tester;
use strict;
use v5.10;

our $VERSION = '0.30';

use parent 'Exporter';
our @EXPORT = (qw(
    new_paia_test done_paia_test paia_response paia_live
    paia PAIA debug
    stdout stderr output error exit_code
    stdout_json stderr_json output_json error exit_code
    ));

use Test::More;
use App::Cmd::Tester;
use File::Temp qw(tempdir);
use Cwd;
use App::PAIA;
use JSON::PP qw(encode_json);
use Scalar::Util qw(reftype);
use HTTP::Tiny;

our $CWD = getcwd();
our $RESULT;

sub decode_json {
    my $json = shift;
    $json =~ s/^#.*$//mg;
    JSON::PP::decode_json($json)
}

sub stdout_json() { decode_json($RESULT->stdout) }
sub stderr_json() { decode_json($RESULT->stderr) }
sub output_json() { decode_json($RESULT->output) }

## no critic
eval "sub $_() { \$RESULT->$_ }" for qw(stdout stderr output error exit_code);

our $HTTP_TINY_REQUEST = \&HTTP::Tiny::request;

our $DEFAULT_PSGI = [ 500, [], ["no response faked yet"] ];
our $PSGI_RESPONSE = $DEFAULT_PSGI;
our $HTTP_REQUEST = sub { $PSGI_RESPONSE };

sub mock_http {
    my ($self, $method, $url, $opts) = @_;
    my $psgi = $HTTP_REQUEST->(
        $method, $url, $opts->{headers}, $opts->{content}
    );
    return {
        protocol => 'HTTP/1.1',
        status   => $psgi->[0],
        headers  => { @{$psgi->[1]} },
        content  => join "", @{$psgi->[2]},
    };
};

sub paia_live() {
    no warnings;
    *HTTP::Tiny::request = $HTTP_TINY_REQUEST; 
}

sub new_paia_test(@) { ## no critic
    chdir tempdir;
    paia_live;
}

sub paia_response(@) { ## no critic
    $PSGI_RESPONSE = $DEFAULT_PSGI;
    if (ref $_[0] and reftype $_[0]  eq 'ARRAY') {
        $PSGI_RESPONSE = shift;
    } else {
        $PSGI_RESPONSE = $DEFAULT_PSGI;
        $PSGI_RESPONSE->[0] = $_[0] =~ /^\d+/ ? shift : 200;
        $PSGI_RESPONSE->[1] = shift if ref $_[0] and reftype $_[0] eq 'ARRAY' and @_ > 1;
        my $content = shift;
        if (reftype $content eq 'HASH') {
            push @{$PSGI_RESPONSE->[1]}, 'Content-type', 'application/json; charset=UTF-8';
            $PSGI_RESPONSE->[2] = [ encode_json($content) ];
        } elsif (reftype $_[1] eq 'ARRAY') {
            $PSGI_RESPONSE->[2] = $content;
        } else {
            $PSGI_RESPONSE->[2] = [$content];
        }
    }

    no warnings;
    *HTTP::Tiny::request = \&mock_http;
}

sub paia(@) { ## no critic
    $RESULT = test_app('App::PAIA' => [@_]);
}

sub PAIA($) { ## no critic
    my @args = split /\s+/, shift;
    say join ' ', '# paia', @args;
    paia(@args);
}

sub done_paia_test() {
    chdir $CWD;
    done_testing;
}

sub debug {
    say "# $_" for split "\n", join "\n", (
        "stdout: ".$RESULT->stdout,
        "stderr: ".$RESULT->stderr,
        "error: ".$RESULT->error // 'undef',
        "exit_code: ".$RESULT->exit_code
    );
}

1;
__END__

=head1 NAME

App::PAIA::Tester - facilitate PAIA testing

=head1 SYNOPSIS

    use Test::More;
    use App::PAIA::Tester;

    new_paia_test;

    # call with list
    paia qw(config base http://example.org/);

    # call with string and print call
    PAIA "config base http://example.org/";
    
    is error, undef;

    paia qw(config);
    is_deeply stdout_json, {
        base => 'http://example.org/'
    };

    paia qw(login -u alice -p 1234);
    is stderr, '';
    is exit_code, 0;

    my $token = stdout_json->{access_token};
    ok $token;
    note "token: $token";

    done_paia_test;

=head1 DESCRIPTION

The module implements a simple a singleton wrapper around L<App::Cmd::Tester>
to facilitate writing tests for and with the paia client L<App::PAIA>. 

=head1 FUNCTIONS

=over

=item C<paia>

Execute L<paia> with arguments given as list.

=item C<PAIA>

Execute L<paia> with arguments given as string and print the call before
execution.

=item C<new_paia_test>

Start a new test by changing into a new empty temporary directory and enabling
C<paia_live>.

=item C<done_paia_test> 

Finish testing and print a summary.

=item C<paia_response>

Set a mocked HTTP result to return for all following paia requests.

=item C<paia_live>

Disable HTTP request mocking.

=item C<stdout>

Return the output sent to STDOUT by last paia execution.

=item C<stderr>

Return the output sent to STDERR by last paia execution.

=item C<stderr>

Return the combined output sent to STDOUT and STDERR by last paia execution.

=item C<stdout_json>

Decode C<stdout>, stripping lines starting with C<#>, as JSON.

=item C<stderr_json>

Decode C<stderr>, stripping lines starting with C<#>, as JSON.

=item C<output_json>

Decode C<output>, stripping lines starting with C<#>, as JSON.

=item C<exit_code>

Return the exit code of last paia execution (C<0> on success).

=item C<error>

Return the exception thrown by last paia execution.

=item C<debug>

Print C<stdout>, C<stderr>, C<error>, and C<exit_code>.

=back

=cut
