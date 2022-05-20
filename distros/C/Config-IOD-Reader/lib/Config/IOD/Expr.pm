package Config::IOD::Expr;

use 5.010;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-02'; # DATE
our $DIST = 'Config-IOD-Reader'; # DIST
our $VERSION = '0.345'; # VERSION

my $EXPR_RE = qr{

(?&ANSWER)

(?(DEFINE)

(?<ANSWER>    (?&ADD))
(?<ADD>       (?&MULT)   | (?&MULT)  (?: \s* ([+.-]) \s* (?&MULT)  )+)
(?<MULT>      (?&UNARY)  | (?&UNARY) (?: \s* ([*/x%]) \s* (?&UNARY))+)
(?<UNARY>     (?&POWER)  | [!~+-] (?&POWER))
(?<POWER>     (?&TERM)   | (?&TERM) (?: \s* \*\* \s* (?&TERM))+)

(?<TERM>
    (?&NUM)
  | (?&STR_SINGLE)
  | (?&STR_DOUBLE)
  | undef
  | (?&VAR)
  | (?&FUNC)
  | \( \s* ((?&ANSWER)) \s* \)
)

(?<FUNC> val \s* \( (?&TERM) \))

(?<NUM>
    (
     -?
     (?: 0 | [1-9][0-9]* )
     (?: \. [0-9]+ )?
     (?: [eE] [-+]? [0-9]+ )?
    )
)

(?<VAR> \$[A-Za-z_][A-Za-z0-9_]{0,63})

(?<STR_SINGLE>
    (
     '
     (?:
         [^\\']+
       |
         \\ ['\\]
       |
         \\
     )*
     '
    )
)

(?<STR_DOUBLE>
    (
     "
     (?:
         [^\\"]+
       |
         \\ ["'\\\$tnrfbae]
# octal, hex, wide hex
     )*
     "
    )
)

) # DEFINE

}msx;

sub _parse_expr {
    my $str = shift;

    return [400, 'Not a valid expr'] unless $str =~ m{\A$EXPR_RE\z}o;
    my $res = eval "package Config::IOD::Expr::_Compiled; no strict; no warnings; $str"; ## no critic: BuiltinFunctions::ProhibitStringyEval
    return [500, "Died when evaluating expr: $@"] if $@;
    [200, "OK", $res];
}

1;
# ABSTRACT: Parse expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::IOD::Expr - Parse expression

=head1 VERSION

This document describes version 0.345 of Config::IOD::Expr (from Perl distribution Config-IOD-Reader), released on 2022-05-02.

=head1 SYNOPSIS

See L<Config::IOD::Reader> on how to use expressions in your IOD file.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD-Reader>.

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

This software is copyright (c) 2022, 2021, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
