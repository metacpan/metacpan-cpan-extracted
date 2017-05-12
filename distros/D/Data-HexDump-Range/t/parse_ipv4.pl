use strict ;
use warnings ;

my $IPV4_header =
	[
	['IPV4_header', '#', 'bright_white on_red'],
		[
			['Version, Header length,  Differentiated Services, Total Length', '#', 'blue on_cyan'],
			['First 32 bits', 4], 
			['Version', 'b4'],
			['Header length', 'x4b4'],
			['Differentiated Services', 'x8b8'],
				# Differentiated Services (DS) 
				# # bit 3: 0 = Normal Delay, 1 = Low Delay
				# # bit 4: 0 = Normal Throughput, 1 = High Throughput
				# # bit 5: 0 = Normal Reliability, 1 = High Reliability
				# # bit 6: 0 = Normal Cost, 1 = Minimize Monetary Cost
				# (defined by RFC 1349)
				# # bit 7: never defined
			['Total length', 'x16b16'],
		],

		[
			['Identification, Flags, Fragment Offset', '#', 'blue on_cyan'],
			['Second 32 bits', 4], 
			['Identification', 'b16'],
			
			['reserved', 'x16b1'],
			["Don't Fragment", 'x17b1'],
			['More Fragments', 'x18b1'],
				# bit 0: Reserved; must be zero. As an April Fools joke, proposed for use in RFC 3514 as the "Evil bit".
				# bit 1: Don't Fragment (DF)
				# bit 2: More Fragments (MF)

			['Fragment Offset', 'x19b13'],
		],

		[
			['Time to Live, Protocol, Header Checksum', '#', 'blue on_cyan'],
			['Third 32 bits', 4], 
			['Time to Live', 'b8'],
			['Protocol', 'x8b8'],
			['Header Checksum', 'x16b16'],
		],
		
		['Addresses and options', '#', 'blue on_cyan'],
		['Source Address', 4],
		['Destination Address', 4], 
		[
		sub
			{
			my ($self, $data, $offset, $size, $range) = @_ ;
			
			my ($header_length_chunk) = grep {$_->{NAME} eq 'Header length'} @{$self->{GATHERED}} ;
			my $header_length = ord(substr($header_length_chunk->{DATA}, 0, 1)) & 0x0f  ;
			
			if($header_length > 5)
				{
				return ['Options', 4, undef ,'header length > 5, extracting options'] ;
				}
			else
				{
				# Note that we could choose to return a comment range instead
				#~ return ['header length < 5, no options', '#', undef, undef] ;
				
				return undef, 'Skipping option field header length < 5';
				}
			}
		],
		['Data', '#', 'blue on_cyan'],
		['Data', 128] # display some of the data
	] ;
	

	