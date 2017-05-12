use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//i;
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w
#
!GROK!THIS!

print OUT <<'!NO!SUBS!';
# Update 0+ files from Date::LastModified config.


# ------ pragmas
use strict;
use DBI;
use Date::Format;
use Date::LastModified;


# ------ define variables
my $NAME      = "dlmup"; # our name
my $config    = "";      # config file
my $date      = "";      # formatted date/time
my @date_time = ();      # date+time values
my $dlm       = "";      # Date::LastModified object
my $file      = "";      # current file being processed
my $file_cnt  = 0;       # count of files to process (can be 0)
my $format    = "";      # Date::Format strftime() format string
my $pattern   = "";      # regexp for text to update (must be on 1 line)
my $verbose   = 0;       # TRUE when verbose (report resource info also)


# ------ process command arguments (ignore unknown)
$file_cnt = 0;
while (@ARGV > 0 && $ARGV[0] =~ m/^-/) {
    if ($ARGV[0] =~ m/^-f(.+)$/) {
        $config = $1;
    }
    if ($ARGV[0] =~ m/^-v/) {
        $verbose = 1;
    }
    shift;
}
if (@ARGV < 1) {
    die <<endDIE;
usage: dlmup [-v] [-fcfgfile] pattern format file1 [file2] ...
    OR
usage: dlmup [-v] [-fcfgfile] format

where:
    -v              verbose: report lastmod resource info too
    -fcfgfile       use config file "cfgfile"
    format          strftime() format string (Perl Date::Format)
    pattern         Perl regex to match in file(s)

If you don't use -fcfgfile, then the environment variable
DLMUPCFG (or \0x25HOME/dlmupcfg.cfg if DLMUPCFG is empty) will
contain the name of the configuration file.
endDIE
} elsif (@ARGV > 2) {
    $pattern  = shift;
    $format   = shift;
    $file_cnt = scalar(@ARGV);
} else {
    $format   = shift;
}


# ------ get last-modified date from Date::LastModified
if ($config ne "") {
    $dlm = new Date::LastModified($config);
} else {
    $dlm = new Date::LastModified(
     $ENV{"\U${NAME}CFG"} || "$ENV{HOME}/${NAME}.cfg");
}
@date_time = localtime($dlm->last);
$date      = strftime($format, @date_time);


# ------ Standard output only: just print according to format
if ($file_cnt < 1) {
    print "$date\n";
    if ($verbose) {
        print $dlm->from(), "\n";
    }


# ------ Modify files, matching $pattern then replacing with print $format
} else {
    foreach $file (@ARGV) {
        open(IFH, $file)
         || die "can't open '$file' because: $!\n";
        open(OFH, ">$file.dlmup")
         || die "can't create '$file.dlmup' because: $!\n";
        while (<IFH>) {
            s/$pattern/$date/g;
            print OFH $_;
        }
        close(IFH)
         || die "can't close '$file' because: $!\n";
        close(OFH)
         || die "can't close '$file.dlmup' because: $!\n";
        rename("$file.dlmup", $file)
         || die "can't rename '$file.dlmup' to '$file' because: $!\n";
    }
    if ($verbose) {
        print "$date\n";
        print $dlm->from(), "\n";
    }
}


# ------ exit
exit 0;
!NO!SUBS!
