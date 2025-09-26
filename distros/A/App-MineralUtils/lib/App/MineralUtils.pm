package App::MineralUtils;

use 5.010001;
use strict;
use utf8;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-09-26'; # DATE
our $DIST = 'App-MineralUtils'; # DIST
our $VERSION = '0.023'; # VERSION

our %SPEC;

# BEGIN magnesium lexical
{

# good sources: pubchem
# not-so-good sources: american elements

my @magnesium_forms = (
    # ---- elemental
    {
        name => 'mg-mg-elem',
        magnesium_ratio => 1,
        summary => 'Elemental magnesium, in milligrams',
    },

    # ---- citrate
    {
        # source: pubchem
        name => 'mg-trimagnesium-dicitrate',
        magnesium_ratio => 24.305*3/451.12, # 16.16%
        summary => 'Magnesium citrate a.k.a trimagnesium dicitrate (C12H10Mg3O14), in milligrams',
    },
    {
        # source: pubchem
        name => 'mg-mg-citrate-dibasic',
        magnesium_ratio => 24.305/214.41, # 11.34%
        summary => 'Magnesium citrate dibasic (C6H6MgO7), in milligrams',
    },
    {
        # source: jungbunzlauer, fischer scientific
        name => 'mg-mg-citrate-anhydrous',
        magnesium_ratio => 24.305*3/457.16, # 15.95%
        summary => 'Magnesium citrate anhydrous ((C6H5O7)2Mg3, C12H16Mg3O14), in milligrams',
    },
    {
        # source: nowfoods, jungbunzlauer, fischer scientific
        name => 'mg-mg-citrate-anhydrous-nowfoods',
        magnesium_ratio => 24.305*3/457.16, # 15.95%
        purity => 0.9091, # 15.95% x 0.9091 = 14.5%
        summary=>'Magnesium citrate in NOW Foods supplement (anhydrous, C12H16Mg3O14, 90.9% pure, contains citric acid etc), in milligrams',
    },
    {
        # source: pubchem, jungbunzlauer
        name => 'mg-mg-citrate-nonahydrate',
        magnesium_ratio => 24.305/613.25, # 11.89%
        summary => 'Magnesium citrate nonahydrate ((C6H5O7)2Mg3 · 9H2O, C12H28Mg3O23) [most common hydrate form of Mg-citrate at room temp], in milligrams',
    },

    # ---- glycinate/bisglycinate
    {
        # source: pubchem
        name=>'mg-mg-glycinate-anhydrous',
        magnesium_ratio => 24.305/172.42, # 14.10%
        summary=>'Magnesium glycinate/bisglycinate anhydrous (C4H8MgN2O4) [most common hydrate form of Mg-glycinate], in milligrams',
    },
    {
        # alias for: mg-mg-glycinate
        # source: pubchem
        name=>'mg-mg-bisglycinate-anhydrous',
        magnesium_ratio => 24.305/172.42, # 14.1%
        summary=>'Magnesium glycinate/bisglycinate (C4H8MgN2O4) [most common hydrate form of Mg-glycinate], in milligrams',
    },
    {
        # source: nowfoods
        name=>'mg-mg-bisglycinate-nowfoods',
        magnesium_ratio => 24.305/172.42, # 14.1%
        purity => 0.7094, # 14.1% x 0.7094 = 10%
        summary=>'Magnesium bisglycinate in NOW Foods supplement (C4H8MgN2O4, 70.5% pure, contains citric acid etc), in milligrams',
    },

    # ---- ascorbate
    # TODO
    #{
    #    # source: pubchem
    #    name=>'mg-mg-ascorbate-anhydrous',
    #    magnesium_ratio => 24.305/, # %
    #    summary => 'Magnesium ascorbate anhydrous (C12H14MgO12) [this and dihydrate are the most common hydrate form of Mg-ascorbate at room temp], in milligrams',
    #},
    {
        # source: pubchem
        name=>'mg-mg-ascorbate-dihydrate',
        magnesium_ratio => 24.305/374.54, # 6.49%
        summary => 'Magnesium ascorbate hydrate (C12H14MgO12) [anhydrous and dihydrate are the most common hydrate forms of Mg-ascorbate at room temp], in milligrams',
    },

    # ---- pidolate
    {
        # source: pubchem
        name=>'mg-mg-pidolate',
        magnesium_ratio => 24.305/280.517, # 8.66%
        summary => 'Magnesium pidolate (C10H12MgN2O6), in milligrams',
    },

    # ---- l-threonate
    {
        # source: pubchem
        name=>'mg-mg-l-threonate',
        magnesium_ratio => 24.305/294.50, # 8.25%
        summary => 'Magnesium L-threonate (C8H14MgO10), in milligrams',
    },

    # ---- oxide
    {
        name=>'mg-mg-oxide-anhydrous',
        magnesium_ratio => 24.305 / 40.3044, # 60.3%
        summary => 'Magnesium oxide anhydrous (MgO) [most common hydrate form of MgO at room temp], in milligrams',
    },
    {
        name=>'mg-magshape',
        magnesium_ratio => 0.32, # 30-36.6% from COA
        summary => 'MAGSHAPE (microencapsulated form of magnesium oxide), in milligrams',
    },

    # ---- others
    {
        name=>'mg-mg-lactate-anhydrous',
        magnesium_ratio => 24.305 / 202.45, # 12.01%
        summary => 'Magnesium lactate dihydrate (C6H10MgO6), in milligrams',
    },
    {
        name=>'mg-mg-lactate-dihydrate',
        magnesium_ratio => 24.305 / 238.48, # 10.19%
        summary => 'Magnesium lactate dihydrate (C6H14MgO8), in milligrams',
    },

    {
        name=>'mg-mg-chloride-ah',
        magnesium_ratio => 24.305/95.211, # 25.5%
        summary => 'Magnesium chloride (anhydrous, MgCl2), in milligrams',
    },
    {
        name=>'mg-mg-chloride-hexahydrate',
        magnesium_ratio => 24.305/203.31, # 12.0%
        summary => 'Magnesium chloride (hexahydrate, H12Cl2MgO6), in milligrams',
    },

    {
        name=>'mg-mg-malate',
        magnesium_ratio => 24.305/156.376, # 15.5%
        summary => 'Magnesium malate (C4H4MgO5), in milligrams',
    },
    {
        name=>'mg-mg-malate-trihydrate',
        magnesium_ratio => 24.305/210.40, # 11.6%
        summary => 'Magnesium malate (MgC4H4O5.3H2O), in milligrams',
    },

    {
        name=>'mg-mg-sulfate-anhydrous',
        magnesium_ratio => 24.305/120.37, # 20.19%
        summary => 'Magnesium sulfate anhydrous (MgSO4), in milligrams',
    },
    {
        name=>'mg-mg-sulfate-monohydrate',
        magnesium_ratio => 24.305/138.39, # 17.56%
        summary => 'Magnesium sulfate monohydrate (MgSO4.H2O), in milligrams',
    },
    {
        name=>'mg-mg-sulfate-heptahydrate',
        magnesium_ratio => 24.305/246.48, # 9.86%
        summary => 'Magnesium sulfate heptahydrate (MgSO4.7H2O) a.k.a. Epsom salt, in milligrams',
    },

    {
        name=>'mg-mg-carbonate-anhydrous',
        magnesium_ratio => 24.305/84.31, # 28.83%
        summary => 'Magnesium carbonate anhydrous (MgCO3), in milligrams',
    },
    {
        name=>'mg-mg-carbonate-trihydrate',
        magnesium_ratio => 24.305/146.39, # 16.61%
        summary => 'Magnesium carbonate trihydrate (MgCO3.3H2O), in milligrams',
    },

    {
        name=>'mg-mg-hydroxide-anhydrous',
        magnesium_ratio => 24.305/58.32, # 41.68%
        summary => 'Magnesium hydroxide anhydrous (Mg(OH)2), in milligrams',
    },
    {
        name=>'mg-mg-hydroxide-pentahydrate',
        magnesium_ratio => 24.305/138.36, # 17.57%
        summary => 'Magnesium hydroxide pentahydrate (Mg(OH)2.5H2O), in milligrams',
    },

    {
        name=>'mg-mg-acetate-anhydrous',
        magnesium_ratio => 24.305/142.39, # 17.07%
        summary => 'Magnesium acetate anhydrous (Mg(CH3COO)2), in milligrams',
    },
    {
        name=>'mg-mg-acetate-tetrahydrate',
        magnesium_ratio => 24.305/214.45, # 11.33%
        summary => 'Magnesium acetate tetrahydrate (Mg(CH3COO)2.4H2O), in milligrams',
    },

    {
        name=>'mg-mg-gluconate-dihydrate',
        magnesium_ratio => 24.305/450.63, # 5.39%
        summary => 'Magnesium gluconate dihydrate (C12H26MgO16), in milligrams',
    },
    {
        name=>'mg-mg-gluconate-hydrate',
        magnesium_ratio => 24.305/432.62, # 5.62%
        summary => 'Magnesium gluconate dihydrate (C12H26MgO16), in milligrams',
    },

    {
        name=>'mg-mg-glycerophosphate-anhydrous',
        magnesium_ratio => 24.305/194.36, # 12.51%
        summary => 'Magnesium glycerophosphate anhydrous (C₃H₇MgO₆P), in milligrams',
    },
    {
        name=>'mg-mg-glycerophosphate-hydrate',
        magnesium_ratio => 24.305/212.3781, # 11.44%
        summary => 'Magnesium glycerophosphate anhydrous (C₃H₇MgO₆P.H2O, C3H9MgO7P), in milligrams',
    },
    # XXX Magnesium glycerophosphate dihydrate?
    # XXX magnesium phosphate?

    {
        name=>'mg-trimagnesium-orthophosphate-anhydrous',
        magnesium_ratio => 3*24.305/262.8577, # 27.74%
        summary => 'Trimagnesium orthophosphate (Mg3O8P2), in milligrams',
    },
    {
        name=>'mg-sunactive-mg',
        magnesium_ratio => 0.12, # >12% according to spec
        summary => 'SunActive Magnesium (a micronized, microencapsulated form of trimagnesium orthophosphate), in milligrams',
    },

    {
        name=>'mg-mg-taurate',
        magnesium_ratio => 24.305/272.6, # 8.92%
        summary => 'Magnesium taurate (C4H12MgN2O6S2), in milligrams',
    },
);

our %argspecs_magnesium = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @magnesium_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @magnesium_forms]],
        pos => 1,
    },
);

