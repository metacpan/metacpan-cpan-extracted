package App::optex::textconv::Converter;

use v5.14;
no strict 'refs';
use warnings;

sub import {
    my $pkg = shift;
    my $callpkg = caller;

    if ($pkg eq __PACKAGE__ and @_ and $_[0] eq "import") {
	*{$callpkg."::import"} = \&import;
	return;
    }

    my $from = \@{"$pkg\::CONVERTER"};
    my $to   = \@{"$callpkg\::CONVERTER"};

    unshift @$to, @$from;
}

1;
