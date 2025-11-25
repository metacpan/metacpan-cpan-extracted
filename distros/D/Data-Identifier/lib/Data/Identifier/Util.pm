# Copyright (c) 2023-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Util;

use v5.14;
use strict;
use warnings;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects);

use Carp;

use Data::Identifier;

our $VERSION = v0.26;

my $_DEFAULT_INSTANCE = __PACKAGE__->new;

my %_4plus12_prefix = (
    sni => (0<<15)|(0<<14),
    sid => (0<<15)|(1<<14),
    hdi => (1<<15)|(0<<14),
    udi => (1<<15)|(1<<14),
);

my $_logical = '5e80c7b7-215e-4154-b310-a5387045c336';

my %_raes_to_raen = (
    NONE    =>  0,
    NOENT   =>  2,
    NOSYS   =>  6,
    NOTSUP  =>  7,
    NOMEM   => 12,
    INVAL   => 13,
    FAULT   => 18,
    IO      => 19,
    NODATA  => 25,
    NOSPC   => 38,
    TYPEMM  => 39,
    RO      => 45,
    ILLSEQ  => 56,
    BADEXEC => 79,
    BADFH   => 83,
);
my %_logicals_to_sni = (
    sni     =>  10,
    sid     => 115,
    raen    => 116,
    chat0w  => 118,
    uuid    => 119,
    uri     => 121,
    asciicp => 122,
    oid     => 120,
    wd      => 123,
    logical => 129,
    false   => 189,
    true    => 190,
);
my %_logicals_to_sid = (
    asi         => 1,
    tagname     => 3,
    SEEK_SET    => 34,
    SEEK_CUR    => 35,
    SEEK_END    => 36,
    backwards   => 43,
    forwards    => 44,
    black       => 61,
    white       => 62,
    grey        => 63,
    red         => 119,
    green       => 120,
    blue        => 121,
    cyan        => 122,
    magenta     => 123,
    yellow      => 124,
    orange      => 125,
    gtin        => 160,
    left        => 192,
    right       => 193,
    up          => 194,
    down        => 195,
    north       => 208,
    east        => 209,
    south       => 210,
    west        => 211,
);


