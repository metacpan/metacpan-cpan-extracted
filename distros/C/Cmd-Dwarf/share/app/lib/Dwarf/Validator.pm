package Dwarf::Validator;
use Dwarf::Pragma;
use Carp ();
use Class::Load ();
use Scalar::Util qw/blessed/;
use Dwarf::Validator::Constraint::Default;
use Dwarf::Accessor {
	rw => [qw/query/]
};

our $Rules;
our $FileRules;
our $Filters;

sub import {
	my ($class, @constraints) = @_;
	$class->load_constraints(@constraints);
}

sub load_constraints {
	my $class = shift;
	for (@_) {
		my $constraint = $_;
		$constraint = ($constraint =~ s/^\+//) ? $constraint : "Dwarf::Validator::Constraint::${constraint}";
		Class::Load::load_class($constraint);
	}
}

sub new {
	my ($class, $q) = @_;
	Carp::croak("Usage: ${class}->new(\$q)") unless $q;
	bless { query => $q, _error => {} }, $class;
}

sub check {
	my ($self, @rule_ary) = @_;
	Carp::croak("this is instance method") unless ref $self;
	while (my ($rule_key, $rules) = splice(@rule_ary, 0, 2)) {
		for my $rule (@$rules) {
			my $rule_name = $self->_rule_name($rule);
			my $args      = $self->_rule_args($rule);

			my ($key, @values);
			if ($Dwarf::Validator::FileRules->{$rule_name}) {
				($key, @values) = $self->_extract_uploads_values($rule_key);
				for my $value (@values) {
					local $_ = $value;
					$self->_check_upload($key, $rule_name, $args);
				}
			} else {
				($key, @values) = $self->_extract_parameters_values($rule_key);
				for my $value (@values) {
					local $_ = $value;
					$self->_check_param($key, $rule_name, $args);
				}
			}
		}

		
	}
	return $self;
}

sub _extract_parameters_values {
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

sub _extract_uploads_values {
	my ($self, $key) = @_;
	my $q = $self->{query};
	my @values = $q->uploads->get_all($key);
	@values = undef if @values == 0;
	return ($key, @values);
}

sub _check_param {
	my ($self, $key, $rule_name, $args) = @_;

	#warn "$key: ", $rule_name;

	my $code = $Dwarf::Validator::Rules->{$rule_name} or Carp::croak("unknown rule $rule_name");

	# FILTER でラップ
	if (exists $Dwarf::Validator::Filters->{$rule_name}) {
		unshift @$args, $rule_name;
		$rule_name = 'FILTER';
		$code = $Dwarf::Validator::Rules->{$rule_name};
	}

	my $is_ok = do {
		# FILTER が何か値を返す場合は元の値を上書きする
		if ($rule_name eq 'FILTER') {
			my $value = $code->(@$args);
			$self->_set_param($key, $value) unless ref $value eq 'Dwarf::Validator::NullValue';
			1;
		} elsif ((not (defined $_ && length $_)) && $rule_name !~ /^(NOT_NULL|REQUIRED|NOT_BLANK)$/) {
			1;
		} else {
			$code->(@$args) ? 1 : 0;
		}
	};

	#warn "is_ok: $is_ok";

	if ($is_ok == 0) {
		$self->set_error($key => $rule_name);
	}
}

sub _check_upload {
	my ($self, $key, $rule_name, $args) = @_;

	#warn "upload: ", $rule_name;

	my $is_ok = do {
		if ((not (defined $_ && length $_)) && $rule_name !~ /^(FILE_NOT_NULL)$/) {
			1;
		} else {
			my $file_rule = $Dwarf::Validator::FileRules->{$rule_name} or Carp::croak("unknown rule $rule_name");
			$file_rule->(@$args) ? 1 : 0;
		}
	};

	if ($is_ok == 0) {
		$self->set_error($key => $rule_name);
	}
}

sub _rule_name {
	my ($self, $rule) = @_;
	return ref($rule) ? $rule->[0]	: $rule;
}

sub _rule_args {
	my ($self, $rule) = @_;
	return ref($rule) ? [ @$rule[ 1 .. scalar(@$rule)-1 ] ] : +[];
}

sub _set_param {
	my ($self, $key, $val) = @_;
	$self->{query}->parameters->set($key, $val);
}

sub is_error {
	my ($self, $key) = @_;
	$self->{_error}->{$key} ? 1 : 0;
}

sub is_valid {
	my $self = shift;
	!$self->has_error ? 1 : 0;
}

sub has_error {
	my ($self, ) = @_;
	%{ $self->{_error} } ? 1 : 0;
}

sub set_error {
	my ($self, $param, $rule_name) = @_;
	$self->{_error}->{$param}->{$rule_name}++;
	push @{$self->{_error_ary}}, [$param, $rule_name];
}

sub errors {
	my ($self) = @_;
	$self->{_error};
}

1;