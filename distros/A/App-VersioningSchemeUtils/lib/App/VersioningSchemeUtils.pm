package App::VersioningSchemeUtils;

our $DATE = '2018-10-14'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %arg_scheme = (
    scheme => {
        schema => ['str*', match=>qr/\A\w+\z/],
        req => 1,
        cmdline_aliases => {s=>{}},
        completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                word => $args{word},
                ns_prefix => 'Versioning::Scheme',
            );
        },
    },
);

our %arg0_v = (
    v => {
        schema => ['str*'],
        pos => 0,
        req => 1,
    },
);

our %arg0_v1 = (
    v1 => {
        schema => ['str*'],
        pos => 0,
        req => 1,
    },
);

our %arg1_v2 = (
    v2 => {
        schema => ['str*'],
        pos => 1,
        req => 1,
    },
);

sub _load_vs_mod {
    my $args = shift;

    my $mod = "Versioning::Scheme::$args->{scheme}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;
    $mod;
}

$SPEC{list_versioning_schemes} = {
    v => 1.1,
    summary => 'List available versioning schemes',
};
sub list_versioning_schemes {
    require PERLANCAR::Module::List;
    my $mods = PERLANCAR::Module::List::list_modules(
        'Versioning::Scheme::', {list_modules=>1});
    my @rows;
    for (sort keys %$mods) { s/\AVersioning::Scheme:://; push @rows, $_ }
    [200, "OK", \@rows];
}

$SPEC{bump_version} = {
    v => 1.1,
    summary => 'Bump version number according to specified scheme',
    args => {
        %arg_scheme,
        %arg0_v,
        # XXX options
    },
};
sub bump_version {
    my %args = @_;

    my $mod = _load_vs_mod(\%args);
    [200, "OK", $mod->bump_version($args{v})];
}

$SPEC{cmp_version} = {
    v => 1.1,
    summary => 'Compare two version number according to specified scheme',
    args => {
        %arg_scheme,
        %arg0_v1,
        %arg1_v2,
    },
};
sub cmp_version {
    my %args = @_;

    my $mod = _load_vs_mod(\%args);
    [200, "OK", $mod->cmp_version($args{v1}, $args{v2})];
}

$SPEC{is_valid_version} = {
    v => 1.1,
    summary => 'Check whether version number is valid, '.
        'according to specified scheme',
    args => {
        %arg_scheme,
        %arg0_v,
        # XXX options
    },
};
sub is_valid_version {
    my %args = @_;

    my $mod = _load_vs_mod(\%args);
    my $res = $mod->is_valid_version($args{v}) ? 1:0;
    [200, "OK", $res, {'cmdline.result'=>'', 'cmdline.exit_code'=>$res ? 0:1}];
}

$SPEC{normalize_version} = {
    v => 1.1,
    summary => 'Normalize version number according to specified scheme',
    args => {
        %arg_scheme,
        %arg0_v,
        # XXX options
    },
};
sub normalize_version {
    my %args = @_;

    my $mod = _load_vs_mod(\%args);
    [200, "OK", $mod->normalize_version($args{v})];
}

$SPEC{parse_version} = {
    v => 1.1,
    summary => 'Parse version number according to specified scheme',
    args => {
        %arg_scheme,
        %arg0_v,
        # XXX options
    },
};
sub parse_version {
    my %args = @_;

    my $mod = _load_vs_mod(\%args);
    [200, "OK", $mod->parse_version($args{v})];
}

1;
# ABSTRACT: Utilities related to Versioning::Scheme

__END__

=pod

=encoding UTF-8

=head1 NAME

App::VersioningSchemeUtils - Utilities related to Versioning::Scheme

=head1 VERSION

This document describes version 0.001 of App::VersioningSchemeUtils (from Perl distribution App-VersioningSchemeUtils), released on 2018-10-14.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<bump-version>

=item * L<cmp-version>

=item * L<is-valid-version>

=item * L<list-versioning-schemes>

=item * L<normalize-version>

=item * L<parse-version>

=back

=head1 FUNCTIONS


=head2 bump_version

Usage:

 bump_version(%args) -> [status, msg, result, meta]

Bump version number according to specified scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<str>

=item * B<v>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 cmp_version

Usage:

 cmp_version(%args) -> [status, msg, result, meta]

Compare two version number according to specified scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<str>

=item * B<v1>* => I<str>

=item * B<v2>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 is_valid_version

Usage:

 is_valid_version(%args) -> [status, msg, result, meta]

Check whether version number is valid, according to specified scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<str>

=item * B<v>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_versioning_schemes

Usage:

 list_versioning_schemes() -> [status, msg, result, meta]

List available versioning schemes.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 normalize_version

Usage:

 normalize_version(%args) -> [status, msg, result, meta]

Normalize version number according to specified scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<str>

=item * B<v>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 parse_version

Usage:

 parse_version(%args) -> [status, msg, result, meta]

Parse version number according to specified scheme.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<scheme>* => I<str>

=item * B<v>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-VersioningSchemeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-VersioningSchemeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-VersioningSchemeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
