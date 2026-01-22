#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
# For Notapad++: [ \t]+\r\n -> \r\n
# For Sublime Text: [ \t]+\n
#
#########################################################################
use strict;
use Test::More;

eval "use Test::TrailingSpace";
plan skip_all => "Test::TrailingSpace required for trailing space test" if $@;

plan tests => 1;

my $finder = Test::TrailingSpace->new({
       root => '.',
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|README.md|Changes|TODO|LICENSE)\z/,
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;

__END__
