# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with display colours

package Data::Displaycolour;

use v5.20;
use strict;
use warnings;

use Carp;

use Data::Identifier;
use Data::URIID;
use Data::URIID::Colour;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects Data::Identifier::Interface::Known);

our $VERSION = v0.04;

my %_abstract_names_to_ise = (
    black    => 'fade296d-c34f-4ded-abd5-d9adaf37c284',
    white    => '1a2c23fa-2321-47ce-bf4f-5f08934502de',
    red      => 'c9ec3bea-558e-4992-9b76-91f128b6cf29',
    green    => 'c0e957d0-b5cf-4e53-8e8a-ff0f5f2f3f03',
    blue     => '3dcef9a3-2ecc-482d-a98b-afffbc2f64b9',
    cyan     => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb',
    magenta  => 'a30d070d-9909-40d4-a33a-474c89e5cd45',
    yellow   => '2892c143-2ae7-48f1-95f4-279e059e7fc3',
    grey     => 'f9bb5cd8-d8e6-4f29-805f-cc6f2b74802d',
    orange   => '5c41829f-5062-4868-9c31-2ec98414c53d',
    savannah => 'c90acb33-b8ea-4f55-bd86-beb7fa5cf80a',
);
my %_abstract_ise_to_name = map {$_abstract_names_to_ise{$_} => $_} keys %_abstract_names_to_ise;
my %_abstract_rgb_to_name = (
    # this is filled later using palette data, so we only do corner cases here:
);

my $_default_text_ops = [qw(trim fc)];
my %_text_types = (
    name        => $_default_text_ops,
    username    => $_default_text_ops,
    displayname => $_default_text_ops,
    text        => $_default_text_ops,
    email       => $_default_text_ops,
    _ise        => [],
);

my %_default_colours = (
    black       => '#000000',
    white       => '#ffffff',
    red         => '#ff0000',
    green       => '#008000',
    blue        => '#0000ff',
    cyan        => '#00ffff',
    magenta     => '#ff00ff',
    yellow      => '#ffff00',
    grey        => '#808080',
    orange      => '#ff8000',
    savannah    => '#decc9c',
);

