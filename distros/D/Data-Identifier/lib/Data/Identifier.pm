#!/usr/bin/perl -w

# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.01;

use constant {
    RE_UUID => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/,
    RE_OID  => qr/^[0-2](\.(?:0|[1-9][0-9]*))+$/,
    RE_URI  => qr/^[a-zA-Z][a-zA-Z0-9\+\.\-]+/,
    RE_UINT => qr/^(?:0|[1-9][0-9]*)$/,
    RE_WD   => qr/^[QPL][1-9][0-9]*$/,
};

use constant {
    WK_UUID => '8be115d2-dc2f-4a98-91e1-a6e3075cbc31', # uuid
    WK_OID  => 'd08dc905-bbf6-4183-b219-67723c3c8374', # oid
    WK_URI  => 'a8d1637d-af19-49e9-9ef8-6bc1fbcf6439', # uri
    WK_SID  => 'f87a38cb-fd13-4e15-866c-e49901adbec5', # small-identifier
    WK_WD   => 'ce7aae1e-a210-4214-926a-0ebca56d77e3', # wikidata-identifier
    WK_GTIN => '82d529be-0f00-4b4f-a43f-4a22de5f5312', # gtin

    NS_WD   => '9e10aca7-4a99-43ac-9368-6cbfa43636df', # Wikidata-namespace
};

my $well_known_uuid = __PACKAGE__->new(ise => WK_UUID, validate => RE_UUID);

my %well_known = (
    uuid => $well_known_uuid,
    oid  => __PACKAGE__->new($well_known_uuid => WK_OID,    validate => RE_OID),
    uri  => __PACKAGE__->new($well_known_uuid => WK_URI,    validate => RE_URI),
    sid  => __PACKAGE__->new($well_known_uuid => WK_SID,    validate => RE_UINT),
    wd   => __PACKAGE__->new($well_known_uuid => WK_WD,     validate => RE_WD,   namespace => NS_WD, generate => 'id-based'),
    gtin => __PACKAGE__->new($well_known_uuid => WK_GTIN,   validate => RE_UINT),
);

my %registered;

$_->register foreach values %well_known;

