package Bio::Cellucidate::Request;

use base REST::Client;
use XML::Simple;

sub processResponse {
    my $self = shift;
    die "No content!" unless (my $content = $self->responseContent);
    unless ($self->responseCode eq '200') {
        die "Invalid Request! Response Code: " . $self->responseCode . "\n" . $content;
    }
    if ($self->responseHeader('Content-Type') =~ /.*application\/xml.*/) {
        return eval { XMLin($content, ForceArray => 0, KeepRoot => 0, KeyAttr => [], NoAttr => 1, SuppressEmpty => undef) };
    } else {
        return $content;
    }
}

sub processResponseAsArray {
    my $self = shift;
    my $key = shift;
    
    my $response_data = $self->processResponse->{$key} if $self->processResponse;

    return [] unless $response_data;
    return ref($response_data) eq 'ARRAY' ? $response_data : [ $response_data ]; 
}


sub _xbuildUseragent {
    my $self = shift;

    return if $self->getUseragent();

    my $ua = LWP::UserAgent->new;
    $ua->agent("Bio::Cellucidate::Request/$Bio::Cellucidate::VERSION");
    $self->setUseragent($ua);

    return;
}

1;
