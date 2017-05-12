package App::BackupPlan::Policy;

use Archive::Tar;
use File::Find;

sub new {
	my $class = shift;
	my $self = {
		maxFiles  => shift,
		prefix    => shift,
		frequency => shift,
		targetDir => shift,
		sourceDir => shift}; 

	bless $self,$class;						
	return $self;				
}

sub setMaxFiles {
    my ( $self, $maxFiles ) = @_;
    $self->{maxFiles} = $maxFiles if defined($maxFiles);
    return $self->{maxFiles};
}

sub getMaxFiles {
    my( $self ) = @_;
    return $self->{maxFiles};
}

sub setPrefix {
    my ( $self, $prefix ) = @_;
    $self->{prefix} = $prefix if defined($prefix);
    return $self->{prefix};
}

sub getPrefix {
    my( $self ) = @_;
    return $self->{prefix};
}

sub setFrequency {
    my ( $self, $frequency ) = @_;
    $self->{frequency} = $frequency if defined($frequency);
    return $self->{frequency};
}

sub getFrequency {
    my( $self ) = @_;
    return $self->{frequency};
}

sub setTargetDir {
    my ( $self, $targetDir ) = @_;
    $self->{targetDir} = $targetDir if defined($targetDir);
    return $self->{targetDir};
}

sub getTargetDir {
    my( $self ) = @_;
    return $self->{targetDir};
}

sub setSourceDir {
    my ( $self, $sourceDir ) = @_;
    $self->{sourceDir} = $sourceDir if defined($sourceDir);
    return $self->{sourceDir};
}

sub getSourceDir {
    my( $self ) = @_;
    return $self->{sourceDir};
}

sub set {
	my ($self, $name, $value) = @_;
	$self->{$name} = $value if defined($value) && defined($name);
}

sub print {
	my( $self ) = @_;
	$self->{maxFiles} = "n/a" unless defined($self->{maxFiles});
	$self->{prefix} = "n/a" unless defined($self->{prefix});
	$self->{frequency} = "n/a" unless defined($self->{frequency});
	$self->{targetDir} = "n/a" unless defined($self->{targetDir});
	$self->{sourceDir} = "n/a" unless defined($self->{sourceDir});
	print "Policy: maxFiles=$self->{maxFiles},
	prefix=$self->{prefix},
	frequency=$self->{frequency},
	targetDir=$self->{targetDir},
	sourceDir=$self->{sourceDir}\n"; 
}

sub info {
	my( $self ) = @_;
	$self->{maxFiles} = "n/a" unless defined($self->{maxFiles});
	$self->{prefix} = "n/a" unless defined($self->{prefix});
	$self->{frequency} = "n/a" unless defined($self->{frequency});
	$self->{targetDir} = "n/a" unless defined($self->{targetDir});
	$self->{sourceDir} = "n/a" unless defined($self->{sourceDir});
	return "Policy: maxFiles=$self->{maxFiles},
	prefix=$self->{prefix},
	frequency=$self->{frequency},
	targetDir=$self->{targetDir},
	sourceDir=$self->{sourceDir}"; 
}

sub tar {
	my( $self, $ts, $hasExcludeTag ) = @_;
	my $filename = sprintf("%s/%s_%s.tar.gz",$self->{targetDir},$self->{prefix},$ts);
	my $option = '';
	$option = '--exclude-tag-all=NOTAR' if $hasExcludeTag;
	my $output = `tar cvzf $filename $option $self->{sourceDir} 2>&1 1>/dev/null`;
	if (-e $filename) {
		my $stat = `ls -lh $filename`;
		return "system tar: $stat";	
	}	
	return "Error: tar failed to produce $filename\n$output\n";
}

sub perlTar {
	my( $self, $ts ) = @_;
	my $filename = sprintf("%s/%s_%s.tar.gz",$self->{targetDir},$self->{prefix},$ts);	
	my $tar = new Archive::Tar;
	our @files=();
	find(sub {push(@files,$File::Find::name);},$self->{sourceDir});
	$tar->add_files(@files);
	$tar->write($filename,COMPRESS_GZIP);
	if (-e $filename) {
		my $stat = `ls -lh $filename`;
		return "perl tar: $stat";	
	}	
	my $err = $tar->error();
	return "Error: tar failed to produce $filename\n$err\n";		
}


package App::BackupPlan;

use 5.012003;
use strict;
use warnings;
use Config;
use DateTime;
use Time::Local;
use XML::DOM;
use Log::Log4perl qw(:easy);

require XML::DOM;
require Log::Log4perl;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use App::BackupPlan ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();


