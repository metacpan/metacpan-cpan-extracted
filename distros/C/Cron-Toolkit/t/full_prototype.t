use strict;
use warnings;
use Test::More;
use String::Util qw(trim);
use Cron::Toolkit;

my @tests = (

   # VALID TESTS (20)
   {
      expr                => '0 */15 * * * ? *',
      valid               => 1,
      field               => 1,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '15',
      english             => trim('every 15 minutes')
   },
   {
      expr              => '0 0 0 1-5 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'range',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight on the first through fifth of every month')
   },
   {
      expr              => '0 0 0 * * 1,3,5 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'list',
      expected_value    => undef,
      expected_children => 3,
      english           => trim('at midnight every Sunday, Tuesday and Thursday')
   },
   {
      expr                => '0 10-20/5 8 * * ? *',
      valid               => 1,
      field               => 1,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '5',
      english             => trim('every 5 minutes from 10 to 20 past 8')
   },
   {
      expr              => '0 0 0 L * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'last',
      expected_value    => 'L',
      expected_children => 0,
      english           => trim('at midnight on the last day of every month')
   },
   {
      expr              => '0 0 0 LW * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'lastW',
      expected_value    => 'LW',
      expected_children => 0,
      english           => trim('at midnight on the last weekday of every month')
   },
   {
      expr              => '0 0 0 ? * 1#3 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'nth',
      expected_value    => '1#3',
      expected_children => 0,
      english           => trim('at midnight on the third Sunday of every month')
   },
   {
      expr              => '0 0 0 * * ? 2025',
      valid             => 1,
      field             => 6,
      expected_type     => 'single',
      expected_value    => '2025',
      expected_children => 0,
      english           => trim('at midnight every day in 2025')
   },
   {
      expr                => '*/5 * * ? * ? *',
      valid               => 1,
      field               => 0,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '5',
      english             => trim('every 5 seconds')
   },
   {
      expr              => '30 45 14 LW * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'lastW',
      expected_value    => 'LW',
      expected_children => 0,
      english           => trim('at 2:45:30 PM on the last weekday of every month')
   },
   {
      expr              => '15 30 9 ? * 1#1 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'nth',
      expected_value    => '1#1',
      expected_children => 0,
      english           => trim('at 9:30:15 AM on the first Sunday of every month')
   },
   {
      expr              => '0 15 6 ? * 1#2 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'nth',
      expected_value    => '1#2',
      expected_children => 0,
      english           => trim('at 6:15:00 AM on the second Sunday of every month')
   },
   {
      expr                => '0 0 */3 ? * *',
      valid               => 1,
      field               => 2,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '3',
      english             => trim('every 3 hours')
   },
   {
      expr                => '*/15 * * ? * *',
      valid               => 1,
      field               => 0,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '15',
      english             => trim('every 15 seconds')
   },
   {
      expr              => '0 0 0 15 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'single',
      expected_value    => '15',
      expected_children => 0,
      english           => trim('at midnight on the 15th of every month')
   },
   {
      expr              => '0 30 * * * ? *',
      valid             => 1,
      field             => 1,
      expected_type     => 'single',
      expected_value    => '30',
      expected_children => 0,
      english           => trim('at 12:30:00 AM')
   },
   {
      expr              => '0 0 0 L-3 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'last',
      expected_value    => 'L-3',
      expected_children => 0,
      english           => trim('at midnight on the third last day of every month')
   },
   {
      expr              => '0 0 0 15W * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'nearest_weekday',
      expected_value    => '15W',
      expected_children => 0,
      english           => trim('at midnight on the nearest weekday to the 15th of every month')
   },
   {
      expr              => '0 0 0 ? * 2#3 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'nth',
      expected_value    => '2#3',
      expected_children => 0,
      english           => trim('at midnight on the third Monday of every month')
   },
   {
      expr              => '0 0 0 * * ? 2024-2025',
      valid             => 1,
      field             => 6,
      expected_type     => 'range',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight every day from 2024 to 2025')
   },

   # 🔥 NEW NAME TESTS (4!)
   {
      expr              => '0 0 0 ? JAN-MAR * *',
      valid             => 1,
      field             => 4,
      expected_type     => 'range',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight from January to March')
   },
   {
      expr              => '0 0 0 ? * MON-FRI *',
      valid             => 1,
      field             => 5,
      expected_type     => 'range',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight every Monday through Friday')
   },
   {
      expr              => '0 0 0 1 JAN ? *',
      valid             => 1,
      field             => 4,
      expected_type     => 'single',
      expected_value    => '1',
      expected_children => 0,
      english           => trim('at midnight on the first of every month in January')
   },
   {
      expr              => '0 0 0 ? * SUN *',
      valid             => 1,
      field             => 5,
      expected_type     => 'single',
      expected_value    => '1',
      expected_children => 0,
      english           => trim('at midnight every Sunday')
   },
   {
      expr              => '0 0 0 1,15 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'list',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight on the first and 15th of every month')
   },
   {
      expr              => '0 0 0 ? * 2-6 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'range',
      expected_value    => undef,
      expected_children => 2,
      english           => trim('at midnight every Monday through Friday')
   },
   {
      expr              => '0 0 0 29 * ? 2024',
      valid             => 1,
      field             => 3,
      expected_type     => 'single',
      expected_value    => '29',
      expected_children => 0,
      english           => trim('at midnight on the 29th of every month in 2024')
   },
   {
      expr                => '0 */5 * * * ? *',
      valid               => 1,
      field               => 1,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '5',
      english             => trim('every 5 minutes')
   },
   {
      expr                => '0 0 5/3 * * ? *',
      valid               => 1,
      field               => 2,
      expected_type       => 'step',
      expected_value      => undef,
      expected_children   => 2,
      expected_step_value => '3',
      english             => trim('every 3 hours starting at 5')
   },
   {
      expr              => '0 0 0 ? * 1#5 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'nth',
      expected_value    => '1#5',
      expected_children => 0,
      english           => trim('at midnight on the fifth Sunday of every month')
   },
   {
      expr              => '0 0 0 31W * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'nearest_weekday',
      expected_value    => '31W',
      expected_children => 0,
      english           => trim('at midnight on the nearest weekday to the 31st of every month')
   },

   # INVALID TESTS (8)
   {
      expr         => '0 0 0 LW-2 * ? *',
      valid        => 0,
      expect_error => qr/Unsupported field: LW-2 \(dom\)/
   },
   {
      expr         => '0 0 0 ? * 1W-5W *',
      valid        => 0,
      expect_error => qr/Unsupported field: 1W-5W \(dow\)/
   },
   {
      expr         => '0 0 0 99 * ? *',
      valid        => 0,
      expect_error => qr/dom 99 out of range \[1-31\]/
   },
   {
      expr         => '0 0 0 ? * 9#5 *',
      valid        => 0,
      expect_error => qr/dow 9 out of range \[1-7\]/
   },
   {
      expr         => '0 0 25 * * ? *',
      valid        => 0,
      expect_error => qr/hour 25 out of range \[0-23\]/
   },
   {
      expr         => '0 0 0 ? 13 * *',
      valid        => 0,
      expect_error => qr/month 13 out of range \[1-12\]/
   },
   {
      expr         => '0 0 0 @ * ? *',
      valid        => 0,
      expect_error => qr/Invalid characters/
   },
   {
      expr         => '0 0 0 L-X * ? *',
      valid        => 0,
      expect_error => qr/Invalid characters/
   },

   # 🔥 HYBRID LIST TESTS (8 NEW)
   {
      expr              => '0 0 0 * * 1,3,5 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'list',
      expected_children => 3,
      english           => trim('at midnight every Sunday, Tuesday and Thursday')
   },
   {
      expr              => '0 0 0 1,15 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'list',
      expected_children => 2,
      english           => trim('at midnight on the first and 15th of every month')
   },
   {
      expr              => '0 0 0 ? JAN,MAR * *',
      valid             => 1,
      field             => 4,
      expected_type     => 'list',
      expected_children => 2,
      english           => trim('at midnight in January and March')
   },
   {
      expr              => '0 0 0 ? * 1,7 *',
      valid             => 1,
      field             => 5,
      expected_type     => 'list',
      expected_children => 2,
      english           => trim('at midnight every Sunday and Saturday')
   },
   {
      expr              => '0 0 0 1,2,3,4,5 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'list',
      expected_children => 5,
      english           => trim('at midnight on the first through fifth of every month')
   },
   {
      expr              => '0 0 0 ? FEB,APR,JUN,AUG,OCT,DEC * *',
      valid             => 1,
      field             => 4,
      expected_type     => 'list',
      expected_children => 6,
      english           => trim('at midnight in February, April, June, August, October and December')
   },
   {
      expr              => '0 0 0 ? * MON,WED,FRI *',
      valid             => 1,
      field             => 5,
      expected_type     => 'list',
      expected_children => 3,
      english           => trim('at midnight every Monday, Wednesday and Friday')
   },
   {
      expr              => '0 0 0 10,20,30 * ? *',
      valid             => 1,
      field             => 3,
      expected_type     => 'list',
      expected_children => 3,
      english           => trim('at midnight on the 10th, 20th and 30th of every month')
   },
   {
      expr              => '0 0 0 ? * 2 2025',
      valid             => 1,
      field             => 5,
      expected_type     => 'single',
      expected_value    => '2',
      expected_children => 0,
      english           => trim('at midnight every Monday in 2025')
   },
);

