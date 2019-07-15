#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 60 2019-07-14 09:57:26Z abalama $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('App::MonM::Notifier') };
ok(App::MonM::Notifier->VERSION,'Version');

1;
__END__
