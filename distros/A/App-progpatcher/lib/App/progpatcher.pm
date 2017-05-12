package App::progpatcher;

our $DATE = '2016-11-27'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use IPC::System::Options qw(system);
use String::ShellQuote;

our %SPEC;

$SPEC{progpatcher} = {
    v => 1.1,
    summary => 'Apply a set of patches to your programs',
    description => <<'_',

This is like <prog:pmpatcher> except for programs. You might have a set of
patches that you want to apply on programs in the `PATH`. For example, currently
as of this writing I have this on my `patches` directory:

    prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch

These patches might be pending for merge upstream, or are of private nature so
might never be merged, or of any other nature. Applying patches is a lightweight
alternative to creating a fork for each of these programs.

This utility helps you making the process of applying these patches more
convenient. Basically this utility just locates all the target modules and
feeds all of these patches to the `patch` program.

To use this utility, first of all you need to gather all your program patches in
a single directory (see `patches_dir` option). Also, you need to make sure that
all patches you want to use match this name pattern:

    prog-<PROGRAM-NAME>.<TOPIC>.patch

This directory can be the same as the one you use for `pmpatcher`, since
`pmpatcher` uses another prefix.

Then, to apply all the patches, you just call:

    % progpatcher --patches-dir ~/patches

(Or, you might also want to put `patches_dir=/path/to/patches` into
`~/progpatcher.conf` to save you from having to type the option repeatedly.)

Example result:

    % progpatcher
    +--------------------------------------------------------------------------+--------+---------+
    | item_id                                                                  | status | message |
    +--------------------------------------------------------------------------+--------+---------+
    | prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch | 200    | Applied |
    +--------------------------------------------------------------------------+--------+---------+

If you try to run it again, you might get:

    % progpatcher
    +--------------------------------------------------------------------------+--------+-----------------+
    | item_id                                                                  | status | message         |
    +--------------------------------------------------------------------------+--------+-----------------+
    | prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch | 304    | Already applied |
    +--------------------------------------------------------------------------+--------+-----------------+

There's also a `--dry-run` and a `-R` (`--reverse`) option, just like `patch`.

_
    args => {
        patches_dir => {
            schema => 'str*',
            req => 1,
        },
        reverse => {
            schema => ['bool', is=>1],
            cmdline_aliases => {R=>{}},
        },
    },
    deps => {
        prog => 'patch',
    },
    features => {
        dry_run => 1,
    },
    links => [
        {url=>'prog:pmpatcher'},
    ],
};
sub progpatcher {
    require File::Which;
    require Perinci::Object;

    my %args = @_;

    my $patches_dir = $args{patches_dir}
        or return [400, "Please specify patches_dir"];
    $patches_dir =~ s!/\z!!; # convenience

    $log->tracef("Opening patches_dir '%s' ...", $patches_dir);
    opendir my($dh), $patches_dir
        or return [500, "Can't open patches_dir '$patches_dir': $!"];

    my $envres = Perinci::Object::envresmulti();

  FILE:
    for my $fname (sort readdir $dh) {
        next if $fname eq '.' || $fname eq '..';
        $log->tracef("Considering file '%s' ...", $fname);
        unless ($fname =~ /\A
                           prog-
                           (.+)\.
                           ([^.]+)
                           \.patch\z/x) {
            $log->tracef("Skipped file '%s' (doesn't match pattern)", $fname);
            next FILE;
        }
        my ($prog, $topic) = ($1, $2);

        my $prog_path = File::Which::which($prog);
        unless ($prog_path) {
            $log->infof("Skipping patch '%s' (program %s not found in PATH)",
                        $fname, $prog);
            next FILE;
        }
        (my $prog_dir = $prog_path) =~ s!(.+)[/\\].+!$1!;

        open my($fh), "<", "$patches_dir/$fname" or do {
            $log->errorf("Skipping patch '%s' (can't open file: %s)",
                         $fname, $!);
            $envres->add_result(500, "Can't open: $!", {item_id=>$fname});
            next FILE;
        };

        my $out;
        # first check if patch is already applied
        system(
            {shell=>1, log=>1, lang=>"C", capture_stdout=>\$out},
            join(" ",
                 "patch", "-d", shell_quote($prog_dir),
                 "-t", "--dry-run",
                 "<", shell_quote("$patches_dir/$fname"),
             ),
        );

        if ($?) {
            $log->errorf("Skipping patch '%s' (can't patch(1) to detect applied: %s)",
                         $fname, $?);
            $envres->add_result(
                500, "Can't patch(1) to detect applied: $?", {item_id=>$fname});
            next FILE;
        }

        my $already_applied = 0;
        if ($out =~ /Reversed .*patch detected/) {
            $already_applied = 1;
        }

        if ($args{reverse}) {
            if (!$already_applied) {
                $log->infof("Skipping patch '%s' (already reversed)", $fname);
                $envres->add_result(
                    304, "Already reversed", {item_id=>$fname});
                next FILE;
            } else {
                if ($args{-dry_run}) {
                    $envres->add_result(
                        200, "Reverse-applying (dry-run)", {item_id=>$fname});
                    next FILE;
                }
                system(
                    {shell=>1, log=>1, lang=>"C", capture_stdout=>\$out},
                    join(" ",
                         "patch", "-d", shell_quote($prog_dir),
                         "--reverse",
                         "<", shell_quote("$patches_dir/$fname"),
                     ),
                );
                if ($?) {
                    $log->errorf("Skipping patch '%s' (can't patch(2b) to reverse-apply: %s)",
                                 $fname, $?);
                    $envres->add_result(
                        500, "Can't patch(2b) to reverse-apply: $?", {item_id=>$fname});
                    next FILE;
                }
            }
        } else {
            if ($already_applied) {
                $log->infof("Skipping patch '%s' (already applied)", $fname);
                $envres->add_result(
                    304, "Already applied", {item_id=>$fname});
                next FILE;
            } else {
                if ($args{-dry_run}) {
                    $envres->add_result(
                        200, "Applying (dry-run)", {item_id=>$fname});
                    next FILE;
                }
                system(
                    {shell=>1, log=>1, lang=>"C", capture_stdout=>\$out},
                    join(" ",
                         "patch", "-d", shell_quote($prog_dir),
                         "--forward",
                         "<", shell_quote("$patches_dir/$fname"),
                     ),
                );
                if ($?) {
                    $log->errorf("Skipping patch '%s' (can't patch(2) to apply: %s)",
                                 $fname, $?);
                    $envres->add_result(
                        500, "Can't patch(2) to apply: $?", {item_id=>$fname});
                    next FILE;
                }
            }
        }

        $envres->add_result(
            200, ($args{reverse} ? "Reverse-applied" : "Applied"),
            {item_id=>$fname});
    }

    my $res = $envres->as_struct;
    $res->[2] = $res->[3]{results};
    $res->[3]{'table.fields'} = [qw/item_id status message/];
    #$res->[3]{'table.hide_unknown_fields'} = 1;
    $res;
}

