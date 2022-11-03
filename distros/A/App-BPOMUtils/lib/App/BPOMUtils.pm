package App::BPOMUtils;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter 'import';
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-02'; # DATE
our $DIST = 'App-BPOMUtils'; # DIST
our $VERSION = '0.013'; # VERSION

our @EXPORT_OK = qw(
                       bpom_list_food_categories
                       bpom_list_food_types
                       bpom_list_food_additives
                       bpom_list_food_ingredients
                       bpom_list_reg_code_prefixes
                       bpom_list_microbe_inputs
                       bpom_list_inputs
                       bpom_show_nutrition_facts
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to BPOM',
};

my $res;

require App::BPOMUtils::Table;
$res = gen_read_table_func(
    name => 'bpom_list_food_categories',
    summary => 'List food categories in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_kategori_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_kategori_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
            {
                summary => 'Print active categories codes matching "cokelat"',
                src_plang => "bash",
                src => "[[prog]] --status-is Aktif 'cokelat hitam'",
                test => 0,
            },
            {
                summary => 'Print active records matching "cokelat hitam" in a formatted text table',
                src_plang => "bash",
                src => "[[prog]] --status-is Aktif 'cokelat hitam' -l --format text-pretty",
                test => 0,
            },
            {
                summary => 'Print all category records with code 14.1.4.2',
                src_plang => "bash",
                src => "[[prog]] --code-matches '^14010402' -l --format text-pretty",
                test => 0,
            },
            {
                summary => 'How many categories are active vs inactive?',
                src_plang => "bash",
                src => "echo -n 'Aktif: '; [[prog]] --status-is Aktif | wc -l; echo -n 'Tidak Aktif: '; [[prog]] --status-isnt Aktif | wc -l",
                test => 0,
            },
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_food_types',
    summary => 'List food types in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_jenis_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_jenis_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_reg_code_prefixes',
    summary => 'List known alphabetical prefixes in BPOM registered product codes',
    table_data => $App::BPOMUtils::Table::data_reg_code_prefixes,
    table_spec => $App::BPOMUtils::Table::meta_reg_code_prefixes,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_food_ingredients',
    summary => 'List ingredients in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_bahan_baku_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_bahan_baku_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_food_additives',
    summary => 'List additives in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_bahan_tambahan_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_bahan_tambahan_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
            {
                summary => 'Check for additives that contain "dextrin" but do not contain "gamma"',
                src_plang => 'bash',
                src => '[[prog]] -l --format text-pretty -- dextrin -gamma',
                test => 0,
            },
            {
                summary => 'Check for additives that contain "magnesium" or "titanium"',
                src_plang => 'bash',
                src => '[[prog]] -l --format text-pretty --or -- magnesium titanium',
                test => 0,
            },
            {
                summary => 'Check for additives that match some regular expressions',
                src_plang => 'bash',
                src => '[[prog]] -l --format text-pretty -- /potassium/ /citrate|phosphate/',
                test => 0,
            },
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_food_microbe_inputs',
    summary => 'List of microbe specification in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_cemaran_mikroba_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_cemaran_mikroba_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'bpom_list_food_inputs',
    summary => 'List of basic characteristic and heavy metal pollutant references in BPOM processed food division',
    table_data => $App::BPOMUtils::Table::data_idn_bpom_karakteristik_dasar_dan_cemaran_logam_pangan,
    table_spec => $App::BPOMUtils::Table::meta_idn_bpom_karakteristik_dasar_dan_cemaran_logam_pangan,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

sub _nearest {
    require Math::Round;
    Math::Round::nearest(@_);
}

sub _fmt_num_id {
    require Number::Format;
    state $nf = Number::Format->new(THOUSANDS_SEP=>".", DECIMAL_POINT=>",");
    $nf->format_number(@_);
}

$SPEC{bpom_show_nutrition_facts} = {
    v => 1.1,
    summary => 'Round values and format them as nutrition fact table (ING - informasi nilai gizi)',
    args => {
        name => {schema=>'str*'},

        # XXX output_format: vertical table, horizontal table, simple table, csv. currently only simple table is supported
        output_format => {
            schema => ['str*', {in=>[qw/
                                           raw_table
                                           vertical_html_table vertical_text_table
                                           linear_html linear_text
                                       /]}],
            # horizontal_html_table horizontal_text_table formats not supported yet
            default => 'vertical_text_table',
            cmdline_aliases => {
                f=>{},
            },
            tags => ['category:output'],
        },

        browser => {
            summary => 'View output HTML in browser instead of returning it',
            schema => 'true*',
            tags => ['category:output'],
        },

        color => {
            schema => ['str*', in=>[qw/always auto never/]],
            default => 'auto',
            tags => ['category:output'],
        },

        fat           => {summary => 'Total fat, in g/100g'           , schema => 'ufloat*', req=>1},
        saturated_fat => {summary => 'Saturated fat, in g/100g'       , schema => 'ufloat*', req=>1},
        protein       => {summary => 'Protein, in g/100g'             , schema => 'ufloat*', req=>1},
        carbohydrate  => {summary => 'Total carbohydrate, in g/100g'  , schema => 'ufloat*', req=>1},
        sugar         => {summary => 'Total sugar, in g/100g'         , schema => 'ufloat*', req=>1},
        sodium        => {summary => 'Sodium, in mg/100g'             , schema => 'ufloat*', req=>1, cmdline_aliases=>{salt=>{}}},

        serving_size  => {summary => 'Serving size, in g'             , schema => 'ufloat*', req=>1},
        package_size  => {summary => 'Packaging size, in g'           , schema => 'ufloat*', req=>1},
    },

    examples => [
        {
            summary => 'An example, in linear text format (color/emphasis is shown with markup)',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"linear_text", color=>"never"},
            test => 0,
        },
        {
            summary => 'The same example in vetical HTML table format',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"vertical_html_table"},
            test => 0,
        },
        {
            summary => 'The same example, in vertical text format (color/emphasis is shown with markup)',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"vertical_text_table", color=>"never"},
            test => 0,
        },
    ],
};
sub bpom_show_nutrition_facts {
    my %args = @_;
    my $output_format = $args{output_format} // 'raw_table';

    my $color = $args{color} // 'auto';
    my $is_interactive = -t STDOUT; ## no critic: InputOutput::ProhibitInteractiveTest
    my $use_color = $color eq 'never' ? 0 : $color eq 'always' ? 1 : $is_interactive;

    my @rows;


    my $attr = $output_format =~ /html/ ? "raw_html" : "text";
    my $code_fmttext = sub {
        my $text = shift;
        if ($output_format =~ /html/) {
            require Org::To::HTML;
            my $res = Org::To::HTML::org_to_html(source_str => $text, naked=>1);
            die "Can't convert Org to HTML: $res->[0] - $res->[1]" if $res->[0] != 200;
            $res->[2];
        } else {
            my $res;
            if ($use_color) {
                require Org::To::ANSIText;
                $res = Org::To::ANSIText::org_to_ansi_text(source_str => $text);
                die "Can't convert Org to ANSI text: $res->[0] - $res->[1]" if $res->[0] != 200;
            } else {
                require Org::To::Text;
                $res = Org::To::Text::org_to_text(source_str => $text);
                die "Can't convert Org to text: $res->[0] - $res->[1]" if $res->[0] != 200;
            }
            $res->[2];
        }
    };

    my $per_package_ing = $args{serving_size} > $args{package_size} ? 1:0;
    my $size_key = $per_package_ing ? 'package_size' : 'serving_size';
    my $BR = $output_format =~ /html/ ? "<br />" : "\n";

    if ($output_format =~ /vertical/) {
        push @rows, [{colspan=>5, align=>'middle', $attr => $code_fmttext->("*INFORMASI NILAI GIZI*")}];
    } elsif ($output_format =~ /linear/) {
        if ($output_format =~ /html/) {
            push @rows, "<big><b>INFORMASI NILAI GIZI</b></big>&nbsp;&nbsp; ";
        } else {
            push @rows, $code_fmttext->("*INFORMASI NILAI GIZI*  ");
        }
    }

    if ($per_package_ing) {
    } else {
        if ($output_format =~ /vertical/) {
            push @rows, [{colspan=>5, text=>''}];
            push @rows, [{colspan=>5, align=>'left', bottom_border=>1,
                          $attr =>
                          $code_fmttext->("Takaran saji "._fmt_num_id($args{serving_size})." g"). $BR .
                          $code_fmttext->(_fmt_num_id(_nearest(0.5, $args{package_size} / $args{serving_size}))." Sajian per kemasan")
                      }];
            push @rows, [{colspan=>5, align=>'left', $attr => $code_fmttext->("*JUMLAH PER SAJIAN*")}];
            push @rows, [{colspan=>5, text=>''}];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("Takaran saji : " . _fmt_num_id($args{serving_size}) . " g, " .
                                        _fmt_num_id(_nearest(0.5, $args{package_size} / $args{serving_size}))." Sajian per kemasan  ");
        }
    }


  ENERGY: {
        my $code_round_energy = sub {
            my $val = shift;
            if ($val < 5)      { 0 }
            elsif ($val <= 50) { _nearest( 5, $val) }
            else               { _nearest(10, $val) }
        };

        if ($per_package_ing) {
            if ($output_format eq 'raw_table') {
            } elsif ($output_format =~ /vertical/) {
                push @rows, [{colspan=>5, $attr=>$code_fmttext->("*JUMLAH PER KEMASAN ("._fmt_num_id($args{package_size})." g*)")}];
            } elsif ($output_format =~ /linear/) {
                push @rows, $code_fmttext->("*JUMLAH PER KEMASAN ("._fmt_num_id($args{package_size})." g*) : ");
            }
        }

        my $val0 = $args{fat} * 9 + $args{protein} * 4 + $args{carbohydrate} * 4;
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_energy->($val);
        my $pct_dv_R = _nearest(1, $val/2150*100);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total energy',
                name_ind => 'Energi total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv        => $val/2150*100,
                pct_dv_R      => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            if ($per_package_ing) {
                push @rows, [{bottom_border=>1, colspan=>5, $attr=>$code_fmttext->("*Energi total $valr kkal*")}];
            } else {
                push @rows, [{colspan=>3, $attr=>$code_fmttext->("*Energi total*")}, {colspan=>2, align=>'right', $attr=>$code_fmttext->("*$valr kkal*")}];
            }
        } elsif ($output_format =~ /linear/) {
            if ($per_package_ing) {
                push @rows, $code_fmttext->("*Energi total $valr kkal*, ");
            } else {
                push @rows, $code_fmttext->("*Energi total $valr kkal*, ");
            }
        }

      ENERGY_FROM_FAT: {
            my $val0 = $args{fat} * 9;
            my $val  = $val0*$args{serving_size}/100;
            my $valr = $code_round_energy->($val);
            if ($output_format eq 'raw_table') {
                push @rows, {
                    name_eng => 'Energy from fat',
                    name_ind => 'Energi dari lemak',
                    val_per_100g  => $val0,
                    (val_per_srv   => $val,
                     val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                    (val_per_pkg   => $val,
                     val_per_pkg_R => $valr) x $per_package_ing,
                };
            } elsif ($output_format =~ /vertical/) {
                if ($per_package_ing) {
                } else {
                    push @rows, ['', {colspan=>2, $attr=>$code_fmttext->("Energi dari lemak")}, {colspan=>2, align=>'right', $attr=>$code_fmttext->("$valr kkal")}];
                }
            } elsif ($output_format =~ /linear/) {
                push @rows, $code_fmttext->("Energi dari lemak $valr kkal, ");
            }
        }

      ENERGY_FROM_SATURATED_FAT: {
            my $val0 = $args{saturated_fat} * 9;
            my $val  = $val0*$args{$size_key}/100;
            my $valr = $code_round_energy->($val);
            if ($output_format eq 'raw_table') {
                push @rows, {
                    name_eng => 'Energy from saturated fat',
                    name_ind => 'Energi dari lemak jenuh',
                    val_per_100g  => $val0,
                    (val_per_srv   => $val,
                     val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                    (val_per_pkg   => $val,
                     val_per_pkg_R => $valr) x $per_package_ing,
                };
            } elsif ($output_format =~ /vertical/) {
                if ($per_package_ing) {
                } else {
                    push @rows, [{bottom_border=>1, text=>''}, {colspan=>2, $attr=>$code_fmttext->("Energi dari lemak jenuh")}, {colspan=>2, align=>'right', $attr=>$code_fmttext->("$valr kkal")}];
                }
            } elsif ($output_format =~ /linear/) {
                push @rows, $code_fmttext->("Energi dari lemak jenuh $valr kkal, ");
            }
        }
    } # ENERGY

    if ($output_format eq 'raw_table') {
    } elsif ($output_format =~ /vertical/) {
        push @rows, [{colspan=>3, text=>''}, {colspan=>2, align=>'middle', $attr=>$code_fmttext->("*\% AKG**")}];
    } elsif ($output_format =~ /linear/) {
    }

  FAT: {
        my $code_round_fat = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            elsif ($val <= 5)  { sprintf("%.1f", _nearest(0.5, $val)) }
            else               { _nearest(1  , $val) }
        };
        my $code_round_fat_pct_dv = sub {
            my ($val, $fat_valr) = @_;
            if ($fat_valr == 0) { 0 }
            else                { _nearest(1  , $val) }
        };

        my $val0 = $args{fat};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_fat->($val);
        my $pct_dv_R = $code_round_fat_pct_dv->($val/67*100, $valr);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total fat',
                name_ind => 'Lemak total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $val/67*100,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Lemak total*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Lemak total $valr g ($pct_dv_R% AKG)*, ");
        }

      SATURATED_FAT: {
            my $val0 = $args{saturated_fat};
            my $val  = $val0*$args{$size_key}/100;
            my $valr = $code_round_fat->($val);
            my $pct_dv_R = $code_round_fat_pct_dv->($val/20*100, $valr);
            if ($output_format eq 'raw_table') {
                push @rows, {
                    name_eng => 'Saturated fat',
                    name_ind => 'Lemak jenuh',
                    val_per_100g  => $val0,
                    (val_per_srv   => $val,
                     val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                    (val_per_pkg   => $val,
                     val_per_pkg_R => $valr) x $per_package_ing,
                    pct_dv   => $val/20*100,
                    pct_dv_R => $pct_dv_R,
                };
            } elsif ($output_format =~ /vertical/) {
                push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Lemak jenuh*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
            } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Lemak jenuh $valr g ($pct_dv_R% AKG)*, ");
            }
        }
    } # FAT

  PROTEIN: {
        my $code_round_protein = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            else               { _nearest(1  , $val) }
        };
        my $code_round_protein_pct_dv = sub {
            my ($val, $fat_valr) = @_;
            if ($fat_valr == 0) { 0 }
            else                { _nearest(1  , $val) }
        };

        my $val0 = $args{protein};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_protein->($val);
        my $pct_dv_R = $code_round_protein_pct_dv->($val/60*100, $valr);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Protein',
                name_ind => 'Protein',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $val/60*100,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Protein*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Protein $valr g ($pct_dv_R% AKG)*, ");
        }
    }

  CARBOHYDRATE: {
        my $code_round_carbohydrate = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            else               { _nearest(1  , $val) }
        };
        my $code_round_carbohydrate_pct_dv = sub {
            my ($val, $fat_valr) = @_;
            if ($fat_valr == 0) { 0 }
            else                { _nearest(1  , $val) }
        };

        my $val0 = $args{carbohydrate};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_carbohydrate->($val);
        my $pct_dv_R = $code_round_carbohydrate_pct_dv->($val/325*100, $valr);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total carbohydrate',
                name_ind => 'Karbohidrat total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $val/325*100,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Karbohidrat total*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Karbohidrat total $valr g ($pct_dv_R% AKG)*, ");
        }
    }

  SUGAR: {
        my $code_round_sugar = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            else               { _nearest(1  , $val) }
        };

        my $val0 = $args{sugar};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_sugar->($val);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total sugar',
                name_ind => 'Gula total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Gula*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, '', ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Gula $valr g*, ");
        }
    }

  SODIUM: {
        my $code_round_sodium = sub {
            my $val = shift;
            if ($val < 5)       { 0 }
            elsif ($val <= 140) { _nearest( 5, $val) }
            else                { _nearest(10, $val) }
        };
        my $code_round_sodium_pct_dv = sub {
            my ($val, $fat_valr) = @_;
            if ($fat_valr == 0) { 0 }
            else                { _nearest(1  , $val) }
        };

        my $val0 = $args{sodium};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_sodium->($val);
        my $pct_dv_R = $code_round_sodium_pct_dv->($val/325*100, $valr);
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Salt (Sodium)',
                name_ind => 'Garam (Natrium)',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $val/325*100,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{bottom_border=>1, colspan=>2, $attr=>$code_fmttext->("*Garam (Natrium)*")}, {align=>'right', $attr=>$code_fmttext->("*$valr mg*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Garam (Natrium) $valr mg ($pct_dv_R% AKG)*. ");
        }
    }

    if ($output_format eq 'raw_table') {
    } elsif ($output_format =~ /vertical/) {
        push @rows, [{colspan=>5, $attr=>$code_fmttext->("/*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./")}];
    } elsif ($output_format =~ /linear/) {
        push @rows, $code_fmttext->(                      "/Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./");
    }


  OUTPUT:
    if ($output_format eq 'raw_table') {
        return [200, "OK", \@rows, {'table.fields'=>[qw/name_eng name_ind val_per_100g val_per_srv val_per_srv_R val_per_pkg val_per_pkg_R pct_dv pct_dv_R/]}];
    }

    my $text;
    if ($output_format =~ /vertical/) {
        if ($output_format =~ /html/) {
            require Text::Table::HTML;
            my $table = Text::Table::HTML::table(rows => \@rows, header_row=>0);
            $table =~ s!<table>!<table><colgroup><col style="width:16pt;"><col style="width:200pt;"><col style="width:48pt;"><col style="width:48pt;"><col style="width:36pt;"></colgroup>!;
            $text = "
<style>
  table { border-collapse: collapse; border: 1px solid; }
  tr.has_bottom_border { border-bottom: 1pt solid black; }
  // td:first-child { background: red; }
</style>\n" . $table;
        } else {
            require Text::Table::More;
            $text = Text::Table::More::generate_table(rows => \@rows, color=>1, header_row=>0);
        }
    } elsif ($output_format =~ /linear/) {
        $text = join("", @rows). "\n";
    }

    if ($output_format =~ /html/ && $args{browser}) {
        require Browser::Open;
        require File::Slurper;
        require File::Temp;

        my $tempdir = File::Temp::tempdir();
        my $temppath = "$tempdir/ing.html";
        File::Slurper::write_text($temppath, $text);

        my $url = "file:$temppath";
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser"] if $err;
        return [200];
    }

    return [200, "OK", $text, {'cmdline.skip_format'=>1}];
}

