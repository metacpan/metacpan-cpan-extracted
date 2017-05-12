#!/usr/bin/perl
# TestApp.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp;
use FindBin qw($Bin);
use Catalyst qw/Setenv/;
__PACKAGE__->config({environment => {FOO    => 'foo', 
				     BAR    => 'bar',
				     EXISTS => '::YYY',
				     PREPEND => 'YYY::',
				     NEW    => "\\:YYY",
				     SLASH  => "\\\\:YYY",
				     END    => "YYY\\\\:", }}
		   );
__PACKAGE__->setup;
1;
