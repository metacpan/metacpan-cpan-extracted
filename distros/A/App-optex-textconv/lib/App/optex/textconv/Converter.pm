package App::optex::textconv::Converter;

use strict;
use warnings;

sub import {
    my $pkg = $_[0];
    my $caller = caller;

    no  strict 'refs';

    if ($pkg eq __PACKAGE__ and @_ > 1 and $_[1] eq "import") {
	*{"$caller\::import"} = \&import;
	return;
    }

    if (@_ > 1) {
	use Exporter ();
	goto &Exporter::import;
    }

    unshift @App::optex::textconv::CONVERTER,
	map { bless $_, __PACKAGE__ } @{"$pkg\::CONVERTER"};
}

sub check    { $_[0]->[0] // die }
sub textize  { $_[0]->[1] // die }
sub validate {
    my $obj = shift;
    @$obj > 2 ? $obj->[2] : sub { 1 };
}

sub treat {
    my $obj = shift;
    local $_ = shift;
    test($obj->check);
}

sub isvalid {
    my $obj = shift;
    local $_ = shift;
    test($obj->validate);
}

sub test {
    my $test = shift;
    if (ref $test eq 'CODE') {
	$test->();
    } else {
	/$test/;
    }
}

1;
