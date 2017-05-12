#!perl
#
# This file is part of Acme::Tie::Eleet.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

#
# Basic tests.
#

#-----------------------------------#
#          Initialization.          #
#-----------------------------------#

# Modules we rely on.
use Test;
use POSIX qw(tmpnam);

BEGIN { plan tests => 3 };

# Vars.
my $file = tmpnam();


#--------------------------------#
#          Basic tests.          #
#--------------------------------#

# Loading the module.
eval { require Acme::Tie::Eleet; };
ok($@, "");


# Simple tiehandle.
eval {
    open OUT, ">$file" or die "Unable to create temporary file: $!";
    tie *OUT, 'Acme::Tie::Eleet', *OUT;
    untie *OUT;
};
ok($@, "");


# Simple tiescalar.
eval {
    my $scalar;
    tie $scalar, 'Acme::Tie::Eleet';
    untie $scalar;
};
ok($@, "");


unlink $file;
