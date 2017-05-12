package Data::HAL;
use strictures;
use boolean qw(false true);
use Clone qw(clone);
use Data::HAL::Link qw();
use Data::HAL::URI qw();
use Data::HAL::URI::NamespaceMap qw();
use Data::Visitor::Callback qw();
use failures qw(Data::HAL::InvalidJSON);
use HTTP::Headers::Util qw(join_header_words);
use JSON qw();
use Moo; # has
use Safe::Isa qw($_isa);
use Scalar::Util qw(reftype);
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Str);

our $VERSION = '1.000';

my $uri_from_str = sub {
    my ($val) = @_;
    return $val->$_isa('Data::HAL::URI') ? $val : Data::HAL::URI->new($val);
};

has('embedded', is => 'rw', isa => ArrayRef[InstanceOf['Data::HAL']]);
has('links',    is => 'rw', isa => ArrayRef[InstanceOf['Data::HAL::Link']]);
has('resource', is => 'rw', isa => HashRef, default => sub {return {};});
has('relation', is => 'rw', isa => InstanceOf['Data::HAL::URI'], coerce => $uri_from_str);
has('_nsmap',   is => 'rw', isa => InstanceOf['Data::HAL::URI::NamespaceMap']);
has('_recursing', is => 'ro', isa => Bool);

sub BUILD {
    my ($self) = @_;
    $self->_expand_curies unless $self->_recursing;
    return;
}

sub from_json {
    my ($self, $json, $relation) = @_;
    my $nested = clone JSON::from_json($json);
    failure::Data::HAL::InvalidJSON->throw('not a JSON object') unless reftype $nested eq reftype {};
    return $self->_from_nested($self->_boolify($nested), $relation)->_expand_curies;
}

sub _boolify {
    my ($self, $nested) = @_;
    my $visited = Data::Visitor::Callback->new(
        object => sub {
            my (undef, $val) = @_;
            if (JSON::is_bool($val)) {
                $val = false if $val == JSON::false;
                $val = true if $val == JSON::true;
            }
            return $val;
        }
    )->visit($nested);
    return $visited;
}

sub _from_nested {
    my ($class, $nested, $relation, $_recursing) = @_;
    my $embedded = delete $nested->{_embedded};
    my $links = delete $nested->{_links};
    my $self = $class->new(
        $relation ? (relation => $relation) : (),
        resource => $nested,
        $_recursing ? (_recursing => $_recursing) : (),
    );
    if ($embedded) {
        $self->embedded([]);
        for my $k (keys %{ $embedded }) {
            push @{ $self->embedded }, (reftype $embedded->{$k} eq reftype [])
                ? map { $self->_from_nested($_, $k, 1) } @{ $embedded->{$k} }
                : $self->_from_nested($embedded->{$k}, $k, 1);
        }
    }
    if ($links) {
        $self->links([]);
        for my $k (keys %{ $links }) {
            push @{ $self->links }, (reftype $links->{$k} eq reftype [])
                ? map { Data::HAL::Link->new(%{ $_ }, relation => $k) } @{ $links->{$k} }
                : Data::HAL::Link->new(%{ $links->{$k} }, relation => $k);
        }
    }
    return $self;
}

sub _expand_curies {
    my ($self) = @_;
    my $nsmap = Data::HAL::URI::NamespaceMap->new;
    if ($self->links) {
        for my $l (@{ $self->links }) {
            if ('curies' eq $l->relation->as_string) {
                $nsmap->add_mapping($l->name, $l->href);
            }
        }
    }
    $self->_nsmap($nsmap);
    $self->_recurse_curies($self);
    return $self;
}

sub _recurse_curies {
    my ($self, $root) = @_;
    if ($self->relation) {
        my $uri = $root->_nsmap->uri($self->relation->as_string);
        if ($uri) {
            $self->relation(Data::HAL::URI->new(
                uri => $uri->uri,
                _original => $self->relation->_original,
            ));
        }
    }
    if ($self->links) {
        for my $l (@{ $self->links }) {
            my $uri = $root->_nsmap->uri($l->relation->as_string($root));
            next unless $uri;
            $l->relation(Data::HAL::URI->new(
                uri => $uri->uri,
                _original => $l->relation->_original,
            ));
        }
    }
    if ($self->embedded) {
        for my $e (@{ $self->embedded }) {
            $e->_recurse_curies($root);
        }
    }
    return $self;
}

