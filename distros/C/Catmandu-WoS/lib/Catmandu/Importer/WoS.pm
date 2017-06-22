package Catmandu::Importer::WoS;

use Catmandu::Sane;

our $VERSION = '0.01';

use MIME::Base64 qw(encode_base64);
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::Compile::Transport::SOAPHTTP;
use XML::LibXML::Simple qw(XMLin);
use Catmandu::WoS::WSDL;
use Catmandu::WoS::AuthWSDL;
use Moo;
use namespace::clean;

with 'Catmandu::Importer';

has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has query    => (is => 'ro', required => 1);
has session_id => (is => 'lazy');
has _init      => (is => 'lazy');
has _search    => (is => 'rwp');
has _retrieve  => (is => 'rwp');

sub _build_session_id {
    my ($self) = @_;

    my $wsdl = XML::Compile::WSDL11->new(Catmandu::WoS::AuthWSDL->xml);

    my $authenticate = $wsdl->compileClient(
        'authenticate',
        transport_hook => sub {
            my ($req, $trace) = @_;
            my $auth = 'Basic '
                . encode_base64(join(':', $self->username, $self->password));
            $req->header(Authorization => $auth);
            my $ua = $trace->{user_agent};
            $ua->request($req);
        }
    );

    undef $wsdl;

    my $res = $authenticate->();

    if ($res->{Fault}) {

        # TODO
    }

    $res->{parameters}{return};
}

sub _build__init {
    my ($self) = @_;
    my $session_id = $self->session_id;

    my $wsdl = XML::Compile::WSDL11->new(Catmandu::WoS::WSDL->xml);

    my $transport_hook = sub {
        my ($req, $trace) = @_;
        $req->header(Cookie => qq|SID="$session_id"|);
        my $ua = $trace->{user_agent};
        $ua->request($req);
    };

    $self->_set__search(
        $wsdl->compileClient('search', transport_hook => $transport_hook));
    $self->_set__retrieve(
        $wsdl->compileClient('retrieve', transport_hook => $transport_hook));

    undef $wsdl;

    1;
}

sub generator {
    my ($self) = @_;

    $self->_init;

    sub {
        state $recs = [];
        state $query_id;
        state $start = 1;
        state $limit = 100;
        state $total;

        if (!@$recs) {
            return if defined $total && $start > $total;

            my $res;

            if (defined $query_id) {
                $res = $self->_retrieve->(
                    queryId => $query_id,
                    retrieveParameters =>
                        {firstRecord => $start, count => $limit,}
                );
                $query_id = $res->{parameters}{return}{queryId}
                    if !$res->{Fault};
            }
            else {
                $res = $self->_search->(
                    queryParameters => {
                        databaseId    => 'WOS',
                        queryLanguage => 'en',
                        userQuery     => $self->query,
                    },
                    retrieveParameters =>
                        {firstRecord => $start, count => $limit,},
                );
            }

            if ($res->{Fault}) {

                # TODO
            }

            $total //= $res->{parameters}{return}{recordsFound};
            $start += $limit;

            my $xml
                = XMLin($res->{parameters}{return}{records}, ForceArray => 1);
            $recs = $xml->{REC};
        }

        shift @$recs;
        }
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Importer::WoS - Import Web of Science records

=head1 SYNOPSIS

    # On the command line

    $ catmandu convert WoS --username XXX -password XXX --query 'TS=(lead OR cadmium)' to YAML

    # In perl

    use Catmandu::Importer::WoS;
    
    my $wos = Catmandu::Importer::WoS->new(username => 'XXX', password => 'XXX', query => 'TS=(lead OR cadmium)');
    $wos->each(sub {
        my $record = shift;
        # ...
    });

=head1 AUTHOR

Nicolas Steenlant E<lt>nicolas.steenlant@ugent.beE<gt>

=head1 COPYRIGHT

Copyright 2017- Nicolas Steenlant

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
