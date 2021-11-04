package App::CPANChangesUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-10-17'; # DATE
our $DIST = 'App-CPANChangesUtils'; # DIST
our $VERSION = '0.074'; # VERSION

our %SPEC;

our %argspecs_common = (
    file => {
        schema => 'filename*',
        summary => 'If not specified, will look for file called '.
        'Changes/ChangeLog in current directory',
        pos => 0,
    },
    class => {
        schema => 'perl::modname*',
        default => 'CPAN::Changes',
    },
);

$SPEC{parse_cpan_changes} = {
    v => 1.1,
    summary => 'Parse CPAN Changes file',
    description => <<'_',

This utility is a simple wrapper for <pm:CPAN::Changes>.

_
    args => {
        %argspecs_common,
        unbless => {
            summary => 'Whether to return Perl objects as unblessed refs',
            schema => 'bool*',
            default => 1,
            description => <<'_',

If you set this to false, you'll need to use an output format that can handle
serializing Perl objects, e.g. on the CLI using `--format=perl`.

_
        },
    },
};
sub parse_cpan_changes {
    require Data::Structure::Util;

    my %args = @_;
    my $unbless = $args{unbless} // 1;
    my $class = $args{class} // 'CPAN::Changes';
    (my $class_pm = "$class.pm") =~ s!::!/!g;
    require $class_pm;

    my $file = $args{file};
    if (!$file) {
	for (qw/Changes ChangeLog/) {
	    do { $file = $_; last } if -f $_;
	}
    }
    return [400, "Please specify file ".
                "(or run in directory where Changes file exists)"]
        unless $file;

    my $ch = $class->load($file);
    [200, "OK", $unbless ? Data::Structure::Util::unbless($ch) : $ch];
}

$SPEC{format_cpan_changes} = {
    v => 1.1,
    summary => 'Format CPAN Changes',
    description => <<'_',

This utility is a simple wrapper to <pm:CPAN::Changes>. It will parse your CPAN
Changes file into data structure, then use `serialize()` to format it back to
text form.

_
    args => {
        %argspecs_common,
    },
};
sub format_cpan_changes {
    my %args = @_;

    my $res = parse_cpan_changes(%args, unbless=>0);
    return $res unless $res->[0] == 200;
    [200, "OK", $res->[2]->serialize];
}

1;
# ABSTRACT: Parse CPAN Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CPANChangesUtils - Parse CPAN Changes file

=head1 VERSION

This document describes version 0.074 of App::CPANChangesUtils (from Perl distribution App-CPANChangesUtils), released on 2021-10-17.

=head1 DESCRIPTION

This distribution provides some CLI utilities related to CPAN Changes

=head1 FUNCTIONS


=head2 format_cpan_changes

Usage:

 format_cpan_changes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Format CPAN Changes.

This utility is a simple wrapper to L<CPAN::Changes>. It will parse your CPAN
Changes file into data structure, then use C<serialize()> to format it back to
text form.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<perl::modname> (default: "CPAN::Changes")

=item * B<file> => I<filename>

If not specified, will look for file called ChangesE<sol>ChangeLog in current directory.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 parse_cpan_changes

Usage:

 parse_cpan_changes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse CPAN Changes file.

This utility is a simple wrapper for L<CPAN::Changes>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<perl::modname> (default: "CPAN::Changes")

=item * B<file> => I<filename>

If not specified, will look for file called ChangesE<sol>ChangeLog in current directory.

=item * B<unbless> => I<bool> (default: 1)

Whether to return Perl objects as unblessed refs.

If you set this to false, you'll need to use an output format that can handle
serializing Perl objects, e.g. on the CLI using C<--format=perl>.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-CPANChangesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CPANChangesUtils>.

=head1 SEE ALSO

L<CPAN::Changes>

L<CPAN::Changes::Spec>

An alternative way to manage your Changes using INI master format:
L<Module::Metadata::Changes>.

Dist::Zilla plugin to check your Changes before build:
L<Dist::Zilla::Plugin::CheckChangesHasContent>,
L<Dist::Zilla::Plugin::CheckChangeLog>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANChangesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
