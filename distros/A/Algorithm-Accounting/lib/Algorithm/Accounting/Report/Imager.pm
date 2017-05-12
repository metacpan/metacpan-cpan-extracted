package Algorithm::Accounting::Report::Imager;
use Algorithm::Accounting::Report -Base;
use Imager::Graph::Pie;
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
  my $chart = Imager::Graph::Pie->new;
  my $img = $chart->draw(
      labels => \@labels,
      data => \@values,
      size => [640,480],
     );
  my $filename = md5_hex($occ);
  $self->save($img,$filename);
}

sub report_field_group_occurrence_percentage {
  my $i = shift; # Only the i-th field group
  my $field_groups = shift;
  my $group_occurrence = shift;
  my @field = @{$field_groups->[$i]};
  my $occ  = $group_occurrence->[$i];
  my $rows = sum(values %$occ);
}

sub save {
    my ($obj,$file) = @_;
    for my $format (qw (png gif jpg tiff ppm)) {
        if ($Imager::formats{$format}) {
            $obj->write(file=>"${file}.${format}")
                or die $obj->errstr;
            print STDERR "${file}.${format} saved";
            last;
        }
    }
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
