use ExtUtils::MakeMaker;

my $gccopt = "";
if (defined $Config{'gccversion'})
 {
  $ver = $Config{'gccversion'};
  if ($ver ge "2.8")
   {
    eval
     {
      if ((getpwuid($<))[6] =~ /Nick\s+Ing-Simmons/)
       {
        # This is the author - catch as many bugs as possible
        $gccopt .= "-Wall -W -Wsign-compare";
       }
     }
   }
 }


WriteMakefile(
    'NAME'     => 'Audio::Data',
    'clean'    => {FILES => "*% *.bak"},
    'OBJECT'   => '$(O_FILES)',
    'dist'     => { COMPRESS => 'gzip -f', SUFFIX => 'gz' },
    'VERSION_FROM'  => 'Data.pm',
    DEFINE        => "$gccopt",
);

package MY;

sub post_initialize
{
 my ($self) = @_;
# my $dir = $self->catdir('$(INST_ARCHLIBDIR)','pTk');
 my $dir = '$(INST_ARCHLIBDIR)';
 foreach $name (sort(@{$self->{H}},qw(Audio.m Audio.t typemap)))
  {
   $self->{PM}->{$name} = $self->catfile($dir,$name);
  }
}

sub postamble
{
'
Audio.t : Audio.h  mkVFunc

config :: Audio.t
	@$(NOOP)
';
}

sub xs_c
{
 my $self = shift;
 return $self->SUPER::xs_c .
'
.SUFFIXES: .t .h
.h.t :
	$(PERL) mkVFunc $<
'
}
