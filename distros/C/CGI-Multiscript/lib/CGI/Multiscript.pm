package CGI::Multiscript;

use 5.008004;
use strict;
use warnings;

use IO::Handle;
use IO::File;
use Fcntl;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Multiscript ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.73';


# Preloaded methods go here.
our $writeflag = 0;
our $tmpfilename;
our $TMPFILE;
our $default;

sub new {
        my ($filename) = @_;
	my ($self) = {};
	bless ($self);
	$self->{'FILE'} = $filename;
	$self->{'LANGS'} = 0;
	return $self;
}

# set default language executor
sub setDefault {
	my ($value) = @_;
	$default = $value;
}

# get the default language executor
sub getDefault {
	return $default;
}

# set the Multiscript filename to execute
sub setFilename {
        my ($self, $value) = @_;
        $self->{'FILE'} = $value;
}

# get the current Multiscript filename
sub getFilename {
        my ($self) = @_;
        return $self->{'FILE'};
}

# display the current Multiscript filename
sub displayFilename {
	my ($self) = @_;
	print $self->{'FILE'}, "\n";
}

# add a language to the Multiscript execution list
sub addLanguage {
	my ($self, $lang, $args) = @_;
	$self->{$lang} = $args;
	$self->{'LANGS'}++;
}

# add a language version to the Multiscript execution list
sub addVersion {
	my ($self, $version, $args) = @_;
	$self->{$version} = $args;
	$self->{'LANGS'}++;
}

# add a language name to the Multiscript execution list
sub addName {
	my ($self, $version, $args) = @_;
	$self->{$version} = $args;
	$self->{'LANGS'}++;

}

# get the number of current languages in the execution list
sub getNumberoflangs {
	my ($self) = @_;
	my $number;
	$number = $self->{'LANGS'};
	return $number;	
}

# display the number of languages in the execution list
sub displayLangs {
	my ($self) = @_;
	my $keys = 0;
	print "There are ", $self->{'LANGS'}, " languages selected\n";
	# print "The languages/versions/names scheduled for execution are:\n";
	# while ($keys < $self->{'LANGS'})
	# {
	# print "$self->{'LANGS'}\n";
	# $keys++;
	# }
}

sub get {
        my ($self, $key) = @_;
        return $self->{$key};
}

# parse command line arguments into the language execution list
sub parseArgs {
	my ($self, @parseArgs) = @_;
	my $argnum;
	foreach $argnum (0 .. $#parseArgs) {
	   # print "$ARGV[$argnum]\n";
		$self->{$ARGV[$argnum]} = "";
		$self->{'LANGS'}++;
	}

}

# exeute the current file in the Multiscript object
sub execute {
my ($self) = @_;

my $filename;
my $line;
my $currentLanguage;
my $currentVersion;
my $currentName;
my $currentArgs;

$filename = $self->{'FILE'};

open (CODEFILE, $filename) or die "Can't Open Multiscript $filename";
    $tmpfilename = get_tmpfilename();

    # print "Creating a new script temp file $tmpfilename\n";
    umask 077;
    open ($TMPFILE, ">$tmpfilename") or die $!;

    $currentLanguage = "";
    $currentVersion = "";
    $currentName = "";
    $currentArgs = "";

    while ($line = <CODEFILE>) {
       # print $line;
       if ($line =~ /^<code\s+lang=["](\S+)["]\s+ver=["](\S+)["]\s+name=["](\S+)["]\s+args=["](\S+)["]>\n/) {
		$currentLanguage = $1;
		$currentVersion  = $2;
		$currentName 	 = $3;
		$currentArgs 	 = $4;
		$line = ""; # tmp fix
		# print "Current ", $currentLanguage, " ", $currentVersion, "\n";
           	set_writeflag(1);
       }
       if ($line =~ /^<code\s+lang=["](\S+)["]>\n/) {
       		# print "Current Code lang $line\n";
       		$currentLanguage = $1;
		$currentArgs = "";
		$line = "";
		set_writeflag(2);
       }
       elsif ($line =~ /^<code>\n/) {
       		$currentLanguage = "";
		$currentArgs = "";
           	set_writeflag(3);
       }
       elsif ($line =~ /^<\/code>\n/) {
           	clear_writeflag(1);
		# if should run and is in argument list
		if ($self->{'LANGS'} == 0) {
			execTmpfile($currentLanguage, $currentArgs);
		}
		elsif (exists $self->{$currentLanguage} ) {
			execTmpfile($currentLanguage, $currentArgs);
		}
		elsif (exists $self->{$currentName} ) {
			execTmpfile($currentLanguage, $currentArgs);
		}
		elsif (exists $self->{$currentVersion} ) {
			execTmpfile($currentLanguage, $currentArgs);
		}
		truncateTmpfile();
		$currentLanguage = "";
		$currentVersion = "";
		$currentName = "";
		$currentArgs = "";
       }
       else
       {
          if ($writeflag != 0) {
	      # print "Writing", $line;
	      print $TMPFILE $line; 
	  }
       }
      }


close($TMPFILE);
close(CODEFILE);
unlink($tmpfilename);

}

