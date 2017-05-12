use strict;
use warnings;

use Test::More tests => 5;

use CPAN::Changes::Markdown::Filter;
use CPAN::Changes::Markdown::Filter::RuleUtil qw( :all );

my $filter = CPAN::Changes::Markdown::Filter->new( rules => [ rule_VersionsToCode, ] );

is( $filter->process("this is a test\n"),   "this is a test\n",     "no numbers == no highlights" );
is( $filter->process("hell 1.0 world\n"),   "hell `1.0` world\n",   "simple numbers are versions" );
is( $filter->process("hell 1.0_ world\n"),  "hell `1.0_` world\n",  "simple numbers include underscores as versions" );
is( $filter->process("hell v1.0_ world\n"), "hell `v1.0_` world\n", "v is extracted as part of the version" );
is( $filter->process("hell v1.0_-TRIAL world\n"), "hell `v1.0_-TRIAL` world\n", "-TRIAL is extracted as part of the version" );
