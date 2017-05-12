use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME                => 'App::VW',
  AUTHOR              => 'John BEPPU <beppu@cpan.org>',
  VERSION_FROM        => 'lib/App/VW.pm',
  ABSTRACT_FROM       => 'lib/App/VW.pm',
  EXE_FILES           => [ 'bin/vw', 'bin/vw-bus' ],
  PREREQ_PM => {
    'Time::HiRes'     => 0,
    'File::Copy'      => 0,
    'YAML'            => 0,
    'Test::More'      => 0,
    'File::ShareDir'  => 0,
    'App::CLI'        => 0,
    'AnyEvent'        => 0,
    'Event'           => 0,
    'Sys::Syslog'     => 0.13,
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'App-VW-*' },
  depend => { 
    pm_to_blib    => 'etc_to_auto', 
    clean_subdirs => 'rm_etc_to_auto' 
  }
);

sub MY::libscan {
  my $self = shift;
  $_       = shift;
  # $self appears to be a blessed hashref that contains
  # all the attributes/value pairs passed to WriteMakeFile()
  # plus some other MakeMaker-related info.
  return 0 if /\.sw.$/ || /~$/;
  return $_;
}

sub MY::postamble {q{
etc_to_auto : etc/init.d/vw-ubuntu etc/vw_harness.tmpl
	$(CP) -R etc $(INST_AUTODIR)
	$(TOUCH) etc_to_auto
rm_etc_to_auto :
	$(RM) etc_to_auto
}}