# Create a temporary file
# With a random name
sub get_tmpfilename() {
	my $tmpname;
	my $random;

	$tmpname = ".ms.";
	srand(time());
	$random = rand();
	$tmpname .= "$$";
	$tmpname .= $random;
	$tmpname .= ".tmp";

	# print "tmpname = $tmpname\n";

	return ($tmpname);

}

sub set_writeflag()
{
	my $flag = $_[0];
	if ($writeflag != 0) {
	print "Code Error -- Not allowed nested code within code!!\n";
		unlink($tmpfilename);
		exit(1);
	}
	$writeflag = $flag; 

}

sub clear_writeflag()
{
  	my $flag = $_[0];
  	$writeflag = 0;
}

sub execTmpfile()
{
	my ($lang, $args) = @_;
	my $returncode;

	# print "executing 1 $lang $tmpfilename\n";

	if (($lang eq "") && ($args eq "")) {
		$returncode = system("$default$tmpfilename");
	}
	elsif (($lang ne "") && ($args eq "")) {
		$returncode = system("$lang $tmpfilename");
	}
	elsif (($lang eq "") && ($args ne "")) {
		$returncode = system("$default$tmpfilename $args");
	}
	elsif (($lang ne "") && ($args ne "")) {
		$returncode = system("$lang $tmpfilename $args");
	}
	
}


sub truncateTmpfile()
{
	seek($TMPFILE, 0, 0);
	truncate($TMPFILE, 0);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
#

=head1 NAME

CGI::Multiscript - Perl extension for Multiscript programming

=head1 SYNOPSIS

use CGI::Multiscript;

CGI::Multiscript::setDefault("./");
CGI::Multiscript::setDefault("sh ");
print "Default execution ", CGI::Multiscript::getDefault(), "\n";
$ms = CGI::Multiscript::new('test_hello.ms');
$ms->parseArgs(@ARGV);
$ms->addLanguage('perl');
$ms->addLanguage('python');
$ms->displayLangs();

print "Current filename ", $ms->getFilename(), "\n";
$ms->execute();

Example Multiscript file:

<code lang="perl">
#!/usr/bin/perl
print "hello World perl\n";
</code>
<code lang="python">
#!/usr/local/python
print "Hello World python"
</code>
<code lang="ruby" ver="X" name="ix"  args="x">
puts "Hello World ruby"
</code>
<code>
#!/usr/bin/tcsh
echo "Hello World csh"
</code>
<code>
#!/usr/bin/bash
echo "Hello Shell"
</code>

=head1 DESCRIPTION

CGI::Multiscript is a Perl Module that allows for Perl scripts to run and execute Multiscript files.
CGI::Multiscript will allow Perl, Python, Ruby or Shell or any other language to coexist in the same external script. 
The Multiscripts consist of multiple languages separated by code tags and attributes.
Multiscript files can be executed from a Perl scripti that uses CGI::Multiscript.
 
CGI::Multiscript will run an external multiscript program according to the execution options which
include language, version, name and command line arguments. 

The current methods are setDefault, getDefault, new,  execute, parseArgs,
addLanguage, addName, addVersion, displayLangs, getFilename, setFilename.

=head2 EXPORT

The project page is mirrored on sourceforge.net and at http://www.mad-dragon.com/multiscript.html.

=head1 SEE ALSO

http://mad-dragon.com/multiscript


=head1 AUTHOR

Nathan Ross 

e-mail: morgothii@cpan.org

=head1 COPYRIGHT AND LICENSE

GPL and Artistic

Copyright (C) 2007 by Nathan Ross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
