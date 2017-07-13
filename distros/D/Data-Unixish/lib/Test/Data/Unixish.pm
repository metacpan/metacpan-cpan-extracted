package Test::Data::Unixish;

use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';

use Data::Unixish qw(aiduxa);
use File::Which qw(which);
use IPC::Cmd qw(run_forked);
use JSON::MaybeXS;
use Module::Load;
use String::ShellQuote;
use Test::More 0.96;

our $VERSION = '1.56'; # VERSION
our $DATE = '2017-07-10'; # DATE

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(test_dux_func);

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
                        if ('itemfunc' ~~ @{$meta->{tags}} &&
                                ref($in) eq 'ARRAY') {
                            if ($t->{skip_itemfunc}) {
                                diag "itemfunc test skipped";
                            } else {
                                my $rout;
                                $rout = aiduxa([$fn, $t->{args}], $in);
                                if ($t->{test_out}) {
                                    $t->{test_out}->($rout);
                                } else {
                                    is_deeply($rout, $out, "out")
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

This document describes version 1.56 of Test::Data::Unixish (from Perl distribution Data-Unixish), released on 2017-07-10.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Unixish>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Unixish>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Unixish>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
