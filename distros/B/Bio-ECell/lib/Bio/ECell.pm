package Bio::ECell;

use 5.006;
use strict;
use warnings;

BEGIN{
    my @lines = qx|ecell3-python -h|;

    if ($?){
	print STDERR "E-Cell3 is not installed on your system. Bio::ECell will not work.\n";
    }else{

	my $flag = 0;
	foreach my $line (@lines){
	    chomp($line);
	    
	    $flag = 1 if($line =~ /^Configurations:/);
	    if($flag == 1 && $line =~ /^\s+(\S+)\s+\=\s+(.*)/){
		$ENV{$1} .= ':' if ($ENV{$1});
		$ENV{$1} .= $2;
	    }
	}   

	$ENV{ECELL3_DM_PATH} .= ':' . $ENV{prefix} . '/lib/' . $ENV{PACKAGE} . '/' . $ENV{VERSION}; 
	$ENV{ECELL3_DM_PATH} .= ':' . $ENV{prefix} . '/lib/' . $ENV{PACKAGE} . '-3.1/dms/';
	$ENV{ECELL3_PREFIX} = $ENV{prefix};
	$ENV{OSOGOPATH} = $ENV{prefix} . '/lib/osogo';
	$ENV{MEPATH} = $ENV{prefix} . '/lib/modeleditor';
	$ENV{TLPATH} = $ENV{prefix} . '/lib/toollauncher';
	$ENV{PYTHONDIR} = $ENV{pythondir};
	$ENV{LTDL_LIBRARY_PATH} .= ':.:/sw/lib/ecell-3.1/dms/' . $ENV{ECELL3_DM_PATH} . ':' . $ENV{prefix} . '/lib/ecell/' . $ENV{VERSION};

	require Inline;
	import Inline Python => << '__INLINE_PYTHON__';
import sys
import string
import getopt
import os

import ecell
import ecell.ecs
import ecell.emc
import ecell.eml
import ecell.analysis.emlsupport

from ecell.Session import Session
from ecell.ECDDataFile import *

def internalLoadEcell3():
    aSimulator = ecell.emc.Simulator()
    aSession = Session(aSimulator)
    return aSession

def internalECDDataFile(logger):
    return ECDDataFile(logger.getData())

def internalEmlSupport(eml):
    return ecell.analysis.emlsupport.EmlSupport(eml)
    
__INLINE_PYTHON__


    }
}


require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::ECell ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.10';


sub new{
    my $this = internalLoadEcell3();
    my $pkg = shift;
    my $eml = shift;

    if(length($eml)){
	$this->loadModel($eml);

	if(wantarray()){
	    return ($this, internalEmlSupport($eml));
	}
    }
    return $this;
}

sub ECDDataFile{
    my $this = shift;
    my $logger = shift;

    return internalECDDataFile($logger);
}

sub EMLSupport{
    my $this = shift;
    my $eml = shift;

    return internalEmlSupport($eml);
}

   

=head1 NAME

Bio::ECell - Perl interface for E-Cell Simulation Environment.

=head1 SYNOPSIS

 # E-Cell way

    use Bio::ECell;

    my $ecell = Bio::ECell::new();

    $ecell->loadModel("simple.eml");
    $ecell->message("Message from Perl!");

    my $logger = $ecell->createLoggerStub('Variable:/:S:Value');
    $logger->create();

    print $ecell->getCurrentTime(), "\n";
    $ecell->run(100);
    print $ecell->getCurrentTime(), "\n";

    my $data = Bio::ECell->ECDDataFile($logger );
    $data->setDataName( $logger->getName() );
    $data->save('S.ecd');

 # more Perl-ish way:)

    use Bio::ECell;
    my ($ecell, $eml) = new Bio::ECell("simple.eml");

    my $duration = 100;
    my $step = 0.001;

    my %loggers;
    foreach my $variable ($eml->getVariableList()){
        next if ($variable =~ /:SIZE/);
        $loggers{$variable} = $ecell->createLoggerStub($variable . ':Value');
        $loggers{$variable}->create();
        $loggers{$variable}->setLoggerPolicy([$step, 0, 1, 1024 * 100]);
    }

    $ecell->run($duration);

    foreach my $variable (keys %loggers){
        my $data = Bio::ECell->ECDDataFile($loggers{$variable});
        my @name = split(/:/, $variable);
        $data->setDataName($name[2]);
        $data->save($name[2]);
    }

    $ecell->saveModel('hoge.eml');


