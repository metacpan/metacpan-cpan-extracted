
package Apache::ASP::CollectionItem;
use strict;

# for support of $Request->QueryString->('foo')->Item() syntax

sub new {
    my($package, $rv) = @_;
    my @items = @$rv;
    bless {
	   'Item' => $items[0],
	   'Items' => \@items,
	   'Count' => defined $items[0] ? scalar(@items) : 0,
	  }, $package;
}

sub Count { shift->{Count} };

sub Item {
    my($self, $index) = @_;
    my $items = $self->{Items};
    
    if(defined $index) {
	$items->[$index-1];
    } else {
	wantarray ? @$items : $items->[0];
    }
}

1;
