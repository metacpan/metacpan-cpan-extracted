#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-trailingspace.t 158 2017-01-31 16:14:06Z minus $
#
# For Notapad++: [ \t]+\r\n -> \r\n
#
#########################################################################
use strict;
use Test::More;

eval "use Test::TrailingSpace";
plan skip_all => "Test::TrailingSpace required for trailing space test" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

plan tests => 1;

my $finder = Test::TrailingSpace->new({
       root => '.',
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|README|CHANGES|TODO|LICENSE)\z/,
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;
__END__
