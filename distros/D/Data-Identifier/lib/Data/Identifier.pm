#!/usr/bin/perl -w

# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier;

use v5.20;
use strict;
use warnings;

use parent qw(Data::Identifier::Interface::Known);

use Carp;
use Math::BigInt lib => 'GMP';
use URI;
use Data::Identifier::Generate;

our $VERSION = v0.09;

use constant {
    RE_UUID => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/,
    RE_OID  => qr/^[0-2](?:\.(?:0|[1-9][0-9]*))+$/,
    RE_URI  => qr/^[a-zA-Z][a-zA-Z0-9\+\.\-]+/,
    RE_UINT => qr/^(?:0|[1-9][0-9]*)$/,
    RE_QID  => qr/^[QPL][1-9][0-9]*$/,
    RE_DOI  => qr/^10\.[1-9][0-9]+(?:\.[0-9]+)*\/./,
    RE_UNICODE => qr/^U\+([0-9A-F]{4,7})$/,
};

use constant {
    WK_UUID => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', # uuid
    WK_OID  => 'd08dc905-bbf6-4183-b219-67723c3c8374', # oid
    WK_URI  => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439', # uri
    WK_SID  => 'f87a38cb-fd13-4e15-866c-e49901adbec5', # small-identifier
    WK_WD   => 'ce7aae1e-a210-4214-926a-0ebca56d77e3', # wikidata-identifier
    WK_GTIN => '82d529be-0f00-4b4f-a43f-4a22de5f5312', # gtin
    WK_IBAN => 'b1418262-6bc9-459c-b4b0-a054d77db0ea', # iban
    WK_BIC  => 'c8a3a132-f160-473c-b5f3-26a748f37e62', # bic
    WK_DOI  => '931f155e-5a24-499b-9fbb-ed4efefe27fe', # doi
    WK_FC   => 'd576b9d1-47d4-43ae-b7ec-bbea1fe009ba', # factgrid-identifier
    WK_UNICODE_CP => '5f167223-cc9c-4b2f-9928-9fe1b253b560', # unicode-code-point

    NS_WD   => '9e10aca7-4a99-43ac-9368-6cbfa43636df', # Wikidata-namespace
    NS_FC   => '6491f7a9-0b29-4ef1-992c-3681cea18182', # factgrid-namespace
    NS_INT  => '5dd8ddbb-13a8-4d6c-9264-36e6dd6f9c99', # integer-namespace
    NS_DATE => 'fc43fbba-b959-4882-b4c8-90a288b7d416', # gregorian-date-namespace
    NS_UNICODE_CP => '132aa723-a373-48bf-a88d-69f1e00f00cf', # 'unicode-character-namespace'
};

# Features:
my $enabled_oid = 1;

my %uuid_to_uriid_org = (
    WK_UUID() => 'uuid',
    WK_OID()  => 'oid',
    WK_URI()  => 'uri',
    WK_SID()  => 'sid',
    WK_GTIN() => 'gtin',
    WK_WD()   => 'wikidata-identifier',
);

my %uuid_org_to_uuid = map {$uuid_to_uriid_org{$_} => $_} keys %uuid_to_uriid_org;

my $well_known_uuid = __PACKAGE__->new(ise => WK_UUID, validate => RE_UUID);

my %well_known = (
    uuid => $well_known_uuid,
    oid  => __PACKAGE__->new($well_known_uuid => WK_OID,    validate => RE_OID),
    uri  => __PACKAGE__->new($well_known_uuid => WK_URI,    validate => RE_URI),
    sid  => __PACKAGE__->new($well_known_uuid => WK_SID,    validate => RE_UINT),
    wd   => __PACKAGE__->new($well_known_uuid => WK_WD,     validate => RE_QID, namespace => NS_WD, generate => 'id-based'),
    fc   => __PACKAGE__->new($well_known_uuid => WK_FC,     validate => RE_QID, namespace => NS_FC, generate => 'id-based'),
    gtin => __PACKAGE__->new($well_known_uuid => WK_GTIN,   validate => RE_UINT),
    iban => __PACKAGE__->new($well_known_uuid => WK_IBAN),
    bic  => __PACKAGE__->new($well_known_uuid => WK_BIC),
    doi  => __PACKAGE__->new($well_known_uuid => WK_DOI,    validate => RE_DOI),

    # Unofficial, not part of public API:
    unicodecp => __PACKAGE__->new($well_known_uuid => WK_UNICODE_CP, validate => RE_UNICODE, namespace => NS_UNICODE_CP, generate => 'id-based'),
);

my %registered;

$_->register foreach values %well_known;

