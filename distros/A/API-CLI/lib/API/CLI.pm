# ABSTRACT: Generic Framework for REST API Command Line Clients
use strict;
use warnings;
use 5.010;
package API::CLI;

our $VERSION = '0.001'; # VERSION

use base 'App::Spec::Run::Cmd';

use URI;
use YAML::XS ();
use LWP::UserAgent;
use HTTP::Request;
use App::Spec;
use JSON::XS;
use API::CLI::Request;

use Moo;

has dir => ( is => 'ro' );
has openapi => ( is => 'ro' );

sub add_auth {
    my ($self, $req) = @_;
    my $appconfig = $self->read_appconfig;
    my $token = $appconfig->{token};
    $req->header(Authorization => "Bearer $token");
}

sub read_appconfig {
    my ($self) = @_;
    my $dir = $self->dir;
    my $appconfig = YAML::XS::LoadFile("$dir/config.yaml");
}

sub apicall {
    my ($self, $run) = @_;
    my ($method, $path) = @{ $run->commands };
    my $params = $run->parameters;
    my $opt = $run->options;
    if ($opt->{debug}) {
        warn __PACKAGE__.':'.__LINE__.": apicall($method $path)\n";
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$params], ['params']);
        warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$opt], ['opt']);
    }
    $path =~ s{(?::(\w+)|\{(\w+)\})}{$params->{ $1 // $2 }}g;
    if ($opt->{debug}) {
        warn __PACKAGE__.':'.__LINE__.": apicall($method $path)\n";
    }

    my $REQ = API::CLI::Request->from_openapi(
        openapi => $run->spec->openapi,
        method => $method,
        path => $path,
        options => $opt,
        parameters => $params,
        verbose => $opt->{verbose} ? 1 : 0,
    );

    $self->add_auth($REQ);

    if ($method =~ m/^(POST|PUT|PATCH|DELETE)$/) {
        my $data_file = $opt->{'data-file'};
        if (defined $data_file) {
            open my $fh, '<', $data_file or die "Could not open '$data_file': $!";
            my $data = do { local $/; <$fh> };
            close $fh;
            $REQ->content($data);
        }
    }

    my ($ok, $out, $content) = $REQ->request;
    if (defined $out) {
        unless ($ok) {
            $out = $run->error($out);
        }
        warn $out;
    }
    say $content;

}

1;

__END__

=pod

=head1 NAME

API::CLI - Generic Framework for REST API Command Line Clients

=head1 SYNOPSIS

    use API::CLI::App::Spec;

    package API::CLI::MetaCPAN;
    use base 'API::CLI';

    sub add_auth {
    }

    package main;

    my $appspec_file = "$Bin/../metacpancl-appspec.yaml";
    my $spec = API::CLI::App::Spec->read($appspec_file);
    my $runner = App::Spec::Run->new(
        spec => $spec,
        cmd => API::CLI::MetaCPAN->new(
            dir => "$ENV{HOME}/.githubcl",
        ),
    );
    $runner->run;

=head1 DESCRIPTION

This is an experimental first version.

With API::CLI you can create a simple commandline client for any
REST API which has an OpenAPI specification.

    # 1. parameter: owner
    # 2. parameter: repo
    % githubcl GET /repos/:owner/:repo perlpunk API-CLI-p5

The generated help will show all methods, endpoints, parameters and
options.

Query parameters are represented as command line options starting with
C<--q->:

    % metacpancl GET /pod/:module App::Spec --q-content-type text/x-pod
    =head1 NAME

    App::Spec - Specification for commandline apps
    ...

It can also generate shell tab completion:

     % metacpancl <TAB>
     GET   -- GET call
     POST  -- POST call
     help  -- Show command help

     % digitaloceancl GET /<TAB>
     /account       -- Account information
     /droplets      -- List all droplets
     /droplets/:id  -- Retrieve a droplet by id

     % metacpancl GET /pod/:module App::Spec --q-content-type text/<TAB>
     text/html        text/plain       text/x-markdown  text/x-pod

Bash users: Note that completion for options and parameters currently does not
work.



=head1 METHODS

=over 4

=item add_auth

=item apicall

=item dir

=item read_appconfig

=item openapi

=back

=head1 SEE ALSO

=over 4

=item L<https://github.com/APIs-guru/openapi-directory>

=item L<App::Spec> - Commandline Interface Framework

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
