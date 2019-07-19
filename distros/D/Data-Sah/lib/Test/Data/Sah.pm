## no critic: (ControlStructures::ProhibitUnreachableCode)

package Test::Data::Sah;

our $DATE = '2019-07-19'; # DATE
our $VERSION = '0.897'; # VERSION

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Data::Dump qw(dump);
use Data::Sah qw(gen_validator);
use File::chdir;
use File::Slurper qw(read_text);

use Exporter qw(import);
our @EXPORT_OK = qw(
                       test_sah_cases
                       run_spectest
                       all_match
                       any_match
                       none_match
               );

# XXX support js & human testing too
sub test_sah_cases {
    my $tests = shift;
    my $opts  = shift // {};

    my $sah = Data::Sah->new;
    my $plc = $sah->get_compiler('perl');

    my $gvopts = $opts->{gen_validator_opts} // {};
    my $rt = $gvopts->{return_type} // 'bool';

    for my $test (@$tests) {
        my $v = gen_validator($test->{schema}, $gvopts);
        my $res = $v->($test->{input});
        my $name = $test->{name} //
            "data " . dump($test->{input}) . " should".
                ($test->{valid} ? " pass" : " not pass"). " schema " .
                    dump($test->{schema});
        my $testres;
        if ($test->{valid}) {
            if ($rt eq 'bool') {
                $testres = ok($res, $name);
            } elsif ($rt eq 'str') {
                $testres = is($res, "", $name) or diag explain $res;
            } elsif ($rt eq 'full') {
                $testres = is(~~keys(%{$res->{errors}}), 0, $name) or diag explain $res;
            }
        } else {
            if ($rt eq 'bool') {
                $testres = ok(!$res, $name);
            } elsif ($rt eq 'str') {
                $testres = isnt($res, "", $name) or diag explain $res;
            } elsif ($rt eq 'full') {
                $testres = isnt(~~keys(%{$res->{errors}}), 0, $name) or diag explain $res;
            }
        }
        next if $testres;

        # when test fails, show the validator generated code to help debugging
        my $cd = $plc->compile(schema => $test->{schema});
        diag "schema compilation result:\n----begin generated code----\n",
            explain($cd->{result}), "\n----end generated code----\n",
                "that code should return ", ($test->{valid} ? "true":"false"),
                    " when fed \$data=", dump($test->{input}),
                        " but instead returns ", dump($res);

        # also show the result for return_type=full
        my $vfull = gen_validator($test->{schema}, {return_type=>"full"});
        diag "\nvalidator result (full):\n----begin result----\n",
            explain($vfull->($test->{input})), "----end result----";
    }
}

sub _decode_json {
    state $json = do {
        require JSON;
        JSON->new->allow_nonref;
    };
    $json->decode(@_);
}