sub new {
    my ($pkg, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return bless {}, $pkg;
}


sub pack {
    my ($self, $template, $identifier, @opts) = _normalise_args(@_);
    my $pack_template;
    my $v;

    croak 'Stray options passed' if scalar @opts;

    $template //= '<undef>';
    $identifier = Data::Identifier->new(from => $identifier) unless eval {$identifier->isa('Data::Identifier')};

    if ($template =~ /^(sid|sni|hdi|udi)([1-9][0-9]*)$/) {
        my $bits = int($2);

        $v = $identifier->as(Data::Identifier->new(wellknown => $1), no_defaults => 1);

        if ($bits == 8) {
            $pack_template = 'C';
        } elsif ($bits == 16) {
            $pack_template = 'n';
        } elsif ($bits == 32) {
            $pack_template = 'N';
        } else {
            croak 'Invalid width: '.$bits;
        }
    } elsif ($template eq '4+12') {
        my $prefix;

        foreach my $type (qw(sid sni hdi udi)) {
            $v = $identifier->as(Data::Identifier->new(wellknown => $type), no_defaults => 1, default => undef);
            if (defined $v) {
                if ($v < 0 || $v > 0x0FFF) {
                    next;
                }
                $v |= $_4plus12_prefix{$type};
                $pack_template = 'n';
                last;
            }
        }
    } elsif ($template eq 'uuid128') {
        return pack('H*', $identifier->uuid(no_defaults => 1) =~ tr/-//dr);
    }

    if (defined($v) && defined($pack_template)) {
        my ($min, $max);

        if ($pack_template eq 'C') {
            ($min, $max) = (0, 0xFF);
        } elsif ($pack_template eq 'n') {
            ($min, $max) = (0, 0xFFFF);
        } elsif ($pack_template eq 'N') {
            ($min, $max) = (0, 0xFFFF_FFFF);
        }

        if ((defined($min) && $v < $min) || (defined($max) && $v > $max)) {
            croak 'Identifier not in range for '.$template.': '.$v;
        }

        return pack($pack_template, $v);
    }

    croak 'Unknown template: '.$template;
}


sub unpack {
    my ($self, $template, $data, @opts) = _normalise_args(@_);
    my $pack_template;
    my $type;

    croak 'Stray options passed' if scalar @opts;

    if ($template =~ /^(sid|sni|hdi|udi)([1-9][0-9]*)$/) {
        my $bits = int($2);
        $type = $1;

        if ($bits == 8) {
            $pack_template = 'C';
        } elsif ($bits == 16) {
            $pack_template = 'n';
        } elsif ($bits == 32) {
            $pack_template = 'N';
        } else {
            croak 'Invalid width: '.$bits;
        }
    } elsif ($template eq '4+12') {
        my $v;
        my $prefix;

        croak 'Input has bad length, expected 2 bytes, got '.length($data) unless length($data) == 2;

        $v = unpack('n', $data);
        $prefix = $v & 0xF000;
        $v      = $v & 0x0FFF;

        foreach my $key (keys %_4plus12_prefix) {
            if ($prefix == $_4plus12_prefix{$key}) {
                return Data::Identifier->new($key => $v);
            }
        }

        croak sprintf('Invalid/unknown prefix: 0x%04x', $prefix);
    } elsif ($template eq 'uuid128') {
        croak 'Input has bad length, expected 16 bytes, got '.length($data) unless length($data) == 16;
        return Data::Identifier->new(uuid => join('-', unpack('H8H4H4H4H12', $data)));
    }

    if (defined($type) && defined($pack_template)) {
        my $len = length($data);
        my $exp;

        if ($pack_template eq 'C') {
            $exp = 1;
        } elsif ($pack_template eq 'n') {
            $exp = 2;
        } elsif ($pack_template eq 'N') {
            $exp = 4;
        }

        croak 'Input has bad length, expected '.$exp.' bytes, got '.$len unless $len == $exp;

        return Data::Identifier->new($type => unpack($pack_template, $data));
    }

    croak 'Unknown template: '.$template;
}


sub parse_sirtx {
    my ($self, $data, @opts) = _normalise_args(@_);

    croak 'Stray options passed' if scalar @opts;

    $self->_load_well_known;

    $data =~ s/^\[(.+)\]$/$1/;

    # Experimental:
    if (my ($d, $v) = $data =~ /^(\[.+?\]):(.+)$/) {
        $d = $self->parse_sirtx($d);
        $v =~ s/^\[(.+)\]$/$1/;
        return Data::Identifier->new($d => $v);
    }

    if ($data =~ /^'([0-9]*)$/) {
        my $num = int($1 || '0');
        require Data::Identifier::Generate;
        return Data::Identifier::Generate->integer($num);
    } elsif ($data =~ /^\/([0-9]+)$/) {
        return Data::Identifier->new('d73b6550-5309-46ad-acc9-865c9261065b' => int($1));
    } elsif ($data =~ /^(sid|sni):([0-9]+)$/) {
        return Data::Identifier->new($1 => int($2));
    } elsif ($data =~ /^uuid:([0-9a-fA-F-]+)$/) {
        return Data::Identifier->new(uuid => $1);
    } elsif ($data =~ /^wd:([QPL][1-9][0-9]*)$/) {
        return Data::Identifier->new(wd => $1);
    } elsif ($data =~ /^~([0-9]+)$/) {
        return Data::Identifier->new(hdi => int($1));
    } elsif ($data =~ /^raen:([0-9]+)$/) {
        return Data::Identifier->new('2bffc55d-7380-454e-bd53-c5acd525d692' => int($1));
    } elsif ($data =~ /^chat0w:([0-9]+)$/) {
        return Data::Identifier->new('2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a' => int($1));
    } elsif ($data =~ /^asciicp:([0-9]+)$/) {
        require Data::Identifier::Generate;
        return Data::Identifier::Generate->unicode_character(ascii => int($1));
    } elsif ($data =~ /^raes:(.+)/) {
        if (defined(my $raen = $_raes_to_raen{$1})) {
            return Data::Identifier->new('2bffc55d-7380-454e-bd53-c5acd525d692' => $raen);
        }
    } elsif (defined $_logicals_to_sni{$data}) {
        return Data::Identifier->new(sni => $_logicals_to_sni{$data});
    } elsif (defined $_logicals_to_sid{$data}) {
        return Data::Identifier->new(sid => $_logicals_to_sid{$data});
    } elsif ($data =~ /^logical:(.+)$/) {
        $data = $1;
        if (defined $_logicals_to_sni{$data}) {
            return Data::Identifier->new(sni => $_logicals_to_sni{$data});
        } elsif (defined $_logicals_to_sid{$data}) {
            return Data::Identifier->new(sid => $_logicals_to_sid{$data});
        }
    }

    croak 'Unsupported/invalid SIRTX identifier';
}


sub render_sirtx {
    my ($self, $identifier, @opts) = _normalise_args(@_);
    state $map = [
        [sid        => Data::Identifier->new(wellknown => 'sid')->register],
        [sni        => Data::Identifier->new(wellknown => 'sni')->register],
        [wd         => Data::Identifier->new(wellknown => 'wd')->register],
        ['/'        => Data::Identifier->new(uuid => 'd73b6550-5309-46ad-acc9-865c9261065b')->register],
        [raen       => Data::Identifier->new(uuid => '2bffc55d-7380-454e-bd53-c5acd525d692')->register],
        [chat0w     => Data::Identifier->new(uuid => '2c7e15ed-aa2f-4e2f-9a1d-64df0c85875a')->register],
        ['~'        => Data::Identifier->new(wellknown => 'hdi')->register],
    ];

    croak 'Stray options passed' if scalar @opts;

    $identifier = Data::Identifier->new(from => $identifier);

    if (defined(my Data::Identifier $generator = $identifier->generator(default => undef)) && defined(my $req = $identifier->request(default => undef))) {
        if ($generator->eq('53863a15-68d4-448d-bd69-a9b19289a191')) {
            return sprintf('\'%u', $req);
        } elsif ($generator->eq('d74f8c35-bcb8-465c-9a77-01010e8ed25c') && $req =~ /^[Uu]\+([0-9a-fA-F]{4,6})$/) {
            my $cp = hex $1;
            if ($cp < 0x80) {
                return sprintf('asciicp:%u', $cp);
            }
        }
    }

    foreach my $ent (@{$map}) {
        my $v = $identifier->as($ent->[1], no_defaults => 1, default => undef) // next;
        $v = sprintf($ent->[0] =~ /^[a-z]/ ? '%s:%s' : '%s%s', $ent->[0], $v);
        $v = '['.$v.']' if $v =~ /-/;
        return $v;
    }

    # Fallback:
    return sprintf('[uuid:%s]', $identifier->uuid);
}

# ---- Private helpers ----

sub _normalise_args {
    my (@args) = @_;

    if (scalar(@args)) {
        if (ref($args[0]) && eval {$args[0]->isa(__PACKAGE__)}) {
            # no-op
        } elsif ($args[0] eq __PACKAGE__) {
            $args[0] = $_DEFAULT_INSTANCE;
        } else {
            unshift(@args, $_DEFAULT_INSTANCE);
        }

        return @args;
    }

    return ($_DEFAULT_INSTANCE);
}

sub _load_well_known {
    state $done = do {
        my %meta = (
            sni => \%_logicals_to_sni,
            sid => \%_logicals_to_sid,
        );

        foreach my $type (keys %meta) {
            my $hash = $meta{$type};

            foreach my $key (keys %{$hash}) {
                my $id = Data::Identifier->new($type => $hash->{$key});

                next unless defined $id->uuid(no_defaults => 1, default => undef);

                $id->{id_cache} //= {};
                $id->{id_cache}->{$_logical} //= $key;

                $id->register;
            }
        }
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Util - format independent identifier object

=head1 VERSION

version v0.26

=head1 SYNOPSIS

    use Data::Identifier::Util;

    my Data::Identifier::Util $util = Data::Identifier::Util->new;

(since v0.23)

This package contains some utilty methods that are left out of L<Data::Identifier> to keep that module slim.

This package inherits from L<Data::Identifier::Interface::Userdata> (since v0.23),
and L<Data::Identifier::Interface::Subobjects> (since v0.23).

=head1 METHODS

=head2 new

    my Data::Identifier::Util $util = Data::Identifier::Util->new;

(since v0.23)

Creates a new instance that can be used to call the different methods.

=head2 pack

    my $packed = $util->pack($template => $identifier);
    # e.g.:
    my $packed = $util->pack(sid16 => $identifier);

(since v0.23)

This method can be used to pack identifiers into a (binary) format using a template.
This is similar to L<perlfunc/pack>.

C<$identifier> is a L<Data::Identifier>, or if not is converted to one using L<Data::Identifier/new> with C<from>.

The following templates are currently supported:

=over

=item {sid|sni|hdi|udi}{8|16|32}

(since v0.23)

An C<small-identifier>, C<sirtx-numerical-identifier>, C<host-defined-identifier>, or C<user-defined-identifier>
packed as 8, 16, or 32 bit value (in network byte order).

=item C<4+12>

(since v0.23)

An C<small-identifier>, C<sirtx-numerical-identifier>, C<host-defined-identifier>, or C<user-defined-identifier>
packed in the 4 bit prefix plus 12 bit identifier format.
The prefix to be used is automatically selected.
This module might make better decisions if L<Data::Identifier::Wellknown> is loaded with the corresponding classes,
and/or if a L<Data::TagMap> is given via L<Data::Identifier::Interface::Subobjects/so_attach>.

=item C<uuid128>

(since v0.23)

An UUID as 128 bit (16 byte).

=back

=head2 unpack

    my Data::Identifier $identifier = $util->unpack($template => $packed);
    # e.g.:
    my Data::Identifier $identifier = $util->unpack(sid32 => $packed);
    # or:
    my Data::Identifier $identifier = $util->unpack('4+12' => $packed);

(since v0.23)

This method unpacks an identifier from a (binary) format using a template.
This undoes what L</pack> does. The same rules apply. See there for details.

B<Note:>
As of v0.23 this module expects C<$packed> to have the correct length.
Later versions of this module may add a mode in which trailing data in C<$packed> might be allowed.

=head2 parse_sirtx

    my Data::Identifier $identifier = $util->parse_sirtx($value);

(experimental since v0.23)

This methods tries to decode the given C<$value> as a SIRTX identifier string.
This method is limited in it's capabilities in that it does not support the full syntax,
as well as it does not have any database or context as a data source.

See also L<Data::TagDB/tag_by_specification> with C<style =E<gt> 'sirtx'>.

This might might support more values if L<Data::Identifier::Wellknown> is loaded with the corresponding classes,
and/or if a L<Data::TagMap> is given via L<Data::Identifier::Interface::Subobjects/so_attach>.

See also L</render_sirtx>.

=head2 render_sirtx

    my $value = $util->render_sirtx($identifier);

(experimental since v0.24)

This methods tries to render an identifier in the standard SIRTX syntax.
It will add escapes as needed.

Future versions of this method might support more identifiers or more compact syntax.

This might might support more values if L<Data::Identifier::Wellknown> is loaded with the corresponding classes,
and/or if a L<Data::TagMap> is given via L<Data::Identifier::Interface::Subobjects/so_attach>.

See also L</parse_sirtx>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
