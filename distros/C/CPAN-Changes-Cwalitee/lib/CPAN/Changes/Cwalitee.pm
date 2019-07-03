package CPAN::Changes::Cwalitee;

our $DATE = '2019-07-03'; # DATE
our $VERSION = '0.000'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       calc_cpan_changes_cwalitee
                       list_cpan_changes_cwalitee_indicators
               );

our %SPEC;

$SPEC{list_cpan_changes_cwalitee_indicators} = {
    v => 1.1,
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases=>{l=>{}},
        },
        # XXX filter by severity
        # XXX filter by module
        # XXX filter by status
    },
};
sub list_cpan_changes_cwalitee_indicators {
    require PERLANCAR::Module::List;

    my %args = @_;

    my @res;

    my $mods = PERLANCAR::Module::List::list_modules(
        'CPAN::Changes::Cwalitee::', {list_modules=>1, recurse=>1});
    for my $mod (sort keys %$mods) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $spec = \%{"$mod\::SPEC"};
        for my $func (sort keys %$spec) {
            next unless $func =~ /\Aindicator_/;
            my $funcmeta = $spec->{$func};
            (my $name = $func) =~ s/\Aindicator_//;
            my $rec = {
                name => $name,
                summary  => $funcmeta->{summary},
                priority => $funcmeta->{'x.indicator.priority'} // 50,
                severity => $funcmeta->{'x.indicator.severity'} // 3,
                status   => $funcmeta->{'x.indicator.status'} // 'stable',
            };
            if ($args{_return_coderef}) {
                $rec->{code} = \&{"$mod\::$func"};
            }
            push @res, $rec;
        }
    }

    unless ($args{detail}) {
        @res = map { $_->{name} } @res;
    }

    [200, "OK", \@res];
}

$SPEC{calc_cpan_changes_cwalitee} = {
    v => 1.1,
    args => {
        path => {
            schema => 'pathname*',
            req => 1,
            pos => 0,
        },
    },
};
sub calc_cpan_changes_cwalitee {
    require File::Slurper;

    my %args = @_;

    my $res = list_cpan_changes_cwalitee_indicators(
        detail => 1,
        _return_coderef => 1,
    );
    return $res unless $res->[0] == 200;

    my @res;
    my $r = {
        path => $args{path},
        file_content => File::Slurper::read_text($args{path}),
        abstract => $args{abstract},
    };
    my $num_run = 0;
    my $num_success = 0;
    my $num_fail = 0;
    my $parse_attempted;
    for my $ind (sort {
        $a->{priority} <=> $b->{priority} ||
            $a->{name} cmp $b->{name}
        } @{ $res->[2] }) {

        if ($ind->{priority} > 1 && !$parse_attempted++) {
            require CPAN::Changes;
            eval {
                $r->{parsed} = CPAN::Changes->load_string($r->{file_content});
            };
        }

        my $indres = $ind->{code}->(r => $r);
        $num_run++;
        my ($result, $result_summary);
        if ($indres->[0] == 200) {
            if ($indres->[2]) {
                $result = 0;
                $num_fail++;
                $result_summary = $indres->[2];
            } else {
                $result = 1;
                $num_success++;
                $result_summary = '';
            }
        } elsif ($indres->[0] == 412) {
            $result = undef;
            $result_summary = "Cannot be run".($indres->[1] ? ": $indres->[1]" : "");
        } else {
            return [500, "Unexpected result when checking indicator ".
                        "'$ind->{name}': $indres->[0] - $indres->[1]"];
        }
        my $res = {
            num => $num_run,
            indicator => $ind->{name},
            priority => $ind->{priority},
            severity => $ind->{severity},
            summary  => $ind->{summary},
            result => $result,
            result_summary => $result_summary,
        };
        push @res, $res;
    }

    push @res, {
        indicator      => 'Score',
        result         => sprintf("%.2f", $num_run ? ($num_success / $num_run)*100 : 0),
        result_summary => "$num_success out of $num_run",
    };

    [200, "OK", \@res];
}

1;
# ABSTRACT: Calculate the cwalitee of your CPAN Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Cwalitee - Calculate the cwalitee of your CPAN Changes file

=head1 VERSION

This document describes version 0.000 of CPAN::Changes::Cwalitee (from Perl distribution CPAN-Changes-Cwalitee), released on 2019-07-03.

=head1 SYNOPSIS

 use CPAN::Changes::Cwalitee qw(
     calc_cpan_changes_cwalitee
     list_cpan_changes_cwalitee_indicators
 );

 my $res = calc_cpan_changes_cwalitee(
     path => 'Changes',
 );

=head1 DESCRIPTION

B<EARLY RELEASE. CURRENTLY ONLY CONTAINS A MINIMUM SET OF INDICATORS.>

B<What is CPAN Changes cwalitee?> A metric to attempt to gauge the quality of
your CPAN Changes file. Since actual quality is hard to measure, this metric is
called a "cwalitee" instead. The cwalitee concept follows "kwalitee" [1] which
is specifically to measure the quality of CPAN distribution. I pick a different
spelling to avoid confusion with kwalitee. And unlike kwalitee, the unqualified
term "cwalitee" does not refer to a specific, particular subject. There can be
"CPAN Changes cwalitee" (which is handled by this module), "module abstract
cwalitee", and so on.

=head1 FUNCTIONS


=head2 calc_cpan_changes_cwalitee

Usage:

 calc_cpan_changes_cwalitee(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<pathname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_cpan_changes_cwalitee_indicators

Usage:

 list_cpan_changes_cwalitee_indicators(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Changes-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Changes-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Changes-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

[1] L<https://cpants.cpanauthors.org/>

L<App::CPANChangesCwaliteeUtils> for the CLI's.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
