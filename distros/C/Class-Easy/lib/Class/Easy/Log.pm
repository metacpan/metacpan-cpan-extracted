package Class::Easy::Log;
# $Id: Log.pm,v 1.3 2009/07/20 18:00:10 apla Exp $

use Class::Easy::Import;
use Class::Easy::Log::Tie;
use Class::Easy ();

# log4perl has categories, layouts and appenders
our $default_layout = '[%P] [%M(%L)] [%c] %m%n';

Class::Easy::make_accessor (__PACKAGE__, 'category');
Class::Easy::make_accessor (__PACKAGE__, 'tied');
Class::Easy::make_accessor (__PACKAGE__, 'layout');

my $driver_config = {};
our $int_loggers   = {
	default => bless {
		category => 'default', broker => '', tied => 0
	}, __PACKAGE__
};

my $java_mappings = {
	L => 'line',
	P => 'pid',
	r => 'ts_start',
	R => 'ts_log',
	c => 'category',
	C => 'package',
	d => 'date',
	F => 'file',
	H => 'hostname',
	l => 'where',
	m => 'message',
	M => 'method',
	n => 'newline',
	p => 'priority',
	T => 'stack',
};

our $hostname;
if (Class::Easy::try_to_use ('Sys::Hostname')) {
	$hostname = Sys::Hostname->can('hostname')->();
}

Class::Easy::Log->configure_driver (
	id => 'log4perl', package => 'Log::Log4perl', constructor => 'get_logger',
	log => 'debug', # default logging level
	
);

# basic logger:    logger ('sql');
# log4perl logger: logger (log4perl => 'sql');
# also you'll need to configure log4perl somewhere:
# Log::Log4perl::init (...);
# Class::Easy::Log->configure_driver (
#	type => 'log4perl', package => 'Log::Log4perl', constructor => 'get_logger'
# );

sub configure_driver {
	my $class = shift;
	my $params = {@_};
	
	if (Class::Easy::try_to_use ($params->{package})) {
		$driver_config->{$params->{id}} = $params;
	}
}

sub logger { # create logger
	
	my $driver_id;
	my $category;
	my $appender;
	
	my $ref;
	
	if (defined $_[1]) {
		$ref = ref \$_[1];
	}
	
	unless (@_) { # if type omitted, we use current package name as type
		$category = (caller)[0];
	} elsif (scalar (@_) == 2 and $ref eq 'GLOB' and defined *{$_[1]}{IO}) {
		$category = $_[0];
		$appender = $_[1];
	} elsif ((@_ == 2 or @_ == 1) and exists $driver_config->{$_[0]}) {
		$driver_id = $_[0];
		$category = @_ == 1 ? (caller)[0] : $_[1];
	} elsif (@_ == 1) {
		$category = $_[0];
	} else {
		die "you must use logger (), logger (driver), logger (category) or logger (driver => category)";
	}
	
	my $self;
	
	unless (defined $driver_id) { # basic internal driver require no processing
		
		my $existing_logger = $int_loggers->{$category};
		
		$self = $existing_logger || bless {
			category => $category,
			broker   => '',
		}, 'Class::Easy::Log';
		
		unless (defined $existing_logger) {
			$int_loggers->{$category} = $self;
			
			Class::Easy::make_accessor ((caller)[0], 'log_'.$category, default => sub {
				my $caller1  = [caller (1)];
				my $caller0  = [caller];

				unshift @_, $category, $self, $caller1, $caller0;
				goto &_wrapper;
			});

			Class::Easy::make_accessor ((caller)[0], 'timer_'.$category, default => sub {
				Class::Easy::Timer->new (@_, $self)
			});
		}

	} elsif (defined $driver_config->{$driver_id}) { # driver defined
		my $driver = $driver_config->{$driver_id};
		$self = $driver->{package}->can ($driver->{constructor})->($driver->{package}, $category);

		Class::Easy::make_accessor ((caller)[0], 'log_'.$category, default => sub {
			goto &{$self->can ($driver->{log})};
		});
		
		# make_accessor ((caller)[0], 'log_'.$type, default => \&Class::Easy::Log::message);
	}
	
	if ($appender) {
		$self->appender ($appender);
	}
	
	return $self;
}

