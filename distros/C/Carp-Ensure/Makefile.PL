use ExtUtils::MakeMaker;

my $tagFile = "tag.log";
die("Need `$tagFile'")
    unless open(TAG, $tagFile);

my $cvsTag = <TAG>;
close(TAG);
chomp($cvsTag);
$cvsTag =~ /(\w+)(-\w+)?_(\d+)_(\d+)\b/;
my $cvsModule = $1;
my $cvsVersion = sprintf("%d.%02d", $3 - 1, $4);

WriteMakefile(
    NAME	=> 'Carp::Ensure',
    VERSION	=> '$(MY_CVSVERSION)',
    depend	=> { Makefile => $tagFile },
    macro	=> { MY_CVSMODULE => $cvsModule,
		     MY_CVSVERSION => $cvsVersion,
		     MY_CVSTAG => $cvsTag,
		   },
);

sub MY::dist_dir {
  return <<'__EOR__';

distdir : README
	$(RM_RF) $(DISTVNAME)
	$(MKPATH) $(DISTVNAME)
	cd $(DISTVNAME) ; lcvs export -d . -r $(MY_CVSTAG) $(MY_CVSMODULE)
	mv $(DISTVNAME)/global.log $(DISTVNAME)/Changes
	cp $^ $(DISTVNAME)

__EOR__
}

sub MY::postamble {
  return <<'__EOR__';

all:: README $(BASEEXT).html

README: $(MAN3PODS)
	pod2text $< > $@

$(BASEEXT).html: $(MAN3PODS)
	pod2html $< > $@

__EOR__
}
