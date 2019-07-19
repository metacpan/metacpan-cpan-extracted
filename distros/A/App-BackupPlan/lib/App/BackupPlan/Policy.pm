package App::BackupPlan::Policy;

use strict;
use warnings;
use Archive::Tar;
use File::Find;

our @ISA = qw(Exporter);
our $VERSION = '0.0.9';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use App::BackupPlan ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(getMaxFiles getFrequency getPrefix getSourceDir getTargetDir set);

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

1;
