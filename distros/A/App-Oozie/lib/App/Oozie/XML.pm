package App::Oozie::XML;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use namespace::autoclean -except => [qw/_options_data _options_config/];

use App::Oozie::Constants qw(
    EMPTY_STRING
    LAST_ELEM
    MIN_OOZIE_SCHEMA_VERSION_FOR_SLA
    MIN_OOZIE_SLA_VERSION
    RE_COLON
    RE_DOT
    XML_LOCALNAME_POS
    XML_NS_FIRST_POS
    XML_UNPACK_LOCALNAME_POS
    XML_VERSION_PADDING
    XML_VERSION_POS
);
use App::Oozie::Types::Common qw( IsFile );
use App::Oozie::Util::Misc    qw( resolve_tmp_dir );

use Archive::Zip;
use Clone qw( clone );
use File::Temp ();
use Text::Trim qw( trim );
use Moo;
use MooX::Options;
use Ref::Util qw( is_ref is_hashref is_arrayref is_scalarref );
use Scalar::Util qw( blessed );
use Types::Standard qw( Str );
use XML::Compile::Cache;
use XML::Compile::Util;
use XML::LibXML;

with qw(
    App::Oozie::Role::Log
    App::Oozie::Role::Fields::Generic
);

# These are cache variables holding the Oozie spec.
#
my($XML_SCHEMA, %XML_NAMESPACE);

has prefix => (
    is  => 'rw',
    isa => Str,
);

has data => (
    is       => 'rw',
    default  => undef,
);

has writer => (
    is       => 'lazy',
    builder  => sub { $XML_SCHEMA->writer( $XML_NAMESPACE{ shift->prefix } ) },
    init_arg => undef,
);

has oozie_client_jar => (
    is       => 'rw',
    isa      => IsFile,
    required => 1,
);

has zip => (
    is      => 'ro',
    default => sub { Archive::Zip->new },
);

has schema => (
    is      => 'lazy',
    default => sub { $XML_SCHEMA },
);

has namespace => (
    is      => 'lazy',
    default => sub { \%XML_NAMESPACE },
);

sub BUILD {
    my ($self, $args) = @_;

    $XML_SCHEMA ||= $self->_build_schema;

    $self->_init_data($args)
        if defined $self->data;

    return;
}

sub _init_data {
    my ($self, $args) = @_;

    my $source = $self->data;
    my $data;

    if (ref $source eq 'HASH') {
        $self->prefix($args->{prefix});
        $data = $source;
    }
    else {

        my ($localname, $version) = $self->sniff_doc( $source );

        my $prefix = "$localname:$version";
        my $type   = $XML_NAMESPACE{$prefix};

        die "Unknown prefix $prefix" if !exists $XML_NAMESPACE{$prefix};

        $self->prefix( $prefix );

        eval {
            $data =  $XML_SCHEMA->reader( $type )->($source);
            1;
        } or do {
            my $eval_error = $@ || 'Zombie error';

            die $eval_error
                if ! ref     $eval_error
                || ! blessed $eval_error
                || ! $eval_error->isa('Log::Report::Exception')
                ;

            # Handling this otherwise is impossible as the schema definitions
            # make such situations fatal, without returning a parsed or semi
            # parsed document.
            #
            # The alternative might be to feed the document to a function which
            # does not do schema validation (like XML::Simple) -- which will lead
            # to double parsing -- or just try to parse the error message like
            # down below.
            #
            if ( $type =~ m{ \Qworkflow-app\E }xms ) {
                die join "\n",
                    $self->_probe_parse_error_for_workflow( $eval_error ),
                    $eval_error->toString,
                    ;
            }
            # Rethrow as we don't know what this is.
            die $eval_error;

        };
    }

    $self->data( $data );

    return;
}

