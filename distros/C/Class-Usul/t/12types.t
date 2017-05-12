use t::boilerplate;

use Test::More;
use English qw( -no_match_vars );
use Try::Tiny;
use Unexpected::Functions qw( catch_class );

{  package MyNLC;

   use Moo;
   use Class::Usul::Types qw( NullLoadingClass );

   has 'test1' => is => 'ro', isa => NullLoadingClass, coerce => 1,
      default  => 'Class::Usul';
   has 'test2' => is => 'ro', isa => NullLoadingClass, coerce => 1,
      default  => 'FooX::BarT';

   $INC{ 'MyNLC.pm' } = __FILE__;
}

my $obj = MyNLC->new;

is $obj->test1, 'Class::Usul', 'NullLoadingClass - loads if exists';
is $obj->test2, 'Class::Null', 'NullLoadingClass - loads Class::Null if not';

{  package MyDT;

   use Moo;
   use Class::Usul::Types qw( DateTimeRef );

   has 'dt1'  => is => 'ro',   isa => DateTimeRef, coerce => 1,
      default => '11/9/2001 12:00 UTC';
   has 'dt2'  => is => 'lazy', isa => DateTimeRef, coerce => 1,
      default => 'today at noon';

   $INC{ 'MyDT.pm' } = __FILE__;
}

$obj = MyDT->new;

is $obj->dt1, '2001-09-11T12:00:00', 'DateTimeRef - coerces from string';

eval { $obj->dt2 }; my $e = $EVAL_ERROR;

is $e->class, 'DateTimeCoercion', 'DateTimeRef - throw expected class';

my $ret = '';

try         { $obj->dt2 }
catch_class [ 'DateTimeCoercion' => sub { $ret = 'handled' } ];

is $ret, 'handled', 'DateTimeRef - can catch_class';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
