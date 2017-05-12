package Algorithm::Accounting::Report::GDGraph;
use Algorithm::Accounting::Report -Base;
use GD::Graph::pie;
use Digest::MD5 qw(md5_hex);
use FreezeThaw qw(thaw);
use List::Util qw(sum);

our $VERSION = '0.01';

sub report_occurrence_percentage {
  my ($field,$occhash) = @_;
  my $occ  = $occhash->{$field};
  my (@labels, @values);
  for(sort {$occ->{$b} <=> $occ->{$a} } keys %$occ) {
      push @labels, $_;
      push @values, $occ->{$_};
  }
  my $graph = GD::Graph::pie->new(640,480);
  my $img = $graph->plot([\@labels,\@values]);
  my $filename = md5_hex($occ);
  $self->save($img,$filename,$graph->export_format);
}

sub report_field_group_occurrence_percentage {
    print STDERR "XXX: Fixme. I don't now how to draw group occurrence into graphs\n";
}

sub save {
    my ($obj,$file,$format) = @_;
    open(IMG, ">${file}.${format}") or die $!;
    binmode IMG;
    print IMG $obj->$format();
    close IMG;
    print STDERR "${file}.${format} saved\n";
}

__DATA__

=head1 NAME

Algorithm::Accounting::Report::GDGraph - generate graph report using GD

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
