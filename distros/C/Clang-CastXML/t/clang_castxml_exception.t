use Test2::V0 -no_srand => 1;
use 5.020;
use experimental qw( signatures );
use Clang::CastXML::Exception;

package Clang::CastXML::Exception::Frooble {
  use Moo;
  use 5.020;
  use experimental qw( signatures );
  extends 'Clang::CastXML::Exception';
  has x => ( is => 'ro', required => 1 );
  has y => ( is => 'ro', required => 1 );
  sub message ($self)
  {
    sprintf "frooble happened, x: %d, y: %d", $self->x, $self->y;
  }
}

our $line;
our $ex;

is(
  $ex = dies { $line = __LINE__; Clang::CastXML::Exception::Frooble->throw( x => 1, y => 2 ) },
  object {
    call [ isa => 'Clang::CastXML::Exception' ] => T();
    call [ isa => 'Clang::CastXML::Exception::Frooble' ] => T();
    call x => 1;
    call y => 2;
    call stack_trace => object {
      call [ isa => 'Devel::StackTrace' ] => T();
    };
    call message => 'frooble happened, x: 1, y: 2';
    call to_string => "frooble happened, x: 1, y: 2 at @{[ __FILE__ ]} line $line";
  },
);

done_testing;