BEGIN {
	our $VERSION = '0.0.7';
	print "App::BackupPlan by Gualtiero Chiaia, version $VERSION\n";	
}

# Preloaded methods go here.

our $TAR = 'system'; #use system tar
our $HAS_EXCLUDE_TAG = 0; #has tar option --exclude-tag

sub new {
	my $class = shift;
	my $self = {
		config => shift,
		log => shift
	};
	
	bless $self,$class;						
	return $self;				
}

sub run {
	my ($self) = @_;
	
	#validate the config file
	die "App::BackupPlan configuration file is required, but was not given!" unless defined $self->{config};

	#logging config
	if (defined $self->{log}) {
		Log::Log4perl::init($self->{log});
	} else {
        Log::Log4perl->easy_init( { level   => $INFO,
                                    file    => ">>easy.log" } );
	}
	
	my $logger = Log::Log4perl::get_logger();
	
	#get the environment
	&getEnvironment;

	#--now read config file
	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile ($self->{config}) or die "Could not parse $self->{config}";

	#get policies
	my ($obj,%policies) = &getPolicies($doc);
	foreach my $k (keys %policies) {
		#policy info			
		print "**$k policy**\n";
		$logger->info("**$k policy**");
				
		my $policy = $policies{$k};
		$policy->print;
		$logger->debug($policy->info);
		my $now = time;
		my $ts = &formatTimeSpan(time);
		my %files = &getFiles($policy->getTargetDir,$policy->getPrefix);
		#get last
		my $lastts = &getLastTs(keys %files);
		my $threshold = &subTimeSpan($now,$policy->getFrequency);
		if (!defined($lastts) || $lastts < $threshold ) { #needs a new tar file
			my $lastTS = '<missing>';
			$lastTS = &formatTimeSpan($lastts) if defined $lastts;				
			$logger->info("Need a new tar file, last tar was on $lastTS");				
			my $tarout;
			if (lc $TAR eq 'perl') {$tarout= $policy->perlTar($ts);}
			else {$tarout = $policy->tar($ts,$HAS_EXCLUDE_TAG);}
			if ($tarout =~ /Error/i) {
				$logger->error($tarout);	
			} else {
				$logger->debug($tarout);
			}
			
			#now delete old
			%files = &getFiles($policy->getTargetDir,$policy->getPrefix);
			my $maxFiles = $policy->getMaxFiles;
			my $cnt = scalar(keys %files); 
			while ($cnt > $maxFiles && $cnt >0) { 
				my $oldts = &getFirstTs(keys %files);
				my $oldTS = '<missing>';
				$oldTS = &formatTimeSpan($oldts) if defined $oldts;
				unlink $files{$oldts};
				$logger->info("Deleted old tar file, with time stamp $oldTS");
				%files = &getFiles($policy->getTargetDir,$policy->getPrefix);
				$cnt--;
			} #end while
		} #end if
	} #end foreach	
} #end sub

sub getEnvironment {
	my $env = $Config{osname};
	if 	($Config{osname} =~ /linux/i) {
		my $output = `man tar | grep /\-\-exclude\-tag/ | wc -l`;
		$HAS_EXCLUDE_TAG = 1 unless ($output eq '0');  		
	} else {$TAR = 'perl';}
	
}


sub getPolicies {
	my $xml = $_[0];
	my $defaultPolicy = new App::BackupPlan::Policy;
	#get default policy first
	#first default policy
	my $nodes = $xml->getElementsByTagName("default");
	if ($nodes->getLength > 0) {
		my $node = $nodes->item(0);
		foreach my $child ($node->getChildNodes) {
			if ($child->getNodeType == ELEMENT_NODE){
				my $name = $child->getNodeName;
				my $value = $child->getFirstChild->getNodeValue;
				$defaultPolicy->set($name,$value);				
			}
		}
	}
	#then all policies
	my %raw_policies;
	$nodes = $xml->getElementsByTagName("task");
	for (my $i=0;$i<$nodes->getLength; $i++) {
		my $task = $nodes->item($i);
		my $taskName = $task->getAttributes->getNamedItem('name')->getNodeValue;
		my $p = new App::BackupPlan::Policy;
		foreach my $child ($task->getChildNodes) {
			if ($child->getNodeType == ELEMENT_NODE){
				my $name = $child->getNodeName;
				my $value = $child->getFirstChild->getNodeValue;
				$p->set($name,$value);				
			}		
		}
		$raw_policies{$taskName} = $p;
	}
	%raw_policies = injectDefaultPolicy($defaultPolicy,%raw_policies);
	return ($defaultPolicy,%raw_policies);	
}

