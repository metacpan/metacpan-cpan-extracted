package Algorithm::Accounting::Report::Text;
use Algorithm::Accounting::Report -Base;
use Perl6::Form;
use FreezeThaw qw(thaw);
use List::Util qw(sum);

our $VERSION = '0.02';

# Do I really have to named it so ?
sub report_occurrence_percentage {
  my ($field,$occhash) = @_;
  my $occ  = $occhash->{$field};
  my $rows = sum(values %$occ);
  my $sep  =  "+===========================================+";
  print form
    $sep,
    "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>>>} |",
       $field,                      'Percentage',
    $sep;

  for(sort {$occ->{$b} <=> $occ->{$a} } keys %$occ) {
    print form
      "| {>>>>>>>>>>>>>>>>>>>>>>>>} | {>>>>>>>>.}% |",
	$_, (100 * $occ->{$_} / $rows) ;
  }
  print form
    $sep,
    '| {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<} |',
    "Total records: $rows",
    $sep, "\n";
}

sub report_field_group_occurrence_percentage {
  my $i = shift; # Only the i-th field group
  my $field_groups = shift;
  my $group_occurrence = shift;
  my @field = @{$field_groups->[$i]};
  my $occ  = $group_occurrence->[$i];
  my $rows = sum(values %$occ);
  local $, = ',';

  my $form_format = '|' . join('|',map {'{<<<<<<<<<<<<}'} @field) . '|{>>>>>>>>>>>>}|';
  my $sep = '+' . '=' x (15*(1+@field) - 1) . '+';
  print form $sep , $form_format, @field, "Percentage",$sep ;
  $form_format =~ s/>>}\|$/.}%|/;
  for(sort { (thaw($a))[0] cmp (thaw($b))[0] } keys %$occ) {
    my @fv = thaw($_);
    print form
      $form_format ,
      @fv, (100 * $occ->{$_} / $rows);
  }
  print form $sep;
  print form
    '|{' . '<' x (15*(1+@field) - 3) . '}|',
    "Total records: $rows",
    $sep, "\n";
}


__DATA__

=head1 NAME

Algorithm::Accounting::Report::Text - generate text version report

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
