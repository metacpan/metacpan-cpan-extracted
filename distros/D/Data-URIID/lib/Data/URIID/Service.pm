# Copyright (c) 2023 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Service;

use v5.10;
use strict;
use warnings;

use Carp;
use JSON;
use URI;
use URI::Escape;
use Encode;
use Scalar::Util qw(weaken);

use Data::URIID::Result;

our $VERSION = v0.03;

my %idmap_wikidata = (
    P213   => 'isni',
    P214   => 'viaf-identifier',
    P227   => 'gnd-identifier',
    P648   => 'open-library-identifier',
    P1566  => 'geonames-identifier',
    P2041  => 'ngv-artist-identifier',
    P3847  => 'open-library-identifier',
    P3916  => 'unesco-thesaurus-identifier',
    P4684  => 'ngv-artwork-identifier',
    P7033  => 'aev-identifier',
    P7704  => 'europeana-entity-identifier',
    P8168  => 'factgrid-identifier',
    P10787 => 'factgrid-identifier',
    (map {$_ => 'musicbrainz-identifier'} qw(P434 P435 P436 P966 P982 P1004 P1330 P1407 P4404 P5813 P6423 P8052)),
);

my @fellig_types = qw(fellig-identifier fellig-box-number uuid oid uri wikidata-identifier e621-post-identifier wikimedia-commons-identifier british-museum-term musicbrainz-identifier gnd-identifier e621tagtype);

my %attrmap_osm = (
    name        => 'displayname',
    description => 'description',
);


# Private method:
sub new {
    my ($pkg, %opts) = @_;
    weaken($opts{extractor});
    return bless \%opts, $pkg;
}

# Private helper:
sub _is_online {
    my ($self) = @_;
    return $self->online && $self->extractor->online;
}

# Private method:
sub _online_lookup {
    my ($self, $result, %opts) = @_;
    my $func;

    return undef unless $self->_is_online;
    $func = $self->can(sprintf('_online_lookup__%s', $self->name =~ tr/\.:/_/r));
    return undef unless $func;

    return $self->$func($result, %opts);
}

# Private method:
sub _offline_lookup {
    my ($self, $result, %opts) = @_;
    my $func;

    $func = $self->can(sprintf('_offline_lookup__%s', $self->name =~ tr/\.:/_/r));
    return undef unless $func;

    return $self->$func($result, %opts);
}


#@returns Data::URIID
sub extractor {
    my ($self) = @_;
    return $self->{extractor} // croak(sprintf('Invalid access to %s belonging to no longer existing instance of Data::URIID', __PACKAGE__));
}


sub ise {
    my ($self) = @_;
    return $self->{ise};
}


sub name {
    my ($self) = @_;
    return $self->{name} //= $self->extractor->ise_to_name(service => $self->ise);
}


sub online {
    my ($self, $new_value) = @_;

    if (scalar(@_) == 2) {
        $self->{online} = !!$new_value;
    }

    return $self->{online};
}


# Private helper:
sub _extra_lookup_services {
    return {
        'wikidata'      => [values(%idmap_wikidata), qw(british-museum-term uuid)],
        'fellig'        => \@fellig_types,
        'noembed.com'   => [qw(youtube-video-identifier)],
        'osm'           => [qw(osm-node osm-way osm-relation)],
        'overpass'      => [qw(wikidata-identifier)],
    }
}

