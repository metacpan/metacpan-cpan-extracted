use Test2::V0 -no_srand => 1;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
BEGIN { $ENV{PERL_INLINE_DIRECTORY} = tempdir( DIR => path('.')->absolute->stringify, CLEANUP => 1, TEMPLATE => 'inlineXXXXX') }
use Acme::Alien::DontPanic;
use Inline 0.56 with => 'Acme::Alien::DontPanic';
use Inline CPP => 'DATA', ENABLE => 'AUTOWRAP';

is Foo->new->string_answer, "the answer to life the universe and everything is 42", 'indirect';
is answer(), 42, "direct";

done_testing;

__DATA__
__CPP__

#include <stdio.h>

class Foo {
public:
  char *string_answer()
  {
    static char buffer[1024];
    sprintf(buffer, "the answer to life the universe and everything is %d", answer());
    return buffer;
  }
};

extern int answer();
