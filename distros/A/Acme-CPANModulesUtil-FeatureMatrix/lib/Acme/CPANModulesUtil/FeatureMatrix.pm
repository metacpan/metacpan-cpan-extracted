package Acme::CPANModulesUtil::FeatureMatrix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-29'; # DATE
our $DIST = 'Acme-CPANModulesUtil-FeatureMatrix'; # DIST
our $VERSION = '0.005'; # VERSION

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
    require Data::Sah::Resolve;
    require Data::Sah::Util::Type;
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
    my %note_nums; # text => num
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
                my $rres = Data::Sah::Resolve::resolve_schema(
                    $list->{entry_features}{$fname}{schema} // 'bool'
                );
                my $ftype = $rres->{type};

                my $fvalue0;
                my $fvalue;
                if (!$e->{features} || !defined($e->{features}{$fname})) {
                    $fvalue = "N/A";
                } else {
                    $fvalue0 = $e->{features}{$fname};
                    $fvalue = ref $fvalue0 eq 'HASH' ? $fvalue0->{value} : $fvalue0;
                    $fvalue = !defined($fvalue) ? "N/A" :
                        $ftype eq 'bool' ? ($fvalue ? "yes" : "no") : $fvalue;
                }

                my $has_note;
                my $this_note_num;
                if (ref $fvalue0 eq 'HASH' && $fvalue0->{summary}) {
                    $has_note++;

                    my $note_text = $fvalue0->{summary};
                    if ($fvalue0->{description}) {
                        $note_text .= Markdown::To::POD::markdown_to_pod($fvalue0->{description}) . "\n\n";
                    }

                    if ($this_note_num = $note_nums{$note_text}) {
                        # reuse the same text from another note
                    } else {
                        $note_num++;
                        push @notes, "=item $note_num. $note_text\n\n";
                        $note_nums{$note_text} = $this_note_num = $note_num;
                    }
                }
                push @row, $fvalue . ($has_note ? " *$this_note_num)" : "");
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

This document describes version 0.005 of Acme::CPANModulesUtil::FeatureMatrix (from Perl distribution Acme-CPANModulesUtil-FeatureMatrix), released on 2021-07-29.

=head1 FUNCTIONS


=head2 draw_feature_matrix

Usage:

 draw_feature_matrix(%args) -> [$status_code, $reason, $payload, \%result_meta]

Draw features matrix of modules in an Acme::CPANModules::* list.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpanmodule>* => I<perl::modname>

Name of Acme::CPANModules::* module, without the prefix.


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

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
