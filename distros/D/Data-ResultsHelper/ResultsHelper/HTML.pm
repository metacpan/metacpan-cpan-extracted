#!/usr/bin/perl -w

package Data::ResultsHelper::HTML;


use vars qw(@ISA);

use Data::ResultsHelper;
@ISA = qw(Data::ResultsHelper);

use strict;

sub new {
  my $type = shift;
  my $class = ref($type) || $type || __PACKAGE__;
  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my @DEFAULT_ARGS = (
    cell_default    => '<td>-i-</td>',
    cell_default_hash => {
      0 => '<td>-NUM-.&nbsp;-0-</td>',
    },
    color_array     => ['#FFFFFF'],
    header_color    => '#FFFFFF',
    header_template => qq|
-table_declaration-
  <tr bgcolor='-header_color-'>
    -header_chunk-
  </tr>
  |,
    results_template  => '-results_chunk-',
    table_declaration => '<table border=0>',
    table_close       => '</table>',
    toc_template => qq|
<table>
  <tr>
    <td>-low- to -high- of -rows-</td>
  </tr>
  <tr>
    <td>-pages- -back_next-</td>
  </tr>
</table>
  |,
    uber_template => qq|
-toc_template-
-header_template-
-results_template-
|,
  );
  my @ARGS = (@DEFAULT_ARGS, @PASSED_ARGS);
  my $self = $class->SUPER::new(@ARGS);
  return $self;
}


sub results2html {
  my $self = shift;
  $self->generate_results_ref;
  my $return = $self->uber_template2html;
  return $return;
}

sub uber_template2html {
  my $self = shift;
  my $uber_template = $self->uber_template;
  $uber_template =~ s/\-(\w+_template)\-/$self->$1/ge;
  $uber_template =~ s/\-(\w+)\-/$self->_uber_helper($1)/ge;
  return $uber_template;
}

sub _uber_helper {
  my $self = shift;
  my $key = shift;
  my $ref = $self->{results_ref};
  my $value = '';
  my $method_value = $self->$key;
  if(defined $method_value) {
    $value = $method_value;
  } elsif($key eq 'pages') {
    my $page_text = $ref->{$self->{prefix} . "_toc_page_text"};
    my $page_href = $ref->{$self->{prefix} . "_toc_page_href"};
    for(my $i=0;$i<@{$page_text};$i++) {
      if($page_href->[$i]) {
        $value .= "<a href=$page_href->[$i]>$page_text->[$i]</a>&nbsp;";
      } else {
        $value .= "$page_text->[$i]&nbsp";
      }
    }
  } elsif($key eq 'back_next') {
    foreach(qw(back next)) {
      my $text = $ref->{$self->{prefix} . "_toc_${_}_text"};
      my $href = $ref->{$self->{prefix} . "_toc_${_}_href"};
      if($href) {
        $value .= "<a href=$href>$text</a>&nbsp;";
      } else {
        $value .= "$text&nbsp;";
      }
    }
  }
  return $value;
}

sub header_chunk {
  my $self = shift;
  my $ref = $self->{results_ref};
  my $header_text = $ref->{$self->{prefix} . "_header_text"};
  my $header_href = $ref->{$self->{prefix} . "_header_href"};
  my $value = '';
  foreach my $i (@{$ref->{"$self->{prefix}_show_cols"}}) {
    if($header_href->[$i]) {
      $value .= "<td><a href=$header_href->[$i]>$header_text->[$i]</a>&nbsp;</td>";
    } else {
      $value .= "<td>$header_text->[$i]&nbsp</td>";
    }
  }
  return $value;
}

sub toc_template {
  my $self = shift;
  return '' if($self->{no_toc});
  return '' if(!$self->second_page && $self->smart_second_page_toc);
  return $self->{toc_template};
}

sub uber_row {
  my $self = shift;
  my $ref = $self->{results_ref};
  unless($self->{uber_row}) {
    $self->{uber_row} = '<tr>';
    my $header_text = $ref->{$self->{prefix} . "_header_text"};
    for(my $i=0;$i<@{$header_text};$i++) {
      my $chunk = ($self->{cell_default_hash} && $self->{cell_default_hash}{$i}) 
        ? $self->{cell_default_hash}{$i} : $self->{cell_default};
      $chunk =~ s/-i-/-$i-/g;
      $self->{uber_row} .= $chunk;
    }
    $self->{uber_row} .= "</tr>\n";
  }
  return $self->{uber_row};
}

sub results_chunk {
  my $self = shift;
  my $return = '';

  my $uber_row = $self->uber_row;
  my $color_array = $self->color_array;
  my $overall_row = 0;
  for(my $i=$self->{prefs}{start_number};$i<=$self->{prefs}{start_number}+$self->{prefs}{at_a_time}-1;$i++) {
    my $row = $self->{results}[$i];
    last unless ref $row;
    if($self->{munge_result_row_code_ref} && ref $self->{munge_result_row_code_ref} eq 'CODE') {
      &{$self->{munge_result_row_code_ref}}($self, $row);
    } elsif($self->can('munge_result_row')) {
      $self->munge_result_row($row);
    }
    $overall_row++;

    for(my $j=0;$j<@{$row};$j++) {
      my $element = \$row->[$j];
      URLDecode($element) if($self->url_decode);
      if($self->time_format && $self->time_format->{$j} && $$element && $$element =~ /^\d+$/) {
        $$element = "<!--$$element-->" . $self->to_char($$element, $self->{time_format}{$j}, $self->gmtime || 1);
      }
    }
    my $chunk = $uber_row;
    $chunk =~ s/-(\d+)-/$row->[$1]/g;
    $chunk =~ s/-num-/$overall_row/g;
    $chunk =~ s/-NUM-/$i/g;

    my $color_index = ($i -1 ) % @{$color_array};
    my $color = $color_array->[$color_index];
    $chunk =~ s/(<tr)/$1 bgcolor=$color/i;

    $return .= $chunk;
  }
  $return .= $self->table_close;
  return $return;
}

1;

__END__

=head1 NAME

Data::ResultsHelper::HTML - sub-classes Data::ResultsHelper to change results to html

=head1 DEFAULTS

  You can set the following options in your object.  The defaults are listed.

    ### what the default cell will look like
    cell_default    => '<td>-i-</td>',
    
    cell_default_hash => {
      0 => '<td>-NUM-.&nbsp;-0-</td>',
    },

    ### an array of alternating colors to use
    color_array     => ['#FFFFFF'],

    ### what color to use for your header row
    header_color    => '#FFFFFF',

    ### the template for your header
    header_template => qq|
-table_declaration-
  <tr bgcolor='-header_color-'>
    -header_chunk-
  </tr>
  |,
    results_template  => '-results_chunk-',
    
    ### opening table tag
    table_declaration => '<table border=0>',

    ### closing table tag
    table_close       => '</table>',

    ### template for the table of contents
    toc_template => qq|
<table>
  <tr>
    <td>-low- to -high- of -rows-</td>
  </tr>
  <tr>
    <td>-pages- -back_next-</td>
  </tr>
</table>
  |,

    ### overall template
    uber_template => qq|
-toc_template-
-header_template-
-results_template-
|,
