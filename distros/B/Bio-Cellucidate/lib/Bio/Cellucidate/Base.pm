package Bio::Cellucidate::Base;

use Bio::Cellucidate;
use Bio::Cellucidate::Request;
use XML::Simple;
use HTTP::Headers;

our %CONTENT_TYPES = (
  'XML' => 'application/xml',
  'CSV' => 'text/csv',
  'KA'  => 'application/x-kappa',
  'M'   => 'text/x-matlab'
);

sub new {
    my $class = shift;
    my $self = bless({}, $class);
    $self;
}

sub client {
    my $self = shift;
    $self->{_client} = Bio::Cellucidate::Request->new($Bio::Cellucidate::CONFIG) unless $self->{_client};
    $self->{_client};
}

# $self->rest('GET', '/foos', 'xml');
sub rest {
    my $self = shift;
    my $method = shift;
    my $url = shift;
    my $format = shift || 'xml';
    my $body = shift || undef;
    my $header = shift || {};

    $self->client->request($method, $url, $body,  { %{$header}, %{$self->headers_for_rest($format)} });
}

sub headers_for_rest {
    my $self = shift;
    my $format = shift || 'xml';
    
    my $header = HTTP::Headers->new;
    $header->authorization_basic($Bio::Cellucidate::AUTH->{login}, $Bio::Cellucidate::AUTH->{api_key});
    return { 'Authorization'=> $header->{authorization}, 
             'Content-Type' => $CONTENT_TYPES{'XML'}, 
             'Accept' => $CONTENT_TYPES{uc($format)} };
}

sub content_type_for_format {
    my $self = shift;
    my $format = shift;
    $CONTENT_TYPES[$format];
}

# find({ name => foo }, 'xml')
sub find {
    my $self = shift;
    my $args = $self->args(shift);
    my $format = shift;
    my $query = $self->formulate_query($args);
    $self->rest('GET', $self->route . "/$query", $format)->processResponseAsArray($self->element);
}

sub get {
    my $self = shift;
    my $id = shift;
    my $format = shift;
    $self->rest('GET', $self->route . "/" . $id, $format)->processResponse;
}

sub update {
    my $self = shift;
    my $id = shift;
    my $data = $self->args(shift);
    my $format = shift;

    $self->rest('PUT', $self->route . "/" . $id, $format, XMLout($data, RootName => $self->element, NoAttr => 1))->processResponse;
}

sub create {
    my $self = shift;
    my $data = $self->args(shift);
    my $format = shift;
    $self->rest('POST', $self->route, $format, XMLout($data, RootName => $self->element, NoAttr => 1))->processResponse;
}

sub delete {
    die "Unimplemented!";
}

sub route {
    die "Override in subclass"; 
}

sub element {
    die "Override in subclass"; 
}

sub args {
    my $package = $_[0];
    my $args = {};
    if (ref $_[0] eq 'HASH') {
        $args = @_;
    } elsif (scalar @_ && scalar @_ % 2 == 0) {
        $args = { @_ };
    }
    return $args->{$package} if $package;
    $args;
}

sub formulate_query {
    my $args = args(@_);
    my $query = '';
    foreach my $key (keys %{$args}) { 
        $query = '?' if $query eq '';
        $query .= "$key=" . $args->{$key} . "&"; 
    }
    $query;
}

1;
