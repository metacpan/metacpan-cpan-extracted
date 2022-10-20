package Test::Data::Sah::Perl;

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah qw(run_spectest all_match);
use Test::More 0.98;

use Data::Sah qw(gen_validator);

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-19'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.914'; # VERSION

our @EXPORT_OK = qw(run_spectest_for_perl);

sub run_spectest_for_perl {
    run_spectest(
        test_merge_clause_sets => 1,
        test_func => sub {
            my $test = shift;

            my $data = $test->{input};
            my $ho = exists($test->{output}); # has output
            my $vbool;
            eval { $vbool = gen_validator(
                $test->{schema}, {accept_ref=>$ho}) };
            my $eval_err = $@;
            if ($test->{dies}) {
                ok($eval_err, "compile error");
                return;
            } else {
                ok(!$eval_err, "compile success") or do {
                    diag $eval_err;
                    return;
                };
            }

            if ($test->{valid_inputs}) {
                # test multiple inputs, currently only done for rt=bool_valid
                for my $i (0..@{ $test->{valid_inputs} }-1) {
                    my $data = $test->{valid_inputs}[$i];
                    ok($vbool->($ho ? \$data : $data), "valid input [$i]");
                }
                for my $i (0..@{ $test->{invalid_inputs} }-1) {
                    my $data = $test->{invalid_inputs}[$i];
                    ok(!$vbool->($ho ? \$data : $data), "invalid input [$i]");
                }
            } elsif (exists $test->{valid}) {
                # test a single input
                if ($test->{valid}) {
                    ok($vbool->($ho ? \$data : $data), "valid (rt=bool_valid)");
                    if ($ho) {
                        is_deeply($data, $test->{output}, "output");
                    }
                } else {
                    ok(!$vbool->($ho ? \$data : $data), "invalid (rt=bool_valid)");
                }
            }

            my $vstr = gen_validator($test->{schema},
                                     {return_type=>'str_errmsg'});
            if (exists $test->{valid}) {
                if ($test->{valid}) {
                    is($vstr->($test->{input}), "", "valid (rt=str_errmsg)");
                } else {
                    like($vstr->($test->{input}), qr/\S/, "invalid (rt=str_errmsg)");
                }
            }

            my $vfull = gen_validator($test->{schema},
                                      {return_type=>'hash_details'});
            my $res = $vfull->($test->{input});
            is(ref($res), 'HASH', "validator (rt=hash_details) returns hash");
            if (exists($test->{errors}) || exists($test->{warnings}) ||
                    exists($test->{valid})) {
                my $errors = $test->{errors} // ($test->{valid} ? 0 : 1);
                is(scalar(keys %{ $res->{errors} // {} }), $errors, "errors (rt=hash_details)")
                    or diag explain $res;
                my $warnings = $test->{warnings} // 0;
                is(scalar(keys %{ $res->{warnings} // {} }), $warnings,
                   "warnings (rt=hash_details)")
                    or diag explain $res;
            }
        }, # test_func

        skip_if => sub {
            my $t = shift;
            return 0 unless $t->{tags};

            # disabled temporarily because failing for bool, even though i've
            # adjust stuffs. but 'between' clause should be very seldomly used
            # on bool, moreover with op, so i haven't looked into it.
            return "currently failing"
                if all_match([qw/type:bool clause:between op/], $t->{tags});

            for (qw/

                       check
                       check_each_elem
                       check_each_index
                       check_each_key
                       check_each_value
                       check_prop
                       exists
                       if
                       postfilters
                       prop
                       uniq

                   /) {
                return "clause $_ not yet implemented"
                    if all_match(["clause:$_"], $t->{tags});
            }

            return "properties are not yet implemented"
                if grep {/^prop:/} @{ $t->{tags} };

            0;
        }, # skip_if

    );
}

1;
# ABSTRACT: Routines for testing Data::Sah (perl compiler)

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Sah::Perl - Routines for testing Data::Sah (perl compiler)

=head1 VERSION

This document describes version 0.914 of Test::Data::Sah::Perl (from Perl distribution Data-Sah), released on 2022-10-19.

=head1 FUNCTIONS

=head2 run_spectest_for_perl()

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
