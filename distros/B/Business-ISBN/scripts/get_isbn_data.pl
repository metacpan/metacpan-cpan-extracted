#!/usr/bin/perl

use LWP::Simple;

my $Base  = 'http://www.isbn.spk-berlin.de/html/prefix/';
my @Files = map "pref$_.htm",
	qw( a b c d_f g_h i_j k_l m n_o p q_r s t u v_z );
	
foreach my $file ( @Files )
	{
	unless( -f $file )
		{
		$_ = get( "$Base$file" );
				
		open FILE, "> $file" or warn "Could not open [$file]\n$!";
		print FILE;
		close FILE;
		}
	else
		{
		local $/;
		open FILE, $file or warn "Could not open local file [$file]\n$!";
		$_ =  <FILE>;
		close FILE;
		}
		
	$_ = munge($_);
	
	open FILE, "> m-$file" or warn "Could not open [m-$file]\n$!";
	print FILE;
	close FILE;
	}

sub munge
	{
	local $_ = shift;
	
	s|.*</form>\s+</td>\s+</tr>.*?<table.*?>\s+||s;  # chop off the head
	s|</table>.*||s;                                 #chop off the tail
	s| +| |sg; #collapse spaces

	foreach my $pattern ( qw( <font.*?> </font> <div.*?> </div> 
		\s+width="\\d+" &nbsp; <b>\s*</b> 
		 \s+colspan="\d+" <br> \s+height="\d+" <hr.*?>  
		 \s+v?align=".*?" <!--.*?--> <p> </p>) 
		 )
		{
		s|$pattern||isg;
		}
	
	s|(\d+)\s+-\s+(\d+)|$1 - $2|g;
	s|<td>\s+|<td>|ig;
	s|\s+</td>|</td>|ig;
	s|\t| |g;

	s|
		<tr>\s+<td>
			<b>\s*
				([\w\s,]+) # $1
			\s*</b>
			\s*
			( .*? )? # $2, possible extra remark
		</td>\s+
   	 
		(?:<td></td>\s+)?              #possible blank cell

		<td>
			<b>\s*
			(\d+) # $3, first country code
			\s*
				(?:</b>)?  # some of these are missing
		       (?: #there might be more country codes
					\s*
					(?:<b>\s*)? # some of these are missing too
					\+
					(?:\s*</b>)? # some of these are missing
					\s*
					(?:<b>)?
					\s*
					(\d+) # $4, $5, ... other country codes
					\s*
					(?:</b>)?
				)* # these might be here or not
	</td>\s+
	|\f$1 $2*$3*$4*$5*$6|ixg;
	
	foreach my $pattern ( qw( <td></td> <tr> </tr> ) )
		{
		s|$pattern||isg;
		}
	
	s|\s+[\r\n]|\n|g;
	s|[\r\n]+|\n|g;
	
	s|(\f.*?)<td>([A-Z]+)</td>\s+|$1*$2\n|sg;
	
	foreach my $pattern ( qw( <td> </td> ) )
		{
		s|$pattern||sg;
		}
		
	return $_;
	}
	