my %_palette = (
    fallbacks => {%_default_colours},
    v0 => {
        black       => '#2E3436',
        white       => '#EEEEEC',
        red         => '#EF2929',
        green       => '#8AE234',
        blue        => '#729FCF',
        cyan        => '#6BE5E5',
        magenta     => '#AD7FA8',
        yellow      => '#FCE94F',
        grey        => '#888A85',
        orange      => '#FCAF3E',
        savannah    => '#E9B96E',
    },
    vga => {
        black       => '#000000',
        white       => '#FFFFFF',
        red         => '#FF0000',
        green       => '#008000',
        blue        => '#0000FF',
        cyan        => '#00FFFF',
        magenta     => '#FF00FF',
        yellow      => '#FFFF00',
        grey        => '#808080',
        _other      => ['#800000', '#808000', '#000080', '#800080', '#008080', '#C0C0C0', '#00FF00'],
    },
    girlsandboys => {
        blue        => '#729FCF',
        magenta     => '#FF65C1',
    },
    roaraudio => {
        _other      => ['#ffbb55', '#cd6648'],
    },
    fun => {
        blue        => '#3465a4',
        green       => '#069a2e',
        red         => '#ce181e',
        magenta     => '#EE82EE',
        _other      => ['#04617b'],
    },
    neko_v0 => {
        black       => '#000000',
        blue        => '#0000ff',
        green       => '#00ff00',
        cyan        => '#00ffff',
        red         => '#ff0000',
        magenta     => '#ff00ff',
        yellow      => '#ffff00',
        white       => '#ffffff',
        orange      => '#ff8000',
        grey        => '#808080',
        _other      => ['#a52a2a'],
    },
    mirc_base => {
        white       => '#ffffff',
        black       => '#000000',
        red         => '#ff0000',
        blue        => '#00007f',
        green       => '#009300',
        yellow      => '#ffff00',
        cyan        => '#009393',
        magenta     => '#ff00ff',
        orange      => '#fc7f00',
        grey        => '#7f7f7f',
        _other => ['#ff0000', '#7f0000', '#9c009c', '#00fc00', '#00ffff', '#0000fc', '#ff00ff', '#d2d2d2']
    },
    websafe => {
        black       => '#000000',
        white       => '#ffffff',
        red         => '#ff0000',
        green       => '#00FF00',
        blue        => '#0000ff',
        cyan        => '#00ffff',
        magenta     => '#ff00ff',
        yellow      => '#ffff00',
        grey        => '#999999',
        orange      => '#ff9000',
    },
    haiku_hrev58909_light => {
        black       => '#000000',
        white       => '#ffffff',
        red         => '#ff4136',
        green       => '#2ecc40',
        blue        => '#0000e5',
        magenta     => '#91709b',
        grey        => '#999999',
        orange      => '#ffcb00',
        _other      => ['#1b528c', '#3296ff', '#336698', '#3366bb', '#505050', '#6698cb', '#798ecb', '#acacac', '#bebebe', '#d8d8d8', '#e0e0e0', '#e8e8e8', '#f5f5f5', '#ffffd8'],
    },
    haiku_hrev58909_dark => {
        black       => '#000000',
        white       => '#ffffff',
        red         => '#ff2836',
        green       => '#2ecc40',
        blue        => '#0000e5',
        magenta     => '#91709b',
        grey        => '#c3c3c3',
        orange      => '#e34911',
        _other      => ['#1b528c', '#1c1c1c', '#1d1d1d', '#272727', '#2b2b2b', '#3296ff', '#336698', '#4b7ca8', '#4c444f', '#5a5a5a', '#6698cb', '#6a70d4', '#798ecb', '#cb2009', '#e6e6e6', '#eaeaea', '#fdfdfd'],
    },
    wfw_default => {
        black       => '#000000',
        white       => '#ffffff',
        blue        => '#000080',
        grey        => '#c0c0c0',
        _other      => ['#808080'],
    },
    vic2 => {
        black       => '#000000',
        white       => '#FFFFFF',
        red         => '#813338',
        cyan        => '#75CEC8',
        magenta     => '#8E3C97',
        green       => '#56AC4D',
        blue        => '#2E2C9B',
        yellow      => '#EDF171',
        orange      => '#8E5029',
        gray        => '#B2B2B2',
        _other      => ['#C46C71', '#4A4A4A', '#7B7B7B', '#A9FF9F', '#706DEB', '#553800'],
    },
);

{
    my @colours;
    my %got = map {$_ => 1} values %{$_palette{websafe}};
    $_palette{websafe}{_other} = \@colours;
    for (my $r = 0x00; $r <= 0xFF; $r += 0x33) {
        for (my $g = 0x00; $g <= 0xFF; $g += 0x33) {
            for (my $b = 0x00; $b <= 0xFF; $b += 0x33) {
                my $c = sprintf('#%02x%02x%02x', $r, $g, $b);
                next if $got{$c};
                push(@colours, $c);
            }
        }
    }
}

foreach my $palette (values %_palette) {
    my $other = $palette->{_other} // [];

    $other = [split/\s+/, $other] unless ref $other;

    $palette->{_all} = [(grep {defined} map {$palette->{$_}} sort keys %_default_colours), @{$other}];
}

foreach my $palette (values(%_palette), \%_default_colours) {
    foreach my $key (grep {!/^_/} keys %{$palette}) {
        $_abstract_rgb_to_name{fc $palette->{$key}} = $key;
    }
}



