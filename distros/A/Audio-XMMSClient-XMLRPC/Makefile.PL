use strict;
use warnings;
use inc::Module::Install;

name     ( 'Audio-XMMSClient-XMLRPC'      );
all_from ( 'lib/Audio/XMMSClient/XMLRPC.pm' );

requires ( 'RPC::XML'          );
requires ( 'Audio::XMMSClient' );

build_requires ( 'Test::More' );

install_script ( 'bin/xmms2-xmlrpc' );

auto_install ();
WriteAll ();