1;
# ABSTRACT: Utilities related to BPOM

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils - Utilities related to BPOM

=head1 VERSION

This document describes version 0.013 of App::BPOMUtils (from Perl distribution App-BPOMUtils), released on 2022-11-02.

=head1 SYNOPSIS

 # Use via the included scripts

=head1 DESCRIPTION

This distribution includes CLI utilities related to BPOM (Badan Pengawas Obat
dan Makanan, Indonesian equivalent of Food & Drug Administration authority).

=over

=item * L<bpom-daftar-bahan-baku-pangan>

=item * L<bpom-daftar-bahan-tambahan-pangan>

=item * L<bpom-daftar-cemaran-logam-pangan>

=item * L<bpom-daftar-cemaran-mikroba-pangan>

=item * L<bpom-daftar-jenis-pangan>

=item * L<bpom-daftar-kategori-pangan>

=item * L<bpom-daftar-kode-prefiks-reg>

=item * L<bpom-list-food-additives>

=item * L<bpom-list-food-categories>

=item * L<bpom-list-food-ingredients>

=item * L<bpom-list-food-inputs>

=item * L<bpom-list-food-microbe-inputs>

=item * L<bpom-list-food-types>

=item * L<bpom-list-reg-code-prefixes>

=item * L<bpom-show-nutrition-facts>

