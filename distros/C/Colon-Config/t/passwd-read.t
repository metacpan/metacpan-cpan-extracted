#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

#use Test::More;
use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;

# kind of a combo test
my $content = <<'EOS';
adm:!:4:4::/var/adm:
bin:!:2:2::/bin:
daemon:!:1:1::/etc:
guest:!:100:100::/home/guest:
invscout:*:200:1::/var/adm/invscout:/usr/bin/ksh
jdoe:*:202:1:John Doe:/home/jdoe:/usr/bin/ksh
lp:*:11:11::/var/spool/lp:/bin/false
lpd:!:9:4294967294::/:
nobody:!:4294967294:4294967294::/:
nuucp:*:6:5:uucp login user:/var/spool/uucppublic:/usr/sbin/uucp/uucico
paul:!:201:1::/home/paul:/usr/bin/ksh
root:!:0:0::/:/usr/bin/ksh
sys:!:3:3::/usr/sys:
uucp:!:5:5::/usr/lib/uucp:
EOS

my $h;

$h = Colon::Config::read_as_hash($content);
is $h,
  {
    'adm'      => '!:4:4::/var/adm:',
    'bin'      => '!:2:2::/bin:',
    'daemon'   => '!:1:1::/etc:',
    'guest'    => '!:100:100::/home/guest:',
    'invscout' => '*:200:1::/var/adm/invscout:/usr/bin/ksh',
    'jdoe'     => '*:202:1:John Doe:/home/jdoe:/usr/bin/ksh',
    'lp'       => '*:11:11::/var/spool/lp:/bin/false',
    'lpd'      => '!:9:4294967294::/:',
    'nobody'   => '!:4294967294:4294967294::/:',
    'nuucp'    => '*:6:5:uucp login user:/var/spool/uucppublic:/usr/sbin/uucp/uucico',
    'paul'     => '!:201:1::/home/paul:/usr/bin/ksh',
    'root'     => '!:0:0::/:/usr/bin/ksh',
    'sys'      => '!:3:3::/usr/sys:',
    'uucp'     => '!:5:5::/usr/lib/uucp:'
  },
  "read passwd file default field=0" or diag explain $h;

is Colon::Config::read_as_hash( $content, 0 ), $h, "setting field to 0 is similar to do not set it";

$h = Colon::Config::read_as_hash( $content, 1 );
is $h,
  {
    'adm'      => '!',
    'bin'      => '!',
    'daemon'   => '!',
    'guest'    => '!',
    'invscout' => '*',
    'jdoe'     => '*',
    'lp'       => '*',
    'lpd'      => '!',
    'nobody'   => '!',
    'nuucp'    => '*',
    'paul'     => '!',
    'root'     => '!',
    'sys'      => '!',
    'uucp'     => '!'
  },
  "read passwd file default field=1" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 2 );
is $h,
  {
    'adm'      => '4',
    'bin'      => '2',
    'daemon'   => '1',
    'guest'    => '100',
    'invscout' => '200',
    'jdoe'     => '202',
    'lp'       => '11',
    'lpd'      => '9',
    'nobody'   => '4294967294',
    'nuucp'    => '6',
    'paul'     => '201',
    'root'     => '0',
    'sys'      => '3',
    'uucp'     => '5'
  },
  "read passwd file default field=2" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 3 );
is $h,
  {
    'adm'      => '4',
    'bin'      => '2',
    'daemon'   => '1',
    'guest'    => '100',
    'invscout' => '1',
    'jdoe'     => '1',
    'lp'       => '11',
    'lpd'      => '4294967294',
    'nobody'   => '4294967294',
    'nuucp'    => '5',
    'paul'     => '1',
    'root'     => '0',
    'sys'      => '3',
    'uucp'     => '5'
  },
  "read passwd file default field=3" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 4 );
is $h,
  {
    'adm'      => undef,
    'bin'      => undef,
    'daemon'   => undef,
    'guest'    => undef,
    'invscout' => undef,
    'jdoe'     => 'John Doe',
    'lp'       => undef,
    'lpd'      => undef,
    'nobody'   => undef,
    'nuucp'    => 'uucp login user',
    'paul'     => undef,
    'root'     => undef,
    'sys'      => undef,
    'uucp'     => undef
  },
  "read passwd file default field=4" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 5 );
is $h,
  {
    'adm'      => '/var/adm',
    'bin'      => '/bin',
    'daemon'   => '/etc',
    'guest'    => '/home/guest',
    'invscout' => '/var/adm/invscout',
    'jdoe'     => '/home/jdoe',
    'lp'       => '/var/spool/lp',
    'lpd'      => '/',
    'nobody'   => '/',
    'nuucp'    => '/var/spool/uucppublic',
    'paul'     => '/home/paul',
    'root'     => '/',
    'sys'      => '/usr/sys',
    'uucp'     => '/usr/lib/uucp'
  },
  "read passwd file default field=5" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 6 );
is $h,
  {
    'adm'      => undef,
    'bin'      => undef,
    'daemon'   => undef,
    'guest'    => undef,
    'invscout' => '/usr/bin/ksh',
    'jdoe'     => '/usr/bin/ksh',
    'lp'       => '/bin/false',
    'lpd'      => undef,
    'nobody'   => undef,
    'nuucp'    => '/usr/sbin/uucp/uucico',
    'paul'     => '/usr/bin/ksh',
    'root'     => '/usr/bin/ksh',
    'sys'      => undef,
    'uucp'     => undef
  },
  "read passwd file default field=6" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 7 );
is $h,
  {
    'adm'      => undef,
    'bin'      => undef,
    'daemon'   => undef,
    'guest'    => undef,
    'invscout' => undef,
    'jdoe'     => undef,
    'lp'       => undef,
    'lpd'      => undef,
    'nobody'   => undef,
    'nuucp'    => undef,
    'paul'     => undef,
    'root'     => undef,
    'sys'      => undef,
    'uucp'     => undef
  },
  "read passwd file default field=7" or diag explain $h;

$h = Colon::Config::read_as_hash( $content, 99 );
is $h,
  {
    'adm'      => undef,
    'bin'      => undef,
    'daemon'   => undef,
    'guest'    => undef,
    'invscout' => undef,
    'jdoe'     => undef,
    'lp'       => undef,
    'lpd'      => undef,
    'nobody'   => undef,
    'nuucp'    => undef,
    'paul'     => undef,
    'root'     => undef,
    'sys'      => undef,
    'uucp'     => undef
  },
  "read passwd file default field=99" or diag explain $h;

done_testing;

__END__