sub _to_nested {
    my ($self, $root) = @_;
    if ($self->relation) {
        $self->relation(Data::HAL::URI->new(
            uri => URI->new($self->relation->_original),
            _original => $self->relation->_original,
        ));
    }
    my $hal = clone $self->resource;
    for my $prop (qw(links embedded)) {
        if ($self->$prop) {
            for my $p (@{ $self->$prop }) {
                my ($nested, $r) = $p->_to_nested($root);
                if (exists $hal->{"_$prop"}{$r}) {
                    if (reftype $hal->{"_$prop"}{$r} eq reftype []) {
                        push @{ $hal->{"_$prop"}{$r} }, $nested;
                    } else {
                        my $attr = delete $hal->{"_$prop"}{$r};
                        push @{ $hal->{"_$prop"}{$r} }, $attr, $nested;
                    }
                } else {
                    $hal->{"_$prop"}{$r} = $nested;
                }
            }
        }
    }
    return($hal, $self->relation ? $self->relation->as_string : ());
}

sub TO_JSON {
    my ($self) = @_;
    my ($nested) = $self->_to_nested($self);
    my $visited = Data::Visitor::Callback->new(
        boolean => sub {
            my (undef, $val) = @_;
            return $val ? JSON::true : JSON::false;
        }
    )->visit($nested);
    return $visited;
}

sub as_json {
    my ($self) = @_;
    return JSON::to_json($self->TO_JSON, { canonical => 1, pretty => 1, utf8 => 1 });
}