=item * L<bpom-tampilkan-ing>

=back

=head1 FUNCTIONS


=head2 bpom_list_food_additives

Usage:

 bpom_list_food_additives(%args) -> [$status_code, $reason, $payload, \%result_meta]

List additives in BPOM processed food division.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<id> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.contains> => I<str>

Only return records where the 'id' field contains specified text.

=item * B<id.in> => I<array[str]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<str>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<str>

Only return records where the 'id' field does not equal specified value.

=item * B<id.matches> => I<str>

Only return records where the 'id' field matches specified regular expression pattern.

=item * B<id.max> => I<str>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<str>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_contains> => I<str>

Only return records where the 'id' field does not contain specified text.

=item * B<id.not_in> => I<array[str]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.not_matches> => I<str>

Only return records where the 'id' field does not match specified regular expression.

=item * B<id.xmax> => I<str>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<str>

Only return records where the 'id' field is greater than specified value.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.matches> => I<str>

Only return records where the 'name' field matches specified regular expression pattern.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.not_matches> => I<str>

Only return records where the 'name' field does not match specified regular expression.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_food_categories

Usage:

 bpom_list_food_categories(%args) -> [$status_code, $reason, $payload, \%result_meta]

List food categories in BPOM processed food division.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.matches> => I<str>

Only return records where the 'code' field matches specified regular expression pattern.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.not_matches> => I<str>

