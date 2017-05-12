#!/usr/bin/perl
use strict;
use warnings; 
use Test::More tests => 10;

require_ok('DBI');
BEGIN {
  use_ok('Net::FTP');
  use_ok('IO::File');
  use_ok('Carp', 'croak');
  use_ok('DBD::MVS_FTPSQL');       
}

{
  my $drh = DBI->internal; # return $drh for internal Switch 'driver'
  ok( defined ($drh), 'DBI->internal returned something.' );
  isa_ok($drh, 'DBI::dr');
  undef($drh);
}

{
  my $drh = DBI->install_driver('MVS_FTPSQL') || diag ('Test installation through install_driver method failed.');
  ok( defined ($drh), 'DBI->install_driver returned something.' );
  isa_ok($drh, 'DBI::dr');
  ok (defined($drh->{Version}), 'DBD::MVS_FTPSQL Version defined') &&
    diag('DBD::MVS_FTPSQL version '. $drh->{Version} ."\n");
}

__END__ 