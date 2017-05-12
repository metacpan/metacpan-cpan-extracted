package Test::Data::Sah::JS;

our $DATE = '2016-09-14'; # DATE
our $VERSION = '0.87'; # VERSION

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah qw(run_spectest all_match);
use Test::More 0.98;

use Capture::Tiny qw(tee_merged);
use Data::Sah qw(gen_validator);
use File::Temp qw(tempdir tempfile);
use Nodejs::Util qw(get_nodejs_path);
use String::Indent qw(indent);

use Exporter qw(import);
our @EXPORT_OK = qw(run_spectest_for_js);

sub _encode_json {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->allow_nonref;
    };
    $json->encode(@_);
}

sub run_spectest_for_js {
    my %args = @_;

    run_spectest(
        tests_func => sub {
            my ($tests, $opts) = @_;

            # we compile all the schemas (plus some control code) to a single js
            # file then execute it using nodejs. the js file is supposed to
            # produce TAP output.

            my $node_path = $opts->{node_path} // $args{nodejs_path} //
                get_nodejs_path();
            my $sah = Data::Sah->new;
            my $js = $sah->get_compiler('js');

            my %names; # key: json(schema)
            my %counters; # key: type name

            my @js_code;

            # controller/tap code
            push @js_code, <<'_';
String.prototype.repeat = function(n) { return new Array(isNaN(n) ? 1 : ++n).join(this) }

// BEGIN TAP

var indent = "    "
var tap_indent_level = 2
var tap_counter = 0
var tap_num_nok = 0

function tap_esc(name) {
    return name.replace(/#/g, '\\#').replace(/\n/g, '\n' + indent.repeat(tap_indent_level+1) + '#')
}

function tap_print_oknok(is_ok, name) {
    if (!is_ok) tap_num_nok++
    console.log(
        indent.repeat(tap_indent_level) +
        (is_ok ? "ok " : "not ok ") +
        ++tap_counter +
        (name ? " - " + tap_esc(name) : "")
    )
}

function tap_print_summary() {
    if (tap_num_nok > 0) {
        console.log(indent.repeat(tap_indent_level) + '# ' + tap_num_nok + ' failed test(s)')
    }
    console.log(
        indent.repeat(tap_indent_level) + "1.." + tap_counter
    )
}

function ok(cond, name) {
    tap_print_oknok(cond, name)
}

function subtest(name, code) {
     var save_counter = tap_counter
     var save_num_nok = tap_num_nok

     tap_num_nok = 0
     tap_counter = 0
     tap_indent_level++
     code()
     tap_print_summary()
     tap_indent_level--

     tap_counter       = save_counter
     var save2_num_nok = tap_num_nok
     tap_num_nok = save_num_nok
     tap_print_oknok(save2_num_nok == 0, name)
}

function done_testing() {
    tap_print_summary()
}

// END TAP

var res;

_

          TEST:
            for my $test (@$tests) {
                my $tname = "(tags=".join(", ", sort @{ $test->{tags} // [] }).
                    ") $test->{name}";
                if ($opts->{parent_args}{skip_if} &&
                        (my $reason = $opts->{parent_args}{skip_if}->($test))) {
                    diag "Skipping test $tname: $reason";
                    next TEST;
                }
                if ($opts->{code_test_excluded} &&
                        (my $reason = $opts->{code_test_excluded}->($test))) {
                    diag "Skipping test $tname: $reason";
                    next TEST;
                }
                my $k = _encode_json($test->{schema});
                my $ns = $sah->normalize_schema($test->{schema});
                $test->{nschema} = $ns;

                my $fn = $names{$k};
                if (!$fn) {
                    $fn = "sahv_" . $ns->[0] . ++$counters{$ns->[0]};
                    $names{$k} = $fn;

                    push @js_code, "\n\n",
                        indent("// ", "schema: " . _encode_json($ns)), "\n\n";

                    for my $rt (qw/bool str full/) {
                        my $code;
                        eval {
                            $code = $js->expr_validator_sub(
                                schema => $ns,
                                schema_is_normalized => 1,
                                return_type => $rt,
                            );
                        };
                        my $err = $@;
                        if ($test->{dies}) {
                            #note "schema = ", explain($ns);
                            ok($err, $tname);
                            next TEST;
                        } else {
                            ok(!$err, "compile ok ($tname}, $rt)") or do {
                                diag $err;
                                next TEST;
                            };
                        }
                        push @js_code, "var $fn\_$rt = $code;\n\n";
                    } # rt
                }

                push @js_code,
                    "subtest("._encode_json($tname).", function() {\n";

                # bool
                if ($test->{valid_inputs}) {
                    # test multiple inputs, currently done for rt=bool only
                    for my $i (0..@{ $test->{valid_inputs} }-1) {
                        my $data = $test->{valid_inputs}[$i];
                        push @js_code,
                            "    ok($fn\_bool("._encode_json($data).")".
                            ", 'valid input [$i]');\n";
                    }
                    for my $i (0..@{ $test->{invalid_inputs} }-1) {
                        my $data = $test->{invalid_inputs}[$i];
                        push @js_code,
                            "    ok(!$fn\_bool("._encode_json($data).")".
                            ", 'invalid input [$i]');\n";
                    }
                } elsif (exists $test->{valid}) {
                    if ($test->{valid}) {
                        # XXX test output
                        push @js_code,
                            "    ok($fn\_bool("._encode_json($test->{input}).")".
                            ", 'valid (rt=bool)');\n";
                    } else {
                        push @js_code,
                            "    ok(!$fn\_bool("._encode_json($test->{input}).")".
                            ", 'invalid (rt=bool)');\n";
                    }
                }

                # str
                if (exists $test->{valid}) {
                    if ($test->{valid}) {
                        push @js_code,
                            "    ok($fn\_str("._encode_json($test->{input}).")".
                            "=='', 'valid (rt=str)');\n";
                    } else {
                        push @js_code,
                            "    ok($fn\_str("._encode_json($test->{input}).")".
                            ".match(/\\S/), 'invalid (rt=str)');\n";
                    }
                }

                # full
                if (exists($test->{errors}) || exists($test->{warnings}) ||
                        exists($test->{valid})) {
                    my $errors   = $test->{errors} // ($test->{valid} ? 0 : 1);
                    my $warnings = $test->{warnings} // 0;
                    push @js_code, (
                        "    res = $fn\_full("._encode_json($test->{input}).");\n",
                        "    ok(typeof(res)=='object', ".
                            "'validator (rt=full) returns object');\n",
                        "    ok(Object.keys(res['errors']   ? res['errors']   : {}).length==$errors, 'errors (rt=full)');\n",
                        "    ok(Object.keys(res['warnings'] ? res['warnings'] : {}).length==$warnings, ".
                            "'warnings (rt=full)');\n",
                    );
                }

                push @js_code, "});\n\n";
            } # for test

            push @js_code, <<'_';
done_testing();
process.exit(code = tap_num_nok == 0 ? 0:1);
_

            state $tempdir = tempdir();
            my ($jsh, $jsfn) = tempfile('jsXXXXXXXX', DIR=>$tempdir);
            note "js filename $jsfn";
            print $jsh @js_code;

            # finally we execute the js file, which should produce TAP
            my ($status, $errno);
            my ($merged, @result) = tee_merged {
                system($node_path, $jsfn);
                ($status, $errno) = ($?, $!);
            };
            # when node fails, we want to know the actual output
            ok(!$status, "js file executed successfully")
                or diag "output=<<$merged>>, exit status (\$?)=$status, ".
                "errno (\$!)=$errno, result=", explain(@result);
        }, # tests_func

        skip_if => sub {
            my $t = shift;
            return 0 unless $t->{tags};

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

            for (qw/isa/) {
                return "obj clause $_ not yet implemented"
                    if all_match(["type:obj", "clause:$_"], $t->{tags});
            }

            return "properties are not yet implemented"
                if grep {/^prop:/} @{ $t->{tags} };

            0;
        },
    );
}

1;
# ABSTRACT: Routines for testing Data::Sah (js compiler)

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Sah::JS - Routines for testing Data::Sah (js compiler)

=head1 VERSION

This document describes version 0.87 of Test::Data::Sah::JS (from Perl distribution Data-Sah-JS), released on 2016-09-14.

=head1 FUNCTIONS

=head2 run_spectest_for_js()

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-JS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-JS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-JS>

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