=head1 DESCRIPTION

Bio::ECell is a Perl interface for the E-Cell Simulation Environment 
version 3 (http://www.e-cell.org/), a generic cell simulation software 
for molecular cell biology researches that allow object-oriented modeling 
and simulation, multi-algorithm/time-scale simulation, and scripting 
through Python. This module allows scripting of sessions with Perl. 

For the details of the E-Cell API, users should refer to the chapter
about scripting a simulation session of E-Cell3 Users Manual, available
at the above-mentioned web-site.

=head2 new

The constructor is just a wrapper around the instance given by 

    ecell.Session(ecell.emc.Simulator())

in Python.

Basically functions required for scripting can be called from this instance.

As a shortcut, if this constructor is called with an EML file path, 
the system loads the model with $ecell->loadModel(), and returns 
the loaded session instance as well as an eml object.

    ex. ($ecell, $eml) = new Bio::ECell("simple.eml");

=head2 ECDDataFile

ECDDataFile constructor can be called as follows:

    $ecell = Bio::ECell::new();
    $logger = $ecell->createLoggerStub('Path-name-for-logger');
    $logger->create();
    $data = Bio::ECell->ECDDataFile( $logger );

Here usage is slightly different from the Python interface, passing
the logger instance instead of the DATA tuple. Internally the system
calls logger.getData() to pass onto ECDDataFile.

=head2 $ecell->loadModel( $file )

Load an EML ﬁle, and create a cell model as described in the ﬁle. 
file can be either a ﬁlename or a ﬁle object. 

=head2 loadScript( $filename )

Load a ESS ﬁle. Usually this is not used in ESS. 

=head2 $ecell->message( $message )

Output message. By default the message is printed to stdout. 
The way the message is handled can be changed by using setMessageMethod 
method. For example, GUI frontend software may give a method to steal the message for its message printing widget. 

=head2 $ecell->saveModel( $file )

Save the current model in memory as an EML ﬁle. File may be either a ﬁlename or 
a ﬁle object. 

=head2 $ecell->setMessageMethod( $method )

This method changes what happens when message method is called. 
method must be a Python callable object which takes just one string parameter. 

=head2 $ecell->restoreMessageMethod()

This method undoes saveMessageMethod, by restoring the default 
MessageMethod for the Session. 

=head2 $ecell->plainMessageMethod()

This method undoes saveMessageMethod, by restoring the default 
MessageMethod for the Session. 

=head2 $ecell->getCurrentTime()

This method returns the current time of the simulator. 

=head2 $ecell->getNextEvent()

This method returns the next scheduled event as a Python 2-tuple consisting of a 
scheduled time and a StepperID. The event will be processed in the next time whe 
step() or run() is called. 

The time is usually different from one that getCurrentTime() returns. This method 
returns the scheduled time of the next event, while getCurrentTime() returns the 
time of the last event. These methods can return the same number if more than one 
events are scheduled at the same point in time. 

=head2 $ecell->run( $sec )

Run the simulation for $sec seconds. 
When this method is called, the simulator internally calls step() method repeat- 
edly until the equation tcurrent > tstart + sec holds. That means, the simulator 
stops immediately after the simulation step in which the time exceeds the speci- 
ﬁed point. The time can be far after the speciﬁed time point if all step sizes taken 
by Steppers in the model are very long. 

If event checker event handler object are set, sec can be omitted. 

=head2 $ecell->setEventChecker( $eventchecker )

If the event checker and an event handler are correctly set, and the run method is 
called with or without time duration, the simulator checks if the event checker 
returns true once in n simulation steps , where n is a positive integer number set 
by using setEventCheckInterval (default n= 20 steps). If it happens, the 
simulator then calls the event handler. If the event handler calls stop method of 
Session, the simulator stops before the next step. This is the only way to quit 
from the simulation loop when run is called without an argument. 

This mechanism is used to implement, mainly but not limited to, GUI frontend 
components to the Session class. 

event checker and event handler must be Python callable objects. event 
checker must return an object which can be evaluated as either true or false. 

=head2 $ecell->setEventCheckInterval( $n )

This method is NOT IMPLEMENTED YET. 

=head2 $ecell->setEventHandler( $eventhandler 

See setEventChecker 

=head2 $ecell->step( $numsteps )

Perform a step of the simulation. If the optional integer numsteps parameter is 
given, the simulator steps that number. If it is omitted, it steps just once. 

=head2 $ecell->stop() 

Stop the simulation. Usually this is called from the event handler, or other 
methods called by the event handler. 

=head2 $ecell->initialize()

Do preparation of the simulation. Usually there is no need to call this method 
because this is automatically called before executing step and run. 
Stepper methods 

=head2 $ecell->getStepperList()

This method returns a Python tuple which contains ID strings of Stepper objects 
in the simulator. 

=head2 $ecell->createStepperStub( $id )

This method returns a StepperStub object bound to this Session object and the 
given id. 

=head2 $ecell->getEntityList( $entitytype, $systempath ) 

This method returns a Python tuple which contains FullID strings of Entity 
objects of entitytype existing in the System pointed by the systempath 
argument entitytype must be one of "Variable", "Process", or "System". VARIABLE, PROCESS, 
or SYSTEM deﬁned in ecell.ECS module. systempath must be a valid SystemPath 
string. 


=head2 $ecell->createEntityStub( $fullid ) 

This method returns an EntityStub object bound to this Session object and the 
given fullid. 


=head2 $ecell->getLoggerList()

This method returns a Python tuple which contains FullPN strings of all the 
Logger objects in the simulator. 

=head2 $ecell->createLoggerStub( $fullpn )

This method returns a LoggerStub object bound to this Session object and the 
given fullpn. 

fullpn must be a valid FullPN string. 

=head2 $ecell->saveLoggerData( $fullpn, $aSaveDirectory , $aSaveDirectory , $aSaveDirectory , $aSaveDirectory ) 

This saves all logger data associated with logger fullpn to 
aSaveDirectory. If fullpn is not speciﬁed, all loggers are 
dumped by this method. If a fullpn is provided, than that 
logger alone will be dumped. aSaveDirectory speciﬁes the 
directory for saving the dump ﬁles; if left blank it defaults to 
./Data. Within no start times, interval increments, or ﬁnish 
times, this function will print out all data, however, any of 
these can be given in seconds as a parameter. 

=head2 $ecell->theSimulator

theSimulator variable holds this Session’s Simulator object. 
Usually ESS users should rarely have need to get into details of the Simulator 
class because almost all simulation jobs can be done with the Session API 
and the ObjectStub classes, which were in fact developed to make it eas- 
ier by providing a simple and consistent object-oriented appearance to the 
lower level ﬂat Simulator API. For the details of Simulator class, consult E- 
Cell C++ library reference manual and the sourcecode of the system, especially 
ecell3/ecell/libemc/Simulator.hpp. 

=head2 $eml->getAllEntityList($entityType, $rootSystemPath)

get the list of all entities under the root system path
entityType: (str) 'Variable' or 'Process' or 'System'

=head2 $eml->getVariableList()

get the list of all variables.

=head2 $eml->getProcessList()

get the list of all processes.

=head2 $eml->calculateActivityArray()

create an Session from Eml and calculate the initial activity of processes
return activityArray

=head2 $eml->getActivityArray()

create an Session from Eml and calculate the initial activity of processes
return activityArray

=head2 $eml->getValueArray()

create an Session from Eml and get the initial value of variables
return valueArray



=head1 SEE ALSO

For complete descriptions of E-Cell API, see
http://www.e-cell.org/software/documentation/ecell3-users-manual_0606.pdf

=head1 AUTHOR

Kazuharu Arakawa, E<lt>gaou@sfc.keio.ac.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kazuharu Arakawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut



1;
__END__
