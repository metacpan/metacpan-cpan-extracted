package Dwarf::Validator::PlackRequest;
use Dwarf::Pragma;
use Carp ();
use Dwarf::Accessor {
	rw => [qw/query/]
};

sub new {
	my ($class, $q) = @_;
	Carp::croak("Usage: ${class}->new(\$q)") unless $q;
	bless { query => $q }, $class;
}

sub extract_parameters_values {
	my ($self, $key) = @_;

	my $q = $self->{query};
	my @values;
	if (ref $key) {
		$key = [%$key];
		@values = [ map { $q->param($_) } @{ $key->[1] } ];
		$key = $key->[0];
	} else {
		@values = $q->parameters->get_all($key);
		@values = undef if @values == 0;
	}

	return ($key, @values);
}

sub extract_uploads_values {
	my ($self, $key) = @_;
	my $q = $self->{query};
	my @values = $q->uploads->get_all($key);
	@values = undef if @values == 0;
	return ($key, @values);
}

sub set_param {
	my ($self, $key, $val, $index) = @_;
	my @all = $self->{query}->parameters->get_all($key);
	$all[$index] = $val;
	$self->{query}->parameters->set($key, @all);
}

1;