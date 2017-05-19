use strict;
use warnings;

package Imager::TabularDisplay {
  use Text::TabularDisplay;
  
  sub generate_table {
    my @cols = @{$_[0]};
    my @res = @{$_[1]};

    my $table = Text::TabularDisplay->new(@cols);

    foreach my $row (sort { ($a->prop('date')||'') cmp ($b->prop('date')||'') } @res) {
      my @line = map {
	my $val = $row->prop($_);
	if (ref($val) eq 'ARRAY') {
	  join ',', @$val;
	} else {
	  $val
	}
      } @cols;
      $table->add(@line);
    }
    $table;
  }
}
1;
