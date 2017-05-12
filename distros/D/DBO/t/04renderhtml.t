# DBO test skeleton (-*- cperl -*-)

use lib './t';
use harness;
use DBO::Visitor::RenderHTML;
require 't/test-begin.pl';

my @tests =
  (
   {
    id			=> 1,
    col_char		=> '012345678901234',
    col_text		=> 'foo' x 10,
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> -100,
    col_unsigned	=> 65536,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
    expected            => <<END,
<BLOCKQUOTE><TABLE BORDER=0 CELLSPACING=0>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">id</TD>
<TD ALIGN="LEFT">1</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_char</TD>
<TD ALIGN="LEFT">012345678901234</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_text</TD>
<TD ALIGN="LEFT">foofoofoofoofoofoofoofoofoofoo</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time1</TD>
<TD ALIGN="LEFT">1999-06-15 14:30:56</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time2</TD>
<TD ALIGN="LEFT">1999-06-15 00:00:00</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_integer</TD>
<TD ALIGN="LEFT">-100</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_unsigned</TD>
<TD ALIGN="LEFT">65536</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_unsigned</TD>
<TD ALIGN="LEFT">0</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_char</TD>
<TD ALIGN="LEFT">red</TD></TR>
</TABLE></BLOCKQUOTE>
END
   },
   {
    id			=> 2,
    col_char		=> '012345678901234',
    col_text		=> q('"="'),
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> -1234,
    col_unsigned	=> 65536,
    col_option_unsigned	=> 1,
    col_option_char	=> 'white',
    expected            => <<END,
<BLOCKQUOTE><TABLE BORDER=0 CELLSPACING=0>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">id</TD>
<TD ALIGN="LEFT">2</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_char</TD>
<TD ALIGN="LEFT">012345678901234</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_text</TD>
<TD ALIGN="LEFT">'&quot;=&quot;'</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time1</TD>
<TD ALIGN="LEFT">1999-06-15 14:30:56</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time2</TD>
<TD ALIGN="LEFT">1999-06-15 00:00:00</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_integer</TD>
<TD ALIGN="LEFT">-1234</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_unsigned</TD>
<TD ALIGN="LEFT">65536</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_unsigned</TD>
<TD ALIGN="LEFT">1</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_char</TD>
<TD ALIGN="LEFT">white</TD></TR>
</TABLE></BLOCKQUOTE>
END
   },
   {
    id			=> 3,
    col_char		=> '',
    col_text		=> '',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'blue',
    expected            => <<END,
<BLOCKQUOTE><TABLE BORDER=0 CELLSPACING=0>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">id</TD>
<TD ALIGN="LEFT">3</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_char</TD>
<TD ALIGN="LEFT"></TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_text</TD>
<TD ALIGN="LEFT"></TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time1</TD>
<TD ALIGN="LEFT">1999-06-15 14:30:56</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_time2</TD>
<TD ALIGN="LEFT">1999-06-15 00:00:00</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_integer</TD>
<TD ALIGN="LEFT">0</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_unsigned</TD>
<TD ALIGN="LEFT">0</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_unsigned</TD>
<TD ALIGN="LEFT">0</TD></TR>
<TR VALIGN="TOP"><TD ALIGN="RIGHT">col_option_char</TD>
<TD ALIGN="LEFT">blue</TD></TR>
</TABLE></BLOCKQUOTE>
END
   },
  );


test {
  my $renderer = DBO::Visitor::RenderHTML->new;
  foreach my $test (@tests) {
    $renderer->{record} = $test;
    my $result = $dbo->apply_to_table("${TABLE}1", $renderer);
    $result eq $test->{expected}
      or die "--- Test $test->{id}: expected ---\n$test->{expected}\n--- but found ---\n$result\n---\n";
  }
};

require 't/test-end.pl';
