#!/usr/bin/env perl
# vim:ts=4:sw=4:noexpandtab
use strict;
use warnings;
use inc::Module::Install;

name     'AllKnowingDNS';
all_from 'script/all-knowing-dns';

requires 'Net::DNS';
requires 'Privileges::Drop';
requires 'Mouse';
requires 'MouseX::NativeTraits';
requires 'NetAddr::IP';

install_script 'all-knowing-dns';

postamble <<'END_OF_MAKEFILE';
install:: extra_install
pure_install:: extra_install
install_vendor:: extra_install

extra_install:
	install -d $(DESTDIR)/etc
	install -m 644 all-knowing-dns.conf $(DESTDIR)/etc/all-knowing-dns.conf
END_OF_MAKEFILE

WriteAll;
