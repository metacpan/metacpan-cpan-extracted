package Bencher::ScenarioUtil::Completion;

our $DATE = '2016-01-07'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter::Rinci qw(import);

our %SPEC;

$SPEC{make_completion_participant} = {
    v => 1.1,
    summary => 'Create a participant specification to benchmark '.
        'bash completion',
    args => {
        name => {
            summary => 'Participant name',
            schema => 'str*',
            req => 1,
        },
        summary => {
            summary => 'Participant summary',
            schema => 'str*',
        },
        description => {
            summary => 'Participant description',
            schema => 'str*',
        },
        tags => {
            summary => 'Participant tags',
            schema => ['array*', of=>'str*'],
        },
        cmdline => {
            summary => 'Command, with ^ put to mark cursor position',
            schema => 'str*',
            req => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => 'hash*', # XXX participant specification
    },
};
sub make_completion_participant {
    my %args = @_;

    my $res = {name=>$args{name}};
    for (qw/summary description tags/) {
        $res->{$_} = $args{$-} if defined($args{$_});
    }

    unless (defined $res->{summary}) {
        $res->{summary} = 'Run command (with COMP_LINE & COMP_POINT set, "^" marks COMP_POINT): ' . $args{cmdline};
    }

    my $cmd = $args{cmdline};
    my $point;
    if ((my $index = index($cmd, '^')) >= 0) {
        $cmd =~ s/\^//;
        $point = $index;
    } else {
        $cmd .= " " unless $cmd =~ / \z/;
        $point = length($cmd);
    }
    $res->{type} = 'perl_code';
    $res->{code} = sub {
        local $ENV{COMP_LINE} = $cmd;
        local $ENV{COMP_POINT} = $point;
        my $out = `$cmd`;
        die "Backtick fails: $?" if $?;
        $out;
    };

    $res;
}

1;
# ABSTRACT: Utility routines for bash-completion-related Bencher scenarios

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::ScenarioUtil::Completion - Utility routines for bash-completion-related Bencher scenarios

=head1 VERSION

This document describes version 0.02 of Bencher::ScenarioUtil::Completion (from Perl distribution Bencher-ScenarioUtil-Completion), released on 2016-01-07.

=head1 FUNCTIONS


=head2 make_completion_participant(%args) -> hash

Create a participant specification to benchmark bash completion.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cmdline>* => I<str>

Command, with ^ put to mark cursor position.

=item * B<description> => I<str>

Participant description.

=item * B<name>* => I<str>

Participant name.

=item * B<summary> => I<str>

Participant summary.

=item * B<tags> => I<array[str]>

Participant tags.

=back

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-ScenarioUtil-Completion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-ScenarioUtil-Completion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-ScenarioUtil-Completion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
