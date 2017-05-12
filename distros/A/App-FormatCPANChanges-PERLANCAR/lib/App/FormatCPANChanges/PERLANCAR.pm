package App::FormatCPANChanges::PERLANCAR;

our $DATE = '2017-02-17'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(max);
use Sort::Sub qw(changes_group_ala_perlancar);

our %SPEC;

$SPEC{format_cpan_changes_perlancar} = {
    v => 1.1,
    summary => 'Format CPAN Changes a la PERLANCAR',
    description => <<'_',

* No preamble.

* Each change is formatted as a separate paragraph (or set of paragraphs).

_
    args => {
        file => {
            schema => 'str*',
            summary => 'If not specified, will look for a file called '.
                'Changes/ChangeLog in current directory',
            pos => 0,
        },
    },
};
sub format_cpan_changes_perlancar {
    require App::ParseCPANChanges;
    #require DateTime::Format::Alami::EN;
    require Text::Wrap;

    my %args = @_;

    my $res = App::ParseCPANChanges::parse_cpan_changes(file => $args{file});
    return $res unless $res->[0] == 200;

    # parse dates and sort releases
    my @rels;
    for my $v (keys %{ $res->[2]{releases} }) {
        my $rel = $res->[2]{releases}{$v};
        # $rel->{_parsed_date} = # assume _parsed_date is already YYYY-MM-DD
        push @rels, $rel;
    }
    @rels = sort { $b->{_parsed_date} cmp $a->{_parsed_date} } @rels;

    # determine the width for version
    my @versions = sort keys %{ $res->[2]{releases} };
    my $v_width = 1 + max map { length } @versions;
    $v_width = 8 if $v_width < 8;

    my $chgs = "";

    # render
    local $Text::Wrap::columns = 80;
    for my $rel (@rels) {
        $chgs .= "\n" if $chgs;

        $chgs .= sprintf "%-${v_width}s%s%s\n\n",
            $rel->{version}, $rel->{_parsed_date}, $rel->{note} ? " $rel->{note}" : "";
        for my $heading (sort {changes_group_ala_perlancar($a,$b)} keys %{ $rel->{changes} }) {
            $chgs .= sprintf "%s%s\n\n", (" " x $v_width), "[$heading]"
                if $heading;
            my $group_changes = $rel->{changes}{$heading};
            for my $ch (@{ $group_changes->{changes} }) {
                $ch .= "." unless $ch =~ /\.$/;
                $chgs .= Text::Wrap::wrap(
                    (" " x $v_width) . "- ",
                    (" " x ($v_width+2)),
                    "$ch\n",
                ) . "\n";
            }
        }
    }

    [200, "OK", $chgs];
}

1;
# ABSTRACT: Format CPAN Changes a la PERLANCAR

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FormatCPANChanges::PERLANCAR - Format CPAN Changes a la PERLANCAR

=head1 VERSION

This document describes version 0.002 of App::FormatCPANChanges::PERLANCAR (from Perl distribution App-FormatCPANChanges-PERLANCAR), released on 2017-02-17.

=head1 FUNCTIONS


=head2 format_cpan_changes_perlancar

Usage:

 format_cpan_changes_perlancar(%args) -> [status, msg, result, meta]

Format CPAN Changes a la PERLANCAR.

=over

=item * No preamble.

=item * Each change is formatted as a separate paragraph (or set of paragraphs).

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<file> => I<str>

If not specified, will look for a file called Changes/ChangeLog in current directory.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FormatCPANChanges-PERLANCAR>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FormatCPANChanges-PERLANCAR>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FormatCPANChanges-PERLANCAR>

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