$SPEC{convert_magnesium_unit} = {
    v => 1.1,
    summary => 'Convert a magnesium quantity from one unit to another',
    description => <<'MARKDOWN',

If target unit is not specified, will show all known conversions.

MARKDOWN
    args => {
        %argspecs_magnesium,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
        {
            args=>{quantity=>'350 mg-mg-oxide-anhydrous', to_unit=>'mg-mg-elem'},
            summary=>'How much of magnesium oxide provides 350 mg of elemental magnesium?',
        },
        {
            src_plang => 'bash',
            src=>'[[prog]] | td sort -- -pct_mg',
            summary=>'Sort by highest magnesium content',
        },
    ],
};

sub convert_magnesium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{magnesium_ratio}*($_->{purity}//1)))}
        @magnesium_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @magnesium_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_mg => $u->{magnesium_ratio} * 100,
                purity => $u->{purity} // 1,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_mg purity unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}],
                                    [number=>{thousands_sep=>'', precision=>3}],
                                    [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

} # END magnesium lexical

# BEGIN potassium lexical
{

my @potassium_forms = (
    {
        name => 'mg-k-elem',
        potassium_ratio => 1,
        summary => 'Elemental potassium, in milligrams',
    },

    # chloride
    {
        name => 'mg-k-chloride-anhydrous',
        potassium_ratio => 39.0983/74.5513, # 52.45%
        summary => 'Potassium chloride (KCl) anhydrous [most common hydrate form of KCl at room temp], in milligrams',
    },
    {
        name => 'mg-k-chloride-dihydrate',
        potassium_ratio => 39.0983/110.58, # 35.36%
        summary => 'Potassium chloride dihydrate (KCl.2H2O) [unstable at room temp], in milligrams',
    },

    # citrate
    {
        name => 'mg-k-citrate-anhydrous',
        potassium_ratio => 3*39.0983/306.395, # 38.28%
        summary => 'Tripotassium citrate anhydrous (K3C6H5O7), in milligrams',
    },
    {
        name => 'mg-k-citrate-monohydrate',
        potassium_ratio => 3*39.0983/324.41, # 36.16%
        summary => 'Tripotassium citrate monohydrate (K3C6H5O7.H2O) [most common hydrate form of K-citrate at room temp], in milligrams',
    },

    # carbonate
    {
        name => 'mg-k-carbonate-anhydrous',
        potassium_ratio => 2*39.0983/138.205, # 56.58%
        summary => 'Potassium carbonate anhydrous (K2CO3), in milligrams',
    },
    {
        name => 'mg-k-carbonate-dihydrate',
        potassium_ratio => 2*39.0983/174.24, # 44.88%
        summary => 'Potassium carbonate dihydrate (K2CO3.2H2O) [most common hydrate form of K-carbonate at room temp], in milligrams',
    },

    # bicarbonate
    {
        name => 'mg-k-bicarbonate-anhydrous',
        potassium_ratio => 39.0983/100.115, # 39.05%
        summary => 'Potassium bicarbonate anhydrous (KHCO3) [most common hydrate form of K-bicarbonate at room temp], in milligrams',
    },

    # acetate
    {
        name => 'mg-k-acetate-anhydrous',
        potassium_ratio => 39.0983/98.14, # 39.84%
        summary => 'Potassium acetate anhydrous (C2H3O2K), in milligrams',
    },
    {
        name => 'mg-k-acetate-monohydrate',
        potassium_ratio => 39.0983/116.16, # 33.66%
        summary => 'Potassium acetate monohydrate (C2H9KO5) [most common hydrate form of K-acetate at room temp], in milligrams',
    },
    {
        name => 'mg-k-acetate-trihydrate',
        potassium_ratio => 39.0983/152.19, # 25.69%
        summary => 'Potassium acetate trihydrate (C2H9KO5), in milligrams',
    },
);

our %argspecs_potassium = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @potassium_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @potassium_forms]],
        pos => 1,
    },
);