sub new {
    my ($pkg, %opts) = @_;
    my $self = bless {}, $pkg;

    if (defined(my $so = delete $opts{subobjects})) {
        $self->so_attach(%{$so});
    }

    {
        my $palette = delete($opts{palette}) // 'v0';

        if (ref($palette) eq 'ARRAY' && scalar(@{$palette}) >= 1) {
            $palette = [map {ref ? Data::URIID::Colour->new(from => $_)->rgb : $_} @{$palette}];
            my $p = $self->{palette} = {
                _all => $palette,
            };
            foreach my $colour (@{$palette}) {
                if (defined(my $name = $_abstract_rgb_to_name{fc($colour)})) {
                    $p->{$name} //= $colour;
                }
            }
        } else {
            $self->{palette} = $_palette{$palette} // croak 'Invalid palette: '.$palette;
        }
    }

    if (!defined($self->{origin}) && defined(my $for = delete $opts{for})) {
        my $id = eval {Data::Identifier->new(from => $for)};
        if (defined $_abstract_ise_to_name{eval {$id->ise} // ''}) {
            $opts{from} //= $for;
        } elsif ($for->isa('Data::URIID::Result')) {
            eval {$self->so_attach(extractor => $for->extractor)};
            $self->{origin} //= $for->attribute('displaycolour', as => 'Data::URIID::Colour', default => undef);
            $opts{for__ise} //= $for->ise(default => undef);
        } else {
            my Data::URIID $extractor = $self->extractor;
            my Data::URIID::Result $result = $extractor->lookup($for);

            $self->{origin} //= $result->attribute('displaycolour', as => 'Data::URIID::Colour', default => undef);
            $opts{for__ise} //= $for->ise(default => undef);
        }

        $opts{for_displayname} //= $id->displayname(default => undef, no_defaults => 1) if defined $id;
    }


    foreach my $key (keys %_text_types) {
        if (defined(my $for = $opts{'for_'.$key})) {
            foreach my $step (@{$_text_types{$key}}) {
                if ($step eq 'fc') {
                    $for = fc($for);
                } elsif ($step eq 'trim') {
                    $for =~ s/^\s+//;
                    $for =~ s/\s+$//;
                    $for =~ s/\s+/ /;
                } else {
                    croak 'BUG';
                }
            }

            $opts{'for_'.$key} = length($for) ? $for : undef;
        }
    }

    foreach my $key (keys %_text_types) {
        if (defined(my $for_text = $opts{'for_'.$key})) {
            foreach my $for (split(/[\s\x20-\x2F\x5B-\x60\x7B-\x7F]+/, $for_text)) {
                require Data::Displaycolour::Data;

                my %langs = %Data::Displaycolour::Data::_langs;
                my @langs;
                my %found;

                if (defined(my $list = delete $opts{language})) {
                    my $n = 0;
                    %langs = ();
                    $list = [split/\s*,\s*|\s+/, $list] unless ref $list;
                    $langs{$_} = $n++ foreach reverse @{$list};
                }

                if (defined(my $list = delete $opts{preferred_language})) {
                    my $n = $Data::Displaycolour::Data::_lang_value;
                    $list = [split/\s*,\s*|\s+/, $list] unless ref $list;
                    $langs{$_} = $n++ foreach reverse @{$list};
                }

                if (defined(my $list = delete $opts{blacklist_language})) {
                    $list = [split/\s*,\s*|\s+/, $list] unless ref $list;
                    delete $langs{$_} foreach @{$list};
                }

                @langs = sort {$langs{$b} <=> $langs{$a}} keys %langs;

                outer:
                foreach my $lang (@langs) {
                    my $l = $Data::Displaycolour::Data::_extra{$lang};
                    foreach my $name (@{$l->{__order__}}) {
                        my $v = _match_with_quality($for, $name);
                        $found{$l->{$name}} += $v if $v;
                    }

                    $l = $Data::Displaycolour::Data::_names{$lang};
                    foreach my $name (@{$l->{__order__}}) {
                        my $v = _match_with_quality($for, $name);
                        $found{$l->{$name}} += $v if $v;
                    }
                }

                {
                    my $best_v = 0;
                    my $best;

                    foreach my $key (keys %found) {
                        my $v = $found{$key};
                        if ($v > $best_v) {
                            $best = $key;
                            $best_v = $v;
                        }
                    }

                    $opts{from} //= $_abstract_names_to_ise{$best} if defined $best;
                }
            }
        }

        next if defined $opts{from};
    }

    unless (delete($opts{no_defaults}) || defined $opts{from}) {
        foreach my $key (keys %_text_types) {
            if (defined(my $for = $opts{'for_'.$key})) {
                unless (defined $self->{origin}) {
                    require Digest;
                    my $v = unpack('L', Digest->new('SHA-1')->add($key)->add(':')->add($for)->digest) & 0xFFFFFF;
                    my $palette = $self->{palette}{_all};
                    $v = $palette->[$v % scalar(@{$palette})];
                    $self->{specific} = $self->{origin} = Data::URIID::Colour->new(rgb => $v);
                }
            }
        }
    }

    # Delete keys after we used them.
    foreach my $key (keys %_text_types) {
        delete $opts{'for_'.$key};
    }

    if (defined(my $from = delete $opts{from})) {
        my $id;
        my $ise;

        eval {
            $id = Data::Identifier->new(from => $from);
            $ise = $id->ise;
        };

        if (defined $ise) {
            if (defined(my $name = $_abstract_ise_to_name{$ise})) {
                $self->{origin} = $from;
                $self->{abstract} = $id;
            }
        }

        unless (defined $self->{origin}) {
            $self->{origin} = Data::URIID::Colour->new(from => $from); # force a valid object.
        }
    }

    croak 'Stray options passed' if scalar keys %opts;

    return $self;
}


sub origin {
    my ($self, @args) = @_;
    return $self->_colour_getter(origin => @args);
}


sub abstract {
    my ($self, @args) = @_;
    return $self->_colour_getter(abstract => @args);
}


sub specific {
    my ($self, @args) = @_;
    return $self->_colour_getter(specific => @args);
}


sub rgb {
    my ($self, %opts) = @_;
    my $no_defaults = delete $opts{no_defaults};
    my $exists_default = exists $opts{default};
    my $value_default = delete $opts{default};
    my $v;

    croak 'Stray options passed' if scalar keys %opts;

    $v //= eval { $self->origin(  'Data::URIID::Colour', no_defaults => 1, default => undef) };
    $v //= eval { $self->specific('Data::URIID::Colour', no_defaults => 1, default => undef) };
    $v //= eval { $self->abstract('Data::URIID::Colour', no_defaults => 1, default => undef) };

    if (!defined($v) && !$no_defaults) {
        $v //= eval { $self->origin(  'Data::URIID::Colour', no_defaults => 0, default => undef) };
        $v //= eval { $self->specific('Data::URIID::Colour', no_defaults => 0, default => undef) };
        $v //= eval { $self->abstract('Data::URIID::Colour', no_defaults => 0, default => undef) };
    }

    return $v->rgb if defined $v;

    return $value_default if $exists_default;
    croak 'No value found';
}


sub list_colours {
    my ($pkg, $palette) = @_;
    my %res;

    $palette = $_palette{$palette} // croak 'Unknown palette: '.$palette;

    %res = map {fc($_) => undef} @{$palette->{_all}};

    foreach my $name (keys %_abstract_names_to_ise) {
        if (defined(my $c = $palette->{$name})) {
            $res{fc $c} = Data::Identifier->new(ise => $_abstract_names_to_ise{$name}, displayname => $name);
        }
    }

    return \%res;
}

# ---- Private helpers ----

sub _colour_getter {
    my ($self, $key, $as, %opts) = @_;
    my $no_defaults = delete $opts{no_defaults};
    my $exists_default = exists $opts{default};
    my $value_default = delete $opts{default};

    croak 'Stray options passed' if scalar keys %opts;

    $as //= 'Data::URIID::Colour';

    unless (exists $self->{$key}) {
        $self->{$key} = undef; # break out of deep recursion.
        if (defined(my $func = $self->can('_load_'.$key))) {
            $self->{$key} = eval { $self->$func() };
        }
    }

    if (defined(my $val = $self->{$key})) {
        return $val->as($as, extractor => $self->extractor);
    }

    return $value_default if $exists_default;
    croak 'No value found';
}

#@returns Data::URIID
sub extractor {
    my ($self) = @_;
    my Data::URIID $extractor = $self->so_get('extractor', default => undef);

    return $extractor if defined $extractor;

    $extractor = Data::URIID->new;

    $self->so_attach(extractor => $extractor);

    return $extractor;
}

# ---- Private loaders ----

sub _match_with_quality {
    my ($haystack, $needle) = @_;
    my ($pre, $post) = $haystack =~ /^(.*)\Q$needle\E(.*)\z/;

    return 0 unless defined($pre) && defined($post);
    return 1 - (length($pre) ? 0.4 : 0) - (length($post) ? 0.4 : 0);
    return 0;
}

sub _load_abstract {
    my ($self) = @_;
    my $rgb = $self->rgb(default => undef);

    if (defined($rgb) && defined(my $name = $_abstract_rgb_to_name{fc($rgb)})) {
        if (defined(my $ise = $_abstract_names_to_ise{$name})) {
            return Data::Identifier->new(ise => $ise, displayname => $name);
        }
    }

    return undef;
}

sub _load_specific {
    my ($self) = @_;
    my $abstract = $self->abstract('Data::Identifier');

    if (defined(my $ise = $abstract->ise(default => undef))) {
        if (defined(my $name = $_abstract_ise_to_name{$ise})) {
            my $c;

            if (defined($c = $self->{palette}{$name})) {
                return Data::URIID::Colour->new(rgb => $c);
            } elsif (defined($c = $_default_colours{$name})) {
                return Data::URIID::Colour->new(rgb => $c);
            }
        }
    }

    return $self->extractor->lookup($abstract)->attribute('displaycolour', as => 'Data::URIID::Colour');
}

# ---- Private helpers for Data::Identifier::Interface::Known ----


sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);

    if ($class eq 'abstract-colours') {
        return ([keys %_abstract_ise_to_name], rawtype => 'ise');
    } elsif ($class eq 'specific-colours') {
        my %rgb;

        foreach my $palette (values %_palette) {
            foreach my $value (values %{$palette}) {
                if (ref $value) {
                    $rgb{$_} = undef foreach @{$value};
                } else {
                    $rgb{$value} = undef;
                }
            }
        }

        return ([map {Data::URIID::Colour->new(rgb => $_)} keys %rgb], rawtype => 'Data::URIID::Colour');
    } elsif ($class eq 'palettes') {
        return ([keys %_palette], not_identifiers => 1);
    } elsif ($class eq ':all') {
        return ([
                @{(__SUB__->($pkg, 'specific-colours', %opts))[0]},
                keys(%_palette),
                (map {Data::Identifier->new(ise => $_)} keys %_abstract_ise_to_name),
            ], not_identifiers => 1);
    }

    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Displaycolour - Work with display colours

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use Data::Displaycolour;

    my Data::Displaycolour $dp = Data::Displaycolour->new(...);

    say $dp->rgb;

