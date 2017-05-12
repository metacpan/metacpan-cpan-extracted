use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'AnyEvent::ForkObject',
    VERSION_FROM      => 'lib/AnyEvent/ForkObject.pm', # finds $VERSION
    PREREQ_PM         => {
    	'AnyEvent::Tools'               => '0.10',
        'AnyEvent::Serialize'           => '0.03',
        'Devel::GlobalDestruction'      => '0.02'
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/AnyEvent/ForkObject.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitry E. Oboukhov <unera@debian.org>') : ()),
);

# I wanna see full report on CPAN
if (open my $file, '+<', 'Makefile') {
    my @lines = <$file>;
    seek $file, 0, 0;
    truncate $file, 0;
    for (@lines) {
    	$_ = "TEST_VERBOSE=1\n" if /^TEST_VERBOSE\s*=\s*.*/;
    	print $file $_;
    }
}
