#!/bin/bash

if [[ -n "$SHORT_CIRCUIT_SMOKE" ]] ; then return ; fi

# we need a mirror that both has the standard index and a backpan version rolled
# into one, due to MDV testing
CPAN_MIRROR="http://cpan.metacpan.org/"

PERL_CPANM_OPT="$PERL_CPANM_OPT --mirror $CPAN_MIRROR"

export PERL_MM_USE_DEFAULT=1 PERL_MM_NONINTERACTIVE=1 PERL_AUTOINSTALL_PREFER_CPAN=1 PERLBREW_CPAN_MIRROR="$CPAN_MIRROR" HARNESS_TIMER=1 MAKEFLAGS="-j$NUMTHREADS"

# try CPAN's latest offering if requested
if [[ "$DEVREL_DEPS" == "true" ]] ; then

  PERL_CPANM_OPT="$PERL_CPANM_OPT --dev"

fi

# Fixup CPANM_OPT to behave more like a traditional cpan client
export PERL_CPANM_OPT="--verify --verbose --no-interactive --no-man-pages $( echo $PERL_CPANM_OPT | sed 's/--skip-satisfied//' )"

if [[ -n "$BREWVER" ]] ; then
  # since perl 5.14 a perl can safely be built concurrently with -j$large
  # (according to brute force testing and my power bill)
  if [[ "$BREWVER" == "blead" ]] || perl -Mversion -e "exit !!(version->new(q($BREWVER)) < 5.014)" ; then
    perlbrew_jopt="$NUMTHREADS"
  fi

  run_or_err "Compiling/installing Perl $BREWVER (without testing, using ${perlbrew_jopt:-1} threads, may take up to 5 minutes)" \
    "perlbrew install --as $BREWVER --notest --noman --verbose $BREWOPTS -j${perlbrew_jopt:-1}  $BREWVER"

  # can not do 'perlbrew uss' in the run_or_err subshell above, or a $()
  # furthermore `perlbrew use` returns 0 regardless of whether the perl is
  # found (won't be there unless compilation suceeded, wich *ALSO* returns 0)
  perlbrew use $BREWVER

  if [[ "$( perlbrew use | grep -oP '(?<=Currently using ).+' )" != "$BREWVER" ]] ; then
    echo_err "Unable to switch to $BREWVER - compilation failed...?"
    echo_err "$LASTOUT"
    exit 1
  fi

# no brewver - this means a travis perl, which means we want to clean up
# the presently installed libs
# Idea stolen from
# https://github.com/kentfredric/Dist-Zilla-Plugin-Prereqs-MatchInstalled-All/blob/master/maint-travis-ci/sterilize_env.pl
elif [[ "$CLEANTEST" == "true" ]] && [[ "$POISON_ENV" != "true" ]] ; then

  echo_err "$(tstamp) Cleaning precompiled Travis-Perl"
  perl -MConfig -MFile::Find -e '
    my $sitedirs = {
      map { $Config{$_} => 1 }
        grep { $_ =~ /site(lib|arch)exp$/ }
          keys %Config
    };
    find({ bydepth => 1, no_chdir => 1, follow_fast => 1, wanted => sub {
      ! $sitedirs->{$_} and ( -d _ ? rmdir : unlink )
    } }, keys %$sitedirs )
  '

  echo_err "Post-cleanup contents of sitelib of the pre-compiled Travis-Perl $TRAVIS_PERL_VERSION:"
  echo_err "$(tree $(perl -MConfig -e 'print $Config{sitelib_stem}'))"
  echo_err
fi

# configure CPAN.pm - older versions go into an endless loop
# when trying to autoconf themselves
CPAN_CFG_SCRIPT="
  require CPAN;
  require CPAN::FirstTime;
  *CPAN::FirstTime::conf_sites = sub {};
  CPAN::Config->load;
  \$CPAN::Config->{urllist} = [qw{ $CPAN_MIRROR }];
  \$CPAN::Config->{halt_on_failure} = 1;
  CPAN::Config->commit;
"
run_or_err "Configuring CPAN.pm" "perl -e '$CPAN_CFG_SCRIPT'"
