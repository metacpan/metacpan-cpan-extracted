package Dwarf::Message;
use Dwarf::Pragma;

use overload '""' => \&stringify;

use Dwarf::Accessor {
	rw => [qw/name data/],
};

sub _build_name { 'Dwarf Message' }
sub _build_data { undef }

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless { @_ }, $class;
	return $self;
}

sub stringify {
	my $self = shift;
	my $data = $self->data;
	if (ref $data eq 'ARRAY') {
		$data = join ', ', @{ $data };
	}
	return $data;
}

1;