$SPEC{convert_potassium_unit} = {
    v => 1.1,
    summary => 'Convert a potassium quantity from one unit to another',
    description => <<'MARKDOWN',

If target unit is not specified, will show all known conversions.

MARKDOWN
    args => {
        %argspecs_potassium,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
        {
            args=>{quantity=>'1000 mg-k-elem', to_unit=>'mg-k-chloride-anhydrous'},
            summary=>'How much of potassium chloride provides 1000 mg of elemental potassium?',
        },
        {
            args=>{quantity=>'1000 mg-k-chloride-anhydrous', to_unit=>'mg-k-elem'},
            summary=>'How much elemental potassium is in 1000mg (1g) of potassium chloride powder in capsule form?',
        },
        {
            args=>{quantity=>'600 mg-k-chloride-anhydrous', to_unit=>'mg-k-elem'},
            summary=>'A tablet supplement called KSR contains 600mg of potassium chloride; how much elemental potassium is that?',
        },
        {
            args=>{quantity=>'4700 mg-k-elem', to_unit=>'mg-k-chloride-anhydrous'},
            summary=>'Recommended daily intake (DV) of (elemental) potassium for adults and children 4 years or older is 4,700mg according to US FDA; how much is that equivalent to in KCl? Note that it is *NOT* recommended (and most probably dangerous) to take KCl supplement that much as potassium is contained in other sources too',
        },
    ],
};
sub convert_potassium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{potassium_ratio}*($_->{purity}//1)))}
        @potassium_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @potassium_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_k => $u->{potassium_ratio} * 100,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_k unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

} # END potassium lexical

# --- sodium

my @sodium_forms = (
    {
        name => 'mg-na-elem',
        sodium_ratio => 1,
        summary => 'Elemental sodium, in milligrams',
    },
    # note: unlike magnesium (MgCl hexahydrate), KCl and NaCl does not form hydrates
    {
        name => 'mg-na-chloride',
        sodium_ratio => 22.989769/58.44, # 39.34%
        summary => 'Sodium chloride (NaCl), in milligrams',
    },
    {
        name => 'mg-na-cl',
        sodium_ratio => 22.989769/58.44, # 39.34%
        summary => 'Sodium chloride (NaCl), in milligrams',
    },
    {
        name => 'mg-na-citrate',
        sodium_ratio => 22.989769/258.06, # 8.909%
        summary => 'Sodium citrate (Na3C6H5O7), in milligrams',
    },
);

our %argspecs_sodium = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @sodium_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @sodium_forms]],
        pos => 1,
    },
);

$SPEC{convert_sodium_unit} = {
    v => 1.1,
    summary => 'Convert a sodium quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %argspecs_sodium,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
        {
            args=>{quantity=>'1000 mg-na-elem', to_unit=>'mg-na-cl'},
            summary=>'How much of sodium chloride provides 1000 mg of elemental sodium?',
        },
    ],
};
sub convert_sodium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{sodium_ratio}*($_->{purity}//1)))}
        @sodium_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @sodium_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_na => $u->{sodium_ratio} * 100,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_na unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

# --- iron

our @iron_forms = (
    {
        name => 'mg-fe-elem',
        iron_ratio => 1,
        summary => 'Elemental iron, in milligrams',
    },

    # sulfate
    {
        name => 'mg-ferrous-sulfate-heptahydrate', # the natural hydrate form, loses water to tetrahydrate at 57C and monohydrate at 65C
        iron_ratio => 55.845/278.02, # 20.09%
        summary => 'Ferrous sulphate heptahydrate (FeSO4.7H2O), in milligrams',
    },

    # pyrophosphate
    {
        name => 'mg-fe-iii-pyrophosphate', #
        iron_ratio => 4*55.845/745.21, # 29.98%
        summary => 'Iron (III) pyrophosphate (Fe4O21P6), in milligrams',
    },
    {
        name => 'mg-lipofer', #
        iron_ratio => 8/100, # 8%, 7.8-9% according to spec
        summary => 'Lipofer (micronized, microencapsulated, water-soluble form of iron pyrophosphate), in milligrams',
    },
    {
        name => 'mg-sunactive-fe', #
        iron_ratio => 8/100, # >8% according to spec
        summary => 'SunActive Fe (micronized, microencapsulated form of iron pyrophosphate), in milligrams',
    },

    # glycinate
    {
        name => 'mg-fe-glycinate', #
        iron_ratio => 55.845/203.96, # 27.38%
        summary => 'Iron glycinate a.k.a. ferrous bisglycinate (C4H8FeN2O4), in milligrams',
    },
    {
        name => 'mg-fe-bisglycinate', #
        iron_ratio => 55.845/203.96, # 27.38%
        summary => 'Iron glycinate a.k.a. ferrous bisglycinate (C4H8FeN2O4), in milligrams',
    },

    # gluconate
    {
        name => 'mg-fe-gluconate', #
        iron_ratio => 55.845/448.156, # 12.46%
        summary => 'Iron (II) gluconate (C12H22FeO14), in milligrams',
    },
);

our %argspecs_iron = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @iron_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @iron_forms]],
        pos => 1,
    },
);

$SPEC{convert_iron_unit} = {
    v => 1.1,
    summary => 'Convert an iron quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %argspecs_iron,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
    ],
};
sub convert_iron_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{iron_ratio}*($_->{purity}//1)))}
        @iron_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @iron_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_fe => $u->{iron_ratio} * 100,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_fe unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

# --- calcium

our @calcium_forms = (
    {
        name => 'mg-ca-elem',
        calcium_ratio => 1,
        summary => 'Elemental calcium, in milligrams',
    },
    {
        name => 'mg-ca-carbonate',
        calcium_ratio => 40.078 / 100.0869, # 40.04%
        summary => 'Calcium carbonate (CaCO3), in milligrams',
    },
    {
        name => 'mg-ca-pidolate',
        calcium_ratio => 40.078 / 296.29, # 13.53%
        summary => 'Calcium pidolate (C10H12CaN2O6), in milligrams',
        tags => ['water-soluble'],
    },
    {
        name => 'mg-ca-lactate',
        calcium_ratio => 40.078 / 218.22, # 18.37%
        summary => 'Calcium lactate (C6H10CaO6), in milligrams',
        tags => ['water-soluble'],
    },
    { # source: pubchem
        name => 'mg-ca-citrate-anhydrous',
        calcium_ratio => 3*40.078 / 498.4, # 24.12%
        summary => 'Calcium citrate anhydrous (C12H10Ca3O14), in milligrams',
    },
    { # source: pubchem
        name => 'mg-ca-citrate-tetrahydrate',
        calcium_ratio => 3*40.078 / 570.5, # 21.08%
        summary => 'Calcium citrate tetrahydrate (C12H18Ca3O18) [most common hydrate form of Ca-citrate], in milligrams',
    },
    { # source: nih
        name => 'mg-ca-ascorbate-dihydrate',
        calcium_ratio => 40.078 / 426.34, # 9.40%
        summary => 'Calcium ascorbate dihydrate (C12H18CaO14), in milligrams',
    },
    { # source: nih
        name => 'mg-ca-gluconate',
        calcium_ratio => 40.078 / 430.37, # 9.31%
        summary => 'Calcium gluconate (C12H22CaO14), in milligrams',
    },
    { # source: nih
        name => 'mg-ca-glycerophosphate',
        calcium_ratio => 40.078 / 210.14, # 19.07%
        summary => 'Calcium glycerophosphate (C3H7CaO6P), in milligrams',
    },
);

our %argspecs_calcium = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @calcium_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @calcium_forms]],
        pos => 1,
    },
);

