use 5.006001;
use ExtUtils::MakeMaker;

use ExtUtils::MakeMaker;

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, cannot override metafile"); return $self->SUPER::metafile_target(@_);
  };

  my $node = new YAML::Node {};

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'perl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

WriteMakefile(
    NAME              => 'Convert::Wiki',
    VERSION_FROM      => 'lib/Convert/Wiki.pm',
    PREREQ_PM         => {
	Test::Differences => 0.47,
	Text::Format => 0.52,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Convert/Wiki.pm', # retrieve abstract from module
       AUTHOR         => 'Tels http//:bloodgate.com') : ()),
);
