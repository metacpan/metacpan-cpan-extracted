package Data::Sah::Compiler::perl::TH::float;

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Mo qw(build default);
use Role::Tiny::With;

extends 'Data::Sah::Compiler::perl::TH::num';
with 'Data::Sah::Type::float';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-01'; # DATE
our $DIST = 'Data-Sah'; # DIST
our $VERSION = '0.911'; # VERSION

sub handle_type {
    my ($self, $cd) = @_;
    my $c = $self->compiler;

    my $dt = $cd->{data_term};
    if ($cd->{args}{core} || $cd->{args}{no_modules}) {
        $cd->{_ccl_check_type} = "$dt =~ ".'/\A(?:[+-]?(?:0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?|((?i)\s*nan\s*)|((?i)\s*[+-]?inf(inity)?)\s*)\z/';
    } else {
        $c->add_sun_module($cd);
        # we use isnum = isint + isfloat, because isfloat(3) is false
        $cd->{_ccl_check_type} = "$cd->{_sun_module}::isnum($dt)";
    }
}

sub clause_is_nan {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        if ($cd->{args}{core} || $cd->{args}{no_modules}) {
            $c->add_ccl(
                $cd,
                qq[$ct ? lc($dt+0) eq "nan" : defined($ct) ? lc($dt+0) ne "nan" : 1],
            );
        } else {
            $c->add_ccl(
                $cd,
                join(
                    "",
                    "$ct ? $cd->{_sun_module}::isnan($dt) : ",
                    "defined($ct) ? !$cd->{_sun_module}::isnan($dt) : 1",
                )
            );
        }
    } else {
        if ($cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[lc($dt+0) eq "nan"]);
            } else {
                $c->add_ccl($cd, "$cd->{_sun_module}::isnan($dt)");
            }
        } elsif (defined $cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[lc($dt+0) ne "nan"]);
            } else {
                $c->add_ccl($cd, "!$cd->{_sun_module}::isnan($dt)");
            }
        }
    }
}

sub clause_is_neg_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        if ($cd->{args}{core} || $cd->{args}{no_modules}) {
            $c->add_ccl(
                $cd, join(
                    '',
                    qq[$ct ? $dt =~ /\\A\\s*-inf(inity)?\\s*\\z/i : ],
                    qq[defined($ct) ? $dt !~ /\\A\\s*inf(inity)?\\s*\\z/i : 1]
                ));
        } else {
            $c->add_ccl(
                $cd, join(
                    '',
                    "$ct ? $cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt) : ",
                    "defined($ct) ? !($cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt)) : 1",
                ));
        }
    } else {
        if ($cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt =~ /\\A\\s*-inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt)");
            }
        } elsif (defined $cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt !~ /\\A\\s*-inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "!($cd->{_sun_module}::isinf($dt) && $cd->{_sun_module}::isneg($dt))");
            }
        }
    }
}

sub clause_is_pos_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        if ($cd->{args}{core} || $cd->{args}{no_modules}) {
            $c->add_ccl(
                $cd, join(
                    '',
                    qq[$ct ? $dt =~ /\\A\\s*inf(inity)?\\s*\\z/i : ],
                    qq[defined($ct) ? $dt !~ /\\A\\s*inf(inity)?\\s*\\z/i : 1]
                ));
        } else {
            $c->add_ccl(
                $cd, join(
                    '',
                    "$ct ? $cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt) : ",
                    "defined($ct) ? !($cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt)) : 1",
                ));
        }
    } else {
        if ($cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt =~ /\\A\\s*inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt)");
            }
        } elsif (defined $cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt !~ /\\A\\s*inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "!($cd->{_sun_module}::isinf($dt) && !$cd->{_sun_module}::isneg($dt))");
            }
        }
    }
}

sub clause_is_inf {
    my ($self, $cd) = @_;
    my $c  = $self->compiler;
    my $ct = $cd->{cl_term};
    my $dt = $cd->{data_term};

    if ($cd->{cl_is_expr}) {
        if ($cd->{args}{core} || $cd->{args}{no_modules}) {
            $c->add_ccl(
                $cd, join(
                    '',
                    qq[$ct ? $dt =~ /\\A\\s*-?inf(inity)?\\s*\\z/i : ],
                    qq[defined($ct) ? $dt+0 !~ /\\A-?inf\\z/ : 1]
                ));
        } else {
            $c->add_ccl($cd, "$ct ? $cd->{_sun_module}::isinf($dt) : ".
                            "defined($ct) ? $cd->{_sun_module}::isinf($dt) : 1");
        }
    } else {
        if ($cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt =~ /\\A\\s*-?inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "$cd->{_sun_module}::isinf($dt)");
            }
        } elsif (defined $cd->{cl_value}) {
            if ($cd->{args}{core} || $cd->{args}{no_modules}) {
                $c->add_ccl($cd, qq[$dt !~ /\\A\\s*-?inf(inity)?\\s*\\z/i]);
            } else {
                $c->add_ccl($cd, "!$cd->{_sun_module}::isinf($dt)");
            }
        }
    }
}

1;
# ABSTRACT: perl's type handler for type "float"

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Compiler::perl::TH::float - perl's type handler for type "float"

=head1 VERSION

This document describes version 0.911 of Data::Sah::Compiler::perl::TH::float (from Perl distribution Data-Sah), released on 2021-12-01.

=for Pod::Coverage ^(compiler|clause_.+|handle_.+)$

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
