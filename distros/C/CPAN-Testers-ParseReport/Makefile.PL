use strict;
use warnings;
use ExtUtils::MakeMaker;
$ExtUtils::MakeMaker::VERSION =~ s/_//g;
my @sign = (MM->can("signature_target") ? (SIGN => 1) : ());
my $version_diff = 0; # we'll have to die if this becomes true
my $trial = 0;
my $version;
my $version_from = './lib/CPAN/Testers/ParseReport.pm';
$version = MM->parse_version($version_from);
if ($trial) {
    $version .= "-TRIAL";
    if ($trial > 1) {
        $version .= $trial;
    }
}
{
  my $version_set_manually = 1;
  if ($ARGV[0] && $ARGV[0] eq "--setversion") {
    die "Your perl is a bit dated[$]].\nDo not make a release with it\n" if $] < 5.016;
    eval {  require $version_from; }; die $@ if $@;
    my $makefile = "Makefile";
    unless (-f $makefile) {
        $makefile = "Makefile.old";
    }
    unless (-f $makefile) {
        die "no Makefile and no Makefile.old found";
    }
    local $ENV{LANG} = "C";
    my $dirty = `git status --porcelain --untracked-files=no`;
    die "Not everything checked in or out?\n====\n$dirty====\n" if $dirty;

    my ($have_version);
    if ($version_set_manually) {
        open my $fh, "make -f $makefile the-release-name|" or die "Could not fork: $!";
        local $/;
        ($have_version) = <$fh> =~ /^version\s+([\d\._]+(?:-TRIAL)?)/m;
        close $fh or die "Could not close: $!";
        die "could not determine current version from Makefile" unless $have_version;
    }
    my ($namespace) = $version_from;
    $namespace =~ s|.*lib/(.+)\.pm$|$1|;
    $namespace =~ s|/|::|g;
    eval qq{ if (\$$namespace\::VERSION != \$have_version) {
        warn "Not equal: CPAN::Testers::ParseReport::VERSION[\$$namespace\::VERSION] Makefile version[\$have_version]";
        \$version_diff = 1;
    }};
    eval qq{ if (\$$namespace\::VERSION != \$versionfrom) {
        warn "Not equal: CPAN::Testers::ParseReport::VERSION[\$$namespace\::VERSION] MM generated version[\$versionfrom]";
        \$version_diff = 1;
    }};
  }
}

my %indirect_dependencies =
    (
     'Class::ISA' => 0,
     'DateTime'   => 0,
     'CPAN::Meta::Converter' => '2.110440',
    );
my %interesting_modules;
for my $m (qw(
    CPAN::Meta::YAML
    File::Spec
    IO::Prompt
    JSON::PP
    Parse::CPAN::Meta
    version
    )){
    if (eval "require $m; 1") {
        $interesting_modules{$m} = $m->VERSION;
    }
}

my $prereq_pm =
    {
     'Compress::Zlib'              => 0,
     'DateTime::Format::Strptime'  => 0,
     'ExtUtils::MakeMaker'         => 6.48,
     'File::Path'                  => '1.08',
     'File::ReadBackwards'         => '1.06',
     'Getopt::Long'                => 0,
     'HTML::Entities'              => 0,
     'Hash::Util'                  => 0,
     # 'IO::Prompt'                  => 0,
     'JSON::XS'                    => 0,
     'LWP::UserAgent'              => 0,
     'List::AllUtils'              => 0,
     'MIME::QuotedPrint'           => '3.07',
     'Pod::Usage'                  => '1.33',
     'Statistics::Regression'      => 0,
     'Test::More'                  => 0,
     'Test::Pod'                   => 0,
     'Time::Local'                 => '1.11',
    };

# intentionally avoiding any size comparisons, trying to catch
# interesting cases that happen during WriteMakefile, like
# http://www.cpantesters.org/cpan/report/e1942da8-5fcc-11e0-994f-224f8e2a057c
while (my($k,$v) = each %interesting_modules) {
    $prereq_pm->{$k} ||= $v;
}
while (my($k,$v) = each %indirect_dependencies) {
    $prereq_pm->{$k} ||= $v;
}

