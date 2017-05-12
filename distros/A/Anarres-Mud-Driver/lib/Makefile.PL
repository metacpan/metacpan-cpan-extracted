require 5.006001;
use ExtUtils::MakeMaker;
use File::Find;

# Stop MakeMaker from including my vi swapfiles. Annoying.
# my @pm;
# find(sub { push(@pm, "$File::Find::dir/$_") if /\.pm$/ }, '.');

WriteMakefile(
    NAME		=> 'Anarres::Mud::Driver',
    AUTHOR		=> 'Shevek (cpan@anarres.org)',
	# PM			=> +{ map { $_ => "'\$(INST_LIBDIR)/$_'" } @pm },
);
