package App::ModuleFeaturesUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-25'; # DATE
our $DIST = 'App-ModuleFeaturesUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Perinci::Sub::Args::Common::CLI qw(%argspec_detail);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI Utilities related to Module::Features',
};

our %argspecreq0_feature_set = (
    feature_set => {
        schema => 'perl::modulefeatures::modname*',
        req => 1,
        pos => 0,
    },
);

our %argspecreq0_module = (
    module => {
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
    },
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
        %argspecreq0_feature_set,
    },
};
sub check_feature_set_spec {
    require Module::FeaturesUtil::Check;

    my %args = @_;

    my $mod = "Module::Features::$args{feature_set}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $spec = \%{"$mod\::FEATURES_DEF"};
    Module::FeaturesUtil::Check::check_feature_set_spec($spec);
}

$SPEC{check_features_decl} = {
    v => 1.1,
    summary => 'Check %FEATURES in a module',
    args => {
        %argspecreq0_module,
    },
};
sub check_features_decl {
    require Module::FeaturesUtil::Check;
    require Module::FeaturesUtil::Get;

    my %args = @_;
    my $mod = $args{module};

    my $features_decl = Module::FeaturesUtil::Get::get_features_decl($mod, 'load');
    Module::FeaturesUtil::Check::check_features_decl($features_decl);
}

$SPEC{check_module_features} = {
    v => 1.1,
    summary => 'Check %FEATURES in a module and return the value of specified feature',
    args => {
        %argspecreq0_module,
        %argspec1_feature_name,
    },
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

1;
# ABSTRACT: CLI Utilities related to Module::Features

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ModuleFeaturesUtils - CLI Utilities related to Module::Features

=head1 VERSION

This document describes version 0.003 of App::ModuleFeaturesUtils (from Perl distribution App-ModuleFeaturesUtils), released on 2021-02-25.

=head1 DESCRIPTION

This distribution includes the following utilities:

=over

=item * L<check-feature-set-spec>

=item * L<check-features-decl>

=item * L<check-module-features>

=item * L<get-feature-set-spec>

=item * L<get-features-decl>

=item * L<list-feature-set-features>

=item * L<list-feature-sets>

=back

=head1 FUNCTIONS


=head2 check_feature_set_spec

Usage:

 check_feature_set_spec(%args) -> [status, msg, payload, meta]

Check specification in %FEATURES_DEF in Modules::Features::* module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<feature_set>* => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 check_features_decl

Usage:

 check_features_decl(%args) -> [status, msg, payload, meta]

Check %FEATURES in a module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 check_module_features

Usage:

 check_module_features(%args) -> [status, msg, payload, meta]

Check %FEATURES in a module and return the value of specified feature.

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

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_feature_set_spec

Usage:

 get_feature_set_spec(%args) -> [status, msg, payload, meta]

Get feature set specification.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<feature_set>* => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_features_decl

Usage:

 get_features_decl(%args) -> [status, msg, payload, meta]

Get features declaration.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_feature_set_features

Usage:

 list_feature_set_features(%args) -> [status, msg, payload, meta]

List features in a feature set.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Return detailed record for each result item.

=item * B<feature_set>* => I<perl::modulefeatures::modname>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_feature_sets

Usage:

 list_feature_sets(%args) -> [status, msg, payload, meta]

List feature sets (in modules under Module::Features:: namespace).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

Return detailed record for each result item.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ModuleFeaturesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ModuleFeaturesUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-ModuleFeaturesUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
