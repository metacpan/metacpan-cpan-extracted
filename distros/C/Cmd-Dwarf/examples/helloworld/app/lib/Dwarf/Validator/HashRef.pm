package Dwarf::Validator::HashRef;
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
	my @values = $q->{$key};
	@values = undef if @values == 0;
	return ($key, @values);
}

sub extract_uploads_values {
	my ($self, $key) = @_;
	my $q = $self->{query};
	my @values;
	@values = undef if @values == 0;
	return ($key, @values);
}

sub set_param {
	my ($self, $key, $val, $index) = @_;
	$self->{query}->{$key} = $val;
}

1;