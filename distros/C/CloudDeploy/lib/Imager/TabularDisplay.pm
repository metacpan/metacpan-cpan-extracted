use strict;
use warnings;

package Imager::TabularDisplay {
  use Text::ASCIITable;

  sub print_table {
    my $t = generate_table(@_);
    print $t;
  }
  
  sub generate_table {
    my @cols = @{$_[0]};
    my @res = @{$_[1]};

    my $table = Text::ASCIITable->new;

    $table->setCols(@cols);

    foreach my $row (sort { ($a->prop('date')||'') cmp ($b->prop('date')||'') } @res) {
      my @line = map {
	my $val = $row->prop($_);
	if (ref($val) eq 'ARRAY') {
	  join ',', @$val;
	} else {
	  $val
	}
      } @cols;
      $table->addRow(@line);
    }
    $table;
  }
}
1;
