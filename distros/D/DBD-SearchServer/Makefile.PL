#!/usr/local/bin/perl -sw
# $Id: Makefile.PL,v 1.17 1999/03/05 09:01:22 shari Exp $

use ExtUtils::MakeMaker;
use FileHandle;
#use ExtUtils::MakeMaker qw(&WriteMakefile $Verbose %att);
use Getopt::Std;
use Config;
use Carp;

$SIG{'__WARN__'} = sub { Carp::carp $_[0] };
$SIG{'__DIE__'}  = sub { Carp::confess $_[0] };
			   
require 'flush.pl';

use DBI;	# The DBI must be installed before we can build a DBD
use DBI::DBD;

getopts('g') or die "Invalid arguments";

$opt_g &&= '-g';

%opts = (
	   NAME    => 'DBD::SearchServer',
	   VERSION_FROM => 'SearchServer.pm',
	   dist => {
		    COMPRESS => 'gzip',
		    SUFFIX => '.gz'
		   }
	  );

# --- Introduction

# print "\nConfiguring DBD::SearchServer $self->{VERSION}...\n";
print "---\> Please, READ the docs before installing!\n\n";
print "Whoa! FULCRUM_HOME is not set. READ THE DOCS!\n\n" if (!$ENV{FULCRUM_HOME});
#print "Whoa! FULSEARCH is not set. READ THE DOCS!\n\n" if (!$ENV{FULSEARCH});
#print "Whoa! FULTEMP is not set. While not mandatory, it is very likely make test will fail. In which case, set it and re-run make test.\n\n" if (!$ENV{FULTEMP});

# --- Where is Fulcrum SearchServer installed...

my $FULCRUM = $ENV{'FULCRUM_HOME'} || '/home/fulcrum';

print "Using Fulcrum SearchServer in $FULCRUM\n";


# --- What FULCRUM is installed...


my $SSINCLUDE = "-I$FULCRUM/include";




# Would this be the default? We'll se with Solaris (next in line)
my $sysliblist ="-L$FULCRUM/lib -lftft -lftet -lm";
$opts{INC}  = "$SSINCLUDE -I\$(INSTALLSITEARCH)/auto/DBI";
$opts{OBJECT} = '$(O_FILES)';

# type of linking and libs (begin)
if ($Config{osname} eq 'dec_osf') {
    print "WHOA!!! ave you read README.dec_osf? You must; you'll need\n";
    print "\tmanual intervention to complete the make phase!\n";
    if ($Config{ldflags} =~ /-taso/ || $Config{lddlflags} =~ /-taso/) {
       print "\tI found -taso in your perl config. Using default configuration\n";
    }
    else {
       print "\tI didn't find -taso in your perl config. Configuring for STATIC linking\n";
       $opts{LINKTYPE} = 'static';
    }
}
elsif ($Config{osname} eq 'aix') {
   $opts{OBJECT} = '$(O_FILES)' . " $FULCRUM/lib/libftft.\*.o $FULCRUM/lib/libftet.\*.o";
   $sysliblist = ''; # sorry, not like this...
   $opts{DEFINE} .= ' -qsrcmsg';
}


$opts{LIBS} = [ $sysliblist ];


# log key platform information to help me help you quickly


print "Searcherver sysliblist (may be empty if .o are needed) on this platform:\n";
print "\t$sysliblist\n";

print "System: perl$] @Config{qw(myuname archname dlsrc)}\n";
print "Compiler: @Config{qw(cc optimize ccflags)}\n";
print "Linker: @Config{qw(ld lddlflags)}\n";
print "\n";

WriteMakefile(%opts);

exit 0;


sub ask {
    my($prompt, $default) = @_;
	printflush(STDOUT,"$prompt: ");
	printflush(STDOUT,"[$default] ") if $default;
    my $value = <>;
	chomp $value;
	return $value or $default;
}

sub MY::postamble {
   return dbd_postamble(@_);
}

{
   package MY;

   sub post_initialize {
      my $self = shift;
      print "\nConfiguring DBD::SearchServer $self->{VERSION}...\n";

      return '';
   }
   
}

__END__
