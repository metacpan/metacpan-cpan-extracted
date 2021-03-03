#!/usr/bin/sh
# install.sh -- A script to install followme on Linux. Must be run with sudo 

# Update for a new version of Perl
PERL_ENV=/usr/local/share/perl/5.30.0

cd `dirname $0`

mkdir -p $PERL_ENV/App
cp ../lib/App/Followme.pm $PERL_ENV/App
chmod -w  $PERL_ENV/App/Followme.pm

mkdir -p $PERL_ENV/App/Followme
cp  ../lib/App/Followme/*.pm $PERL_ENV/App/Followme
chmod -w  $PERL_ENV/App/Followme/*.pm

cp ../script/followme /usr/local/bin
chmod -w /usr/local/bin/followme
