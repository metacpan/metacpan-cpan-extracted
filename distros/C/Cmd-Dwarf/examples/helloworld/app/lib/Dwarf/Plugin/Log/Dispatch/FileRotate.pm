package Dwarf::Plugin::Log::Dispatch::FileRotate;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use Log::Dispatch::FileRotate;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {
		min_level   => 'debug',
		filename    => $c->base_dir . '/log/dwarf.log',
		mode        => 'append',
		TZ          => 'Asia/Tokyo',
		DatePattern => 'yyyy-MM-dd',
	};

	$conf->{min_level} ||= 'debug';
	$conf->{filename}  ||= $c->base_dir . '/log/dwarf_log';
	$conf->{mode}      ||= 'append';

	unless (-f $conf->{filename}) {
		my $dir = dirname($conf->{filename});
		make_path($dir, { mode => 0775 }) unless -d $dir;
	}

	$c->{'dwarf.log'} = Log::Dispatch::FileRotate->new(%$conf);

	add_method($c, log => sub {
		my $self = shift;
		return $self->{'dwarf.log'};
	});

	add_method($c, debug => sub {
		my $self = shift;
		return unless @_;
		my $message = join '', @_;
		unless ($message =~ /\n$/) {
			$message .= "\n";
		}
		$self->{'dwarf.log'}->log(level => 'debug', message => $message);
	});
}

1;
