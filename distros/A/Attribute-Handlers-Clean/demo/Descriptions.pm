package Descriptions;
$VERSION = '1.00';

use Attribute::Handlers::Clean;

my %name;

sub name {
	return $name{$_[2]}||*{$_[1]}{NAME};
}

sub Name :ATTR {
	$name{$_[2]} = $_[4];
}

sub Purpose :ATTR {
	print STDERR "Purpose of ", &name, " is $_[4]\n";
}

sub Unit :ATTR {
	print STDERR &name, " measured in $_[4]\n";
}


1;