1;
# ABSTRACT: Apply a set of patches to your programs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::progpatcher - Apply a set of patches to your programs

=head1 VERSION

This document describes version 0.001 of App::progpatcher (from Perl distribution App-progpatcher), released on 2016-11-27.

=head1 SYNOPSIS

See L<progpatcher> CLI.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 progpatcher(%args) -> [status, msg, result, meta]

Apply a set of patches to your programs.

This is like L<pmpatcher> except for programs. You might have a set of
patches that you want to apply on programs in the C<PATH>. For example, currently
as of this writing I have this on my C<patches> directory:

 prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch

These patches might be pending for merge upstream, or are of private nature so
might never be merged, or of any other nature. Applying patches is a lightweight
alternative to creating a fork for each of these programs.

This utility helps you making the process of applying these patches more
convenient. Basically this utility just locates all the target modules and
feeds all of these patches to the C<patch> program.

To use this utility, first of all you need to gather all your program patches in
a single directory (see C<patches_dir> option). Also, you need to make sure that
all patches you want to use match this name pattern:

 prog-<PROGRAM-NAME>.<TOPIC>.patch

This directory can be the same as the one you use for C<pmpatcher>, since
C<pmpatcher> uses another prefix.

Then, to apply all the patches, you just call:

 % progpatcher --patches-dir ~/patches

(Or, you might also want to put C<patches_dir=/path/to/patches> into
C<~/progpatcher.conf> to save you from having to type the option repeatedly.)

Example result:

 % progpatcher
 +--------------------------------------------------------------------------+--------+---------+
 | item_id                                                                  | status | message |
 +--------------------------------------------------------------------------+--------+---------+
 | prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch | 200    | Applied |
 +--------------------------------------------------------------------------+--------+---------+

If you try to run it again, you might get:

 % progpatcher
 +--------------------------------------------------------------------------+--------+-----------------+
 | item_id                                                                  | status | message         |
 +--------------------------------------------------------------------------+--------+-----------------+
 | prog-cpanm.20161127-only_use_uri_from_mirror_where_we_found_module.patch | 304    | Already applied |
 +--------------------------------------------------------------------------+--------+-----------------+

There's also a C<--dry-run> and a C<-R> (C<--reverse>) option, just like C<patch>.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<patches_dir>* => I<str>

=item * B<reverse> => I<bool>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-progpatcher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-progpatcher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-progpatcher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<pmpatcher>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