This module supports working with display colours for arbitrary subjects.

B<Note:>
This package is still a bit experimental.
While the API should be stable for use, the results may change over the next releases
as palette and matching code updates will take place.

This package inherits from L<Data::Identifier::Interface::Userdata>, and L<Data::Identifier::Interface::Subobjects>, and
L<Data::Identifier::Interface::Known>.

=head1 METHODS

=head2 new

    my Data::Displaycolour $dc = Data::Displaycolour->new(%opts);

Creates a new displaycolour object.

The following options are supported:

=over

=item C<for>

A blessed reference that represents the object we want the display colour for.
This might be anything L<Data::URIID/lookup> accepts as input.
(If it is a URI it must be a L<URI> object or similar.)

=item C<for_displayname>

A displayname for which a colour should be found.

=item C<for_email>

An e-mail address (without the name) for which a colour should be found.

=item C<for_name>

An name (such as a legal name) for which a colour should be found.

=item C<for_text>

Some portion of text (normally one sentence to a full paragraph) for which a colour should be found.

=item C<for_username>

Some username for which a colour should be found.

=item C<from>

A colour value this object should be constructed from.
This might be anything L<Data::URIID::Colour/new> accespts via C<from>.
Please also keep the notes in the documentation for that method in mind.

=item C<palette>