# Refill with sids:
{
    my %wk_sids = (
        'ddd60c5c-2934-404f-8f2d-fcb4da88b633'  => 1, # also-shares-identifier
        WK_UUID()                               => 2,
        'bfae7574-3dae-425d-89b1-9c087c140c23'  => 3, # tagname
        '7f265548-81dc-4280-9550-1bd0aa4bf748'  => 4, # has-type
        WK_URI()                                => 5,
        WK_OID()                                => 6,
        # Unassigned: 7
        'd0a4c6e2-ce2f-4d4c-b079-60065ac681f1'  => 8, # language-tag-identifier
        WK_WD()                                 => 9,
        WK_SID()                                => 27,
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
foreach my $ise (NS_WD) {
    my $identifier = __PACKAGE__->new(ise => $ise);
    $identifier->register; # re-register
}

# Call this after after we loaded all our stuff and before anyone else will register stuff:
__PACKAGE__->wellknown;


sub new {
    my ($pkg, $type, $id, %opts) = @_;
    my $self = bless {};

    if (!ref($type) && $type eq 'ise') {
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

    if ($type == ($well_known_uuid // 0)) {
        $id = lc($id); # normalise

    }

    if (defined(my $v = $registered{$type->uuid}{$id})) {
        return $v;
    }


    if (defined $type->{validate}) {
        croak 'Identifier did not validate against type' unless $id =~ $type->{validate};
    }

    $self->{type} = $type;
    $self->{id} = $id;

    foreach my $key (qw(validate namespace generate)) {
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


sub wellknown {
    my ($pkg) = @_;
    state $well_known = {map{$_ => $_} values(%well_known), map {values %{$_}} values(%registered)};

    return values %{$well_known};
}


sub type {
    my ($self) = @_;
    return $self->{type};
}



sub id {
    my ($self) = @_;
    return $self->{id};
}


sub uuid {
    my ($self) = @_;
    return $self->{id_cache}{WK_UUID()} if defined($self->{id_cache}) && defined($self->{id_cache}{WK_UUID()});
    if ($self->{type} == $well_known_uuid) {
        return $self->{id};
    }

    # Try to generate a UUID and recheck cache:
    $self->_generate;
    return $self->{id_cache}{WK_UUID()} if defined($self->{id_cache}) && defined($self->{id_cache}{WK_UUID()});

    croak 'Identifier has no valid UUID';
}

sub oid {
    my ($self) = @_;
    my $type = $well_known{oid};
    return $self->{id_cache}{$type->ise} if defined($self->{id_cache}) && defined($self->{id_cache}{$type->ise});
    if ($self->{type} == $type) {
        return $self->{id};
    }

    croak 'Identifier has no valid OID';
}

sub uri {
    my ($self) = @_;
    my $type = $well_known{uri};
    return $self->{id_cache}{$type->ise} if defined($self->{id_cache}) && defined($self->{id_cache}{$type->ise});
    if ($self->{type} == $type) {
        return $self->{id};
    }

    croak 'Identifier has no valid URI';
}

sub sid {
    my ($self) = @_;
    my $type = $well_known{sid};
    return $self->{id_cache}{$type->ise} if defined($self->{id_cache}) && defined($self->{id_cache}{$type->ise});
    if ($self->{type} == $type) {
        return $self->{id};
    }

    croak 'Identifier has no valid SID';
}



sub ise {
    my ($self) = @_;
    return eval {$self->uuid} // eval {$self->oid} // $self->uri;
}


sub namespace {
    my ($self) = @_;
    return $self->{namespace} // croak 'No namespace';
}


sub register {
    my ($self) = @_;
    $registered{$self->{type}->uuid}{$self->{id}} = $self;

    foreach my $type_name (qw(uuid oid uri sid)) {
        my $f = $self->can($type_name) || next;
        my $v = eval {$self->$f()} // next;
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
    my ($self) = @_;
    return $self->id.''; # force stringification.
}


sub displaycolour { return undef; }
sub icontext { return undef; }
sub description { return undef; }

# Private helpers:

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
                    require UUID::Tiny;

                    $self->{id_cache}{WK_UUID()} = UUID::Tiny::create_uuid_as_string(UUID::Tiny::UUID_SHA1(), $ns, $input);
                }
            }
        }
    }
    $self->{_generate} = undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier - format independent identifier object

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Data::Identifier;

This module provides an common interface to identifiers of different types.
Each identifier stores both it's raw value (called C<id>) and it's type (C<type>).

B<Note:> This module performs basic deduplication and normalisation. This means that you
might not always get back exactly the identifier you passed in but an equivalent one.
Also note that deduplication is done with performance in mind. This means that there is no
guarantee for two equal identifiers to become deduplicated. See also L</register>.

=head2 new

    my Data::Identifier $identifier = Data::Identifier->new($type => $id, %opts);

Creates a new identifier.

C<$type> needs to be a L<Data::Identifier>, a well known name, a UUID, C<wellknown>, or C<ise>.
If it is an UUID a type is created as needed.
If it is C<ise> it is parsed as C<uuid>, C<oid>, or C<uri> according to it's format.
If it is C<wellknown> it refers to an identifier from the well known list.

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

=item C<gtin>

An GTIN (or EAN).

=back

The following options are supported:

=over

=item C<validate>

A regex that should be used to validate identifiers if this identifier is used as a type.

=item C<namespace>

The namespace used by a type. Must be a L<Data::Identifier> or an ISE. Must also resolve to an UUID.

=back

=head2 wellknown

    my @wellknown = Data::Identifier->wellknown;

Returns a list with all well known identifiers.

This is mostly useful to prime a database.

=head2 type

    my Data::Identifier $type = $identifier->type;

Returns the type of the identifier.

=head2 id

    my $id = $identifier->id;

Returns the raw id of the identifier.

=head2 uuid, oid, uri, sid

    my $uuid = $identifier->uuid;
    my $oid  = $identifier->oid;
    my $uri  = $identifier->uri;
    my $sid  = $identifier->sid;

Return the UUID, OID, URI, or SID (small-identifier) of the current identifier or die if no identifier of that type is known nor can be calculated.

=head2 ise

    my $ise = $identifier->ise;

Returns the ISE (UUID, OID, or URI) for the current identifier or die if no ISE is known nor can be calculated.

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

    my $displayname = $identifier->displayname;

Returns a display name suitable to display to the user. This function always returns a string.
This is mostly for compatibility with L<Data::TagDB::Tag>.

=head2 displaycolour, icontext, description

    my $displaycolour = $identifier->displaycolour;
    my $icontext      = $identifier->icontext;
    my $description   = $identifier->description;

These functions always return C<undef>. They are for compatibility with L<Data::TagDB::Tag>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
