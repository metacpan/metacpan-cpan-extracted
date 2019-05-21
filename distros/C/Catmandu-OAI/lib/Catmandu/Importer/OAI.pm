package Catmandu::Importer::OAI;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Scalar::Util qw(blessed);
use HTTP::OAI;
use Carp;
use Catmandu::Error;
use URI;

our $VERSION = '0.19';

with 'Catmandu::Importer';

has url                    => (is => 'ro', required => 1);
has identifier             => (is => 'ro');
has metadataPrefix         => (is => 'ro', default => sub { "oai_dc" });
has set                    => (is => 'ro');
has from                   => (is => 'ro');
has until                  => (is => 'ro');
has resumptionToken        => (is => 'ro');

has strict                 => (is => 'ro');

has identify               => (is => 'ro');
has listIdentifiers        => (is => 'ro');
has listRecords            => (is => 'ro');
has listSets               => (is => 'ro');
has listMetadataFormats    => (is => 'ro');
has getRecord              => (is => 'ro');

has oai                    => (is => 'ro', lazy => 1, builder => 1);
has dry                    => (is => 'ro');
has handler                => (is => 'rw', lazy => 1 , builder => 1, coerce => \&_coerce_handler );
has xslt                   => (is => 'ro', coerce => \&_coerce_xslt );
has max_retries            => ( is => 'ro', default => sub { 0 } );
has _retried               => ( is => 'rw', default => sub { 0; } );
has _xml_handlers          => ( is => 'ro', default => sub { +{} } );
has realm                  => ( is => 'ro', predicate => 1 );
has username               => ( is => 'ro', predicate => 1 );
has password               => ( is => 'ro', predicate => 1 );

sub _build_handler {
    my ($self) = @_;
    if ($self->metadataPrefix eq 'oai_dc') {
        return 'oai_dc';
    }
    elsif ($self->metadataPrefix eq 'marcxml') {
        return 'marcxml';
    }
    elsif ($self->metadataPrefix eq 'mods') {
        return 'mods';
    }
    else {
        return 'struct';
    }
}

sub _coerce_handler {
  my ($handler) = @_;

  return $handler if is_invocant($handler) or is_code_ref($handler);

  if (is_string($handler) && !is_number($handler)) {
      my $class = $handler =~ /^\+(.+)/ ? $1
        : "Catmandu::Importer::OAI::Parser::$handler";

      my $handler;
      eval {
          $handler = Catmandu::Util::require_package($class)->new;
      };
      if ($@) {
        croak $@;
      } else {
        return $handler;
      }
  }

  return sub { return { _metadata => readXML($_[0]) } };
}

sub _coerce_xslt {
  eval {
    Catmandu::Util::require_package('Catmandu::XML::Transformer')
      ->new( stylesheet => $_[0] )
  } or croak $@;
}

sub _build_oai {
    my ($self) = @_;
    my $agent = HTTP::OAI::Harvester->new(baseURL => $self->url, resume => 0, keep_alive => 1);
    if( $self->has_username && $self->has_password ) {
        my $uri = URI->new( $self->url );
        my @credentials = (
            $uri->host_port,
            $self->realm || undef,
            $self->username,
            $self->password
        );
        $agent->credentials( @credentials );
    }
    $agent->env_proxy;
    $agent;
}

sub _xml_handler_for_node {
    my ( $self, $node ) = @_;
    my $ns = $node->namespaceURI();

    my $type;

    if( $ns eq "http://www.openarchives.org/OAI/2.0/oai_dc/" ){

        $type = "oai_dc";

    }
    elsif( $ns eq "http://www.loc.gov/MARC21/slim" ){

        $type = "marcxml";

    }
    elsif( $ns eq "http://www.loc.gov/mods/v3" ){

        $type = "mods";

    }
    else{

        $type = "struct";

    }

    $self->_xml_handlers()->{$type} ||= Catmandu::Util::require_package( "Catmandu::Importer::OAI::Parser::$type" )->new();
}

sub _map_set {
    my ($self, $rec) = @_;

    +{
        _id => $rec->setSpec(),
        setSpec => $rec->setSpec(),
        setName => $rec->setName(),
        setDescription => [ map {

            #root: 'setDescription'
            my @root = $_->dom()->childNodes();
            #child: oai_dc, marcxml, mods..
            my @children = $root[0]->childNodes();
            $self->_xml_handler_for_node( $children[0] )->parse( $children[0] );

        } $rec->setDescription() ]
    };
}

sub _map_format {
    my ($self, $rec) = @_;

    +{
        _id => $rec->metadataPrefix,
        metadataPrefix    => $rec->metadataPrefix(),
        metadataNamespace => $rec->metadataNamespace(),
        schema            => $rec->schema()
    };
}

