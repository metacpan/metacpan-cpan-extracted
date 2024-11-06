package App::BPOMUtils::NutritionFacts;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-05'; # DATE
our $DIST = 'App-BPOMUtils-NutritionFacts'; # DIST
our $VERSION = '0.028'; # VERSION

our @EXPORT_OK = qw(
                       bpom_show_nutrition_facts
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to BPOM nutrition facts',
};

my $res;

my $M = "\N{MULTIPLICATION SIGN}";

sub _nearest {
    require Math::Round;
    Math::Round::nearest(@_);
}

sub _fmt_num_id {
    require Number::Format;
    state $nf = Number::Format->new(THOUSANDS_SEP=>".", DECIMAL_POINT=>",");
    $nf->format_number(@_);
}

my @output_formats = (qw/
                                           raw_table
                                           vertical_html_table vertical_text_table
                                           linear_html linear_text raw_linear
                                           calculation_html calculation_text
/);
# horizontal_html_table horizontal_text_table formats not supported yet

sub _add_real_and_nufact_args {
    my %args = @_;
    my %res;
    for my $key (keys %args) {
        $res{$key} = $args{$key};
        $res{"${key}_nufact"} = {
            summary => "$args{$key}{summary} (value to be used in nutrition facts table instead the lab test result)",
            schema => $args{$key}{schema},
        };
        $res{"${key}_nufact_note"} = {
            schema => "str*",
        };
    }
    %res;
}