$SPEC{convert_calcium_unit} = {
    v => 1.1,
    summary => 'Convert an iron quantity from one unit to another',
    description => <<'_',

If target unit is not specified, will show all known conversions.

_
    args => {
        %argspecs_iron,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
    ],
};
sub convert_calcium_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{calcium_ratio}*($_->{purity}//1)))}
        @calcium_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @calcium_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_ca => $u->{calcium_ratio} * 100,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_ca unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

# --- zinc


our @zinc_forms = (
    # source: chatgpt
    {
        name => 'mg-zn-elem',
        zinc_ratio => 1,
        summary => 'Elemental zinc, in milligrams',
    },

    # LACTATE
    {
        name => 'mg-zn-lactate-anhydrous',
        zinc_ratio => 65.38 / 245.5, # 26.63%
        summary => 'Zinc lactate anhydrous (Zn(C3H5O3)2), in milligrams',
    },
    {
        name => 'mg-zn-lactate-monohydrate',
        zinc_ratio => 65.38 / 263.6, # 24.80%
        summary => 'Zinc lactate monohydrate (Zn(C₃H₅O₃)₂·H₂O), in milligrams',
    },
    {
        name => 'mg-zn-lactate-dihydrate',
        zinc_ratio => 65.38 / 281.6, # 23.22%
        summary => 'Zinc lactate dihydrate (Zn(C₃H₅O₃)₂·2H₂O) [most common hydrate form, along -trihydrate], in milligrams',
    },
    {
        name => 'mg-zn-lactate-trihydrate',
        zinc_ratio => 65.38 / 299.6, # 21.82%
        summary => 'Zinc lactate trihydrate (Zn(C₃H₅O₃)₂·3H₂O) [most common hydrate form, along -diihydrate], in milligrams',
    },

    # PICOLINATE
    {
        name => 'mg-zn-picolinate-anhydrous',
        zinc_ratio => 65.38 / 298.6, # 21.9%
        summary => 'Zinc picolinate (Zn(C6H4NO2)2), in milligrams',
    },
    {
        name => 'mg-zn-picolinate-dihydrate',
        zinc_ratio => 65.38 / (298.6+2*18), # 19.5%
        summary => 'Zinc picolinate dihydrate (Zn(C6H4NO2)2.2H2O) [most common hydrate form, along with -tetrahydrate], in milligrams',
    },
    {
        name => 'mg-zn-picolinate-tetrahydrate',
        zinc_ratio => 65.38 / (298.6+4*18), # 17.6%
        summary => 'Zinc picolinate tetrahydrate (Zn(C6H4NO2)2.2H2O) [most common hydrate form, along with -dihydrate], in milligrams',
    },

    # GLUCONATE
    {
        name => 'mg-zn-gluconate-anhydrous',
        zinc_ratio => 65.38 / 455.7, # 14.4%
        summary => 'Zinc gluconate anhydrous (Zn(C6H11O7)2) [uncommon], in milligrams',
    },
    {
        name => 'mg-zn-gluconate-dihydrate',
        zinc_ratio => 65.38 / (455.7 + 2*18), # 13.3%
        summary => 'Zinc gluconate dihydrate (Zn(C6H11O7)2.2H2O) [most common hydrate form with trihydrate], in milligrams',
    },
    {
        name => 'mg-zn-gluconate-trihydrate',
        zinc_ratio => 65.38 / (455.7 + 3*18), # 12.8%
        summary => 'Zinc gluconate trihydrate (Zn(C6H11O7)2.3H2O) [most common hydrate form with dihydrate], in milligrams',
    },

    # CITRATE
    {
        name => 'mg-zn-citrate-andhydrous',
        zinc_ratio => 3*65.38 / 574.3, # 34.2%
        summary => 'Zinc citrate (trizinc dicitrate) anhydrous (Zn3(C6H5O7)2), in milligrams',
    },
    {
        name => 'mg-zn-citrate-dihydrate',
        zinc_ratio => 3*65.38 / (574.3+3*18), # 32.1%
        summary => 'Zinc citrate (trizinc dicitrate) dihydrate (Zn3(C6H5O7)2.2H2O) [most common hydrate form], in milligrams',
    },
    {
        name => 'mg-zn-citrate-trihydrate',
        zinc_ratio => 3*65.38 / (574.3+3*18), # 31.2%
        summary => 'Zinc citrate (trizinc dicitrate) trihydrate (Zn3(C6H5O7)2.3H2O) [uncommon], in milligrams',
    },

    # OXIDE, no hydrate forms
    {
        name => 'mg-zn-oxide',
        zinc_ratio => 65.38 / 81.38, # 80.3%
        summary => 'Zinc oxide (ZnO), in milligrams',
    },

    # SULFATE
    {
        name => 'mg-zn-sulfate-anhydrous',
        zinc_ratio =>  65.38 / 161.5, # 36.6%
        summary => 'Zinc sulfate anhydrous (ZnSO4), in milligrams',
    },
    {
        name => 'mg-zn-sulfate-heptahydrate',
        zinc_ratio =>  65.38 / (161.5+7*18), # 22.7%
        summary => 'Zinc sulfate heptahydrate (ZnSO4.7H2O) [most common hydrate form], in milligrams',
    },
    {
        name => 'mg-zn-sulfate-dihydrate',
        zinc_ratio =>  65.38 / (161.5+2*18), # 33.1%
        summary => 'Zinc sulfate dihydrate (ZnSO4.7H2O) [less common hydrate form], in milligrams',
    },

    # GLYCINATE
    {
        name => 'mg-zn-glycinate-anhydrous',
        zinc_ratio => 65.38 / 213.5, # 30.6%
        summary => 'Zinc (bis)glycinate anhydrous (C4H8N2O4Zn) [most common hydrate form], in milligrams',
    },
    {
        name => 'mg-zn-glycinate-monohydrate',
        zinc_ratio => 65.38 / 233.5, # 28.0%
        summary => 'Zinc (bis)glycinate monohydrate (C4H8N2O4Zn.H2O), in milligrams',
    },
);

our %argspecs_zinc = (
    quantity => {
        # schema => 'physical::mass*', # XXX Perinci::Sub::GetArgs::Argv is not smart enough to coerce from string
        schema => 'str*',
        default => '1 mg',
        req => 0,
        pos => 0,
        completion => sub {
            require Complete::Sequence;

            my %args = @_;
            Complete::Sequence::complete_sequence(
                word => $args{word},
                sequence => [
                    # TEMP
                    #sub {
                    #    require Complete::Number;
                    #    my $stash = shift;
                    #    Complete::Number::complete_int(word => $stash->{cur_word});
                    #},
                    #' ',
                    {alternative=>[map {$_->{name}} @zinc_forms]},
                ],
            );
        },
    },
    to_unit => {
        # schema => 'physical::unit', # IU hasn't been added
        schema => ['str*', in=>['mg', map {$_->{name}} @zinc_forms]],
        pos => 1,
    },
);

$SPEC{convert_zinc_unit} = {
    v => 1.1,
    summary => 'Convert a zinc quantity from one unit to another',
    description => <<'MARKDOWN',

If target unit is not specified, will show all known conversions.

MARKDOWN
    args => {
        %argspecs_zinc,
    },
    examples => [
        {
            args=>{},
            summary=>'Show all possible conversions',
        },
    ],
};
sub convert_zinc_unit {
    require Physics::Unit;

    Physics::Unit::InitUnit(
        map {([$_->{name}], sprintf("%.3f mg", $_->{zinc_ratio}*($_->{purity}//1)))}
        @zinc_forms,
    );

    my %args = @_;
    my $quantity = Physics::Unit->new($args{quantity});
    return [412, "Must be a Mass quantity"] unless $quantity->type eq 'Mass';

    if ($args{to_unit}) {
        my $new_amount = $quantity->convert($args{to_unit});
        return [200, "OK", $new_amount];
    } else {
        my @rows;
        for my $u (
            @zinc_forms,
        ) {
            push @rows, {
                amount => $quantity->convert($u->{name}),
                unit => $u->{name},
                summary => $u->{summary},
                pct_zn => $u->{zinc_ratio} * 100,
            };
        }
        [200, "OK", \@rows, {
            'table.fields' => [qw/amount pct_zn unit summary/],
            'table.field_formats'=>[[number=>{thousands_sep=>'', precision=>3}], [number=>{thousands_sep=>'', precision=>3}], undef, undef],
            'table.field_aligns' => [qw/number number left left/],
        }];
    }
}

1;
# ABSTRACT: Utilities related to mineral supplements

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MineralUtils - Utilities related to mineral supplements

=head1 VERSION

This document describes version 0.023 of App::MineralUtils (from Perl distribution App-MineralUtils), released on 2025-09-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<convert-calcium-unit>

=item * L<convert-iron-unit>

=item * L<convert-magnesium-unit>

=item * L<convert-potassium-unit>

=item * L<convert-sodium-unit>

=item * L<convert-zinc-unit>

=back

=head1 FUNCTIONS


=head2 convert_calcium_unit

Usage:

 convert_calcium_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert an iron quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_calcium_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_ca  => 100,
       unit    => "mg-ca-elem",
       summary => "Elemental calcium, in milligrams",
     },
     {
       amount  => 2.5,
       pct_ca  => 40.0432024570648,
       unit    => "mg-ca-carbonate",
       summary => "Calcium carbonate (CaCO3), in milligrams",
     },
     {
       amount  => 7.40740740740741,
       pct_ca  => 13.5266124405144,
       unit    => "mg-ca-pidolate",
       summary => "Calcium pidolate (C10H12CaN2O6), in milligrams",
     },
     {
       amount  => 5.43478260869565,
       pct_ca  => 18.3658693062048,
       unit    => "mg-ca-lactate",
       summary => "Calcium lactate (C6H10CaO6), in milligrams",
     },
     {
       amount  => 4.149377593361,
       pct_ca  => 24.1239967897271,
       unit    => "mg-ca-citrate-anhydrous",
       summary => "Calcium citrate anhydrous (C12H10Ca3O14), in milligrams",
     },
     {
       amount  => 4.739336492891,
       pct_ca  => 21.0751971954426,
       unit    => "mg-ca-citrate-tetrahydrate",
       summary => "Calcium citrate tetrahydrate (C12H18Ca3O18) [most common hydrate form of Ca-citrate], in milligrams",
     },
     {
       amount  => 10.6382978723404,
       pct_ca  => 9.40047849134494,
       unit    => "mg-ca-ascorbate-dihydrate",
       summary => "Calcium ascorbate dihydrate (C12H18CaO14), in milligrams",
     },
     {
       amount  => 10.752688172043,
       pct_ca  => 9.31245207612055,
       unit    => "mg-ca-gluconate",
       summary => "Calcium gluconate (C12H22CaO14), in milligrams",
     },
     {
       amount  => 5.23560209424084,
       pct_ca  => 19.0720472066242,
       unit    => "mg-ca-glycerophosphate",
       summary => "Calcium glycerophosphate (C3H7CaO6P), in milligrams",
     },
   ],
   {
     "table.fields"        => ["amount", "pct_ca", "unit", "summary"],
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.field_formats" => [
                                ["number", { precision => 3, thousands_sep => "" }],
                                ["number", { thousands_sep => "", precision => 3 }],
                                undef,
                                undef,
                              ],
   },
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_iron_unit

Usage:

 convert_iron_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert an iron quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_iron_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_fe  => 100,
       unit    => "mg-fe-elem",
       summary => "Elemental iron, in milligrams",
     },
     {
       amount  => 4.97512437810945,
       pct_fe  => 20.0866844111934,
       unit    => "mg-ferrous-sulfate-heptahydrate",
       summary => "Ferrous sulphate heptahydrate (FeSO4.7H2O), in milligrams",
     },
     {
       amount  => 3.33333333333333,
       pct_fe  => 29.975443163672,
       unit    => "mg-fe-iii-pyrophosphate",
       summary => "Iron (III) pyrophosphate (Fe4O21P6), in milligrams",
     },
     {
       amount  => 12.5,
       pct_fe  => 8,
       unit    => "mg-lipofer",
       summary => "Lipofer (micronized, microencapsulated, water-soluble form of iron pyrophosphate), in milligrams",
     },
     {
       amount  => 12.5,
       pct_fe  => 8,
       unit    => "mg-sunactive-fe",
       summary => "SunActive Fe (micronized, microencapsulated form of iron pyrophosphate), in milligrams",
     },
     {
       amount  => 3.64963503649635,
       pct_fe  => 27.380368699745,
       unit    => "mg-fe-glycinate",
       summary => "Iron glycinate a.k.a. ferrous bisglycinate (C4H8FeN2O4), in milligrams",
     },
     {
       amount  => 3.64963503649635,
       pct_fe  => 27.380368699745,
       unit    => "mg-fe-bisglycinate",
       summary => "Iron glycinate a.k.a. ferrous bisglycinate (C4H8FeN2O4), in milligrams",
     },
     {
       amount  => 8,
       pct_fe  => 12.4610626656789,
       unit    => "mg-fe-gluconate",
       summary => "Iron (II) gluconate (C12H22FeO14), in milligrams",
     },
   ],
   {
     "table.field_formats" => [
                                ["number", { precision => 3, thousands_sep => "" }],
                                ["number", { thousands_sep => "", precision => 3 }],
                                undef,
                                undef,
                              ],
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.fields"        => ["amount", "pct_fe", "unit", "summary"],
   },
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_magnesium_unit

