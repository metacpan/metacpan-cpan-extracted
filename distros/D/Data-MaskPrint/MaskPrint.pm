#!/usr/local/bin/perl -wc

package Data::MaskPrint;
use vars qw($myself @ISA $VERSION);
$VERSION = "1.0";
use Exporter();
@ISA = qw(Exporter);


use strict;
use Carp;

sub new ()
{
	my $class = shift;
	my $self=[];
	bless $self, $class;
}

sub num_mask_print($$$)
{
	my $this = shift;
	my $data = shift;
	my $mask = shift;


	#defines follow
	my $PAREN  = 0;
	my $PLUS   = 0;
	my $MINUS  = 0;
	my $DOLLAR = 0;
	my $DECIMAL= 0;
	my $NEGATIVE = 0;
	my $SUPRESS_LEAD_SPACE = 0;
	

	my @fmt_pic;

	$DOLLAR = 1 if ($mask =~ /\$/);
	$MINUS = 1 if (($mask =~ /-/) || ($mask =~ /\+/));
	$PLUS = 1 if ($mask =~ /\+/);

	if ($mask =~ /</)
	{
		$mask =~ s/</\#/g;
		$SUPRESS_LEAD_SPACE = 1;
	}

	if ($mask =~ /\..*\./)
	{
		croak "Only one decimal point is permitted in the mask (Picture)";
	}
	elsif ($mask =~ /\./)
	{
		$DECIMAL = 1;
	}

	if ($mask =~ /\).*\)/)
	{
		croak "Only one ) is permitted in the mask (Picture)";
	}
	elsif ($mask =~ /\)/)
	{
		$PAREN = 1;
	}

	if ((($mask =~ /\(/) && !$PAREN) || ($PAREN && !($mask =~ /\(/)))
	{
		croak "Parenthesis does not match in the mask (Picture)";
	}

	if (($PAREN) && ($MINUS || $PLUS))
	{
		croak "Mask (Picture) formatted incorrectly cannot have both parenthesis and -/+ sign";
	}


	if ($data >= 0)
	{
		if ($PAREN)
		{
			$mask =~ s/\)//g;
			$mask = '#' . $mask;
			$mask =~ s/\(/\#/g;
			$SUPRESS_LEAD_SPACE = 1;
		}
		$mask =~ s/-/\#/g;
	}
	else
	{
		$NEGATIVE = 1;
		if ($PLUS)
		{
			$mask =~ s/\+/-/g;
		}
		$data =~ s/-//;
	}

	if (!$DECIMAL)
	{
		$data =~ s/\..*$//;
	}

	#preparing mask array
	for(my $i = 0; $i < length($mask); $i++)
	{
		$fmt_pic[$i] = substr($mask, $i, 1);
	}

	#checking if the data will fit into the space provided by the mask
	my @arr = split(/\./, $data);
	my @arr2 = split(/\./, $mask);
	$arr2[0] =~ s/,//g;
	my $count = length($arr2[0]);
	$count-- if ($PAREN || $MINUS || $PLUS);
	$count-- if ($DOLLAR);
	return '*' x length($mask) if (length($arr[0]) > $count);


	#processing right side of the mask
	my $DECIMAL_POS_MASK = length($mask);
	my $DECIMAL_POS_DATA = length($data);
	if ($DECIMAL)
	{
		$DECIMAL_POS_MASK = index($mask, '.');
		if ($data =~ /\./)
		{
			$DECIMAL_POS_DATA = index($data, '.');
		}
		else
		{
			$DECIMAL_POS_DATA = length($data);
		}
		for(my $i = $DECIMAL_POS_MASK, my $j = $DECIMAL_POS_DATA;
		    $i < scalar(@fmt_pic);
			$i++)
		{
			my $num = undef;
			if ($j < length($data))
			{
				$num = substr($data, $j, 1);
				$j++;
			}
			
			while(($fmt_pic[$i] eq ')') || ($fmt_pic[$i] eq ','))
			{
				$i++;
			}
			last if !defined($fmt_pic[$i]);

			foreach ($fmt_pic[$i])
			{
				/\*/ && do
					{
						if (defined($num))
						{
							$fmt_pic[$i] = $num;
						}
						else
						{
							$fmt_pic[$i] = '*';
						}
					};
				/\$|#|-|\&/ && do
					{
						if (defined($num))
						{
							$fmt_pic[$i] = $num;
						}
						else
						{
							$fmt_pic[$i] = 0;
						}
					};
			}
		}
	}

	#Processing left side of mask here(side to re left of .)
	#Right side should already be processed if there is no right side
	#just process the rest of mask
	my $i;
	for($i = $DECIMAL_POS_MASK - 1, my $j = $DECIMAL_POS_DATA - 1;
		$j >= 0 ;
		$j--, $i--)
	{
			my $num = substr($data, $j, 1);
			
			while(($fmt_pic[$i] eq ')') || ($fmt_pic[$i] eq ','))
			{
				$i--;
			}
			last if ($i < 0);

			if (($fmt_pic[$i] eq '$') ||
			    ($fmt_pic[$i] eq '('))
			{
				for(my $k = $i - 1; $k >= 0; $k--)
				{
					next if ($fmt_pic[$k] eq ',');
					$fmt_pic[$k] = $fmt_pic[$i];
					last;
				}
			}
			$fmt_pic[$i] = $num;
	}

	#Processing leftover string afetr all numbers have been processed
	my $HAD_DOLLAR = 0;
	my $HAD_SIGN   = 0;
	my $HAD_PAREN  = 0;
	my $HAD_STAR   = 0;

	for( ; $i >= 0; $i--)
	{
		foreach ($fmt_pic[$i])
		{
			if (($NEGATIVE) && !($HAD_SIGN) && !($PAREN) && !($MINUS))
			{
				$fmt_pic[$i] = '-';
				$HAD_SIGN = 1;
				next;
			}
			/\*/ && do
				{
					#Let it be
				};
			/\,/ && do
				{
					if ($i > 0)
					{
						$fmt_pic[$i] = $fmt_pic[$i - 1];
						$i++;
						next;
					}
					elsif ($fmt_pic[$i + 1] =~ /[0-9]/)
					{
						$fmt_pic[$i] = ' ';
					}
					else
					{
						$fmt_pic[$i] = $fmt_pic[$i + 1];
						$i++;
						next;
					}
				};
			/\&/ && do
				{
					$fmt_pic[$i] = 0;
				};
			/\$/ && do
				{
					if ($HAD_DOLLAR)
					{
						if ($i > 0)
						{
							my $symbol = '#';
							for(my $k = $i - 1; $k >= 0; $k--)
							{
								if (($fmt_pic[$k] eq '$') ||
								    ($fmt_pic[$k] eq ',') ||
									($fmt_pic[$k] eq '('))
								{
									next;
								}
								else
								{
									$symbol = $fmt_pic[$k];
									last;
								}
							}
							$fmt_pic[$i] = $symbol;
							#This is to reprocess this symbol again
							$i++;
							next;
						}
						else
						{
							$fmt_pic[$i] = ' ';
						}
					}
					else
					{
						$HAD_DOLLAR = 1;
						$fmt_pic[$i] = '$';
					}
				};
			/\#/ && do
				{
					$fmt_pic[$i] = ' ';
				};
			/\(/ && do
				{
					if ($HAD_PAREN)
					{
						$SUPRESS_LEAD_SPACE = 1;
						if ($i > 0)
						{
							my $symbol = '#';
							for(my $k = $i - 1; $k >= 0; $k--)
							{
								if (($fmt_pic[$k] eq '(') ||
								    ($fmt_pic[$k] eq ',') ||
									($fmt_pic[$k] eq '$'))
								{
									next;
								}
								else
								{
									$symbol = $fmt_pic[$k];
									last;
								}
							}
							$fmt_pic[$i] = $symbol;
							#This is to reprocess this symbol again
							$i++;
							next;
						}
						else
						{
							$fmt_pic[$i] = ' ';
						}
					}
					else
					{
						$HAD_PAREN = 1;
						$fmt_pic[$i] = '(';
					}
				};
			/-|\+/ && do
				{
					if ($HAD_SIGN)
					{
						if ($i > 0)
						{
							my $symbol = '#';
							for(my $k = $i - 1; $k >= 0; $k--)
							{
								if (($fmt_pic[$k] eq $_) ||
								    ($fmt_pic[$k] eq ',') ||
									($fmt_pic[$k] eq '$'))
								{
									next;
								}
								else
								{
									$symbol = $fmt_pic[$k];
									last;
								}
							}
							$fmt_pic[$i] = $symbol;
							#This is to reprocess this symbol again
							$i++;
							next;
						}
						else
						{
							$fmt_pic[$i] = ' ';
						}
					}
					else
					{
						$HAD_SIGN = 1;
						$fmt_pic[$i] = $_;
					}
				};
		}
	}

	my $pic = join("", @fmt_pic);
	$pic =~ s/^\s+// if ($SUPRESS_LEAD_SPACE);
	return $pic;
}

1;
__END__;

=head1 NAME

MaskPrint - Data format module.

=head1 SYNOPSIS

 use strict;
 use Data::MaskPrint;

 my $ftm = new Data::MaskPrint();
 my $formatted_data = $fmt->num_mask_print(1234, '$$,$$$.&&')

=head1 DESCRIPTION

=item Data::MaskPrint::new()

Creates a new formatter

=item Data::MaskPrint::num_mask_print($data, $mask)

=over 4

=item $data - numeric data value

=item $mask - mask value

=back

=head2 DESCRIPTION OF MASKS

=over 4

=item Formatting Number Expressions

The format string (mask) consists of combination of the following characters: * & # < , . - + ( ) $. The characters - + ( ) $ will float. When character floats MaskPrint display multiple leading occurances of the character as the single character as far to the right as possible, without interfering with the number that is being displayed.

=over 2

=item '*'

This character fills with asterisks any positions that would otherwise be blank

=item '&'

This character fills with 0 any positions that would otherwise be blank

=item '#'

This character does not change any blank positions in the display field. Use this character to specify max. width of the field.

=item '<'

This character causes numbers to be left-justified

=item ','

This character is a literal it displays ,. It will not dispay , if there is no numbers to the left

=item '.'

This character is a literal it displays . (Only one is allowed per string)

=item '-'

This character is a literal it displays - sign if expression is < 0. When you group several in a row, it will float to the rightmost position without interfering with the numbers being printed.

=item '+'

This character is a literal it displays '-' sign if expression is < 0 and '+' if expression is > 0.  When you group several in a row, it will float to the rightmost position without interfering with the numbers being printed.

=item '('

This character is a literal it displays accounting parenthesis is expression is < 0 (Instead of the minus sign).  When you group several in a row, it will float to the rightmost position without interfering with the numbers being printed.

=item ')'

This character is a literal it displays accounting parenthesis is expression is
< 0 (Instead of the minus sign). Only one is allowed per mask.

=item '$'

This character is a literal it displays $. When you group several in a row, it will float to the rightmost position without interfering with the numbers being printed.

=item Examples of masks 

Format String       Data Value          Formatted Result    

'#####'             0                   bbbb0               
'&&&&&'             0                   00000               
'$$$$$'             0                   bbb$0               
'*****'             0                   ****0               
'##,###'            12345               12,345              
'##,###'            1234                b1,234              
'##,###'            123                 bbb123              
'##,###'            12                  bbbb12              
'##,###'            1                   bbbbb1              
'##,###'            -1                  bbbb-1              
'##,###'            0                   bbbbb0              
'&&,&&&'            12345               12,345              
'&&,&&&'            1234                01,234              
'&&,&&&'            123                 000123              
'&&,&&&'            12                  000012              
'&&,&&&'            1                   000001              
'&&,&&&'            0                   000000              
'$$,$$$'            12345               ******              
                                        (overflow)

'$$,$$$'            1234                $1,234              
'$$,$$$'            123                 bb$123              
'$$,$$$'            12                  bbb$12              
'$$,$$$'            1                   bbbb$1              
'$$,$$$'            0                   bbbb$0              
'**,***'            12345               12,345              
'**,***'            1234                *1,234              
'**,***'            123                 ***123              
'**,***'            12                  ****12              
'**,***'            1                   *****1              
'**,***'            0                   *****0              
'##,###.##'         12345.67            12,345.67           
'##,###.##'         1234.56             b1,234.56           
'##,###.##'         123.45              bbb123.45           
'##,###.##'         12.34               bbbb12.34           
'##,###.##'         1.23                bbbbb1.23           
'##,###.##'         0.12                bbbbb0.12           
'##,###.##'         0.01                bbbbb0.01           
'##,###.##'         -0.01               bbbb-0.01           
'##,###.##'         -1                  bbbb-1.00           
'&&,&&&.&&'         12345.67            12,345.67           
'&&,&&&.&&'         1234.56             01,234.56           
'&&,&&&.&&'         123.45              000123.45           
'&&,&&&.&&'         0.01                000000.01           
'$$,$$$.$$'         12345.67            *********           
                                        (overflow)

'$$,$$$.$$'         1234.56             $1,234.56           
'$$,$$$.##'         0                   bbbb$0.00           
'$$,$$$.##'         1234                $1,234.00           
'$$,$$$.&&'         0                   bbbb$0.00           
'$$,$$$.&&'         1234                $1,234.00           
'-##,###.##'        -12345.67           -12,345.67          
'-##,###.##'        -123.45             -bbb123.45          
'-##,###.##'        -12.34              -bbbb12.34          
'--#,###.##'        -12.34              b-bbb12.34          
'---,###.##'        -12.34              bbb-b12.34          
'---,-##.##'        -12.34              bbbb-12.34          
'---,--#.##'        -1                  bbbbb-1.00          
'-##,###.##'        12345.67            b12,345.67          
'-##,###.##'        1234.56             bb1,234.56          
'-##,###.##'        123.45              bbbb123.45          
'-##,###.##'        12.34               bbbbb12.34          
'--#,###.##'        12.34               bbbbb12.34          
'---,###.##'        12.34               bbbbb12.34          
'---,-##.##'        12.34               bbbbb12.34          
'---,---.##'        1                   bbbbbb1.00          
'---,---.--'        -0.01               bbbbb-0.01          
'---,---.&&'        -0.01               bbbbb-0.01          
'-$$,$$$.&&'        -12345.67           **********          
                                        (overflow)

'-$$,$$$.&&'        -1234.56            -$1,234.56          
'-$$,$$$.&&'        -123.45             bb-$123.45          
'--$,$$$.&&'        -12345.67           **********          

                                        (overflow)
'--$,$$$.&&'        -1234.56            -$1,234.56          
'--$,$$$.&&'        -123.45             bb-$123.45          
'--$,$$$.&&'        -12.34              bbb-$12.34          
'--$,$$$.&&'        -1.23               bbbb-$1.23          
'----,--$.&&'       -12345.67           -$12,345.67         
'----,--$.&&'       -1234.56            b-$1,234.56         
'----,--$.&&'       -123.45             bbb-$123.45         
'----,--$.&&'       -12.34              bbbb-$12.34         
'----,--$.&&'       -1.23               bbbbb-$1.23         
'----,--$.&&'       -0.12               bbbbb-$0.12         
'$***,***.&&'       12345.67            $*12,345.67         
'$***,***.&&'       1234.56             $**1,234.56         
'$***,***.&&'       123.45              $****123.45         
'$***,***.&&'       12.34               $*****12.34         
'$***,***.&&'       1.23                $******1.23         
'$***,***.&&'       0.12                $******0.12         
'($$$,$$$.&&)'      -12345.67           ($12,345.67)        
'($$$,$$$.&&)'      -1234.56            (b$1,234.56)        
'($$$,$$$.&&)'      -123.45             (bbb$123.45)        
'(($$,$$$.&&)'      -12345.67           ($12,345.67)        
'(($$,$$$.&&)'      -1234.56            ($1,234.56)         
'(($$,$$$.&&)'      -123.45             (bb$123.45)         
'(($$,$$$.&&)'      -12.34              (bbb$12.34)         
'(($$,$$$.&&)'      -1.23               (bbbb$1.23)         
'((((,(($.&&)'      -12345.67           ($12,345.67)        
'((((,(($.&&)'      -1234.56            ($1,234.56)         
'((((,(($.&&)'      -123.45             (b$123.45)          
'((((,(($.&&)'      -12.34              ($12.34)            
'((((,(($.&&)'      -1.23               ($1.23)             
'((((,(($.&&)'      -0.12               ($0.12)             
'($$$,$$$.&&)'      12345.67            $12,345.67          
'($$$,$$$.&&)'      1234.56             $1,234.56           
'($$$,$$$.&&)'      123.45              $123.45             
'(($$,$$$.&&)'      12345.67            $12,345.67          
'(($$,$$$.&&)'      1234.56             $1,234.56           
'(($$,$$$.&&)'      123.45              $123.45             
'(($$,$$$.&&)'      12.34               $12.34              
'(($$,$$$.&&)'      1.23                $1.23               
'((((,(($.&&)'      12345.67            $12,345.67          
'((((,(($.&&)'      1234.56             $1,234.56           
'((((,(($.&&)'      123.45              $123.45             
'((((,(($.&&)'      12.34               $12.34              
'((((,(($.&&)'      1.23                $1.23               
'((((,(($.&&)'      0.12                $0.12               
'<<<<<'             0                   0                   
'<<<,<<<'           12345               12,345              
'<<<,<<<'           1234                1,234               
'<<<,<<<'           123                 123                 
'<<<,<<<'           12                  12                  

=head1 AUTHOR

Send bug reports, hints, tips, suggestions to Ilya Verlinsky <F<ilya@wsi.net>>.

=cut
