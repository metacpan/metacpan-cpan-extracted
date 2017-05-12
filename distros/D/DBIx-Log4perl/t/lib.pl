# $Id: lib.pl 4157 2010-07-05 10:45:22Z martin $
use Cwd;
use File::Spec;

my $logtmp1;
my $logtmp2;

sub get_config
{
    my @v;
    if (-f ($file = 't/dbixl4p.config')  ||
	-f ($file = '../dbixl4p.config') ||
	-f ($file = 'dbixl4p.config')) {
	open IN, "$file";
	while (<IN>) {
	    chomp;
	    if ($_ eq 'UNDEF') {
		push @v, undef;
	    } else {
		push @v, $_;
	    }
	}
    }
    return @v;
}
sub config
{
    my $td = File::Spec->tmpdir or die q/Can't find a temporary directory to use. Please set TMPDIR, TEMP or TMP environment variables to a valid cirectory/;

#####    open OUT, ">pipe.pl" or die "Failed to create pipe.pl - $!";
#####    print OUT "#!$^X\n";
#####    print OUT 'while (<STDIN>) {open OUT, ">>dbixl4p.log"; print OUT $_;close OUT;}';
#####    close OUT;
#####    chmod 0777, "pipe.pl";

    $logtmp1 = File::Spec->catfile($td, 'dbixroot.log');
    $logtmp2 = File::Spec->catfile($td, 'dbix.log');
    my $cwd = getcwd();
    my $pipe = File::Spec->catfile($cwd, "pipe.pl");
    my $loginit = qq(
log4perl.logger = FATAL, LOGFILE

# LOGFILE appender used by root (here)
# log anything at level ERROR and above to $logtmp1
log4perl.appender.LOGFILE=Log::Log4perl::Appender::File
log4perl.appender.LOGFILE.filename=$logtmp1
log4perl.appender.LOGFILE.mode=append
log4perl.appender.LOGFILE.utf8=1
log4perl.appender.LOGFILE.autoflush=1
log4perl.appender.LOGFILE.Threshold = ERROR
log4perl.appender.LOGFILE.layout=PatternLayout
log4perl.appender.LOGFILE.layout.ConversionPattern=[%r] %F %L %c - %m%n

# Define DBIx::Log4perl to output DEBUG and above msgs to
# $logtmp2 using the simple layout
log4perl.logger.DBIx.Log4perl=DEBUG, A1
log4perl.appender.A1=Log::Log4perl::Appender::File
log4perl.appender.A1.filename=$logtmp2
log4perl.appender.A1.mode=append
log4perl.appender.A1.recreate=1
log4perl.appender.A1.recreate_check_interval=0
log4perl.appender.A1.utf8=1
log4perl.appender.A1.autoflush=1
log4perl.appender.A1.layout=Log::Log4perl::Layout::SimpleLayout
		     );

    ok (Log::Log4perl->init(\$loginit), 'init config');

    ok (Log::Log4perl->get_logger('DBIx::Log4perl'), 'get log handle');

    return($logtmp1, $logtmp2);
}

sub check_log
{
    my ($s, $file) = @_;
    $$s = "";
    return 0 if (! -r $file);
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
    return 0 if ($size <= 0);
    open IN, "<$file";
    while (<IN>) {$$s .= $_};
    close IN;
    unlink $file;
    diag($$s) if ($ENV{TEST_VERBOSE});
    return 1;
}
1;
