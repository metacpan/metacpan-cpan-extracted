use Test::More;

do "dry_run.pl";

ok $user eq <<'USER';

============================================================
Bootstrap Perl
============================================================

============================================================

  Bootstrap Perl
  --------------

  version:        blead

  git-describe:   v5.21.10-20-gada289e

  git-changeset:  ada289e74406815f75328d011e5521339169abe7

  codespeed name: perl-5.21-thread-no64bit

  PREFIX:         /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e

  configureargs:  

  CPAN mirrors:   http://search.cpan.org/CPAN/

  modules:        

  scripts:        

============================================================

*** BUILD perl
# CPAN:     /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan5.21.11
# PERL:     /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11
# PERLDOC:  /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc5.21.11
# POD2TEXT: /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text5.21.11
USER

print "\$@ = [$@]\n" if $@;
done_testing();

__DATA__
@ARGV = qw(--nouse64bit)

# --- prepare

= $build_path eq '/tmp/bootstrap-perl-build'
mkdir -p /tmp/bootstrap-perl-build
= ! -d $build_path
cd /tmp/bootstrap-perl-build && git clone git://github.com/Perl/perl5.git perl
cd /tmp/bootstrap-perl-build/perl && rm -f /tmp/bootstrap-perl-build/perl/.git/index.lock
cd /tmp/bootstrap-perl-build/perl && git reset --hard
cd /tmp/bootstrap-perl-build/perl && git clean -dxf
cd /tmp/bootstrap-perl-build/perl && git checkout blead
cd /tmp/bootstrap-perl-build/perl && git pull
cd /tmp/bootstrap-perl-build/perl && git checkout blead
cd /tmp/bootstrap-perl-build/perl && git pull

cd /tmp/bootstrap-perl-build/perl && git describe --all
< heads/blead
cd /tmp/bootstrap-perl-build/perl && git describe
< v5.21.10-20-gada289e
cd /tmp/bootstrap-perl-build/perl && git rev-parse HEAD
< ada289e74406815f75328d011e5521339169abe7

= $VERSION eq v5.21.10

git branch --contains ada289e74406815f75328d011e5521339169abe7
< * blead

# --- build perl

cd /tmp/bootstrap-perl-build/perl; sh Configure -de -Dusedevel -Dusethreads   -Dprefix=/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e
cd /tmp/bootstrap-perl-build/perl; make -j 2
cd /tmp/bootstrap-perl-build/perl; make  install

open > /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-gitdescribe
chmod ugo+x /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-gitdescribe

open > /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-gitchangeset
chmod ugo+x /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-gitchangeset

open > /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-codespeed-executable
chmod ugo+x /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl-codespeed-executable

ls -drt1 /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan5.*.*     | tail -1
< /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan5.21.11

ls -drt1 /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.*.*     | tail -1
< /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11

ls -drt1 /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc5.*.*  | tail -1
< /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc5.21.11

ls -drt1 /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text5.*.* | tail -1
< /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text5.21.11

if [ ! -e /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl     ] ; then ln -sf /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11     /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl     ; fi

if [ ! -e /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan     ] ; then ln -sf /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan5.21.11     /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan     ; fi

if [ ! -e /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc  ] ; then ln -sf /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc5.21.11  /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc  ; fi

if [ ! -e /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text ] ; then ln -sf /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text5.21.11 /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/pod2text ; fi

# --- prefs

mkdir -p /tmp/bootstrap-perl-build
cd /tmp/bootstrap-perl-build && git clone git://github.com/renormalist/cpanpm-distroprefs.git
cd /tmp/bootstrap-perl-build/cpanpm-distroprefs && git pull
cd /tmp/bootstrap-perl-build/cpanpm-distroprefs && git submodule update --init --recursive
cd /tmp/bootstrap-perl-build/cpanpm-distroprefs && git pull
mkdir -p /opt/cpan/prefs
rsync -r /tmp/bootstrap-perl-build/cpanpm-distroprefs/cpanpm/distroprefs/ /opt/cpan/prefs/
rsync -r /tmp/bootstrap-perl-build/cpanpm-distroprefs/renormalist/distroprefs/ /opt/cpan/prefs/
rm -fr /opt/cpan/build

# --- cpan config

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perldoc5.21.11 -l CPAN | sed -e "s/CPAN.pm/CPAN\/Config.pm/"
< /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm

open > /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm

# --- cpan

if [ -L /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -o ! -e /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan ] ; then /bin/rm /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan ; echo "force install CPAN" | /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MCPAN -e shell ; fi

chmod +x /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan5.21.11
chmod +x /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan

# cpan helper
open > /tmp/bootstrap-perl-build/cpan_helper.pl
if [ ! -p /tmp/bootstrap-perl-build/cpan_helper.out ]; then mkfifo /tmp/bootstrap-perl-build/cpan_helper.out; fi
open |- /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 /tmp/bootstrap-perl-build/cpan_helper.pl /tmp/bootstrap-perl-build/cpan_helper.out /tmp/bootstrap-perl-build/cpan_helper.log
open < /tmp/bootstrap-perl-build/cpan_helper.out

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm YAML::XS

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm YAML

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm MSTROUT/YAML-0.84.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm MSTROUT/YAML-0.83.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm MSTROUT/YAML-0.82.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.81.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.80.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.79.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.78.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.77.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm INGY/YAML-0.76.tar.gz ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MYAML -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm -f -i YAML ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -MIO::Compress::Base -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm -f -i IO::Compress::Base ; fi 

if ! /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/perl5.21.11 -M"version 0.97" -e1 ; then /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm -f -i version ; fi 

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm    -i YAML::Syck

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm    -i IO::Tty

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm    -i Expect

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm    -i Bundle::CPAN

/opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/bin/cpan -j /opt/perl-5.21-thread-no64bit-v5.21.10-20-gada289e/lib/5.21.11/CPAN/Config.pm    -i LWP