Only return records where the 'code' field does not match specified regular expression.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.matches> => I<str>

Only return records where the 'name' field matches specified regular expression pattern.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.not_matches> => I<str>

Only return records where the 'name' field does not match specified regular expression.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<status> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.contains> => I<str>

Only return records where the 'status' field contains specified text.

=item * B<status.in> => I<array[str]>

Only return records where the 'status' field is in the specified values.

=item * B<status.is> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.isnt> => I<str>

Only return records where the 'status' field does not equal specified value.

=item * B<status.matches> => I<str>

Only return records where the 'status' field matches specified regular expression pattern.

=item * B<status.max> => I<str>

Only return records where the 'status' field is less than or equal to specified value.

=item * B<status.min> => I<str>

Only return records where the 'status' field is greater than or equal to specified value.

=item * B<status.not_contains> => I<str>

Only return records where the 'status' field does not contain specified text.

=item * B<status.not_in> => I<array[str]>

Only return records where the 'status' field is not in the specified values.

=item * B<status.not_matches> => I<str>

Only return records where the 'status' field does not match specified regular expression.

=item * B<status.xmax> => I<str>

Only return records where the 'status' field is less than specified value.

=item * B<status.xmin> => I<str>

Only return records where the 'status' field is greater than specified value.

=item * B<summary> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.contains> => I<str>

Only return records where the 'summary' field contains specified text.

=item * B<summary.in> => I<array[str]>

Only return records where the 'summary' field is in the specified values.

=item * B<summary.is> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.isnt> => I<str>

Only return records where the 'summary' field does not equal specified value.

=item * B<summary.matches> => I<str>

Only return records where the 'summary' field matches specified regular expression pattern.

=item * B<summary.max> => I<str>

Only return records where the 'summary' field is less than or equal to specified value.

=item * B<summary.min> => I<str>

Only return records where the 'summary' field is greater than or equal to specified value.

=item * B<summary.not_contains> => I<str>

Only return records where the 'summary' field does not contain specified text.

=item * B<summary.not_in> => I<array[str]>

Only return records where the 'summary' field is not in the specified values.

=item * B<summary.not_matches> => I<str>

Only return records where the 'summary' field does not match specified regular expression.

=item * B<summary.xmax> => I<str>

Only return records where the 'summary' field is less than specified value.

=item * B<summary.xmin> => I<str>

Only return records where the 'summary' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_food_ingredients

Usage:

 bpom_list_food_ingredients(%args) -> [$status_code, $reason, $payload, \%result_meta]

List ingredients in BPOM processed food division.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<country_of_origin> => I<str>

Only return records where the 'country_of_origin' field equals specified value.

=item * B<country_of_origin.contains> => I<str>

Only return records where the 'country_of_origin' field contains specified text.

=item * B<country_of_origin.in> => I<array[str]>

Only return records where the 'country_of_origin' field is in the specified values.

=item * B<country_of_origin.is> => I<str>

Only return records where the 'country_of_origin' field equals specified value.

=item * B<country_of_origin.isnt> => I<str>

Only return records where the 'country_of_origin' field does not equal specified value.

=item * B<country_of_origin.matches> => I<str>

Only return records where the 'country_of_origin' field matches specified regular expression pattern.

=item * B<country_of_origin.max> => I<str>

Only return records where the 'country_of_origin' field is less than or equal to specified value.

=item * B<country_of_origin.min> => I<str>

Only return records where the 'country_of_origin' field is greater than or equal to specified value.

=item * B<country_of_origin.not_contains> => I<str>

Only return records where the 'country_of_origin' field does not contain specified text.

=item * B<country_of_origin.not_in> => I<array[str]>

Only return records where the 'country_of_origin' field is not in the specified values.

=item * B<country_of_origin.not_matches> => I<str>

Only return records where the 'country_of_origin' field does not match specified regular expression.

=item * B<country_of_origin.xmax> => I<str>

Only return records where the 'country_of_origin' field is less than specified value.

=item * B<country_of_origin.xmin> => I<str>

Only return records where the 'country_of_origin' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<id> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.in> => I<array[int]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<int>

Only return records where the 'id' field does not equal specified value.

=item * B<id.max> => I<int>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<int>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_in> => I<array[int]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.xmax> => I<int>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<int>

Only return records where the 'id' field is greater than specified value.

=item * B<is_herbal> => I<str>

Only return records where the 'is_herbal' field equals specified value.

=item * B<is_herbal.contains> => I<str>

Only return records where the 'is_herbal' field contains specified text.

=item * B<is_herbal.in> => I<array[str]>

Only return records where the 'is_herbal' field is in the specified values.

=item * B<is_herbal.is> => I<str>

Only return records where the 'is_herbal' field equals specified value.

=item * B<is_herbal.isnt> => I<str>

Only return records where the 'is_herbal' field does not equal specified value.

=item * B<is_herbal.matches> => I<str>

Only return records where the 'is_herbal' field matches specified regular expression pattern.

=item * B<is_herbal.max> => I<str>

Only return records where the 'is_herbal' field is less than or equal to specified value.

=item * B<is_herbal.min> => I<str>

