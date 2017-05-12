#!/usr/bin/perl -w -*- mode: cperl -*-
use strict;
use ExtUtils::MakeMaker qw(:DEFAULT);
my $version_diff = 0; # we'll have to die if this becomes true
{
  my $version_from = q(lib/CPAN/Checksums.pm);

  {
    local $^W;
    $ExtUtils::MakeMaker::VERSION = eval $ExtUtils::MakeMaker::VERSION;
    warn "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nYou should get a new one\n"
        if $ExtUtils::MakeMaker::VERSION < 6.0;
  }

  if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.016;
    die "Your MakeMaker is a bit dated[$ExtUtils::MakeMaker::VERSION].\nDo not make a release with it\n"
        if $ExtUtils::MakeMaker::VERSION < 7;
    die "Your MakeMaker doesn't do the sign woodoo" unless
        MM->can("signature_target");
    shift @ARGV;
    local $ENV{LANG} = "C";
    my $dirty = `git status --porcelain --untracked-files=no`;
    die "Not everything checked in?" if $dirty;

    my $version_set_manually = 1;
    if ($version_set_manually) {
      # we must control that the VERSION in this .pm is the same as in the Makefile
      unshift @INC, "lib";
      require $version_from;
      open my $fh, "make the-release-name|" or die;
      my $have_version;
      while (<$fh>) {
        next unless /^version\s+([\d\._]+)/;
        $have_version = eval $1;
      }
      die "could not determine current version from Makefile" unless $have_version;
      eval q{
      no warnings "numeric";
      if ($CPAN::Checksums::VERSION != $have_version) {
        warn "Not equal: CPAN::Checksums::VERSION[$CPAN::Checksums::VERSION] Makefile version[$have_version]";
        $version_diff = 1;
      }
};
      die $@ if $@;
    } else {
        die;
    }
    exit unless $version_diff;
  }
}
my $prereq_pm = {
                 'Compress::Bzip2' => 0,
                 'Compress::Zlib' => 0,
                 'Data::Compare' => 0,
                 'Data::Dumper' => 0,
                 'Digest::MD5' => "2.36",
                 'Digest::SHA' => 0,
                 'DirHandle' => 0,
                 'File::Spec' => 0,
                 'File::Temp' => 0,
                 'IO::File' => "1.14",
                };
for my $interesting_module (qw(
        Module::Signature
                             )) {
    eval "require $interesting_module";
    if (!$@) {
        $prereq_pm->{$interesting_module} ||= 0;
    }
}

WriteMakefile(
              'NAME'	=> 'CPAN::Checksums',
              'VERSION_FROM' => 'lib/CPAN/Checksums.pm',
              (MM->can("signature_target") ? (SIGN => 1) : ()),
              'PREREQ_PM' => $prereq_pm,
              ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
               (LICENSE      => "perl") : (),
              ),
              'dist' => {
                         DIST_DEFAULT => join(" ",
                                              "verify-changes-date",
                                              "verify-changes-version",
                                              'Makefile',
                                              "META.yml",
                                              "setversion",
                                              "README",
                                              "all",
                                              'tardist',
                                              ),
                         COMPRESS => 'gzip -9f'
                        },
              # I took it from RT-CPAN ticket 30098:
              ($ExtUtils::MakeMaker::VERSION >= 6.4502 ?
               (META_ADD => {
                             resources => {
                                 repository => "git://github.com/andk/cpan-checksums.git",
                             },
                             keywords => ['CPAN infrastructure','per-directory indexing and signing'],
                            }) : ()),
             );

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;
sub postamble {
  q{
setversion:
	$(PERL) Makefile.PL --setversion

Makefile : lib/CPAN/Checksums.pm

README: Makefile
	$(PERL) -MPod::Text -e 'Pod::Text->new->parse_from_file(\*ARGV)' lib/CPAN/Checksums.pm > $@

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release :: disttest
	ls -l $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)
	$(NOECHO) $(ECHO) '  git tag -m "This is $(VERSION)" "$(VERSION)"'
	$(NOECHO) $(ECHO) '  xxx-upload $(DISTVNAME).tar$(SUFFIX)'
	$(NOECHO) $(ECHO) '  git push --tags'

sign:
	`dirname $(PERL)`/cpansign -s

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^$$t\s/; END{die "Alert: did not find <$$t> in Changes file" unless $$ok}' Changes

verify-changes-version:
	@$(PERL) -ne '$$ok++,exit if /\b$(VERSION)\b/; END{die "Alert: did not find <$(VERSION)> in Changes file" unless $$ok}' Changes

}
}

sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvzf $(DISTVNAME).tar$(SUFFIX)
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)

}
}
sub distsignature {
    my($self) = shift;
    my $ret = $self->SUPER::distsignature_target(@_);
    $ret =~ s|cpansign|\`dirname \$(PERL)\`/cpansign|g;
    return $ret;
}
