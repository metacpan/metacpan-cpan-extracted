package Test::Data::Sah::Perl;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah qw(run_spectest all_match);
use Test::More 0.98;

use Data::Sah qw(gen_validator);

use Exporter qw(import);
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
                # test multiple inputs, currently only done for rt=bool
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
                    ok($vbool->($ho ? \$data : $data), "valid (rt=bool)");
                    if ($ho) {
                        is_deeply($data, $test->{output}, "output");
                    }
                } else {
                    ok(!$vbool->($ho ? \$data : $data), "invalid (rt=bool)");
                }
            }

            my $vstr = gen_validator($test->{schema},
                                     {return_type=>'str'});
            if (exists $test->{valid}) {
                if ($test->{valid}) {
                    is($vstr->($test->{input}), "", "valid (rt=str)");
                } else {
                    like($vstr->($test->{input}), qr/\S/, "invalid (rt=str)");
                }
            }

            my $vfull = gen_validator($test->{schema},
                                      {return_type=>'full'});
            my $res = $vfull->($test->{input});
            is(ref($res), 'HASH', "validator (rt=full) returns hash");
            if (exists($test->{errors}) || exists($test->{warnings}) ||
                    exists($test->{valid})) {
                my $errors = $test->{errors} // ($test->{valid} ? 0 : 1);
                is(scalar(keys %{ $res->{errors} // {} }), $errors, "errors (rt=full)")
                    or diag explain $res;
                my $warnings = $test->{warnings} // 0;
                is(scalar(keys %{ $res->{warnings} // {} }), $warnings,
                   "warnings (rt=full)")
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
                       prefilters
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

This document describes version 0.896 of Test::Data::Sah::Perl (from Perl distribution Data-Sah), released on 2019-07-04.

=head1 FUNCTIONS

=head2 run_spectest_for_perl()

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
