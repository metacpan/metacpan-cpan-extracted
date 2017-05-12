package Catmandu::Fix::sfx_threshold;

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
    "if (is_string(${var})) {" .
        "${var} = ${sfx}->parse_sfx_threshold(${var})" .
    "}";
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::Fix::sfx_threshold - parse the SFX threshold data

  # Map the SFX threshold data
  marc_map('866a','holding.$append')

  # Calculate the content of the holdings
  sfx_threshold(holding.*)

  # If the SFX threshold was something like:
  #
  #  Available from 2013
  #
  # then the holding contains
  #
  # holding => [{
  #     raw => 'Available from 2013' , 
  #     start => {
  #         year => 2013
  #     } , 
  #     end => {} , 
  #     limit => {} , 
  #     years => [ 2013, 2014, .... $current_year ]
  # }]

=head1 DESCRIPTION

The sfx_threshold parses the Ex Libris SFX data for machine processing. 
The result output contains a HASH for every threshold containing the 
following fields:

   * raw          - The unprocessed SFX threshold
   * start.year   - A start year
   * start.volume - A start volume
   * start.issue  - A start issue
   * end.year     - An end year
   * end.volume   - An end volume
   * end.issue    - An end issue
   * limit.num    - Number of year or months if a moving wall is applicable
   * limit.type   - 'year' or 'month'
   * limit.availble - 1, when the holding includes the years/months, 0 otherwise
   * human        - A human understandable string. E.g. 1997 - 2013
   * is_running   - 1, when it is a running subscription, 0 otherwise
   * years        - An array of all years available [ 2001, 2002, 2003 ... ]
   
=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 20145by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
