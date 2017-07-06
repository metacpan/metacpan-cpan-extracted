package App::pmpatcher;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options qw(system);
use String::ShellQuote;

our %SPEC;

$SPEC{pmpatcher} = {
    v => 1.1,
    summary => 'Apply a set of module patches on your Perl installation',
    description => <<'_',

You might have a set of patches that you want to apply on Perl modules on all
your Perl installation. For example, currently as of this writing I have this on
my `patches` directory:

    pm-OrePAN-Archive-0.08-support_no_index_file.patch
    pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch

These patches might be pending merge by the module maintainer, or are of private
nature so might never be merged, or of any other nature. Applying module patches
to an installation is a lightweight alternative to creating a fork for each of
these modules.

This utility helps you making the process of applying these patches more
convenient. Basically this utility just locates all the target modules and
feeds all of these patches to the `patch` program.

To use this utility, first of all you need to gather all your module patches in
a single directory (see `patches_dir` option). Also, you need to make sure that
all your `*.patch` files match this name pattern:

    pm-<MODULE-NAME-DASH-SEPARATED>-<VERSION>-<TOPIC>.patch

Then, to apply all the patches, you just call:

    % pmpatcher --patches-dir ~/patches

(Or, you might also want to put `patches_dir=/path/to/patches` into
`~/pmpatcher.conf` to save you from having to type the option repeatedly.)

Example result:

    % pmpatcher
    +--------------------------------------------------------------+--------+---------+
    | item_id                                                      | status | message |
    +--------------------------------------------------------------+--------+---------+
    | pm-OrePAN-Archive-0.08-support_no_index_file.patch           | 200    | Applied |
    | pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch | 200    | Applied |
    +--------------------------------------------------------------+--------+---------+

If you try to run it again, you might get:

    % pmpatcher
    +--------------------------------------------------------------+--------+-----------------+
    | item_id                                                      | status | message         |
    +--------------------------------------------------------------+--------+-----------------+
    | pm-OrePAN-Archive-0.08-support_no_index_file.patch           | 304    | Already applied |
    | pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch | 304    | Already applied |
    +--------------------------------------------------------------+--------+-----------------+

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
        {url=>'prog:progpatcher'},
    ],
};
sub pmpatcher {
    require Module::Path::More;
    require Perinci::Object;

    my %args = @_;

    my $patches_dir = $args{patches_dir}
        or return [400, "Please specify patches_dir"];
    $patches_dir =~ s!/\z!!; # convenience

    log_trace("Opening patches_dir '%s' ...", $patches_dir);
    opendir my($dh), $patches_dir
        or return [500, "Can't open patches_dir '$patches_dir': $!"];

    my $envres = Perinci::Object::envresmulti();

  FILE:
    for my $fname (sort readdir $dh) {
        next if $fname eq '.' || $fname eq '..';
        log_trace("Considering file '%s' ...", $fname);
        unless ($fname =~ /\A
                           pm-
                           (\w+(?:-\w+)*)-
                           ([0-9][0-9._]*)-
                           ([^.]+)
                           \.patch\z/x) {
            log_trace("Skipped file '%s' (doesn't match pattern)", $fname);
            next FILE;
        }
        my ($mod0, $ver, $topic) = ($1, $2, $3);
        my $mod = $mod0; $mod =~ s!-!::!g;
        my $mod_pm = $mod0; $mod_pm =~ s!-!/!g; $mod_pm .= ".pm";

        my $mod_path = Module::Path::More::module_path(module=>$mod_pm);
        unless ($mod_path) {
            log_info("Skipping patch '%s' (module %s not installed)",
                        $fname, $mod);
            next FILE;
        }
        (my $mod_dir = $mod_path) =~ s!(.+)[/\\].+!$1!;

        open my($fh), "<", "$patches_dir/$fname" or do {
            log_error("Skipping patch '%s' (can't open file: %s)",
                         $fname, $!);
            $envres->add_result(500, "Can't open: $!", {item_id=>$fname});
            next FILE;
        };

        my $out;
        # first check if patch is already applied
        system(
            {shell=>1, log=>1, lang=>"C", capture_stdout=>\$out},
            join(" ",
                 "patch", "-d", shell_quote($mod_dir),
                 "-t", "--dry-run",
                 "<", shell_quote("$patches_dir/$fname"),
             ),
        );

        if ($?) {
            log_error("Skipping patch '%s' (can't patch(1) to detect applied: %s)",
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
                log_info("Skipping patch '%s' (already reversed)", $fname);
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
                         "patch", "-d", shell_quote($mod_dir),
                         "--reverse",
                         "<", shell_quote("$patches_dir/$fname"),
                     ),
                );
                if ($?) {
                    log_error("Skipping patch '%s' (can't patch(2b) to reverse-apply: %s)",
                                 $fname, $?);
                    $envres->add_result(
                        500, "Can't patch(2b) to reverse-apply: $?", {item_id=>$fname});
                    next FILE;
                }
            }
        } else {
            if ($already_applied) {
                log_info("Skipping patch '%s' (already applied)", $fname);
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
                         "patch", "-d", shell_quote($mod_dir),
                         "--forward",
                         "<", shell_quote("$patches_dir/$fname"),
                     ),
                );
                if ($?) {
                    log_error("Skipping patch '%s' (can't patch(2) to apply: %s)",
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
# ABSTRACT: Apply a set of module patches on your Perl installation

__END__

=pod

=encoding UTF-8

=head1 NAME

App::pmpatcher - Apply a set of module patches on your Perl installation

=head1 VERSION

This document describes version 0.05 of App::pmpatcher (from Perl distribution App-pmpatcher), released on 2017-07-03.

=head1 SYNOPSIS

See L<pmpatcher> CLI.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 pmpatcher

Usage:

 pmpatcher(%args) -> [status, msg, result, meta]

Apply a set of module patches on your Perl installation.

You might have a set of patches that you want to apply on Perl modules on all
your Perl installation. For example, currently as of this writing I have this on
my C<patches> directory:

 pm-OrePAN-Archive-0.08-support_no_index_file.patch
 pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch

These patches might be pending merge by the module maintainer, or are of private
nature so might never be merged, or of any other nature. Applying module patches
to an installation is a lightweight alternative to creating a fork for each of
these modules.

This utility helps you making the process of applying these patches more
convenient. Basically this utility just locates all the target modules and
feeds all of these patches to the C<patch> program.

To use this utility, first of all you need to gather all your module patches in
a single directory (see C<patches_dir> option). Also, you need to make sure that
all your C<*.patch> files match this name pattern:

 pm-<MODULE-NAME-DASH-SEPARATED>-<VERSION>-<TOPIC>.patch

Then, to apply all the patches, you just call:

 % pmpatcher --patches-dir ~/patches

(Or, you might also want to put C<patches_dir=/path/to/patches> into
C<~/pmpatcher.conf> to save you from having to type the option repeatedly.)

Example result:

 % pmpatcher
 +--------------------------------------------------------------+--------+---------+
 | item_id                                                      | status | message |
 +--------------------------------------------------------------+--------+---------+
 | pm-OrePAN-Archive-0.08-support_no_index_file.patch           | 200    | Applied |
 | pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch | 200    | Applied |
 +--------------------------------------------------------------+--------+---------+

If you try to run it again, you might get:

 % pmpatcher
 +--------------------------------------------------------------+--------+-----------------+
 | item_id                                                      | status | message         |
 +--------------------------------------------------------------+--------+-----------------+
 | pm-OrePAN-Archive-0.08-support_no_index_file.patch           | 304    | Already applied |
 | pm-Pod-Elemental-PerlMunger-0.200002-DATA_encoding_fix.patch | 304    | Already applied |
 +--------------------------------------------------------------+--------+-----------------+

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

Please visit the project's homepage at L<https://metacpan.org/release/App-pmpatcher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-pmpatcher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-pmpatcher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<progpatcher>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