sub _probe_parse_error_for_workflow {
    my $self           = shift;
    my $eval_error_obj = shift;
    my $logger         = $self->logger;

    my $dumb_conf;
    eval {
        require XML::LibXML::Simple;
        my $xs   = XML::LibXML::Simple->new;
        $dumb_conf = $xs->XMLin( $self->data );
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        $logger->debug( sprintf 'Failed to fall back to dumb XML parser: %s. The next steps might fail', $eval_error );
    };

    state $re_path     = qr{ (?<version>[0-9.]+) [:] workflow-app \z }xms;
    state $re_sla_new  = qr{ \bsla\b[:] (?<version>[0-9.]+) }xms;     # >=0.5
    state $re_sla_path = qr{ \bsla\b[-] (?<version>[0-9.]+) [:] }xms; # <0.5

    my $msg  = $eval_error_obj->message;
    my $name = $msg->{name};
    my $path = $msg->{path};

    my($wf_version, $sla_version);
    if ( $path =~ $re_path ) {
        $wf_version = $+{version};
    }

    if (   (   $name       && $name =~ $re_sla_new  )
        || ( ! $wf_version && $path =~ $re_sla_path )
    ) {
        $sla_version = $+{version};
    }

    my @extra_error;

    if ( defined $sla_version && $sla_version < MIN_OOZIE_SLA_VERSION ) {
        push @extra_error,
            'Schema version mismatch for the SLA feature!',
            sprintf(
                'Your sla definition refers to a schema older than the minimum required version of %s (you have defined %s).',
                    MIN_OOZIE_SLA_VERSION,
                    $sla_version,
            ),
        ;
    }

    if ( defined $wf_version && $wf_version < MIN_OOZIE_SCHEMA_VERSION_FOR_SLA ) {
        push @extra_error,
            'Schema version mismatch for the SLA feature!',
            sprintf(
                'Your workflow definition refers to a schema older than the minimum required version of %s (you have defined %s).',
                    MIN_OOZIE_SCHEMA_VERSION_FOR_SLA,
                    $wf_version,
            ),
        ;
    }

    if ( $dumb_conf ) {
        if ( my $forks = $dumb_conf->{fork} ) {
            for my $node ( sort keys %{ $forks } ) {
                my $paths = $forks->{ $node }{path};
                my $total = keys %{ $paths };
                if ( $total < 2 ) {
                    push @extra_error, sprintf <<'NEED_AT_LEAST_TWO', $node;
The fork node `%s` has less than 2 paths. Oozie won't execute such definitions.
Either remove fork node, or change the definiton to have at least 2 paths.
NEED_AT_LEAST_TWO

                }
            }
        }
    }

    return @extra_error;
}

sub localname {
    my ($self) = @_;
    my $type = $XML_NAMESPACE{ $self->prefix };
    return +( XML::Compile::Util::unpack_type( $type ) )[LAST_ELEM];
}

sub is_foreign_prefix {
    my ($self, $prefix) = @_;
    my ($ns, $localname) = XML::Compile::Util::unpack_type($XML_NAMESPACE{$self->prefix});
    my $nsobj = ( $XML_SCHEMA->namespaces->namespace($ns) )[XML_NS_FIRST_POS];
    my %elements =
        map { lc $_ => 1 }
        map { (XML::Compile::Util::unpack_type($_))[XML_UNPACK_LOCALNAME_POS] }
        $nsobj->elements, $nsobj->types;
    return not exists $elements{$prefix};
}

sub xml {
    my ($self) = @_;
    my $data = clone( $self->data );

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    # visit the cloned datastructure
    # and write back the XML for internal "any" nodes
    my @queue = ($data);
    while ( my $this = shift @queue ) {
        if ( is_hashref $this ) {
            for my $prefix ( keys %{ $this } ) {
                if ( exists $XML_NAMESPACE{$prefix} and $self->is_foreign_prefix($prefix) ) {
                    $this->{ $XML_NAMESPACE{$prefix} } =
                      $XML_SCHEMA->writer( $XML_NAMESPACE{$prefix} )
                      ->( $doc, delete $this->{$prefix} );
                }
                elsif ( is_ref $this->{$prefix} ) {
                    push @queue, $this->{$prefix};
                }
            }
        }
        elsif ( is_arrayref $this ) {
            push @queue,
                grep {
                    is_hashref( $_ )  || is_arrayref( $_ )
                } @{ $this };
        }
    }

    return $self->writer->( $doc, $data );
}

