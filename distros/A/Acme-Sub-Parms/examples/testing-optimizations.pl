#!/usr/bin/perl

use strict;
use warnings;

use Acme::Sub::Parms qw(:no_validation);

############
# Example 1
BindParms : (
     my $thing       : thing [optional];
     my $other_thing : other_thing [required];
     my $third_thing : third_thing [callback=callback_example];
)
#

sub callback_example {
	return 1;
}