sub _map_identify {
    my ($self, $rec) = @_;

    my @description;

    if ($rec->description) {
      for my $desc ($rec->description) {
         push @description , $desc->dom->toString;
      }
    }

    +{
        _id => $rec->baseURL,
        baseURL            => $rec->baseURL,
        granularity        => $rec->granularity,
        deletedRecord      => $rec->deletedRecord,
        earliestDatestamp  => $rec->earliestDatestamp,
        adminEmail         => $rec->adminEmail,
        protocolVersion    => $rec->protocolVersion,
        repositoryName     => $rec->repositoryName,
        description        => \@description
    };
}

sub _map_record {
    my ($self, $rec) = @_;

    my $sets       = [ $rec->header->setSpec ];
    my $identifier = $rec->identifier;
    my $datestamp  = $rec->datestamp;
    my $status     = $rec->status // "";
    my $dom        = $rec->metadata ? $rec->metadata->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0] : undef;
    my $about      = [];

    for ($rec->about) {
        push(@$about , $_->dom->nonBlankChildNodes->[0]->nonBlankChildNodes->[0]->toString);
    }

    my $values = $self->handle_record($dom) // { };

    my $data = {
        _id => $identifier ,
        _identifier => $identifier ,
        _datestamp  => $datestamp ,
        _status     => $status ,
        _setSpec    => $sets ,
        _about      => $about ,
        %$values
    };

    $data;
}

sub _args {
    my $self = $_[0];

    my %args = (
        identifier     => $self->identifier,
        metadataPrefix => $self->metadataPrefix,
        set            => $self->set ,
        from           => $self->from ,
        until          => $self->until ,
        force          => !$self->strict ,
    );

    for( keys %args ) {
        delete $args{$_} if !defined($args{$_}) || !length($args{$_});
    }

    return %args;
}

sub _verb {
    my $self = $_[0];

    if ($self->identify) {
        return 'Identify';
    }
    elsif ($self->listIdentifiers) {
        return 'ListIdentifiers';
    }
    elsif ($self->listSets) {
        return 'ListSets';
    }
    elsif ($self->getRecord) {
        return 'GetRecord';
    }
    elsif ($self->listMetadataFormats) {
        return 'ListMetadataFormats';
    }
    elsif ($self->listRecords) {
        return 'ListRecords';
    }
    else {
        return 'ListRecords';
    }
}

sub handle_record {
    my ($self, $dom) = @_;
    return unless $dom;

    $dom = $self->xslt->transform($dom) if $self->xslt;
    return blessed($self->handler)
         ? $self->handler->parse($dom)
         : $self->handler->($dom);
}

sub dry_run {
    my ($self) = @_;
    sub {
        state $called = 0;
        return if $called;
        $called = 1;
        # TODO: make sure that HTTP::OAI does not change this internal method
        return +{
            url => $self->oai->_buildurl(
                $self->_args(),
                verb => $self->_verb()
            )
        };
    };
}

sub _retry {
    my ( $self, $sub ) = @_;

    $self->_retried( 0 );

    my $res;

    while ( 1 ) {

        $res = $sub->();

        if ($res->is_error && ref($res) ne 'HTTP::OAI::Response') {

            my $max_retries = $self->max_retries();
            my $_retried = $self->_retried();

            if ( $max_retries > 0 && $_retried < $max_retries  ){

                $_retried++;

                #exponential backoff:  [0 .. 2^c [
                my $n_seconds = int( 2**$_retried );
                $self->log->error("failed, retrying after $n_seconds");
                sleep $n_seconds;
                $self->_retried( $_retried );
                next;
            }
            else {
                my $err_msg = $self->url . " : " . $res->message." (stopped after ".$self->_retried()." retries)";
                $self->log->error( $err_msg );
                Catmandu::Error->throw( $err_msg );
            }
        }

        last;
    }

    $res;
}

