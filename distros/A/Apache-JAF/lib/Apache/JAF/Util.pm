package Apache::JAF::Util;

use strict;
use Apache;
use Apache::Util ();

### Content

sub escape_uri {
  my $uri = shift;
  return $uri && Apache::Util::escape_uri($uri);
}

sub unescape_uri {
  my $uri = shift;
  return $uri && Apache::Util::unescape_uri($uri);
}

sub escape_html {
  my $html = shift;
  return $html && Apache::Util::escape_html($html);
}

sub valid_html {
  my $string = shift;
  $string = escape_html($string) if $ENV{MOD_PERL};
  $string =~ s/\</\&lt;/g;
  $string =~ s/\>/\&gt;/g;
  $string =~ s/\n{2,}/<p>/sg;
  $string =~ s/\n/<br>/sg;
  $string = '<p>' . $string;
  return $string;
}

# Navigation
################################################################################
sub get_navigation {
  my ($start, $count, $records_per_page, $navigation_count) = @_;
  
  my $return = { total => $count };
  return $return if($count <= $records_per_page);
  
  for (my ($i,$j) = (0, int -$navigation_count/2); $i < $navigation_count;) {
    last if ($start + $j*$records_per_page > $count);
  
    if ( $start + ($j+1)*$records_per_page > 1 ) {
      push @{$return->{pages}}, {link => ($start + $j*$records_per_page > 0) ? $start + $j*$records_per_page : 1,
                                 selected => !$j,
                                 title =>  (($start + $j*$records_per_page > 0) ? $start + $j*$records_per_page : 1)
                                ."-".
                                 (($start + ($j+1)*$records_per_page - 1 > $count) ? $count : $start + ($j+1)*$records_per_page - 1)};
      $i++
    }
    $j++
  }

  $return->{first} = 1 if($return->{pages}->[0]->{link} > 1);
  $return->{last} = $count - $records_per_page + 1 if($count - $records_per_page >= $return->{pages}->[-1]->{link});
  $return->{prev} = $start - $records_per_page if ($start - $records_per_page > 0);
  $return->{next} = $start + $records_per_page if ($start + $records_per_page <= $count);

  $return;
}

1;
