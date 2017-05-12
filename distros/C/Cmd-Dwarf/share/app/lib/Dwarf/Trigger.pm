package Dwarf::Trigger;
use Dwarf::Pragma;
use parent qw/Exporter/;
use Scalar::Util ();

our @EXPORT = qw/add_trigger call_trigger get_trigger_code/;

sub add_trigger {
	my ($class, %args) = @_;
	if (ref $class) {
		while (my ($hook, $code) = each %args) {
			next unless ref $code eq 'CODE';
			push @{$class->{_trigger}->{$hook}}, $code;
		}
	} else {
		no strict 'refs';
		while (my ($hook, $code) = each %args) {
			next unless ref $code eq 'CODE';
			push @{${"${class}::_trigger"}->{$hook}}, $code;
		}
	}
}

sub call_trigger {
	my ($class, $hook, @args) = @_;
	my @code = $class->get_trigger_code($hook);
	for my $code (@code) {
		$code->(@args);
	}
}

sub get_trigger_code {
	my ($class, $hook) = @_;
	my @code;
	if (Scalar::Util::blessed($class)) {
		push @code, @{ $class->{_trigger}->{$hook} || [] };
		$class = ref $class;
	}
	no strict 'refs';
	my $klass = ref $class || $class;
	push @code, @{${"${klass}::_trigger"}->{$hook} || []};
	return @code;
}

1;
