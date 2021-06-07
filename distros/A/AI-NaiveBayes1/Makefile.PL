use ExtUtils::MakeMaker;
#<? read_starfish_conf() !>

my $module = 'AI::NaiveBayes1';
my $name   = 'NaiveBayes1.pm';
(my $dir = $module) =~ s/::/-/g;

WriteMakefile
( 'NAME'       => $module,
  'VERSION_FROM' => $name, # finds $VERSION
  'dist' => { COMPRESS=>"gzip",
	      SUFFIX=>"gz",
	      #PREOP=>('starfish README; '.
	      #        "cp -f README $dir-\$(VERSION); "
	      #       ),
	  },
  'clean' => {FILES => "tmp* testfiles/tmp1 AI *~ t/tmp1 t/*~ t/tmp6 t/tmp6-2"},
  'PREREQ_PM' => { YAML => '0.0' },
  'PL_FILES' => {},
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
   (ABSTRACT_FROM => $name, # retrieve abstract from module
   # <? echo "   AUTHOR => 'Vlado Keselj $VladoURL')" !>#+
      AUTHOR => 'Vlado Keselj https://web.cs.dal.ca/~vlado')
   #-
   : ()
   ),
  ($ExtUtils::MakeMaker::VERSION ge '6.30_00'? 
   ('LICENSE'         => 'perl', ) : ()),
  );

open(M, ">>Makefile") or die;

if ( -f 'priv.make' ) { print M getfile('priv.make') }

close(M);

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
