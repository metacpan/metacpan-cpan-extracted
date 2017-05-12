package Bio::NEXUS::Util::Logger;
use strict;
#use warnings;
use File::Spec;
use Bio::NEXUS::Util::Exceptions 'throw';
use Config;
use vars qw($volume $class_dir $file $VERBOSE $AUTOLOAD);

BEGIN {
	my $class_file = __FILE__;
	( $volume, $class_dir, $file ) = File::Spec->splitpath( $class_file );
	$class_dir =~ s/Bio.NEXUS.Util.?$//;
	#printf "[ %s starting, will use PREFIX=%s where applicable ]\n", __PACKAGE__, $class_dir;
}

{	
	my $self;	
	my %VERBOSE;
	my %LEVEL;
	my @listeners = (
		sub {
			my $msg = shift;
			print STDERR $msg;
		}
	);	
	@LEVEL{ qw(FATAL ERROR WARN INFO DEBUG) } = ( 0 .. 4 );
	$VERBOSE = $LEVEL{'WARN'};
	
	sub new {
		my $package = shift;
		my %args;
		
		# singleton object
		if ( not $self ) {
			$self = \$package;
			bless $self, $package;
		}
		
		# process args
		if (@_) {
			
			# create hash
			eval { %args = @_ };
			if ($@) {
				throw 'OddHash' => $@;
			} 
		}
		
		# set level
		if ( defined $args{'-level'} ) {
			
			# check validity
			if ( $args{'-level'} > $LEVEL{'DEBUG'} xor $args{'-level'} < $LEVEL{'FATAL'} ) {
				throw 'OutOfBounds' => "'-level' can be between $LEVEL{'FATAL'} and $LEVEL{'DEBUG'}, $args{'-level'} is outside that range";
			}
			else {
				if ( $args{'-class'} ) {
					$VERBOSE{$args{'-class'}} = $args{'-level'};
				}
				else {
					$VERBOSE = $args{'-level'};
				}
			}
		}
		
		# done
		return $self;
	}
	
	sub set_listeners {
		my ( $self, @args ) = @_;
		for my $arg ( @args ) {
			if ( UNIVERSAL::isa( $arg, 'CODE' ) ) {
				push @listeners, $arg;
			}
			else {
				throw 'BadArgs' => "$arg not a CODE reference";
			}
		}
		return $self;
	}
	
	sub log {
		my ( $self, $level, $msg ) = @_;
		my ( $package, $file1up,  $line1up, $subroutine ) = caller(2);
		my ( $pack0up, $filename, $line,    $sub0up )     = caller(1);		
		my $verbosity = exists $VERBOSE{$pack0up} ? $VERBOSE{$pack0up} : $VERBOSE;
		if ( $verbosity >= $LEVEL{$level} ) {			
			my $log_string;
			if ( $filename =~ s/\Q$class_dir\E// ) {
				$log_string = sprintf( "%s %s [\$PREFIX/%s, %s] - %s\n",
				$level, $subroutine, $filename, $line, $msg );
			}
			else {
				$log_string = sprintf( "%s %s [%s, %s] - %s\n",
				$level, $subroutine, $filename, $line, $msg );			
			}
			$_->( $log_string ) for @listeners;
		}
		return $self;
	}
	
	sub AUTOLOAD {
		my ( $self, $msg ) = @_;
		my $method = $AUTOLOAD;
		$method =~ s/.*://;
		$method = uc $method;
		if ( exists $LEVEL{$method} ) {
			$self->log( $method, $msg );
		}
	}
	
	sub PREFIX { 
		my ( $self, $prefix ) = @_;
		$class_dir = $prefix if $prefix;
		return $class_dir;
	}
	
	sub VERBOSE {
		my $self = shift;
		if (@_) {
			my %opt;
			eval { %opt = @_ };
			if ($@) {
				throw 'OddHash' => $@;
			}
			if ( defined $opt{'-level'} ) {
				
				# check validity
				if ( $opt{'-level'} > $LEVEL{'DEBUG'} xor $opt{'-level'} < $LEVEL{'FATAL'} ) {
					throw 'OutOfBounds' => "'-level' can be between $LEVEL{'FATAL'} and $LEVEL{'DEBUG'}, not $opt{'-level'}";
				}				
				
				if ( $opt{'-class'} ) {
					$VERBOSE{ $opt{'-class'} } = $opt{'-level'};
					$self->info("Changed verbosity for $opt{'-class'} to $opt{'-level'}");
				}
				else {
					$VERBOSE = $opt{'-level'};				
					$self->info("Changed global verbosity to $VERBOSE");
				}
			}
		}
		return $VERBOSE;
	}	
	
	sub DESTROY {} # empty destructor so we don't go up inheritance tree at the end
	
}

1;		

=head1 NAME

Bio::NEXUS::Util::Logger - Logging for Bio::NEXUS.

