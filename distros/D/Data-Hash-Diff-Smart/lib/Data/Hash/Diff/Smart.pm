package Data::Hash::Diff::Smart;

use strict;
use warnings;

use Exporter 'import';
use Data::Hash::Diff::Smart::Engine ();

our @EXPORT_OK = qw(
	diff
	diff_text
	diff_json
	diff_yaml
	diff_test2
);

our $VERSION = '0.01';

=pod

=head1 NAME

Data::Hash::Diff::Smart - Smart structural diff for Perl data structures

=head1 SYNOPSIS

    use Data::Hash::Diff::Smart qw(diff diff_text diff_json diff_yaml diff_test2);

    my $changes = diff($old, $new);

    print diff_text($old, $new);

    my $json = diff_json($old, $new);

    my $yaml = diff_yaml($old, $new);

    diag diff_test2($old, $new);

=head1 DESCRIPTION

C<Data::Hash::Diff::Smart> provides a modern, recursive, configurable diff
engine for Perl data structures. It understands nested hashes, arrays,
scalars, objects, and supports ignore rules, custom comparators, and
multiple array diffing strategies.

The diff engine produces a stable, structured list of change operations,
which can be rendered as text, JSON, YAML, or Test2 diagnostics.

=head1 FUNCTIONS

=head2 diff($old, $new, %opts)

Compute a structural diff between two Perl data structures.

Returns an arrayref of change operations:

    [
        { op => 'change', path => '/user/name', from => 'Nigel', to => 'N. Horne' },
        { op => 'add',    path => '/tags/2',    value => 'admin' },
        { op => 'remove', path => '/debug',     from  => 1 },
    ]

=head3 Options

=over 4

=item * ignore => [ '/path', qr{^/debug}, '/foo/*/bar' ]

Ignore specific paths. Supports exact paths, regexes, and wildcard
segments.

=item * compare => { '/price' => sub { abs($_[0] - $_[1]) < 0.01 } }

Custom comparator callbacks for specific paths.

=item * array_mode => 'index' | 'lcs' | 'unordered'

Choose how arrays are diffed:

=over 4

=item * index - compare by index (default)

=item * lcs - minimal diff using Longest Common Subsequence

=item * unordered - treat arrays as multisets (order ignored)

=back

=back

=head2 diff_text($old, $new, %opts)

Render the diff as a human-readable text format.

=head2 diff_json($old, $new, %opts)

Render the diff as JSON using C<JSON::MaybeXS>.

=head2 diff_yaml($old, $new, %opts)

Render the diff as YAML using C<YAML::XS>.

=head2 diff_test2($old, $new, %opts)

Render the diff as Test2 diagnostics suitable for C<diag>.

=head1 INTERNALS

The diff engine lives in L<Data::Hash::Diff::Smart::Engine>.

=cut

# Core diff
sub diff {
	my ($old, $new, %opts) = @_;
	return Data::Hash::Diff::Smart::Engine::diff($old, $new, %opts);
}

# Text renderer (lazy-loaded)
sub diff_text {
	my ($old, $new, %opts) = @_;
	require Data::Hash::Diff::Smart::Renderer::Text;
	my $changes = diff($old, $new, %opts);
	return Data::Hash::Diff::Smart::Renderer::Text::render($changes);
}

# JSON renderer (lazy-loaded)
sub diff_json {
	my ($old, $new, %opts) = @_;
	require Data::Hash::Diff::Smart::Renderer::JSON;
	my $changes = diff($old, $new, %opts);
	return Data::Hash::Diff::Smart::Renderer::JSON::render($changes);
}

# YAML renderer (lazy-loaded)
sub diff_yaml {
	my ($old, $new, %opts) = @_;
	require Data::Hash::Diff::Smart::Renderer::YAML;
	my $changes = diff($old, $new, %opts);
	return Data::Hash::Diff::Smart::Renderer::YAML::render($changes);
}

sub diff_test2 {
	my ($old, $new, %opts) = @_;
	require Data::Hash::Diff::Smart::Renderer::Test2;
	my $changes = diff($old, $new, %opts);
	return Data::Hash::Diff::Smart::Renderer::Test2::render($changes);
}

1;

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Data-Hash-Diff-Smart>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-data-hash-diff-smart at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Hash-Diff-Smart>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Data::Hash::Diff::Smart

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Data-Hash-Diff-Smart>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Hash-Diff-Smart>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Data-Hash-Diff-Smart>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Data::Hash::Diff::Smart>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