Usage:

 convert_magnesium_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a magnesium quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_magnesium_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_mg  => 100,
       purity  => 1,
       unit    => "mg-mg-elem",
       summary => "Elemental magnesium, in milligrams",
     },
     {
       amount  => 6.17283950617284,
       pct_mg  => 16.1631051604894,
       purity  => 1,
       unit    => "mg-trimagnesium-dicitrate",
       summary => "Magnesium citrate a.k.a trimagnesium dicitrate (C12H10Mg3O14), in milligrams",
     },
     {
       amount  => 8.84955752212389,
       pct_mg  => 11.3357585933492,
       purity  => 1,
       unit    => "mg-mg-citrate-dibasic",
       summary => "Magnesium citrate dibasic (C6H6MgO7), in milligrams",
     },
     {
       amount  => 6.28930817610063,
       pct_mg  => 15.9495581415697,
       purity  => 1,
       unit    => "mg-mg-citrate-anhydrous",
       summary => "Magnesium citrate anhydrous ((C6H5O7)2Mg3, C12H16Mg3O14), in milligrams",
     },
     {
       amount  => 6.89655172413793,
       pct_mg  => 15.9495581415697,
       purity  => 0.9091,
       unit    => "mg-mg-citrate-anhydrous-nowfoods",
       summary => "Magnesium citrate in NOW Foods supplement (anhydrous, C12H16Mg3O14, 90.9% pure, contains citric acid etc), in milligrams",
     },
     {
       amount  => 25,
       pct_mg  => 3.96331023236853,
       purity  => 1,
       unit    => "mg-mg-citrate-nonahydrate",
       summary => "Magnesium citrate nonahydrate ((C6H5O7)2Mg3 \xB7 9H2O, C12H28Mg3O23) [most common hydrate form of Mg-citrate at room temp], in milligrams",
     },
     {
       amount  => 7.09219858156028,
       pct_mg  => 14.0963925298689,
       purity  => 1,
       unit    => "mg-mg-glycinate-anhydrous",
       summary => "Magnesium glycinate/bisglycinate anhydrous (C4H8MgN2O4) [most common hydrate form of Mg-glycinate], in milligrams",
     },
     {
       amount  => 7.09219858156028,
       pct_mg  => 14.0963925298689,
       purity  => 1,
       unit    => "mg-mg-bisglycinate-anhydrous",
       summary => "Magnesium glycinate/bisglycinate (C4H8MgN2O4) [most common hydrate form of Mg-glycinate], in milligrams",
     },
     {
       amount  => 10,
       pct_mg  => 14.0963925298689,
       purity  => 0.7094,
       unit    => "mg-mg-bisglycinate-nowfoods",
       summary => "Magnesium bisglycinate in NOW Foods supplement (C4H8MgN2O4, 70.5% pure, contains citric acid etc), in milligrams",
     },
     {
       amount  => 15.3846153846154,
       pct_mg  => 6.48929353340097,
       purity  => 1,
       unit    => "mg-mg-ascorbate-dihydrate",
       summary => "Magnesium ascorbate hydrate (C12H14MgO12) [anhydrous and dihydrate are the most common hydrate forms of Mg-ascorbate at room temp], in milligrams",
     },
     {
       amount  => 11.4942528735632,
       pct_mg  => 8.66435902280432,
       purity  => 1,
       unit    => "mg-mg-pidolate",
       summary => "Magnesium pidolate (C10H12MgN2O6), in milligrams",
     },
     {
       amount  => 12.0481927710843,
       pct_mg  => 8.25297113752122,
       purity  => 1,
       unit    => "mg-mg-l-threonate",
       summary => "Magnesium L-threonate (C8H14MgO10), in milligrams",
     },
     {
       amount  => 1.65837479270315,
       pct_mg  => 60.303589682516,
       purity  => 1,
       unit    => "mg-mg-oxide-anhydrous",
       summary => "Magnesium oxide anhydrous (MgO) [most common hydrate form of MgO at room temp], in milligrams",
     },
     {
       amount  => 3.125,
       pct_mg  => 32,
       purity  => 1,
       unit    => "mg-magshape",
       summary => "MAGSHAPE (microencapsulated form of magnesium oxide), in milligrams",
     },
     {
       amount  => 8.33333333333333,
       pct_mg  => 12.0054334403556,
       purity  => 1,
       unit    => "mg-mg-lactate-anhydrous",
       summary => "Magnesium lactate dihydrate (C6H10MgO6), in milligrams",
     },
     {
       amount  => 9.80392156862745,
       pct_mg  => 10.1916303253942,
       purity  => 1,
       unit    => "mg-mg-lactate-dihydrate",
       summary => "Magnesium lactate dihydrate (C6H14MgO8), in milligrams",
     },
     {
       amount  => 3.92156862745098,
       pct_mg  => 25.5275125773282,
       purity  => 1,
       unit    => "mg-mg-chloride-ah",
       summary => "Magnesium chloride (anhydrous, MgCl2), in milligrams",
     },
     {
       amount  => 8.33333333333333,
       pct_mg  => 11.9546505336678,
       purity  => 1,
       unit    => "mg-mg-chloride-hexahydrate",
       summary => "Magnesium chloride (hexahydrate, H12Cl2MgO6), in milligrams",
     },
     {
       amount  => 6.45161290322581,
       pct_mg  => 15.54266639382,
       purity  => 1,
       unit    => "mg-mg-malate",
       summary => "Magnesium malate (C4H4MgO5), in milligrams",
     },
     {
       amount  => 8.62068965517241,
       pct_mg  => 11.5518060836502,
       purity  => 1,
       unit    => "mg-mg-malate-trihydrate",
       summary => "Magnesium malate (MgC4H4O5.3H2O), in milligrams",
     },
     {
       amount  => 4.95049504950495,
       pct_mg  => 20.1919082827947,
       purity  => 1,
       unit    => "mg-mg-sulfate-anhydrous",
       summary => "Magnesium sulfate anhydrous (MgSO4), in milligrams",
     },
     {
       amount  => 5.68181818181818,
       pct_mg  => 17.5626851651131,
       purity  => 1,
       unit    => "mg-mg-sulfate-monohydrate",
       summary => "Magnesium sulfate monohydrate (MgSO4.H2O), in milligrams",
     },
     {
       amount  => 10.1010101010101,
       pct_mg  => 9.86084063615709,
       purity  => 1,
       unit    => "mg-mg-sulfate-heptahydrate",
       summary => "Magnesium sulfate heptahydrate (MgSO4.7H2O) a.k.a. Epsom salt, in milligrams",
     },
     {
       amount  => 3.47222222222222,
       pct_mg  => 28.8281342663978,
       purity  => 1,
       unit    => "mg-mg-carbonate-anhydrous",
       summary => "Magnesium carbonate anhydrous (MgCO3), in milligrams",
     },
     {
       amount  => 6.02409638554217,
       pct_mg  => 16.6029100348384,
       purity  => 1,
       unit    => "mg-mg-carbonate-trihydrate",
       summary => "Magnesium carbonate trihydrate (MgCO3.3H2O), in milligrams",
     },
     {
       amount  => 2.39808153477218,
       pct_mg  => 41.6752400548697,
       purity  => 1,
       unit    => "mg-mg-hydroxide-anhydrous",
       summary => "Magnesium hydroxide anhydrous (Mg(OH)2), in milligrams",
     },
     {
       amount  => 5.68181818181818,
       pct_mg  => 17.5664932061289,
       purity  => 1,
       unit    => "mg-mg-hydroxide-pentahydrate",
       summary => "Magnesium hydroxide pentahydrate (Mg(OH)2.5H2O), in milligrams",
     },
     {
       amount  => 5.84795321637427,
       pct_mg  => 17.0693166654962,
       purity  => 1,
       unit    => "mg-mg-acetate-anhydrous",
       summary => "Magnesium acetate anhydrous (Mg(CH3COO)2), in milligrams",
     },
     {
       amount  => 8.84955752212389,
       pct_mg  => 11.3336442061087,
       purity  => 1,
       unit    => "mg-mg-acetate-tetrahydrate",
       summary => "Magnesium acetate tetrahydrate (Mg(CH3COO)2.4H2O), in milligrams",
     },
     {
       amount  => 18.5185185185185,
       pct_mg  => 5.3935601269334,
       purity  => 1,
       unit    => "mg-mg-gluconate-dihydrate",
       summary => "Magnesium gluconate dihydrate (C12H26MgO16), in milligrams",
     },
     {
       amount  => 17.8571428571429,
       pct_mg  => 5.61809440155333,
       purity  => 1,
       unit    => "mg-mg-gluconate-hydrate",
       summary => "Magnesium gluconate dihydrate (C12H26MgO16), in milligrams",
     },
     {
       amount  => 8,
       pct_mg  => 12.5051450915826,
       purity  => 1,
       unit    => "mg-mg-glycerophosphate-anhydrous",
       summary => "Magnesium glycerophosphate anhydrous (C\x{2083}H\x{2087}MgO\x{2086}P), in milligrams",
     },
     {
       amount  => 8.7719298245614,
       pct_mg  => 11.4442119973764,
       purity  => 1,
       unit    => "mg-mg-glycerophosphate-hydrate",
       summary => "Magnesium glycerophosphate anhydrous (C\x{2083}H\x{2087}MgO\x{2086}P.H2O, C3H9MgO7P), in milligrams",
     },
     {
       amount  => 3.6101083032491,
       pct_mg  => 27.7393433785657,
       purity  => 1,
       unit    => "mg-trimagnesium-orthophosphate-anhydrous",
       summary => "Trimagnesium orthophosphate (Mg3O8P2), in milligrams",
     },
     {
       amount  => 8.33333333333333,
       pct_mg  => 12,
       purity  => 1,
       unit    => "mg-sunactive-mg",
       summary => "SunActive Magnesium (a micronized, microencapsulated form of trimagnesium orthophosphate), in milligrams",
     },
     {
       amount  => 11.2359550561798,
       pct_mg  => 8.91599413059428,
       purity  => 1,
       unit    => "mg-mg-taurate",
       summary => "Magnesium taurate (C4H12MgN2O6S2), in milligrams",
     },
   ],
   {
     "table.field_formats" => [
                                ["number", { thousands_sep => "", precision => 3 }],
                                ["number", { thousands_sep => "", precision => 3 }],
                                ["number", { thousands_sep => "", precision => 3 }],
                                undef,
                                undef,
                              ],
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.fields"        => ["amount", "pct_mg", "purity", "unit", "summary"],
   },
 ]