# Private helper:
sub _get_json {
    my ($self, $url, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;

    if (defined(my $query = $opts{query})) {
        $url = ref($url) ? $url->clone : URI->new($url);
        $url->query_form($url->query_form, %{$query});
    }

    # We cannot use decoded_content()'s charset decoding here as it's buggy for JSON response (at least in v6.18).
    return eval {
        my $msg = $extractor->_ua->get($url);
        return undef unless $msg->is_success;
        my $val = $msg->decoded_content(ref => 1, charset => 'none');
        from_json(decode($msg->content_charset, $$val));
    };
}

# Private lookup drivers:
sub _offline_lookup__Data__URIID {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $ise_order = $result->{primary}{ise_order} // [qw(uuid oid uri)];
    my %attr;
    my %res = (attributes => \%attr);

    outer:
    foreach my $ise_type (@{$ise_order}) {
        my $ise = eval {$result->id($ise_type)} // next;
        foreach my $type (qw(service type action)) {
            my $name = eval { $extractor->ise_to_name($type => $ise) } // next;
            my $displayname = $attr{displayname} //= {};
            $displayname->{'*'} //= $name;
            last outer;
        }
    }

    return \%res;
}

sub _online_lookup__wikidata {
    my ($self, $result) = @_;
    my $id = eval {$result->id('wikidata-identifier')};

    unless (defined $id) {
        $id = $self->_online_lookup__wikidata__stage_0($result);
    }

    if (defined $id) {
        return $self->_online_lookup__wikidata__stage_1($result, $id);
    }

    return undef;
}

sub _online_lookup__wikidata__stage_0 {
    my ($self, $result) = @_;
    my @ids;

    foreach my $property (keys %idmap_wikidata) {
        my $id = eval {$result->id($idmap_wikidata{$property})};
        if (defined $id) {
            if ($id !~ /['"]/) {
                push(@ids, sprintf('?item wdt:%s "%s"', $property, $id));
            }
        }
    }

    # british-museum-term is special:
    {
        my $id = eval {$result->id('british-museum-term')};
        if (defined $id) {
            if ($id =~ /^BIOG([1-9][0-9]+)$/) {
                push(@ids, sprintf('?item wdt:P1711 "%s"', $1));
            }
        }
    }

    # UUID is special:
    {
        my $id = eval {$result->id('uuid')};
        if (defined $id) {
            foreach my $property (qw(P434)) {
                push(@ids, sprintf('?item wdt:%s "%s"', $property, $id));
            }
        }
    }

    return undef unless scalar @ids;

    {
        my $q = sprintf('SELECT * WHERE { { %s } } LIMIT 1', join('} UNION {', @ids));
        my $res = $self->_get_json('https://query.wikidata.org/sparql', query => {format => 'json', query => $q});
        my $item = eval {$res->{results}{bindings}[0]{item}};
        return undef unless $item;
        return undef unless ($item->{type} // '') eq 'uri';
        if (($item->{value} // '') =~ m#^http://www\.wikidata\.org/entity/([QP][1-9][0-9]+)$#) {
            return $1;
        }
    }

    return undef;
}

sub _online_lookup__wikidata__stage_1 {
    my ($self, $result, $id) = @_;
    my $data = $self->_get_json(sprintf('https://www.wikidata.org/wiki/Special:EntityData/%s.json?flavor=dump', $id))->{entities}{$id};
    my %ids = ('wikidata-identifier' => $id);
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);

    $attr{displayname} = {map {$_ => $data->{labels}{$_}{value}}       keys %{$data->{labels}}};
    $attr{description} = {map {$_ => $data->{descriptions}{$_}{value}} keys %{$data->{descriptions}}};

    $res{wikidata_sitelinks} = $data->{sitelinks};
    foreach my $property (keys %idmap_wikidata) {
        foreach my $entry (@{$data->{claims}{$property} // []}) {
            $ids{$idmap_wikidata{$property}} = $entry->{mainsnak}{datavalue}{value};
        }
    }

    # Special:
    foreach my $entry (@{$data->{claims}{P1711} // []}) {
        $ids{'british-museum-term'} = sprintf('BIOG%u', $entry->{mainsnak}{datavalue}{value});
    }
    foreach my $entry (@{$data->{claims}{P625} // []}) { # 'coordinate location'
        foreach my $subkey (qw(altitude latitude longitude)) {
            $attr{$subkey} = {'*' => $entry->{mainsnak}{datavalue}{value}{$subkey} + 0} if defined $entry->{mainsnak}{datavalue}{value}{$subkey};
        }
        $attr{space_object} = {'*' => URI->new($entry->{mainsnak}{datavalue}{value}{globe})} if defined $entry->{mainsnak}{datavalue}{value}{globe};
    }
    foreach my $entry (@{$data->{claims}{P376} // []}) { # 'located on astronomical body'
        $attr{space_object} = {'*' => URI->new(sprintf('http://www.wikidata.org/entity/%s', $entry->{mainsnak}{datavalue}{value}{id}))} if defined $entry->{mainsnak}{datavalue}{value}{id};
    }

    return \%res;
}

sub _online_lookup__fellig {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;

    foreach my $type (@fellig_types) {
        my $id = eval {$result->id($type, _no_convert => 1)} // next;
        my $json = $self->_get_json(sprintf('https://api.fellig.org/v0/overview/%s/%s', $type, uri_escape($id))) // next;

        foreach my $idx (@{$json->{main_result}}) {
            my $tag = $json->{tags}[$idx];
            my %ids;
            my %attr;
            my %res = (id => \%ids, attributes => \%attr);

            foreach my $class (qw(unvaried varied)) {
                # This is a trusted service, so we only check for the id types to be valid ISE
                # but accept them all.
                foreach my $idtype (keys %{$tag->{$class}{ids}//{}}) {
                    if ($extractor->is_ise($idtype)) {
                        $ids{$idtype} //= $tag->{$class}{ids}{$idtype}[0];
                    }
                }

                $attr{displayname}    = {'*' => $tag->{$class}{displayname}} if defined $tag->{$class}{displayname};
                $attr{icon_text}      = {'*' => $tag->{$class}{icontext}} if defined $tag->{$class}{icontext};
                $attr{displaycolour}  = {'*' => $tag->{$class}{displaycolour}} if defined $tag->{$class}{displaycolour};
                $attr{final_file_size}= {'*' => $tag->{$class}{'final-file-size'}} if defined $tag->{$class}{'final-file-size'};
                $attr{icon}           = {'*' => URI->new($tag->{$class}{icon})} if defined $tag->{$class}{icon};
            }

            return \%res;
        }
    }

    return undef;
}

sub _online_lookup__noembed_com {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;

    foreach my $service (qw(youtube)) {
        my $url = eval {$result->url(service => $service, action => 'render')} // eval {$result->url($service, action => 'embed')} // next;
        my $json = $self->_get_json('https://noembed.com/embed', query => {url => $url}) // next;
        my %attr;
        my %res = (attributes => \%attr);

        $attr{displayname} = {'*' => $json->{title}} if defined $json->{title};
        $attr{thumbnail}   = {'*' => URI->new($json->{thumbnail_url})} if defined $json->{thumbnail_url};

        return \%res;
    }

    return undef;
}

sub _online_lookup__osm__handle {
    my ($self, $element) = @_;
    my $tags = $element->{tags} // {};
    my %ids;
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);

    $attr{space_object} = {'*' => URI->new('http://www.wikidata.org/entity/Q2')}; # If it's on OSM it's on earth.
    $attr{latitude} = {'*' => $element->{lat} + 0} if defined $element->{lat};
    $attr{longitude} = {'*' => $element->{lon} + 0} if defined $element->{lon};
    $attr{altitude} = {'*' => $tags->{ele} + 0} if defined $tags->{ele};
    $attr{altitude} = {'*' => $tags->{'ele:wgs84'} + 0} if defined $tags->{'ele:wgs84'};
    #foreach my $subkey (qw(altitude latitude longitude)) {

    $ids{'wikidata-identifier'} = $tags->{wikidata} if defined $tags->{wikidata};

    foreach my $key (keys %attrmap_osm) {
        my %data;

        $data{'*'} = $tags->{$key} if defined $tags->{$key};
        foreach my $inkey (keys %{$tags}) {
            if ($inkey =~ /^\Q$key\E:([a-z]{2,3})$/) {
                $data{$1} = $tags->{$inkey};
            }
        }

        $attr{$attrmap_osm{$key}} = \%data if scalar keys %data;
    }

    return \%res;
}

sub _online_lookup__osm {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;

    foreach my $type (qw(node way relation)) {
        my $id = eval {$result->id('osm-'.$type)} // next;
        my $json = $self->_get_json(sprintf('https://api.openstreetmap.org/api/0.6/%s/%s.json', $type, $id)) // next;
        my $element = eval {$json->{elements}[0]} // return undef;
        return $self->_online_lookup__osm__handle($element);
    }

    return undef;
}

sub _online_lookup__overpass {
    my ($self, $result) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $id = $result->id('wikidata-identifier');
    my $json = $self->_get_json('https://overpass-api.de/api/interpreter', query => {
            data => sprintf("[out:json][timeout:25];\n(node[\"wikidata\"=\"%s\"];\nway[\"wikidata\"=\"%s\"];\nrelation[\"wikidata\"=\"%s\"];\n);\nout;",
                $id, $id, $id,
            ),
        }) // return undef;
    my $element = eval {$json->{elements}[0]} // return undef;
    my $res = $self->_online_lookup__osm__handle($element);
    my $type = $element->{type} // '';
    my $id_new = $element->{id} // '';

    if ($type eq 'node' || $type eq 'way' || $type eq 'relation') {
        if ($id_new =~ Data::URIID::Result->RE_UINT) {
            $res->{id}->{'osm-'.$type} = $id_new;
        }
    }

    return $res;
}

sub _online_lookup__xkcd {
    my ($self, $result, %opts) = @_;
    my Data::URIID $extractor = $self->extractor;
    my $json = $self->_get_json($opts{metadata_url} // $result->url(service => 'xkcd', action => 'metadata')) // return undef;
    my %ids;
    my %attr;
    my %res = (id => \%ids, attributes => \%attr);

    $ids{'xkcd-num'} = int($json->{num}) if defined($json->{num}) && $json->{num} =~ Data::URIID::Result->RE_UINT;
    $attr{displayname} = {'*' => $json->{title}} if defined($json->{title}) && length($json->{title});

    return \%res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Service - Extractor for identifiers from URIs

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use Data::URIID;

    my $extractor = Data::URIID->new;
    my $result = $extractor->lookup( $URI );
    my $service = $result->attribute('service');

    my $name = $service->name;
    my $ise = $service->ise;

=head1 METHODS

=head2 extractor

    my $extractor = $service->extractor;

Returns the L<Data::URIID> object used to create this object.

=head2 ise

    my $ise = $service->ise;

Returns the ISE of this service.

=head2 name

    my $name = $service->name;

Returns the name of this service.

=head2 online

    my $online = $service->online( [ $new_value ] );

Gets or sets the online status of the service.
If this value is false no online operations are permitted.
In addition to this value being true the online value for the extractor need to be true.

See also L<"extractor">, L<Data::URIID/"online">.

=head1 KNOWN/SUPPORTED SERVICES

The following is a non-complete list of services for which lookups (online or offline) are supported.
For a complete list of known services see L<Data::URIID/"known">.

=head2 C<wikidata> and C<wikipedia>

Wikidata is a large collection of machine readable data from all categories. It can act as a central connecting point
for several types of identifiers and services. It also provides Wikipedia pages for the given subject.

The C<wikipedia> services is only used for online lookups if a Wikipedia page is used as an input. It does not provide
lookup from identifiers to Wikipedia links.

In many cases you want to enable online lookups for both C<wikidata>, and C<wikipedia>. This is specifically true if you
want to work with very different services at once.

You commonly don't need to enable online lookups if all the services you're interested in use the same type of identifiers.

=head2 C<osm> and C<overpass>

The C<osm> service is mainly used to lookup from OpenStreetMap identifiers to other identifiers as well as attributes.
While the C<overpass> service is mostly used to look up from other identifiers to OpenStreetMap identifiers.

If you work with places you most likely want to enable online lookups on those services.

=head2 C<Data::URIID>

This service is used to perform internal offline lookups on identifiers known to the module.
It mainly provides display names for ISEs used by this module.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