Only return records where the 'is_herbal' field is greater than or equal to specified value.

=item * B<is_herbal.not_contains> => I<str>

Only return records where the 'is_herbal' field does not contain specified text.

=item * B<is_herbal.not_in> => I<array[str]>

Only return records where the 'is_herbal' field is not in the specified values.

=item * B<is_herbal.not_matches> => I<str>

Only return records where the 'is_herbal' field does not match specified regular expression.

=item * B<is_herbal.xmax> => I<str>

Only return records where the 'is_herbal' field is less than specified value.

=item * B<is_herbal.xmin> => I<str>

Only return records where the 'is_herbal' field is greater than specified value.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.matches> => I<str>

Only return records where the 'name' field matches specified regular expression pattern.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.not_matches> => I<str>

Only return records where the 'name' field does not match specified regular expression.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

=item * B<origin> => I<str>

Only return records where the 'origin' field equals specified value.

=item * B<origin.contains> => I<str>

Only return records where the 'origin' field contains specified text.

=item * B<origin.in> => I<array[str]>

Only return records where the 'origin' field is in the specified values.

=item * B<origin.is> => I<str>

Only return records where the 'origin' field equals specified value.

=item * B<origin.isnt> => I<str>

Only return records where the 'origin' field does not equal specified value.

=item * B<origin.matches> => I<str>

Only return records where the 'origin' field matches specified regular expression pattern.

=item * B<origin.max> => I<str>

Only return records where the 'origin' field is less than or equal to specified value.

=item * B<origin.min> => I<str>

Only return records where the 'origin' field is greater than or equal to specified value.

=item * B<origin.not_contains> => I<str>

Only return records where the 'origin' field does not contain specified text.

=item * B<origin.not_in> => I<array[str]>

Only return records where the 'origin' field is not in the specified values.

=item * B<origin.not_matches> => I<str>

Only return records where the 'origin' field does not match specified regular expression.

=item * B<origin.xmax> => I<str>

Only return records where the 'origin' field is less than specified value.

=item * B<origin.xmin> => I<str>

Only return records where the 'origin' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<status> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.contains> => I<str>

Only return records where the 'status' field contains specified text.

=item * B<status.in> => I<array[str]>

Only return records where the 'status' field is in the specified values.

=item * B<status.is> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.isnt> => I<str>

Only return records where the 'status' field does not equal specified value.

=item * B<status.matches> => I<str>

Only return records where the 'status' field matches specified regular expression pattern.

=item * B<status.max> => I<str>

Only return records where the 'status' field is less than or equal to specified value.

=item * B<status.min> => I<str>

Only return records where the 'status' field is greater than or equal to specified value.

=item * B<status.not_contains> => I<str>

Only return records where the 'status' field does not contain specified text.

=item * B<status.not_in> => I<array[str]>

Only return records where the 'status' field is not in the specified values.

=item * B<status.not_matches> => I<str>

Only return records where the 'status' field does not match specified regular expression.

=item * B<status.xmax> => I<str>

Only return records where the 'status' field is less than specified value.

=item * B<status.xmin> => I<str>

Only return records where the 'status' field is greater than specified value.

=item * B<type> => I<str>

Only return records where the 'type' field equals specified value.

=item * B<type.contains> => I<str>

Only return records where the 'type' field contains specified text.

=item * B<type.in> => I<array[str]>

Only return records where the 'type' field is in the specified values.

=item * B<type.is> => I<str>

Only return records where the 'type' field equals specified value.

=item * B<type.isnt> => I<str>

Only return records where the 'type' field does not equal specified value.

=item * B<type.matches> => I<str>

Only return records where the 'type' field matches specified regular expression pattern.

=item * B<type.max> => I<str>

Only return records where the 'type' field is less than or equal to specified value.

=item * B<type.min> => I<str>

Only return records where the 'type' field is greater than or equal to specified value.

=item * B<type.not_contains> => I<str>

Only return records where the 'type' field does not contain specified text.

=item * B<type.not_in> => I<array[str]>

Only return records where the 'type' field is not in the specified values.

=item * B<type.not_matches> => I<str>

Only return records where the 'type' field does not match specified regular expression.

=item * B<type.xmax> => I<str>

Only return records where the 'type' field is less than specified value.

=item * B<type.xmin> => I<str>

Only return records where the 'type' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_food_inputs

Usage:

 bpom_list_food_inputs(%args) -> [$status_code, $reason, $payload, \%result_meta]

List of basic characteristic and heavy metal pollutant references in BPOM processed food division.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.contains> => I<str>

Only return records where the 'category' field contains specified text.

=item * B<category.in> => I<array[str]>

Only return records where the 'category' field is in the specified values.

=item * B<category.is> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.isnt> => I<str>

Only return records where the 'category' field does not equal specified value.

=item * B<category.matches> => I<str>

Only return records where the 'category' field matches specified regular expression pattern.

=item * B<category.max> => I<str>

Only return records where the 'category' field is less than or equal to specified value.

=item * B<category.min> => I<str>

Only return records where the 'category' field is greater than or equal to specified value.

=item * B<category.not_contains> => I<str>

Only return records where the 'category' field does not contain specified text.

=item * B<category.not_in> => I<array[str]>

Only return records where the 'category' field is not in the specified values.

=item * B<category.not_matches> => I<str>

Only return records where the 'category' field does not match specified regular expression.

=item * B<category.xmax> => I<str>

Only return records where the 'category' field is less than specified value.

=item * B<category.xmin> => I<str>

Only return records where the 'category' field is greater than specified value.

=item * B<characteristic> => I<str>

Only return records where the 'characteristic' field equals specified value.

=item * B<characteristic.contains> => I<str>

Only return records where the 'characteristic' field contains specified text.

=item * B<characteristic.in> => I<array[str]>

Only return records where the 'characteristic' field is in the specified values.

=item * B<characteristic.is> => I<str>

Only return records where the 'characteristic' field equals specified value.

=item * B<characteristic.isnt> => I<str>

Only return records where the 'characteristic' field does not equal specified value.

=item * B<characteristic.matches> => I<str>

Only return records where the 'characteristic' field matches specified regular expression pattern.

=item * B<characteristic.max> => I<str>

Only return records where the 'characteristic' field is less than or equal to specified value.

=item * B<characteristic.min> => I<str>

Only return records where the 'characteristic' field is greater than or equal to specified value.

=item * B<characteristic.not_contains> => I<str>

Only return records where the 'characteristic' field does not contain specified text.

=item * B<characteristic.not_in> => I<array[str]>

Only return records where the 'characteristic' field is not in the specified values.

=item * B<characteristic.not_matches> => I<str>

Only return records where the 'characteristic' field does not match specified regular expression.

=item * B<characteristic.xmax> => I<str>

Only return records where the 'characteristic' field is less than specified value.

