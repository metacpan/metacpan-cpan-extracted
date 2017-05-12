
package Data::HexDump::Range ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{

use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.13';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

use List::Util qw(min max) ;
use List::MoreUtils qw(all) ;
use Scalar::Util qw(looks_like_number) ;
use Term::ANSIColor ;
use Data::TreeDumper ;

use Data::HexDump::Range::Object ;
use Data::HexDump::Range::Gather ;
use Data::HexDump::Range::Split ;
use Data::HexDump::Range::Format ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range - Hexadecimal Range Dumper with color, bitfields and skip ranges

=head1 SYNOPSIS

  my $hdr = Data::HexDump::Range->new() ;
  
  print $hdr->dump([['magic cookie', 12, 'red'],['image type', 2, 'green']],  $data) ;
  print $hdr->dump('magic cookie, 12, red :image type, 2, green',  $data) ;
  
  $hdr->gather(['magic cookie', 12, 'red'], $data) ; 
  $hdr->gather(['image type', 2, 'green'], $other_data) ;
  
  print $hdr->dump_gathered() ;
  $hdr->reset() ;

=head1 DESCRIPTION

Creates a dump from binary data and user defined I<range> descriptions. The goal of this module is
to create an easy to understand dump of binary data. 

This achieved through:

=over 2

=item * Highlighted (colors) dump that is easier to understand than a monochrome blob of hex data

=item * Multiple rendering modes with different output formats

=item * Bitfield rendering

=item * Skipping uninterresting data

=item * The possibility to describe complex structures

=back

=head1 DOCUMENTATION

The shortest perl dumper is C<perl -ne 'BEGIN{$/=\16} printf "%07x0: @{[unpack q{(H2)*}]}\n", $.-1'>, courtesy of a golfing session 
with Andrew Rodland <arodland@cpan.org> aka I<hobbs>. I<priodev>, I<tm604>, I<Khisanth> and other provided valuable insight particularely  with the html output.

B<hexd> from libma L<http://www.ioplex.com/~miallen/libmba/> is nice tools that inspired me to write this module. This module offers many
more options but B<hexd> may be a better  alternative If you need very fast dump generation.

B<Data::HexDump::Range> splits binary data according to user defined I<ranges> and renderes them as a B<hex> or/and B<decimal> data dump.
The data dump can be rendered in ANSI, ASCII or HTML.

=head2 Rendered Columns

You can choose which columns are rendered by setting options when creating a Data::HexDump::Range object.
The default rendering  includes the following

  RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP ASCII_DUMP

which corresponds to the object below:

  Data::HexDump::Range->new
	(
	FORMAT => 'ANSI',
	COLOR => 'cycle',
	
	ORIENTATION => 'horizontal',
	
	DISPLAY_RANGE_NAME => 1 ,
	
	DISPLAY_OFFSET  => 1 ,
	OFFSET_FORMAT => 'hex',
	
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_ASCII_DUMP => 1,
	
	DATA_WIDTH => 16,
	) ;

If you decided that you wanted the binary data to be showed in decimal instead for hexadecimal, you' set DISPLAY_HEX_DUMP => 0 and DISPLAY_DEC_DUMP => 1.
See L<new> for all the possible options. Most option are also available from the command line utility I<hdr>.

=head2 Orientation

The examples below show the output of the following command:

  $>hdr -r 'magic cookie,12:padding, 32:header,5:data, 20:extra data,#:header,5:data,40:footer,4' -col -o ver -display_ruler lib/Data/HexDump/Range.pm

=head3 Vertical orientation

In this orientation mode, each range displayed on a separate line.

  RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP        
                                     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345  
  magic cookie     00000000 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74              .package Dat     
  padding          0000000c 00000000                                     61 3a 3a 48              a::H 
  padding          00000010 00000004 65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a  exDump::Range ;. 
  padding          00000020 00000014 0a 75 73 65 20 73 74 72 69 63 74 3b              .use strict;     
  header           0000002c 00000000                                     0a 75 73 65              .use 
  header           00000030 00000004 20                                                                
  data             00000031 00000000    77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20   warnings ;.use  
  data             00000040 0000000f 43 61 72 70 20                                   Carp             
  "extra data" 
  header           00000045 00000000                3b 0a 0a 42 45                         ;..BE       
  data             0000004a 00000000                               47 49 4e 20 0a 7b            GIN .{ 
  data             00000050 00000006 0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72  ..use Sub::Expor 
  data             00000060 00000016 74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09  ter -setup => .. 
  data             00000070 00000026 7b 0a                                            {.               
  footer           00000072 00000000       09 65 78 70                                  .exp           

In colors:

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">
<span style = 'color:#fff; '>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff; '>                                   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0f0; '>magic cookie    </span><span style = 'color:#fff;  color:#0f0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>0a 70 61 63 6b 61 67 65 20 44 61 74 </span><span style = 'color:#fff;  color:#0f0; '>            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>.package Dat</span><span style = 'color:#fff;  color:#0f0; '>    </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff;  color:#ff0; '>padding         </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>0000000c</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>                                    </span><span style = 'color:#fff;  color:#ff0; '>61 3a 3a 48 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>            </span><span style = 'color:#fff;  color:#ff0; '>a::H</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '>padding         </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000010</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000004</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>exDump::Range ;.</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '>padding         </span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000020</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000014</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>0a 75 73 65 20 73 74 72 69 63 74 3b </span><span style = 'color:#fff;  color:#ff0; '>            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>.use strict;</span><span style = 'color:#fff;  color:#ff0; '>    </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '></span><span style = 'color:#fff;  color:#0ff; '>header          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>0000002c</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>                                    </span><span style = 'color:#fff;  color:#0ff; '>0a 75 73 65 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>            </span><span style = 'color:#fff;  color:#0ff; '>.use</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>header          </span><span style = 'color:#fff;  color:#0ff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000030</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000004</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>20 </span><span style = 'color:#fff;  color:#0ff; '>                                             </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '> </span><span style = 'color:#fff;  color:#0ff; '>               </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f0f; '></span><span style = 'color:#fff;  color:#f0f; '>data            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000031</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>   </span><span style = 'color:#fff;  color:#f0f; '>77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '> </span><span style = 'color:#fff;  color:#f0f; '>warnings ;.use </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f0f; '>data            </span><span style = 'color:#fff;  color:#f0f; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000040</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>0000000f</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>43 61 72 70 20 </span><span style = 'color:#fff;  color:#f0f; '>                                 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>Carp </span><span style = 'color:#fff;  color:#f0f; '>           </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f00; '>&quot;extra data&quot;</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff;  color:#ff0; '>header          </span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000045</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>               </span><span style = 'color:#fff;  color:#ff0; '>3b 0a 0a 42 45 </span><span style = 'color:#fff;  color:#ff0; '>                  </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>     </span><span style = 'color:#fff;  color:#ff0; '>;..BE</span><span style = 'color:#fff;  color:#ff0; '>      </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '></span><span style = 'color:#fff;  color:#0ff; '>data            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>0000004a</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>                              </span><span style = 'color:#fff;  color:#0ff; '>47 49 4e 20 0a 7b </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>          </span><span style = 'color:#fff;  color:#0ff; '>GIN .{</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>data            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000050</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000006</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>..use Sub::Expor</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>data            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000060</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000016</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>ter -setup =&gt; ..</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>data            </span><span style = 'color:#fff;  color:#0ff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000070</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000026</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>7b 0a </span><span style = 'color:#fff;  color:#0ff; '>                                          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>{.</span><span style = 'color:#fff;  color:#0ff; '>              </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0f0; '></span><span style = 'color:#fff;  color:#0f0; '>footer          </span><span style = 'color:#fff;  color:#0f0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000072</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>      </span><span style = 'color:#fff;  color:#0f0; '>09 65 78 70 </span><span style = 'color:#fff;  color:#0f0; '>                              </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>  </span><span style = 'color:#fff;  color:#0f0; '>.exp</span><span style = 'color:#fff;  color:#0f0; '>          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span>
</pre>

=end html

=head3 Horizontal orientation

In this mode, the data are packed together in the dump

 OFFSET   HEX_DUMP                                         ASCII_DUMP       RANGE_NAME
          0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345
 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74 61 3a 3a 48  .package Data::H magic cookie, padding,
 00000020 65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a  exDump::Range ;. padding,
 00000030 0a 75 73 65 20 73 74 72 69 63 74 3b 0a 75 73 65  .use strict;.use padding, header,
 00000050 20 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20   warnings ;.use  header, data,
 00000070 43 61 72 70 20 3b 0a 0a 42 45 47 49 4e 20 0a 7b  Carp ;..BEGIN .{ data, "extra data", header, data,
 000000a0 0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72  ..use Sub::Expor data,
 000000b0 74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09  ter -setup => .. data,
 000000c0 7b 0a 09 65 78 70                                {..exp           data, footer,

In colors:

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">

<span style='color:#fff;'>OFFSET   HEX_DUMP                                         ASCII_DUMP       RANGE_NAME              </span> 
<span style='color:#fff;'>         0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345                         </span> 
<span style='color:#fff;'>00000000</span><span style='color:#fff;'></span> <span style='color:#0f0;'>0a 70 61 63 6b 61 67 65 20 44 61 74 </span><span style='color:#ff0;'>61 3a 3a 48 </span> <span style='color:#0f0;'>.package Dat</span><span style='color:#ff0;'>a::H</span> <span style='color:#0f0;'>magic cookie</span><span style='color:#fff;'>, </span><span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000020</span> <span style='color:#ff0;'>65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a </span> <span style='color:#ff0;'>exDump::Range ;.</span> <span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000030</span><span style='color:#fff;'></span> <span style='color:#ff0;'>0a 75 73 65 20 73 74 72 69 63 74 3b </span><span style='color:#f0f;'>0a 75 73 65 </span> <span style='color:#ff0;'>.use strict;</span><span style='color:#f0f;'>.use</span> <span style='color:#ff0;'>padding</span><span style='color:#fff;'>, </span><span style='color:#f0f;'>header</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000050</span><span style='color:#fff;'></span> <span style='color:#f0f;'>20 </span><span style='color:#f00;'>77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 </span> <span style='color:#f0f;'> </span><span style='color:#f00;'>warnings ;.use </span> <span style='color:#f0f;'>header</span><span style='color:#fff;'>, </span><span style='color:#f00;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>00000070</span><span style='color:#fff;'></span><span style='color:#fff;'></span> <span style='color:#f00;'>43 61 72 70 20 </span><span style='color:#0f0;'>3b 0a 0a 42 45 </span><span style='color:#ff0;'>47 49 4e 20 0a 7b </span> <span style='color:#f00;'>Carp </span><span style='color:#0f0;'>;..BE</span><span style='color:#ff0;'>GIN .{</span> <span style='color:#f00;'>data</span><span style='color:#fff;'>, </span><span style='color:#fff;'>"extra data"</span><span style='color:#fff;'>, </span><span style='color:#0f0;'>header</span><span style='color:#fff;'>, </span><span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000a0</span> <span style='color:#ff0;'>0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72 </span> <span style='color:#ff0;'>..use Sub::Expor</span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000b0</span> <span style='color:#ff0;'>74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20 0a 09 </span> <span style='color:#ff0;'>ter -setup => ..</span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span> 
<span style='color:#fff;'>000000c0</span><span style='color:#fff;'></span> <span style='color:#ff0;'>7b 0a </span><span style='color:#f0f;'>09 65 78 70                               </span> <span style='color:#ff0;'>{.</span><span style='color:#f0f;'>.exp          </span> <span style='color:#ff0;'>data</span><span style='color:#fff;'>, </span><span style='color:#f0f;'>footer</span><span style='color:#fff;'>, </span> 

</pre>

=end html

=head2 Range definition

  my $simple_range = ['magic cookie', 12, 'red'] ;
  
Ranges are Array references containing two to four  elements:

=over 2

=item * name - a string

=item * size - an integer or a format - a string

=item * color - a string or undef

=item * user information - a very short string descibing  the range or undef

=back

Any of the elements can be replaced by a subroutine reference. See L<Dynamic range definition> below.

You can also pass the ranges as a string. The L<hdr> command line range dumper that was installed by this module uses the string format.

Example:

 $>hdr --col -display_ruler -o ver -r 'header,12:name,10:magic,2:offset,4:BITMAP,4,bright_yellow:ff,x2b2:fx,b32:f0,b16:field,x8b8:field2, b17:footer,20' my_binary

=head3 Size field format

The size field is used to defined if the range is a normal range, a comment, a bitfield or a skip range. The formats are a s follows:

                  format                          range example
		  
  normal range => integer                         header, 4, bright_blue
  comment      => #                               data section start, # 
  extra header => @                               header, @, red 
  bitfield     => [XInteger][xInteger]bInteger    bitfield, X2x4b4         # X is byte offset, x is bit offset
  skip range   => xInteger                        boring, X256,, comment

Note that the integer part can be a hexadecimal value starting with I<0x>

=head3 Coloring

Ranges and ranges names are displayed according to the color field in the range definition. 

The color definition is one of:

=over 2

=item * A user defined color name found in B<COLOR_NAMES> (see L<new>)

=item * An ansi color definition - 'blue on_yellow'

=item * undef - will be repaced by a white color or picked from a cyclic color list (see B<COLOR> in L<new>).

=back

=head3 Linear ranges

For simple data formats, your can put all the your range descriptions in a array:

  my $image_ranges =
	[
	  ['magic cookie', 12, 'red'],
	  ['size', 10, 'yellow'],
	  ['data', 10, 'blue on_yellow'],
	  ['timestamp', 5, 'green'],
	] ;

=head3 Structured Ranges

  my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_yellow'],
	  ['data', 100, 'blue'],
	] ;
			
  my $structured_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 88, 'yellow'],
	    $data_range, 
	  ],
		
	  [
	    ['extra data', 12, undef],
	    [
	      $data_range, 
	      ['footer', 4, 'yellow on_red'],
	    ]
	  ],
	]

=head4 Comment ranges

If the size of a range is the string '#', the whole range is considered a comment

  my $range_defintion_with_comments = 
	[
	  ['comment text', '#', 'optional color for meta range'],
	  ['magic cookie', 12, 'red'],
	  ['padding', 88, 'yellow'],
	    
	  [
	    ['another comment', '#'],
	    ['data header', 5, 'blue on_yellow'],
	    ['data', 100, 'blue'],
	  ],
	] ;

=head4 Extra header

If the size of a range is the string '@', and extra header is inserted in the output. This is useful when 
you have very long  output and want an extra header.

=head3 Bitfields

Bitfields can be up to 32 bits long and can overlap each other. Bitfields are applied on the previously defined range.

In the example below, bitfields I<ff, fx, f0> are extracted form the data defined by the I<BITMAP> range.

                 .------------.                      .--------------.
 .---.           | data range |                      | data hexdump |
 | b |           '------------'                      '--------------'
 | i |                  |                                    |
 | t |     BITMAP  <----'   00000000 00000000 0a 70 61 63 <--'                                 .pac           
 | f |   ^ .ff              02 .. 03          -- -- -- 00    ----------------------------00--  .bitfield: ---.
 | i |---> .fx              00 .. 31          0a 70 61 63    00001010011100000110000101100011  .bitfield: .pac
 | e |   v .f0              00 .. 15          -- -- 61 63    ----------------0110000101100011  .bitfield: --ac
 | l |                         ^                    ^                     ^                          ^
 | d |                         |                    |                     |                          |
 | s |             .----------------------.-------------------.----------------------.    .---------------------.
 '---'             | start bit .. end bit | bitfields hexdump | bitfield binary dump |    | bitfield ascci dump |
                   '----------------------'-------------------'----------------------'    '---------------------'

The the format definiton  is: an optional "x (for offset) + offset" + "b (for bits) + number of bits". Eg: I<x8b8> second byte in MYDATA.

An example output containing normal data and bifields dumps using the comand below.

  $>hdr  -r 'header,12:BITMAP,4,bright_yellow:ff,x2b2:fx,b32:f0,b16:footer,16' -o ver file_name

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">
<span style = 'color:#fff;  color:#0f0; '>header          </span><span style = 'color:#fff;  color:#0f0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>44 61 74 61 3a 3a 48 65 78 44 75 6d </span><span style = 'color:#fff;  color:#0f0; '>            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>Data::HexDum</span><span style = 'color:#fff;  color:#0f0; '>    </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff;  color:#ff0; '>BITMAP          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>0000000c</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>                                    </span><span style = 'color:#fff;  color:#ff0; '>70 3a 3a 52 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>            </span><span style = 'color:#fff;  color:#ff0; '>p::R</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '>.ff             </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>02 .. 03</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>        </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>-- -- -- 00    ----------------------------00-- </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>.bitfield: ---. </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>.fx             </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>00 .. 31</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>        </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>70 3a 3a 52    01110000001110100011101001010010 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>.bitfield: p::R </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f0f; '>.f0             </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>00 .. 15</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>        </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>-- -- 3a 52    ----------------0011101001010010 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>.bitfield: --:R </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f00; '>footer          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000010</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>61 6e 67 65 0a 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>ange.===========</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span>
</pre>

=end html

By default bitfields are not displayed  in horizontal mode.

=head3 Skip ranges

If the size format is 'X' + number, that number of bytes is skipped from the data. B<Data::HexDump::Range>
will display the skip range in the dump but not the data.

In the command below, the range 'skip' removes 32 bytes from the display. '>>' is prepended to the range name.

Command: I<hdr -r 'magic cookie, 5   :other,37  :bf,b8   :skip,X32,, I skipped :more, 20'  -rul -col -o ver>

  RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP        
                                     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345  
  magic cookie     00000000 00000000 44 61 74 61 3a                                   Data:            
  other            00000005 00000000                3a 48 65 78 44 75 6d 70 3a 3a 52       :HexDump::R 
  other            00000010 0000000b 61 6e 67 65 0a 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d  ange.=========== 
  other            00000020 0000001b 3d 3d 3d 3d 3d 3d 3d 3d 3d 0a                    =========.       
  .bf              00 .. 07          -- -- -- 0a    ------------------------00001010  .bitfield: ---.  
  >>skip           0000002a 00000049 00 00 00 20 bytes skipped                                         
  more             0000004a 00000000                               20 63 6f 6c 6f 72             color 
  more             00000050 00000006 2c 20 62 69 74 66 69 65 6c 64 73 20 61 6e        , bitfields an 

in color:

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">
<span style = 'color:#fff; '>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff; '>                                   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0f0; '>magic cookie    </span><span style = 'color:#fff;  color:#0f0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>44 61 74 61 3a </span><span style = 'color:#fff;  color:#0f0; '>                                 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0f0; '>Data:</span><span style = 'color:#fff;  color:#0f0; '>           </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff;  color:#ff0; '>other           </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000005</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>               </span><span style = 'color:#fff;  color:#ff0; '>3a 48 65 78 44 75 6d 70 3a 3a 52 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>     </span><span style = 'color:#fff;  color:#ff0; '>:HexDump::R</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '>other           </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000010</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>0000000b</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>61 6e 67 65 0a 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d 3d </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>ange.===========</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#ff0; '>other           </span><span style = 'color:#fff;  color:#ff0; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000020</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>0000001b</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>3d 3d 3d 3d 3d 3d 3d 3d 3d 0a </span><span style = 'color:#fff;  color:#ff0; '>                  </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#ff0; '>=========.</span><span style = 'color:#fff;  color:#ff0; '>      </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#0ff; '>.bf             </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>00 .. 07</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>        </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>-- -- -- 0a    ------------------------00001010 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#0ff; '>.bitfield: ---. </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f0f; '>&gt;&gt;skip          </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>0000002a</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000049</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>00 00 00 20 bytes skipped                       </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f0f; '>                </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f00; '></span><span style = 'color:#fff;  color:#f00; '>more            </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>0000004a</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '></span><span style = 'color:#fff; '>00000000</span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>                              </span><span style = 'color:#fff;  color:#f00; '>20 63 6f 6c 6f 72 </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>          </span><span style = 'color:#fff;  color:#f00; '> color</span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span><span style = 'color:#fff;  color:#f00; '>more            </span><span style = 'color:#fff;  color:#f00; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000050</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>00000006</span><span style = 'color:#fff; '></span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>2c 20 62 69 74 66 69 65 6c 64 73 20 61 6e </span><span style = 'color:#fff;  color:#f00; '>      </span><span style = 'color:#fff; '> </span><span style = 'color:#fff;  color:#f00; '>, bitfields an</span><span style = 'color:#fff;  color:#f00; '>  </span><span style = 'color:#fff; '> </span><span style = 'color:#fff; '>
</span>
</pre>

=end html

=head3 Dynamic range definition

The whole range can be replaced by a subroutine reference or elements of the range can be replaced by
a subroutine definition.

  my $dynamic_range =
	[
	  [\&name, \&size, \&color, \&comment ],
	  [\&define_range] # returns a range definition
	] ;

=head4 'name' sub ref

  sub cloth_size
  {
  my ($self, $data, $used_data, $size, $range) = @_ ;
  my %types = (O => 'S', 1 => 'M', 2 => 'L',) ;
  return 'size:' . ($types{$data} // '?') ;
  }
  
  $hdr->dump([\&cloth_size, 1, 'yellow'], $data) ;

=head4 'size' sub ref

  sub cloth_size
  {
  my ($self, $data, $used_data, $size, $range) = @_ ;
  return unpack "a", $data ;
  }
  
  $hdr->dump(['data', \&get_size, 'yellow'], $data) ;

=head4 'color' sub ref

  my $flip_flop = 1 ;
  my @colors = ('green', 'red') ;
  
  sub alternate_color {$flip_flop ^= 1 ; return $colors[$flip_flop] }
  
  $hdr->dump(['data', 100, \&alternate_color], $data) ;

=head4 'range' sub ref

  sub define_range(['whole range', 5, 'on_yellow']}
  
  $hdr->dump([\&define_range], $data) ;


=head2 define_range($data, $offset)

Returns a range description for the next range to dump

I<Arguments> - See L<gather>

=over 2

=item * $self - A Data::HexDump::Range object

=item * $data - Binary string - the data passed to the I<dump> method

=item * $offset - Integer - current offset in $data

=back

I<Returns> - 

=over 2

=item * $range - An array reference containing a name, size and color and user_information

OR

=item * undef - Ignore this range

=item * $comment - String - an optional comment that will be displayed if DUMP_RANGE_DESCRIPTION is set.

=back

=head4

B<Note> this is, very, different from L<User defined range generator> below.
 
=head3  User defined range generator

A subroutine reference can be passed as a range definition. The subroutine will be called repetitively
till the data is exhausted or the subroutine returns I<undef>.

  sub my_parser 
  	{
  	my ($data, $offset) = @_ ;
  	
  	my $first_byte = unpack ("x$offset C", $data) ;
  	
  	$offset < length($data)
  		?  $first_byte == ord(0)
  			? ['from odd', 5, 'blue on_yellow']
  			: ['from even', 3, 'green']
  		: undef ;
  	}
  
  my $hdr = Data::HexDump::Range->new() ;
  print $hdr->dump(\&my_parser, '01' x 50) ;

=head2 my_parser($data, $offset)

Returns a range description for the next range to dump

I<Arguments> - See L<gather>

=over 2

=item * $self - A Data::HexDump::Range object

=item * $data - Binary string - the data passed to the I<dump> method

=item * $offset - Integer - current offset in $data

=back

I<Returns> - 

=over 2

=item * $range - An array reference containing a name, size and color

OR

=item * undef - Done parsing

=back

=cut

=head1 EXAMPLES

See L<hdr_examples.pod> in the distribution.

=head1 SUBROUTINES/METHODS

=cut

#-------------------------------------------------------------------------------

sub new
{

=head2 new(NAMED_ARGUMENTS)

Create a Data::HexDump::Range object.

  my $hdr = Data::HexDump::Range->new() ; # use default setup
  
  my $hdr = Data::HexDump::Range->new
		(
		FORMAT => 'ANSI'|'ASCII'|'HTML',
		COLOR => 'bw' | 'cycle',
		OFFSET_FORMAT => 'hex' | 'dec',
		DATA_WIDTH => 16 | 20 | ... ,
		DISPLAY_RANGE_NAME => 1 ,
		MAXIMUM_RANGE_NAME_SIZE => 16,
		DISPLAY_COLUMN_NAMES => 0,
		DISPLAY_RULER => 0,
		DISPLAY_OFFSET  => 1 ,
		DISPLAY_CUMULATIVE_OFFSET  => 1 ,
		DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
		DISPLAY_ZERO_SIZE_RANGE => 1,
		DISPLAY_RANGE_SIZE => 1,
		DISPLAY_ASCII_DUMP => 1 ,
		DISPLAY_HEX_DUMP => 1,
		DISPLAY_HEXASCII_DUMP => 0,
		DISPLAY_DEC_DUMP => 0,
		COLOR_NAMES => {},
		ORIENTATION => 'horizontal',
		) ;

I<Arguments> - All arguments are optional. Default values are listed below.

=over 2 

=item * NAME - String - Name of the Data::HexDump::Range object, set to 'Anonymous' by default

=item * INTERACTION - Hash reference - Set of subs that are used to display information to the user

Useful if you use Data::HexDump::Range in an application without terminal.

=item * VERBOSE - Boolean - Display information about the creation of the object. Default is I<false>

=item * DUMP_ORIGINAL_RANGE_DESCRIPTION - Boolean - Diplays the un-processed range descritption.

With B<DUMP_RANGE_DESCRIPTION>, this fields can be used to peek into what range descriptions the module get and how they are
transformed  into the format that is internally used by the module. These are for debugging purpose and you should normally not need to used them.

 Original range description
 |- 0 = 'Data'
 |- 1 = '128'
 |- 2 = undef
 `- 3 = undef
 
 Original range description
 |- 0 = CODE(0x1dc5230)
 |- 1 = undef
 |- 2 = undef
 `- 3 = undef

=item * DUMP_RANGE_DESCRIPTION - Boolean - Diplays the processed range descritption in plain text before the dump

 128->26:Data
 |- COLOR = undef
 |- DATA = '_blah_blah_blah_blah_blah[\n]'
 |- IS_BITFIELD = '0'
 |- IS_COMMENT = '0'
 |- IS_SKIP = '0'
 |- NAME = '128->26:Data'
 |- OFFSET = '20'
 |- unpack format = 'x20 a26'
 `- USER_INFORMATION = undef

=item * FORMAT - String - format of the dump string generated by Data::HexDump::Range.

Default is B<ANSI> which allows for colors. Other formats are 'ASCII' and 'HTML'.

=item * COLOR - String 'cycle', 'no_cycle', 'bw'

Controls the coloring policy of ranges

=over 2

=item * cycle: if the range definition contains a color does not define a color, a color is automatically assigned

=item * no_cycle: only ranges with a color defined are colorized

=item * bw: no color is used even if the range contains a color definition

=back

=item * OFFSET_FORMAT - String - 'hex' or 'dec'

If set to 'hex', the offset will be displayed in base 16. When set to 'dec' the offset is displayed
in base 10. Default is 'hex'.

=item * DATA_WIDTH - Integer - Number of elements displayed per line. Default is 16.

=item * DISPLAY_RANGE_NAME - Boolean - If set, range names are displayed in the dump.

=item * MAXIMUM_RANGE_NAME_SIZE - Integer - maximum size of a range name (horizontal mode). Default size is 16.

=item * DISPLAY_COLUMN_NAMES - Boolean -  If set, the column names are displayed. Default I<false>

=item * DISPLAY_RULER - Boolean - if set, a ruler is displayed above the dump, Default is I<false>

=item * DISPLAY_OFFSET - Boolean - If set, the offset column is displayed. Default I<true>

=item * DISPLAY_CUMULATIVE_OFFSET - Boolean - If set, the cumulative offset column is displayed in 'vertical' rendering mode. Default is I<true>

=item * OFFSET_START - Integer - value added to the offset. 

=item * DISPLAY_ZERO_SIZE_RANGE - Boolean - if set, ranges that do not consume data are displayed. default is I<true> 

=item * DISPLAY_ZERO_SIZE_RANGE_WARNING - Boolean - if set, a warning is emitted if ranges that do not consume data. Default is I<true> 

=item * DISPLAY_COMMENT_RANGE - Boolean - if set, comment ranges are displayed. default is I<true> 

=item * DISPLAY_RANGE_SIZE - Bolean - if set the range size is prepended to the name. Default I<false>

=item * DISPLAY_ASCII_DUMP - Boolean - If set, the ASCII representation of the binary data is displayed. Default is I<true>

=item * DISPLAY_HEX_DUMP - Boolean - If set, the hexadecimal dump column is displayed. Default is I<true>

=item * DISPLAY_HEXASCII_DUMP - Boolean - If set, the comined hexadecimal and ASCII dump column is displayed. Default is I<false>

=item * DISPLAY_DEC_DUMP - Boolean - If set, the decimall dump column is displayed. Default is I<false>

=item * DISPLAY_BITFIELD_SOURCE - Boolean - if set an extra column indicating the source of bitfields is displayed

=item * MAXIMUM_BITFIELD_SOURCE_SIZE - Integer - maximum size of the bifield source column 

=item * DISPLAY_USER_INFORMATION - Boolean - if set an extra column displaying user supplied information is shown

=item * MAXIMUM_USER_INFORMATION_SIZE - Integer - maximum size of theuser information column 

=item * DISPLAY_BITFIELDS - Boolean - if set the bitfields are displayed

=item * BIT_ZERO_ON_LEFT - Boolean - if set the bit of index 0 is on left growing to the right. Default I<false>

=item * COLOR_NAMES - A hash reference

  {
  ANSI =>
	{
	header => 'yellow on_blue',
	data => 'yellow on_black',
	},
	
  HTML =>
	{
	header => 'FFFF00 0000FF',
	data => 'FFFF00 000000',
	},
  }

=item * ORIENTATION - String - 'vertical' or 'horizontal' (the default).

=back

I<Returns> - Nothing

I<Exceptions> - Dies if an unsupported option is passed.

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Error: Invalid constructor call' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub gather
{

=head2 gather($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description. The data dump is kept in the object so you can
merge multiple gathered dumps and get a single rendering.

  $hdr->gather($range_description, $data, $offset, $size)
  $hdr->gather($range_description, $more_data)
  
  print $hdr->dump_gathered() ;

I<Arguments>

=over 2 

=item * $range_description - See L<Range definition>
  
=item * $data - A string - binary data to dump

=item * $offset - dump data from offset

=over 2

=item * undef - start from first byte

=back

=item * $size - amount of data to dump

=over 2

=item * undef - use range description

=item * CONSUME_ALL_DATA - apply range descritption till all data is consumed

=back

=back

I<Returns> - An integer - the number of processed bytes

I<Exceptions> - See L<_gather>

=cut

my ($self, $range, $data, $offset, $size) = @_ ;

my ($gathered_data, $used_data) = $self->_gather($self->{GATHERED}, $range, $data, $offset, $size) ;

return $used_data ;
}

#-------------------------------------------------------------------------------

sub dump_gathered
{

=head2 dump_gathered()

Returns the dump string for the gathered data.

  $hdr->gather($range_description, $data, $size)
  $hdr->gather($range_description, $data, $size)
  
  print $hdr->dump_gathered() ;

I<Arguments> - None

I<Returns> - A string - the binary data formated according to the rnage descriptions

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $split_data = $self->split($self->{GATHERED}) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
}

#-------------------------------------------------------------------------------

sub dump ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{

=head2 dump($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description

I<Arguments> - See L<gather>

I<Returns> - A string -  the formated dump

I<Exceptions> - dies if the range description is invalid

=cut

my ($self, $range_description, $data, $offset, $size) = @_ ;

return unless defined wantarray ;

local $self->{GATHERED} = [] ;

my ($gathered_data, $used_data) = $self->_gather($self->{GATHERED}, $range_description, $data, $offset, $size) ;

my $split_data = $self->split($gathered_data) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
}

#-------------------------------------------------------------------------------

sub get_dump_and_consumed_data_size
{

=head2 get_dump_and_consumed_data_size($range_description, $data, $offset, $size)

Dump the data, from $offset up to $size, according to the $range_description

I<Arguments> - See L<gather>

I<Returns> - 

=over 2

=item *  A string -  the formated dump

=item * An integer - the number of bytes consumed by the range specification

=back 

I<Exceptions> - dies if the range description is invalid

=cut

my ($self,$data, $offset, $size) = @_ ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, $data, $offset, $size) ;

my $dump =$self->format($self->split($gathered_data)) ;

return  $dump, $used_data ;
}

#-------------------------------------------------------------------------------

sub reset ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{

=head2 reset()

Clear the gathered dump 

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

$self->{GATHERED} = [] ;

return ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright Nadim Khemir 2010-2012.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::HexDump::Range

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-HexDump-Range>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-data-hexdump-range@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Data-HexDump-Range>

=back

=head1 SEE ALSO

L<Data::Hexdumper>, L<Data::ParseBinary>, L<Convert::Binary::C>, L<Parse::Binary>

=cut