for my $test (@tests) {
   subtest "Test: $test->{expr} (valid: $test->{valid})" => sub {
      my $raw     = $test->{expr};
      my $success = eval {
         my $cron       = Cron::Toolkit->new( expression => $raw );
         my $normalized = join( ' ', split /\s+/, $cron->{expression} );
         diag "RAW: '$raw' → NORMALIZED: '$normalized'";

         if ( !$test->{valid} ) {
            fail("Should have croaked for invalid expr");
            return 0;
         }

         ok( 1, "Built: $test->{expr}" );
         my @children = @{ $cron->{root}{children} };
         my $node     = $children[ $test->{field} ];
         diag "\n=== TREE DUMP for $test->{expr} FIELD $test->{field} ===";
         $node->dump_tree();
         diag "=== END TREE DUMP ===\n";

         is( $node->{type},                       $test->{expected_type},        "Type" );
         is( $node->{value} // '',                $test->{expected_value} // '', "Value" );
         is( scalar @{ $node->{children} || [] }, $test->{expected_children},    "Children" );
         if ( $test->{expected_step_value} ) {
            is( $node->{children}[1]{value}, $test->{expected_step_value}, "Step value" );
         }
         is( $cron->describe, $test->{english}, "English (expected: '$test->{english}')" );
         1;
      };

      if ($@) {
         if ( $test->{valid} ) {
            fail("Built VALID expr: $test->{expr}");
            diag "Error: $@";
         }
         else {
            like( $@, $test->{expect_error}, "PASS: Rejects INVALID '$test->{expr}'" );
         }
         return;    # SKIP NODE TESTS!
      }

      if ( !$test->{valid} ) {
         fail("Built INVALID expr: $test->{expr}");
         diag "Should have croaked!";
      }
   };
}
done_testing();