=item * B<characteristic.xmin> => I<str>

Only return records where the 'characteristic' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<id> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.in> => I<array[int]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<int>

Only return records where the 'id' field does not equal specified value.

=item * B<id.max> => I<int>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<int>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_in> => I<array[int]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.xmax> => I<int>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<int>

Only return records where the 'id' field is greater than specified value.

=item * B<lower_limit> => I<str>

Only return records where the 'lower_limit' field equals specified value.

=item * B<lower_limit.contains> => I<str>

Only return records where the 'lower_limit' field contains specified text.

=item * B<lower_limit.in> => I<array[str]>

Only return records where the 'lower_limit' field is in the specified values.

=item * B<lower_limit.is> => I<str>

Only return records where the 'lower_limit' field equals specified value.

=item * B<lower_limit.isnt> => I<str>

Only return records where the 'lower_limit' field does not equal specified value.

=item * B<lower_limit.matches> => I<str>

Only return records where the 'lower_limit' field matches specified regular expression pattern.

=item * B<lower_limit.max> => I<str>

Only return records where the 'lower_limit' field is less than or equal to specified value.

=item * B<lower_limit.min> => I<str>

Only return records where the 'lower_limit' field is greater than or equal to specified value.

=item * B<lower_limit.not_contains> => I<str>

Only return records where the 'lower_limit' field does not contain specified text.

=item * B<lower_limit.not_in> => I<array[str]>

Only return records where the 'lower_limit' field is not in the specified values.

=item * B<lower_limit.not_matches> => I<str>

Only return records where the 'lower_limit' field does not match specified regular expression.

=item * B<lower_limit.xmax> => I<str>

Only return records where the 'lower_limit' field is less than specified value.

=item * B<lower_limit.xmin> => I<str>

Only return records where the 'lower_limit' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<upper_limit> => I<str>

Only return records where the 'upper_limit' field equals specified value.

=item * B<upper_limit.contains> => I<str>

Only return records where the 'upper_limit' field contains specified text.

=item * B<upper_limit.in> => I<array[str]>

Only return records where the 'upper_limit' field is in the specified values.

=item * B<upper_limit.is> => I<str>

Only return records where the 'upper_limit' field equals specified value.

=item * B<upper_limit.isnt> => I<str>

Only return records where the 'upper_limit' field does not equal specified value.

=item * B<upper_limit.matches> => I<str>

Only return records where the 'upper_limit' field matches specified regular expression pattern.

=item * B<upper_limit.max> => I<str>

Only return records where the 'upper_limit' field is less than or equal to specified value.

=item * B<upper_limit.min> => I<str>

Only return records where the 'upper_limit' field is greater than or equal to specified value.

=item * B<upper_limit.not_contains> => I<str>

Only return records where the 'upper_limit' field does not contain specified text.

=item * B<upper_limit.not_in> => I<array[str]>

Only return records where the 'upper_limit' field is not in the specified values.

=item * B<upper_limit.not_matches> => I<str>

Only return records where the 'upper_limit' field does not match specified regular expression.

=item * B<upper_limit.xmax> => I<str>

Only return records where the 'upper_limit' field is less than specified value.

=item * B<upper_limit.xmin> => I<str>

Only return records where the 'upper_limit' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_food_microbe_inputs

Usage:

 bpom_list_food_microbe_inputs(%args) -> [$status_code, $reason, $payload, \%result_meta]

List of microbe specification in BPOM processed food division.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<category> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.contains> => I<str>

Only return records where the 'category' field contains specified text.

=item * B<category.in> => I<array[str]>

Only return records where the 'category' field is in the specified values.

=item * B<category.is> => I<str>

Only return records where the 'category' field equals specified value.

=item * B<category.isnt> => I<str>

Only return records where the 'category' field does not equal specified value.

=item * B<category.matches> => I<str>

Only return records where the 'category' field matches specified regular expression pattern.

=item * B<category.max> => I<str>

Only return records where the 'category' field is less than or equal to specified value.

=item * B<category.min> => I<str>

Only return records where the 'category' field is greater than or equal to specified value.

=item * B<category.not_contains> => I<str>

Only return records where the 'category' field does not contain specified text.

=item * B<category.not_in> => I<array[str]>

Only return records where the 'category' field is not in the specified values.

=item * B<category.not_matches> => I<str>

Only return records where the 'category' field does not match specified regular expression.

=item * B<category.xmax> => I<str>

Only return records where the 'category' field is less than specified value.

=item * B<category.xmin> => I<str>

Only return records where the 'category' field is greater than specified value.

=item * B<characteristic> => I<str>

Only return records where the 'characteristic' field equals specified value.

=item * B<characteristic.contains> => I<str>

Only return records where the 'characteristic' field contains specified text.

=item * B<characteristic.in> => I<array[str]>

Only return records where the 'characteristic' field is in the specified values.

=item * B<characteristic.is> => I<str>

Only return records where the 'characteristic' field equals specified value.

=item * B<characteristic.isnt> => I<str>

Only return records where the 'characteristic' field does not equal specified value.

=item * B<characteristic.matches> => I<str>

Only return records where the 'characteristic' field matches specified regular expression pattern.

=item * B<characteristic.max> => I<str>

Only return records where the 'characteristic' field is less than or equal to specified value.

=item * B<characteristic.min> => I<str>

Only return records where the 'characteristic' field is greater than or equal to specified value.

=item * B<characteristic.not_contains> => I<str>

Only return records where the 'characteristic' field does not contain specified text.

=item * B<characteristic.not_in> => I<array[str]>

Only return records where the 'characteristic' field is not in the specified values.

=item * B<characteristic.not_matches> => I<str>

Only return records where the 'characteristic' field does not match specified regular expression.

=item * B<characteristic.xmax> => I<str>

Only return records where the 'characteristic' field is less than specified value.

=item * B<characteristic.xmin> => I<str>

Only return records where the 'characteristic' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<id> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.in> => I<array[int]>

Only return records where the 'id' field is in the specified values.

=item * B<id.is> => I<int>

Only return records where the 'id' field equals specified value.

=item * B<id.isnt> => I<int>

Only return records where the 'id' field does not equal specified value.

=item * B<id.max> => I<int>

Only return records where the 'id' field is less than or equal to specified value.

=item * B<id.min> => I<int>

Only return records where the 'id' field is greater than or equal to specified value.

=item * B<id.not_in> => I<array[int]>

Only return records where the 'id' field is not in the specified values.

=item * B<id.xmax> => I<int>

Only return records where the 'id' field is less than specified value.

=item * B<id.xmin> => I<int>

Only return records where the 'id' field is greater than specified value.

=item * B<lower_limit> => I<str>

Only return records where the 'lower_limit' field equals specified value.

