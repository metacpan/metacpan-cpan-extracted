use ExtUtils::MakeMaker;
{
  package MY;

  sub manifypods {

    my ($self,%attribs) = @_;
    my $result = $self->SUPER::manifypods(%attribs);
    $result =~ s/^(POD2MAN_EXE\s*=\s*)(.+)$/$1$2 -r "v. $self->{VERSION}" -d "\$(REVISION_DATE)"/m;
    return $result;
  }
}

eval { require Test::More } 
  or warn<<EOW;
################
# To test this module, you need to dowload the Test::More module
# from CPAN and install it. 
#
# If you sees this warning, then Test::More is not installed 
# on your system.
#
# This will not prevent Date::Roman from work, the olny drawback is
# that you will not be hable to run the 
#
#  make test
# 
# target from the automaticaly generated Makefile.
################
EOW

WriteMakefile(
    'NAME'		=> 'Date::Roman',
    'VERSION_FROM'	=> 'lib/Date/Roman.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Roman => 0, #Needed to use Roman numbering
			    Getopt::Long => 0, #Needed by RomanDate
			   }, 
    'EXE_FILES'         => [ <bin/*> ],
    'macro'             => {REVISION_DATE => 'a.d. XI Kal. Mai. MMDCCLV AUC'},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Date/Roman.pm', # retrieve abstract from module
       AUTHOR     => 'Leo Cacciari aka TheHobbit <thehobbit@altern.org>') : ()),
);

