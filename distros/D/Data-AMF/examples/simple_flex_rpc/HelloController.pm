package HelloController;
use Moose;

sub echo
{
	my ($self, $args) = @_;
	
	return $args;
}

sub list
{
	my ($self, $args) = @_;
	
	my $len = $args->[0] || 1000;
	
	my @result;
	for (1 .. $len) {
		push @result, {
			id => $_,
			name => 'data' . $_,
			description => 'こんにちは。これは AMF から受け取ったデータです。'
		};
	}
	
	return { 'data' => \@result };
}

sub add
{
	my ($self, $args) = @_;
	return $args->[0] . " + " . $args->[1] . " = " . ($args->[0] + $args->[1]);
}


1;
