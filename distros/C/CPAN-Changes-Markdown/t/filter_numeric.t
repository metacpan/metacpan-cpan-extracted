use strict;
use warnings;

use Test::More tests => 6;

use CPAN::Changes::Markdown::Filter;
use CPAN::Changes::Markdown::Filter::RuleUtil qw( :all );

my $filter = CPAN::Changes::Markdown::Filter->new( rules => [rule_NumericsToCode] );

is( $filter->process("this is a test\n"),       "this is a test\n",       "no numbers = no highlight" );
is( $filter->process("hell 1.0 world\n"),       "hell `1.0` world\n",     "numeric extraction ok" );
is( $filter->process("hell 1.0_ world\n"),      "hell `1.0_` world\n",    "numeric with underscore ok" );
is( $filter->process("hell1.0_ world\n"),       "hell1.0_ world\n",       "hugging text == not a number" );
is( $filter->process("hell v1.0 world\n"),      "hell v1.0 world\n",      "hugging text(v) == not a number" );
is( $filter->process("hell 1.0-TRIAL world\n"), "hell 1.0-TRIAL world\n", "hugging text(-TRIAL) == not a number" );
