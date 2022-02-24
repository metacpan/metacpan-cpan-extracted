package App::ModuleFeaturesUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Perinci::Sub::Args::Common::CLI qw(%argspec_detail);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-31'; # DATE
our $DIST = 'App-ModuleFeaturesUtils'; # DIST
our $VERSION = '0.006'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI Utilities related to Module::Features',
};

our %argspecreq0_feature_set = (
    feature_set_name => {
        schema => 'perl::modulefeatures::modname*',
        req => 1,
        pos => 0,
    },
);

our %argspecs_feature_set = (
    feature_set_name => {
        schema => 'perl::modulefeatures::modname*',
        pos => 0,
    },
    feature_set_data => {
        schema => 'hash*',
    },
);

our %argsrels_feature_set = (
    req_one => [qw/feature_set_name feature_set_data/],
);

our %argspecreq0_module = (
    module => {
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
    },
);

our %argspecs_features_decl = (
    module => {
        schema => 'perl::modname*',
        pos => 0,
    },
    features_decl_data => {
        schema => 'hash*',
    },
);

our %argsrels_features_decl = (
    req_one => [qw/module features_decl_data/],
);

our %argspec1_feature_name = (
    feature_name => {
        schema => 'str*', # XXX completion
        description => <<'_',

Can be unqualified:

    feature_name

or qualified with feature set name using the `::` or `/` separator:

    Feature::SetName::feature_name
    Feature/SetName/feature_name

_
        pos => 1,
    },
);

$SPEC{get_feature_set_spec} = {
    v => 1.1,
    summary => 'Get feature set specification',
    args => {
        %argspecreq0_feature_set,
    },
    examples => [
        {
            args => {feature_set_name => 'TextTable'},
        }
    ],
};
sub get_feature_set_spec {
    require Module::FeaturesUtil::Get;

    my %args = @_;
    [200, "OK", Module::FeaturesUtil::Get::get_feature_set_spec($args{feature_set}, 'load')];
}

$SPEC{get_features_decl} = {
    v => 1.1,
    summary => 'Get features declaration',
    args => {
        %argspecreq0_module,
    },
    examples => [
        {
            args => {module => 'Text::Table::Tiny'},
        }
    ],
};
sub get_features_decl {
    require Module::FeaturesUtil::Get;

    my %args = @_;
    [200, "OK", Module::FeaturesUtil::Get::get_features_decl($args{module}, 'load')];
}

$SPEC{list_feature_sets} = {
    v => 1.1,
    summary => 'List feature sets (in modules under Module::Features:: namespace)',
    args => {
        %argspec_detail,
    },
    examples => [
        {
            args => {},
        },
        {
            summary => 'Show detail',
            args => {},
        }
    ],
};
sub list_feature_sets {
    require Module::List::Tiny;

    my %args = @_;

    my $res = Module::List::Tiny::list_modules(
        "Module::Features::", {list_modules=>1, recurse=>1});

    my @rows;
    for my $mod (sort keys %$res) {
        (my $fsetname = $mod) =~ s/^Module::Features:://;
        if ($args{detail}) {
            (my $modpm = "$mod.pm") =~ s!::!/!g;
            require $modpm;

            my $spec = \%{"$mod\::FEATURES_DEF"};

            push @rows, {
                name => $fsetname,
                module => $mod,
                summary => $spec->{summary},
                num_features => (scalar keys %{$spec->{features}}),
            };
        } else {
            push @rows, $fsetname;
        }
    }
    [200, "OK", \@rows];
}

