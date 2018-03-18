#!/bin/sh
#USE_SPEEDY=<APP_NAME>
PATH=/usr/local/bin:/bin:/usr/bin

# Put local $PATH setting in this file.
# "run.cgi.env" file should not be committed in repository.
if [ -r run.cgi.env ]; then
	. ./run.cgi.env
fi

if [ "$USE_SPEEDY" != "" ]; then
	export SPEEDY_TIMEOUT=${SPEEDY_TIMEOUT:-60}
	export SPEEDY_MAXRUNS=${SPEEDY_MAXRUNS:-200}
	export SPEEDY_MAXBACKENDS=${SPEEDY_MAXBACKENDS:-20}
	exec speedy -x "$0" "${1+$@}"
else
	exec perl -x "$0" "${1+$@}"
fi

#!perl
use strict;
use warnings;
use FindBin;
use lib ($FindBin::Bin . '/../../app/local/lib/perl5', $FindBin::Bin . '/../../app/lib');
use Plack::Loader;
my $app = Plack::Util::load_psgi($FindBin::Bin . '/../../app/app.psgi');
Plack::Loader->auto->run($app);
