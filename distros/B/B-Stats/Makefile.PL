use strict;
use warnings;

use ExtUtils::MakeMaker 6.17; # perl-5.6.2

my %WriteMakefileArgs =
  (
   "NAME" 		=> "B::Stats",
   "VERSION_FROM" 	=> "lib/B/Stats.pm",
   "ABSTRACT"		=> "print optree statistics",
   "AUTHOR" 		=> "Reini Urban <rurban\@cpan.org>",
   "LICENSE" 		=> "perl",
   "PREREQ_PM" =>  {
		    'Opcodes' 	=> "0.11",
		    'B' 	=> 0,	# 5.6.2 has no version, 5.8.1 has 1.02
		    'Data::Dumper' => 0,# in core since perl 5.005
		   },
   "SIGN" => 1,
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
	license     => 'http://dev.perl.org/licenses/',
	bugtracker  => 'RT',
	repository  => 'git://github.com/rurban/B-Stats.git',
      }}) : ()),
  );

WriteMakefile(%WriteMakefileArgs);

sub MY::depend {
  "
lib/B/Stats/Minus.pm : Makefile c_minus
	\$(TOUCH) \$@
	\$(MAKE) pm_to_blib
	\$(FULLPERL) c_minus

README : lib/B/Stats.pm
	pod2text lib/B/Stats.pm > README
";
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