sub _list_records {
    my $self = $_[0];
    my $args = $_[1];
    sub {
        state $stack = [];
        state $resumptionToken = $self->resumptionToken;
        state $resumptionData  = {};
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my %args = $args ? %$args : $self->_args;

            # Use the resumptionToken if one found on the last run, or if it was
            # undefined (last record)
            if (defined $resumptionToken) {
                my $verb = $args{verb};
                %args = (verb => $verb , resumptionToken => $resumptionToken);
            }

            my $sub = $self->listIdentifiers() ?
                sub { $self->oai->ListIdentifiers( %args , onRecord => $fill_stack ); } :
                sub { $self->oai->ListRecords( %args , onRecord => $fill_stack ); };

            my $res = $self->_retry( $sub );
            if (defined $res->resumptionToken) {
                $resumptionToken = $res->resumptionToken->resumptionToken;

                $resumptionData->{token}            = $resumptionToken;
                $resumptionData->{expirationDate}   = $res->resumptionToken->expirationDate;
                $resumptionData->{completeListSize} = $res->resumptionToken->completeListSize;
                $resumptionData->{cursor}           = $res->resumptionToken->cursor;
            }
            else {
                $resumptionToken = undef;
            }

            unless (defined $resumptionToken && length $resumptionToken) {
                $done = 1;
            }
        }

        if (my $rec = shift @$stack) {
            if ($rec->isa('HTTP::OAI::Record')) {
                my $rec = $self->_map_record($rec);

                $rec->{_resumptionToken} = $resumptionToken if defined($resumptionToken);
                $rec->{_resumption} = $resumptionData if defined($resumptionData);

                return $rec;
            }
            else {
                my $rec =  {
                    _id => $rec->identifier,
                    _datestamp  => $rec->datestamp,
                    _status => $rec->status // "",
                };

                $rec->{_resumptionToken} = $resumptionToken if defined($resumptionToken);
                $rec->{_resumption} = $resumptionData if defined($resumptionData);

                return $rec;
            }
        }

        return undef;
    };
}

sub _list_sets {
    my $self = $_[0];
    sub {
        state $stack = [];
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my $sub = sub { $self->oai->ListSets( onRecord => $fill_stack ); };

            my $res = $self->_retry( $sub );
            $done = 1;
        }

        if (my $rec = shift @$stack) {
            return $self->_map_set($rec);
        }

        return undef;
    };
}

sub _get_record {
    my $self = $_[0];
    my $args = $_[1];
    sub {
        state $stack = [];
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my %args = $args ? %$args : $self->_args;
            my $sub  = sub { $self->oai->GetRecord(%args , onRecord => $fill_stack) };
            my $res  = $self->_retry( $sub );
            $done = 1;
        }

        if (my $rec = shift @$stack) {
            if ($rec->isa('HTTP::OAI::Record')) {
                return $self->_map_record($rec);
            }
            else {
                return {
                    _id => $rec->identifier,
                    _datestamp  => $rec->datestamp,
                    _status => $rec->status // "",
                }
            }
        }

        return undef;
    };
}

sub _list_metadata_formats {
    my $self = $_[0];
    my $args = $_[1];
    sub {
        state $stack = [];
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my %args = $args ? %$args : $self->_args;
            delete $args{metadataPrefix};

            my $sub = sub { $self->oai->ListMetadataFormats( %args ); };

            my $res = $self->_retry( $sub );

            while( my $mdf = $res->next ) {
                $fill_stack->($mdf);
            }

            $done = 1;
        }

        if (my $rec = shift @$stack) {
            return $self->_map_format($rec);
        }

        return undef;
    };
}

sub _identify {
    my $self = $_[0];
    sub {
        state $stack = [];
        state $done  = 0;

        my $fill_stack = sub {
            push @$stack , shift;
        };

        if (@$stack <= 1 && $done == 0) {
            my $sub  = sub { $self->oai->Identify( onRecord => $fill_stack) };
            my $res  = $self->_retry( $sub );

            $fill_stack->($res);

            $done = 1;
        }

        if (my $rec = shift @$stack) {
            return $self->_map_identify($rec);
        }

        return undef;
    };
}

sub oai_run {
    my ($self) = @_;

    if ($self->identify) {
        return $self->_identify;
    }
    elsif ($self->listIdentifiers) {
        return $self->_list_records;
    }
    elsif ($self->listSets) {
        return $self->_list_sets
    }
    elsif ($self->getRecord) {
        return $self->_get_record;
    }
    elsif ($self->listMetadataFormats) {
        return $self->_list_metadata_formats;
    }
    elsif ($self->listRecords) {
        return $self->_list_records
    }
    else {
        return $self->_list_records
    }
}

sub generator {
    my ($self) = @_;

    return $self->dry ? $self->dry_run : $self->oai_run;
}

1;
__END__

=head1 NAME

Catmandu::Importer::OAI - Package that imports OAI-PMH feeds

=head1 SYNOPSIS

    # From the command line

    # Harvest records
    $ catmandu convert OAI --url http://myrepo.org/oai
    $ catmandu convert OAI --url http://myrepo.org/oai --metadataPrefix didl --handler raw

    # Harvest repository description
    $ catmandu convert OAI --url http://myrepo.org/oai --identify 1

    # Harvest identifiers
    $ catmandu convert OAI --url http://myrepo.org/oai --listIdentifiers 1

    # Harvest sets
    $ catmandu convert OAI --url http://myrepo.org/oai --listSets 1

    # Harvest metadataFormats
    $ catmandu convert OAI --url http://myrepo.org/oai --listMetadataFormats 1

    # Harvest one record
    $ catmandu convert OAI --url http://myrepo.org/oai --getRecord 1 --identifier oai:myrepo:1234

