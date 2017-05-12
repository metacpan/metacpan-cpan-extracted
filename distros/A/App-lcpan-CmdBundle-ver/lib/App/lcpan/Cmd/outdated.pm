package App::lcpan::Cmd::outdated;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use ExtUtils::MakeMaker;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'lcpan version of cpan-outdated',
    description => <<'_',

Like <prog:cpan-outdated> utility, this subcommand also checks the versions of
installed modules and compares them against the database. If the installed
version is older, will show the release files. The output can then be fed to
<prog:cpanm>, for example.

Thanks to the data already in SQLite format, it can be faster than
<prog:cpan-outdated>.

_
    args => {
        %App::lcpan::common_args,
    },
};
sub handle_cmd {
    require PERLANCAR::Module::List;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $mod_paths = PERLANCAR::Module::List::list_modules(
        "", {list_modules=>1, recurse=>1, return_path=>1},
    );

    my %mods_from_db;
    my %file_mods; # key=filename, val=(hash key=)
    {
        last unless %$mod_paths;
        my $sth = $dbh->prepare("
SELECT
  name, version, cpanid,
  (SELECT name FROM file WHERE id=file_id) fname
FROM module WHERE name IN (".
                join(",", map {$dbh->quote($_)} keys %$mod_paths).")");
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            $row->{fname} = join(
                "",
                substr($row->{cpanid}, 0, 1), "/",
                substr($row->{cpanid}, 0, 2), "/",
                $row->{cpanid}, "/",
                $row->{fname},
            );
            $mods_from_db{$row->{name}} = $row;
            $file_mods{$row->{fname}}{$row->{name}}++;
        }
    }

    my @res;
    my %done_mods;
    for my $mod (sort keys %$mod_paths) {
        next if $done_mods{$mod};
        next unless exists $mods_from_db{$mod};

        my $fname = $mods_from_db{$mod}{fname};
        $log->tracef("Checking module %s (%s)", $mod, $fname);

        my $ver = MM->parse_version($mod_paths->{$mod});
        $ver = 0 if !defined($ver) || defined($ver) && $ver eq 'undef';
        $log->tracef("Version of installed module %s (%s): %s",
                     $mod, $mod_paths->{$mod}, $ver);

        # mark all modules from the same file as done
        $log->tracef("Marking all modules from (%s) as done ...", $fname);
        for (keys %{ $file_mods{$fname} }) {
            $log->tracef("  %s", $_);
            $done_mods{$_}++;
        }
        my $cmp = version->parse($ver) <=>
            version->parse($mods_from_db{$mod}{version});
        next unless $cmp == -1;

        $log->tracef("Adding file %s because %s\'s installed version (%s) is older than db version (%s)", $fname, $mod, $ver, $mods_from_db{$mod}{version});
        push @res, $fname;

    }

    [200, "OK", \@res];
}

1;
# ABSTRACT: lcpan version of cpan-outdated

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::outdated - lcpan version of cpan-outdated

=head1 VERSION

This document describes version 0.03 of App::lcpan::Cmd::outdated (from Perl distribution App-lcpan-CmdBundle-ver), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<outdated>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

lcpan version of cpan-outdated.

Like L<cpan-outdated> utility, this subcommand also checks the versions of
installed modules and compares them against the database. If the installed
version is older, will show the release files. The output can then be fed to
L<cpanm>, for example.

Thanks to the data already in SQLite format, it can be faster than
L<cpan-outdated>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-ver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-ver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-ver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
