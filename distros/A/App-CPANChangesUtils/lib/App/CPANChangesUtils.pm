package App::CPANChangesUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-13'; # DATE
our $DIST = 'App-CPANChangesUtils'; # DIST
our $VERSION = '0.077'; # VERSION

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

our $re_rel_metadata = qr/(?:([A-Za-z]+(?:-[A-Za-z]+)*):\s*([^;]*))/;

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
        parse_release_metadata => {
            summary => 'Whether to parse release metadata in release note',
            schema => 'bool*',
            default => 1,
            description => <<'_',

If set to true (the default), the utility will attempt to parse release metadata
in the release note. The release note is the text after the version and date in
the first line of a release entry:

    0.001 - 2022-06-10 THIS IS THE RELEASE NOTE AND CAN BE ANY TEXT

One convention I use is for the release note to be semicolon-separated of
metadata entries, where each metadata is in the form of HTTP-header-like "Name:
Value" text where Name is dash-separated words and Value is any text that does
not contain newline or semicolon. Example:

    0.001 - 2022-06-10  Urgency: high; Backward-Incompatible: yes

Note that Debian changelog also supports "key=value" in the release line.

This option, when enabled, will first check if the release note is indeed in the
form of semicolon-separated metadata. If yes, will create a key called
C<metadata> in the release result structure containing a hash of metadata:

    { "urgency" => "high", "backward-incompatible" => "yes" }

Note that the metadata names are converted to lowercase.

_
        },
    },
    examples => [
        {
            summary => 'Parse with default settings',
            args => {},
            description => <<'_',

Content of `Changes` file:

    0.077   2022-06-13  Released-By: PERLANCAR; Urgency: low
    
            - No functional changes.
    
            - [ux] Show content of Changes file in example.
    
    
    0.076   2022-06-10  Released-By: PERLANCAR; Urgency: low
    
            - No functional changes.
    
            - [ux] Add an example.
    
    
    0.075   2022-06-10  Released-By: PERLANCAR; Urgency: medium
    
            - [utility parse-cpan-changes] Add option parse_release_metadata
              (defaults to true) to parse 'key: value' metadata in the release
              note.
    
    
    0.073   2021-10-17  Released-By: PERLANCAR; Urgency: medium
    
    	- Rename module/dist App-ParseCPANChanges -> App-CPANChangesUtils.
    
            - Add CLI format-cpan-changes.
    
    
    0.072   2021-05-25  Released-By: PERLANCAR; Urgency: high
    
    	- [build] Rebuild to update Sah coercion module names (old Sah coercion
              modules have been purged from CPAN).
    
    
    0.071   2020-10-06  Released-By: PERLANCAR; Urgency: medium
    
    	- Add option --no-unbless.
    
    
    0.070   2019-07-03  Released-By: PERLANCAR; Urgency: medium
    
    	- Add option --class to customize parser class.
    
    
    0.06    2016-01-18  Released-By: PERLANCAR
    
            - No functional changes.
    
            - [build] Rebuild to fix POD section ordering.
    
    
    0.05    2015-09-03  Released-By: PERLANCAR
    
    	- No functional changes.
    
    	- [dist] Move spec prereqs from RuntimeRequires to
    	  DevelopRecommends to reduce deps but still allow indicating spec
    	  requirement.
    
    
    0.04     2014-07-22  Released-By: SHARYANTO
    
             - No functional changes.
    
             - Switch CLI scripts from using Perinci::CmdLine to
               Perinci::CmdLine::Any to reduce size of dependencies.
    
    
    0.03    2013-11-01  Released-By: SHARYANTO
    
            - No functional changes. Mention some other modules and the rationale
              for the script.
    
    
    0.02    2013-08-06  Released-By: SHARYANTO
    
            - No functional changes. Add missing dep [CT].
    
    
    0.01    2013-08-05  Released-By: SHARYANTO
    
            - First version.

_
        },
    ],
};
sub parse_cpan_changes {
    require Data::Structure::Util;

    my %args = @_;
    my $unbless = $args{unbless} // 1;
    my $parse_release_metadata = $args{parse_release_metadata} // 1;
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

    if ($parse_release_metadata) {
        for my $rel ($ch->releases) {
            my $note = $rel->note;
            if ($note =~ /\A$re_rel_metadata(?:;\s*$re_rel_metadata)*/) {
                my $meta = {};
                while ($note =~ /$re_rel_metadata/g) {
                    $meta->{lc $1} = $2;
                }
                $rel->{metadata} = $meta;
            }
        }
    }

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

This document describes version 0.077 of App::CPANChangesUtils (from Perl distribution App-CPANChangesUtils), released on 2022-06-13.

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

Examples:

=over

=item * Parse with default settings:

 parse_cpan_changes();

Result:

 [
   200,
   "OK",
   {
     months   => {
                   Apr => 4,
                   Aug => 8,
                   Dec => 12,
                   Feb => 2,
                   Jan => 1,
                   Jul => 7,
                   Jun => 6,
                   Mar => 3,
                   May => 5,
                   Nov => 11,
                   Oct => 10,
                   Sep => 9,
                 },
     preamble => "",
     releases => {
                   "0.01"  => {
                                _parsed_date => "2013-08-05",
                                changes      => { "" => { changes => ["First version."], name => "" } },
                                date         => "2013-08-05",
                                metadata     => { "released-by" => "SHARYANTO" },
                                note         => "Released-By: SHARYANTO",
                                version      => 0.01,
                              },
                   "0.02"  => {
                                _parsed_date => "2013-08-06",
                                changes      => {
                                                  "" => {
                                                          changes => ["No functional changes. Add missing dep [CT]."],
                                                          name => "",
                                                        },
                                                },
                                date         => "2013-08-06",
                                metadata     => { "released-by" => "SHARYANTO" },
                                note         => "Released-By: SHARYANTO",
                                version      => 0.02,
                              },
                   "0.03"  => {
                                _parsed_date => "2013-11-01",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "No functional changes. Mention some other modules and the rationale for the script.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2013-11-01",
                                metadata     => { "released-by" => "SHARYANTO" },
                                note         => "Released-By: SHARYANTO",
                                version      => 0.03,
                              },
                   "0.04"  => {
                                _parsed_date => "2014-07-22",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "No functional changes.",
                                                            "Switch CLI scripts from using Perinci::CmdLine to Perinci::CmdLine::Any to reduce size of dependencies.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2014-07-22",
                                metadata     => { "released-by" => "SHARYANTO" },
                                note         => "Released-By: SHARYANTO",
                                version      => 0.04,
                              },
                   "0.05"  => {
                                _parsed_date => "2015-09-03",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "No functional changes.",
                                                            "[dist] Move spec prereqs from RuntimeRequires to DevelopRecommends to reduce deps but still allow indicating spec requirement.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2015-09-03",
                                metadata     => { "released-by" => "PERLANCAR" },
                                note         => "Released-By: PERLANCAR",
                                version      => 0.05,
                              },
                   "0.06"  => {
                                _parsed_date => "2016-01-18",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "No functional changes.",
                                                            "[build] Rebuild to fix POD section ordering.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2016-01-18",
                                metadata     => { "released-by" => "PERLANCAR" },
                                note         => "Released-By: PERLANCAR",
                                version      => 0.06,
                              },
                   "0.070" => {
                                _parsed_date => "2019-07-03",
                                changes      => {
                                                  "" => {
                                                          changes => ["Add option --class to customize parser class."],
                                                          name => "",
                                                        },
                                                },
                                date         => "2019-07-03",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "medium" },
                                note         => "Released-By: PERLANCAR; Urgency: medium",
                                version      => "0.070",
                              },
                   "0.071" => {
                                _parsed_date => "2020-10-06",
                                changes      => { "" => { changes => ["Add option --no-unbless."], name => "" } },
                                date         => "2020-10-06",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "medium" },
                                note         => "Released-By: PERLANCAR; Urgency: medium",
                                version      => 0.071,
                              },
                   "0.072" => {
                                _parsed_date => "2021-05-25",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "[build] Rebuild to update Sah coercion module names (old Sah coercion modules have been purged from CPAN).",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2021-05-25",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "high" },
                                note         => "Released-By: PERLANCAR; Urgency: high",
                                version      => 0.072,
                              },
                   "0.073" => {
                                _parsed_date => "2021-10-17",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "Rename module/dist App-ParseCPANChanges -> App-CPANChangesUtils. - Add CLI format-cpan-changes.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2021-10-17",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "medium" },
                                note         => "Released-By: PERLANCAR; Urgency: medium",
                                version      => 0.073,
                              },
                   "0.075" => {
                                _parsed_date => "2022-06-10",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "[utility parse-cpan-changes] Add option parse_release_metadata (defaults to true) to parse 'key: value' metadata in the release note.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2022-06-10",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "medium" },
                                note         => "Released-By: PERLANCAR; Urgency: medium",
                                version      => 0.075,
                              },
                   "0.076" => {
                                _parsed_date => "2022-06-10",
                                changes      => {
                                                  "" => {
                                                          changes => ["No functional changes.", "[ux] Add an example."],
                                                          name => "",
                                                        },
                                                },
                                date         => "2022-06-10",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "low" },
                                note         => "Released-By: PERLANCAR; Urgency: low",
                                version      => 0.076,
                              },
                   "0.077" => {
                                _parsed_date => "2022-06-13",
                                changes      => {
                                                  "" => {
                                                          changes => [
                                                            "No functional changes.",
                                                            "[ux] Show content of Changes file in example.",
                                                          ],
                                                          name => "",
                                                        },
                                                },
                                date         => "2022-06-13",
                                metadata     => { "released-by" => "PERLANCAR", "urgency" => "low" },
                                note         => "Released-By: PERLANCAR; Urgency: low",
                                version      => 0.077,
                              },
                 },
   },
   {},
 ]

