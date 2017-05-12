use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use File::Spec::Functions;

my $class_std_dir = (reverse glob (catdir(updir(), "Class-Std*")))[0];
my $file = catfile $class_std_dir, "README";

if (-d $class_std_dir && -f $file && open R, $file) {
    local $/;
    my $readme = <R>;
    $readme =~ s/\s+/ /gs; # Normalise all whitespace;
    if ($readme =~ /^Class::Std version/
	&& $readme =~ m!redistribute it and/or modify it under the same terms as Perl itself!) {
	# All systems go for plagiary
	my $his_testdir = catdir ($class_std_dir, "t");
	opendir D, $his_testdir or die "Can't open '$his_testdir': $!";
	foreach my $testfile (readdir D) {
	    next if $testfile eq '.' or $testfile eq '..';
	    my $his = catfile $his_testdir, $testfile;
	    my $mine = catfile "t", $testfile;

	    open R, "<$his" or die "Can't open '$his': $!";
	    open W, ">$mine" or die "Can't open '$mine': $!";
	    my $test = <R>;
	    $test =~ s/(Class::Std[^:])/Acme::$1/gs;
	    print W $test or die "Can't print to '$mine': $!";
	    close W or die  "Can't close '$mine': $!";
	}
    }
}

WriteMakefile(
    NAME              => 'Acme::Class::Std',
    VERSION_FROM      => 'Std.pm', # finds $VERSION
    PREREQ_PM         => {
			  'Test::More' => 0,
			  'Class::Std' => 0,
		      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Std.pm', # retrieve abstract from module
       AUTHOR         => 'Nicholas Clark <nwc10+acme-class-std@colon.colondot.net>') : ()),
);
