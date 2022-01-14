package App::optex::textconv::Converter;

use strict;
no strict 'refs';
use warnings;

sub import {
    my $pkg = $_[0];
    my $caller = caller;

    if ($pkg eq __PACKAGE__ and @_ > 1 and $_[1] eq "import") {
	*{$caller."::import"} = \&import;
	return;
    }

    if (@_ > 1) {
	use Exporter ();
	goto &Exporter::import;
    }

    my $from = \@{$pkg   ."::CONVERTER"};
    my $to   = \@{$caller."::CONVERTER"};
    unshift @$to, @$from;
}

1;
