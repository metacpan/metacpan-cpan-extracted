package App::PerlCriticUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-02'; # DATE
our $DIST = 'App-PerlCriticUtils'; # DIST
our $VERSION = '0.007'; # VERSION

our %SPEC;

our %arg_policies = (
    policies => {
        schema => ['array*' => of=>'perl::modname*', min_len=>1],
        req    => 1,
        pos    => 0,
        greedy => 1,
        element_completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

our %arg_policy = (
    policy => {
        schema => 'perl::modname*',
        req    => 1,
        pos    => 0,
        completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

our %argopt_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

$SPEC{pcplist} = {
    v => 1.1,
    summary => 'List installed Perl::Critic policy modules',
    args => {
        %argopt_detail,
        query => {
            summary => "Filter by name",
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
            tags => ['category:filtering'],
        },
        default_severity => {
            schema => ['uint*'],
            tags => ['category:filtering'],
        },
        min_default_severity => {
            schema => ['uint*'],
            tags => ['category:filtering'],
        },
        max_default_severity => {
            schema => ['uint*'],
            tags => ['category:filtering'],
        },
    },
    examples => [
        {
            summary => 'List installed policies',
            argv => [],
            test => 0,
        },
        {
            summary => 'List installed policies (show details)',
            argv => ['-l'],
            test => 0,
        },
        {
            summary => "What's that policy that prohibits returning undef explicitly?",
            argv => ["undef"],
            test => 0,
        },
        {
            summary => "What's that policy that requires using strict?",
            argv => ["req", "strict"],
            test => 0,
        },

        {
            summary => "List policies which have default severity of 5",
            argv => ["--default-severity=5", "-l"],
            test => 0,
        },
        {
            summary => "List policies which have default severity between 4 and 5",
            argv => ["--min-default-severity=4", "--max-default-severity=5", "-l"],
            test => 0,
        },
    ],
};
sub pcplist {
    require PERLANCAR::Module::List;

    my %args = @_;
    my $query = $args{query} // [];

    my $mods = PERLANCAR::Module::List::list_modules(
        'Perl::Critic::Policy::', {list_modules=>1, recurse=>1});
    my @rows;
    my $resmeta = {};
  MOD:
    for my $mod (sort keys %$mods) {
        (my $name = $mod) =~ s/^Perl::Critic::Policy:://;

        my $row = {
            name => $name,
        };

        my $str;

        if ($args{detail} || @$query) {
            require Module::Abstract;
            $row->{abstract} = Module::Abstract::module_abstract($mod);
            $str = lc join(" ", $row->{name}, $row->{abstract});
        } else {
            $str = lc $name;
        }

        # filter by query
        if (@$query) {
            for my $q (@$query) {
                next MOD unless index($str, $q) >= 0;
            }
        }

        if ($args{detail} ||
            defined($args{default_severity}) ||
            defined($args{min_default_severity}) ||
            defined($args{max_default_severity})
        ) {
            (my $modpm = "$mod.pm") =~ s!::!/!g;
            require $modpm;
            $row->{default_severity} = $mod->default_severity;

            # filter by default_severity
            next MOD if defined $args{default_severity} && $row->{default_severity} != $args{default_severity};
            # filter by min_default_severity
            next MOD if defined $args{min_default_severity} && $row->{default_severity} < $args{min_default_severity};
            # filter by max_default_severity
            next MOD if defined $args{max_default_severity} && $row->{default_severity} > $args{max_default_severity};

            $row->{supported_parameters} = join(", ", map {$_->{name}} $mod->supported_parameters);
            $row->{default_themes} = join(", ", $mod->default_themes);
            $row->{applies_to} = $mod->applies_to;
        }

        push @rows, $args{detail} ? $row : $row->{name};
    }
    $resmeta->{'table.fields'} = [qw/name abstract/] if $args{detail};
    [200, "OK", \@rows, $resmeta];
}

$SPEC{pcpgrep} = {
    v => 1.1,
    summary => 'Grep from list of installed Perl::Critic policy module names (abstracts, ...)',
    description => <<'_',

I can never remember the names of the policies, hence this utility. It's a
convenience shortcut for:

    % pcplist | grep SOMETHING
    % pcplist -l | grep SOMETHING

Note that pcplist also can filter:

    % pcplist undef
    % pcplist req strict
_
    args => {
        query => {
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        ignore_case => {
            summary => 'Defaults to true for convenience',
            schema => 'bool*',
            default => 1,
        },
    },
    examples => [
        {
            summary => "What's that policy that prohibits returning undef explicitly?",
            argv => ["undef"],
            test => 0,
        },
        {
            summary => "What's that policy that requires using strict?",
            argv => ["req", "strict"],
            test => 0,
        },
    ],
};
sub pcpgrep {
    require PERLANCAR::Module::List;

    my %args = @_;
    my $query = $args{query} or return [400, "Please specify query"];
    my $ignore_case = $args{ignore_case} // 1;

    my $listres = pcplist(detail=>1);
    my $grepres = [$listres->[0], $listres->[1], [], $listres->[3]];

    for my $row (@{ $listres->[2] }) {
        my $str = join(" ", $row->{name}, $row->{abstract});
        my $match = 1;
        for my $q (@$query) {
            if ($ignore_case) {
                do { $match = 0; last } unless index(lc($str), lc($q)) >= 0;
            } else {
                do { $match = 0; last } unless index($str, $q) >= 0;
            }
        }
        next unless $match;
        push @{$grepres->[2]}, $row;
    }

    $grepres;
}

$SPEC{pcppath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl::Critic policy module',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
        },
    ],
};
sub pcppath {
    require Module::Path::More;
    my %args = @_;

    my $policies = $args{policies};
    my $res = [];
    my $found;

    for my $policy (@{$policies}) {
        my $mpath = Module::Path::More::module_path(
            module      => "Perl::Critic::Policy::$policy",
        );
        $found++ if $mpath;
        for (ref($mpath) eq 'ARRAY' ? @$mpath : ($mpath)) {
            push @$res, @$policies > 1 ? {policy=>$policy, path=>$_} : $_;
        }
    }

    if ($found) {
        [200, "OK", $res];
    } else {
        [404, "No such module"];
    }
}

$SPEC{pcpless} = {
    v => 1.1,
    summary => 'Show Perl::Critic policy module source code with `less`',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'less',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpless {
    require Module::Path::More;
    my %args = @_;
    my $policy = $args{policy};
    my $mpath = Module::Path::More::module_path(
        module => "Perl::Critic::Policy::$policy",
        find_pmc=>0, find_pod=>0, find_prefix=>0);
    if (defined $mpath) {
        system "less", $mpath;
        [200, "OK"];
    } else {
        [404, "Can't find policy $policy"];
    }
}

$SPEC{pcpcat} = {
    v => 1.1,
    summary => 'Print Perl::Critic policy module source code',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpcat {
    require Module::Path::More;

    my %args = @_;
    my $policies = $args{policies};
    return [400, "Please specify at least one policy"] unless @$policies;

    my $has_success;
    my $has_error;
    for my $policy (@$policies) {
        my $path = Module::Path::More::module_path(
            module=>"Perl::Critic::Policy::$policy", find_pod=>0) or do {
                warn "pcpcat: No such policy '$policy'\n";
                $has_error++;
                next;
            };
        open my $fh, "<", $path or do {
            warn "pcpcat: Can't open '$path': $!\n";
            $has_error++;
            next;
        };
        print while <$fh>;
        close $fh;
        $has_success++;
    }

    if ($has_error) {
        if ($has_success) {
            return [207, "Some policies failed"];
        } else {
            return [500, "All policies failed"];
        }
    } else {
        return [200, "All policies OK"];
    }
}

$SPEC{pcpdoc} = {
    v => 1.1,
    summary => 'Show documentation of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'perldoc',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpdoc {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("perldoc", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

$SPEC{pcpman} = {
    v => 1.1,
    summary => 'Show manpage of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'man',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpman {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("man", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

1;
# ABSTRACT: Command-line utilities related to Perl::Critic

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlCriticUtils - Command-line utilities related to Perl::Critic

=head1 VERSION

This document describes version 0.007 of App::PerlCriticUtils (from Perl distribution App-PerlCriticUtils), released on 2022-05-02.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
Perl::Critic:

=over

=item * L<pcpcat>

=item * L<pcpdoc>

=item * L<pcpgrep>

=item * L<pcpless>

=item * L<pcplist>

=item * L<pcpman>

=item * L<pcppath>

=back

=head1 FUNCTIONS


=head2 pcpcat

Usage:

 pcpcat(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print Perl::Critic policy module source code.

Examples:

=over

=item * Example #1:

 pcpcat(policies => ["Variables/ProhibitMatchVars"]);

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policies>* => I<array[perl::modname]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcpdoc

Usage:

 pcpdoc(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show documentation of Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcpdoc(policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcpgrep

Usage:

 pcpgrep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Grep from list of installed Perl::Critic policy module names (abstracts, ...).

Examples:

=over

=item * What's that policy that prohibits returning undef explicitly?:

 pcpgrep(query => ["undef"]);

Result:

 [
   200,
   "OK",
   [
     {
       name => "BuiltinFunctions::ProhibitSleepViaSelect",
       abstract => "Use L<Time::HiRes|Time::HiRes> instead of something like C<select(undef, undef, undef, .05)>.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, pbp, bugs",
     },
     {
       name => "InputOutput::ProhibitJoinedReadline",
       abstract => "Use C<local \$/ = undef> or L<Path::Tiny|Path::Tiny> instead of joined readline.",
       default_themes => "core, pbp, performance",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
     },
     {
       name => "Subroutines::ProhibitExplicitReturnUndef",
       abstract => "Return failure with bare C<return> instead of C<return undef>.",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
       default_themes => "core, pbp, bugs, certrec",
     },
   ],
   { "table.fields" => ["name", "abstract"] },
 ]

=item * What's that policy that requires using strict?:

 pcpgrep(query => ["req", "strict"]);

Result:

 [
   200,
   "OK",
   [
     {
       name => "TestingAndDebugging::RequireUseStrict",
       abstract => "Always C<use strict>.",
       supported_parameters => "equivalent_modules",
       default_severity => 5,
       applies_to => "PPI::Document",
       default_themes => "core, pbp, bugs, certrule, certrec",
     },
   ],
   { "table.fields" => ["name", "abstract"] },
 ]

=back

I can never remember the names of the policies, hence this utility. It's a
convenience shortcut for:

 % pcplist | grep SOMETHING
 % pcplist -l | grep SOMETHING

Note that pcplist also can filter:

 % pcplist undef
 % pcplist req strict

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ignore_case> => I<bool> (default: 1)

Defaults to true for convenience.

=item * B<query>* => I<array[str]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcpless

Usage:

 pcpless(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show Perl::Critic policy module source code with `less`.

Examples:

=over

=item * Example #1:

 pcpless(policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcplist

Usage:

 pcplist(%args) -> [$status_code, $reason, $payload, \%result_meta]

List installed Perl::Critic policy modules.

Examples:

=over

=item * List installed policies:

 pcplist();

Result:

 [
   200,
   "OK",
   [
     "BuiltinFunctions::GrepWithSimpleValue",
     "BuiltinFunctions::ProhibitBooleanGrep",
     "BuiltinFunctions::ProhibitComplexMappings",
     "BuiltinFunctions::ProhibitLvalueSubstr",
     "BuiltinFunctions::ProhibitReverseSortBlock",
     "BuiltinFunctions::ProhibitShiftRef",
     "BuiltinFunctions::ProhibitSleepViaSelect",
     "BuiltinFunctions::ProhibitStringyEval",
     "BuiltinFunctions::ProhibitStringySplit",
     "BuiltinFunctions::ProhibitUniversalCan",
     "BuiltinFunctions::ProhibitUniversalIsa",
     "BuiltinFunctions::ProhibitUselessTopic",
     "BuiltinFunctions::ProhibitVoidGrep",
     "BuiltinFunctions::ProhibitVoidMap",
     "BuiltinFunctions::RequireBlockGrep",
     "BuiltinFunctions::RequireBlockMap",
     "BuiltinFunctions::RequireGlobFunction",
     "BuiltinFunctions::RequireSimpleSortBlock",
     "ClassHierarchies::ProhibitAutoloading",
     "ClassHierarchies::ProhibitExplicitISA",
     "ClassHierarchies::ProhibitOneArgBless",
     "CodeLayout::ProhibitHardTabs",
     "CodeLayout::ProhibitParensWithBuiltins",
     "CodeLayout::ProhibitQuotedWordLists",
     "CodeLayout::ProhibitTrailingWhitespace",
     "CodeLayout::RequireConsistentNewlines",
     "CodeLayout::RequireTidyCode",
     "CodeLayout::RequireTrailingCommas",
     "ControlStructures::ProhibitCStyleForLoops",
     "ControlStructures::ProhibitCascadingIfElse",
     "ControlStructures::ProhibitDeepNests",
     "ControlStructures::ProhibitLabelsWithSpecialBlockNames",
     "ControlStructures::ProhibitMutatingListFunctions",
     "ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions",
     "ControlStructures::ProhibitPostfixControls",
     "ControlStructures::ProhibitUnlessBlocks",
     "ControlStructures::ProhibitUnreachableCode",
     "ControlStructures::ProhibitUntilBlocks",
     "ControlStructures::ProhibitYadaOperator",
     "Documentation::PodSpelling",
     "Documentation::RequirePackageMatchesPodName",
     "Documentation::RequirePodAtEnd",
     "Documentation::RequirePodSections",
     "ErrorHandling::RequireCarping",
     "ErrorHandling::RequireCheckingReturnValueOfEval",
     "InputOutput::ProhibitBacktickOperators",
     "InputOutput::ProhibitBarewordFileHandles",
     "InputOutput::ProhibitExplicitStdin",
     "InputOutput::ProhibitInteractiveTest",
     "InputOutput::ProhibitJoinedReadline",
     "InputOutput::ProhibitOneArgSelect",
     "InputOutput::ProhibitReadlineInForLoop",
     "InputOutput::ProhibitTwoArgOpen",
     "InputOutput::RequireBracedFileHandleWithPrint",
     "InputOutput::RequireBriefOpen",
     "InputOutput::RequireCheckedClose",
     "InputOutput::RequireCheckedOpen",
     "InputOutput::RequireCheckedSyscalls",
     "InputOutput::RequireEncodingWithUTF8Layer",
     "Miscellanea::ProhibitFormats",
     "Miscellanea::ProhibitTies",
     "Miscellanea::ProhibitUnrestrictedNoCritic",
     "Miscellanea::ProhibitUselessNoCritic",
     "Modules::ProhibitAutomaticExportation",
     "Modules::ProhibitConditionalUseStatements",
     "Modules::ProhibitEvilModules",
     "Modules::ProhibitExcessMainComplexity",
     "Modules::ProhibitMultiplePackages",
     "Modules::RequireBarewordIncludes",
     "Modules::RequireEndWithOne",
     "Modules::RequireExplicitPackage",
     "Modules::RequireFilenameMatchesPackage",
     "Modules::RequireNoMatchVarsWithUseEnglish",
     "Modules::RequireVersionVar",
     "NamingConventions::Capitalization",
     "NamingConventions::ProhibitAmbiguousNames",
     "Objects::ProhibitIndirectSyntax",
     "References::ProhibitDoubleSigils",
     "RegularExpressions::ProhibitCaptureWithoutTest",
     "RegularExpressions::ProhibitComplexRegexes",
     "RegularExpressions::ProhibitEnumeratedClasses",
     "RegularExpressions::ProhibitEscapedMetacharacters",
     "RegularExpressions::ProhibitFixedStringMatches",
     "RegularExpressions::ProhibitSingleCharAlternation",
     "RegularExpressions::ProhibitUnusedCapture",
     "RegularExpressions::ProhibitUnusualDelimiters",
     "RegularExpressions::ProhibitUselessTopic",
     "RegularExpressions::RequireBracesForMultiline",
     "RegularExpressions::RequireDotMatchAnything",
     "RegularExpressions::RequireExtendedFormatting",
     "RegularExpressions::RequireLineBoundaryMatching",
     "Subroutines::ProhibitAmpersandSigils",
     "Subroutines::ProhibitBuiltinHomonyms",
     "Subroutines::ProhibitExcessComplexity",
     "Subroutines::ProhibitExplicitReturnUndef",
     "Subroutines::ProhibitManyArgs",
     "Subroutines::ProhibitNestedSubs",
     "Subroutines::ProhibitReturnSort",
     "Subroutines::ProhibitSubroutinePrototypes",
     "Subroutines::ProhibitUnusedPrivateSubroutines",
     "Subroutines::ProtectPrivateSubs",
     "Subroutines::RequireArgUnpacking",
     "Subroutines::RequireFinalReturn",
     "TestingAndDebugging::ProhibitNoStrict",
     "TestingAndDebugging::ProhibitNoWarnings",
     "TestingAndDebugging::ProhibitProlongedStrictureOverride",
     "TestingAndDebugging::RequireTestLabels",
     "TestingAndDebugging::RequireUseStrict",
     "TestingAndDebugging::RequireUseWarnings",
     "ValuesAndExpressions::ProhibitCommaSeparatedStatements",
     "ValuesAndExpressions::ProhibitComplexVersion",
     "ValuesAndExpressions::ProhibitConstantPragma",
     "ValuesAndExpressions::ProhibitEmptyQuotes",
     "ValuesAndExpressions::ProhibitEscapedCharacters",
     "ValuesAndExpressions::ProhibitImplicitNewlines",
     "ValuesAndExpressions::ProhibitInterpolationOfLiterals",
     "ValuesAndExpressions::ProhibitLeadingZeros",
     "ValuesAndExpressions::ProhibitLongChainsOfMethodCalls",
     "ValuesAndExpressions::ProhibitMagicNumbers",
     "ValuesAndExpressions::ProhibitMismatchedOperators",
     "ValuesAndExpressions::ProhibitMixedBooleanOperators",
     "ValuesAndExpressions::ProhibitNoisyQuotes",
     "ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters",
     "ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator",
     "ValuesAndExpressions::ProhibitVersionStrings",
     "ValuesAndExpressions::RequireConstantVersion",
     "ValuesAndExpressions::RequireInterpolationOfMetachars",
     "ValuesAndExpressions::RequireNumberSeparators",
     "ValuesAndExpressions::RequireQuotedHeredocTerminator",
     "ValuesAndExpressions::RequireUpperCaseHeredocTerminator",
     "Variables::ProhibitAugmentedAssignmentInDeclaration",
     "Variables::ProhibitConditionalDeclarations",
     "Variables::ProhibitEvilVariables",
     "Variables::ProhibitFatCommaInDeclaration",
     "Variables::ProhibitLocalVars",
     "Variables::ProhibitMatchVars",
     "Variables::ProhibitPackageVars",
     "Variables::ProhibitPerl4PackageNames",
     "Variables::ProhibitPunctuationVars",
     "Variables::ProhibitReusedNames",
     "Variables::ProhibitUnusedVariables",
     "Variables::ProtectPrivateVars",
     "Variables::RequireInitializationForLocalVars",
     "Variables::RequireLexicalLoopIterators",
     "Variables::RequireLocalizedPunctuationVars",
     "Variables::RequireNegativeIndices",
   ],
   {},
 ]

=item * List installed policies (show details):

 pcplist(detail => 1);

Result:

 [
   200,
   "OK",
   [
     {
       name => "BuiltinFunctions::GrepWithSimpleValue",
       abstract => "Warn grep with simple value",
       default_themes => "core, bugs",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
     },
     {
       name => "BuiltinFunctions::ProhibitBooleanGrep",
       abstract => "Use C<List::MoreUtils::any> instead of C<grep> in boolean context.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 2,
       default_themes => "core, pbp, performance, certrec",
     },
     {
       name => "BuiltinFunctions::ProhibitComplexMappings",
       abstract => "Map blocks should have a single statement.",
       default_themes => "core, pbp, maintenance, complexity",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
       supported_parameters => "max_statements",
     },
     {
       name => "BuiltinFunctions::ProhibitLvalueSubstr",
       abstract => "Use 4-argument C<substr> instead of writing C<substr(\$foo, 2, 6) = \$bar>.",
       default_themes => "core, maintenance, pbp",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
     },
     {
       name => "BuiltinFunctions::ProhibitReverseSortBlock",
       abstract => "Forbid \$b before \$a in sort blocks.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 1,
     },
     {
       name => "BuiltinFunctions::ProhibitShiftRef",
       abstract => "Prohibit C<\\shift> in code",
       default_themes => "core, bugs, tests",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
     },
     {
       name => "BuiltinFunctions::ProhibitSleepViaSelect",
       abstract => "Use L<Time::HiRes|Time::HiRes> instead of something like C<select(undef, undef, undef, .05)>.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, pbp, bugs",
     },
     {
       name => "BuiltinFunctions::ProhibitStringyEval",
       abstract => "Write C<eval { my \$foo; bar(\$foo) }> instead of C<eval \"my \$foo; bar(\$foo);\">.",
       supported_parameters => "allow_includes",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       default_themes => "core, pbp, bugs, certrule",
     },
     {
       name => "BuiltinFunctions::ProhibitStringySplit",
       abstract => "Write C<split /-/, \$string> instead of C<split '-', \$string>.",
       default_themes => "core, pbp, cosmetic, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 2,
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::ProhibitUniversalCan",
       abstract => "Write C<< eval { \$foo->can(\$name) } >> instead of C<UNIVERSAL::can(\$foo, \$name)>.",
       default_themes => "core, maintenance, certrule",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
     },
     {
       name => "BuiltinFunctions::ProhibitUniversalIsa",
       abstract => "Write C<< eval { \$foo->isa(\$pkg) } >> instead of C<UNIVERSAL::isa(\$foo, \$pkg)>.",
       default_themes => "core, maintenance, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::ProhibitUselessTopic",
       abstract => "Don't pass \$_ to built-in functions that assume it, or to most filetest operators.",
       default_themes => "core",
       default_severity => 2,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::ProhibitVoidGrep",
       abstract => "Don't use C<grep> in void contexts.",
       default_themes => "core, maintenance",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::ProhibitVoidMap",
       abstract => "Don't use C<map> in void contexts.",
       default_themes => "core, maintenance",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::RequireBlockGrep",
       abstract => "Write C<grep { /\$pattern/ } \@list> instead of C<grep /\$pattern/, \@list>.",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
       default_themes => "core, bugs, pbp",
     },
     {
       name => "BuiltinFunctions::RequireBlockMap",
       abstract => "Write C<map { /\$pattern/ } \@list> instead of C<map /\$pattern/, \@list>.",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, bugs, pbp",
     },
     {
       name => "BuiltinFunctions::RequireGlobFunction",
       abstract => "Use C<glob q{*}> instead of <*>.",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Token::QuoteLike::Readline",
       default_themes => "core, pbp, bugs",
     },
     {
       name => "BuiltinFunctions::RequireSimpleSortBlock",
       abstract => "Sort blocks should have a single statement.",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "",
       default_themes => "core, pbp, maintenance, complexity",
     },
     {
       name => "ClassHierarchies::ProhibitAutoloading",
       abstract => "AUTOLOAD methods should be avoided.",
       default_themes => "core, maintenance, pbp",
       supported_parameters => "",
       applies_to => "PPI::Statement::Sub",
       default_severity => 3,
     },
     {
       name => "ClassHierarchies::ProhibitExplicitISA",
       abstract => "Employ C<use base> instead of C<\@ISA>.",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Token::Symbol",
       default_themes => "core, maintenance, pbp, certrec",
     },
     {
       name => "ClassHierarchies::ProhibitOneArgBless",
       abstract => "Write C<bless {}, \$class;> instead of just C<bless {};>.",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
       default_themes => "core, pbp, bugs",
     },
     {
       name => "CodeLayout::ProhibitHardTabs",
       abstract => "Use spaces instead of tabs.",
       default_severity => 3,
       applies_to => "PPI::Token",
       supported_parameters => "allow_leading_tabs",
       default_themes => "core, cosmetic, pbp",
     },
     {
       name => "CodeLayout::ProhibitParensWithBuiltins",
       abstract => "Write C<open \$handle, \$path> instead of C<open(\$handle, \$path)>.",
       supported_parameters => "",
       default_severity => 1,
       applies_to => "PPI::Token::Word",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "CodeLayout::ProhibitQuotedWordLists",
       abstract => "Write C<qw(foo bar baz)> instead of C<('foo', 'bar', 'baz')>.",
       default_themes => "core, cosmetic",
       supported_parameters => "min_elements, strict",
       default_severity => 2,
       applies_to => "PPI::Structure::List",
     },
     {
       name => "CodeLayout::ProhibitTrailingWhitespace",
       abstract => "Don't use whitespace at the end of lines.",
       default_severity => 1,
       applies_to => "PPI::Token::Whitespace",
       supported_parameters => "",
       default_themes => "core, maintenance",
     },
     {
       name => "CodeLayout::RequireConsistentNewlines",
       abstract => "Use the same newline through the source.",
       default_themes => "core, bugs",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Document",
     },
     {
       name => "CodeLayout::RequireTidyCode",
       abstract => "Must run code through L<perltidy|perltidy>.",
       supported_parameters => "perltidyrc",
       applies_to => "PPI::Document",
       default_severity => 1,
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "CodeLayout::RequireTrailingCommas",
       abstract => "Put a comma at the end of every multi-line list declaration, including the last one.",
       supported_parameters => "",
       default_severity => 1,
       applies_to => "PPI::Structure::List",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ControlStructures::ProhibitCStyleForLoops",
       abstract => "Write C<for(0..20)> instead of C<for(\$i=0; \$i<=20; \$i++)>.",
       applies_to => "PPI::Structure::For",
       default_severity => 2,
       supported_parameters => "",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "ControlStructures::ProhibitCascadingIfElse",
       abstract => "Don't write long \"if-elsif-elsif-elsif-elsif...else\" chains.",
       default_themes => "core, pbp, maintenance, complexity",
       supported_parameters => "max_elsif",
       applies_to => "PPI::Statement::Compound",
       default_severity => 3,
     },
     {
       name => "ControlStructures::ProhibitDeepNests",
       abstract => "Don't write deeply nested loops and conditionals.",
       default_severity => 3,
       applies_to => "PPI::Statement::Compound",
       supported_parameters => "max_nests",
       default_themes => "core, maintenance, complexity",
     },
     {
       name => "ControlStructures::ProhibitLabelsWithSpecialBlockNames",
       abstract => "Don't use labels that are the same as the special block names.",
       default_themes => "core, bugs",
       applies_to => "PPI::Token::Label",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "ControlStructures::ProhibitMutatingListFunctions",
       abstract => "Don't modify C<\$_> in list functions.",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "list_funcs, add_list_funcs",
       default_themes => "core, bugs, pbp, certrule",
     },
     {
       name => "ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions",
       abstract => "Don't use operators like C<not>, C<!~>, and C<le> within C<until> and C<unless>.",
       default_themes => "core, maintenance, pbp",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "ControlStructures::ProhibitPostfixControls",
       abstract => "Write C<if(\$condition){ do_something() }> instead of C<do_something() if \$condition>.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Token::Word",
       default_severity => 2,
       supported_parameters => "allow, flowcontrol",
     },
     {
       name => "ControlStructures::ProhibitUnlessBlocks",
       abstract => "Write C<if(! \$condition)> instead of C<unless(\$condition)>.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Statement::Compound",
       default_severity => 2,
       supported_parameters => "",
     },
     {
       name => "ControlStructures::ProhibitUnreachableCode",
       abstract => "Don't write code after an unconditional C<die, exit, or next>.",
       default_themes => "core, bugs, certrec",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "ControlStructures::ProhibitUntilBlocks",
       abstract => "Write C<while(! \$condition)> instead of C<until(\$condition)>.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Statement",
       default_severity => 2,
       supported_parameters => "",
     },
     {
       name => "ControlStructures::ProhibitYadaOperator",
       abstract => "Never use C<...> in production code.",
       default_themes => "core, pbp, maintenance",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Token::Operator",
     },
     {
       name => "Documentation::PodSpelling",
       abstract => "Check your spelling.",
       default_themes => "core, cosmetic, pbp",
       applies_to => "PPI::Document",
       default_severity => 1,
       supported_parameters => "spell_command, stop_words, stop_words_file",
     },
     {
       name => "Documentation::RequirePackageMatchesPodName",
       abstract => "The C<=head1 NAME> section should match the package.",
       default_themes => "core, cosmetic",
       default_severity => 1,
       applies_to => "PPI::Document",
       supported_parameters => "",
     },
     {
       name => "Documentation::RequirePodAtEnd",
       abstract => "All POD should be after C<__END__>.",
       applies_to => "PPI::Document",
       default_severity => 1,
       supported_parameters => "",
       default_themes => "core, cosmetic, pbp",
     },
     {
       name => "Documentation::RequirePodSections",
       abstract => "Organize your POD into the customary sections.",
       default_themes => "core, pbp, maintenance",
       default_severity => 2,
       applies_to => "PPI::Document",
       supported_parameters => "lib_sections, script_sections, source, language",
     },
     {
       name => "ErrorHandling::RequireCarping",
       abstract => "Use functions from L<Carp|Carp> instead of C<warn> or C<die>.",
       default_themes => "core, pbp, maintenance, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "allow_messages_ending_with_newlines, allow_in_main_unless_in_subroutine",
     },
     {
       name => "ErrorHandling::RequireCheckingReturnValueOfEval",
       abstract => "You can't depend upon the value of C<\$\@>/C<\$EVAL_ERROR> to tell whether an C<eval> failed.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       default_themes => "core, bugs",
     },
     {
       name => "InputOutput::ProhibitBacktickOperators",
       abstract => "Discourage stuff like C<\@files = `ls \$directory`>.",
       default_themes => "core, maintenance",
       default_severity => 3,
       applies_to => "PPI::Token::QuoteLike::Command",
       supported_parameters => "only_in_void_context",
     },
     {
       name => "InputOutput::ProhibitBarewordFileHandles",
       abstract => "Write C<open my \$fh, q{<}, \$filename;> instead of C<open FH, q{<}, \$filename;>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "InputOutput::ProhibitExplicitStdin",
       abstract => "Use \"<>\" or \"<ARGV>\" or a prompting module instead of \"<STDIN>\".",
       default_themes => "core, pbp, maintenance",
       default_severity => 4,
       applies_to => "PPI::Token::QuoteLike::Readline",
       supported_parameters => "",
     },
     {
       name => "InputOutput::ProhibitInteractiveTest",
       abstract => "Use prompt() instead of -t.",
       default_themes => "core, pbp, bugs, certrule",
       default_severity => 5,
       applies_to => "PPI::Token::Operator",
       supported_parameters => "",
     },
     {
       name => "InputOutput::ProhibitJoinedReadline",
       abstract => "Use C<local \$/ = undef> or L<Path::Tiny|Path::Tiny> instead of joined readline.",
       default_themes => "core, pbp, performance",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "InputOutput::ProhibitOneArgSelect",
       abstract => "Never write C<select(\$fh)>.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
       default_themes => "core, bugs, pbp, certrule",
     },
     {
       name => "InputOutput::ProhibitReadlineInForLoop",
       abstract => "Write C<< while( \$line = <> ){...} >> instead of C<< for(<>){...} >>.",
       default_themes => "core, bugs, pbp",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Statement::Compound",
     },
     {
       name => "InputOutput::ProhibitTwoArgOpen",
       abstract => "Write C<< open \$fh, q{<}, \$filename; >> instead of C<< open \$fh, \"<\$filename\"; >>.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       default_themes => "core, pbp, bugs, security, certrule",
     },
     {
       name => "InputOutput::RequireBracedFileHandleWithPrint",
       abstract => "Write C<print {\$FH} \$foo, \$bar;> instead of C<print \$FH \$foo, \$bar;>.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "",
       default_severity => 1,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "InputOutput::RequireBriefOpen",
       abstract => "Close filehandles as soon as possible after opening them.",
       default_themes => "core, pbp, maintenance",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
       supported_parameters => "lines",
     },
     {
       name => "InputOutput::RequireCheckedClose",
       abstract => "Write C<< my \$error = close \$fh; >> instead of C<< close \$fh; >>.",
       supported_parameters => "autodie_modules",
       default_severity => 2,
       applies_to => "PPI::Token::Word",
       default_themes => "core, maintenance, certrule",
     },
     {
       name => "InputOutput::RequireCheckedOpen",
       abstract => "Write C<< my \$error = open \$fh, \$mode, \$filename; >> instead of C<< open \$fh, \$mode, \$filename; >>.",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
       supported_parameters => "autodie_modules",
       default_themes => "core, maintenance, certrule",
     },
     {
       name => "InputOutput::RequireCheckedSyscalls",
       abstract => "Return value of flagged function ignored.",
       default_themes => "core, maintenance, certrule",
       supported_parameters => "functions, exclude_functions, autodie_modules",
       applies_to => "PPI::Token::Word",
       default_severity => 1,
     },
     {
       name => "InputOutput::RequireEncodingWithUTF8Layer",
       abstract => "Write C<< open \$fh, q{<:encoding(UTF-8)}, \$filename; >> instead of C<< open \$fh, q{<:utf8}, \$filename; >>.",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       default_themes => "core, bugs, security",
     },
     {
       name => "Miscellanea::ProhibitFormats",
       abstract => "Do not use C<format>.",
       default_themes => "core, maintenance, pbp, certrule",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "Miscellanea::ProhibitTies",
       abstract => "Do not use C<tie>.",
       default_themes => "core, pbp, maintenance",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 2,
     },
     {
       name => "Miscellanea::ProhibitUnrestrictedNoCritic",
       abstract => "Forbid a bare C<## no critic>",
       default_themes => "core, maintenance",
       default_severity => 3,
       applies_to => "PPI::Document",
       supported_parameters => "",
     },
     {
       name => "Miscellanea::ProhibitUselessNoCritic",
       abstract => "Remove ineffective \"## no critic\" annotations.",
       default_severity => 2,
       applies_to => "PPI::Document",
       supported_parameters => "",
       default_themes => "core, maintenance",
     },
     {
       name => "Modules::ProhibitAutomaticExportation",
       abstract => "Export symbols via C<\@EXPORT_OK> or C<%EXPORT_TAGS> instead of C<\@EXPORT>.",
       default_themes => "core, bugs",
       applies_to => "PPI::Document",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "Modules::ProhibitConditionalUseStatements",
       abstract => "Avoid putting conditional logic around compile-time includes.",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Statement::Include",
       default_themes => "core, bugs",
     },
     {
       name => "Modules::ProhibitEvilModules",
       abstract => "Ban modules that aren't blessed by your shop.",
       default_themes => "core, bugs, certrule",
       applies_to => "PPI::Statement::Include",
       default_severity => 5,
       supported_parameters => "modules, modules_file",
     },
     {
       name => "Modules::ProhibitExcessMainComplexity",
       abstract => "Minimize complexity in code that is B<outside> of subroutines.",
       default_themes => "core, complexity, maintenance",
       default_severity => 3,
       applies_to => "PPI::Document",
       supported_parameters => "max_mccabe",
     },
     {
       name => "Modules::ProhibitMultiplePackages",
       abstract => "Put packages (especially subclasses) in separate files.",
       default_themes => "core, bugs",
       default_severity => 4,
       applies_to => "PPI::Document",
       supported_parameters => "",
     },
     {
       name => "Modules::RequireBarewordIncludes",
       abstract => "Write C<require Module> instead of C<require 'Module.pm'>.",
       default_themes => "core, portability",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
     },
     {
       name => "Modules::RequireEndWithOne",
       abstract => "End each module with an explicitly C<1;> instead of some funky expression.",
       default_severity => 4,
       applies_to => "PPI::Document",
       supported_parameters => "",
       default_themes => "core, bugs, pbp, certrule",
     },
     {
       name => "Modules::RequireExplicitPackage",
       abstract => "Always make the C<package> explicit.",
       default_themes => "core, bugs",
       supported_parameters => "exempt_scripts, allow_import_of",
       default_severity => 4,
       applies_to => "PPI::Document",
     },
     {
       name => "Modules::RequireFilenameMatchesPackage",
       abstract => "Package declaration must match filename.",
       default_severity => 5,
       applies_to => "PPI::Document",
       supported_parameters => "",
       default_themes => "core, bugs",
     },
     {
       name => "Modules::RequireNoMatchVarsWithUseEnglish",
       abstract => "C<use English> must be passed a C<-no_match_vars> argument.",
       default_themes => "core, performance",
       supported_parameters => "",
       default_severity => 2,
       applies_to => "PPI::Statement::Include",
     },
     {
       name => "Modules::RequireVersionVar",
       abstract => "Give every module a C<\$VERSION> number.",
       supported_parameters => "",
       applies_to => "PPI::Document",
       default_severity => 2,
       default_themes => "core, pbp, readability",
     },
     {
       name => "NamingConventions::Capitalization",
       abstract => "Distinguish different program components by case.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "packages, package_exemptions, subroutines, subroutine_exemptions, local_lexical_variables, local_lexical_variable_exemptions, scoped_lexical_variables, scoped_lexical_variable_exemptions, file_lexical_variables, file_lexical_variable_exemptions, global_variables, global_variable_exemptions, constants, constant_exemptions, labels, label_exemptions",
       applies_to => "PPI::Token::Label",
       default_severity => 1,
     },
     {
       name => "NamingConventions::ProhibitAmbiguousNames",
       abstract => "Don't use vague variable or subroutine names like 'last' or 'record'.",
       default_themes => "core, pbp, maintenance",
       supported_parameters => "forbid",
       default_severity => 3,
       applies_to => "PPI::Statement::Variable",
     },
     {
       name => "Objects::ProhibitIndirectSyntax",
       abstract => "Prohibit indirect object call syntax.",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
       supported_parameters => "forbid",
       default_themes => "core, pbp, maintenance, certrule",
     },
     {
       name => "References::ProhibitDoubleSigils",
       abstract => "Write C<\@{ \$array_ref }> instead of C<\@\$array_ref>.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "",
       default_severity => 2,
       applies_to => "PPI::Token::Cast",
     },
     {
       name => "RegularExpressions::ProhibitCaptureWithoutTest",
       abstract => "Capture variable used outside conditional.",
       default_severity => 3,
       applies_to => "PPI::Token::Magic",
       supported_parameters => "exception_source",
       default_themes => "core, pbp, maintenance, certrule",
     },
     {
       name => "RegularExpressions::ProhibitComplexRegexes",
       abstract => "Split long regexps into smaller C<qr//> chunks.",
       default_themes => "core, pbp, maintenance",
       default_severity => 3,
       applies_to => "PPI::Token::QuoteLike::Regexp",
       supported_parameters => "max_characters",
     },
     {
       name => "RegularExpressions::ProhibitEnumeratedClasses",
       abstract => "Use named character classes instead of explicit character lists.",
       default_themes => "core, pbp, cosmetic, unicode",
       supported_parameters => "",
       default_severity => 1,
       applies_to => "PPI::Token::QuoteLike::Regexp",
     },
     {
       name => "RegularExpressions::ProhibitEscapedMetacharacters",
       abstract => "Use character classes for literal meta-characters instead of escapes.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Token::QuoteLike::Regexp",
       default_severity => 1,
       supported_parameters => "",
     },
     {
       name => "RegularExpressions::ProhibitFixedStringMatches",
       abstract => "Use C<eq> or hash instead of fixed-pattern regexps.",
       default_themes => "core, pbp, performance",
       supported_parameters => "",
       default_severity => 2,
       applies_to => "PPI::Token::QuoteLike::Regexp",
     },
     {
       name => "RegularExpressions::ProhibitSingleCharAlternation",
       abstract => "Use C<[abc]> instead of C<a|b|c>.",
       default_severity => 1,
       applies_to => "PPI::Token::QuoteLike::Regexp",
       supported_parameters => "",
       default_themes => "core, pbp, performance",
     },
     {
       name => "RegularExpressions::ProhibitUnusedCapture",
       abstract => "Only use a capturing group if you plan to use the captured value.",
       default_themes => "core, pbp, maintenance",
       applies_to => "PPI::Token::Regexp::Substitute",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "RegularExpressions::ProhibitUnusualDelimiters",
       abstract => "Use only C<//> or C<{}> to delimit regexps.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "allow_all_brackets",
       applies_to => "PPI::Token::QuoteLike::Regexp",
       default_severity => 1,
     },
     {
       name => "RegularExpressions::ProhibitUselessTopic",
       abstract => "Don't use \$_ to match against regexes.",
       default_themes => "core",
       supported_parameters => "",
       applies_to => "PPI::Token::Magic",
       default_severity => 2,
     },
     {
       name => "RegularExpressions::RequireBracesForMultiline",
       abstract => "Use C<{> and C<}> to delimit multi-line regexps.",
       default_themes => "core, pbp, cosmetic",
       supported_parameters => "allow_all_brackets",
       applies_to => "PPI::Token::QuoteLike::Regexp",
       default_severity => 1,
     },
     {
       name => "RegularExpressions::RequireDotMatchAnything",
       abstract => "Always use the C</s> modifier with regular expressions.",
       default_severity => 2,
       applies_to => "PPI::Token::QuoteLike::Regexp",
       supported_parameters => "",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "RegularExpressions::RequireExtendedFormatting",
       abstract => "Always use the C</x> modifier with regular expressions.",
       applies_to => "PPI::Token::QuoteLike::Regexp",
       default_severity => 3,
       supported_parameters => "minimum_regex_length_to_complain_about, strict",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "RegularExpressions::RequireLineBoundaryMatching",
       abstract => "Always use the C</m> modifier with regular expressions.",
       applies_to => "PPI::Token::QuoteLike::Regexp",
       default_severity => 2,
       supported_parameters => "",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "Subroutines::ProhibitAmpersandSigils",
       abstract => "Don't call functions with a leading ampersand sigil.",
       supported_parameters => "",
       default_severity => 2,
       applies_to => "PPI::Token::Symbol",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "Subroutines::ProhibitBuiltinHomonyms",
       abstract => "Don't declare your own C<open> function.",
       default_themes => "core, bugs, pbp, certrule",
       applies_to => "PPI::Statement::Sub",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "Subroutines::ProhibitExcessComplexity",
       abstract => "Minimize complexity by factoring code into smaller subroutines.",
       applies_to => "PPI::Statement::Sub",
       default_severity => 3,
       supported_parameters => "max_mccabe",
       default_themes => "core, complexity, maintenance",
     },
     {
       name => "Subroutines::ProhibitExplicitReturnUndef",
       abstract => "Return failure with bare C<return> instead of C<return undef>.",
       default_themes => "core, pbp, bugs, certrec",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "Subroutines::ProhibitManyArgs",
       abstract => "Too many arguments.",
       default_themes => "core, pbp, maintenance",
       supported_parameters => "max_arguments, skip_object",
       applies_to => "PPI::Statement::Sub",
       default_severity => 3,
     },
     {
       name => "Subroutines::ProhibitNestedSubs",
       abstract => "C<sub never { sub correct {} }>.",
       default_themes => "core, bugs",
       applies_to => "PPI::Statement::Sub",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "Subroutines::ProhibitReturnSort",
       abstract => "Behavior of C<sort> is not defined if called in scalar context.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, bugs, certrule",
     },
     {
       name => "Subroutines::ProhibitSubroutinePrototypes",
       abstract => "Don't write C<sub my_function (\@\@) {}>.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 5,
       applies_to => "PPI::Statement::Sub",
       supported_parameters => "",
     },
     {
       name => "Subroutines::ProhibitUnusedPrivateSubroutines",
       abstract => "Prevent unused private subroutines.",
       default_themes => "core, maintenance, certrec",
       supported_parameters => "private_name_regex, allow, skip_when_using, allow_name_regex",
       applies_to => "PPI::Statement::Sub",
       default_severity => 3,
     },
     {
       name => "Subroutines::ProtectPrivateSubs",
       abstract => "Prevent access to private subs in other packages.",
       applies_to => "PPI::Token::Word",
       default_severity => 3,
       supported_parameters => "private_name_regex, allow",
       default_themes => "core, maintenance, certrule",
     },
     {
       name => "Subroutines::RequireArgUnpacking",
       abstract => "Always unpack C<\@_> first.",
       supported_parameters => "short_subroutine_statements, allow_subscripts, allow_delegation_to",
       applies_to => "PPI::Statement::Sub",
       default_severity => 4,
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "Subroutines::RequireFinalReturn",
       abstract => "End every path through a subroutine with an explicit C<return> statement.",
       default_themes => "core, bugs, pbp, certrec",
       default_severity => 4,
       applies_to => "PPI::Statement::Sub",
       supported_parameters => "terminal_funcs, terminal_methods",
     },
     {
       name => "TestingAndDebugging::ProhibitNoStrict",
       abstract => "Prohibit various flavors of C<no strict>.",
       applies_to => "PPI::Statement::Include",
       default_severity => 5,
       supported_parameters => "allow",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "TestingAndDebugging::ProhibitNoWarnings",
       abstract => "Prohibit various flavors of C<no warnings>.",
       default_themes => "core, bugs, pbp, certrec",
       supported_parameters => "allow, allow_with_category_restriction",
       default_severity => 4,
       applies_to => "PPI::Statement::Include",
     },
     {
       name => "TestingAndDebugging::ProhibitProlongedStrictureOverride",
       abstract => "Don't turn off strict for large blocks of code.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "statements",
       applies_to => "PPI::Statement::Include",
       default_severity => 4,
     },
     {
       name => "TestingAndDebugging::RequireTestLabels",
       abstract => "Tests should all have labels.",
       default_severity => 3,
       applies_to => "PPI::Token::Word",
       supported_parameters => "modules",
       default_themes => "core, maintenance, tests",
     },
     {
       name => "TestingAndDebugging::RequireUseStrict",
       abstract => "Always C<use strict>.",
       applies_to => "PPI::Document",
       default_severity => 5,
       supported_parameters => "equivalent_modules",
       default_themes => "core, pbp, bugs, certrule, certrec",
     },
     {
       name => "TestingAndDebugging::RequireUseWarnings",
       abstract => "Always C<use warnings>.",
       default_themes => "core, pbp, bugs, certrule",
       supported_parameters => "equivalent_modules",
       applies_to => "PPI::Document",
       default_severity => 4,
     },
     {
       name => "ValuesAndExpressions::ProhibitCommaSeparatedStatements",
       abstract => "Don't use the comma operator as a statement separator.",
       default_themes => "core, bugs, pbp, certrule",
       applies_to => "PPI::Statement",
       default_severity => 4,
       supported_parameters => "allow_last_statement_to_be_comma_separated_in_map_and_grep",
     },
     {
       name => "ValuesAndExpressions::ProhibitComplexVersion",
       abstract => "Prohibit version values from outside the module.",
       default_severity => 3,
       applies_to => "PPI::Token::Symbol",
       supported_parameters => "forbid_use_version",
       default_themes => "core, maintenance",
     },
     {
       name => "ValuesAndExpressions::ProhibitConstantPragma",
       abstract => "Don't C<< use constant FOO => 15 >>.",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Statement::Include",
       default_themes => "core, bugs, pbp",
     },
     {
       name => "ValuesAndExpressions::ProhibitEmptyQuotes",
       abstract => "Write C<q{}> instead of C<''>.",
       supported_parameters => "",
       applies_to => "PPI::Token::Quote",
       default_severity => 2,
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::ProhibitEscapedCharacters",
       abstract => "Write C<\"\\N{DELETE}\"> instead of C<\"\\x7F\">, etc.",
       applies_to => "PPI::Token::Quote::Interpolate",
       default_severity => 2,
       supported_parameters => "",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::ProhibitImplicitNewlines",
       abstract => "Use concatenation or HEREDOCs instead of literal line breaks in strings.",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Token::Quote",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::ProhibitInterpolationOfLiterals",
       abstract => "Always use single quotes for literal strings.",
       default_severity => 1,
       applies_to => "PPI::Token::Quote::Interpolate",
       supported_parameters => "allow, allow_if_string_contains_single_quote",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::ProhibitLeadingZeros",
       abstract => "Write C<oct(755)> instead of C<0755>.",
       supported_parameters => "strict",
       applies_to => "PPI::Token::Number::Octal",
       default_severity => 5,
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "ValuesAndExpressions::ProhibitLongChainsOfMethodCalls",
       abstract => "Long chains of method calls indicate tightly coupled code.",
       default_severity => 2,
       applies_to => "PPI::Statement",
       supported_parameters => "max_chain_length",
       default_themes => "core, maintenance",
     },
     {
       name => "ValuesAndExpressions::ProhibitMagicNumbers",
       abstract => "Don't use values that don't explain themselves.",
       default_themes => "core, maintenance, certrec",
       supported_parameters => "allowed_values, allowed_types, allow_to_the_right_of_a_fat_comma, constant_creator_subroutines",
       default_severity => 2,
       applies_to => "PPI::Token::Number",
     },
     {
       name => "ValuesAndExpressions::ProhibitMismatchedOperators",
       abstract => "Don't mix numeric operators with string operands, or vice-versa.",
       default_themes => "core, bugs, certrule",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Token::Operator",
     },
     {
       name => "ValuesAndExpressions::ProhibitMixedBooleanOperators",
       abstract => "Write C< !\$foo && \$bar || \$baz > instead of C< not \$foo && \$bar or \$baz>.",
       applies_to => "PPI::Statement",
       default_severity => 4,
       supported_parameters => "",
       default_themes => "core, bugs, pbp, certrec",
     },
     {
       name => "ValuesAndExpressions::ProhibitNoisyQuotes",
       abstract => "Use C<q{}> or C<qq{}> instead of quotes for awkward-looking strings.",
       default_themes => "core, pbp, cosmetic",
       default_severity => 2,
       applies_to => "PPI::Token::Quote::Single",
       supported_parameters => "",
     },
     {
       name => "ValuesAndExpressions::ProhibitQuotesAsQuotelikeOperatorDelimiters",
       abstract => "Don't use quotes (C<'>, C<\">, C<`>) as delimiters for the quote-like operators.",
       default_themes => "core, maintenance",
       supported_parameters => "single_quote_allowed_operators, double_quote_allowed_operators, back_quote_allowed_operators",
       applies_to => "PPI::Token::Regexp::Transliterate",
       default_severity => 3,
     },
     {
       name => "ValuesAndExpressions::ProhibitSpecialLiteralHeredocTerminator",
       abstract => "Don't write C< print <<'__END__' >.",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Token::HereDoc",
       default_themes => "core, maintenance",
     },
     {
       name => "ValuesAndExpressions::ProhibitVersionStrings",
       abstract => "Don't use strings like C<v1.4> or C<1.4.5> when including other modules.",
       default_themes => "core, pbp, maintenance",
       applies_to => "PPI::Statement::Include",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "ValuesAndExpressions::RequireConstantVersion",
       abstract => "Require \$VERSION to be a constant rather than a computed value.",
       default_themes => "core, maintenance",
       applies_to => "PPI::Token::Symbol",
       default_severity => 2,
       supported_parameters => "allow_version_without_use_on_same_line",
     },
     {
       name => "ValuesAndExpressions::RequireInterpolationOfMetachars",
       abstract => "Warns that you might have used single quotes when you really wanted double-quotes.",
       supported_parameters => "rcs_keywords",
       default_severity => 1,
       applies_to => "PPI::Token::Quote::Literal",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::RequireNumberSeparators",
       abstract => "Write C< 141_234_397.0145 > instead of C< 141234397.0145 >.",
       supported_parameters => "min_value",
       default_severity => 2,
       applies_to => "PPI::Token::Number",
       default_themes => "core, pbp, cosmetic",
     },
     {
       name => "ValuesAndExpressions::RequireQuotedHeredocTerminator",
       abstract => "Write C< print <<'THE_END' > or C< print <<\"THE_END\" >.",
       default_severity => 3,
       applies_to => "PPI::Token::HereDoc",
       supported_parameters => "",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "ValuesAndExpressions::RequireUpperCaseHeredocTerminator",
       abstract => "Write C< <<'THE_END'; > instead of C< <<'theEnd'; >.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Token::HereDoc",
       default_severity => 2,
       supported_parameters => "",
     },
     {
       name => "Variables::ProhibitAugmentedAssignmentInDeclaration",
       abstract => "Do not write C< my \$foo .= 'bar'; >.",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Statement::Variable",
       default_themes => "core, bugs",
     },
     {
       name => "Variables::ProhibitConditionalDeclarations",
       abstract => "Do not write C< my \$foo = \$bar if \$baz; >.",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Variable",
       default_themes => "core, bugs",
     },
     {
       name => "Variables::ProhibitEvilVariables",
       abstract => "Ban variables that aren't blessed by your shop.",
       supported_parameters => "variables, variables_file",
       default_severity => 5,
       applies_to => "PPI::Token::Symbol",
       default_themes => "core, bugs",
     },
     {
       name => "Variables::ProhibitFatCommaInDeclaration",
       abstract => "Prohibit fat comma in declaration",
       applies_to => "PPI::Statement::Variable",
       default_severity => 4,
       supported_parameters => "",
       default_themes => "core, bugs",
     },
     {
       name => "Variables::ProhibitLocalVars",
       abstract => "Use C<my> instead of C<local>, except when you have to.",
       supported_parameters => "",
       applies_to => "PPI::Statement::Variable",
       default_severity => 2,
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "Variables::ProhibitMatchVars",
       abstract => "Avoid C<\$`>, C<\$&>, C<\$'> and their English equivalents.",
       supported_parameters => "",
       applies_to => "PPI::Statement::Include",
       default_severity => 4,
       default_themes => "core, performance, pbp",
     },
     {
       name => "Variables::ProhibitPackageVars",
       abstract => "Eliminate globals declared with C<our> or C<use vars>.",
       applies_to => "PPI::Statement::Include",
       default_severity => 3,
       supported_parameters => "packages, add_packages",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "Variables::ProhibitPerl4PackageNames",
       abstract => "Use double colon (::) to separate package name components instead of single quotes (').",
       default_themes => "core, maintenance, certrec",
       applies_to => "PPI::Token::Symbol",
       default_severity => 2,
       supported_parameters => "",
     },
     {
       name => "Variables::ProhibitPunctuationVars",
       abstract => "Write C<\$EVAL_ERROR> instead of C<\$\@>.",
       default_themes => "core, pbp, cosmetic",
       applies_to => "PPI::Token::HereDoc",
       default_severity => 2,
       supported_parameters => "allow, string_mode",
     },
     {
       name => "Variables::ProhibitReusedNames",
       abstract => "Do not reuse a variable name in a lexical scope",
       supported_parameters => "allow",
       default_severity => 3,
       applies_to => "PPI::Statement::Variable",
       default_themes => "core, bugs",
     },
     {
       name => "Variables::ProhibitUnusedVariables",
       abstract => "Don't ask for storage you don't need.",
       default_themes => "core, maintenance, certrec",
       applies_to => "PPI::Document",
       default_severity => 3,
       supported_parameters => "",
     },
     {
       name => "Variables::ProtectPrivateVars",
       abstract => "Prevent access to private vars in other packages.",
       applies_to => "PPI::Token::Symbol",
       default_severity => 3,
       supported_parameters => "",
       default_themes => "core, maintenance, certrule",
     },
     {
       name => "Variables::RequireInitializationForLocalVars",
       abstract => "Write C<local \$foo = \$bar;> instead of just C<local \$foo;>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "",
       default_severity => 3,
       applies_to => "PPI::Statement::Variable",
     },
     {
       name => "Variables::RequireLexicalLoopIterators",
       abstract => "Write C<for my \$element (\@list) {...}> instead of C<for \$element (\@list) {...}>.",
       supported_parameters => "",
       applies_to => "PPI::Statement::Compound",
       default_severity => 5,
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "Variables::RequireLocalizedPunctuationVars",
       abstract => "Magic variables should be assigned as \"local\".",
       supported_parameters => "allow",
       applies_to => "PPI::Token::Operator",
       default_severity => 4,
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "Variables::RequireNegativeIndices",
       abstract => "Negative array index should be used.",
       supported_parameters => "",
       applies_to => "PPI::Structure::Subscript",
       default_severity => 4,
       default_themes => "core, maintenance, pbp",
     },
   ],
   { "table.fields" => ["name", "abstract"] },
 ]

=item * What's that policy that prohibits returning undef explicitly?:

 pcplist(query => ["undef"]);

Result:

 [
   200,
   "OK",
   [
     "BuiltinFunctions::ProhibitSleepViaSelect",
     "InputOutput::ProhibitJoinedReadline",
     "Subroutines::ProhibitExplicitReturnUndef",
   ],
   {},
 ]

=item * What's that policy that requires using strict?:

 pcplist(query => ["req", "strict"]);

Result:

 [200, "OK", ["TestingAndDebugging::RequireUseStrict"], {}]

=item * List policies which have default severity of 5:

 pcplist(default_severity => 5, detail => 1);

Result:

 [
   200,
   "OK",
   [
     {
       name => "BuiltinFunctions::ProhibitSleepViaSelect",
       abstract => "Use L<Time::HiRes|Time::HiRes> instead of something like C<select(undef, undef, undef, .05)>.",
       default_themes => "core, pbp, bugs",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
     },
     {
       name => "BuiltinFunctions::ProhibitStringyEval",
       abstract => "Write C<eval { my \$foo; bar(\$foo) }> instead of C<eval \"my \$foo; bar(\$foo);\">.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "allow_includes",
       default_themes => "core, pbp, bugs, certrule",
     },
     {
       name => "BuiltinFunctions::RequireGlobFunction",
       abstract => "Use C<glob q{*}> instead of <*>.",
       default_themes => "core, pbp, bugs",
       applies_to => "PPI::Token::QuoteLike::Readline",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "ClassHierarchies::ProhibitOneArgBless",
       abstract => "Write C<bless {}, \$class;> instead of just C<bless {};>.",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
       default_themes => "core, pbp, bugs",
     },
     {
       name => "ControlStructures::ProhibitMutatingListFunctions",
       abstract => "Don't modify C<\$_> in list functions.",
       default_themes => "core, bugs, pbp, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "list_funcs, add_list_funcs",
     },
     {
       name => "InputOutput::ProhibitBarewordFileHandles",
       abstract => "Write C<open my \$fh, q{<}, \$filename;> instead of C<open FH, q{<}, \$filename;>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "InputOutput::ProhibitInteractiveTest",
       abstract => "Use prompt() instead of -t.",
       applies_to => "PPI::Token::Operator",
       default_severity => 5,
       supported_parameters => "",
       default_themes => "core, pbp, bugs, certrule",
     },
     {
       name => "InputOutput::ProhibitTwoArgOpen",
       abstract => "Write C<< open \$fh, q{<}, \$filename; >> instead of C<< open \$fh, \"<\$filename\"; >>.",
       default_themes => "core, pbp, bugs, security, certrule",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "InputOutput::RequireEncodingWithUTF8Layer",
       abstract => "Write C<< open \$fh, q{<:encoding(UTF-8)}, \$filename; >> instead of C<< open \$fh, q{<:utf8}, \$filename; >>.",
       default_themes => "core, bugs, security",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "Modules::ProhibitEvilModules",
       abstract => "Ban modules that aren't blessed by your shop.",
       supported_parameters => "modules, modules_file",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
       default_themes => "core, bugs, certrule",
     },
     {
       name => "Modules::RequireBarewordIncludes",
       abstract => "Write C<require Module> instead of C<require 'Module.pm'>.",
       default_themes => "core, portability",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
     },
     {
       name => "Modules::RequireFilenameMatchesPackage",
       abstract => "Package declaration must match filename.",
       supported_parameters => "",
       applies_to => "PPI::Document",
       default_severity => 5,
       default_themes => "core, bugs",
     },
     {
       name => "Subroutines::ProhibitExplicitReturnUndef",
       abstract => "Return failure with bare C<return> instead of C<return undef>.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "Subroutines::ProhibitNestedSubs",
       abstract => "C<sub never { sub correct {} }>.",
       default_severity => 5,
       applies_to => "PPI::Statement::Sub",
       supported_parameters => "",
       default_themes => "core, bugs",
     },
     {
       name => "Subroutines::ProhibitReturnSort",
       abstract => "Behavior of C<sort> is not defined if called in scalar context.",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, bugs, certrule",
     },
     {
       name => "Subroutines::ProhibitSubroutinePrototypes",
       abstract => "Don't write C<sub my_function (\@\@) {}>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "",
       applies_to => "PPI::Statement::Sub",
       default_severity => 5,
     },
     {
       name => "TestingAndDebugging::ProhibitNoStrict",
       abstract => "Prohibit various flavors of C<no strict>.",
       applies_to => "PPI::Statement::Include",
       default_severity => 5,
       supported_parameters => "allow",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "TestingAndDebugging::RequireUseStrict",
       abstract => "Always C<use strict>.",
       default_themes => "core, pbp, bugs, certrule, certrec",
       supported_parameters => "equivalent_modules",
       applies_to => "PPI::Document",
       default_severity => 5,
     },
     {
       name => "ValuesAndExpressions::ProhibitLeadingZeros",
       abstract => "Write C<oct(755)> instead of C<0755>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "strict",
       default_severity => 5,
       applies_to => "PPI::Token::Number::Octal",
     },
     {
       name => "Variables::ProhibitConditionalDeclarations",
       abstract => "Do not write C< my \$foo = \$bar if \$baz; >.",
       default_themes => "core, bugs",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Variable",
     },
     {
       name => "Variables::ProhibitEvilVariables",
       abstract => "Ban variables that aren't blessed by your shop.",
       default_themes => "core, bugs",
       supported_parameters => "variables, variables_file",
       default_severity => 5,
       applies_to => "PPI::Token::Symbol",
     },
     {
       name => "Variables::RequireLexicalLoopIterators",
       abstract => "Write C<for my \$element (\@list) {...}> instead of C<for \$element (\@list) {...}>.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 5,
       applies_to => "PPI::Statement::Compound",
       supported_parameters => "",
     },
   ],
   { "table.fields" => ["name", "abstract"] },
 ]

=item * List policies which have default severity between 4 and 5:

 pcplist(detail => 1, max_default_severity => 5, min_default_severity => 4);

Result:

 [
   200,
   "OK",
   [
     {
       name => "BuiltinFunctions::ProhibitSleepViaSelect",
       abstract => "Use L<Time::HiRes|Time::HiRes> instead of something like C<select(undef, undef, undef, .05)>.",
       default_themes => "core, pbp, bugs",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::ProhibitStringyEval",
       abstract => "Write C<eval { my \$foo; bar(\$foo) }> instead of C<eval \"my \$foo; bar(\$foo);\">.",
       default_themes => "core, pbp, bugs, certrule",
       supported_parameters => "allow_includes",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "BuiltinFunctions::RequireBlockGrep",
       abstract => "Write C<grep { /\$pattern/ } \@list> instead of C<grep /\$pattern/, \@list>.",
       default_themes => "core, bugs, pbp",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
     },
     {
       name => "BuiltinFunctions::RequireBlockMap",
       abstract => "Write C<map { /\$pattern/ } \@list> instead of C<map /\$pattern/, \@list>.",
       default_themes => "core, bugs, pbp",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "BuiltinFunctions::RequireGlobFunction",
       abstract => "Use C<glob q{*}> instead of <*>.",
       default_themes => "core, pbp, bugs",
       default_severity => 5,
       applies_to => "PPI::Token::QuoteLike::Readline",
       supported_parameters => "",
     },
     {
       name => "ClassHierarchies::ProhibitOneArgBless",
       abstract => "Write C<bless {}, \$class;> instead of just C<bless {};>.",
       default_themes => "core, pbp, bugs",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "CodeLayout::RequireConsistentNewlines",
       abstract => "Use the same newline through the source.",
       default_themes => "core, bugs",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Document",
     },
     {
       name => "ControlStructures::ProhibitLabelsWithSpecialBlockNames",
       abstract => "Don't use labels that are the same as the special block names.",
       default_themes => "core, bugs",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Token::Label",
     },
     {
       name => "ControlStructures::ProhibitMutatingListFunctions",
       abstract => "Don't modify C<\$_> in list functions.",
       default_themes => "core, bugs, pbp, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "list_funcs, add_list_funcs",
     },
     {
       name => "ControlStructures::ProhibitUnreachableCode",
       abstract => "Don't write code after an unconditional C<die, exit, or next>.",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
       default_themes => "core, bugs, certrec",
     },
     {
       name => "ControlStructures::ProhibitYadaOperator",
       abstract => "Never use C<...> in production code.",
       default_themes => "core, pbp, maintenance",
       applies_to => "PPI::Token::Operator",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "InputOutput::ProhibitBarewordFileHandles",
       abstract => "Write C<open my \$fh, q{<}, \$filename;> instead of C<open FH, q{<}, \$filename;>.",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "InputOutput::ProhibitExplicitStdin",
       abstract => "Use \"<>\" or \"<ARGV>\" or a prompting module instead of \"<STDIN>\".",
       default_severity => 4,
       applies_to => "PPI::Token::QuoteLike::Readline",
       supported_parameters => "",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "InputOutput::ProhibitInteractiveTest",
       abstract => "Use prompt() instead of -t.",
       supported_parameters => "",
       applies_to => "PPI::Token::Operator",
       default_severity => 5,
       default_themes => "core, pbp, bugs, certrule",
     },
     {
       name => "InputOutput::ProhibitOneArgSelect",
       abstract => "Never write C<select(\$fh)>.",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
       default_themes => "core, bugs, pbp, certrule",
     },
     {
       name => "InputOutput::ProhibitReadlineInForLoop",
       abstract => "Write C<< while( \$line = <> ){...} >> instead of C<< for(<>){...} >>.",
       supported_parameters => "",
       applies_to => "PPI::Statement::Compound",
       default_severity => 4,
       default_themes => "core, bugs, pbp",
     },
     {
       name => "InputOutput::ProhibitTwoArgOpen",
       abstract => "Write C<< open \$fh, q{<}, \$filename; >> instead of C<< open \$fh, \"<\$filename\"; >>.",
       default_themes => "core, pbp, bugs, security, certrule",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "InputOutput::RequireBriefOpen",
       abstract => "Close filehandles as soon as possible after opening them.",
       default_themes => "core, pbp, maintenance",
       supported_parameters => "lines",
       default_severity => 4,
       applies_to => "PPI::Token::Word",
     },
     {
       name => "InputOutput::RequireEncodingWithUTF8Layer",
       abstract => "Write C<< open \$fh, q{<:encoding(UTF-8)}, \$filename; >> instead of C<< open \$fh, q{<:utf8}, \$filename; >>.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       default_themes => "core, bugs, security",
     },
     {
       name => "Modules::ProhibitAutomaticExportation",
       abstract => "Export symbols via C<\@EXPORT_OK> or C<%EXPORT_TAGS> instead of C<\@EXPORT>.",
       default_themes => "core, bugs",
       supported_parameters => "",
       applies_to => "PPI::Document",
       default_severity => 4,
     },
     {
       name => "Modules::ProhibitEvilModules",
       abstract => "Ban modules that aren't blessed by your shop.",
       default_themes => "core, bugs, certrule",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
       supported_parameters => "modules, modules_file",
     },
     {
       name => "Modules::ProhibitMultiplePackages",
       abstract => "Put packages (especially subclasses) in separate files.",
       applies_to => "PPI::Document",
       default_severity => 4,
       supported_parameters => "",
       default_themes => "core, bugs",
     },
     {
       name => "Modules::RequireBarewordIncludes",
       abstract => "Write C<require Module> instead of C<require 'Module.pm'>.",
       default_themes => "core, portability",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
     },
     {
       name => "Modules::RequireEndWithOne",
       abstract => "End each module with an explicitly C<1;> instead of some funky expression.",
       default_themes => "core, bugs, pbp, certrule",
       default_severity => 4,
       applies_to => "PPI::Document",
       supported_parameters => "",
     },
     {
       name => "Modules::RequireExplicitPackage",
       abstract => "Always make the C<package> explicit.",
       default_severity => 4,
       applies_to => "PPI::Document",
       supported_parameters => "exempt_scripts, allow_import_of",
       default_themes => "core, bugs",
     },
     {
       name => "Modules::RequireFilenameMatchesPackage",
       abstract => "Package declaration must match filename.",
       default_themes => "core, bugs",
       applies_to => "PPI::Document",
       default_severity => 5,
       supported_parameters => "",
     },
     {
       name => "Objects::ProhibitIndirectSyntax",
       abstract => "Prohibit indirect object call syntax.",
       applies_to => "PPI::Token::Word",
       default_severity => 4,
       supported_parameters => "forbid",
       default_themes => "core, pbp, maintenance, certrule",
     },
     {
       name => "Subroutines::ProhibitBuiltinHomonyms",
       abstract => "Don't declare your own C<open> function.",
       supported_parameters => "",
       applies_to => "PPI::Statement::Sub",
       default_severity => 4,
       default_themes => "core, bugs, pbp, certrule",
     },
     {
       name => "Subroutines::ProhibitExplicitReturnUndef",
       abstract => "Return failure with bare C<return> instead of C<return undef>.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 5,
       applies_to => "PPI::Token::Word",
       supported_parameters => "",
     },
     {
       name => "Subroutines::ProhibitNestedSubs",
       abstract => "C<sub never { sub correct {} }>.",
       applies_to => "PPI::Statement::Sub",
       default_severity => 5,
       supported_parameters => "",
       default_themes => "core, bugs",
     },
     {
       name => "Subroutines::ProhibitReturnSort",
       abstract => "Behavior of C<sort> is not defined if called in scalar context.",
       supported_parameters => "",
       applies_to => "PPI::Token::Word",
       default_severity => 5,
       default_themes => "core, bugs, certrule",
     },
     {
       name => "Subroutines::ProhibitSubroutinePrototypes",
       abstract => "Don't write C<sub my_function (\@\@) {}>.",
       default_themes => "core, pbp, bugs, certrec",
       supported_parameters => "",
       applies_to => "PPI::Statement::Sub",
       default_severity => 5,
     },
     {
       name => "Subroutines::RequireArgUnpacking",
       abstract => "Always unpack C<\@_> first.",
       applies_to => "PPI::Statement::Sub",
       default_severity => 4,
       supported_parameters => "short_subroutine_statements, allow_subscripts, allow_delegation_to",
       default_themes => "core, pbp, maintenance",
     },
     {
       name => "Subroutines::RequireFinalReturn",
       abstract => "End every path through a subroutine with an explicit C<return> statement.",
       default_themes => "core, bugs, pbp, certrec",
       supported_parameters => "terminal_funcs, terminal_methods",
       default_severity => 4,
       applies_to => "PPI::Statement::Sub",
     },
     {
       name => "TestingAndDebugging::ProhibitNoStrict",
       abstract => "Prohibit various flavors of C<no strict>.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 5,
       applies_to => "PPI::Statement::Include",
       supported_parameters => "allow",
     },
     {
       name => "TestingAndDebugging::ProhibitNoWarnings",
       abstract => "Prohibit various flavors of C<no warnings>.",
       applies_to => "PPI::Statement::Include",
       default_severity => 4,
       supported_parameters => "allow, allow_with_category_restriction",
       default_themes => "core, bugs, pbp, certrec",
     },
     {
       name => "TestingAndDebugging::ProhibitProlongedStrictureOverride",
       abstract => "Don't turn off strict for large blocks of code.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 4,
       applies_to => "PPI::Statement::Include",
       supported_parameters => "statements",
     },
     {
       name => "TestingAndDebugging::RequireUseStrict",
       abstract => "Always C<use strict>.",
       applies_to => "PPI::Document",
       default_severity => 5,
       supported_parameters => "equivalent_modules",
       default_themes => "core, pbp, bugs, certrule, certrec",
     },
     {
       name => "TestingAndDebugging::RequireUseWarnings",
       abstract => "Always C<use warnings>.",
       default_severity => 4,
       applies_to => "PPI::Document",
       supported_parameters => "equivalent_modules",
       default_themes => "core, pbp, bugs, certrule",
     },
     {
       name => "ValuesAndExpressions::ProhibitCommaSeparatedStatements",
       abstract => "Don't use the comma operator as a statement separator.",
       default_themes => "core, bugs, pbp, certrule",
       applies_to => "PPI::Statement",
       default_severity => 4,
       supported_parameters => "allow_last_statement_to_be_comma_separated_in_map_and_grep",
     },
     {
       name => "ValuesAndExpressions::ProhibitConstantPragma",
       abstract => "Don't C<< use constant FOO => 15 >>.",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Statement::Include",
       default_themes => "core, bugs, pbp",
     },
     {
       name => "ValuesAndExpressions::ProhibitLeadingZeros",
       abstract => "Write C<oct(755)> instead of C<0755>.",
       default_themes => "core, pbp, bugs, certrec",
       default_severity => 5,
       applies_to => "PPI::Token::Number::Octal",
       supported_parameters => "strict",
     },
     {
       name => "ValuesAndExpressions::ProhibitMixedBooleanOperators",
       abstract => "Write C< !\$foo && \$bar || \$baz > instead of C< not \$foo && \$bar or \$baz>.",
       default_themes => "core, bugs, pbp, certrec",
       applies_to => "PPI::Statement",
       default_severity => 4,
       supported_parameters => "",
     },
     {
       name => "Variables::ProhibitAugmentedAssignmentInDeclaration",
       abstract => "Do not write C< my \$foo .= 'bar'; >.",
       default_themes => "core, bugs",
       default_severity => 4,
       applies_to => "PPI::Statement::Variable",
       supported_parameters => "",
     },
     {
       name => "Variables::ProhibitConditionalDeclarations",
       abstract => "Do not write C< my \$foo = \$bar if \$baz; >.",
       default_themes => "core, bugs",
       supported_parameters => "",
       applies_to => "PPI::Statement::Variable",
       default_severity => 5,
     },
     {
       name => "Variables::ProhibitEvilVariables",
       abstract => "Ban variables that aren't blessed by your shop.",
       default_themes => "core, bugs",
       default_severity => 5,
       applies_to => "PPI::Token::Symbol",
       supported_parameters => "variables, variables_file",
     },
     {
       name => "Variables::ProhibitFatCommaInDeclaration",
       abstract => "Prohibit fat comma in declaration",
       default_themes => "core, bugs",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Statement::Variable",
     },
     {
       name => "Variables::ProhibitMatchVars",
       abstract => "Avoid C<\$`>, C<\$&>, C<\$'> and their English equivalents.",
       default_severity => 4,
       applies_to => "PPI::Statement::Include",
       supported_parameters => "",
       default_themes => "core, performance, pbp",
     },
     {
       name => "Variables::RequireLexicalLoopIterators",
       abstract => "Write C<for my \$element (\@list) {...}> instead of C<for \$element (\@list) {...}>.",
       supported_parameters => "",
       default_severity => 5,
       applies_to => "PPI::Statement::Compound",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "Variables::RequireLocalizedPunctuationVars",
       abstract => "Magic variables should be assigned as \"local\".",
       supported_parameters => "allow",
       default_severity => 4,
       applies_to => "PPI::Token::Operator",
       default_themes => "core, pbp, bugs, certrec",
     },
     {
       name => "Variables::RequireNegativeIndices",
       abstract => "Negative array index should be used.",
       default_themes => "core, maintenance, pbp",
       supported_parameters => "",
       default_severity => 4,
       applies_to => "PPI::Structure::Subscript",
     },
   ],
   { "table.fields" => ["name", "abstract"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<default_severity> => I<uint>

=item * B<detail> => I<bool>

=item * B<max_default_severity> => I<uint>

=item * B<min_default_severity> => I<uint>

=item * B<query> => I<array[str]>

Filter by name.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcpman

Usage:

 pcpman(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show manpage of Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcpman(policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pcppath

Usage:

 pcppath(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get path to locally installed Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcppath(policies => ["Variables/ProhibitMatchVars"]);

Result:

 [
   200,
   "OK",
   [
     "/home/u1/perl5/perlbrew/perls/perl-5.34.0/lib/site_perl/5.34.0/Perl/Critic/Policy/Variables/ProhibitMatchVars.pm",
   ],
   {},
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policies>* => I<array[perl::modname]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-PerlCriticUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PerlCriticUtils>.

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

This software is copyright (c) 2022, 2021, 2018, 2017 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PerlCriticUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