=head1 SYNOPSIS

 use Bio::NEXUS::Util::Logger;
 
 # can instantiate as (singleton) object, in this case telling it that only
 # messages from Bio::NEXUS::Forest with log level >= 3 are displayed...
 my $logger->new( -level => 3, -class => 'Bio::NEXUS::Matrix' );
 
 
 #...or use static...
 Bio::NEXUS::Util::Logger->info("Log level too low for this to be printed");
 Bio::NEXUS::Matrix->VERBOSE( -level => 2 );
 Bio::NEXUS::Util::Logger->info("Not any more, now we're talking");
 

=head1 DESCRIPTION

This class defines a logger, a utility object for logging messages.
The other objects in Bio::NEXUS use this logger to give detailed feedback
about what they are doing at per-class, user-configurable log levels
(debug, info, warn, error and fatal). You can tell the logger for each 
class how verbose to be. The least verbose is level 0, in which case only
'fatal' messages are shown. The most verbose level, 4, shows debugging 
messages, include from internal methods (i.e. ones that start with 
underscores, and special 'ALLCAPS' perl methods like DESTROY or TIEARRAY).
For example, to monitor what the root class is
doing, you would say:

 $logger->( -class => 'Bio::NEXUS', -level => 4 )

To define global verbosity you can omit the -class argument.

=head1 METHODS

=head2 CONSTRUCTOR

=over

=item new()

Constructor for Logger.

 Type    : Constructor
 Title   : new
 Usage   : my $logger = Bio::NEXUS::Util::Logger->new;
 Function: Instantiates a logger
 Returns : a Bio::NEXUS::Util::Logger object
 Args    : -verbose => verbosity, 0 .. 4 (optional)
 		   -package => a package for which to set verbosity (optional)	

=back

head2 LOGGING METHODS

=over

=item log()

Prints argument debugging message, depending on verbosity.

 Type    : logging method
 Title   : log
 Usage   : $logger->log( "WARN", "warning message" );
 Function: prints logging message, depending on verbosity
 Returns : invocant
 Args    : message log level, logging message

=item debug()

Prints argument debugging message, depending on verbosity.

 Type    : logging method
 Title   : debug
 Usage   : $logger->debug( "debugging message" );
 Function: prints debugging message, depending on verbosity
 Returns : invocant
 Args    : logging message

=item info()

Prints argument informational message, depending on verbosity.

 Type    : logging method
 Title   : info
 Usage   : $logger->info( "info message" );
 Function: prints info message, depending on verbosity
 Returns : invocant
 Args    : logging message

=item warn()

Prints argument warning message, depending on verbosity.

 Type    : logging method
 Title   : warn
 Usage   : $logger->warn( "warning message" );
 Function: prints warning message, depending on verbosity
 Returns : invocant
 Args    : logging message

=item error()

Prints argument error message, depending on verbosity.

 Type    : logging method
 Title   : error
 Usage   : $logger->error( "error message" );
 Function: prints error message, depending on verbosity
 Returns : invocant
 Args    : logging message

=item fatal()

Prints argument fatal message, depending on verbosity.

 Type    : logging method
 Title   : fatal
 Usage   : $logger->fatal( "fatal message" );
 Function: prints fatal message, depending on verbosity
 Returns : invocant
 Args    : logging message

=item set_listeners()

Adds listeners to send log messages to.

 Type    : Mutator
 Title   : set_listeners()
 Usage   : Bio::NEXUS::Util::Logger->set_listeners( sub { warn shift } )
 Function: Sets additional listeners to log to (e.g. a file)
 Returns : invocant
 Args    : One or more code references
 Comments: On execution of the listeners, the first (and only) argument 
           is the log message.
 
=item PREFIX()

Getter and setter of path prefix to strip from source file paths in messages.

 Type    : Mutator/Accessor
 Title   : PREFIX()
 Usage   : Bio::NEXUS::Util::Logger->PREFIX( '/path/to/Bio/NEXUS' )
 Function: Sets/gets $PREFIX
 Returns : Verbose level
 Args    : Optional: a path
 Comments:

=item VERBOSE()

Setter for the verbose level. This comes in five levels: 0 = only
fatal messages (though, when something fatal happens, you'll most likely get
an exception object), 1 = errors (hopefully recoverable), 2 = warnings 
(recoverable), 3 = info (useful diagnostics), 4 = debug (almost every method call)

 Type    : Mutator
 Title   : VERBOSE()
 Usage   : Bio::NEXUS::Util::Logger->VERBOSE( -level => $level )
 Function: Sets/gets verbose level
 Returns : Verbose level
 Args    : 0 <= $level && $level <= 4
 Comments:

=back

=head1 REVISION

 $Id: Logger.pm,v 1.3 2010/09/22 20:05:51 astoltzfus Exp $

=cut