=item * How much of magnesium oxide provides 350 mg of elemental magnesium?:

 convert_magnesium_unit(quantity => "350 mg-mg-oxide-anhydrous", to_unit => "mg-mg-elem");

Result:

 [200, "OK", 211.05, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_potassium_unit

Usage:

 convert_potassium_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a potassium quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_potassium_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_k   => 100,
       unit    => "mg-k-elem",
       summary => "Elemental potassium, in milligrams",
     },
     {
       amount  => 1.90839694656489,
       pct_k   => 52.4448265825009,
       unit    => "mg-k-chloride-anhydrous",
       summary => "Potassium chloride (KCl) anhydrous [most common hydrate form of KCl at room temp], in milligrams",
     },
     {
       amount  => 2.82485875706215,
       pct_k   => 35.3574787484174,
       unit    => "mg-k-chloride-dihydrate",
       summary => "Potassium chloride dihydrate (KCl.2H2O) [unstable at room temp], in milligrams",
     },
     {
       amount  => 2.61096605744125,
       pct_k   => 38.2822500367173,
       unit    => "mg-k-citrate-anhydrous",
       summary => "Tripotassium citrate anhydrous (K3C6H5O7), in milligrams",
     },
     {
       amount  => 2.76243093922652,
       pct_k   => 36.156376190623,
       unit    => "mg-k-citrate-monohydrate",
       summary => "Tripotassium citrate monohydrate (K3C6H5O7.H2O) [most common hydrate form of K-citrate at room temp], in milligrams",
     },
     {
       amount  => 1.76678445229682,
       pct_k   => 56.5801526717557,
       unit    => "mg-k-carbonate-anhydrous",
       summary => "Potassium carbonate anhydrous (K2CO3), in milligrams",
     },
     {
       amount  => 2.2271714922049,
       pct_k   => 44.8786730945822,
       unit    => "mg-k-carbonate-dihydrate",
       summary => "Potassium carbonate dihydrate (K2CO3.2H2O) [most common hydrate form of K-carbonate at room temp], in milligrams",
     },
     {
       amount  => 2.55754475703325,
       pct_k   => 39.0533886031064,
       unit    => "mg-k-bicarbonate-anhydrous",
       summary => "Potassium bicarbonate anhydrous (KHCO3) [most common hydrate form of K-bicarbonate at room temp], in milligrams",
     },
     {
       amount  => 2.51256281407035,
       pct_k   => 39.8393111880986,
       unit    => "mg-k-acetate-anhydrous",
       summary => "Potassium acetate anhydrous (C2H3O2K), in milligrams",
     },
     {
       amount  => 2.9673590504451,
       pct_k   => 33.6590048209366,
       unit    => "mg-k-acetate-monohydrate",
       summary => "Potassium acetate monohydrate (C2H9KO5) [most common hydrate form of K-acetate at room temp], in milligrams",
     },
     {
       amount  => 3.89105058365759,
       pct_k   => 25.6904527235692,
       unit    => "mg-k-acetate-trihydrate",
       summary => "Potassium acetate trihydrate (C2H9KO5), in milligrams",
     },
   ],
   {
     "table.field_formats" => [
                                ["number", { thousands_sep => "", precision => 3 }],
                                ["number", { precision => 3, thousands_sep => "" }],
                                undef,
                                undef,
                              ],
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.fields"        => ["amount", "pct_k", "unit", "summary"],
   },
 ]