=item * B<lower_limit.contains> => I<str>

Only return records where the 'lower_limit' field contains specified text.

=item * B<lower_limit.in> => I<array[str]>

Only return records where the 'lower_limit' field is in the specified values.

=item * B<lower_limit.is> => I<str>

Only return records where the 'lower_limit' field equals specified value.

=item * B<lower_limit.isnt> => I<str>

Only return records where the 'lower_limit' field does not equal specified value.

=item * B<lower_limit.matches> => I<str>

Only return records where the 'lower_limit' field matches specified regular expression pattern.

=item * B<lower_limit.max> => I<str>

Only return records where the 'lower_limit' field is less than or equal to specified value.

=item * B<lower_limit.min> => I<str>

Only return records where the 'lower_limit' field is greater than or equal to specified value.

=item * B<lower_limit.not_contains> => I<str>

Only return records where the 'lower_limit' field does not contain specified text.

=item * B<lower_limit.not_in> => I<array[str]>

Only return records where the 'lower_limit' field is not in the specified values.

=item * B<lower_limit.not_matches> => I<str>

Only return records where the 'lower_limit' field does not match specified regular expression.

=item * B<lower_limit.xmax> => I<str>

Only return records where the 'lower_limit' field is less than specified value.

=item * B<lower_limit.xmin> => I<str>

Only return records where the 'lower_limit' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<upper_limit> => I<str>

Only return records where the 'upper_limit' field equals specified value.

=item * B<upper_limit.contains> => I<str>

Only return records where the 'upper_limit' field contains specified text.

=item * B<upper_limit.in> => I<array[str]>

Only return records where the 'upper_limit' field is in the specified values.

=item * B<upper_limit.is> => I<str>

Only return records where the 'upper_limit' field equals specified value.

=item * B<upper_limit.isnt> => I<str>

Only return records where the 'upper_limit' field does not equal specified value.

=item * B<upper_limit.matches> => I<str>

Only return records where the 'upper_limit' field matches specified regular expression pattern.

=item * B<upper_limit.max> => I<str>

Only return records where the 'upper_limit' field is less than or equal to specified value.

=item * B<upper_limit.min> => I<str>

Only return records where the 'upper_limit' field is greater than or equal to specified value.

=item * B<upper_limit.not_contains> => I<str>

Only return records where the 'upper_limit' field does not contain specified text.

=item * B<upper_limit.not_in> => I<array[str]>

Only return records where the 'upper_limit' field is not in the specified values.

=item * B<upper_limit.not_matches> => I<str>

Only return records where the 'upper_limit' field does not match specified regular expression.

=item * B<upper_limit.xmax> => I<str>

Only return records where the 'upper_limit' field is less than specified value.

=item * B<upper_limit.xmin> => I<str>

Only return records where the 'upper_limit' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_food_types

Usage:

 bpom_list_food_types(%args) -> [$status_code, $reason, $payload, \%result_meta]

List food types in BPOM processed food division.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.matches> => I<str>

Only return records where the 'code' field matches specified regular expression pattern.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.not_matches> => I<str>

Only return records where the 'code' field does not match specified regular expression.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<summary> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.contains> => I<str>

Only return records where the 'summary' field contains specified text.

=item * B<summary.in> => I<array[str]>

Only return records where the 'summary' field is in the specified values.

=item * B<summary.is> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.isnt> => I<str>

Only return records where the 'summary' field does not equal specified value.

=item * B<summary.matches> => I<str>

Only return records where the 'summary' field matches specified regular expression pattern.

=item * B<summary.max> => I<str>

Only return records where the 'summary' field is less than or equal to specified value.

=item * B<summary.min> => I<str>

Only return records where the 'summary' field is greater than or equal to specified value.

=item * B<summary.not_contains> => I<str>

Only return records where the 'summary' field does not contain specified text.

=item * B<summary.not_in> => I<array[str]>

Only return records where the 'summary' field is not in the specified values.

=item * B<summary.not_matches> => I<str>

Only return records where the 'summary' field does not match specified regular expression.

=item * B<summary.xmax> => I<str>

Only return records where the 'summary' field is less than specified value.

=item * B<summary.xmin> => I<str>

Only return records where the 'summary' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_list_reg_code_prefixes

Usage:

 bpom_list_reg_code_prefixes(%args) -> [$status_code, $reason, $payload, \%result_meta]

List known alphabetical prefixes in BPOM registered product codes.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<division> => I<str>

Only return records where the 'division' field equals specified value.

=item * B<division.contains> => I<str>

Only return records where the 'division' field contains specified text.

=item * B<division.in> => I<array[str]>

Only return records where the 'division' field is in the specified values.

=item * B<division.is> => I<str>

Only return records where the 'division' field equals specified value.

=item * B<division.isnt> => I<str>

Only return records where the 'division' field does not equal specified value.

=item * B<division.max> => I<str>

Only return records where the 'division' field is less than or equal to specified value.

=item * B<division.min> => I<str>

Only return records where the 'division' field is greater than or equal to specified value.

=item * B<division.not_contains> => I<str>

Only return records where the 'division' field does not contain specified text.

=item * B<division.not_in> => I<array[str]>

Only return records where the 'division' field is not in the specified values.

=item * B<division.xmax> => I<str>

Only return records where the 'division' field is less than specified value.

=item * B<division.xmin> => I<str>

Only return records where the 'division' field is greater than specified value.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<summary_eng> => I<str>

Only return records where the 'summary_eng' field equals specified value.

=item * B<summary_eng.contains> => I<str>

Only return records where the 'summary_eng' field contains specified text.

=item * B<summary_eng.in> => I<array[str]>

Only return records where the 'summary_eng' field is in the specified values.

=item * B<summary_eng.is> => I<str>

Only return records where the 'summary_eng' field equals specified value.

=item * B<summary_eng.isnt> => I<str>

Only return records where the 'summary_eng' field does not equal specified value.

=item * B<summary_eng.max> => I<str>

Only return records where the 'summary_eng' field is less than or equal to specified value.

=item * B<summary_eng.min> => I<str>

Only return records where the 'summary_eng' field is greater than or equal to specified value.

=item * B<summary_eng.not_contains> => I<str>

Only return records where the 'summary_eng' field does not contain specified text.

=item * B<summary_eng.not_in> => I<array[str]>

Only return records where the 'summary_eng' field is not in the specified values.

=item * B<summary_eng.xmax> => I<str>

Only return records where the 'summary_eng' field is less than specified value.

=item * B<summary_eng.xmin> => I<str>

Only return records where the 'summary_eng' field is greater than specified value.

=item * B<summary_ind> => I<str>

Only return records where the 'summary_ind' field equals specified value.

=item * B<summary_ind.contains> => I<str>

Only return records where the 'summary_ind' field contains specified text.