sub sniff_doc {
    my($self, $doc) = @_;
    my $logger  = $self->logger;
    my $verbose = $self->verbose;

    my $type = fileno $doc ? 'IO'
             : ( ( $doc =~ m{ \A \s* [<] }xms ) or is_scalarref $doc ) ? 'string'
             : 'location';

    my $xml  = XML::LibXML->load_xml($type => $doc);
    my $root = $xml->documentElement;

    my $namespace = $root->getNamespaceURI;

    if ($namespace) {
        my ($localname, $version) = (split RE_COLON, $namespace )[XML_LOCALNAME_POS, XML_VERSION_POS];
        if ($localname and $version) {
            return $localname, $version;
        }
        else {
            $logger->logdie(
                sprintf q{Can't parse out localname and version from namespace: %s},
                        $namespace,
            )
        }
    }
    else {
        $logger->logdie(
            sprintf q{Can't get namespace URI from xml document: %s},
                    trim( $doc ),
        );
    }

    return;
}

sub _build_schema {
    my $self    = shift;
    my $logger  = $self->logger;
    my $verbose = $self->verbose;

    my @xsd;         # final list of XSD files to load
    my %prefixes;    # final prefix -> namespaces mapping

    my $oozie_client_jar = $self->oozie_client_jar;
    my $tempdir          = File::Temp::tempdir(
                                CLEANUP => 1,
                                DIR     => resolve_tmp_dir(),
                            );
    my $zip              = $self->zip;

    state $zip_error_code_to_str = {
        map {
            Archive::Zip->$_ => $_
        } qw(
            AZ_STREAM_END
            AZ_ERROR
            AZ_FORMAT_ERROR
            AZ_IO_ERROR
        )
    };

    if ( $verbose ) {
        $logger->debug(
                sprintf 'Attempting to collect the Oozie schema specs from %s into %s',
                        $oozie_client_jar,
                        $tempdir,
        );
    }

    eval {
        READ_ATTEMPT: {
            my $rv_read = $zip->read( $oozie_client_jar );
            if ( $rv_read != Archive::Zip::AZ_OK ) {
                die sprintf 'Zip file %s read error: read() returned %s',
                                $oozie_client_jar,
                                $zip_error_code_to_str->{ $rv_read } || $rv_read,
                ;
            }
        }

        EXTRACT_ATTEMPT: {
            my $rv_extract = $zip->extractTree({ zipName => $tempdir });
            if ( $rv_extract != Archive::Zip::AZ_OK ) {
                die sprintf 'Zip file %s extract error (be sure that the local file system is not full): extractTree() returned %s',
                                $oozie_client_jar,
                                $zip_error_code_to_str->{ $rv_extract } || $rv_extract,
                ;
            }
        }

        @xsd = glob "${tempdir}/*.xsd"
                    or die sprintf 'Failed to locate xsd files inside %s',
                                        $oozie_client_jar;
        1;
    } or do {
        my $eval_error = $@ || 'Zombie error';
        my $msg = sprintf 'Error collecting Oozie schemas. Ensure oozie-client is installed and the specs exist under %s: %s',
                            $oozie_client_jar,
                            $eval_error,
                    ;
        $logger->logdie( $msg );
    };

    if ( $verbose ) {
        $logger->debug( sprintf 'Reading the %s unpacked Oozie schemas',
                                    scalar @xsd );
    }

    # check all the XSD files to figure out which is the latest
    for my $file ( @xsd ) {

        # read the XSD file as XML and get the schema attributes
        my $xml = XML::LibXML->load_xml( location => $file );
        my ($this_xml_schema) = $xml->findnodes('/xs:schema');
        my ($first)  = $xml->findnodes('/xs:schema/xs:element');

        # get the namespace and version
        my %attr      = map +( $_->name, $_->value ), $this_xml_schema->attributes;
        if ( ! exists $attr{targetNamespace} ) {
            # seems to be a change in new version
            next;
        }
        my $namespace = delete $attr{targetNamespace};
        my $version   = ( split RE_COLON, $namespace )[LAST_ELEM]; # assuming uri:oozie:...:$version
        my $prefix    = ( split RE_COLON, ( grep $attr{$_} eq $namespace, keys %attr )[0] )[LAST_ELEM];

        # build a "version string" that can be asciibetically compared
        my $v = join EMPTY_STRING,
                map sprintf( '%04d', $_ ),
                    (
                        split( RE_DOT, $version ),
                        (0) x XML_VERSION_PADDING
                    )[ 0 .. XML_VERSION_PADDING ]
                ;

        # keep name, version and xsd file for the latest version
        if ( $v gt( $prefixes{$prefix}[2] || EMPTY_STRING ) ) {
            $prefixes{$prefix} = [
                $prefix,
                $namespace,
                $v,
                $version,
                $first->getAttribute('name'),
                $file,
            ];
        }

        # also support prefix:version
        $prefixes{"$prefix-$version"} = [
            $prefix,
            $namespace,
            $v,
            $version,
            $first->getAttribute('name'),
            $file,
        ];
    };

    # clean up %prefixes
    # value = [ prefix, namespace, version, top-element, file ]
    for ( sort { $a->[2] cmp $b->[2] } values %prefixes ) {
        my ($prefix, $namespace, $v, $version, $top, $file) = @{ $_ };
        $XML_NAMESPACE{"$prefix"} = # assume latest
        $XML_NAMESPACE{"$prefix:$version"} = XML::Compile::Util::pack_type($namespace, $top);
        $_ = $namespace;    # changes the value in %prefixes
    }

    # build the final $XML_SCHEMA object
    return XML::Compile::Cache->new(
        \@xsd,
        prefixes         => \%prefixes,
        allow_undeclared => 1,
        opts_writers     => { any_element => 'TAKE_ALL' },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::XML

=head1 VERSION

version 0.017

=head1 SYNOPSIS

    use App::Oozie::XML;
    my $xml = App::Oozie::XML->new(
                data             => $data,
                oozie_client_jar => $oozie_client_jar,
                verbose          => 1,
    );
    my $localname = $xml->localname;
    my $xml_in    = $xml->data;

=head1 DESCRIPTION

Oozie XML spec Handler.

=for Pod::Coverage BUILD

=head1 NAME

App::Oozie::XML - XML Handler.

=head1 Methods

=head2 is_foreign_prefix

=head2 localname

=head2 sniff_doc

=head2 xml

=head1 Accessors

=head2 Overridable from sub-classes

=head3 data

=head3 namespace

=head3 oozie_client_jar

=head3 prefix

=head3 schema

=head3 writer

=head3 zip

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
