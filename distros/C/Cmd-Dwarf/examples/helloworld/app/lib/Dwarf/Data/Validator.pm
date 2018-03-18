package Dwarf::Data::Validator;
use Dwarf::Pragma;
use Carp qw(croak);
use Data::Dumper;
use Data::Validator;

sub validate {
	my ($class, $rules, $args) = @_;
	my ($package, $filename, $line, $func) = caller(0);

	for my $key (keys %$rules) {
		if (ref $rules->{$key} eq 'HASH') {
			next unless $rules->{$key}->{isa} =~ 'HashRef';
			next unless ref $rules->{$key}->{rules} eq 'HASH';

			my @args = ($args->{$key});
			@args = @{ $args->{$key} } if ref $args->{$key} eq 'ARRAY';

			for my $arg (@args) {
				# Recursive Support
				next unless $rules->{$key}->{rules};
				next unless ref $arg eq 'HASH';
				Dwarf::Data::Validator->validate($rules->{$key}->{rules}, $arg);
			}

			delete $rules->{$key}->{rules};
			next;
		}

		my $value = $rules->{$key};
		my ($isa, $default) = split /\s*=\s*/, $value;
		
		$value = { isa => $isa };
		$value->{default} = $default if $default;

		if ($isa =~ m/^(.+)\?$/) {
			$value->{isa} = $1 . '|Undef';
			$value->{optional} = 1;

			# Optional でデフォルト値がある場合、バリューが undef ならキー毎削除する
			delete $args->{$key} if $default and not defined $args->{$key};
		}
		
		$rules->{$key} = $value;
	}

	my $validator = Data::Validator->new(%$rules)->with(qw/NoRestricted AllowExtra NoThrow/);
	my @ret = $validator->validate($args);

	if ($validator->has_errors) {
		my $errors = $validator->clear_errors;
		my $error = Dwarf::Data::Validator->handle_errors($package, $rules, $args, $errors);
		croak $error;
	}
	
	return wantarray ? @ret : \@ret;
}

sub handle_errors {
	my ($class, $package, $rules, $args, $errors) = @_;

	my @list;
	push @list, join "", map { $_->{message} } @$errors;
	push @list, '[Package] ' . $package;
	push @list, '[Rules] ' . Dumper($rules);
	push @list, '[Args] ' . Dumper($args);

	for my $i (0 .. 100) {
		my ($package, $filename, $line, $func) = caller($i);
		last unless $func;
		push @list, $func . " at line " . $line;
	}

	return join "\n", @list;
}

1;