package Catmandu::Fix::sfx_year_range;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use Catmandu::SFX;
use Catmandu::Fix::Has;

has path  => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var, $fixer) = @_;
    my $sfx = $fixer->capture(Catmandu::SFX->new());
    "if (is_array_ref(${var})) {" .
        "${var} = ${sfx}->parse_sfx_year_range(${var}); " .
    "}";
}

1;

=encoding utf-8

=head1 NAME

Catmandu::Fix::sfx_year_range - parse the SFX threshold data

  # Parse an array of years into a human reabable string
  # E.g.
  #    holding: 1900 , 1901 , 1902 , 1920 , 1980 , 1981 , 1982
  sfx_year_range(holding)

  # Holding will be:  1900 - 1902 ; 1920 ; 1980 - 1982
   
=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 20145by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut