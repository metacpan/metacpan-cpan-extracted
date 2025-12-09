#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
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
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|README.md|Changes|TODO|LICENSE|distsync)\z/,
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;

__END__

prove -lv t/00-trailingspace.t
