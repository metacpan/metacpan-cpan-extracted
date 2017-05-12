package Dwarf::Plugin::Log::Dispatch;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Log::Dispatch;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $outputs = $conf->{outputs};
	$outputs ||= [
		[
			'Screen',
			min_level => 'debug',
			stderr    => 1,
        	newline   => 1
        ],
	];

	$c->{'dwarf.log'} = Log::Dispatch->new(outputs => $outputs);

	add_method($c, log => sub {
		my $self = shift;
		return $self->{'dwarf.log'};
	});

	add_method($c, debug => sub {
		my $self = shift;
		return unless @_;
		my $message = '[DWARF] ' . join '', @_;
		$self->{'dwarf.log'}->log(level => 'debug', message => $message);
	});
}

1;
