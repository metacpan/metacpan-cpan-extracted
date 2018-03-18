package App::Model::Hash;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::DSL;
use Digest::SHA qw/sha256_hex/;
use Scalar::Util qw/looks_like_number/;

use Dwarf::Accessor qw/secret/;

sub init {
	self->{secret} ||= 'this is app\'s hash suffix';
}

sub create {
	my ($self, $value, $prefix, $suffix) = @_;
	$suffix ||= $self->secret;
	return sha256_hex(_create($value, $prefix, $suffix));
}

sub _create {
	my ($value, $prefix, $suffix) = @_;
	die "value must be integer" unless looks_like_number $value;
	$value = abs($value);
	$value = $prefix . $value if defined $prefix;
	$value .= $suffix; 
	return $value;
}

1;
