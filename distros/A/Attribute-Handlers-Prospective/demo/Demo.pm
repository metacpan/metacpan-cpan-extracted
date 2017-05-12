$DB::single = 1;

package Demo;
use Attribute::Handlers::Prospective;

sub Demo : ATTR(ANY) {
	my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
	$data = '<undef>' unless defined $data;
	print STDERR ref($referent), ' ', *{$symbol}{NAME}||$symbol,
		     " ($referent) was ascribed ${attr}\n",
		     "with data (@$data)\nin phase $phase\n";
};

sub This : ATTR(SCALAR) {
	print STDERR "This at ",
		     join(":", map { defined() ? $_ : "" } caller(1)),
		     "\n";
}

sub Multi : ATTR(RAWDATA) {
	my ($package, $symbol, $referent, $attr, $data) = @_;
	$data = '<undef>' unless defined $data;
	print STDERR ref($referent), ' ', *{$symbol}{NAME},
		     " ($referent) was ascribed ${attr} with data ($data)\n";
};

sub ExplMulti : ATTR(ANY) {
	my ($package, $symbol, $referent, $attr, $data) = @_;
	$data = '<undef>' unless defined $data;
	print STDERR ref($referent), ' ', *{$symbol}{NAME},
		     " ($referent) was ascribed ${attr} with data (@$data)\n";
};

1;