sub http_headers {
    my ($self) = @_;
    my @headers;
    if ($self->links) {
        if (my ($profile_link) = grep { 'profile' eq $_->relation->as_string } @{ $self->links }) {
            push @headers, 'Content-Type' => join_header_words(
                'application/hal+json' => undef, profile => $profile_link->href->as_string
            );
        } else {
            push @headers, 'Content-Type' => 'application/hal+json';
        }
        push @headers,
            map { (Link => $_->as_http_link_value) }
            grep { 'curies' ne $_->relation->as_string }
            @{ $self->links };
    }
    return @headers;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Data::HAL - Hypertext Application Language resource

=head1 VERSION

This document describes Data::HAL version 1.000

=head1 SYNOPSIS

    use Data::HAL qw();
    use Data::HAL::Link qw();
    {
        my $hal = Data::HAL->from_json($json_str);
        my $resource_member_data_href = $hal->resource;
        my $links_aref = $hal->links;
        my $embedded_resources_aref = $hal->embedded;
    }

    {
        my $hal = Data::HAL->new(
            resource => {foo => 23, bar => 42},
            links    => [Data::HAL::Link->new(relation => 'self', href => '/')],
        );

        my $json_str = $hal->as_json;
        # {
        #    "_links" : {
        #       "self" : {
        #          "href" : "/"
        #       }
        #    },
        #    "bar" : 42,
        #    "foo" : 23
        # }

        my @headers = $hal->http_headers;
        # (
        #     'Content-Type' => 'application/hal+json',
        #     'Link' => '</>;rel="self"'
        # )
    }

=head1 DESCRIPTION

HAL is a format you can use in your hypermedia API.

=head2 Introduction

This section is completely quoted from the specification:

There is an emergence of non-HTML HTTP applications ("Web APIs")
which use hyperlinks to direct clients around their resources.

The JSON Hypertext Application Language (HAL) is a standard which
establishes conventions for expressing hypermedia controls, such as
links, with JSON.

HAL is a generic media type with which Web APIs can be developed and
exposed as series of links.  Clients of these APIs can select links
by their link relation type and traverse them in order to progress
through the application.

HAL's conventions result in a uniform interface for serving and
consuming hypermedia, enabling the creation of general-purpose
libraries that can be re-used on any API utilising HAL.

The primary design goals of HAL are generality and simplicity.  HAL
can be applied to many different domains, and imposes the minimal
amount of structure necessary to cover the key requirements of a
hypermedia Web API.

=head2 Conformance

The author claims to conform with L<http://tools.ietf.org/html/draft-kelly-json-hal-06>, published 2013-10-03.

=head1 INTERFACE

=head2 Composition

None.

=head2 Constructors

=head3 C<from_json>

    Data::HAL->from_json($json_str)

Takes a HAL+JSON document as string and returns a C<Data::HAL> object.

=head3 C<new>

    Data::HAL->new(
        resource => {foo => 23, bar => 42},
        links    => [Data::HAL::Link->new(relation => 'self', href => '/')]
    )

Default L<Moo> constructor, returns a C<Data::HAL> object.

=head2 Attributes

=head3 C<embedded>

Type C<ArrayRef[Data::HAL]>,
L<< embedded resource objects|http://tools.ietf.org/html/draft-kelly-json-hal#section-4.1.2 >>

=head3 C<links>

Type C<ArrayRef[Data::HAL::Link]>,
L<< link objects|http://tools.ietf.org/html/draft-kelly-json-hal#section-4.1.1 >>

=head3 C<resource>

Type C<HashRef>, member data
L<< representing the current state of the resource|http://tools.ietf.org/html/draft-kelly-json-hal#section-4 >>

=head3 C<relation>

Type L<Data::HAL::URI>,
L<< identifier of the semantics of a link|http://tools.ietf.org/html/rfc5988#section-4 >>

Perl strings are coerced to the L<Data::HAL::URI> type.

A stand-alone HAL+JSON document, when deserialised, will not have this attribute set in the root resource since nothing
is linking to the document.

=head2 Methods

=head3 C<TO_JSON>

Serialisation hook for the L<JSON> (or compatible) module.

This method is not intended to be called directly from your code. Instead call L</as_json> or
C<< JSON::to_json $hal, { convert_blessed => 1 } >> or similar.

=head3 C<as_json>

Returns the resource object serialised as a HAL+JSON document string.

=head3 C<http_headers>

Returns a list of pairs of HTTP message headers. The keys are field name strings and the values are field content
strings. B<Warning>: since field names can repeat, assigning this list to a hash loses information.

The list is suitable as input for e.g. the
L<< C<headers> accessor in HTTP::Headers|HTTP::Headers/$h->header( $f1 => $v1, $f2 => $v2, ... ) >>
or the L<< C<headers> attribute in Plack::Response|Plack::Response/headers >>.

=head4 C<Content-Type>

The value is C<application/hal+json>, perhaps with a C<profile> parameter.

=head4 C<Link>

See L<Data::HAL::Link/as_http_link_value>.

=head2 Exports

None.

=head1 DIAGNOSTICS

=head2 C<not a JSON object>

The L</from_json> constructor throws this exception of type C<failure::Data::HAL::InvalidJSON> when the JSON input is a
malformed HAL+JSON document.

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.

=head1 DEPENDENCIES

See meta file in the source distribution.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-data-hal@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-HAL>.

=head2 tight coupling to JSON

It is currently difficult to exert control over the specifics of (de)serialisation, perhaps put the (de)serialisers
into attributes?

=head2 error type is an attribute, not a class name

It is not worth it to design an error class hierarchy for a single error.

=head2 Data::HAL::URI::NamespaceMap is undocumented

It is used only internally.

=head1 TO DO

=over

=item make everything cache-friendly

=item non-standard accessors for link objects

=item support §8.3. cache pattern

=item support HAL XML

=back

=head1 SEE ALSO

L<AtomPub|http://enwp.org/AtomPub>, the more mature, featureful hypermedia protocol

=head1 AUTHOR

Lars Dɪᴇᴄᴋᴏᴡ C<< <daxim@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright © 2013 Lars Dɪᴇᴄᴋᴏᴡ C<< <daxim@cpan.org> >>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.18.0.

=head2 Disclaimer of warranty

This library is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or fitness
for a particular purpose.
