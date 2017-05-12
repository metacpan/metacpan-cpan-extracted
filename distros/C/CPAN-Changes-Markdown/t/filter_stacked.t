
use strict;
use warnings;

use Test::More tests => 10;

use CPAN::Changes::Markdown::Filter;
use CPAN::Changes::Markdown::Filter::RuleUtil qw( :all );

my $filter = CPAN::Changes::Markdown::Filter->new( rules => [ rule_UnderscoredToCode, rule_VersionsToCode ] );

is( $filter->process("something_underscored"), "`something_underscored`", 'underscores highlight' );
is( $filter->process("1.0"),                   "`1.0`",                   'single decimals highlight' );
is( $filter->process("1.0.0"),                 "`1.0.0`",                 'multipart decimals highlight' );
is( $filter->process("v1.0"),                  "`v1.0`",                  'single decimals with v-prefix highlight' );
is( $filter->process("v1.0.0"),                "`v1.0.0`",                'multipart decimals with v-prefix highlight' );

is( $filter->process("something_underscored 1.0"), "`something_underscored` `1.0`", '+underscore single decimals highlight' );
is(
  $filter->process("something_underscored 1.0.0"),
  "`something_underscored` `1.0.0`",
  '+underscore multipart decimals highlight'
);
is(
  $filter->process("something_underscored v1.0"),
  "`something_underscored` `v1.0`",
  '+underscore single decimals with v-prefix highlight'
);
is(
  $filter->process("something_underscored v1.0.0"),
  "`something_underscored` `v1.0.0`",
  '+underscore multipart decimals with v-prefix highlight'
);
use charnames qw( :full );
my ( $source, $target );
$source = "Dist::Zilla::PluginBundle::Author::KENTNL v1.0.0\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}v1.3.0";
$target = "Dist::Zilla::PluginBundle::Author::KENTNL `v1.0.0`\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}`v1.3.0`";

is( $filter->process($source), $target, "Unicode containing string works" );
