#!/usr/bin/perl

use v5.26;
use warnings;
use experimental qw( signatures );

use Test2::V0;

use Tickit::Test;

use App::sdview::Output::Tickit;

# Testing is simpler with a smaller window
mk_term lines => 10, cols => 40;
my $win = mk_window;

my $incremental_re;
my $entered_re;

my $searchbox = App::sdview::Output::Tickit::_SearchBox->new(
   on_incremental => sub ( $searchbox, $re ) { $incremental_re = $re; },
   on_enter       => sub ( $searchbox, $re ) { $entered_re = $re; }
);

$searchbox->set_window( $win );

my $float_hidden;
package MockFloat {
   sub hide { $float_hidden++ }
}
$searchbox->set_float( bless {}, "MockFloat" );

# Avoids repetition
my @PEN = ( b=>1,bg=>8,fg=>16 );

# initial
{
   flush_tickit;

   is_display( [ [TEXT("Search:",@PEN), BLANK(30,@PEN), TEXT("(0)",@PEN)] ],
      'Display initially' );
}

# type to build pattern
{
   presskey text => "a";
   flush_tickit;

   is_display( [ [TEXT("Search: a",@PEN), BLANK(28,@PEN), TEXT("(0)",@PEN)] ],
      'Display after typing "a"' );
   is( "$incremental_re", "(?^u:(?:a))",
      'on_incremental after typing "a"' );

   presskey text => "b";
   flush_tickit;

   is_display( [ [TEXT("Search: ab",@PEN), BLANK(27,@PEN), TEXT("(0)",@PEN)] ],
      'Display after typing "b"' );
   is( "$incremental_re", "(?^u:(?:ab))",
      'on_incremental after typing "b"' );

   presskey key => "Backspace";
   flush_tickit;

   is_display( [ [TEXT("Search: a",@PEN), BLANK(28,@PEN), TEXT("(0)",@PEN)] ],
      'Display after typing Backspace' );
   is( "$incremental_re", "(?^u:(?:a))",
      'on_incremental after typing Backspace' );
}

# enter accepts
{
   presskey key => "Enter";
   flush_tickit;

   is( "$entered_re", "(?^u:(?:a))",
      'on_enter after typing Enter' );
   ok( $float_hidden, 'float is hidden by Enter' );
}

# matchcount
{
   $searchbox->set_matchcount( 5 );
   flush_tickit;

   is_display( [ [TEXT("Search: a",@PEN), BLANK(28,@PEN), TEXT("(5)",@PEN)] ],
      'Display after setting matchcount' );
}

# Alt-i for ignorecase
{
   presskey key => "M-i";
   flush_tickit;

   is( "$incremental_re", "(?^u:(?i:a))",
      'on_enter after typing M-i' );
   is_display( [ [TEXT("Search: a",@PEN), BLANK(25,@PEN), TEXT("/i ",@PEN),TEXT("(5)",@PEN)] ],
      'Display after typing M-i' );
}

# Alt-w for wholeword
{
   presskey key => "M-w";
   flush_tickit;

   is( "$incremental_re", "(?^u:\\b(?i:a)\\b)",
      'on_enter after typing M-w' );
   is_display( [ [TEXT("Search: a",@PEN), BLANK(23,@PEN), TEXT("W /i ",@PEN),TEXT("(5)",@PEN)] ],
      'Display after typing M-w' );
}

done_testing;