=head1 DESCRIPTION

L<Catmandu::Importer::OAI> is an L<Catmandu> importer to harvest metadata records
from an OAI-PMH endpoint.

=head1 CONFIGURATION

=over

=item url

OAI-PMH Base URL.

=item metadataPrefix

Metadata prefix to specify the metadata format. Set to C<oai_dc> by default.

=item handler( sub {} | $object | 'NAME' | '+NAME' )

Handler to transform each record from XML DOM (L<XML::LibXML::Element>) into
Perl hash.

Handlers can be provided as function reference, an instance of a Perl
package that implements 'parse', or by a package NAME. Package names should
be prepended by C<+> or prefixed with C<Catmandu::Importer::OAI::Parser>. E.g
C<foobar> will create a C<Catmandu::Importer::OAI::Parser::foobar> instance.

By default the handler L<Catmandu::Importer::OAI::Parser::oai_dc> is used for
metadataPrefix C<oai_dc>,  L<Catmandu::Importer::OAI::Parser::marcxml> for
C<marcxml>, L<Catmandu::Importer::OAI::Parser::mods> for
C<mods>, and L<Catmandu::Importer::OAI::Parser::struct> for other formats.
In addition there is L<Catmandu::Importer::OAI::Parser::raw> to return the XML
as it is.

=item identifier

Option return only results for this particular identifier

=item set

An optional set for selective harvesting.

=item from

An optional datetime value (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ) as lower bound
for datestamp-based selective harvesting.

=item until

An optional datetime value (YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ) as upper bound
for datestamp-based selective harvesting.

=item identify

Harvest the repository description instead of all records.

=item getRecord

Harvest one record instead of all records.

=item listIdentifiers

Harvest identifiers instead of full records.

=item listRecords

Harvest full records. Default operation.

=item listSets

Harvest sets instead of records.

=item listMetadataFormats

Harvest metadata formats of records

=item resumptionToken

An optional resumptionToken to start harvesting from.

=item dry

Don't do any HTTP requests but return URLs that data would be queried from.

=item strict

Optional validate all parameters first against the OAI 2 spefications before
sending it to an OAI server. Default: undef.

=item xslt

Preprocess XML records with XSLT script(s) given as comma separated list or
array reference. Requires L<Catmandu::XML>.

=item max_retries

When an oai request fails, the importer will retry this number of times.
Set to '0' by default.

Internally the exponential backoff algorithm is used
for this. This means that after every failed request the importer
will choose a random number between 0 and 2^collision (excluded),
and wait that number of seconds. So the actual ammount of time before
the importer stops can differ:

 first retry:
    wait [ 0..2^1 [ seconds
 second retry:
    wait [ 0..2^2 [ seconds
 third retry:
    wait [ 0..2^3 [ seconds

 ..

=item realm

An optional realm value. This value is used when the importer harvests from a
repository which is secured with basic authentication through Integrated Windows
Authentication (NTLM or Kerberos).

=item username

An optional username value. This value is used when the importer harvests from a
repository which is secured with basic authentication.

=item password

An optional password value. This value is used when the importer harvests from a
repository which is secured with basic authentication.

=back

=head1 METHOD

Every Catmandu::Importer is a L<Catmandu::Iterable> all its methods are
inherited. The Catmandu::Importer::OAI methods are not idempotent: OAI-PMH
feeds can only be read once.

In addition to methods inherited from L<Catmandu::Iterable>, this module
provides the following public methods:

=head2 handle_record( $dom )

Process an XML DOM as with xslt and handler as configured and return the
result.

=head1 ENVIRONMENT

If you are connected to the internet via a proxy server you need to set the
coordinates to this proxy in your environment:

    export http_proxy="http://localhost:8080"

If you are connecting to a HTTPS server and don't want to verify the validity
of certificates of the peer you can set the PERL_LWP_SSL_VERIFY_HOSTNAME to
false in your environment. This maybe required to connect to broken SSL servers:

    export PERL_LWP_SSL_VERIFY_HOSTNAME=0

=head1 SEE ALSO

L<Catmandu> ,
L<Catmandu::Importer>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 CONTRIBUTOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

Jakob Voss, C<< <nichtich at cpan.org> >>

Nicolas Franck, C<< <nicolas.franck at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
