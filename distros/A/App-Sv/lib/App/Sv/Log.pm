package App::Sv::Log;

use strict;
use warnings;

use Carp 'croak';
use POSIX;
use AnyEvent::Log;

# Loggers

sub new {
	my ($class, $self) = @_;
	
	$self = ref $self eq 'HASH' ? $self : {};
	bless $self, $class;
	
	return $self->_logger();
}

sub _logger {
	my $self = shift;
	
	my $ctx; $ctx = AnyEvent::Log::Ctx->new(
		title => 'app-sv',
		fmt_cb => sub { $self->_log_format(@_) }
	);
	
	# set output
	if ($self->{file}) {
		$ctx->log_to_file($self->{file});
	}
	elsif (-t \*STDOUT && -t \*STDIN) {
		$ctx->log_cb(sub { print @_ });
	}
	elsif (-t \*STDERR) {
		$ctx->log_cb(sub { print STDERR @_ });
	}
	
	# set log level
	if ($ENV{SV_DEBUG}) {
		$ctx->level(8);
	}
	elsif ($self->{level}) {
		$ctx->level($self->{level});
	}
	else {
		$ctx->level(5);
	}
	
	return $ctx;
}

sub _log_format {
	my ($self, $ts, $ctx, $lvl, $msg) = @_;
	
	my $ts_fmt =  $self->{ts_format} || "%Y-%m-%dT%H:%M:%S%z";
	my @levels = qw(0 fatal alert crit error warn note info debug trace);
	$ts = POSIX::strftime($ts_fmt, localtime((int $ts)[0]));
	
	return "$ts $levels[$lvl] $$ $msg\n"
}

1;
