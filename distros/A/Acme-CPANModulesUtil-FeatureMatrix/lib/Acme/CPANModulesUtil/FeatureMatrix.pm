package Acme::CPANModulesUtil::FeatureMatrix;

our $DATE = '2019-01-12'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our %SPEC;

use Exporter qw(import);
our @EXPORT_OK = qw(draw_feature_matrix);

$SPEC{draw_feature_matrix} = {
    v => 1.1,
    summary => 'Draw features matrix of modules in an Acme::CPANModules::* list',
    args => {
        cpanmodule => {
            summary => 'Name of Acme::CPANModules::* module, without the prefix',
            schema => 'perl::modname*',
            req => 1,
            pos => 0,
            'x.completion' => ['perl_modname' => {ns_prefix=>'Acme::CPANModules'}],
        },
    },
};
sub draw_feature_matrix {
    require Markdown::To::POD;
    require Text::Table::Any;

    my %args = @_;

    my $list;
    my $mod;

    if ($args{_list}) {
        $list = $args{_list};
    } else {
        $mod = $args{cpanmodule} or return [400, "Please specify cpanmodule"];
        $mod = "Acme::CPANModules::$mod" unless $mod =~ /\AAcme::CPANModules::/;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;

        $list = ${"$mod\::LIST"};
    }

    # collect all features mentioned
    my @features;
    for my $e (@{ $list->{entries} }) {
        next unless $e->{features};
        for my $fname (sort keys %{$e->{features}}) {
            push @features, $fname unless grep {$_ eq $fname} @features;
        }
    }

    return [412, "No features mentioned in " . ($mod // "list")]
        unless @features;

    # generate table and collect notes
    my @notes;
    my $note_num = 0;
    my @rows;

  HEADER_ROW:
    {
        my @header_row = ("module");
        for my $fname (@features) {
            my $has_note;
            if ($list->{entry_features} && $list->{entry_features}{$fname} &&
                    $list->{entry_features}{$fname}{summary}) {
                $has_note++;
                $note_num++;
                my $note = "=item $note_num. $fname: " . $list->{entry_features}{$fname}{summary} . "\n\n";
                if ($list->{entry_features}{$fname}{description}) {
                    $note .= Markdown::To::POD::markdown_to_pod($list->{entry_features}{$fname}{description}) . "\n\n";
                }
                push @notes, $note;
            }
            push @header_row, "$fname" . ($has_note ? " *$note_num)" : "");
        }
        push @rows, \@header_row;
    }

  DATA_ROW:
    {
        for my $e (@{ $list->{entries} }) {
            my @row = ($e->{module});
            for my $fname (@features) {
                my $f;
                if (!$e->{features} || !defined($f = $e->{features}{$fname})) {
                    push @row, "N/A";
                    next;
                }
                if (!ref $f) {
                    push @row, $f ? "yes" : "no";
                    next;
                }
                my $fv = defined($f->{value}) ? ($f->{value} ? "yes" : "no") : "N/A";
                my $has_note;
                if ($f->{summary}) {
                    $has_note++;
                    $note_num++;
                    my $note = "=item $note_num. $f->{summary}\n\n";
                    if ($f->{description}) {
                        $note .= Markdown::To::POD::markdown_to_pod($f->{description}) . "\n\n";
                    }
                    push @notes, $note;
                }
                push @row, $fv . ($has_note ? " *$note_num)" : "");
            }
            push @rows, \@row;
        }
    }

    my $res = Text::Table::Any::table(
        rows => \@rows,
        header_row => 1,
    ); $res =~ s/^/ /gm;

    if (@notes) {
        $res .= join(
            "",
            "\n\nNotes:\n\n=over\n\n", @notes, "=back\n\n",
        );
    }

    [200, "OK", $res];
}

1;
# ABSTRACT: Draw features matrix of modules in an Acme::CPANModules::* list

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModulesUtil::FeatureMatrix - Draw features matrix of modules in an Acme::CPANModules::* list

=head1 VERSION

This document describes version 0.002 of Acme::CPANModulesUtil::FeatureMatrix (from Perl distribution Acme-CPANModulesUtil-FeatureMatrix), released on 2019-01-12.

=head1 FUNCTIONS


=head2 draw_feature_matrix

Usage:

 draw_feature_matrix(%args) -> [status, msg, payload, meta]

Draw features matrix of modules in an Acme::CPANModules::* list.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpanmodule>* => I<perl::modname>

Name of Acme::CPANModules::* module, without the prefix.

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

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModulesUtil-FeatureMatrix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModulesUtil-FeatureMatrix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModulesUtil-FeatureMatrix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

C<Acme::CPANModules>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
