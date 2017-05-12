package Config::IOD::Expr;

our $DATE = '2017-01-16'; # DATE
our $VERSION = '0.32'; # VERSION

use 5.010;
use strict;
use warnings;

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
  | (?&FUNC)
  | \( \s* ((?&ANSWER)) \s* \)
)

(?<FUNC> val \s* \( (?&TERM) \))

(?<NUM>
    (
     -?
     (?: 0 | [1-9]\d* )
     (?: \. \d+ )?
     (?: [eE] [-+]? \d+ )?
    )
)

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
    my $res = eval $str;
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

This document describes version 0.32 of Config::IOD::Expr (from Perl distribution Config-IOD-Reader), released on 2017-01-16.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Config-IOD-Reader>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Config-IOD-Reader>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Config-IOD-Reader>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
