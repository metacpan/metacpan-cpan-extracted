package Descriptions;

use Attribute::Handlers::Prospective;

my %name;

sub name {
	return $name{$_[2]}||*{$_[1]}{NAME};
}

sub UNIVERSAL::Name :ATTR(RAWDATA) {
	$name{$_[2]} = $_[4];
}

sub UNIVERSAL::Purpose :ATTR(RAWDATA) {
	print STDERR "Purpose of ", &name, " is $_[4]\n";
}

sub UNIVERSAL::Unit :ATTR(RAWDATA) {
	print STDERR &name, " measured in $_[4]\n";
}


1;
