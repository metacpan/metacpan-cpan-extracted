package Algorithm::Diff::JSON;

use strict;
use warnings;

use Algorithm::Diff qw(diff);
use Cpanel::JSON::XS qw(encode_json);

use Sub::Exporter -setup  => { exports => [ 'json_diff' ] };

our $VERSION = '1.000';

sub json_diff {
    my @changes = ();

    foreach my $diff (map { @{$_} } diff(@_)) {
        my($action, $this_line, $content) = @{$diff};
        if(defined($changes[$this_line])) {
            $changes[$this_line] = {
                change => {
                    add    => $content,
                    remove => $changes[$this_line]->{remove}
                }
            };
        } elsif($action eq '+') {
            $changes[$this_line] = { add  => $content };
        } elsif($action eq '-') {
            $changes[$this_line] = { remove => $content };
        }
    }
    return encode_json([
        map { defined($changes[$_]) ? { element => $_, %{$changes[$_]} } : () }
        0 .. $#changes
    ]);
}

=head1 NAME

Algorithm::Diff::JSON - find the differences between two lists and report on them in JSON

=head1 SYNOPSIS

This perl code:

    use Algorithm::Diff::JSON qw(json_diff);

    my $json = json_diff(
        [0,      1, 2, 3, 4, 5,      6],
        ['zero', 1, 2, 3,    5, 5.5, 6]
    );

will generate this JSON:

    [
        { "element": 0, "change": { "remove": 0, "add": "zero" } },
        { "element": 4, "remove": 4 },
        { "element": 5, "add": 5.5 }
    ]

(well, an ugly, minimised, equivalent version of that JSON anyway)

=head1 FUNCTIONS

There is only one function, which is a simple wrapper around L<Algorithm::Diff>'s
C<diff> function:

=head2 json_diff

This takes two list-ref arguments. It returns a JSON array describing the
changes needed to transform the first into the second.

This function may be exported. If you want to export it with a different name
then you can do so:

    use Algorithm::Diff::JSON 'json_diff' => { -as => 'something_else };

Each element in the returned array is a hash. Hashes always have:

=over

=item element

The element number, as given to us by C<Algorithm::Diff>

=back

and will also have exactly one of the following keys:

=over

=item add

The content to add at this location

=item remove

The content to remove from this location

=item change

A hash of both ...

=over

=item add

The content to add at this location

=item remove

The content which that replaces at this location

=back

=back

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism, bug
reports, documentation improvements, and feature requests. The best bug reports
include files that I can add to the test suite, which fail with the current
code in my git repo and will pass once I've fixed the bug

Feature requests are far more likely to get implemented if you submit a patch
yourself.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-Algorithm-Diff-JSON.git>

=head1 SEE ALSO

L<Text::Diff>

L<Algorithm::Diff>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2020 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used, distributed, and
modified under the terms of either the GNU General Public Licence version 2 or
the Artistic Licence. It's up to you which one you use. The full text of the
licences can be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
