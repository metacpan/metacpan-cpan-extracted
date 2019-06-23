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
# $Id$
#
# For Notapad++: [ \t]+\r\n -> \r\n
# For Sublime  : [ \t]+\n
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
       filename_regex => qr/(?:\.(?:t|pm|pl|cgi|xs|c|h|pod|PL|conf)|Changes|TODO)\z/,
       abs_path_prune_re => qr(\Asrc),
   });

# TEST
$finder->no_trailing_space("No trailing space was found");

1;

__END__