$SPEC{list_feature_set_features} = {
    v => 1.1,
    summary => 'List features in a feature set',
    args => {
        %argspecreq0_feature_set,
        %argspec_detail,
    },
};
sub list_feature_set_features {
    require Data::Sah::Util::Type;

    my %args = @_;

    my $mod = "Module::Features::$args{feature_set}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $spec = \%{"$mod\::FEATURES_DEF"};

    my @rows;
    for my $fname (sort keys %{ $spec->{features} }) {
        my $fspec = $spec->{features}{$fname};
        if ($args{detail}) {
            push @rows, {
                name    => $fname,
                summary => $fspec->{summary},
                req     => $fspec->{req} // 0,
                schema_type => Data::Sah::Util::Type::get_type($fspec->{schema} // 'bool'),
            };
        } else {
            push @rows, $fname;
        }
    }
    [200, "OK", \@rows];
}

$SPEC{check_feature_set_spec} = {
    v => 1.1,
    summary => 'Check specification in %FEATURES_DEF in Modules::Features::* module',
    args => {
        %argspecs_feature_set,
    },
    args_rels => {
        %argsrels_feature_set,
    },
    examples => [
        {
            summary => 'Check %FEATURES_DEF in Module::Features::TextTable',
            args => {feature_set_name => 'TextTable'},
        },
        {
            summary => 'Check feature set specification specified on the command line',
            src => q([[prog]] --feature-set-data-json '{"v":1, "summary":"Foo", "features":{"feature1":{}, "feature2":{"schema":"uint*","req":1}}}'),
            src_plang => 'bash',
        },
    ],
};
sub check_feature_set_spec {
    require Module::FeaturesUtil::Check;

    my %args = @_;

    my $spec;
    if (defined(my $name = $args{feature_set_name} // $args{feature_set})) {
        my $mod = "Module::Features::$name";
        (my $modpm = "$mod.pm") =~ s!::!/!g;
        require $modpm;

        $spec = \%{"$mod\::FEATURES_DEF"};
    } else {
        $spec = $args{feature_set_data};
    }

    Module::FeaturesUtil::Check::check_feature_set_spec($spec);
}

$SPEC{check_features_decl} = {
    v => 1.1,
    summary => 'Check %FEATURES in a module (or given in argument)',
    args => {
        %argspecs_features_decl,
    },
    args_rels => {
        %argsrels_features_decl,
    },
    examples => [
        {
            summary => 'Check feature declaration (%FEATURES) in a module',
            args => {module=>'Text::Table::Sprintf'},
        },
        {
            summary => 'Check feature declaration specified on the command line as JSON',
            src => q([[prog]] --features-decl-data-json '{"v":1, "features":{"TextTable": {"can_halign":0}}}'),
        },
    ],
};
sub check_features_decl {
    require Module::FeaturesUtil::Check;
    require Module::FeaturesUtil::Get;

    my %args = @_;

    my $decl;
    if (defined(my $mod = $args{module})) {
        $decl = Module::FeaturesUtil::Get::get_features_decl($mod, 'load');
    } else {
        $decl = $args{features_decl_data};
    }

    Module::FeaturesUtil::Check::check_features_decl($decl);
}

$SPEC{check_module_features} = {
    v => 1.1,
    summary => 'Check %FEATURES in a module and return the value of specified feature',
    args => {
        %argspecreq0_module,
        %argspec1_feature_name,
    },
    examples => [
        {
            summary => 'Check all features declared in a module',
            args => {module=>'Text::Table::Sprintf'},
        },
        {
            summary => 'Check a single feature declared in a module',
            args => {module=>'Text::Table::Sprintf', feature_name=>'speed'},
        },
    ],
};
sub check_module_features {
    require Module::FeaturesUtil::Check;
    require Module::FeaturesUtil::Get;

    my %args = @_;
    my $fname = $args{feature_name};
    my $mod = $args{module};

    my $features_decl = Module::FeaturesUtil::Get::get_features_decl($mod, 'load');;
    my $res = Module::FeaturesUtil::Check::check_features_decl($features_decl);
    return $res unless $res->[0] == 200;

    return [200, "No features"] unless $features_decl->{features};

    if (defined $fname) {
        my @fsetnames = sort keys %{ $features_decl->{features} };
        return [412, "There are no feature sets declared by $mod"]
            unless @fsetnames;

        my $fsetname;
        if ($fname =~ m!(.+)(/|::)(.+)!) {
            $fsetname = $1;
            $fname = $3;
            $fsetname =~ s!/!::!g;
        } else {
            return [400, "Please prefix feature name with feature set name (e.g. $fsetnames[0]/foo), there are more than one feature sets: ".join(", ", @fsetnames)]
                unless @fsetnames == 1;
            $fsetname = $fsetnames[0];
        }
        my $set_features = $features_decl->{features}{$fsetname}
            or return [404, "No such feature set name declared: $fsetname"];
        [200, "OK", $set_features->{$fname}];
    } else {
        [200, "OK", $features_decl->{features}];
    }
}

$SPEC{compare_module_features} = {
    v => 1.1,
    summary => 'Return a table data comparing features from several modules',
    args => {
        modules => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module',
            schema => ['array*', of=>'perl::modname*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    examples => [
        {
            summary => 'Compare features of two modules',
            args => {modules=>[qw/Text::ANSITable Text::Table::More/]},
        },
    ],
};
sub compare_module_features {
    require Module::FeaturesUtil::Get;

    my %args = @_;
    my $modules = $args{modules};
    my $fsetname = $args{feature_name};

    my %features_decls; # key = module name
    my %fsetspecs; # key = fsetname
    my @modules;
    my %fsetnames;
    my %seen_modules;
    for my $module (@$modules) {
        if ($seen_modules{$module}++) {
            log_error "Module $module is specified more than once, ignoring";
            next;
        } else {
            log_trace "Loading module %s ...", $module;
        }
        push @modules, $module;
        my $features_decl = Module::FeaturesUtil::Get::get_features_decl($module, 'load', 'fatal');
        #use DD; dd $features_decl;
        for my $fsetname (sort keys %{ $features_decl->{features} }) {
            unless ($fsetnames{$fsetname}++) {
                $fsetspecs{$fsetname} = Module::FeaturesUtil::Get::get_feature_set_spec($fsetname, 'load', 'fatal');
            }
        }
        $features_decls{$module} = $features_decl;
    }
    my @fsetnames = sort keys %fsetnames;
    log_trace "Feature set names: %s", \@fsetnames;

    my @rows;
    for my $fsetname (@fsetnames) {
        my $fset0 = $features_decls{ $modules[0] }{features}{ $fsetname };
        for my $fname (sort keys %$fset0) {
            push @rows, {
                # XXX what if a module is named this?
                feature_set => $fsetname,
                feature     => $fname,
            };
            for my $module (@modules) {
                my $fset = $features_decls{$module}{features}{ $fsetname };
                my $val0 = $fset->{$fname};
                my $val  = ref $val0 eq 'HASH' ? $val0->{value} : $val0;
                $rows[-1]{$module} = $val;
            }
        }
    }

    [200, "OK", \@rows, {'table.fields'=>[qw/feature_set feature/, @modules]}];
}

1;
# ABSTRACT: CLI Utilities related to Module::Features

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ModuleFeaturesUtils - CLI Utilities related to Module::Features

=head1 VERSION

This document describes version 0.006 of App::ModuleFeaturesUtils (from Perl distribution App-ModuleFeaturesUtils), released on 2021-08-31.

=head1 DESCRIPTION

This distribution includes the following utilities:

=over

=item * L<check-feature-set-spec>

=item * L<check-features-decl>

=item * L<check-module-features>

=item * L<compare-module-features>

=item * L<get-feature-set-spec>

=item * L<get-features-decl>

=item * L<list-feature-set-features>

=item * L<list-feature-sets>

=back

=head1 FUNCTIONS


=head2 check_feature_set_spec

Usage:

 check_feature_set_spec(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check specification in %FEATURES_DEF in Modules::Features::* module.

Examples:

=over

=item * Check %FEATURES_DEF in Module::Features::TextTable:

 check_feature_set_spec(feature_set_name => "TextTable"); # -> [200, "OK", undef, { "func.warnings" => [] }]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<feature_set_data> => I<hash>

=item * B<feature_set_name> => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_features_decl

Usage:

 check_features_decl(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check %FEATURES in a module (or given in argument).

Examples:

=over

=item * Check feature declaration (%FEATURES) in a module:

 check_features_decl(module => "Text::Table::Sprintf"); # -> [200, undef, undef, {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<features_decl_data> => I<hash>

=item * B<module> => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_module_features

Usage:

 check_module_features(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check %FEATURES in a module and return the value of specified feature.

Examples:

=over

=item * Check all features declared in a module:

 check_module_features(module => "Text::Table::Sprintf");

Result:

 [
   200,
   "OK",
   {
     TextTable => {
       can_align_cell_containing_color_code     => 0,
       can_align_cell_containing_newline        => 0,
       can_align_cell_containing_wide_character => 0,
       can_color                                => 0,
       can_color_theme                          => 0,
       can_colspan                              => 0,
       can_customize_border                     => 0,
       can_halign                               => 0,
       can_halign_individual_cell               => 0,
       can_halign_individual_column             => 0,
       can_halign_individual_row                => 0,
       can_hpad                                 => 0,
       can_hpad_individual_cell                 => 0,
       can_hpad_individual_column               => 0,
       can_hpad_individual_row                  => 0,
       can_rowspan                              => 0,
       can_set_cell_height                      => 0,
       can_set_cell_height_of_individual_row    => 0,
       can_set_cell_width                       => 0,
       can_set_cell_width_of_individual_column  => 0,
       can_use_box_character                    => 0,
       can_valign                               => 0,
       can_valign_individual_cell               => 0,
       can_valign_individual_column             => 0,
       can_valign_individual_row                => 0,
       can_vpad                                 => 0,
       can_vpad_individual_cell                 => 0,
       can_vpad_individual_column               => 0,
       can_vpad_individual_row                  => 0,
       speed                                    => "fast",
     },
   },
   {},
 ]

=item * Check a single feature declared in a module:

 check_module_features(module => "Text::Table::Sprintf", feature_name => "speed");

Result:

 [200, "OK", "fast", {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<feature_name> => I<str>

Can be unqualified:

 feature_name

or qualified with feature set name using the C<::> or C</> separator:

 Feature::SetName::feature_name
 Feature/SetName/feature_name

=item * B<module>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 compare_module_features

Usage:

 compare_module_features(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return a table data comparing features from several modules.

Examples:

=over

=item * Compare features of two modules:

 compare_module_features(modules => ["Text::ANSITable", "Text::Table::More"]);

Result:

 [
   200,
   "OK",
   [
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "Development Status",
       "Text::ANSITable"   => "5 - Production/Stable",
       "Text::Table::More" => "4 - Beta",
     },
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "Environment",
       "Text::ANSITable"   => "Console",
       "Text::Table::More" => "Console",
     },
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "Intended Audience",
       "Text::ANSITable"   => ["Developers"],
       "Text::Table::More" => ["Developers"],
     },
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "License",
       "Text::ANSITable"   => "OSI Approved :: Artistic License",
       "Text::Table::More" => "OSI Approved :: Artistic License",
     },
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "Programming Language",
       "Text::ANSITable"   => "Perl",
       "Text::Table::More" => "Perl",
     },
     {
       "feature_set"       => "PerlTrove",
       "feature"           => "Topic",
       "Text::ANSITable"   => [
                                "Software Development :: Libraries :: Perl Modules",
                                "Utilities",
                              ],
       "Text::Table::More" => [
                                "Software Development :: Libraries :: Perl Modules",
                                "Utilities",
                              ],
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_align_cell_containing_color_code",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_align_cell_containing_newline",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_align_cell_containing_wide_character",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_color",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_color_theme",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_colspan",
       "Text::ANSITable"   => 0,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_customize_border",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_halign",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_halign_individual_cell",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_halign_individual_column",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_halign_individual_row",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_hpad",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_hpad_individual_cell",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_hpad_individual_column",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_hpad_individual_row",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_rowspan",
       "Text::ANSITable"   => 0,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_set_cell_height",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_set_cell_height_of_individual_row",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_set_cell_width",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_set_cell_width_of_individual_column",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_use_box_character",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_valign",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_valign_individual_cell",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_valign_individual_column",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_valign_individual_row",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 1,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_vpad",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_vpad_individual_cell",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_vpad_individual_column",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "can_vpad_individual_row",
       "Text::ANSITable"   => 1,
       "Text::Table::More" => 0,
     },
     {
       "feature_set"       => "TextTable",
       "feature"           => "speed",
       "Text::ANSITable"   => "slow",
       "Text::Table::More" => "slow",
     },
   ],
   {
     "table.fields" => [
       "feature_set",
       "feature",
       "Text::ANSITable",
       "Text::Table::More",
     ],
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[perl::modname]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_feature_set_spec

Usage:

 get_feature_set_spec(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get feature set specification.

Examples:

=over

=item * Example #1:

 get_feature_set_spec(feature_set_name => "TextTable"); # -> [200, "OK", {}, {}]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<feature_set_name>* => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_features_decl

Usage:

 get_features_decl(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get features declaration.

Examples:

=over

=item * Example #1:

 get_features_decl(module => "Text::Table::Tiny");

Result:

 [
   200,
   "OK",
   {
     "features" => {
                     TextTable => {
                       can_align_cell_containing_color_code     => 1,
                       can_align_cell_containing_newline        => 0,
                       can_align_cell_containing_wide_character => 0,
                       can_color                                => 0,
                       can_color_theme                          => 0,
                       can_colspan                              => 0,
                       can_customize_border                     => 1,
                       can_halign                               => 1,
                       can_halign_individual_cell               => 0,
                       can_halign_individual_column             => 1,
                       can_halign_individual_row                => 0,
                       can_hpad                                 => 0,
                       can_hpad_individual_cell                 => 0,
                       can_hpad_individual_column               => 0,
                       can_hpad_individual_row                  => 0,
                       can_rowspan                              => 0,
                       can_set_cell_height                      => 0,
                       can_set_cell_height_of_individual_row    => 0,
                       can_set_cell_width                       => 0,
                       can_set_cell_width_of_individual_column  => 0,
                       can_use_box_character                    => 0,
                       can_valign                               => 0,
                       can_valign_individual_cell               => 0,
                       can_valign_individual_column             => 0,
                       can_valign_individual_row                => 0,
                       can_vpad                                 => 0,
                       can_vpad_individual_cell                 => 0,
                       can_vpad_individual_column               => 0,
                       can_vpad_individual_row                  => 0,
                       speed                                    => "medium",
                     },
                   },
     "module_v" => 1.02,
     "x.source" => "pm:Text::Table::Tiny::_ModuleFeatures",
   },
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_feature_set_features

Usage:

 list_feature_set_features(%args) -> [$status_code, $reason, $payload, \%result_meta]

List features in a feature set.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Return detailed record for each result item.

=item * B<feature_set_name>* => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_feature_sets

Usage:

 list_feature_sets(%args) -> [$status_code, $reason, $payload, \%result_meta]

List feature sets (in modules under Module::Features:: namespace).

Examples:

=over

=item * Example #1:

 list_feature_sets();

Result:

 [
   200,
   "OK",
   ["Dummy", "PerlTrove", "PythonTrove", "TextTable"],
   {},
 ]

=item * Show detail:

 list_feature_sets();

Result:

 [
   200,
   "OK",
   ["Dummy", "PerlTrove", "PythonTrove", "TextTable"],
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Return detailed record for each result item.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ModuleFeaturesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ModuleFeaturesUtils>.

=head1 SEE ALSO

L<Module::Features>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ModuleFeaturesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