The palette to use. If this is a scalar it is the name of the palette.
If an array reference it must be a list of C<#rrggbb> values.
In this case the colours are matched to the abstract colours if possible,
with the default values used what what cannot be matched.
Other types of values might be supported.
Newer versions of this module might support more palette types.

=item C<language>

A language or list (arrayref or comma/space separated list) of languages as language tags (in order of preference) to use for lookups.

Lookups will only performed with the listed languages.

Defaults to a build in list.

=item C<preferred_language>

A list of langauges that are preferred. This will however not remove any languages from the list.

The format is the same as for L</language>.

Defaults to an empty list.

B<Note:>
It is not defined what happens if both this and L</language> is given.

=item C<blacklist_language>

A list of languages that are never tried for lookups.

The format is the same as for L</language>.

Defaults to an empty list.

B<Note:>
It is safe to combine with option with any other option.
If a language is specifically asked for and blacklisted, the blacklist wins.

=item C<no_defaults>

Do not try to use calculate fallback colours if no colour could be detected.

=item C<subobjects>

    A unblessed hashref that is passed to L<Data::Identifier::Interface::Subobjects/so_attach>.

=back

=head2 origin

    my Data::URIID::Colour $origin = $dc->origin;
    # or:
    my $origin = $dc->origin($as [, %opts ] );

