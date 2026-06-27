# Copyright (c) 2023-2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Util;

use v5.14;
use strict;
use warnings;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects);

use Carp;

use Data::Identifier;
use Data::Identifier::Generate;

our $VERSION = v0.31;

use constant {
    BOOL_TRUE  => Data::Identifier->new(uuid => 'eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5')->register,
    BOOL_FALSE => Data::Identifier->new(uuid => '6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1')->register,
};

_update_tag(BOOL_TRUE,  46, 190, 'true');
_update_tag(BOOL_FALSE, 45, 189, 'false');

my @truths = (BOOL_TRUE,  qw(https://schema.org/True  http://schema.org/True),  Data::Identifier->new(wd => 'Q16751793'));
my @falses = (BOOL_FALSE, qw(https://schema.org/False http://schema.org/False), Data::Identifier->new(wd => 'Q5432619'));

foreach my $id (@truths, @falses) {
    $id = Data::Identifier->new(from => $id)->register;
}

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

my %_wk = (
    bunit_ns    => {uuid => 'e8e9846a-37ec-42fd-8e89-d15f5467aa9c', displayname => 'unit-namespace'},
    bunit_gen   => {uuid => 'b1620795-b29a-4aea-ba46-371b187d0a4b', displayname => 'unit-generator'},
    dunit_ns    => {uuid => 'da8a7fe4-935c-4bf7-9bd1-aaf8fc39305b', displayname => 'derived-unit-namespace'},
    dunit_gen   => {uuid => 'c3446cff-672b-4247-b62c-755a295ee15f', displayname => 'derived-unit-generator'},
    #x => {uuid => '', displayname => ''},
);

foreach my $value (values %_wk) {
    my $uuid = delete $value->{uuid};
    $value = Data::Identifier->new(uuid => $uuid, %{$value})->register;
}

my %_base_units = (
    map {
        $_->{id} = Data::Identifier::Generate->generic(
            namespace => $_wk{bunit_ns},
            generator => $_wk{bunit_gen},
            style => 'name-based',
            request => $_->{symbol},
            displayname => $_->{name},
        )->register;
        $_->{symbol} => $_
    } (
        {name => 'second',      symbol => 's',      dimension => 'T',           quantity => 'time',                         variable => [qw(t)]},
        {name => 'metre',       symbol => 'm',      dimension => 'L',           quantity => 'length',                       variable => [qw(l x r)]},
        {name => 'kilogram',    symbol => 'kg',     dimension => 'M',           quantity => 'mass',                         variable => [qw(m)]},
        {name => 'ampere',      symbol => 'A',      dimension => 'I',           quantity => 'electric current',             variable => [qw(I i)]},
        {name => 'kelvin',      symbol => 'K',      dimension => "\N{U+0398}",  quantity => 'thermodynamic temperature',    variable => [qw(T)]},
        {name => 'mole',        symbol => 'mol',    dimension => 'N',           quantity => 'amount of substance',          variable => [qw(n)]},
        {name => 'candela',     symbol => 'cd',     dimension => 'J',           quantity => 'luminous intensity',           variable => [qw(Iv)]},
    )
);

my %_number_units = map { $_ => Data::Identifier::Generate->integer($_)->register } (2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73); # primes

my %_composite_unit_elements = (
    Hz      => {s => -1},
    N       => {s => -2, m =>  1, kg =>  1},
    Pa      => {s => -2, m => -1, kg =>  1},
    J       => {s => -2, m =>  2, kg =>  1},
    W       => {s => -3, m =>  2, kg =>  1},
    C       => {s =>  1,                    A =>  1},
    V       => {s => -3, m =>  2, kg =>  1, A => -1},
    F       => {s =>  4, m => -2, kg => -1, A =>  2},
    "\N{U+03A9}"    => {s => -3, m =>  2, kg =>  1, A => -2},
    "\N{U+2126}"    => {s => -3, m =>  2, kg =>  1, A => -2}, # alias
    ohm             => {s => -3, m =>  2, kg =>  1, A => -2}, # alias
    S       => {s =>  3, m => -2, kg => -1, A =>  2},
    Wb      => {s => -2, m =>  2, kg =>  1, A => -1},
    T       => {s => -2,          kg =>  1, A => -1},
    H       => {s => -2, m =>  2, kg =>  1, A => -2},
    kat     => {s => -1,                             mol => 1},
    10      => {2 => 1,         5 => 1},
    12      => {2 => 2, 3 => 1},
    24      => {2 => 3, 3 => 1},
    28      => {2 => 2,                  7 => 1},
    30      => {2 => 1, 3 => 1, 5 => 1},
    60      => {2 => 2, 3 => 1, 5 => 1},
    365     => {                5 => 1, 73 => 1},
    366     => {2 => 1, 3 => 1,         61 => 1},
    3600    => {2 => 4, 3 => 2, 5 => 2},
    86400   => {2 => 7, 3 => 3, 5 => 2},
);

my %_component_to_name = (
    # Units:
    (map {$_base_units{$_}{id}->uuid => $_} keys %_base_units),
    # Numbers:
    (map {$_number_units{$_}->uuid => $_} keys %_number_units),
);

my %_si_prefix = (
    quetta  =>  30, Q   => 30,
    ronna   =>  27, R   => 27,
    yotta   =>  24, Y   => 24,
    zetta   =>  21, Z   => 21,
    exa     =>  18, E   => 18,
    peta    =>  15, P   => 15,
    tera    =>  12, T   => 12,
    giga    =>   9, G   => 9,
    mega    =>   6, M   => 6,
    kilo    =>   3, k   => 3,
    hecto   =>   2, h   => 2,
    deca    =>   1, da  => 1,
    deci    =>  -1, d   => -1,
    centi   =>  -2, c   => -2,
    milli   =>  -3, m   => -3,
    micro   =>  -6, "\N{GREEK SMALL LETTER MU}" => -6,
    nano    =>  -9, n   => -9,
    pico    => -12, p   => -12,
    femto   => -15, f   => -15,
    atto    => -18, a   => -18,
    zepto   => -21, z   => -21,
    yocto   => -24, y   => -24,
    ronto   => -27, r   => -27,
    quecto  => -30, q   => -30,
);


sub new {
    my ($pkg, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return bless {}, $pkg;
}


#@returns Data::Identifier
sub from_bool {
    my ($self, $bool, @opts) = _normalise_args(@_);

    croak 'Stray options passed' if scalar @opts;

    return $bool ? BOOL_TRUE : BOOL_FALSE;
}


sub is_true {
    my ($self, $identifier, @opts) = _normalise_args(@_);

    croak 'Stray options passed' if scalar @opts;

    foreach my $ref (@truths) {
        return !!1 if $ref->eq($identifier);
    }

    return !!0;
}


sub is_false {
    my ($self, $identifier, @opts) = _normalise_args(@_);

    croak 'Stray options passed' if scalar @opts;

    foreach my $ref (@falses) {
        return !!1 if $ref->eq($identifier);
    }

    return !!0;
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
    } elsif ($template eq 'uuidhexdash') {
        return $identifier->uuid(no_defaults => 1);
    } elsif ($template eq 'uuidHEXDASH') {
        return $identifier->uuid(no_defaults => 1) =~ tr/a-f/A-F/r;
    } elsif ($template eq 'Data::Identifier') {
        return $identifier;
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


#@returns Data::Identifier
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
    } elsif ($template eq 'uuidhexdash') {
        return Data::Identifier->new(uuid => $data);
    } elsif ($template eq 'uuidHEXDASH') {
        return Data::Identifier->new(uuid => $data);
    } elsif ($template eq 'Data::Identifier') {
        # We don't care too much here if it is actually a Data::Identifier or just any other supported type.
        # Data::Identifier will do the right thing anyway.
        return Data::Identifier->new(from => $data);
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


#@returns Data::Identifier
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

# Too experimental for listing in public API.
# TODO: Get this on track for the public API!
sub parse_unit_request {
    my ($self, $template, $request, %opts) = _normalise_args(@_);
    my $exponentas = delete($opts{exponentas}) // 'int';
    my @res;

    croak 'Stray options passed' if scalar keys %opts;

    if ($template eq 'request') {
        foreach my $subreq (split(/--/, $request)) {
            my ($uuid, $neg, $exp_mul) = $subreq =~ /^([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})~(-?)([0-9])\z/;
            my $exp;

            #printf("%-42s -> <%s> <%1s> <%s>\n", $subreq, $uuid, $neg, $exp_mul);

            if ($exponentas eq 'int') {
                $exp = int($exp_mul);
                $exp = -$exp if $neg eq '-';
            } else {
                croak 'Invalid exponentas: '.$exponentas;
            }

            push(@res, {
                    component => Data::Identifier->new(uuid => $uuid),
                    exponent  => $exp,
                });
        }
    } else {
        croak 'Unknown template: '.$template;
    }

    return \@res;
}

# Too experimental for listing in public API.
# TODO: Get this on track for the public API!
sub render_unit_request {
    my ($pkg, $template, $request, %opts) = _normalise_args(@_);
    my $displayname = delete $opts{displayname};
    my $input;
    my %took;

    croak 'Stray options passed' if scalar keys %opts;

    if (ref($request) eq 'ARRAY') {
        $request = {map {($_component_to_name{$_->{component}->uuid} // croak 'Unknown base unit: '.$_->{component}->uuid) => $_->{exponent}} @{$request}};
    }

    if (defined(my $prefix = delete($request->{prefix}))) {
        $prefix = $_si_prefix{$prefix} // croak 'Bad prefix: '.$prefix;
        $request->{10} //= 0;
        $request->{10}  += $prefix;
    }

    foreach my $key (keys(%_composite_unit_elements)) {
        my $n = $_composite_unit_elements{$key};
        my $mul = delete($request->{$key}) // 0;
        croak 'Bad exponent: '.$mul if $mul != int($mul);
        $mul = int($mul);
        next if $mul == 0;
        foreach my $prime_element (keys %{$n}) {
            $request->{$prime_element} //= 0;
            $request->{$prime_element} += $n->{$prime_element} * $mul;
        }
    }

    foreach my $key (keys(%_base_units), keys(%_number_units)) {
        my $mul = delete($request->{$key}) // 0;
        croak 'Bad exponent: '.$mul if $mul != int($mul);
        $mul = int($mul);
        $took{$key} = $mul if $mul != 0;
    }

    {
        my @keys = keys %{$request};
        croak 'Bad extra units: '.join(', ', @keys) if scalar @keys;
    }

    unless (scalar(grep {!defined $_number_units{$_}} keys %took)) {
        my $i = 1;

        foreach my $key (keys %took) {
            $i *= $key ** $took{$key};
        }

        if ($i == int($i)) {
            return $pkg->pack($template => Data::Identifier::Generate->integer($i));
        }
        croak 'Invalid numeric only request';
    }

    # Rename from units to UUIDs as keys.
    foreach my $key (keys %took) {
        my $uuid = ($_number_units{$key} // $_base_units{$key}{id})->uuid;
        $took{$uuid} = delete $took{$key};
    }

    if (scalar(keys %took) == 1) {
        my ($mul) = values %took;
        if ($mul == 1) {
            my ($uuid) = keys %took;
            return $pkg->pack($template => Data::Identifier->new(uuid => $uuid));
        }
    }

    $input = join('--', map{$_.'~'.$took{$_}} sort keys %took);

    if ($template eq 'request') {
        return $input;
    }

    $opts{namespace} //= $_wk{dunit_ns},
    $opts{generator} //= $_wk{dunit_gen},
    $opts{input}       = $input;
    $opts{request}     = $input;
    $opts{displayname} = $displayname;

    return $pkg->pack($template => Data::Identifier::Generate->generic(%opts));
}


#@returns Data::Identifier
sub register_namespace {
    my ($self, $identifier, %opts) = _register_base(@_);

    $identifier->uuid; # ensure we map to an UUID

    croak 'Stray options passed' if scalar keys %opts;

    return $identifier->register;
}


#@returns Data::Identifier
sub register_generator {
    my ($self, $identifier, %opts) = _register_base(@_);
    my %pass;

    $pass{$_} = delete $opts{$_} foreach qw(namespace style type);
    delete $opts{$_} foreach qw(native_case source_role up_relation for_type copy_tagnames native_ise_template);

    $pass{namespace} = $self->register_namespace($pass{namespace}) if defined $pass{namespace};
    $pass{type}      = $self->register_type($pass{type}) if defined $pass{type};

    Data::Identifier::Generate->_register_generator($identifier, %pass);

    croak 'Stray options passed' if scalar keys %opts;

    return $identifier->register;
}


#@returns Data::Identifier
sub register_type {
    my ($self, $identifier, %opts) = _register_base(@_);
    my $uuid = $identifier->uuid; # ensure we map to an UUID

    if (defined(my $validate = delete $opts{validate})) {
        $identifier->{validate} //= $validate;
    }

    if (defined(my $namespace = delete $opts{namespace})) {
        $identifier->{namespace} //= $self->register_namespace($namespace);
    }

    if (defined(my $null_value = delete $opts{null_value})) {
        my $null = Data::Identifier->new(sid => 0);

        $null->{id_cache}{$uuid} //= $null_value;

        $null->register;
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $identifier->register;
}


#@returns Data::Identifier
sub regenerate {
    my ($self, $identifier, %opts) = _normalise_args(@_);

    $identifier = Data::Identifier->new(from => $identifier);

    if (defined(my $generator = delete $opts{generator})) {
        # TODO compare with what is in $identifier already and die on mismatch.
        $identifier->{generator} //= Data::Identifier->new(from => $generator);
    }

    if (defined(my $request = delete $opts{request})) {
        # TODO compare with what is in $identifier already and die on mismatch.
        croak 'Invalid request' unless length($request);
        $identifier->{request} //= $request;
    }

    croak 'Stray options passed' if scalar keys %opts;

    if (defined(my $generator = $identifier->{generator}) && defined(my $request = $identifier->{request})) {
        my $n = eval { Data::Identifier::Generate->generic(generator => $generator, request => $request) };

        if (defined $n) {
            foreach my $key (qw(displayname displaycolour description icontext)) {
                $identifier->{$key} //= $n->{$key} // next;
            }
        }
    }

    return $identifier;
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

#@returns Data::Identifier
sub _update_tag {
    my ($identifier, $sid, $sni, $tagname) = @_;
    my $id_cache = $identifier->{id_cache} //= {};

    $id_cache->{Data::Identifier::WK_SID()} //= $sid if defined $sid;
    $id_cache->{Data::Identifier::WK_SNI()} //= $sni if defined $sni;

    if (defined $tagname) {
        my %tagnames = map {$_ => undef} $tagname, $identifier->tagname(list => 1, default => [], no_defaults => 1);
        $identifier->{tagname} = [keys %tagnames];
    }

    $identifier->register; # re-register

    return $identifier;
}

# prepares arguments for register_*().
# Removes any common arguments from %opts
# does NOT call $identifier->register as register_*() might make additional changes that register needs to know about,
# so doing it here would just mean to do it twice.
sub _register_base {
    my ($self, $identifier, %opts) = _normalise_args(@_);

    $identifier = Data::Identifier->new(from => $identifier);

    if (defined(my $displayname = delete $opts{displayname})) {
        $identifier->{displayname} //= $displayname;
    }

    if (defined(my $tagname = delete $opts{tagname})) {
        my %tagnames = map {$_ => undef} (ref $tagname ? @{$tagname} : $tagname), $identifier->tagname(list => 1, default => [], no_defaults => 1);
        $identifier->{tagname} = [keys %tagnames];
    }

    return ($self, $identifier, %opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Util - format independent identifier object

=head1 VERSION

version v0.31

=head1 SYNOPSIS

    use Data::Identifier::Util;

    my Data::Identifier::Util $util = Data::Identifier::Util->new;

(since v0.23)

This package contains some utility methods that are left out of L<Data::Identifier> to keep that module slim.

This package inherits from L<Data::Identifier::Interface::Userdata> (since v0.23),
and L<Data::Identifier::Interface::Subobjects> (since v0.23).

B<Note:>
This package may register (see L<Data::Identifier/register>) some identifiers required for the provided operations.
This may or may not overlap with what L<Data::Identifier::Wellknown> registers.

=head1 METHODS

=head2 new

    my Data::Identifier::Util $util = Data::Identifier::Util->new;

(since v0.23)

Creates a new instance that can be used to call the different methods.

=head2 from_bool

    my Data::Identifier $identifier = $util->from_bool($bool);

(experimental since v0.30)

Returns a true or false as an identifier based on the passed boolean.
The value is check for it's boolean value by perl's rules.

=head2 is_true

    my $bool = $util->is_true($identifier);

(experimental since v0.30)

Returns true if the given identifier represents true (not just a true-ish value).

This implementation tries to support many different vocabularies.

B<Note:>
As this tests for true (not true-ish) values can be both not-true and not-false.

See also:
L</is_false>.

=head2 is_false

    my $bool = $util->is_false($identifier);

(experimental since v0.30)

Returns true if the identifier represents false (not just a false-ish value).

All limitations and notes of L</is_true> also apply.

See also:
L</is_true>.

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

=item C<uuidhexdash>, C<uuidHEXDASH>

(since v0.27)

An UUID in hex-and-hash format.
Use C<uuidhexdash> for lower case and C<uuidHEXDASH> for upper case.

=item C<Data::Identifier>

(experimental since v0.29)

A full L<Data::Identifier> object.
This is mostly for compatibility with other APIs.

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

=head2 register_namespace

    my Data::Identifier $identifier = $util->register_namespace($id, %opts);

(experimental since v0.30)

Registers a namespace by creating a L<Data::Identifier> object (unless one is already passed),
updating it's values, and calling L<Data::Identifier/register> on it before returning.

This function may also validate the passed values and update other global data structures.

C<$id> is parsed as per C<from> in L<Data::Identifier/new>. However it must resolve to an UUID.

The following options from L<Data::Identifier/new> are supported:
C<displayname>,
C<tagname>.

Currently no options specific to namespaces are supported.

B<Note:>
This method is not suitable for use with L<constant>.
However it is possible to register the Identifier as a constant and the use it with this method.
For example:

    use constant NS_INT => Data::Identifier->new(uuid => '5dd8ddbb-13a8-4d6c-9264-36e6dd6f9c99')->register;

    Data::Identifier::Util->register_namespace(NS_INT, tagname => 'integer-namespace');

=head2 register_generator

    my Data::Identifier $identifier = $util->register_generator($id, %opts);

(experimental since v0.30)

Registers a generator the same way L</register_namespace> registers an namespace.
All aspects of L</register_namespace> apply as well but for the fact that this method is used to register generators and the list of specific options.

Currently the following options as known from L<Data::Identifier::Generate/generic> are accepted:
C<namespace>,
C<style>,
C<type>.

If a namespace is passed it is registered as per L</register_namespace> with no options.
It is still valid to call L</register_namespace> for it manually to (re)register it with options.

Equally, if type is passed it is registered as per L</register_type> in the same way.

Also the following keys not yet supported by L<Data::Identifier::Generate/generic> are accepted but ignored:
C<native_case>,
C<source_role>,
C<up_relation>,
C<for_type>,
C<copy_tagnames>,
C<native_ise_template>.

Future versions of this module may implement those options.

=head2 register_type

    my Data::Identifier $identifier = $util->register_type($id, %opts);

(experimental since v0.30)

Registers a type the same way L</register_namespace> registers an namespace.
All aspects of L</register_namespace> apply as well but for the fact that this method is used to register types and the list of specific options.

Currently the following type specific options are supported:

=over

=item C<validate>

A regex that should be used to validate identifiers if this identifier is used as a type.

=item C<namespace>

The namespace used by a type. Must be a L<Data::Identifier> or an ISE. Must also resolve to an UUID.
This method calls L</register_namespace> on the given namespace to ensure the namespace is correctly registered.

=item C<null_value>

The value that represents a null for the given identifier.
It will be aliased to the null identifier.

=back

=head2 regenerate

    my Data::Identifier $identifier = $util->regenerate($id, %opts);

(experimental since v0.31)

This method tries to run the generator for an identifier already in existance in the same way
L<Data::Identifier::Generate> does for requests.

C<$id> should be an instance of L<Data::Identifier>. Otherwise it is parsed as per C<from> in L<Data::Identifier/new>.

B<Note:>
This method will C<die> if there is a problem (such as an identifier mismatch, validation error, etc.).
It will however not report any error if not enough data is available for regeneration or the specific regeneration
is not supported. It however may update the identifier as much as possible.

The following options are supported. All values default to what is already known (e.g. by been given to L<Data::Identifier/new>).

=over

=item C<generator>

The same as C<generator> in L<Data::Identifier/new>.

The generator should be registered using L</register_generator>.

=item C<request>

The same as C<request> in L<Data::Identifier/new>.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
