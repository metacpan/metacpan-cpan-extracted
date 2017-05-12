package Loud;

use Attribute::Handlers::Prospective;

sub UNIVERSAL::Loud :ATTR(SCALAR,RUN) {
	my ($pkg,$glob,$ref,$data,$phase) = @_;
	tie $$ref, 'Loud', '$'.*{$glob}{NAME};
}

sub TIESCALAR {
	my ($class, $name) = @_;
	print STDERR "creating $name\n";
	bless { name=>$name }
}

sub STORE {
	my ($self, $newval) = @_;
	print STDERR "storing $newval in $self->{name}\n";
	$self->{value} = $newval;
}

sub FETCH {
	my ($self) = @_;
	print STDERR "evaluating $self->{name} (as $self->{value})\n";
	return $self->{value};
}

sub DESTROY {
	my ($self) = @_;
	print STDERR "destroying $self->{name}\n";
}

1;