Content of C<Changes> file:

 0.076   2022-06-10  Released-By: PERLANCAR; Urgency: low
 
         - No functional changes.
 
         - [ux] Add an example.
 
 
 0.075   2022-06-10  Released-By: PERLANCAR; Urgency: medium
 
         - [utility parse-cpan-changes] Add option parse_release_metadata
           (defaults to true) to parse 'key: value' metadata in the release
           note.
 
 
 0.073   2021-10-17  Released-By: PERLANCAR; Urgency: medium
 
     - Rename module/dist App-ParseCPANChanges -> App-CPANChangesUtils.
 
         - Add CLI format-cpan-changes.
 
 
 0.072   2021-05-25  Released-By: PERLANCAR; Urgency: high
 
     - [build] Rebuild to update Sah coercion module names (old Sah coercion
           modules have been purged from CPAN).
 
 
 0.071   2020-10-06  Released-By: PERLANCAR; Urgency: medium
 
     - Add option --no-unbless.
 
 
 0.070   2019-07-03  Released-By: PERLANCAR; Urgency: medium
 
     - Add option --class to customize parser class.
 
 
 0.06    2016-01-18  Released-By: PERLANCAR
 
         - No functional changes.
 
         - [build] Rebuild to fix POD section ordering.
 
 
 0.05    2015-09-03  Released-By: PERLANCAR
 
     - No functional changes.
 
     - [dist] Move spec prereqs from RuntimeRequires to
       DevelopRecommends to reduce deps but still allow indicating spec
       requirement.
 
 
 0.04     2014-07-22  Released-By: SHARYANTO
 
          - No functional changes.
 
          - Switch CLI scripts from using Perinci::CmdLine to
            Perinci::CmdLine::Any to reduce size of dependencies.
 
 
 0.03    2013-11-01  Released-By: SHARYANTO
 
         - No functional changes. Mention some other modules and the rationale
           for the script.
 
 
 0.02    2013-08-06  Released-By: SHARYANTO
 
         - No functional changes. Add missing dep [CT].
 
 
 0.01    2013-08-05  Released-By: SHARYANTO
 
         - First version.

=back

This utility is a simple wrapper for L<CPAN::Changes>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<class> => I<perl::modname> (default: "CPAN::Changes")

=item * B<file> => I<filename>

If not specified, will look for file called ChangesE<sol>ChangeLog in current directory.

=item * B<parse_release_metadata> => I<bool> (default: 1)

Whether to parse release metadata in release note.

If set to true (the default), the utility will attempt to parse release metadata
in the release note. The release note is the text after the version and date in
the first line of a release entry:

 0.001 - 2022-06-10 THIS IS THE RELEASE NOTE AND CAN BE ANY TEXT

One convention I use is for the release note to be semicolon-separated of
metadata entries, where each metadata is in the form of HTTP-header-like "Name:
Value" text where Name is dash-separated words and Value is any text that does
not contain newline or semicolon. Example:

 0.001 - 2022-06-10  Urgency: high; Backward-Incompatible: yes

Note that Debian changelog also supports "key=value" in the release line.

This option, when enabled, will first check if the release note is indeed in the
form of semicolon-separated metadata. If yes, will create a key called
C<metadata> in the release result structure containing a hash of metadata:

 { "urgency" => "high", "backward-incompatible" => "yes" }

Note that the metadata names are converted to lowercase.

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

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CPANChangesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
