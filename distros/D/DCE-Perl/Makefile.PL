=pod

=cut

use Config; 
use ExtUtils::MakeMaker;
use strict;
my $def_dce_libs = '-L/usr/include/dce -ldce';

my $mm_dce = {
    hpux => {LIBS => [$def_dce_libs, "-lc_r"]},
#    solaris => {LIBS => [qw(-ldce)],
#		DEFINE => '-I/usr/include/dce -D_REENTRANT'}
    solaris => {LIBS => [qw(-ldce -lthread -lsocket -lnsl -lm)],
		DEFINE => ''}
};
  
# Provide a default LIBS for other systems.
my $MM_dce = $mm_dce->{$Config{osname}} || {LIBS => [$def_dce_libs]};
  
my $typemap = '../typemap';
if (!-f $typemap) { $typemap = './typemap'; } # for top level

WriteMakefile (
  %$MM_dce,
  TYPEMAPS => [$typemap],
  XSPROTOARG	=> '-noprototypes',
  NAME => 'DCE-Perl',
  VERSION => '0.19',
  'dist'    => {
      COMPRESS=> 'gzip -9f', SUFFIX=>'gz', 
      POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
  },
);

#    "\t".'XSUBPPARGS="$(XSUBPPARGS) -typemap ../typemap"\\', 
#    "\t".'XSUBPPDEPS="$(XSUBPPDEPS) ../typemap"\\', 
sub MY::pasthru {
    my $self = shift;
    chomp(my $str = $self->MM::pasthru);
    join $/, "$str\\", 
    "\t".'DEFINE="$(DEFINE)"\\', 
    "\t".'PERL="$(PERL)"\\', 
    "\t".'FULLPERL="$(FULLPERL)"\\', 
    "\t".'EXTRALIBS="$(EXTRALIBS)"\\', 
    "\t".'LDLOADLIBS="$(LDLOADLIBS)"\\', 
    "\t".'XSPROTOARG="$(XSPROTOARG)"', 
    "";   
}

sub MY::test {
    q(
TEST_VERBOSE=0

test:
	$(FULLPERL) t/TEST $(TEST_VERBOSE)

);
}

sub MY::post_initialize {
    my($self) = shift;
    # handy for other DCEish .xs modules 
    $self->{PM}->{'DCE_Perl.h'} = '$(INST_ARCHLIBDIR)/DCE/DCE_Perl.h';
    '';
}