Returns the origin colour of this object.
This value might be an abstract or specific colour and might or might not be set.

If there is any problem or error this method C<die>s.

C<$as> is to be understood the same way as in L<Data::Identifier/as>.
If not given, L<Data::URIID::Colour> is assumed.

The following options are supported:

=over

=item C<default>

The default value to return if no value is known.
When set to C<undef> this can be used to switch this method to returning C<undef> (not C<die>) in case no value is known.

=item C<no_defaults>

If a true value disables looking up a value based on other values.

=back

=head2 abstract

    my $abstract = $dc->abstract( [ $as [, %opst] ] );

This method returns the abstract colour.
It works the same as L</origin> and takes the same arguments.

=head2 specific

    my $specific = $dc->specific( [ $as [, %opst] ] );

This method returns the specific colour.
It works the same as L</origin> and takes the same arguments.

=head2 rgb

    my $rgb = $dc->rgb( [ %opts ] );

Returns a single RGB value as per L<Data::URIID::Colour/rgb>.

Takes the same options as L</origin>.

=head2 list_colours

    my $colours = Data::Displaycolour->list_colours($palette_name);

Returns a hashref with the keys being RGB (C<#rrggbb>) colour values of all colours present in the palette (fallbacks are not listed).
The values are a L<Data::Identifier> of the abstract colour this value represents (if any) or C<undef>.

For discovery of known palettes see L</known>.

=head2 known

    my @list = Data::Displaycolour->known($class [, %opts ] );

Returns a list of well known items. See L<Data::Identifier::Interface::Known/known> for details.

The following classes are supported:

=over

=item C<abstract-colours>

The list of abstract colours known by this module.

=item C<specific-colours>

The list of specific colours known by this module for all palettes.

See also:
L</list_colours>.

=item C<palettes>

The list of palettes known by this module. See L</new>.

=back

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