sub run_spectest {
    require File::ShareDir;
    require File::ShareDir::Tarball;
    require Sah;

    my %args = @_;

    my $sah = Data::Sah->new;

    my $dir;
    if (version->parse($Sah::VERSION) == version->parse("0.9.27")) {
        # this version of Sah temporarily uses ShareDir instead of
        # ShareDir::Tarball due to garbled output problem of tarball.
        $dir = File::ShareDir::dist_dir("Sah");
    } else {
        $dir = File::ShareDir::Tarball::dist_dir("Sah");
    }
    $dir && (-d $dir) or die "Can't find spectest, have you installed Sah?";
    (-f "$dir/spectest/00-normalize_schema.json")
        or die "Something's wrong, spectest doesn't contain the correct files";

    my @specfiles;
    {
        local $CWD = "$dir/spectest";
        @specfiles = glob("*.json");
    }

    # to test certain files only
    my @files;
    if ($ENV{TEST_SAH_SPECTEST_FILES}) {
        @files = split /\s*,\s*|\s+/, $ENV{TEST_SAH_SPECTEST_FILES};
    } else {
        @files = @ARGV;
    }

    # to test certain types only
    my @types;
    if ($ENV{TEST_SAH_SPECTEST_TYPES}) {
        @types = split /\s*,\s*|\s+/, $ENV{TEST_SAH_SPECTEST_TYPES};
    }

    # to test only tests that have all matching tags
    my @include_tags;
    if ($ENV{TEST_SAH_SPECTEST_INCLUDE_TAGS}) {
        @include_tags = split /\s*,\s*|\s+/,
            $ENV{TEST_SAH_SPECTEST_INCLUDE_TAGS};
    }

    # to skip tests that have all matching tags
    my @exclude_tags;
    if ($ENV{TEST_SAH_SPECTEST_EXCLUDE_TAGS}) {
        @exclude_tags = split /\s*,\s*|\s+/,
            $ENV{TEST_SAH_SPECTEST_EXCLUDE_TAGS};
    }

    my $code_test_excluded = sub {
        my $test = shift;

        if ($test->{tags} && @exclude_tags) {
            if (any_match(\@exclude_tags, $test->{tags})) {
                return "contains excluded tag(s) (".
                    join(", ", @exclude_tags).")";
            }
        }
        if (@include_tags) {
            if (!all_match(\@include_tags, $test->{tags} // [])) {
                return "does not contain all include tags (".
                    join(", ", @include_tags).")";
            }
        }
        "";
    };

    {
        use experimental 'smartmatch';

        last unless $args{test_normalize_schema};

        for my $file ("00-normalize_schema.json") {
            unless (!@files || $file ~~ @files) {
                diag "Skipping file $file";
                next;
            }
            subtest $file => sub {
                my $tspec = _decode_json(~~read_text("$dir/spectest/$file"));
                for my $test (@{ $tspec->{tests} }) {
                    subtest $test->{name} => sub {
                        if (my $reason = $code_test_excluded->($test)) {
                            plan skip_all => "Skipping test $test->{name}: $reason";
                            return;
                        }
                        eval {
                            is_deeply(normalize_schema($test->{input}),
                                      $test->{result}, "result");
                        };
                        my $eval_err = $@;
                        if ($test->{dies}) {
                            ok($eval_err, "dies");
                        } else {
                            ok(!$eval_err, "doesn't die")
                                or diag $eval_err;
                        }
                    };
                }
                ok 1; # an extra dummy ok to pass even if all spectest is skipped
            };
        }
    }

    {
        use experimental 'smartmatch';

        last unless $args{test_merge_clause_sets};

        for my $file ("01-merge_clause_sets.json") {
            last; # we currently remove _merge_clause_sets() from Data::Sah
            unless (!@files || $file ~~ @files) {
                diag "Skipping file $file";
                next;
            }
            subtest $file => sub {
                my $tspec = _decode_json(~~read_text("$dir/spectest/$file"));
                for my $test (@{ $tspec->{tests} }) {
                    subtest $test->{name} => sub {
                        if (my $reason = $code_test_excluded->($test)) {
                            plan skip_all => "Skipping test $test->{name}: $reason";
                            return;
                        }
                        eval {
                            is_deeply($sah->_merge_clause_sets(@{ $test->{input} }),
                                      $test->{result}, "result");
                        };
                        my $eval_err = $@;
                        if ($test->{dies}) {
                            ok($eval_err, "dies");
                        } else {
                            ok(!$eval_err, "doesn't die")
                                or diag $eval_err;
                        }
                    };
                }
                ok 1; # an extra dummy ok to pass even if all spectest is skipped
            };
        }
    }

    {
        use experimental 'smartmatch';

        for my $file (grep {/^10-type-/} @specfiles) {
            unless (!@files || $file ~~ @files) {
                diag "Skipping file $file";
                next;
            }
            subtest $file => sub {
                diag "Loading $file ...";
                my $tspec = _decode_json(~~read_text("$dir/spectest/$file"));
                note "Test version: ", $tspec->{version};
                my $tests = $tspec->{tests};
                if ($args{tests_func}) {
                    $args{tests_func}->($tests, {
                        parent_args => \%args,
                        code_test_excluded => $code_test_excluded,
                    });
                } elsif ($args{test_func}) {
                    for my $test (@$tests) {
                        my $skip_reason;
                        {
                            if ($args{skip_if}) {
                                $skip_reason = $args{skip_if}->($test);
                                last if $skip_reason;
                            }
                            $skip_reason = $code_test_excluded->($test);
                            last if $skip_reason;
                        }
                        my $tname = "(tags=".join(", ", sort @{ $test->{tags} // [] }).
                            ") $test->{name}";
                        if ($skip_reason) {
                            diag "Skipping test $tname: $skip_reason";
                            next;
                        }
                        note explain $test;
                        subtest $tname => sub {
                            $args{test_func}->($test);
                        };
                    } # for $test
                    ok 1; # an extra dummy ok to pass even if all spectest is skipped
                } else {
                    die "Please specify 'test_func' or 'tests_func'";
                }
            }; # subtest $file
        } # for $file
    }

}

sub all_match {
    use experimental 'smartmatch';

    my ($list1, $list2) = @_;

    for (@$list1) {
        return 0 unless $_ ~~ @$list2;
    }
    1;
}

sub any_match {
    use experimental 'smartmatch';

    my ($list1, $list2) = @_;

    for (@$list1) {
        return 1 if $_ ~~ @$list2;
    }
    0;
}

sub none_match {
    use experimental 'smartmatch';

    my ($list1, $list2) = @_;

    for (@$list1) {
        return 0 if $_ ~~ @$list2;
    }
    1;
}

1;
# ABSTRACT: Test routines for Data::Sah

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Sah - Test routines for Data::Sah

=head1 VERSION

This document describes version 0.897 of Test::Data::Sah (from Perl distribution Data-Sah), released on 2019-07-19.

=head1 FUNCTIONS

=head2 test_sah_cases(\@tests)

=head2 run_spectest(\@tests, \%opts)

=head2 all_match(\@array1, \@array2) => bool

A utility routine. Probably will be moved to another module in the future.

Return true if all of the elements in C<@array1> is in C<@array2>.

=head2 any_match(\@array1, \@array2) => bool

A utility routine. Probably will be moved to another module in the future.

Return true if any element in C<@array1> is in C<@array2>.

=head2 none_match(\@array1, \@array2) => bool

A utility routine. Probably will be moved to another module in the future.

Return true if none of the elements in C<@array1> is in C<@array2>.

=head1 ENVIRONMENT

=head2 TEST_SAH_SPECTEST_FILES => str

Comma-separated list of files in spectest to test. Default is all files. If you
only want to test certain spectest files, use this.

=head2 TEST_SAH_SPECTEST_TYPES => str

Comma-separated list of types to test. Default is all types. If you only want to
test certain types, use this.

=head2 TEST_SAH_SPECTEST_INCLUDE_TAGS => str

Comma-separated list of tags to include. If you only want to include tests that
have certain tags, use this.

=head2 TEST_SAH_SPECTEST_EXCLUDE_TAGS => str

Comma-separated list of tags to exclude. If you want to exclude tests that have
certain tags, use this.

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
