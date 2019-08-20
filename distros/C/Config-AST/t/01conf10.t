# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 2);

my %keywords = (
    base => { mandatory => 1 },
    file => { default => sub {
	my $self = shift;
	return $self->get('base') . '/passwd';
      }
    },
    index => {
	default => 0
    }
);

my $t = new TestConfig(
    config => [
	base => '/etc'
    ],
    lexicon => \%keywords);
ok($t->get('file'), '/etc/passwd');
ok($t->get('index'), 0);