=item * How much of potassium chloride provides 1000 mg of elemental potassium?:

 convert_potassium_unit(quantity => "1000 mg-k-elem", to_unit => "mg-k-chloride-anhydrous");

Result:

 [200, "OK", 1908.39694656489, {}]

=item * How much elemental potassium is in 1000mg (1g) of potassium chloride powder in capsule form?:

 convert_potassium_unit(quantity => "1000 mg-k-chloride-anhydrous", to_unit => "mg-k-elem");

Result:

 [200, "OK", 524, {}]

=item * A tablet supplement called KSR contains 600mg of potassium chloride; how much elemental potassium is that?:

 convert_potassium_unit(quantity => "600 mg-k-chloride-anhydrous", to_unit => "mg-k-elem");

Result:

 [200, "OK", 314.4, {}]

=item * Recommended daily intake (DV) of (elemental) potassium for adults and children 4 years or older is 4,700mg according to US FDA; how much is that equivalent to in KCl? Note that it is *NOT* recommended (and most probably dangerous) to take KCl supplement that much as potassium is contained in other sources too:

 convert_potassium_unit(quantity => "4700 mg-k-elem", to_unit => "mg-k-chloride-anhydrous");

Result:

 [200, "OK", 8969.46564885496, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_sodium_unit

Usage:

 convert_sodium_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a sodium quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_sodium_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_na  => 100,
       unit    => "mg-na-elem",
       summary => "Elemental sodium, in milligrams",
     },
     {
       amount  => 2.54452926208651,
       pct_na  => 39.339098220397,
       unit    => "mg-na-chloride",
       summary => "Sodium chloride (NaCl), in milligrams",
     },
     {
       amount  => 2.54452926208651,
       pct_na  => 39.339098220397,
       unit    => "mg-na-cl",
       summary => "Sodium chloride (NaCl), in milligrams",
     },
     {
       amount  => 11.2359550561798,
       pct_na  => 8.90869138959932,
       unit    => "mg-na-citrate",
       summary => "Sodium citrate (Na3C6H5O7), in milligrams",
     },
   ],
   {
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.field_formats" => [
                                ["number", { precision => 3, thousands_sep => "" }],
                                ["number", { precision => 3, thousands_sep => "" }],
                                undef,
                                undef,
                              ],
     "table.fields"        => ["amount", "pct_na", "unit", "summary"],
   },
 ]