# Refill with sids:
{
    my %wk_sids = (
        'ddd60c5c-2934-404f-8f2d-fcb4da88b633'  =>   1, # also-shares-identifier
        WK_UUID()                               =>   2,
        'bfae7574-3dae-425d-89b1-9c087c140c23'  =>   3, # tagname
        '7f265548-81dc-4280-9550-1bd0aa4bf748'  =>   4, # has-type
        WK_URI()                                =>   5,
        WK_OID()                                =>   6,
        # Unassigned: 7
        'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1'  =>   8, # language-tag-identifier
        WK_WD()                                 =>   9,
        '923b43ae-a50e-4db3-8655-ed931d0dd6d4'  =>  10, # specialises
        'eacbf914-52cf-4192-a42c-8ecd27c85ee1'  =>  11, # unicode-string
        '928d02b0-7143-4ec9-b5ac-9554f02d3fb1'  =>  12, # integer
        'dea3782c-6bcb-4ce9-8a39-f8dab399d75d'  =>  13, # unsigned-integer
        # Unassigned: 14, 15
        '6ba648c2-3657-47c2-8541-9b73c3a9b2b4'  =>  16, # default-context
        '52a516d0-25d8-47c7-a6ba-80983e576c54'  =>  17, # proto-file
        '1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d'  =>  18, # final-file-size
        '6085f87e-4797-4bb2-b23d-85ff7edc1da0'  =>  19, # text-fragment
        '4c9656eb-c130-42b7-9348-a1fee3f42050'  =>  20, # also-list-contains-also
        '298ef373-9731-491d-824d-b2836250e865'  =>  21, # proto-message
        '7be4d8c7-6a75-44cc-94f7-c87433307b26'  =>  22, # proto-entity
        '65bb36f2-b558-48af-8512-bca9150cca85'  =>  23, # proxy-type
        'a1c478b5-0a85-4b5b-96da-d250db14a67c'  =>  24, # flagged-as
        '59cfe520-ba32-48cc-b654-74f7a05779db'  =>  25, # marked-as
        '2bffc55d-7380-454e-bd53-c5acd525d692'  =>  26, # roaraudio-error-number
        WK_SID()                                =>  27,
        'd2750351-aed7-4ade-aa80-c32436cc6030'  =>  28, # also-has-role
        # Unassigned: 29, 30, 31
        '448c50a8-c847-4bc7-856e-0db5fea8f23b'  =>  32, # final-file-encoding
        '79385945-0963-44aa-880a-bca4a42e9002'  =>  33, # final-file-hash
        '3fde5688-6e34-45e9-8f33-68f079b152c8'  =>  34, # SEEK_SET
        'bc598c52-642e-465b-b079-e9253cd6f190'  =>  35, # SEEK_CUR
        '06aff30f-70e8-48b4-8b20-9194d22fc460'  =>  36, # SEEK_END
        '59a5691a-6a19-4051-bc26-8db82c019df3'  =>  37, # inode
        '2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a'  => 112, # chat-0-word-identifier
        WK_GTIN()                               => 160,
    );

    foreach my $ise (keys %wk_sids) {
        my $identifier = __PACKAGE__->new(ise => $ise);
        $identifier->{id_cache} //= {};
        $identifier->{id_cache}->{WK_SID()} //= $wk_sids{$ise};
        $identifier->register; # re-register
    }
}

# Some extra tags such as namespaces:
foreach my $ise (NS_WD, NS_INT, NS_DATE) {
    my $identifier = __PACKAGE__->new(ise => $ise);
    $identifier->register; # re-register
}

# Refill with displaynames
{
    my %displaynames = (
        WK_UUID()                               => 'uuid',
        WK_OID()                                => 'oid',
        WK_URI()                                => 'uri',
        WK_SID()                                => 'small-identifier',
        WK_WD()                                 => 'wikidata-identifier',
        WK_GTIN()                               => 'gtin',
        WK_IBAN()                               => 'iban',
        WK_BIC()                                => 'bic',
        WK_DOI()                                => 'doi',
        WK_FC()                                 => 'factgrid-identifier',
        WK_UNICODE_CP()                         => 'unicode-code-point',
        NS_WD()                                 => 'Wikidata-namespace',
        NS_FC()                                 => 'factgrid-namespace',
        NS_INT()                                => 'integer-namespace',
        NS_DATE()                               => 'gregorian-date-namespace',
        NS_UNICODE_CP()                         => 'unicode-character-namespace',

        'ddd60c5c-2934-404f-8f2d-fcb4da88b633'  => 'also-shares-identifier',
        'bfae7574-3dae-425d-89b1-9c087c140c23'  => 'tagname',
        '7f265548-81dc-4280-9550-1bd0aa4bf748'  => 'has-type',
        'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1'  => 'language-tag-identifier',
        '923b43ae-a50e-4db3-8655-ed931d0dd6d4'  => 'specialises',
        'eacbf914-52cf-4192-a42c-8ecd27c85ee1'  => 'unicode-string',
        '928d02b0-7143-4ec9-b5ac-9554f02d3fb1'  => 'integer',
        'dea3782c-6bcb-4ce9-8a39-f8dab399d75d'  => 'unsigned-integer',
        '6ba648c2-3657-47c2-8541-9b73c3a9b2b4'  => 'default-context',
        '52a516d0-25d8-47c7-a6ba-80983e576c54'  => 'proto-file',
        '1cd4a6c6-0d7c-48d1-81e7-4e8d41fdb45d'  => 'final-file-size',
        '6085f87e-4797-4bb2-b23d-85ff7edc1da0'  => 'text-fragment',
        '4c9656eb-c130-42b7-9348-a1fee3f42050'  => 'also-list-contains-also',
        '298ef373-9731-491d-824d-b2836250e865'  => 'proto-message',
        '7be4d8c7-6a75-44cc-94f7-c87433307b26'  => 'proto-entity',
        '65bb36f2-b558-48af-8512-bca9150cca85'  => 'proxy-type',
        'a1c478b5-0a85-4b5b-96da-d250db14a67c'  => 'flagged-as',
        '59cfe520-ba32-48cc-b654-74f7a05779db'  => 'marked-as',
        '2bffc55d-7380-454e-bd53-c5acd525d692'  => 'roaraudio-error-number',
        'd2750351-aed7-4ade-aa80-c32436cc6030'  => 'also-has-role',
        '448c50a8-c847-4bc7-856e-0db5fea8f23b'  => 'final-file-encoding',
        '79385945-0963-44aa-880a-bca4a42e9002'  => 'final-file-hash',
        '3fde5688-6e34-45e9-8f33-68f079b152c8'  => 'SEEK_SET',
        'bc598c52-642e-465b-b079-e9253cd6f190'  => 'SEEK_CUR',
        '06aff30f-70e8-48b4-8b20-9194d22fc460'  => 'SEEK_END',
        '59a5691a-6a19-4051-bc26-8db82c019df3'  => 'inode',
        '2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a'  => 'chat-0-word-identifier',
    );

    foreach my $ise (keys %displaynames) {
        my $identifier = __PACKAGE__->new(ise => $ise);
        $identifier->{displayname} //= $displaynames{$ise};
        $identifier->register; # re-register
    }
}

