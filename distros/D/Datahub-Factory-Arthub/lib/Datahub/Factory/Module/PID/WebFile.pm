package Datahub::Factory::Module::PID::WebFile;

use Datahub::Factory::Sane;
use Moo;
use Catmandu;

use LWP::UserAgent;
use URI::Split qw(uri_split);

with 'Datahub::Factory::Module::PID::File';


has url      => (is => 'ro', required => 1);
has username => (is => 'ro');
has password => (is => 'ro');
has realm    => (is => 'ro');

has client    => (is => 'lazy');
has file_name => (is => 'lazy');

sub _build_client {
    my $self = shift;
    my $lwp = LWP::UserAgent->new(
        agent => 'datahub/factory'
    );
    if (defined ($self->username) && $self->username ne '') {
        $lwp->credentials(
            $self->netloc($self->url),
            $self->realm,
            $self->username,
            $self->password
        );
    }
    return $lwp;
}

sub _build_file_name {
    my $self = shift;
    my @uri = uri_split($self->url);
    if ($uri[2] eq '') {
        return 'datahub-factory_pidfile';
    } else {
        my $safe_file_name = $uri[2];
        $safe_file_name =~ s/[^a-zA-Z0-9_.-]//gi;
        return $safe_file_name;
    }
}

sub get_file {
    my $self = shift;
    my $response = $self->client->get($self->url);
    if ($response->is_success) {
        return $response->content;
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->status_line,
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

sub _build_path {
    my $self = shift;
    my $file_name = sprintf('/tmp/%s', $self->file_name);
    open my $out_fh, '>', $file_name or Catmandu::Error->throw(sprintf('Failed to write to %s: %s', $file_name, $!));
    print $out_fh $self->get_file();
    close $out_fh;
    return $file_name;
}

1;