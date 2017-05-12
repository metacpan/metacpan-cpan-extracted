package ClearCase::Attache;

use strict;

use Carp;
use Symbol;
use Win32;
use vars qw ($VERSION $ATTCMD $AUTOLOAD);
#
$VERSION = '0.01';
#
$ATTCMD="C:\\Program Files\\Rational\\Attache\\bin\\attcmd.exe";
$ATTCMD=((-x $ATTCMD )? $ATTCMD: pathfind('attcmd.exe'));

#============
#==METHODS===
#============
# Constructor
sub new {
    my($pkg,$ws,$attache)=(@_);
    my $self = {};
    #
    carp( "Workspace needed") unless $ws;
    $self->{_WS_}=$ws;
    #
    if ($attache) {
	carp("no $attache or not executable")
	    unless -x $attache;
    } else {
	carp("ATTACHE not specified and no default exists")
	    unless -x $ATTCMD;
	$attache=$ATTCMD;
    }
    $self->{_ATTCMD_}=Win32::GetShortPathName($attache);
    #
    bless $self,$pkg;
}
# If we want to use a log file.
sub setlog {
    my($self,$logfile,$append)=(@_);
    if($logfile) {
	my $h=gensym();
	open($h,($append? '>>' : '>'),$logfile)
	    or (carp("Opening $logfile: $!"),return);
	$self->{_LOG_}=$logfile;
	print $h "***Start logging at:", scalar(localtime()),"\n";
	close $h;  # Needed on windoze to preserve the log file.
    } else {
	delete $self->{_LOG_};
    }
    $logfile;
}
# maps workspace to physical location
sub vault {
    my($self)=(@_);
    my $ws=$self->{_WS_};
    $self->lsws();
    
    foreach my $l ($self->lastoutput()) {
	next if ($l=~/^Workspace name/);
	$l=~s/^\s+//;
	$l=~s/^\*\s*//;
	my ($ows,$locdir,$host)=(split(/\s+/,$l));
	return $locdir if ($ows eq $ws);
    }
    return;
}
# result of the latest command
sub lastoutput {
    my($self)=(@_);
    @{ $self->{_OUT_} };
}
# workspace accessors
sub getWs {
    $_[0]->{_WS_};
}

sub setWs {
    $_[0]->{_WS_}=$_[1];
}

