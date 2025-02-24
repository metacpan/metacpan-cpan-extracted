## no critic: (Modules::ProhibitAutomaticExportation)

package Test::Data::Unixish;

use 5.010001;
use strict;
use warnings;

use Data::Unixish qw(aiduxa);
use Exporter qw(import);
use File::Which qw(which);
use IPC::Cmd qw(run_forked);
use JSON::MaybeXS;
use Module::Load;
use String::ShellQuote;
use Test::More 0.96;

our @EXPORT = qw(test_dux_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-02-24'; # DATE
our $DIST = 'Data-Unixish'; # DIST
our $VERSION = '1.574'; # VERSION


my $json = JSON::MaybeXS->new->allow_nonref;

sub test_dux_func {
    no strict 'refs';

    my %args = @_;
    my $fn  = $args{func};
    my $fnl = $fn; $fnl =~ s/.+:://;
    load "Data::Unixish::$fn";
    my $f = "Data::Unixish::$fn\::$fnl";
    my $spec = \%{"Data::Unixish::$fn\::SPEC"};
    my $meta = $spec->{$fn};

    $meta or die "BUG: func $fn not found or does not have meta";

    my $i = 0;
    subtest $fn => sub {
      TEST:
        for my $t (@{$args{tests}}) {
            $i++;
            my $tn = $t->{name} // "test[$i]";
            subtest $tn => sub {
                if ($t->{skip}) {
                    my $msg = $t->{skip}->();
                    plan skip_all => $msg if $msg;
                }

                # test func
                if ($t->{skip_func}) {
                    diag "func test skipped";
                } else {
                    subtest "func" => sub {
                        my $in   = $t->{in};
                        my $out  = $t->{out};
                        my $rout = [];
                        my $res;
                        eval { $res = $f->(in=>$in,out=>$rout,%{$t->{args}}) };
                        my $err = $@;
                        if ($t->{func_dies} // $t->{dies} // 0) {
                            ok($err, "dies");
                            return;
                        } else {
                            ok(!$err, "doesn't die") or do {
                                diag "func dies: $err";
                                return;
                            };
                        }
                        is($res->[0], 200, "status");
                        if ($t->{test_out}) {
                            $t->{test_out}->($rout);
                        } else {
                            is_deeply($rout, $out, "out")
                            or diag explain $rout;
                        }

                        # if itemfunc, test against each item
                        if ((grep {$_ eq 'itemfunc'} @{$meta->{tags}}) &&
                                ref($in) eq 'ARRAY') {
                            if ($t->{skip_itemfunc}) {
                                diag "itemfunc test skipped";
                            } else {
                                my $rout;
                                $rout = aiduxa([$fn, $t->{args}], $in);
                                if ($t->{test_out}) {
                                    $t->{test_out}->($rout);
                                } else {
                                    is_deeply($rout, $out, "out (itemfunc)")
                                        or diag explain $rout;
                                }
                            }
                        }
                    };
                }

                # test running through cmdline
                if ($t->{skip_cli} // 1) {
                    #diag "cli test skipped";
                } else {
                    subtest cli => sub {
                        if ($^O =~ /win/i) {
                            plan skip_all => "run_forked() not available ".
                                "on Windows";
                            return;
                        }
                        unless (which("dux")) {
                            plan skip_all => "dux command-line not available, ".
                                "you might want to install App::dux first";
                            return;
                        }
                        my $cmd = "dux $fn ".
                            join(" ", map {
                                my $v = $t->{args}{$_};
                                my $p = $_; $p =~ s/_/-/g;
                                ref($v) ?
                                    ("--$p-json",
                                     shell_quote($json->encode($v))) :
                                    ("--$p", shell_quote($v))
                                }
                                     keys %{ $t->{args} });
                        #diag "cmd: $cmd";
                        my %runopts = (
                            child_stdin => join("", map {"$_\n"} @{ $t->{in} }),
                        );
                        my $res = run_forked($cmd, \%runopts);
                        if ($t->{cli_dies} // $t->{dies} // 0) {
                            ok($res->{exit_code}, "dies");
                            return;
                        } else {
                            ok(!$res->{exit_code}, "doesn't die") or do {
                                diag "dux dies ($res->{exit_code})";
                                return;
                            };
                        }
                        is_deeply(join("", map {"$_\n"} @{ $t->{out} }),
                                       $res->{stdout}, "output");
                    }
                }
            };
        }
    };
}

1;
# ABSTRACT: Routines to test Data::Unixish

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Data::Unixish - Routines to test Data::Unixish

=head1 VERSION

This document describes version 1.574 of Test::Data::Unixish (from Perl distribution Data-Unixish), released on 2025-02-24.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
