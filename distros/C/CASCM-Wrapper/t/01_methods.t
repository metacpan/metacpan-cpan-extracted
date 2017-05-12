#!/usr/bin/perl

#####################
# LOAD CORE MODULES
#####################
use strict;
use warnings;
use Test::More;

# Autoflush
local $| = 1;

# What are we testing?
my $module = "CASCM::Wrapper";

# Load
use_ok($module) or exit;

# Init
my $cascm = new_ok($module) or exit;

my @methods = qw(
  new
  set_context
  load_context
  update_context
  get_context
  errstr
);

my @commands = qw(
  haccess
  hap
  har
  hauthsync
  hcbl
  hccmrg
  hcrrlte
  hchgtype
  hchu
  hci
  hcmpview
  hco
  hcp
  hcpj
  hcropmrg
  hcrtpath
  hdbgctrl
  hdelss
  hdlp
  hdp
  hdv
  hexecp
  hexpenv
  hfatt
  hformsync
  hft
  hgetusg
  himpenv
  hlr
  hlv
  hmvitm
  hmvpkg
  hmvpth
  hpg
  hpkgunlk
  hpp
  hppolget
  hppolset
  hrefresh
  hrepedit
  hrepmngr
  hri
  hrmvpth
  hrnitm
  hrnpth
  hrt
  hsigget
  hsigset
  hsmtp
  hspp
  hsql
  hsv
  hsync
  htakess
  hucache
  hudp
  hup
  husrmgr
  husrunlk
);

my @private = qw(
  _init
  _err
  _run
  _get_run_context
  _get_option_str
  _get_cmd_options
  _handle_error
  _parse_log
);

can_ok( $cascm, @methods );
can_ok( $cascm, @commands );
can_ok( $cascm, @private );

foreach my $cmd (@commands) {
    ok( CASCM::Wrapper::_get_cmd_options("$cmd") )
      or diag "Missing options for $cmd";
} ## end foreach my $cmd (@commands)

done_testing();
