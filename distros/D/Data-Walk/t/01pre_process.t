# Data::Walk - Traverse Perl data structures.
# Copyright (C) 2005-2016 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

use strict;

use Test;
use Data::Walk;

BEGIN {
    plan tests => 160;
}

my ($wanted, $count, $preprocess, $preprocessor_calls, $last);

my %data = ('A' .. 'Z', 'a' .. 'z');

$preprocessor_calls = 0;
$preprocess = sub {
    my %container = @_;
    my @sorted;
	
    foreach my $key (sort keys %container) {
        push @sorted, $key, $container{$key};
    }

    ++$preprocessor_calls;
    return @sorted;
};

$last = '';
$wanted = sub {
    unless (ref $_) {
        ok($_ gt $last);
	$last = $_;
    }
};
walk { wanted => $wanted, preprocess => $preprocess}, \%data;

ok $preprocessor_calls;

my @data = ('A' .. 'Z', 'a' .. 'z');

$preprocessor_calls = 0;
$preprocess = sub {
    ++$preprocessor_calls;
   return reverse sort @_;
};

$last = chr (1 + ord $data[-1]);
$wanted = sub {
    unless (ref $_) {
        ok($_ lt $last);
        $last = $_;
    }
};
walk { wanted => $wanted, preprocess => $preprocess}, \@data;

ok $preprocessor_calls;

%data = ('A' .. 'Z', 'a' .. 'z');

$preprocessor_calls = 0;
$preprocess = sub {
    my %container = @_;
    my @sorted;
	
    foreach my $key (sort keys %container) {
        push @sorted, $key, $container{$key};
    }

    ++$preprocessor_calls;
    return @sorted;
};

$last = '';
$wanted = sub {
    unless (ref $_) {
        ok($_ gt $last);
        $last = $_;
    }
};
walk { wanted => $wanted, preprocess_hash => $preprocess}, \%data;

ok $preprocessor_calls;

@data = ('A' .. 'Z', 'a' .. 'z');

$preprocessor_calls = 0;
$preprocess = sub {
    ++$preprocessor_calls;
};

$wanted = sub {};
walk { wanted => $wanted, preprocess_hash => $preprocess}, \@data;

ok(!$preprocessor_calls);
