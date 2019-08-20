# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 1);

my %keywords = (
    core => {
	section => {
	    name => {
		check => sub {
		    my ($self, $vref, $prev, $loc) = @_;
		    if ($$vref !~ /^[A-Z]/) {
			$self->error("must start with a capital letter",
				     locus => $loc);
			return 0;
		    }
		    return 1;
		}
	    }
	}
    }
);

ok(new TestConfig(
       config => [
	   'core.name' => 'foo'
       ],
       lexicon => \%keywords,
       expect => [ "must start with a capital letter" ]));