sub injectDefaultPolicy {
	my ($defPolicy,%raw_pcs) = @_;
	foreach my $k (keys %raw_pcs) {
		$raw_pcs{$k}->setMaxFiles($defPolicy->getMaxFiles) unless defined($raw_pcs{$k}->getMaxFiles);
		$raw_pcs{$k}->setPrefix($defPolicy->getPrefix) unless defined($raw_pcs{$k}->getPrefix);
		$raw_pcs{$k}->setFrequency($defPolicy->getFrequency) unless defined($raw_pcs{$k}->getFrequency);
		$raw_pcs{$k}->setSourceDir($defPolicy->getSourceDir) unless defined($raw_pcs{$k}->getSourceDir);
		$raw_pcs{$k}->setTargetDir($defPolicy->getTargetDir) unless defined($raw_pcs{$k}->getTargetDir);
	}
	return %raw_pcs;
}

sub addTimeSpan{
	my ($timestamp,$span) = @_;
	my @ts = localtime $timestamp;
	my $year = $ts[5]+1900;
	my $month = $ts[4]+1;
	my $day = $ts[3];
	my $dt = DateTime->new(year	=> $year, month	=> $month, day	=> $day);
	if ($span=~/(\d+)d/) {
		$dt->add_duration(DateTime::Duration->new(days => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
	if ($span=~/(\d+)m/) {
		$dt->add_duration(DateTime::Duration->new(months => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
	if ($span=~/(\d+)y/) {
		$dt->add_duration(DateTime::Duration->new(years => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
}

sub subTimeSpan{
	my ($timestamp,$span) = @_;
	my @ts = localtime $timestamp;
	my $year = $ts[5]+1900;
	my $month = $ts[4]+1;
	my $day = $ts[3];
	my $dt = DateTime->new(year	=> $year, month	=> $month, day	=> $day,);
	if ($span=~/(\d+)d/) {
		$dt->subtract_duration(DateTime::Duration->new(days => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
	if ($span=~/(\d+)m/) {
		$dt->subtract_duration(DateTime::Duration->new(months => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
	if ($span=~/(\d+)y/) {
		$dt->subtract_duration(DateTime::Duration->new(years => $1));
		return timelocal(0,0,0,$dt->day(),$dt->month()-1,$dt->year());
	}
	return $timestamp;		
}

sub formatTimeSpan {
	my $ts = $_[0];
	my @ts = localtime $ts;
	my $year = $ts[5]+1900;
	my $month = $ts[4]+1;
	my $day = $ts[3];
	return sprintf("%4d%02d%02d",$year,$month,$day); 
}

sub getFiles {
	my %fileMap;
	my ($sourceDir, $pattern) = @_;
	opendir DH, $sourceDir or die "Cannot open directory $sourceDir: $!\n";
	foreach my $f (readdir DH) {
		if ($f=~/$pattern.*/) {
			my $fname = $sourceDir."/".$f;
			#print "$fname\n";
			my @s = stat $fname;
			my $mtime = $s[9];
			$fileMap{$mtime}= $fname;			
		}
	} 
	closedir DH;
	return %fileMap;
}

sub getLastTs {
	my (@ts) = sort @_;
	my $nts = scalar @ts;
	return $ts[$nts-1];
}

sub getFirstTs {
	my (@ts) = sort @_;
	return $ts[0];
}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

App::BackupPlan - Perl extension for automated, regular backups

=head1 SYNOPSIS

  #when using system tar
  use App::BackupPlan;
  my $plan = new App::BackupPlan($configFile, $logFile);
  $plan->run;
  
  #when using perl tar
  use App::BackupPlan;
  $App::BackupPlan::TAR='perl';
  my $plan = new App::BackupPlan($configFile, $logFile);
  $plan->run;  

=head1 DESCRIPTION

App::BackupPlan is a simple module to perform regular, selective and automated 
backups of your system. It requires an xml file with the
specification of your backup plan, logically divided into independent tasks.
The constructor also takes a log4perl configuration file, to customise the logging produced.
This can be omitted if the default logging behaviour is desired.
By setting up a regular back-up task using cron or similar, and by configuring a backup plan with different
tasks, backup frequencies and max number of files retained, it is possible to achieve a regular
and incremental backup of different part of your system, without too much trouble. 

=head2 CONFIGURATION

Here is a made-up sample configuration file for a backup plan that backups two directories with 
different frequencies: a B<pictures> and a B<videos> directories.

	<backup>
		<plan name="one">
			<default>
				<maxFiles>3</maxFiles>
				<frequency>1m</frequency>
				<targetDir><![CDATA[/backup]]></targetDir>
			</default>
			<task name="pics">
				<prefix>pics</prefix>
				<sourceDir><![CDATA[/data/pictures]]></sourceDir>
				<frequency>20d</frequency>	
			</task>	
			<task name="video">
				<prefix>vid</prefix>
				<maxFiles>2</maxFiles>
				<sourceDir><![CDATA[/data/Videos]]></sourceDir>
				<frequency>40d</frequency>	
			</task>			
		</plan>
	</backup>

=over

=item * The tag B<E<lt>backupE<gt>> is the container tag for the backup plan.

=item * The tag B<E<lt>planE<gt>> contains the actual plan, as a collection of B<tasks>,
with an identifying name that is not currently used. A B<plan> is made of a E<lt>defaultE<gt> B<task>
and many separate B<tasks>. The E<lt>defaultE<gt> B<task> contains the definition of the properties
of a general B<task>, when an override is not given. Strictly speaking the current version of 
B<App::BackupPlan> requires only a default task and some distinct task elements inside a well formed
XML document. The structure of this sample configuration is mostly given for clarity.

=item * The tag B<E<lt>defaultE<gt>> contains the specification of the common properties for all
other tasks. This element is used to specify the default behaviour and its properies are inherited
by all other B<tasks>. It allows the same XML sub-elements as E<lt>taskE<gt> does, so for its
specification please see below.

=item * The tag B<E<lt>taskE<gt>> defines a backup policy for a given directory structure. It
has an attribute I<name> mostly for debugging purpouse. Its properties, partially inherited
from the E<lt>defaultE<gt> B<task> and partially overridden, are:

=over

=item * B<E<lt>prefixE<gt>> The prefix used to identify the beginning of the compressed backup file.

=item * B<E<lt>maxFilesE<gt>> The maximum number of backup files preserved in the E<lt>targetDirE<gt>
directory. As soon as this number is breached, the oldest backup file is removed (rolling behaviour).

=item * B<E<lt>frequencyE<gt>> The period of time between two consecutive backups of the current
E<lt>sourceDirE<gt>. This is specified by a string of type C<n[dmy]>, where n is a number and the 
second letter is either C<d> for days, C<m> for months or C<y> for years. Internally, C<1m = 30d>
and C<1y = 360d>, wihtout considering months of 28 or 31 days. 

=item * B<E<lt>sourceDirE<gt>> The path for the directory structure to be backed up. It requires
a B<CDATA> xml tag to escape the slashes in the full path.

=item * B<E<lt>targetDirE<gt>> The path for the destination directory where backup files are stored. It requires
a B<CDATA> xml tag to escape the slashes in the full path. Typically this will be a single location on the disk,
and hence the same for all tasks and specified in the E<lt>defaultE<gt> section.

=back

=back

=head2 USAGE

This perl module was written with an automated backup functionality in mind. So, even if it can
be run manually and on demand, it is best suited to be integrated in a regular batch (overnight maybe)
or even better as a B<cron> task. To facilitate this task there is a script client in the bin
directory of this distribution, B<backup.pl>, which can be easily scheduled as cron task and, that can be run
as follow: C<backup.pl -c /pathto/plan.xml -l /pathto/log4perl.conf> when using I<system> B<tar>, or as
C<backup.pl -c /pathto/plan.xml -l /pathto/log4perl.conf -t perl> for I<perl> B<tar>.  

=head2 DEPENDENCIES

The list of module dependencies is as follows:

=over

=item * B<XML::DOM> for parsing the configuration file,

=item * B<Log::Log4perl> for logging,

=item * B<File::Find> to collect the entire content of a directory substructure when using Archive::Tar

=item * B<Archive::Tar> to perform perl based tar, instead of using system tar

=item * B<tar> executable used in Linux environment for storage and compression

=back

On a B<Linux> system it is recommended to use the I<system> B<tar> executable, which is the default
behaviour for this module.
There is also the option of using L<Archive::Tar> perl module isntead of the I<system> B<tar>. This is
recommended for Windows based systems, or if the B<tar> executable is not available. This behaviour is designated
as I<perl> B<tar> and is selected by setting C<$App::BackupPlan::TAR='perl'>.

On some distributions B<XML::DOM> does not build straight away, using cpan install or download & make.
This is caused by a dependency of this module, B<XML::Parser>, requiring a C library to be present
in your system: B<expat-devel>. On some distributions, Debian for example, this package is unavailble.
This problem can be overcome by first installing (apt-get) B<libxml-parser-perl>.

	
=head2 EXPORT

None by default.



=head1 SEE ALSO

L<XML::DOM>, L<Log::Log4perl>, L<File::Find>, L<Archive::Tar>

=head1 AUTHOR

Gualtiero Chiaia

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Gualtiero Chiaia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
