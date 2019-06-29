package App::lcpan::Cmd::extract_script;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

use Perinci::Object;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => "Extract a script's latest release file to current directory",
    args => {
        %App::lcpan::common_args,
        %App::lcpan::script_args,
        %App::lcpan::all_args,
    },
    tags => ['write-to-fs'],
};
sub handle_cmd {
    require Archive::Extract;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $script = $args{script};

    my $sth = $dbh->prepare("SELECT
  script.name script,
  file.cpanid author,
  file.name release
FROM script
LEFT JOIN file ON script.file_id=file.id
LEFT JOIN module ON file.id=module.file_id
WHERE script.name=?
GROUP BY file.id
ORDER BY module.version_numified DESC");

    $sth->execute($script);

    my @paths;
    my %mem;
    while (my $row = $sth->fetchrow_hashref) {
        unless ($args{all}) {
            next if $mem{$row->{script}}++;
        }
        push @paths, App::lcpan::_fullpath(
            $row->{release}, $state->{cpan}, $row->{author});
    }

    return [404, "No release for script '$script'"] unless @paths;

    my $envres = envresmulti();
    for my $i (0..$#paths) {
        my $path = $paths[$i];
        (-f $path) or do {
            $envres->add_result(
                404, "File not found: $path",
                {item_id => $path},
            );
            next;
        };
        my $ae = Archive::Extract->new(archive => $path);
        $ae->extract or do {
            $envres->add_result(
                500, "Can't extract: " . $ae->error,
                {item_id => $path},
            );
            next;
        };
        $envres->add_result(
            200, "OK",
            {item_id => $path},
        );
    }
    $envres->as_struct;
}

1;
# ABSTRACT: Extract a script's latest release file to current directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::extract_script - Extract a script's latest release file to current directory

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::extract_script (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Extract a script's latest release file to current directory.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<bool>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<script>* => I<str>

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