sub appender {
	my $self     = shift;
	# my $appender = shift;
	
	if (@_) {
		$self->{tied} = 1;
		tie $self->{broker} => 'Class::Easy::Log::Tie', $_[0];
	} else {
		$self->{tied} = 0;
		untie $self->{broker};
	}

}

# example usage: 
# logger (sql); # create sub log_sql
# log_sql ('message'); # log message, but nobody receive this message
# logger (sql => 'STDERR'); # now any log messages go to the STDERR

sub _parse_layout {
	my $logger = shift;
	
	$logger->{layout} ||= $default_layout;
	
	return $logger
		if defined $logger->{_layout} and $logger->{layout} eq $logger->{_layout};
	
	my $layout = $logger->{layout};
	
	my $layout_format = '';
	my @layout_fields = ();
	while ($layout =~ /([^\%]*)\%([^\%cCdFHlLmMnpPrRTxX]*)([\%cCdFHlLmMnpPrRTxX])/g) {
		
		$layout_format .= "$1\%$2";
		if ($3 eq 'L' or $3 eq 'P') {
			$layout_format .= 'd';
		} elsif ($3 eq 'r' or $3 eq 'R') {
			$layout_format .= 'd';
		} elsif ($3 eq '%') {
			$layout_format .= '%';
		} else {
			$layout_format .= 's';
		}
		push @layout_fields, $java_mappings->{$3}
			unless $3 eq '%';
	}
	# TODO: create more failsafe solution
	$layout_format .= substr ($layout, length($layout_format));
	
	$logger->{_layout_format} = $layout_format;
	$logger->{_layout_fields} = \@layout_fields;
	$logger->{_layout} = $layout;
	
	return $logger;
}

sub _format_log {
	my $self = shift;
	
	my $time = time;
	
	my $values = {
		pid      => $$,
		category => $self->{category},
		newline  => "\n",
		ts_start => $time - $^T,
		hostname => $hostname, # doesn't reflect hostname changes in runtime
		date     => $time,
		@_
	};

#	TODO: make sure all these values supported
#	R => 'ts_log',   # use timer_${logger} instead
#	C => 'package',  # useless, because we have %M = method
#	F => 'file',     # who cares about script files?
#	l => 'where',    # wtf?
#	p => 'priority', # log level, if written not for robots
#	T => 'stack',    # everything loves java stacks
#	TODO: add date formatting support
	
#	use Data::Dumper;
#	warn Dumper $self->{_layout_fields};
#	warn Dumper [map {$values->{$_}} @{$self->{_layout_fields}}];
	
#	warn $self->{_layout_format}, join (', ', @{$self->{_layout_fields}}), (join ', ', map {
#		$values->{$_}
#	} @{$self->{_layout_fields}});
	
	return sprintf ($self->{_layout_format}, (map {
		$values->{$_}
	} @{$self->{_layout_fields}}));
	
}

sub _wrapper {
	my $category = shift;
	my $logger   = shift;
	my $caller1  = shift;
	my $caller0  = shift;
	
	my $sub  = $caller1->[3] || 'main';
	my $line = $caller0->[2];
	
	# my ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
	# $evaltext, $is_require, $hints, $bitmask)
	
	$logger->_parse_layout;
		
	$logger->{broker} = $logger->_format_log (
		message => join ('', @_),
		method  => $sub,
		line    => $line
	);
	
	return 1;
}

sub debug {
	my $caller1  = [caller (1)];
	my $caller0  = [caller];

	unshift @_, 'default', $int_loggers->{default}, $caller1, $caller0;

	goto &_wrapper;
}

sub debug_depth {
	my $caller1  = [caller (2)];
	my $caller0  = [caller (1)];

	unshift @_, 'default', $int_loggers->{default}, $caller1, $caller0;

	goto &_wrapper;
}

sub critical {
	my $sub  = (caller (1))[3] || 'main';
	my $line = (caller)[2];
	
	my $logger = logger ('DIE')->_parse_layout;
	
	die $logger->_format_log (
		message => join ('', @_),
		method  => $sub,
		line    => $line
	);
}

sub catch_stderr {
	my $ref = shift;
	tie *STDERR => 'Class::Easy::Log::Tie', $ref;
}

sub release_stderr {
	untie *STDERR;
}

1;