{
    # ISE -> namespace
    my %namespaces_uint = (
        '2bffc55d-7380-454e-bd53-c5acd525d692' => '744eaf4e-ae93-44d8-9ab5-744105222da6', # roaraudio-error-number: roaraudio-error-namespace
        '4a7fc2e2-854b-42ec-b24f-c7fece371865' => 'ac59062c-6ba2-44de-9f54-09e28f2c0b5c', # e621-post-identifier: e621-post-namespace
        'a0a4fae2-be6f-4a51-8326-6110ba845a16' => '69b7ff38-ca78-43a8-b9ea-66cb02312eef', # e621-pool-identifier: e621-pool-namespace
    );

    foreach my $ise (keys %namespaces_uint) {
        my $identifier = __PACKAGE__->new(ise => $ise);
        $identifier->{namespace}    //= __PACKAGE__->new(ise => $namespaces_uint{$ise});
        $identifier->{validate}     //= RE_UINT;
        $identifier->{generate}     //= 'id-based';
        $identifier->register; # re-register
    }

    # validate => RE_QID, namespace => NS_FC, generate => 'id-based'
}

# Call this after after we loaded all our stuff and before anyone else will register stuff:
__PACKAGE__->_known_provider('wellknown');


sub new {
    my ($pkg, $type, $id, %opts) = @_;
    my $self = bless {};

    if (!ref($type) && $type eq 'from') {
        if (ref($id)) {
            my $from = $id;
            if ($id->isa('Data::Identifier')) {
                if (scalar(keys %opts)) {
                    $type = $id->type;
                    $id   = $id->id;
                } else {
                    return $id;
                }
            } elsif ($id->isa('URI')) {
                $type = 'uri';
            } elsif ($id->isa('Data::URIID::Result')) {
                $opts{displayname} //= sub { return $from->attribute('displayname', default => undef) };
                $type = $id->id_type;
                $id   = $id->id;
            } elsif ($id->isa('Data::URIID::Base') || $id->isa('Data::URIID::Colour') || $id->isa('Data::URIID::Service')) {
                #$opts{displayname} //= $id->name if $id->isa('Data::URIID::Service');
                $opts{displayname} //= $id->displayname(default => undef, no_defaults => 1);
                $type = 'ise';
                $id   = $id->ise;
            } elsif ($id->isa('Data::TagDB::Tag')) {
                $opts{displayname} //= sub { $from->displayname };
                $type = 'ise';
                $id   = $id->ise;
            } elsif ($id->isa('Business::ISBN')) {
                $type = $well_known{gtin};
                $id   = $id->as_isbn13->as_string([]);
            } else {
                croak 'Unsupported input data';
            }
        } else {
            # If it's not a ref, try as ise.
            $type = 'ise';
        }
    }

    if (!ref($type) && $type eq 'ise') {
        croak 'Undefined identifier but type is ISE' unless defined $id;

        if ($id =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/) { # allow less normalised form than RE_UUID
            $type = $well_known_uuid;

            # For bootstrap only.
            if (!defined($type) && $id eq '8be115d2-dc2f-4a98-91e1-a6e3075cbc31') {
                $self->{type} = $well_known_uuid = $type = $self;
                $self->{id} = $id;
            }
        } elsif ($id =~ RE_OID) {
            $type = 'oid';
        } elsif ($id =~ RE_URI) {
            $type = 'uri';
        } else {
            croak 'Not a valid ISE identifier';
        }
    }

    unless (ref $type) {
        if ($type =~ /^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$/) { # allow less normalised form than RE_UUID
            $type = $pkg->new(uuid => $type);
            $type->register;
        } elsif ($type eq 'wellknown') {
            $self = $well_known{$id};
            croak 'Unknown well-known' unless defined $self;
            return $self;
        } else {
            $type = $well_known{$type};
        }
        croak 'Unknown type name' unless defined $type;
    }

    croak 'Not a valid type' unless $type->isa(__PACKAGE__);

    # we normalise URIs first as they may then normalised again
    if ($type == ($well_known{uri} // 0)) {
        my $uri = $id.''; # force stringification

        if ($uri =~ m#^urn:uuid:([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})$#) {
            $id = $1;
            $type = $well_known_uuid;
        } elsif ($uri =~ m#^urn:oid:([0-2](?:\.(?:0|[1-9][0-9]*))+)$#) {
            $id = $1;
            $type = $well_known{oid};
        } elsif ($uri =~ m#^https?://www\.wikidata\.org/entity/([QPL][1-9][0-9]*)$#) {
            $id = $1;
            $type = $well_known{wd};
        } elsif ($uri =~ m#^https?://doi\.org/(10\..+)$#) {
            $id = $1;
            $type = $well_known{doi};
        } elsif ($uri =~ m#^https?://uriid\.org/([^/]+)/[^/]+#) {
            my $ptype = $1;
            if (defined($uuid_org_to_uuid{$ptype}) || $ptype =~ RE_UUID) {
                my $u = URI->new($uri);
                my @path_segments = $u->path_segments;
                if (scalar(@path_segments) == 3 && $path_segments[0] eq '') {
                    $type = $pkg->new(uuid => ($uuid_org_to_uuid{$path_segments[1]} // $path_segments[1]));
                    $id = $path_segments[2];
                }
            }
        }
    }

    if ($type == ($well_known_uuid // 0)) {
        $id = lc($id); # normalise
    } elsif ($type == ($well_known{oid} // 0)) {
        if ($id =~ /^2\.25\.([1-9][0-9]*)$/) {
            my $hex = Math::BigInt->new($1)->as_hex;
            $hex =~ s/^0x//;
            $hex = ('0' x (32 - length($hex))) . $hex;
            $hex =~ s/^(.{8})(.{4})(.{4})(.{4})(.{12})$/$1-$2-$3-$4-$5/;
            $type = $well_known_uuid;
            $id = $hex;
        }
    }

    if (defined(my $v = $registered{$type->uuid}{$id})) {
        return $v;
    }


    if (defined $type->{validate}) {
        croak 'Identifier did not validate against type' unless $id =~ $type->{validate};
    }

    $self->{type} = $type;
    $self->{id} = $id;

    foreach my $key (qw(validate namespace generate displayname)) {
        next unless defined $opts{$key};
        $self->{$key} //= $opts{$key};
    }

    foreach my $key (qw(namespace)) {
        if (defined(my $v = $self->{$key})) {
            unless (ref $v) {
                $self->{$key} = $pkg->new(ise => $v);
            }
        }
    }

    return bless $self;
}


#@returns __PACKAGE__
sub random {
    my ($pkg, %opts) = @_;
    my $type = $opts{type} // 'uuid';

    if (ref $type) {
        if ($type == $well_known_uuid) {
            $type = 'uuid';
        } else {
            croak 'Invalid/Unsupported type';
        }
    }

    if ($type ne 'ise' && $type ne 'uuid') {
        croak 'Invalid/Unsupported type';
    }

    my $uuid = Data::Identifier::Generate->_random(%opts{'sources'});
    return $pkg->new(uuid => $uuid, %opts{'displayname'});
}



sub wellknown {
    my ($pkg, @args) = @_;
    return $pkg->known('wellknown', @args);
}


#@returns __PACKAGE__
sub type {
    my ($self) = @_;
    return $self->{type};
}



sub id {
    my ($self) = @_;
    return $self->{id};
}


sub uuid {
    my ($self, %opts) = @_;

    return $self->{id_cache}{WK_UUID()} if !$opts{no_defaults} && defined($self->{id_cache}) && defined($self->{id_cache}{WK_UUID()});

    if ($self->{type} == $well_known_uuid) {
        return $self->{id};
    }

    unless ($opts{no_defaults}) {
        # Try to generate a UUID and recheck cache:
        $self->_generate;
        return $self->{id_cache}{WK_UUID()} if defined($self->{id_cache}) && defined($self->{id_cache}{WK_UUID()});
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier has no valid UUID';
}

sub oid {
    my ($self, %opts) = @_;
    my $type = $well_known{oid};

    return $self->{id_cache}{WK_OID()} if !$opts{no_defaults} && defined($self->{id_cache}) && defined($self->{id_cache}{WK_OID()});

    if ($self->{type} == $type) {
        return $self->{id};
    }

    unless ($opts{no_defaults}) {
        if (defined(my $uuid = $self->uuid(default => undef))) {
            return $self->{id_cache}{WK_OID()} = sprintf('2.25.%s', Math::BigInt->new('0x'.$uuid =~ tr/-//dr));
        }
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier has no valid OID';
}

sub uri {
    my ($self, %opts) = @_;
    my $type = $well_known{uri};

    return $self->{id_cache}{WK_URI()} if !$opts{no_defaults} && defined($self->{id_cache}) && defined($self->{id_cache}{WK_URI()});

    if ($self->{type} == $type) {
        return $self->{id};
    }

    unless ($opts{no_defaults}) {
        if ($self->{type} == $well_known{wd}) {
            return $self->{id_cache}{WK_URI()} = sprintf('http://www.wikidata.org/entity/%s', $self->{id});
        } elsif ($self->{type} == $well_known{doi}) {
            return $self->{id_cache}{WK_URI()} = sprintf('https://doi.org/%s', $self->{id});
        } elsif (defined(my $uuid = $self->uuid(default => undef))) {
            return $self->{id_cache}{WK_URI()} = sprintf('urn:uuid:%s', $uuid);
        } elsif ($enabled_oid && defined(my $oid = $self->oid(default => undef))) {
            return $self->{id_cache}{WK_URI()} = sprintf('urn:oid:%s', $oid);
        } else {
            my $u = URI->new("https://uriid.org/");
            my $type_uuid = $self->{type}->uuid;
            $u->path_segments('', $uuid_to_uriid_org{$type_uuid} // $type_uuid, $self->{id});
            return $self->{id_cache}{WK_URI()} = $u;
        }
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier has no valid URI';
}

sub sid {
    my ($self, %opts) = @_;
    my $type = $well_known{sid};
    return $self->{id_cache}{WK_SID()} if defined($self->{id_cache}) && defined($self->{id_cache}{WK_SID()});
    if ($self->{type} == $type) {
        return $self->{id};
    }

    return $opts{default} if exists $opts{default};
    croak 'Identifier has no valid SID';
}



sub ise {
    my ($self, %opts) = @_;
    my $type = $self->{type};
    my $have_default = exists $opts{default};
    my $default = delete $opts{default};
    my $value;

    if ($type == $well_known{uuid} || $type == $well_known{oid} || $type == $well_known{uri}) {
        $value = $self->{id};
    } else {
        $opts{default} = undef;
        $value = $self->uuid(%opts) // $self->oid(%opts) // $self->uri(%opts);
    }

    return $value if defined $value;
    return $default if $have_default;
    croak 'Identifier has no valid ISE';
}


sub as {
    my ($self, $as, %opts) = @_;

    $as = $opts{rawtype} if $as eq 'raw' && defined($opts{rawtype});

    return $self if ($as =~ /^[A-Z]/ || $as =~ /::/) && eval {$self->isa($as)};

    $self = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};

    if ($as eq 'uuid' || $as eq 'oid' || $as eq 'uri' || $as eq 'sid' || $as eq 'ise') {
        my $func = $self->can($as);
        return $self->$func(%opts);
    } elsif ($as eq __PACKAGE__) {
        return $self;
    } elsif ($as eq 'URI') {
        my $had_default = exists $opts{default};
        my $default = delete $opts{default};
        my $val = $self->uri(%opts, default => undef);

        return URI->new($val) if defined $val;
        if ($had_default) {
            return $default if ref $default;
            return URI->new($default);
        }
        croak 'No value for URI';
    } elsif ($as eq 'Data::URIID::Result' && defined($opts{extractor})) {
        return $opts{extractor}->lookup($self->type->uuid => $self->id);
    } elsif ($as eq 'Data::URIID::Service' && defined($opts{extractor})) {
        return $opts{extractor}->service($self->uuid);
    } elsif ($as eq 'Data::TagDB::Tag' && defined($opts{db})) {
        if ($opts{autocreate}) {
            return $opts{db}->create_tag($self);
        } else {
            return $opts{db}->tag_by_id($self);
        }
    } elsif ($as eq 'Business::ISBN' && $self->type->eq('gtin')) {
        require Business::ISBN;
        my $val = Business::ISBN->new($self->id);
        return $val if defined($val) && $val->is_valid;
    }

    return $opts{default} if exists $opts{default};
    croak 'Unknown/Unsupported as: '.$as;
}


sub eq {
    my ($self, $other) = @_;

    foreach my $e ($self, $other) {
        if (defined($e) && !scalar(eval {$e->isa(__PACKAGE__)})) {
            if (defined $well_known{$e}) {
                $e = $well_known{$e}
            } else {
                $e = Data::Identifier->new(from => $e);
            }
        }
    }

    if (defined($self)) {
        return undef unless defined $other;
        return 1 if $self == $other;
        return undef unless $self->type->eq($other->type);
        return $self->id eq $other->id;
    } else {
        return !defined($other);
    }
}


sub cmp {
    my ($self, $other) = @_;

    foreach my $e ($self, $other) {
        if (defined($e) && !scalar(eval {$e->isa(__PACKAGE__)})) {
            if (defined $well_known{$e}) {
                $e = $well_known{$e}
            } else {
                $e = Data::Identifier->new(from => $e);
            }
        }
    }

    if (defined($self)) {
        return undef unless defined $other;
        return 0 if $self == $other;
        if ((my $r = $self->type->cmp($other->type)) != 0) {
            return $r;
        }

        {
            my $self_id = $self->id;
            my $other_id = $other->id;

            if ((my ($sa, $sb) = $self_id =~ /^([^0-9]*)([0-9]+)$/) && (my ($oa, $ob) = $other_id =~ /^([^0-9]*)([0-9]+)$/)) {
                my $r = $sa cmp $oa;
                return $r if $r;
                return $sb <=> $ob;
            }

            return $self_id cmp $other_id;
        }
    } else {
        return !defined($other);
    }
}


#@returns __PACKAGE__
sub namespace {
    my ($self) = @_;
    return $self->{namespace} // croak 'No namespace';
}


sub register {
    my ($self) = @_;
    $registered{$self->{type}->uuid}{$self->{id}} = $self;

    foreach my $type_name (qw(uuid oid uri sid)) {
        my $f = $self->can($type_name) || next;
        my $v = $self->$f(default => undef) // next;
        $registered{$well_known{$type_name}->uuid}{$v} = $self;
    }
}


sub userdata {
    my ($self, $package, $key, $value) = @_;
    $self->{userdata} //= {};
    $self->{userdata}{$package} //= {};
    return $self->{userdata}{$package}{$key} = $value // $self->{userdata}{$package}{$key};
}


sub displayname {
    my ($self, %opts) = @_;

    if (defined(my $displayname = $self->{displayname})) {
        $displayname = $self->$displayname() if ref $displayname;

        # recheck and return as any of the above conversions could result in $displayname becoming invalid.
        return $displayname if defined($displayname) && length($displayname);
    }

    return $self->id.'' unless $opts{no_defaults}; # force stringification.
    return $opts{default} if exists $opts{default};
    croak 'No value for displayname';
}


sub displaycolour { my ($self, %opts) = @_; return $opts{default}; }
sub icontext { my ($self, %opts) = @_; return $opts{default}; }
sub description { my ($self, %opts) = @_; return $opts{default}; }

# ---- Private helpers ----

sub import {
    my ($pkg, $opts) = @_;
    return unless defined $opts;
    croak 'Bad options' unless ref($opts) eq 'HASH';

    if (defined(my $disable = $opts->{disable})) {
        $disable = [split /\s*,\s*/, $disable] unless ref $disable;
        foreach my $to_disable (@{$disable}) {
            if ($to_disable eq 'oid') {
                $enabled_oid = undef;
                undef *oid;
            } else {
                croak 'Unknown feature: '.$to_disable;
            }
        }
    }
}

sub _generate {
    my ($self) = @_;
    unless (exists $self->{_generate}) {
        my __PACKAGE__ $type = $self->type;

        if (defined(my $generate = $type->{generate})) {
            unless (ref $generate) {
                $self->{generate} = $generate = {style => $generate};
            }

            $self->{id_cache} //= {};

            if (defined(my __PACKAGE__ $ns = eval {$type->namespace->uuid})) {
                my $style = $generate->{style};
                my $input;

                if ($style eq 'id-based') {
                    $input = lc($self->id);
                } else {
                    croak 'Unsupported generator style';
                }

                if (defined $input) {
                    $self->{id_cache}{WK_UUID()} = Data::Identifier::Generate->_uuid_v5($ns, $input);
                }
            }
        }
    }
    $self->{_generate} = undef;
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);

    if ($class eq 'wellknown') {
        state $wellknown = do {
            my %hash = map{$_ => $_} values(%well_known), map {values %{$_}} values(%registered);
            [values %hash];
        };

        return ($wellknown, rawtype => __PACKAGE__);
    } elsif ($class eq 'registered' || $class eq ':all') {
        my %hash = map{$_ => $_} values(%well_known), map {values %{$_}} values(%registered);
        return ([values %hash], rawtype => __PACKAGE__);
    }

    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier - format independent identifier object

=head1 VERSION

version v0.09

=head1 SYNOPSIS

    use Data::Identifier;
    # or:
    use Data::Identifier {option => value, ...};

    my Data::Identifier $id = Data::Identifier->new(uuid => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633');
    my Data::Identifier $id = Data::Identifier->new(oid => '2.1.0.1.0');

    my Data::Identifier $custom_type = Data::Identifier->new(uuid => ...);
    my Data::Identifier $id = Data::Identifier->new($custom_type => '123abc');

    my Data::Identifier $type = $id->type;
    my $raw = $id->id;

    my $uuid = $id->uuid;
    my $oid  = $id->oid;
    my $uri  = $id->uri;
    my $ise  = $id->ise;

This module provides an common interface to identifiers of different types.
Each identifier stores both it's raw value (called C<id>) and it's type (C<type>).

B<Note:> Validation on the raw identifier value may or may not be performed depending on the type.
The level of validation this module can do is limited by it's knowledge about the type as well
as performance aspects. This module may therefore reject invalid values. But it is not safe to assume
that it will reject all invalid values.

B<Note:> This module performs basic deduplication and normalisation. This means that you
might not always get back exactly the identifier you passed in but an equivalent one.
Also note that deduplication is done with performance in mind. This means that there is no
guarantee for two equal identifiers to become deduplicated. See also L</register>.

This package inherits from L<Data::Identifier::Interface::Known>.

=head2 OPTIONS

The following options are supported. Some are marked as experimental.

=head3 disable

B<Note:>
This is an B<experimental> option. It may be changed, renamed, or removed without notice.

This option allows to disable a feature.
This is a global setting, and therefore should only be used at the top level code.

In order for this to be most effective this should be used in the top level code
before any other module is C<use>-ed or C<require>-ed that makes use of this module.

This setting takes an arrayref of strings or a single string that is a comma separated list.

Currently the following features can be disabled:

=over

=item C<oid>

Support for OID. This removes the L</oid> function from this package,
removes internal OID based caches, and parts of the OID detection and normalisation logic.

However this improves the speed of L</register> and some others significantly.

This feature should only be disabled if you're sure you will not use OIDs in your code.

=back

=head1 METHODS

=head2 new

    my Data::Identifier $identifier = Data::Identifier->new($type => $id, %opts);

Creates a new identifier.

C<$type> needs to be a L<Data::Identifier>, a well known name, a UUID, C<wellknown>, C<ise>, or C<from>.

If it is an UUID a type is created as needed.

If it is C<ise> it is parsed as C<uuid>, C<oid>, or C<uri> according to it's format.

If it is C<wellknown> it refers to an identifier from the well known list.

If it is C<from> then C<$id> should refer to an object of some kind that should be converted to identifier.
In this case not all options might be supported. Currently it is possible to convert from:
L<Data::Identifier>,
L<Data::URIID::Colour>, L<Data::URIID::Service>, L<Data::URIID::Result>,
L<Data::TagDB::Tag>,
and L<Business::ISBN>. If C<$id> is not a reference it is parsed as with C<ise>.

The following type names are currently well known:

=over

=item C<uuid>

An UUID.

=item C<oid>

An OID.

=item C<uri>

An URI.

=item C<wd>

An wikidata identifier (Q, P, or L).

=item C<fc>

An FactGrid identifier (Q, P, or L).

=item C<gtin>

An GTIN (or EAN).

=item C<iban>

An IBAN (International Bank Account Number).

=item C<bic>

A BIC (Business Identifier Code).

=item C<doi>

A doi (digital object identifier).

=back

The following options are supported:

=over

=item C<validate>

A regex that should be used to validate identifiers if this identifier is used as a type.

=item C<namespace>

The namespace used by a type. Must be a L<Data::Identifier> or an ISE. Must also resolve to an UUID.

=item C<displayname>

The name as to be returned by L</displayname>.
Must be a scalar string value or a code reference that returns a scalar string.
If it is a code reference the identifier object is passed as C<$_[0]>.

=item C<extractor>

An instance of L<Data::URIID>. This option is currently ignored.

=item C<db>

An instance of L<Data::TagDB>. This option is currently ignored.

=back

=head2 random

    my Data::Identifier $identifier = Data::Identifier->random([ %opts ]);

Generate a new random identifier.
This method will C<die> on error.

The following options (all optional) are supported:

=over

=item C<displayname>

The same as the option of the same name in L</new>. See also L</displayname>.

=item C<sources>

The backend data sources to use for generation of the identifier. This is an array reference
with the names of the modules in order of preference (most preferred first).

Defaults to a list of high quality sources.

Currently supported are at least:
L<Crypt::URandom>,
L<UUID4::Tiny>,
L<Math::Random::Secure>,
L<UUID::URandom>,
L<UUID::Tiny::Patch::UseMRS>,
L<UUID::Tiny> (low quality).

=item C<type>

The type to generate a random identifier in.
A L<Data::Identifier> or one of the special values C<uuid> or C<ise>.

=back

=head2 known

    my @list = Data::Identifier->known($class [, %opts ] );

This module implements L<Data::Identifier::Interface::Known/known>. See there for details.

Supported classes:

=over

=item C<wellknown>

Returns a list with all well known identifiers.

This is useful to prime a database.

=item C<registered>

Returns the list of all currently registered identifiers.

=item C<:all>

Returns the list of all currently known identifiers.

=back

=head2 wellknown

    my @wellknown = Data::Identifier->wellknown(%opts);

This is an alias for:

    my @wellknown = Data::Identifier->known('wellknown', %opts);

See also L</known>.

=head2 type

    my Data::Identifier $type = $identifier->type;

Returns the type of the identifier.

=head2 id

    my $id = $identifier->id;

Returns the raw id of the identifier.

=head2 uuid, oid, uri, sid

    my $uuid = $identifier->uuid( [ %opts ] );
    my $oid  = $identifier->oid( [ %opts ] );
    my $uri  = $identifier->uri( [ %opts ] );
    my $sid  = $identifier->sid( [ %opts ] );

Return the UUID, OID, URI, or SID (small-identifier) of the current identifier or die if no identifier of that type is known nor can be calculated.

The following options (all optional) are supported:

=over

=item C<default>

The default value to return if no other value is available.
This can be set to C<undef> to change the method from C<die>ing in failture to returning C<undef>.

=item C<no_defaults>

If set true do not try to generate a matching identifier.
Note: This does not apply to C<sid()> as small-identifiers cannot be generated. For C<sid()> the option is ignored.

=back

=head2 ise

    my $ise = $identifier->ise( [ %opts ] );

Returns the ISE (UUID, OID, or URI) for the current identifier or die if no ISE is known nor can be calculated.

Supports all options also supported by L</uuid>, L</oid>, and L</uri>.

=head2 as

    my $res = $identifier->as($as, %opts);
    # or:
    my $res = $identifier->Data::Identifier::as($as, %opts); # $identifier is an alien type

This method converts the given identifier to another type of object.

C<$as> must be a name of the package (containing C<::> or starting with an uppercase letter),
or one of the special values.

Currently the following packages are supported:
L<URI>,
L<Data::Identifier>,
L<Data::URIID::Result>,
L<Data::URIID::Service>,
L<Data::TagDB::Tag>,
L<Business::ISBN>.
Other packages might be supported. Packages need to be installed in order to be supported.
Also some packages need special options to be passed to be available.

The folliwng special values are supported:
C<uuid>, C<oid>, C<uri>, C<sid>, C<ise>, and C<raw>.
All but C<raw> are aliases to the corresponding functions.
C<raw> is an alias for the type set with the C<rawtype> option (see below).

If C<$identifier> is or may not be an L<Data::Identifier> this method can be called like
C<$identifier-E<gt>Data::Identifier::as($as...)>.
In that case C<$identifier> is parsed as with C<from> in L</new>.

If C<$identifier> is a C<$as> (see also C<rawtype> below) then C<$identifier> is returned as-is,
even if C<$as> would not be supported otherwise.

The following options (all optional) are supported:

=over

=item C<autocreate>

If the requested type refers to some permanent storage and the object does not exist for
the given identifier whether to create a new object or not.

Defaults to false.

=item C<db>

An instance of L<Data::TagDB>. This is used to create instances of related packages.

=item C<default>

Same as in L</uuid>.

=item C<no_defaults>

Same as in L</uuid>.

=item C<rawtype>

If C<$as> is given as C<raw> then this value is used for C<$as>.
This can be used to ease implementation of other methods that are required to accept C<raw>.

=item C<extractor>

An instance of L<Data::URIID>. This is used to create instances of related packages
such as L<Data::URIID::Result>.

=back

=head2 eq

    my $bool = $identifier->eq($other); # $identifier must be non-undef
    # or:
    my $bool = Data::Identifier::eq($identifier, $other); # $identifier can be undef

Compares two identifiers to be equal.

If both identifiers are C<undef> they are considered equal.

If C<$identifier> or C<$other> is not an instance of L<Data::Identifier> or C<undef>
then it is checked against the list of well known identifiers (see L</new>).
If it has still no match L</new> with the virtual type C<from> is used.

=head2 cmp

    my $val = $identifier->cmp($other); # $identifier must be non-undef
    # or:
    my $val = Data::Identifier::cmp($identifier, $other); # $identifier can be undef

Compares the identifiers similar to C<cmp>. This method can be used to order identifiers.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

The order is stable

=item *

Identifiers are ordered by type first

=item *

If the all identifiers have the same type this method tries to be smart about ordering
(ordering numeric values correctly).

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

=head2 namespace

    my Data::Identifier $namespace = $identifier->namespace;

Gets the namespace for the type C<$identifier> or dies.
This call is only valid for identifiers that are types.

=head2 register

    $identifier->register;

Registers the identifier for deduplication.
This can be used to register much used identifiers and types
early in an application to increase performance.
However, note that once registered an identifier object is cached for
the life time of the process.

=head2 userdata

    my $value = $identifier->userdata(__PACKAGE__, $key);
    $identifier->userdata(__PACKAGE__, $key => $value);

Get or set user data to be used with this identifier. The data is stored using the given C<$key>.
The package of the caller is given to provide namespaces for the userdata, so two independent packages
can use the same C<$key>.

The meaning of C<$key>, and C<$value> is up to C<__PACKAGE__>.

=head2 displayname

    my $displayname = $identifier->displayname( [ %opts ] );

Returns a display name suitable to display to the user. This function always returns a string.
This is mostly for compatibility with L<Data::TagDB::Tag>.

The following options (all optional) are supported:

=over

=item C<default>

The default value to return if no other value is available.
This can be set to C<undef> to let this method return undef (not die).

=item C<no_defaults>

If set true do not try to use any identifier or other fallback as displayname.

=back

=head2 displaycolour, icontext, description

    my $displaycolour = $identifier->displaycolour( [ %opts ] );
    my $icontext      = $identifier->icontext( [ %opts ] );
    my $description   = $identifier->description( [ %opts ] );

These functions always return C<undef>. They are for compatibility with L<Data::TagDB::Tag>.

The following options (all optional) are supported:

=over

=item C<default>

The default value to return if no other value is available (which is always the case).
This is for compatibility with L</displayname> and implementations of other packages.

=item C<no_defaults>

This option is accepted but ignored.
This is for compatibility with L</displayname> and implementations of other packages.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
