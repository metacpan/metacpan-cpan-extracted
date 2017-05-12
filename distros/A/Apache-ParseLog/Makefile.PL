# Makefile.PL for Apache::ParseLog

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my($dir);
my($name) = "ParseLog.pm";
my($FS) = ($^O =~ /^mac/i ? ":" : "/");
chomp($dir = `pwd`);
my($file) = "${dir}${FS}ParseLog.pm";
my($version) = $];
 
my($arg) = @ARGV;
if ($arg =~ m/^-r/) {
	&restore();
} else {
	&main();
}

sub main {
	print "Your perl version: $version\n";

    if ($version < 5.004) {
    	die "Sorry, but you will need Perl version 5.004 or later.\n";
    
    } elsif ($version >= 5.005) {
		if (-w $file) {
        	print "Modifying $name for perl $version...";
        	open(FH, "<$file") or die "$!\n";
        	@lines = <FH>;
        	close(FH);
        	open(FH, ">$file") or die "$!\n";
        	foreach (@lines) {
        		if (m#my\(\$regex\)\s=\s\$FORMAT#) {
        			my($line) = $_;
        			$line =~ s#(\$FORMAT)#qr/$1/#;
        			print FH $line;
        		} elsif (m#require 5.004#) {
        			my($line) = $_;
        			$line =~ s#5.004#5.005#;
        			print FH $line;
        		} else {
        			print FH;
        		}
        	}
		}
    	close(FH);
    	print "done.\n";
    }

    WriteMakefile(
        'NAME'	=> 'Apache::ParseLog',
        'VERSION_FROM' => 'ParseLog.pm', # finds $VERSION
    	'clean' => { FILES => '${EXE_FILE}' },
    );

}

sub restore {
	print "Rewriting the ParseLog.pm to the 5.004-compatible version...";
	open(RES, "<$file") or die "\n$!\n";
	@lines = <RES>;
	close(RES);
	open(RES, ">$file") or die "\n$!\n";
	foreach (@lines) {
		if (m#my\(\$regex\)\s=\sqr/\$FORMAT/#) {
			my($line) = $_;
			$line =~ s#qr/##;
			$line =~ s#/##;
			print RES $line;
		} elsif (m#require 5.005#) {
			my($line) = $_;
			$line =~ s#5.005#5.004#;
			print RES $line;
		} else {
			print RES;
		}
	}
	close(RES);
	print "done.\n";
}