# error flag
sub hasErrors {
    $_[0]->{_HASERRORS_}? 1: 0;
}
# error messages
sub errors {
    @{$_[0]->{_ERR_}};
}
# warning flags
sub hasWarnings {
    $_[0]->{_HASWARNINGS_}? 1: 0;
}
#warning content
sub warnings {
    @{$_[0]->{_WARN_}};
}
# run an arbitrary attache command
sub runcmd {
    my($self,$args)=(@_);
    my($ws)=($self->{_WS_});
    
    my($h)=(gensym());  #from Symbol
    my $cmd="$self->{_ATTCMD_} -ws $ws $args"; #No quotes, we used getshort..
    # get logfile
    my $log=gensym();
    if (exists $self->{_LOG_}) {
	my $logfile=$self->{_LOG_};
	open($log,'>>',$logfile)
	    or (carp("Opening $logfile: $!"),$log=undef());
    }
    $log && (print $log "$cmd\n");
    open($h,"-|",$cmd) or
	(carp("$! while invoking: $cmd"),return);
	#
    my($out,$err,$warn);
    $out=[];
    $err=[];
    $warn=[];
    $self->{_ERR_} =undef;
    $self->{_WARN_}=undef;
    $self->{_HASERRORS_} =0;
    $self->{_HASWARNINGS_}=0;
    $self->{_OUT_} =undef;
    #
    while(<$h>) { 
	next if /^Ready/;
	next if /^Setting workspace to/;
	chomp;
	substr($_,-1)=undef if(substr($_,-1) eq "\r");
	$log && (print $log '# ',$_,"\n");
	if (/Error:/) {
	    push @{$err},$_ ;
	    $self->{_HASERRORS_}++;
	} elsif(/Warning:/) {
	    push @{$warn},$_ ;
	    $self->{_HASWARNINGS_}++;
	} else {
	    push @{$out},$_;
	}
    }
    close $h;
    $log && close $log;

    $self->{_ERR_}=$err if {$#{$err}>= 0};
    $self->{_WARN_}=$warn if {$#{$warn}>=0};
    $self->{_OUT_}=$out;    
    1;
}
# Delegates everything to runcmd
sub AUTOLOAD {
    my($self,$args)=(@_);
    my($cmd);

    ($cmd=$AUTOLOAD)=~s/.*:://;
    $self->runcmd("$cmd $args");
}

sub DESTROY {} #avoids AUTOLOAD on destroy
#=============
#==UTILITIES==
#=============

sub pathfind {
    my($f)=(@_);
    my($sep)=(($^O=~/mswin/i)?';':':');
    foreach my $dir (split($sep,$ENV{PATH})) {
	return  "$dir/$f" if (-x "$dir/$f" );
    } 
    return
}

#========
#==OVER==
#========
1;
__END__
=head1 NAME

Attache - Perl extension for interfacing to attcmd on WIn32

=head1 SYNOPSIS

  use Attache;
  # Create 
  my $a=Attache->new('alfo_webteam');
  # Run a command
  $a->lsws() or warn("Problems on lsws"); 
  # Check errors, warnings, output
  if($attache->hasErrors()) {
      print STDOUT
	  "completed, with ERRORS:\n",
	  join("\n", $attache->errors()),"\n";
  } 
  if($attache->hasWarnings()) {
      print STDOUT
	  "completed, with WARNINGS:\n",
	  join("\n", $attache->warnings()),"\n";
  }
  print STDOUT "Output:\n",join("\n",$attache->lastoutput()),"\n";


=head1 DESCRIPTION

Attache.pm is an OO interface to the ClearCase CLI facility on Win32 systems
(attcmd). You need attcmd installed to be able to use this module. 

=head2 METHODS

=over 4

=item new($ws,[$attcmd])

Constructs a new attache command: takes the workspace as a mandatory
argument. Optional argument is the path to attcmd.

=item getWs()

returns the curent workspace

=item setWs($ws)

sets the current workspace

=item vault()

Returns the local physical location for the current workspace,
e.g:

    my $a=Attache->new("alfo_dev7");
    print $a->vault(),"\n";
    # prints F:\home\alf\ClearCase\alfo_dev7 on my machine
    


=item lastoutput()

returns the output of the last issued command, as an array of lines
(trailing newlines and CR removed)
 
=item hasErrors()

true if the last command had erros

=item errors()

returns the error diagnostics of the last issued command, as an array of lines
(trailing newlines and CR removed)
 

=item hasWarnings()

true if the last command had warnings

=item warnings()

returns the warning diagnostics of the last issued command, as an
array of lines (trailing newlines and CR removed)

=item [any_attcmd_command]($argstring)

executes any given attache command, with the given args, for instance:

    my $a=Attache->new("alfo_dev7");
    $a->co(' -c "None of your business" /tt_vob/foo/bar/baz.cpp'); 

Arguments are processed by the shell, so caution with quoting, special
characters etc. should be exercised.
DO NOT include any workspace indication - it is automatically inserted.

Please consult the attache documentation to find out which commands are
supported.

=item setlog($path,[$appendflag])

Calling setlog directs attache to direct the comand output ti the
given file.  If the (optional) $appendflag is true, the file is opened
in append mode and any previous content is preserved, rather than
truncated (the default). Calling
    
    $a->setlog(undef)

Disables logging.


=back

=head2 EXPORT

None 

=head2 INSTALLATION

Just drop in any directory of your INCLUDE path, or read the FindBin
docs and do something along the lines of:

  use FindBin qw($Bin);
  use lib ($Bin,"$Bin/../perl/lib", "$Bin/../lib/perl","$Bin/../lib");
  #
  use Attache;


=head2 SUPPORTED VERSIONS AND PLATFORMS 

Tested with perl 5.6 (ActiveState build 623) on Windows NT. For Unix,
check the Clearcase wrapper on the nearest CPAN site 
(http://search.cpan.org/search?mode=module&query=Clearcase).

Lesser perl versions may work (I'm almost positive about 5.5).
Windowze (non-NT) may also work, but I doubt it, as command.com is even more
broken than cmd.exe .

=head2 BUGS AND LIMITATIONS

No effort is made to ensure workspace validity.
Setlog should accept filehandle objects, and it should be possible to log
directly to STDOUT or STDERR.

Due to the cretin way in which cmd.exe handles command line quoting, some
combinations of (legitimate) arguments may break Attache - when this happens, 
please direct your grievances to:

    Microsoft Corp., Redmond, WA, U.S.A.

Every command starts a new attcmd.exe. If anybody knows a way to use attcmd
over a pipe (or a COM interface, or something else) pls. let me know. 


=head1 AUTHOR

Alessandro Forghieri, alf@orion.it

=head1 SEE ALSO

The attache documentation, perl(1).


=head1 LICENSE

This code is released under the No-Copyright provisions of the
GNU Public License

=cut