eval { WriteMakefile
    (
     'NAME' => 'CPAN::Testers::ParseReport',
     'VERSION' => $version,
     'PREREQ_PM' => $prereq_pm,
     'INSTALLDIRS' => 'site',
     'EXE_FILES' => [
                     'bin/ctgetreports',
                    ],
     LICENSE => "perl",
     ABSTRACT => "parse reports to www.cpantesters.org from various sources",
     'PL_FILES' => {},
     dist => {
              DIST_DEFAULT => join(" ", # note: order matters!
                                   "verify-changes-date",
                                   "Makefile",
                                   "META.yml",
                                   "setversion",
                                   "all",
                                   "tardist",
                                  ),
              COMPRESS => 'bzip2 -9f',
              SUFFIX => ".bz2",
             },
     META_MERGE => {
                    # write: git push git+ssh://repo.or.cz/srv/git/cpan-testers-parsereport.git master
                    resources => { repository => "https://repo.or.cz/cpan-testers-parsereport.git" },
                    provides => { "CPAN::Testers::ParseReport" => { version => $version, file => $version_from }},
                   },
     MIN_PERL_VERSION => '5.008', # Rule: _pragma_utf8
     @sign,
    );
   };
if (my $err = $@) {
    while (my($k,$v) = each %interesting_modules) {
        warn "Found $k version $v\n";
    }
    die $err;
}

if ($version_diff){
  die "
==> I had to update some \$VERSIONs <==
==> Your Makefile has been rebuilt. <==
==> Please rerun the make command.  <==
";
}

package MY;
sub distsignature {
    my($self) = shift;
    my $ret = $self->SUPER::distsignature_target(@_);
    $ret =~ s|cpansign|\$(PERL) \`dirname \$(PERL)\`/cpansign|g;
    return $ret;
}
sub postamble {
  my @m;
  push @m, q{
# the subdirs on MY OWN BOX are allowed here (only used for make dist!)
OKDIRS=DIST|bin|blib|cover_db\
       |lib|t

Makefile: }.$version_from.q{

META.yml: metafile
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	-$(CP) $(DISTVNAME)/META.json  ./META.json

setversion:
	$(PERL) Makefile.PL --setversion

verify-changes-date:
	@$(PERL) -ne 'BEGIN{my@t=(localtime)[5,4,3];$$t[0]+=1900;$$t[1]++;$$t=sprintf"%04d-%02d-%02d",@t}' \
		-e '$$ok++,exit if /^[\d\.]+(?:-TRIAL\d*)?\s+$$t\s/ && $$.<12; END{die "Alert: did not find <$$t> in the first 12 lines of the Changes file" unless $$ok}' Changes

verify-no-subdir:
	@$(PERL) -e 'my$$s=join",",grep{!/^($(OKDIRS))\z/x&&-d($$_)}glob"*";' \
		-e 'die"unexpected dir:$$s"if$$s'

the-release-name :
	$(NOECHO) $(ECHO) 'version ' $(VERSION)
	$(NOECHO) $(ECHO) 'release-name ' $(DISTVNAME).tar$(SUFFIX)

release :: disttest
	test -e META.json
	ls -l $(DISTVNAME).tar$(SUFFIX)
	rm -rf $(DISTVNAME)
	$(NOECHO) $(ECHO) '#### Suggested next steps (if all looks good):'
	$(NOECHO) $(ECHO) '  make reversion AGAINST_TAG=__previous_release__'
	$(NOECHO) $(ECHO) '  git tag -m "This is $(VERSION)" "$(VERSION)"'
	$(NOECHO) $(ECHO) '  git push --tags origin master'

reversion:
	$(NOECHO) $(ECHO) AGAINST_TAG=$(AGAINST_TAG)
	$(PERL) dagolden-reversion-gist.pl $(AGAINST_TAG)

sign:
	$(PERL) `dirname $(PERL)`/cpansign -s
};
  join "", @m;
}

sub dist_test {
  return q{
# if we depend on $(DISTVNAME).tar$(SUFFIX), then the rest of the
# Makefile breaks our intent to NOT remake dist
disttest :
	rm -rf $(DISTVNAME)
	tar xvjf $(DISTVNAME).tar$(SUFFIX)
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)

distdir ::
	touch $(DISTVNAME)/SIGNATURE && $(CP) $(DISTVNAME)/SIGNATURE ./SIGNATURE
	$(CP) $(DISTVNAME)/META.yml  ./META.yml
	-$(CP) $(DISTVNAME)/META.json  ./META.json
	$(CP) $(DISTVNAME)/MANIFEST  ./MANIFEST

}
}

sub distdir {
  my $self = shift;
  my $out = $self->SUPER::distdir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}

# dist_dir was the name in very old MakeMaker as of 5.005_04
sub dist_dir {
  my $self = shift;
  my $out = $self->SUPER::dist_dir;
  $out =~ s/distdir :/distdir ::/g;
  return $out;
}