=item * How much of sodium chloride provides 1000 mg of elemental sodium?:

 convert_sodium_unit(quantity => "1000 mg-na-elem", to_unit => "mg-na-cl");

Result:

 [200, "OK", 2544.52926208651, {}]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 convert_zinc_unit

Usage:

 convert_zinc_unit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert a zinc quantity from one unit to another.

Examples:

=over

=item * Show all possible conversions:

 convert_zinc_unit();

Result:

 [
   200,
   "OK",
   [
     {
       amount  => 1,
       pct_zn  => 100,
       unit    => "mg-zn-elem",
       summary => "Elemental zinc, in milligrams",
     },
     {
       amount  => 3.7593984962406,
       pct_zn  => 26.6313645621181,
       unit    => "mg-zn-lactate-anhydrous",
       summary => "Zinc lactate anhydrous (Zn(C3H5O3)2), in milligrams",
     },
     {
       amount  => 4.03225806451613,
       pct_zn  => 24.8027314112291,
       unit    => "mg-zn-lactate-monohydrate",
       summary => "Zinc lactate monohydrate (Zn(C\x{2083}H\x{2085}O\x{2083})\x{2082}\xB7H\x{2082}O), in milligrams",
     },
     {
       amount  => 4.31034482758621,
       pct_zn  => 23.2173295454545,
       unit    => "mg-zn-lactate-dihydrate",
       summary => "Zinc lactate dihydrate (Zn(C\x{2083}H\x{2085}O\x{2083})\x{2082}\xB72H\x{2082}O) [most common hydrate form, along -trihydrate], in milligrams",
     },
     {
       amount  => 4.58715596330275,
       pct_zn  => 21.8224299065421,
       unit    => "mg-zn-lactate-trihydrate",
       summary => "Zinc lactate trihydrate (Zn(C\x{2083}H\x{2085}O\x{2083})\x{2082}\xB73H\x{2082}O) [most common hydrate form, along -diihydrate], in milligrams",
     },
     {
       amount  => 4.5662100456621,
       pct_zn  => 21.8955123911587,
       unit    => "mg-zn-picolinate-anhydrous",
       summary => "Zinc picolinate (Zn(C6H4NO2)2), in milligrams",
     },
     {
       amount  => 5.12820512820513,
       pct_zn  => 19.5397489539749,
       unit    => "mg-zn-picolinate-dihydrate",
       summary => "Zinc picolinate dihydrate (Zn(C6H4NO2)2.2H2O) [most common hydrate form, along with -tetrahydrate], in milligrams",
     },
     {
       amount  => 5.68181818181818,
       pct_zn  => 17.6416621694549,
       unit    => "mg-zn-picolinate-tetrahydrate",
       summary => "Zinc picolinate tetrahydrate (Zn(C6H4NO2)2.2H2O) [most common hydrate form, along with -dihydrate], in milligrams",
     },
     {
       amount  => 6.99300699300699,
       pct_zn  => 14.347158218126,
       unit    => "mg-zn-gluconate-anhydrous",
       summary => "Zinc gluconate anhydrous (Zn(C6H11O7)2) [uncommon], in milligrams",
     },
     {
       amount  => 7.5187969924812,
       pct_zn  => 13.2967256457189,
       unit    => "mg-zn-gluconate-dihydrate",
       summary => "Zinc gluconate dihydrate (Zn(C6H11O7)2.2H2O) [most common hydrate form with trihydrate], in milligrams",
     },
     {
       amount  => 7.8125,
       pct_zn  => 12.8271532273887,
       unit    => "mg-zn-gluconate-trihydrate",
       summary => "Zinc gluconate trihydrate (Zn(C6H11O7)2.3H2O) [most common hydrate form with dihydrate], in milligrams",
     },
     {
       amount  => 2.92397660818713,
       pct_zn  => 34.1528817691102,
       unit    => "mg-zn-citrate-andhydrous",
       summary => "Zinc citrate (trizinc dicitrate) anhydrous (Zn3(C6H5O7)2), in milligrams",
     },
     {
       amount  => 3.20512820512821,
       pct_zn  => 31.2175712239376,
       unit    => "mg-zn-citrate-dihydrate",
       summary => "Zinc citrate (trizinc dicitrate) dihydrate (Zn3(C6H5O7)2.2H2O) [most common hydrate form], in milligrams",
     },
     {
       amount  => 3.20512820512821,
       pct_zn  => 31.2175712239376,
       unit    => "mg-zn-citrate-trihydrate",
       summary => "Zinc citrate (trizinc dicitrate) trihydrate (Zn3(C6H5O7)2.3H2O) [uncommon], in milligrams",
     },
     {
       amount  => 1.2453300124533,
       pct_zn  => 80.3391496682232,
       unit    => "mg-zn-oxide",
       summary => "Zinc oxide (ZnO), in milligrams",
     },
     {
       amount  => 2.46913580246914,
       pct_zn  => 40.4829721362229,
       unit    => "mg-zn-sulfate-anhydrous",
       summary => "Zinc sulfate anhydrous (ZnSO4), in milligrams",
     },
     {
       amount  => 4.40528634361233,
       pct_zn  => 22.7408695652174,
       unit    => "mg-zn-sulfate-heptahydrate",
       summary => "Zinc sulfate heptahydrate (ZnSO4.7H2O) [most common hydrate form], in milligrams",
     },
     {
       amount  => 3.02114803625378,
       pct_zn  => 33.1037974683544,
       unit    => "mg-zn-sulfate-dihydrate",
       summary => "Zinc sulfate dihydrate (ZnSO4.7H2O) [less common hydrate form], in milligrams",
     },
     {
       amount  => 3.26797385620915,
       pct_zn  => 30.6229508196721,
       unit    => "mg-zn-glycinate-anhydrous",
       summary => "Zinc (bis)glycinate anhydrous (C4H8N2O4Zn) [most common hydrate form], in milligrams",
     },
     {
       amount  => 3.57142857142857,
       pct_zn  => 28,
       unit    => "mg-zn-glycinate-monohydrate",
       summary => "Zinc (bis)glycinate monohydrate (C4H8N2O4Zn.H2O), in milligrams",
     },
   ],
   {
     "table.fields"        => ["amount", "pct_zn", "unit", "summary"],
     "table.field_aligns"  => ["number", "number", "left", "left"],
     "table.field_formats" => [
                                ["number", { precision => 3, thousands_sep => "" }],
                                ["number", { thousands_sep => "", precision => 3 }],
                                undef,
                                undef,
                              ],
   },
 ]

=back

If target unit is not specified, will show all known conversions.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<quantity> => I<str> (default: "1 mg")

(No description)

=item * B<to_unit> => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-MineralUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MineralUtils>.

=head1 SEE ALSO

L<App::VitaminUtils>

L<Physics::Unit>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MineralUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
