## no critic: ControlStructures::ProhibitUnreachableCode

package App::lcpan::Cmd::whatsnew;

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
use Hash::Subset 'hash_subset';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-26'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.074'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => "Show what's added/updated recently",
    args => {
        %App::lcpan::common_args,
        %App::lcpan::fctime_or_mtime_args,
        my_author => {
            summary => 'My author ID',
            description => <<'_',

If specified, will show additional added/updated items for this author ID
("you"), e.g. what distributions recently added dependency to one of your
modules.

_
            schema => 'str*',
            cmdline_aliases => {a=>{}},
            completion => \&App::lcpan::_complete_cpanid,
        },
    },
};
sub handle_cmd {
    require Perinci::Result::Format::Lite;
    require Text::Table::Org; # just to let scan-prereqs know

    my %args = @_;
    my $my_author = $args{my_author};

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    $args{added_or_updated_since_last_index_update} = 1 if !(grep {exists $App::lcpan::fctime_or_mtime_args{$_}} keys %args);
    App::lcpan::_set_since(\%args, $dbh);

    my $time = delete($args{added_or_updated_since});
    my $ftime = scalar(gmtime $time) . " UTC";

    my $org = '';

    local $ENV{FORMAT_PRETTY_TABLE_BACKEND} = 'Text::Table::Org';

    #$org .= "#+INFOJS_OPT: view:info toc:nil\n";
    $org .= "WHAT'S NEW SINCE $ftime\n\n";

  NEW_MODULES: {
        my ($res, $fres);
        $res = App::lcpan::modules(added_since=>$time, detail=>1);
        unless ($res->[0] == 200) {
            $org .= "Can't list new modules: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* New modules ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  UPDATED_MODULES: {
        my ($res, $fres);
        $res = App::lcpan::modules(updated_since=>$time, detail=>1);
        unless ($res->[0] == 200) {
            $org .= "Can't list updated modules: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* Updated modules ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  NEW_AUTHORS: {
        my ($res, $fres);
        $res = App::lcpan::authors(added_since=>$time, detail=>1);
        unless ($res->[0] == 200) {
            $org .= "Can't list new authors: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* New authors ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  UPDATED_AUTHORS: {
        my ($res, $fres);
        $res = App::lcpan::authors(updated_since=>$time, detail=>1);
        unless ($res->[0] == 200) {
            $org .= "Can't list updated authors: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* Updated authors ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  NEW_REVERSE_DEPENDENCIES: {
        last unless defined $my_author;
        my ($res, $fres);
        require App::lcpan::Cmd::author_rdeps;
        $res = App::lcpan::Cmd::author_rdeps::handle_cmd(
            author=>$my_author, user_authors_arent=>[$my_author],
            added_since=>$time,
            phase => 'ALL',
            rel => 'ALL',
        );
        unless ($res->[0] == 200) {
            $org .= "Can't list new reverse dependencies for modules of $my_author: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* Distributions of other authors recently depending on one of $my_author\'s modules ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  UPDATED_REVERSE_DEPENDENCIES: {
        # skip for now, usually empty. because dep records are usually not
        # updated but recreated.
        last;

        last unless defined $my_author;
        my ($res, $fres);
        require App::lcpan::Cmd::author_rdeps;
        $res = App::lcpan::Cmd::author_rdeps::handle_cmd(
            author=>$my_author, user_authors_arent=>[$my_author], updated_since=>$time,
            phase => 'ALL',
            rel => 'ALL',
        );
        unless ($res->[0] == 200) {
            $org .= "Can't list updated reverse dependencies for modules of $my_author: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* Distributions of other authors which updated dependencies to one of $my_author\'s modules ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

  NEW_MENTIONS: {
        last unless defined $my_author;
        my ($res, $fres);
        require App::lcpan::Cmd::mentions;
        $res = App::lcpan::Cmd::mentions::handle_cmd(
            mentioned_authors=>[$my_author], mentioner_authors_arent=>[$my_author], added_since=>$time,
        );
        unless ($res->[0] == 200) {
            $org .= "Can't list updated reverse dependencies for modules of $my_author: $res->[0] - $res->[1]\n\n";
            last;
        }
        my $num = @{ $res->[2] };
        $org .= "* New mentions to one of $my_author\'s modules ($num)\n";
        $fres = Perinci::Result::Format::Lite::format(
            $res, 'text-pretty', 0, 0);
        $org .= $fres;
        $org .= "\n";
    }

    [200, "OK", $org, {'content_type' => 'text/x-org'}];
}

1;
# ABSTRACT: Show what's added/updated recently

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::whatsnew - Show what's added/updated recently

=head1 VERSION

This document describes version 1.074 of App::lcpan::Cmd::whatsnew (from Perl distribution App-lcpan), released on 2023-09-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show what's addedE<sol>updated recently.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<my_author> => I<str>

My author ID.

If specified, will show additional added/updated items for this author ID
("you"), e.g. what distributions recently added dependency to one of your
modules.

=item * B<update_db_schema> => I<bool> (default: 1)

Whether to update database schema to the latest.

By default, when the application starts and reads the index database, it updates
the database schema to the latest if the database happens to be last updated by
an older version of the application and has the old database schema (since
database schema is updated from time to time, for example at 1.070 the database
schema is at version 15).

When you disable this option, the application will not update the database
schema. This option is for testing only, because it will probably cause the
application to run abnormally and then die with a SQL error when reading/writing
to the database.

Note that in certain modes e.g. doing tab completion, the application also will
not update the database schema.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