$SPEC{bpom_show_nutrition_facts} = {
    v => 1.1,
    summary => 'Render BPOM-compliant nutrition fact table (ING - informasi nilai gizi) in various formats',
    args => {
        name => {schema=>'str*'},

        output_format => {
            summary => 'Pick an output format for the nutrition fact',
            schema => ['str*', {in=>\@output_formats}],
            description => <<'_',

`vertical_text_table` is the default. The /(vertical)?.*table/ formats presents
the information in a table, while the /linear/ formats presents the information
in a paragraph.

_
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

        _add_real_and_nufact_args(
        fat           => {summary => 'Total fat, in g/100g'           , schema => 'ufloat*', req=>1},
        saturated_fat => {summary => 'Saturated fat, in g/100g'       , schema => 'ufloat*', req=>1},
        cholesterol   => {summary => 'Cholesterol, in mg/100g'        , schema => 'ufloat*'},
        protein       => {summary => 'Protein, in g/100g'             , schema => 'ufloat*', req=>1},
        carbohydrate  => {summary => 'Total carbohydrate, in g/100g'  , schema => 'ufloat*', req=>1},
        sugar         => {summary => 'Total sugar, in g/100g'         , schema => 'ufloat*', req=>1},
        sodium        => {summary => 'Sodium, in mg/100g'             , schema => 'ufloat*', req=>1, cmdline_aliases=>{salt=>{}}},
        va            => {summary => 'Vitamin A, in mcg/100g (all-trans-)retinol', schema => 'ufloat*'},
        vd            => {summary => 'Vitamin D, in mcg', schema => 'ufloat*'},
        ve            => {summary => 'Vitamin E, in mg alpha-TE (tocopherol-equivalent)', schema => 'ufloat*'},
        vk            => {summary => 'Vitamin K, in mcg', schema => 'ufloat*'},
        vb1           => {summary => 'Vitamin B1, in mg/100g', schema => 'ufloat*'},
        vb2           => {summary => 'Vitamin B2, in mg/100g', schema => 'ufloat*'},
        vb3           => {summary => 'Vitamin B3, in mg/100g', schema => 'ufloat*'},
        vb5           => {summary => 'Vitamin B5 (pantothenic acid), in mg/100g', schema => 'ufloat*'},
        vb6           => {summary => 'Vitamin B6, in mg/100g', schema => 'ufloat*'},
        folate        => {summary => 'Folate (vitamin B9), in mcg/100g', schema => 'ufloat*'},
        vb12          => {summary => 'Vitamin B12, in mcg/100g', schema => 'ufloat*'},
        biotin        => {summary => 'Biotin, in mcg/100g', schema => 'ufloat*'},
        choline       => {summary => 'Choline, in mg/100g', schema => 'ufloat*'},
        vc            => {summary => 'Vitamin C, in mg/100g', schema => 'ufloat*'},
        ca            => {summary => 'Calcium, in mg/100g', schema => 'ufloat*'},
        phosphorus    => {summary => 'Phosphorus, in mg/100g', schema => 'ufloat*'},
        mg            => {summary => 'Magnesium, in mg/100g', schema => 'ufloat*'},
        k             => {summary => 'Potassium, in mg/100g', schema => 'ufloat*'},
        mn            => {summary => 'Manganese, in mcg/100g', schema => 'ufloat*'},
        cu            => {summary => 'Copper, in mcg/100g', schema => 'ufloat*'},
        cr            => {summary => 'Chromium, in mcg/100g', schema => 'ufloat*'},
        fe            => {summary => 'Iron, in mg/100g', schema => 'ufloat*'},
        iodium        => {summary => 'Iodium, in mcg/100g', schema => 'ufloat*'},
        zn            => {summary => 'Zinc, in mg/100g', schema => 'ufloat*'},
        se            => {summary => 'Selenium, in mcg/100g', schema => 'ufloat*'},
        fluorine      => {summary => 'Fluorine, in mg/100g', schema => 'ufloat*'},
        ),

        serving_size  => {summary => 'Serving size, in g'             , schema => 'ufloat*', req=>1},
        package_size  => {summary => 'Packaging size, in g'           , schema => 'ufloat*', req=>1},

        has_claims    => {summary => 'Whether food is registered as having claims', schema=>'bool*'},
    },

    examples => [
        {
            summary => 'An example, in linear text format (color/emphasis is shown with markup)',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"raw_linear", color=>"never"},
            test => 0,
        },
        {
            summary => 'An example, in raw_linear format (just like linear_text but with no border)',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"linear_text", color=>"never"},
            test => 0,
        },
        {
            summary => 'The same example in vertical HTML table format',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"vertical_html_table"},
            test => 0,
        },
        {
            summary => 'The same example, in vertical text format (color/emphasis is shown with markup)',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"vertical_text_table", color=>"never"},
            test => 0,
        },
        {
            summary => 'The same example, in calculation text format',
            args => {fat=>0.223, saturated_fat=>0.010, protein=>0.990, carbohydrate=>13.113, sugar=>7.173, sodium=>0.223, serving_size=>175, package_size=>20, output_format=>"calculation_text", color=>"never"},
            test => 0,
        },
    ],
};
sub bpom_show_nutrition_facts {
    my %args = @_;
    my $output_format = $args{output_format} // 'raw_table';
    return [400, "Unknown output format '$output_format'"] unless grep { $output_format eq $_ } @output_formats;

    my $color = $args{color} // 'auto';
    my $is_interactive = -t STDOUT; ## no critic: InputOutput::ProhibitInteractiveTest
    my $use_color = $color eq 'never' ? 0 : $color eq 'always' ? 1 : $is_interactive;

    my @rows;
    my $funcraw = {};

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

    $funcraw->{per_package_ing} = $per_package_ing;

    if ($output_format =~ /vertical/) {
        push @rows, [{colspan=>5, align=>'middle', $attr => $code_fmttext->("*INFORMASI NILAI GIZI*")}];
    } elsif ($output_format =~ /linear/) {
        if ($output_format =~ /html/) {
            push @rows, "<big><b>INFORMASI NILAI GIZI</b></big>&nbsp;&nbsp; ";
        } else {
            push @rows, $code_fmttext->("*INFORMASI NILAI GIZI*  ");
        }
    } elsif ($output_format =~ /calculation/) {
        push @rows, [{colspan=>2, align=>'middle', $attr => $code_fmttext->("*PERHITUNGAN INFORMASI NILAI GIZI*")}];
    }

    if ($per_package_ing) {
        if ($output_format =~ /vertical/) {
            push @rows, [{colspan=>5, text=>''}];
            push @rows, [{colspan=>5, align=>'left', $attr => $code_fmttext->("*JUMLAH PER KEMASAN ($args{package_size} g)*")}];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->(" *JUMLAH PER KEMASAN ($args{package_size} g)* : ");
        }
    } else {
        my $srvs_per_pkg = _nearest(0.5, $args{package_size} / $args{serving_size});
        $funcraw->{srvs_per_pkg} = $srvs_per_pkg;
        if ($output_format =~ /vertical/) {
            push @rows, [{colspan=>5, text=>''}];
            push @rows, [{colspan=>5, align=>'left', bottom_border=>1,
                          $attr =>
                          $code_fmttext->("Takaran saji "._fmt_num_id($args{serving_size})." g"). $BR .
                          $code_fmttext->(_fmt_num_id($srvs_per_pkg)." Sajian per Kemasan")
                      }];
            push @rows, [{colspan=>5, align=>'left', $attr => $code_fmttext->("*JUMLAH PER SAJIAN*")}];
            push @rows, [{colspan=>5, text=>''}];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("Takaran saji : " . _fmt_num_id($args{serving_size}) . " g, " .
                                        _fmt_num_id($srvs_per_pkg)." Sajian per Kemasan *JUMLAH PER SAJIAN* : ");
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Sajian per kemasan*')}];
            push @rows, [{align=>'right', text=>'Sajian per kemasan'},
                         {align=>'left', $attr=>"= $args{package_size} / $args{serving_size} = ".($args{package_size}/$args{serving_size})}];
            push @rows, [{align=>'right', text=>"(dibulatkan 0,5 terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *".$srvs_per_pkg."*")}];
        }
    }


  ENERGY: {
        my $code_round_energy = sub {
            my $val = shift;
            if ($val < 5)      { 0 }
            elsif ($val <= 50) { _nearest( 5, $val) }
            else               { _nearest(10, $val) }
        };

        my $val0 = $args{fat} * 9 + $args{protein} * 4 + $args{carbohydrate} * 4;
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_energy->($val);
        my $pct_dv = $val/2150*100;
        my $pct_dv_R = _nearest(1, $pct_dv);
        $funcraw->{total_energy_per_srv} = $val          if !$per_package_ing;
        $funcraw->{total_energy_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{total_energy_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{total_energy_per_pkg_rounded} = $valr if  $per_package_ing;
        $funcraw->{total_energy_pct_dv} = $pct_dv;
        $funcraw->{total_energy_pct_dv_rounded} = $pct_dv_R;
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total energy',
                name_ind => 'Energi total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv        => $pct_dv,
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
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Energi total*')}];
            push @rows, [{align=>'right', text=>'Energi total per 100 g'},
                         {align=>'left', $attr=>"= lemak $M 9 + protein $M 4 + karbohidrat $M 4 = $args{fat} $M 9 + $args{protein} $M 4 + $args{carbohydrate} $M 4 = $val0 kkal"}];
            push @rows, [{align=>'right', text=>"Energi total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val kkal"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* kkal")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG energi total*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 2150 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
        }

      ENERGY_FROM_FAT: {
            my $val0 = $args{fat} * 9;
            my $val  = $val0*$args{serving_size}/100;
            my $valr = $code_round_energy->($val);
            $funcraw->{energy_from_fat_per_srv} = $val          if !$per_package_ing;
            $funcraw->{energy_from_fat_per_srv_rounded} = $valr if !$per_package_ing;
            $funcraw->{energy_from_fat_per_pkg} = $val          if  $per_package_ing;
            $funcraw->{energy_from_fat_per_pkg_rounded} = $valr if  $per_package_ing;
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
            } elsif ($output_format =~ /calculation/) {
                push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Energi dari lemak*')}];
                push @rows, [{align=>'right', text=>'Energi dari lemak per 100 g'},
                             {align=>'left', $attr=>"= lemak $M 9 = $args{fat} $M 9 = $val0 kkal"}];
                push @rows, [{align=>'right', text=>"Energi dari lemak per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                             {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val kkal"}];
                push @rows, [{align=>'right', text=>"(dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat)"},
                             {align=>'left', $attr=>$code_fmttext->("= *$valr* kkal")}];
            }
        }

      ENERGY_FROM_SATURATED_FAT: {
            my $val0 = $args{saturated_fat} * 9;
            my $val  = $val0*$args{$size_key}/100;
            my $valr = $code_round_energy->($val);
            $funcraw->{energy_from_saturated_fat_per_srv} = $val          if !$per_package_ing;
            $funcraw->{energy_from_saturated_fat_per_srv_rounded} = $valr if !$per_package_ing;
            $funcraw->{energy_from_saturated_fat_per_pkg} = $val          if  $per_package_ing;
            $funcraw->{energy_from_saturated_fat_per_pkg_rounded} = $valr if  $per_package_ing;
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
            } elsif ($output_format =~ /calculation/) {
                push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Energi dari lemak jenuh*')}];
                push @rows, [{align=>'right', text=>'Energi dari lemak per 100 g'},
                             {align=>'left', $attr=>"= lemak jenuh $M 9 = $args{saturated_fat} $M 9 = $val0 kkal"}];
                push @rows, [{align=>'right', text=>"Energi dari lemak jenuh per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                             {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val kkal"}];
                push @rows, [{align=>'right', text=>"(dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat)"},
                             {align=>'left', $attr=>$code_fmttext->("= *$valr* kkal")}];
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
            my ($val, $valr) = @_;
            if ($valr == 0)    { 0 }
            else               { _nearest(1  , $val) }
        };

        my $val0 = $args{fat};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_fat->($val);
        my $pct_dv = $val/67*100;
        my $pct_dv_R = $code_round_fat_pct_dv->($pct_dv, $valr);
        $funcraw->{total_fat_per_srv} = $val          if !$per_package_ing;
        $funcraw->{total_fat_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{total_fat_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{total_fat_per_pkg_rounded} = $valr if  $per_package_ing;
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Total fat',
                name_ind => 'Lemak total',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $pct_dv,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Lemak total*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Lemak total $valr g ($pct_dv_R% AKG)*, ");
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Lemak total*')}];
            push @rows, [{align=>'right', text=>'Lemak total per 100 g'},
                         {align=>'left', $attr=>"= $args{fat} g"}];
            push @rows, [{align=>'right', text=>"Lemak total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val g"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <0.5 -> 0, <=5 -> 0.5 g terdekat, >=5 -> 1 g terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* g")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG lemak total*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 67 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
        }

      SATURATED_FAT: {
            my $val0 = $args{saturated_fat};
            my $val  = $val0*$args{$size_key}/100;
            my $valr = $code_round_fat->($val);
            my $pct_dv = $val/20*100;
            my $pct_dv_R = $code_round_fat_pct_dv->($pct_dv, $valr);
            $funcraw->{saturated_fat_per_srv} = $val          if !$per_package_ing;
            $funcraw->{saturated_fat_per_srv_rounded} = $valr if !$per_package_ing;
            $funcraw->{saturated_fat_per_pkg} = $val          if  $per_package_ing;
            $funcraw->{saturated_fat_per_pkg_rounded} = $valr if  $per_package_ing;
            if ($output_format eq 'raw_table') {
                push @rows, {
                    name_eng => 'Saturated fat',
                    name_ind => 'Lemak jenuh',
                    val_per_100g  => $val0,
                    (val_per_srv   => $val,
                     val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                    (val_per_pkg   => $val,
                     val_per_pkg_R => $valr) x $per_package_ing,
                    pct_dv   => $pct_dv,
                    pct_dv_R => $pct_dv_R,
                };
            } elsif ($output_format =~ /vertical/) {
                push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Lemak jenuh*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
            } elsif ($output_format =~ /linear/) {
                push @rows, $code_fmttext->("*Lemak jenuh $valr g ($pct_dv_R% AKG)*, ");
            } elsif ($output_format =~ /calculation/) {
                push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Lemak jenuh*')}];
                push @rows, [{align=>'right', text=>'Lemak jenuh per 100 g'},
                             {align=>'left', $attr=>"= $args{saturated_fat} g"}];
                push @rows, [{align=>'right', text=>"Lemak jenuh per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                             {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val g"}];
                push @rows, [{align=>'right', text=>"(dibulatkan: <0.5 -> 0, <=5 -> 0.5 g terdekat, >=5 -> 1 g terdekat)"},
                             {align=>'left', $attr=>$code_fmttext->("= *$valr* g")}];
                push @rows, ['', ''];
                push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG lemak jenuh*')}];
                push @rows, [{align=>'right', text=>"\%AKG"},
                             {align=>'left', $attr=>"= $val / 67 $M 100 = $pct_dv"}];
                push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                             {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
            }
    } # FAT

  CHOLESTEROL: {
        my $code_round_cholesterol = sub {
            my $val = shift;
            if ($val <  2)    { 0 }
            if ($val <= 5)    { _nearest(1  , $val) }
            else              { _nearest(5  , $val) }
        };
        my $code_round_cholesterol_pct_dv = sub {
            my ($val, $valr) = @_;
            if   ($valr == 0)  { 0 }
            else               { _nearest(1  , $val) }
        };

        my $val0 = $args{cholesterol};
        last unless defined $val0;
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_cholesterol->($val);
        my $pct_dv = $val/300*100;
        my $pct_dv_R = $code_round_cholesterol_pct_dv->($pct_dv, $valr);
        $funcraw->{cholesterol_per_srv} = $val          if !$per_package_ing;
        $funcraw->{cholesterol_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{cholesterol_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{cholesterol_per_pkg_rounded} = $valr if  $per_package_ing;
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Cholesterol',
                name_ind => 'Kolesterol',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $pct_dv,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("Kolesterol")}, {align=>'right', $attr=>$code_fmttext->("$valr mg")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("Kolesterol $valr mg ($pct_dv_R% AKG), ");
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Kolesterol*')}];
            push @rows, [{align=>'right', text=>'Kolesterol per 100 g'},
                         {align=>'left', $attr=>"= $args{cholesterol} mg"}];
            push @rows, [{align=>'right', text=>"Kolesterol total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val mg"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <2 -> 0, 2-5 -> 1 mg terdekat, >5 -> 5 mg terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* mg")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG kolesterol*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 300 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
        }
    }

  PROTEIN: {
        my $code_round_protein = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            else               { _nearest(1  , $val) }
        };
        my $code_round_protein_pct_dv = sub {
            my ($val, $valr) = @_;
            if   ($valr == 0)  { 0 }
            else               { _nearest(1  , $val) }
        };

        my $val0 = $args{protein};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_protein->($val);
        my $pct_dv = $val/60*100;
        my $pct_dv_R = $code_round_protein_pct_dv->($pct_dv, $valr);
        $funcraw->{protein_per_srv} = $val          if !$per_package_ing;
        $funcraw->{protein_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{protein_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{protein_per_pkg_rounded} = $valr if  $per_package_ing;
        if ($output_format eq 'raw_table') {
            push @rows, {
                name_eng => 'Protein',
                name_ind => 'Protein',
                val_per_100g  => $val0,
                (val_per_srv   => $val,
                 val_per_srv_R => $valr) x ($per_package_ing ? 0:1),
                (val_per_pkg   => $val,
                 val_per_pkg_R => $valr) x $per_package_ing,
                pct_dv   => $pct_dv,
                pct_dv_R => $pct_dv_R,
            };
        } elsif ($output_format =~ /vertical/) {
            push @rows, [{colspan=>2, $attr=>$code_fmttext->("*Protein*")}, {align=>'right', $attr=>$code_fmttext->("*$valr g*")}, {align=>'right', $attr=>"$pct_dv_R %"}, ''];
        } elsif ($output_format =~ /linear/) {
            push @rows, $code_fmttext->("*Protein $valr g ($pct_dv_R% AKG)*, ");
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Protein*')}];
            push @rows, [{align=>'right', text=>'Protein per 100 g'},
                         {align=>'left', $attr=>"= $args{protein} g"}];
            push @rows, [{align=>'right', text=>"Protein total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val g"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* g")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG protein*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 60 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
        }
    }

  CARBOHYDRATE: {
        my $code_round_carbohydrate = sub {
            my $val = shift;
            if ($val < 0.5)    { 0 }
            else               { _nearest(1  , $val) }
        };
        my $code_round_carbohydrate_pct_dv = sub {
            my ($val, $valr) = @_;
            if ($valr == 0)    { 0 }
            else               { _nearest(1  , $val) }
        };

        my $val0 = $args{carbohydrate};
        my $val  = $val0*$args{$size_key}/100;
        my $valr = $code_round_carbohydrate->($val);
        my $pct_dv_R = $code_round_carbohydrate_pct_dv->($val/325*100, $valr);
        $funcraw->{carbohydrate_per_srv} = $val          if !$per_package_ing;
        $funcraw->{carbohydrate_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{carbohydrate_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{carbohydrate_per_pkg_rounded} = $valr if  $per_package_ing;
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
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Karbohidrat total*')}];
            push @rows, [{align=>'right', text=>'Karbohidrat total per 100 g'},
                         {align=>'left', $attr=>"= $args{carbohydrate} g"}];
            push @rows, [{align=>'right', text=>"Karbohidrat total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val g"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* g")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG karbohidrat total*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 325 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
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
        $funcraw->{total_sugar_per_srv} = $val          if !$per_package_ing;
        $funcraw->{total_sugar_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{total_sugar_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{total_sugar_per_pkg_rounded} = $valr if  $per_package_ing;
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
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Gula*')}];
            push @rows, [{align=>'right', text=>'Gula per 100 g'},
                         {align=>'left', $attr=>"= $args{sugar} g"}];
            push @rows, [{align=>'right', text=>"Gula per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val g"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* g")}];
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
        my $pct_dv = $val/1500*100;
        my $pct_dv_R = $code_round_sodium_pct_dv->($val/1500*100, $valr);
        $funcraw->{sodium_per_srv} = $val          if !$per_package_ing;
        $funcraw->{sodium_per_srv_rounded} = $valr if !$per_package_ing;
        $funcraw->{sodium_per_pkg} = $val          if  $per_package_ing;
        $funcraw->{sodium_per_pkg_rounded} = $valr if  $per_package_ing;
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
        } elsif ($output_format =~ /calculation/) {
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*Natrium*')}];
            push @rows, [{align=>'right', text=>'Natrium per 100 g'},
                         {align=>'left', $attr=>"= $args{sodium} mg"}];
            push @rows, [{align=>'right', text=>"Natrium per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                         {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val mg"}];
            push @rows, [{align=>'right', text=>"(dibulatkan: <5 -> 0, <=140 -> 5 mg terdekat, >140 -> 10 mg terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$valr* mg")}];
            push @rows, ['', ''];
            push @rows, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->('*%AKG natrium*')}];
            push @rows, [{align=>'right', text=>"\%AKG"},
                         {align=>'left', $attr=>"= $val / 1500 $M 100 = $pct_dv"}];
            push @rows, [{align=>'right', text=>"(dibulatkan ke % terdekat)"},
                         {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
        }
    }
    }

  VITAMIN_MINERAL_NONNUTRIENTS: {

        my @rows_vm;
      VITAMIN_MINERAL: {
            my $code_round_vitamin_mineral_pct_dv = sub {
                my ($val, $valr) = @_;
                if   ($val <= 10)  { _nearest(2, $val) }
                else               { _nearest(5, $val) }
            };

            my $do_vm = sub {
                my ($sym, $name_ind, $akg, $unit, $name_eng) = @_;

                my $val0 = $args{$sym};
                my $val0_nufact = $args{"${sym}_nufact"};
                my $nufact_note = $args{"${sym}_nufact_note"};

                if (defined $val0_nufact) {
                    if ($args{has_claims}) {
                        if ($val0 < $val0_nufact) {
                            die "$name_eng: In food with claims, value in lab test result ($val0) must be greater than or equal to value to be shown in nufacts";
                        }
                    } else {
                        if ($val0 < $val0_nufact * 0.8) {
                            die "$name_eng: In food without claims, value in lab test result ($val0) must at least be 80% of value to be shown in nufacts";
                        }
                    }
                    $val0 = $val0_nufact;
                }

                $name_eng //= $name_ind;
                my $val  = $val0*$args{$size_key}/100;
                my $pct_dv = $val/$akg *100;
                my $pct_dv_R = $code_round_vitamin_mineral_pct_dv->($pct_dv, $pct_dv);
                if ($pct_dv_R < 2) {
                    die "$name_eng value is below 2% AKG, can't show in nutrition facts\n";
                    return;
                }
                $funcraw->{"${sym}_pct_dv_per_srv"} = $pct_dv           if !$per_package_ing;
                $funcraw->{"${sym}_pct_dv_per_srv_rounded"} = $pct_dv_R if !$per_package_ing;
                $funcraw->{"${sym}_pct_dv_per_pkg"} = $pct_dv           if  $per_package_ing;
                $funcraw->{"${sym}_pct_dv_per_pkg_rounded"} = $pct_dv_R if  $per_package_ing;
                if ($output_format eq 'raw_table') {
                    push @rows_vm, {
                        name_eng => $name_eng,
                        name_ind => $name_ind,
                        val_per_100g  => $val0,
                        (val_per_srv   => $val) x (!$per_package_ing ? 1:0),
                        (val_per_pkg   => $val) x ( $per_package_ing ? 1:0),
                        pct_dv   => $pct_dv,
                        pct_dv_R => $pct_dv_R,
                    };
                } elsif ($output_format =~ /vertical/) {
                    push @rows_vm, [{}, {colspan=>2, $attr=>$code_fmttext->($name_ind)}, {colspan=>2, align=>'right', $attr=>$code_fmttext->("$pct_dv_R %")}];
                } elsif ($output_format =~ /linear/) {
                    push @rows_vm, $code_fmttext->("$name_ind ($pct_dv_R% AKG)");
                } elsif ($output_format =~ /calculation/) {
                    push @rows_vm, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->("*$name_ind*")}];
                    push @rows_vm, [{align=>'right', text=>"$name_ind per 100 g"},
                                     {align=>'left', $attr=>"= $val0 $unit"}];
                    push @rows_vm, [{align=>'right', text=>"$name_ind total per ".($per_package_ing ? "kemasan $args{package_size} g" : "takaran saji $args{serving_size} g")},
                                     {align=>'left', $attr=>"= $val0 $M $args{$size_key} / 100 = $val $unit"}];
                    push @rows_vm, ['', ''];
                    push @rows_vm, [{colspan=>2, align=>'middle', $attr=>$code_fmttext->("*%AKG $name_ind*")}];
                    push @rows_vm, [{align=>'right', text=>"\%AKG"},
                                    {align=>'left', $attr=>"= $val / $akg $M 100 = $pct_dv"}];
                    push @rows_vm, [{align=>'right', text=>"(dibulatkan [<=10% AKG -> 2% terdekat, >10% AKG -> 5% terdekat])"},
                                    {align=>'left', $attr=>$code_fmttext->("= *$pct_dv_R*")}];
                }
            }; # do_vm

            $do_vm->("va", "Vitamin A", 600, "mcg (all-trans-)retinol") if $args{va};
            $do_vm->("vd", "Vitamin D", 15, "mcg") if $args{vd};
            $do_vm->("ve", "Vitamin E", 15, "mg alpha-TE (tocopherol-equivalent)") if $args{ve};
            $do_vm->("vk", "Vitamin K", 60, "mcg") if $args{vk};
            $do_vm->("vb1", "Vitamin B1", 1.4, "mg") if $args{vb1};
            $do_vm->("vb2", "Vitamin B2", 1.6, "mg") if $args{vb2};
            $do_vm->("vb3", "Vitamin B3", 15, "mg") if $args{vb3};
            $do_vm->("vb5", "Vitamin B5", 5, "mg") if $args{vb5};
            $do_vm->("vb6", "Vitamin B6", 1.3, "mg") if $args{vb6};
            $do_vm->("folate", "Folat", 400, "mcg", "Folate") if $args{folate};
            $do_vm->("vb12", "Vitamin B12", 2.4, "mcg") if $args{vb12};
            $do_vm->("biotin", "Biotin", 30, "mcg") if $args{biotin};
            $do_vm->("choline", "Kolin", 450, "mg", "Choline") if $args{choline};
            $do_vm->("vc", "Vitamin C", 90, "mg") if $args{vc};
            $do_vm->("ca", "Kalsium", 1100, "mg", "Calcium") if $args{ca};
            $do_vm->("phosphorus", "Fosfor", 700, "mg", "Phosphorus") if $args{phosphorus};
            $do_vm->("mg", "Magnesium", 350, "mg") if $args{mg};
            $do_vm->("potassium", "Kalium", 4700, "mg", "Potassium") if $args{potassium};
            $do_vm->("mn", "Mangan", 2000, "mcg", "Manganese") if $args{mn};
            $do_vm->("cu", "Tembaga", 800, "mcg", "Copper") if $args{cu};
            $do_vm->("cr", "Kromium", 26, "mcg", "Chromium") if $args{cr};
            $do_vm->("fe", "Besi", 22, "mg", "Iron") if $args{fe};
            $do_vm->("iodium", "Iodium", 90, "mcg", "Iodium") if $args{iodium};
            $do_vm->("zn", "Seng", 13, "mg", "Zinc") if $args{zn};
            $do_vm->("se", "Selenium", 30, "mcg") if $args{se};
            $do_vm->("fluorine", "Fluor", 2.5, "mg", "Fluorine") if $args{fluorine};
        } # VITAMIN_MINERAL

        my @rows_nn;
      NONNUTRIENTS: {
            1;
        } # NONNUTRIENTS

        # add heading & border
        if (@rows_vm) {
            if ($output_format =~ /vertical/) {
                push @rows, [{colspan=>5, $attr=>$code_fmttext->("Vitamin dan mineral")}];
                unless (@rows_nn) {
                    for (@{ $rows_vm[-1] }) { $_->{bottom_border} = 1 }
                }
            }
        }
        if (@rows_nn) {
            if ($output_format =~ /vertical/) {
                push @rows, [{colspan=>5, $attr=>$code_fmttext->("Zat Nongizi")}];
                for (@{ $rows_nn[-1] }) { $_->{bottom_border} = 1 }
            }
        }

        if ($output_format =~ /linear/) {
            push @rows, join(", ", @rows_vm, @rows_nn), (@rows_vm || @rows_nn ? ". " : "");
        } else {
            push @rows, @rows_vm, @rows_nn;
        }

    } # VITAMIN_MINERAL_NONNUTRIENTS

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
            $table =~ s!<table>!<table class="$output_format"><colgroup><col style="width:16pt;"><col style="width:200pt;"><col style="width:48pt;"><col style="width:48pt;"><col style="width:36pt;"></colgroup>!;
            $text = "
<style>
  table.$output_format { border-collapse: collapse; border: solid 1pt black; }
  table.$output_format tr.has_bottom_border { border-bottom: solid 1pt black; }
</style>\n" . $table;
        } else {
            require Text::Table::More;
            $text = Text::Table::More::generate_table(rows => \@rows, color=>1, header_row=>0);
        }
    } elsif ($output_format =~ /linear/) {
        if ($output_format =~ /html/) {
            $text = "
<style>
  p.$output_format { border: solid 1pt black; }
</style>
<p class=\"$output_format\">" . join("", @rows). "</p>\n";
        } elsif ($output_format =~ /text/) {
            require Text::ANSI::Util;
            require Text::Table::More;
            my $ing = Text::ANSI::Util::ta_wrap(join("", @rows), $ENV{COLUMNS} // 80);
            $text = Text::Table::More::generate_table(rows => [[$ing]], header_row=>0);
        } else {
            # raw_linear
            $text = join("", @rows) . "\n";
        }
    } elsif ($output_format =~ /calculation/) {
        if ($output_format =~ /html/) {
            require Text::Table::HTML;
            my $table = Text::Table::HTML::table(rows => \@rows, header_row=>0);
            $table =~ s!<table>!<table class="$output_format">!;
            $text = "
<style>
  table.$output_format { font-size: smaller; border-collapse: collapse; border: solid 1pt black; }
  table.$output_format tr.has_bottom_border { border-bottom: solid 1pt black; }
</style>\n" . $table;
        } else {
            require Text::Table::More;
            $text = Text::Table::More::generate_table(rows => \@rows, color=>1, header_row=>0);
        }
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

    return [200, "OK", $text, {'func.raw' => $funcraw, 'cmdline.skip_format'=>1}];
}

1;
# ABSTRACT: Utilities related to BPOM nutrition facts

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::NutritionFacts - Utilities related to BPOM nutrition facts

=head1 VERSION

This document describes version 0.028 of App::BPOMUtils::NutritionFacts (from Perl distribution App-BPOMUtils-NutritionFacts), released on 2024-11-05.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes CLI utilities related to BPOM nutrition facts.

=over

=item * L<bpom-show-nutrition-facts>

=item * L<bpom-tampilkan-ing>

=back

=head1 FUNCTIONS


=head2 bpom_show_nutrition_facts

Usage:

 bpom_show_nutrition_facts(%args) -> [$status_code, $reason, $payload, \%result_meta]

Render BPOM-compliant nutrition fact table (ING - informasi nilai gizi) in various formats.

Examples:

=over

=item * An example, in linear text format (colorE<sol>emphasis is shown with markup):

 bpom_show_nutrition_facts(
   carbohydrate => 13.113,
   color => "never",
   fat => 0.223,
   output_format => "raw_linear",
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
   "*INFORMASI NILAI GIZI*   *JUMLAH PER KEMASAN (20 g)* : *Energi total 10 kkal*, Energi dari lemak 0 kkal, Energi dari lemak jenuh 0 kkal, *Lemak total 0 g (0% AKG)*, *Lemak jenuh 0 g (0% AKG)*, *Protein 0 g (0% AKG)*, *Karbohidrat total 3 g (1% AKG)*, *Gula 1 g*, *Garam (Natrium) 0 mg (0% AKG)*. /Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./\n",
   {
     "cmdline.skip_format" => 1,
     "func.raw" => {
       carbohydrate_per_pkg                      => 2.6226,
       carbohydrate_per_pkg_rounded              => 3,
       energy_from_fat_per_pkg                   => 3.51225,
       energy_from_fat_per_pkg_rounded           => 0,
       energy_from_saturated_fat_per_pkg         => 0.018,
       energy_from_saturated_fat_per_pkg_rounded => 0,
       per_package_ing                           => 1,
       protein_per_pkg                           => 0.198,
       protein_per_pkg_rounded                   => 0,
       saturated_fat_per_pkg                     => 0.002,
       saturated_fat_per_pkg_rounded             => 0,
       sodium_per_pkg                            => 0.0446,
       sodium_per_pkg_rounded                    => 0,
       total_energy_pct_dv                       => 0.543432558139535,
       total_energy_pct_dv_rounded               => 1,
       total_energy_per_pkg                      => 11.6838,
       total_energy_per_pkg_rounded              => 10,
       total_fat_per_pkg                         => 0.0446,
       total_fat_per_pkg_rounded                 => 0,
       total_sugar_per_pkg                       => 1.4346,
       total_sugar_per_pkg_rounded               => 1,
     },
   },
 ]

=item * An example, in raw_linear format (just like linear_text but with no border):

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
   ".---------------------------------------------------------------------------------.\n| *INFORMASI NILAI GIZI* *JUMLAH PER KEMASAN (20 g)* : *Energi total 10 kkal*,    |\n| Energi dari lemak 0 kkal, Energi dari lemak jenuh 0 kkal, *Lemak total 0 g (0%  |\n| AKG)*, *Lemak jenuh 0 g (0% AKG)*, *Protein 0 g (0% AKG)*, *Karbohidrat total 3 |\n| g (1% AKG)*, *Gula 1 g*, *Garam (Natrium) 0 mg (0% AKG)*. /Persen AKG           |\n| berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih     |\n| tinggi atau lebih rendah./                                                      |\n`---------------------------------------------------------------------------------'\n",
   {
     "cmdline.skip_format" => 1,
     "func.raw" => {
       carbohydrate_per_pkg                      => 2.6226,
       carbohydrate_per_pkg_rounded              => 3,
       energy_from_fat_per_pkg                   => 3.51225,
       energy_from_fat_per_pkg_rounded           => 0,
       energy_from_saturated_fat_per_pkg         => 0.018,
       energy_from_saturated_fat_per_pkg_rounded => 0,
       per_package_ing                           => 1,
       protein_per_pkg                           => 0.198,
       protein_per_pkg_rounded                   => 0,
       saturated_fat_per_pkg                     => 0.002,
       saturated_fat_per_pkg_rounded             => 0,
       sodium_per_pkg                            => 0.0446,
       sodium_per_pkg_rounded                    => 0,
       total_energy_pct_dv                       => 0.543432558139535,
       total_energy_pct_dv_rounded               => 1,
       total_energy_per_pkg                      => 11.6838,
       total_energy_per_pkg_rounded              => 10,
       total_fat_per_pkg                         => 0.0446,
       total_fat_per_pkg_rounded                 => 0,
       total_sugar_per_pkg                       => 1.4346,
       total_sugar_per_pkg_rounded               => 1,
     },
   },
 ]

=item * The same example in vertical HTML table format:

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
   "\n<style>\n  table.vertical_html_table { border-collapse: collapse; border: solid 1pt black; }\n  table.vertical_html_table tr.has_bottom_border { border-bottom: solid 1pt black; }\n</style>\n<table class=\"vertical_html_table\"><colgroup><col style=\"width:16pt;\"><col style=\"width:200pt;\"><col style=\"width:48pt;\"><col style=\"width:48pt;\"><col style=\"width:36pt;\"></colgroup>\n<tbody>\n<tr><td colspan=5 align=\"middle\"><b>INFORMASI NILAI GIZI</b></td></tr>\n<tr><td colspan=5></td></tr>\n<tr><td colspan=5 align=\"left\"><b>JUMLAH PER KEMASAN (20 g)</b></td></tr>\n<tr class=has_bottom_border><td colspan=5><b>Energi total 10 kkal</b></td></tr>\n<tr><td colspan=3></td><td colspan=2 align=\"middle\"><b>% AKG</b>*</td></tr>\n<tr><td colspan=2><b>Lemak total</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Lemak jenuh</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Protein</b></td><td align=\"right\"><b>0 g</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=2><b>Karbohidrat total</b></td><td align=\"right\"><b>3 g</b></td><td align=\"right\">1 %</td><td></td></tr>\n<tr><td colspan=2><b>Gula</b></td><td align=\"right\"><b>1 g</b></td><td></td><td></td></tr>\n<tr class=has_bottom_border><td colspan=2><b>Garam (Natrium)</b></td><td align=\"right\"><b>0 mg</b></td><td align=\"right\">0 %</td><td></td></tr>\n<tr><td colspan=5><i>*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah.</i></td></tr>\n</tbody>\n</table>\n",
   {
     "cmdline.skip_format" => 1,
     "func.raw" => {
       carbohydrate_per_pkg                      => 2.6226,
       carbohydrate_per_pkg_rounded              => 3,
       energy_from_fat_per_pkg                   => 3.51225,
       energy_from_fat_per_pkg_rounded           => 0,
       energy_from_saturated_fat_per_pkg         => 0.018,
       energy_from_saturated_fat_per_pkg_rounded => 0,
       per_package_ing                           => 1,
       protein_per_pkg                           => 0.198,
       protein_per_pkg_rounded                   => 0,
       saturated_fat_per_pkg                     => 0.002,
       saturated_fat_per_pkg_rounded             => 0,
       sodium_per_pkg                            => 0.0446,
       sodium_per_pkg_rounded                    => 0,
       total_energy_pct_dv                       => 0.543432558139535,
       total_energy_pct_dv_rounded               => 1,
       total_energy_per_pkg                      => 11.6838,
       total_energy_per_pkg_rounded              => 10,
       total_fat_per_pkg                         => 0.0446,
       total_fat_per_pkg_rounded                 => 0,
       total_sugar_per_pkg                       => 1.4346,
       total_sugar_per_pkg_rounded               => 1,
     },
   },
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
   ".---------------------------------------------------------------------------------------------------------------------.\n|                                               *INFORMASI NILAI GIZI*                                                |\n|                                                                                                                     |\n| *JUMLAH PER KEMASAN (20 g)*                                                                                         |\n| *Energi total 10 kkal*                                                                                              |\n+-----------------------|----------------------|-----------------------+----------------------|-----------------------+\n|                                                                      |                   *% AKG**                   |\n| *Lemak total*                                |                 *0 g* |                  0 % |                       |\n| *Lemak jenuh*                                |                 *0 g* |                  0 % |                       |\n| *Protein*                                    |                 *0 g* |                  0 % |                       |\n| *Karbohidrat total*                          |                 *3 g* |                  1 % |                       |\n| *Gula*                                       |                 *1 g* |                      |                       |\n| *Garam (Natrium)*                            |                *0 mg* |                  0 % |                       |\n+-----------------------|----------------------+-----------------------+----------------------+-----------------------+\n| /*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi Anda mungkin lebih tinggi atau lebih rendah./ |\n`---------------------------------------------------------------------------------------------------------------------'\n",
   {
     "cmdline.skip_format" => 1,
     "func.raw" => {
       carbohydrate_per_pkg                      => 2.6226,
       carbohydrate_per_pkg_rounded              => 3,
       energy_from_fat_per_pkg                   => 3.51225,
       energy_from_fat_per_pkg_rounded           => 0,
       energy_from_saturated_fat_per_pkg         => 0.018,
       energy_from_saturated_fat_per_pkg_rounded => 0,
       per_package_ing                           => 1,
       protein_per_pkg                           => 0.198,
       protein_per_pkg_rounded                   => 0,
       saturated_fat_per_pkg                     => 0.002,
       saturated_fat_per_pkg_rounded             => 0,
       sodium_per_pkg                            => 0.0446,
       sodium_per_pkg_rounded                    => 0,
       total_energy_pct_dv                       => 0.543432558139535,
       total_energy_pct_dv_rounded               => 1,
       total_energy_per_pkg                      => 11.6838,
       total_energy_per_pkg_rounded              => 10,
       total_fat_per_pkg                         => 0.0446,
       total_fat_per_pkg_rounded                 => 0,
       total_sugar_per_pkg                       => 1.4346,
       total_sugar_per_pkg_rounded               => 1,
     },
   },
 ]

=item * The same example, in calculation text format:

 bpom_show_nutrition_facts(
   carbohydrate => 13.113,
   color => "never",
   fat => 0.223,
   output_format => "calculation_text",
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
   ".-------------------------------------------------------------------------------------------------------------------------------------------------------------------------.\n|                                                                   *PERHITUNGAN INFORMASI NILAI GIZI*                                                                    |\n|                                                                             *Energi total*                                                                              |\n|                                                  Energi total per 100 g | = lemak \xD7 9 + protein \xD7 4 + karbohidrat \xD7 4 = 0.223 \xD7 9 + 0.99 \xD7 4 + 13.113 \xD7 4 = 58.419 kkal |\n|                                           Energi total per kemasan 20 g | = 58.419 \xD7 20 / 100 = 11.6838 kkal                                                            |\n| (dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat) | = *10* kkal                                                                                   |\n|                                                                         |                                                                                               |\n|                                                                           *%AKG energi total*                                                                           |\n|                                                                    %AKG | = 11.6838 / 2150 \xD7 100 = 0.543432558139535                                                    |\n|                                              (dibulatkan ke % terdekat) | = *1*                                                                                         |\n|                                                                           *Energi dari lemak*                                                                           |\n|                                             Energi dari lemak per 100 g | = lemak \xD7 9 = 0.223 \xD7 9 = 2.007 kkal                                                          |\n|                                      Energi dari lemak per kemasan 20 g | = 2.007 \xD7 20 / 100 = 3.51225 kkal                                                             |\n| (dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat) | = *0* kkal                                                                                    |\n|                                                                        *Energi dari lemak jenuh*                                                                        |\n|                                             Energi dari lemak per 100 g | = lemak jenuh \xD7 9 = 0.01 \xD7 9 = 0.09 kkal                                                      |\n|                                Energi dari lemak jenuh per kemasan 20 g | = 0.09 \xD7 20 / 100 = 0.018 kkal                                                                |\n| (dibulatkan: <5 -> 0, <=50 -> 5 kkal terdekat, >50 -> 10 kkal terdekat) | = *0* kkal                                                                                    |\n|                                                                              *Lemak total*                                                                              |\n|                                                   Lemak total per 100 g | = 0.223 g                                                                                     |\n|                                            Lemak total per kemasan 20 g | = 0.223 \xD7 20 / 100 = 0.0446 g                                                                 |\n|     (dibulatkan: <0.5 -> 0, <=5 -> 0.5 g terdekat, >=5 -> 1 g terdekat) | = *0* g                                                                                       |\n|                                                                         |                                                                                               |\n|                                                                           *%AKG lemak total*                                                                            |\n|                                                                    %AKG | = 0.0446 / 67 \xD7 100 = 0.0665671641791045                                                      |\n|                                              (dibulatkan ke % terdekat) | = *0*                                                                                         |\n|                                                                              *Lemak jenuh*                                                                              |\n|                                                   Lemak jenuh per 100 g | = 0.01 g                                                                                      |\n|                                            Lemak jenuh per kemasan 20 g | = 0.01 \xD7 20 / 100 = 0.002 g                                                                   |\n|     (dibulatkan: <0.5 -> 0, <=5 -> 0.5 g terdekat, >=5 -> 1 g terdekat) | = *0* g                                                                                       |\n|                                                                         |                                                                                               |\n|                                                                           *%AKG lemak jenuh*                                                                            |\n|                                                                    %AKG | = 0.002 / 67 \xD7 100 = 0.01                                                                     |\n|                                              (dibulatkan ke % terdekat) | = *0*                                                                                         |\n|                                                                                *Protein*                                                                                |\n|                                                       Protein per 100 g | = 0.99 g                                                                                      |\n|                                          Protein total per kemasan 20 g | = 0.99 \xD7 20 / 100 = 0.198 g                                                                   |\n|                          (dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat) | = *0* g                                                                                       |\n|                                                                         |                                                                                               |\n|                                                                             *%AKG protein*                                                                              |\n|                                                                    %AKG | = 0.198 / 60 \xD7 100 = 0.33                                                                     |\n|                                              (dibulatkan ke % terdekat) | = *0*                                                                                         |\n|                                                                           *Karbohidrat total*                                                                           |\n|                                             Karbohidrat total per 100 g | = 13.113 g                                                                                    |\n|                                      Karbohidrat total per kemasan 20 g | = 13.113 \xD7 20 / 100 = 2.6226 g                                                                |\n|                          (dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat) | = *3* g                                                                                       |\n|                                                                         |                                                                                               |\n|                                                                        *%AKG karbohidrat total*                                                                         |\n|                                                                    %AKG | = 2.6226 / 325 \xD7 100 = 0.0665671641791045                                                     |\n|                                              (dibulatkan ke % terdekat) | = *1*                                                                                         |\n|                                                                                 *Gula*                                                                                  |\n|                                                          Gula per 100 g | = 7.173 g                                                                                     |\n|                                                   Gula per kemasan 20 g | = 7.173 \xD7 20 / 100 = 1.4346 g                                                                 |\n|                          (dibulatkan: <0.5 -> 0, >=0.5 -> 1 g terdekat) | = *1* g                                                                                       |\n|                                                                                *Natrium*                                                                                |\n|                                                       Natrium per 100 g | = 0.223 mg                                                                                    |\n|                                                Natrium per kemasan 20 g | = 0.223 \xD7 20 / 100 = 0.0446 mg                                                                |\n|   (dibulatkan: <5 -> 0, <=140 -> 5 mg terdekat, >140 -> 10 mg terdekat) | = *0* mg                                                                                      |\n|                                                                         |                                                                                               |\n|                                                                             *%AKG natrium*                                                                              |\n|                                                                    %AKG | = 0.0446 / 1500 \xD7 100 = 0.00297333333333333                                                   |\n|                                              (dibulatkan ke % terdekat) | = *0*                                                                                         |\n`-------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------'\n",
   {
     "cmdline.skip_format" => 1,
     "func.raw" => {
       carbohydrate_per_pkg                      => 2.6226,
       carbohydrate_per_pkg_rounded              => 3,
       energy_from_fat_per_pkg                   => 3.51225,
       energy_from_fat_per_pkg_rounded           => 0,
       energy_from_saturated_fat_per_pkg         => 0.018,
       energy_from_saturated_fat_per_pkg_rounded => 0,
       per_package_ing                           => 1,
       protein_per_pkg                           => 0.198,
       protein_per_pkg_rounded                   => 0,
       saturated_fat_per_pkg                     => 0.002,
       saturated_fat_per_pkg_rounded             => 0,
       sodium_per_pkg                            => 0.0446,
       sodium_per_pkg_rounded                    => 0,
       total_energy_pct_dv                       => 0.543432558139535,
       total_energy_pct_dv_rounded               => 1,
       total_energy_per_pkg                      => 11.6838,
       total_energy_per_pkg_rounded              => 10,
       total_fat_per_pkg                         => 0.0446,
       total_fat_per_pkg_rounded                 => 0,
       total_sugar_per_pkg                       => 1.4346,
       total_sugar_per_pkg_rounded               => 1,
     },
   },
 ]

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<biotin> => I<ufloat>

Biotin, in mcgE<sol>100g.

=item * B<biotin_nufact> => I<ufloat>

Biotin, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<biotin_nufact_note> => I<str>

(No description)

=item * B<browser> => I<true>

View output HTML in browser instead of returning it.

=item * B<ca> => I<ufloat>

Calcium, in mgE<sol>100g.

=item * B<ca_nufact> => I<ufloat>

Calcium, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<ca_nufact_note> => I<str>

(No description)

=item * B<carbohydrate>* => I<ufloat>

Total carbohydrate, in gE<sol>100g.

=item * B<carbohydrate_nufact> => I<ufloat>

Total carbohydrate, in gE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<carbohydrate_nufact_note> => I<str>

(No description)

=item * B<cholesterol> => I<ufloat>

Cholesterol, in mgE<sol>100g.

=item * B<cholesterol_nufact> => I<ufloat>

Cholesterol, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<cholesterol_nufact_note> => I<str>

(No description)

=item * B<choline> => I<ufloat>

Choline, in mgE<sol>100g.

=item * B<choline_nufact> => I<ufloat>

Choline, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<choline_nufact_note> => I<str>

(No description)

=item * B<color> => I<str> (default: "auto")

(No description)

=item * B<cr> => I<ufloat>

Chromium, in mcgE<sol>100g.

=item * B<cr_nufact> => I<ufloat>

Chromium, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<cr_nufact_note> => I<str>

(No description)

=item * B<cu> => I<ufloat>

Copper, in mcgE<sol>100g.

=item * B<cu_nufact> => I<ufloat>

Copper, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<cu_nufact_note> => I<str>

(No description)

=item * B<fat>* => I<ufloat>

Total fat, in gE<sol>100g.

=item * B<fat_nufact> => I<ufloat>

Total fat, in gE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<fat_nufact_note> => I<str>

(No description)

=item * B<fe> => I<ufloat>

Iron, in mgE<sol>100g.

=item * B<fe_nufact> => I<ufloat>

Iron, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<fe_nufact_note> => I<str>

(No description)

=item * B<fluorine> => I<ufloat>

Fluorine, in mgE<sol>100g.

=item * B<fluorine_nufact> => I<ufloat>

Fluorine, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<fluorine_nufact_note> => I<str>

(No description)

=item * B<folate> => I<ufloat>

Folate (vitamin B9), in mcgE<sol>100g.

=item * B<folate_nufact> => I<ufloat>

Folate (vitamin B9), in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<folate_nufact_note> => I<str>

(No description)

=item * B<has_claims> => I<bool>

Whether food is registered as having claims.

=item * B<iodium> => I<ufloat>

Iodium, in mcgE<sol>100g.

=item * B<iodium_nufact> => I<ufloat>

Iodium, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<iodium_nufact_note> => I<str>

(No description)

=item * B<k> => I<ufloat>

Potassium, in mgE<sol>100g.

=item * B<k_nufact> => I<ufloat>

Potassium, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<k_nufact_note> => I<str>

(No description)

=item * B<mg> => I<ufloat>

Magnesium, in mgE<sol>100g.

=item * B<mg_nufact> => I<ufloat>

Magnesium, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<mg_nufact_note> => I<str>

(No description)

=item * B<mn> => I<ufloat>

Manganese, in mcgE<sol>100g.

=item * B<mn_nufact> => I<ufloat>

Manganese, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<mn_nufact_note> => I<str>

(No description)

=item * B<name> => I<str>

(No description)

=item * B<output_format> => I<str> (default: "vertical_text_table")

Pick an output format for the nutrition fact.

C<vertical_text_table> is the default. The /(vertical)?.*table/ formats presents
the information in a table, while the /linear/ formats presents the information
in a paragraph.

=item * B<package_size>* => I<ufloat>

Packaging size, in g.

=item * B<phosphorus> => I<ufloat>

Phosphorus, in mgE<sol>100g.

=item * B<phosphorus_nufact> => I<ufloat>

Phosphorus, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<phosphorus_nufact_note> => I<str>

(No description)

=item * B<protein>* => I<ufloat>

Protein, in gE<sol>100g.

=item * B<protein_nufact> => I<ufloat>

Protein, in gE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<protein_nufact_note> => I<str>

(No description)

=item * B<saturated_fat>* => I<ufloat>

Saturated fat, in gE<sol>100g.

=item * B<saturated_fat_nufact> => I<ufloat>

Saturated fat, in gE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<saturated_fat_nufact_note> => I<str>

(No description)

=item * B<se> => I<ufloat>

Selenium, in mcgE<sol>100g.

=item * B<se_nufact> => I<ufloat>

Selenium, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<se_nufact_note> => I<str>

(No description)

=item * B<serving_size>* => I<ufloat>

Serving size, in g.

=item * B<sodium>* => I<ufloat>

Sodium, in mgE<sol>100g.

=item * B<sodium_nufact> => I<ufloat>

Sodium, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<sodium_nufact_note> => I<str>

(No description)

=item * B<sugar>* => I<ufloat>

Total sugar, in gE<sol>100g.

=item * B<sugar_nufact> => I<ufloat>

Total sugar, in gE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<sugar_nufact_note> => I<str>

(No description)

=item * B<va> => I<ufloat>

Vitamin A, in mcgE<sol>100g (all-trans-)retinol.

=item * B<va_nufact> => I<ufloat>

Vitamin A, in mcgE<sol>100g (all-trans-)retinol (value to be used in nutrition facts table instead the lab test result).

=item * B<va_nufact_note> => I<str>

(No description)

=item * B<vb1> => I<ufloat>

Vitamin B1, in mgE<sol>100g.

=item * B<vb12> => I<ufloat>

Vitamin B12, in mcgE<sol>100g.

=item * B<vb12_nufact> => I<ufloat>

Vitamin B12, in mcgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb12_nufact_note> => I<str>

(No description)

=item * B<vb1_nufact> => I<ufloat>

Vitamin B1, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb1_nufact_note> => I<str>

(No description)

=item * B<vb2> => I<ufloat>

Vitamin B2, in mgE<sol>100g.

=item * B<vb2_nufact> => I<ufloat>

Vitamin B2, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb2_nufact_note> => I<str>

(No description)

=item * B<vb3> => I<ufloat>

Vitamin B3, in mgE<sol>100g.

=item * B<vb3_nufact> => I<ufloat>

Vitamin B3, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb3_nufact_note> => I<str>

(No description)

=item * B<vb5> => I<ufloat>

Vitamin B5 (pantothenic acid), in mgE<sol>100g.

=item * B<vb5_nufact> => I<ufloat>

Vitamin B5 (pantothenic acid), in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb5_nufact_note> => I<str>

(No description)

=item * B<vb6> => I<ufloat>

Vitamin B6, in mgE<sol>100g.

=item * B<vb6_nufact> => I<ufloat>

Vitamin B6, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vb6_nufact_note> => I<str>

(No description)

=item * B<vc> => I<ufloat>

Vitamin C, in mgE<sol>100g.

=item * B<vc_nufact> => I<ufloat>

Vitamin C, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<vc_nufact_note> => I<str>

(No description)

=item * B<vd> => I<ufloat>

Vitamin D, in mcg.

=item * B<vd_nufact> => I<ufloat>

Vitamin D, in mcg (value to be used in nutrition facts table instead the lab test result).

=item * B<vd_nufact_note> => I<str>

(No description)

=item * B<ve> => I<ufloat>

Vitamin E, in mg alpha-TE (tocopherol-equivalent).

=item * B<ve_nufact> => I<ufloat>

Vitamin E, in mg alpha-TE (tocopherol-equivalent) (value to be used in nutrition facts table instead the lab test result).

=item * B<ve_nufact_note> => I<str>

(No description)

=item * B<vk> => I<ufloat>

Vitamin K, in mcg.

=item * B<vk_nufact> => I<ufloat>

Vitamin K, in mcg (value to be used in nutrition facts table instead the lab test result).

=item * B<vk_nufact_note> => I<str>

(No description)

=item * B<zn> => I<ufloat>

Zinc, in mgE<sol>100g.

=item * B<zn_nufact> => I<ufloat>

Zinc, in mgE<sol>100g (value to be used in nutrition facts table instead the lab test result).

=item * B<zn_nufact_note> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-NutritionFacts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-NutritionFacts>.

=head1 SEE ALSO

L<https://pom.go.id>

Other C<App::BPOMUtils::*> distributions.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-NutritionFacts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
