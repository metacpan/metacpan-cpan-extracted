use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Basename;

if (-f 'oaf') {
  open my $in,  '<', 'oaf' or die $!;
  open my $out, '>', 'bin/oaf' or die $!;

  # Fixup for MakeMaker to replace with system path
  while (<$in>) {
    s|^#!/usr/bin/env perl|#!perl|;
    print $out $_;
  }

  close $in;
  close $out;
}

WriteMakefile(
     NAME         => 'App::oaf',
     VERSION_FROM => 'bin/oaf',
     ABSTRACT_FROM => 'lib/App/oaf.pm',
     AUTHOR       => 'Skye Shaw <skye.shaw AT gmail.com>',
     LICENSE      => 'perl',
     EXE_FILES    => ['bin/oaf'],
     (eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
      (META_MERGE  => { resources => { bugtracker => 'http://github.com/sshaw/output-as-format/issues',
                                       repository => 'http://github.com/sshaw/output-as-format',
				       homepage   => 'http://github.com/sshaw/output-as-format'} }) : ())
);

# Create README.pod for a repo's GitHub page. Unlike CPAN, GitHub won't
# display the module's POD, it looks for a README.*
sub MY::postamble
{
    my $self = shift;
    return if -r 'README' or ! -r $self->{VERSION_FROM};
    return<<END_MAKE;
README.pod: $self->{ABSTRACT_FROM}
	\@perldoc -uT $self->{ABSTRACT_FROM} > README.pod
END_MAKE
}