=item * B<summary_ind.in> => I<array[str]>

Only return records where the 'summary_ind' field is in the specified values.

=item * B<summary_ind.is> => I<str>

Only return records where the 'summary_ind' field equals specified value.

=item * B<summary_ind.isnt> => I<str>

Only return records where the 'summary_ind' field does not equal specified value.

=item * B<summary_ind.max> => I<str>

Only return records where the 'summary_ind' field is less than or equal to specified value.

=item * B<summary_ind.min> => I<str>

Only return records where the 'summary_ind' field is greater than or equal to specified value.

=item * B<summary_ind.not_contains> => I<str>

Only return records where the 'summary_ind' field does not contain specified text.

=item * B<summary_ind.not_in> => I<array[str]>

Only return records where the 'summary_ind' field is not in the specified values.

=item * B<summary_ind.xmax> => I<str>

Only return records where the 'summary_ind' field is less than specified value.

=item * B<summary_ind.xmin> => I<str>

Only return records where the 'summary_ind' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 bpom_show_nutrition_facts

Usage:

 bpom_show_nutrition_facts(%args) -> [$status_code, $reason, $payload, \%result_meta]

Round values and format them as nutrition fact table (ING - informasi nilai gizi).

Examples:

=over

=item * An example, in linear text format (colorE<sol>emphasis is shown with markup):

 bpom_show_nutrition_facts(
   carbohydrate => 13.113,
   color => "never",
   fat => 0.223,
   output_format => "linear_text",
   package_size => 20,
   protein => 0.99,
   saturated_fat => 0.01,
   serving_size => 175,
   sodium => 0.223,
   sugar => 7.173
 );

Result:

 [
   200,
   "OK",
   "*INFORMASI NILAI GIZI*  *JUMLAH PER KEMASAN (20 g*) : *Energi total 10 kkal*, Energi dari lemak 0 kkal, Energi dari lemak jenuh 0 kkal, *Lemak total 0 g (0% AKG)*, *Lemak jenuh 0 g (0% AKG)*, *Protein 0 g (0% AKG)*, *Karbohidrat total 3 g (1% AKG)*, *Gula 1 g*, *Garam (Natrium) 0 mg (0% AKG)*. /Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./\n",
   { "cmdline.skip_format" => 1 },
 ]

=item * The same example in vetical HTML table format:

 bpom_show_nutrition_facts(
   carbohydrate => 13.113,
   fat => 0.223,
   output_format => "vertical_html_table",
   package_size => 20,
   protein => 0.99,
   saturated_fat => 0.01,
   serving_size => 175,
   sodium => 0.223,
   sugar => 7.173
 );

Result:

 [
   200,
   "OK",
   "\n<style>\n  table { border-collapse: collapse; border: 1px solid; }\n  tr.has_bottom_border { border-bottom: 1pt solid black; }\n  // td:first-child { background: red; }\n</style>\n<table><colgroup><col style=\"width:16pt;\"><col style=\"width:200pt;\"><col style=\"width:48pt;\"><col style=\"width:48pt;\"><col style=\"width:36pt;\"></colgroup>\n<tr><td colspan=5 align=\"middle\"><b>INFORMASI NILAI GIZI</b></td></tr>\n<tbody>\n<tr><td colspan=5><b>JUMLAH PER KEMASAN (20 g</b>)</td></tr>\n<tr class=has_bottom_border><td colspan=5><b>Energi total 10 kkal</b></td></tr>\n<tr><td colspan=3></td><td colspan=2 align=\"middle\"><b>% AKG</b>*</td></tr>\n<tr><td colspan=2><b>Lemak total</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Lemak jenuh</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Protein</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Karbohidrat total</b></td><td align=\"right\"><b>3 g</b></td><td align=\"right\">1 %</td><td></td></tr>\n<tr><td colspan=2><b>Gula</b></td><td align=\"right\"><b>1 g</b></td><td></td><td></td></tr>\n<tr class=has_bottom_border><td colspan=2><b>Garam (Natrium)</b></td><td align=\"right\"><b>0 mg</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=5><i>*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah.</i></td></tr>\n</tbody>\n</table>\n",
   { "cmdline.skip_format" => 1 },
 ]

=item * The same example, in vertical text format (colorE<sol>emphasis is shown with markup):

 bpom_show_nutrition_facts(
   carbohydrate => 13.113,
   color => "never",
   fat => 0.223,
   output_format => "vertical_text_table",
   package_size => 20,
   protein => 0.99,
   saturated_fat => 0.01,
   serving_size => 175,
   sodium => 0.223,
   sugar => 7.173
 );

Result:

 [
   200,
   "OK",
   ".---------------------------------------------------------------------------------------------------------------------.\n|                                               *INFORMASI NILAI GIZI*                                                |\n| *JUMLAH PER KEMASAN (20 g*)                                                                                         |\n| *Energi total 10 kkal*                                                                                              |\n+-----------------------|----------------------|-----------------------+----------------------|-----------------------+\n|                                                                      |                   *% AKG**                   |\n| *Lemak total*                                |                 *0 g* |                  0 % |                       |\n| *Lemak jenuh*                                |                 *0 g* |                  0 % |                       |\n| *Protein*                                    |                 *0 g* |                  0 % |                       |\n| *Karbohidrat total*                          |                 *3 g* |                  1 % |                       |\n| *Gula*                                       |                 *1 g* |                      |                       |\n| *Garam (Natrium)*                            |                *0 mg* |                  0 % |                       |\n+-----------------------|----------------------+-----------------------+----------------------+-----------------------+\n| /*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./ |\n`---------------------------------------------------------------------------------------------------------------------'\n",
   { "cmdline.skip_format" => 1 },
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<browser> => I<true>

View output HTML in browser instead of returning it.

=item * B<carbohydrate>* => I<ufloat>

Total carbohydrate, in gE<sol>100g.

=item * B<color> => I<str> (default: "auto")

(No description)

=item * B<fat>* => I<ufloat>

Total fat, in gE<sol>100g.

=item * B<name> => I<str>

(No description)

=item * B<output_format> => I<str> (default: "vertical_text_table")

(No description)

=item * B<package_size>* => I<ufloat>

Packaging size, in g.

=item * B<protein>* => I<ufloat>

Protein, in gE<sol>100g.

=item * B<saturated_fat>* => I<ufloat>

Saturated fat, in gE<sol>100g.

=item * B<serving_size>* => I<ufloat>

Serving size, in g.

=item * B<sodium>* => I<ufloat>

Sodium, in mgE<sol>100g.

=item * B<sugar>* => I<ufloat>

Total sugar, in gE<sol>100g.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils>.

=head1 SEE ALSO

L<https://pom.go.id>

L<Business::ID::BPOM>

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
