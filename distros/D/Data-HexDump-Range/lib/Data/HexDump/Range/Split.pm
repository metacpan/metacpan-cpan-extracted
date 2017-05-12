
package Data::HexDump::Range ; ## no critic (Modules::RequireFilenameMatchesPackage)

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
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;
use Text::Pluralize ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Split - Handles formating for Data::HexDump::Range

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut

#-------------------------------------------------------------------------------

sub split
{

=head2 [P] split($collected_data)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> -  An Array  containing column elements

I<Exceptions>

=cut

my ($self, $collected_data) = @_ ;

if($self->{ORIENTATION} =~ /^hor/)
	{
	return $self->_split_horizontal($collected_data) ;
	}
else
	{
	return $self->_split_vertical($collected_data) ;
	}
}

#-------------------------------------------------------------------------------

sub _split_horizontal
{

=head2 [P] _split_horizontal($collected_data)

Split the collected data into horizontal lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> -  An Array  containing column elements

I<Exceptions>

=cut


my ($self, $collected_data) = @_ ;

my @lines ;
my $line = {} ;
my $wrapped_line = 0 ;

my $current_offset = 0 ;
my $total_dumped_data =  $self->{OFFSET_START} ;
my $room_left = $self->{DATA_WIDTH} ;

my $lines_since_header = 0 ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $user_information_size = $self->{MAXIMUM_USER_INFORMATION_SIZE} ;
my $range_source = ['?', 'white'] ;

my @found_bitfields ;

my $last_range = (grep {!  $_->{IS_BITFIELD}}@{$collected_data})[-1] ;

my @collected_data_to_dump = @{$collected_data} ;

	if($self->{OFFSET_START}) 
		{
		my $range = {} ;
		$range->{NAME} =  '>>' ;
		$range->{DATA} = '?' x $self->{DATA_WIDTH} ;
		
		my $left_pad_size = $self->{OFFSET_START} % $self->{DATA_WIDTH} ;
		my $aligned_start_offset = $self->{OFFSET_START} - $left_pad_size ;

=pod 

=item * $self - 

=item * $visible - Boolean - wether the range elements will be visible or not. used for alignment

=item * $range - the range structure created by Gather

=item * $line - container for the range strings to be displayed

=item * $last_range - Boolean - wether the range is the last one to be displayed

=item * $total_dumped_data - Integer -  the amount of total data dumped so far

=item * $dumped_data - Integer - the amount of byte dumped from the range so far

=item *  $size_to_dump - Integer - the amount of data to extract from the range

=item * $room_left - Integer - the amount of space left in the line for the dimped data

=cut

		$self->_dump_range_horizontal(0, $range, $line, 0, $aligned_start_offset, 0, $left_pad_size, $self->{DATA_WIDTH}) ;
	
		$current_offset += $self->{OFFSET_START} ;
		$room_left = $self->{DATA_WIDTH} - $left_pad_size ;
		}
		
while (my $range = shift @collected_data_to_dump)
	{
	my $data_length = defined $range->{DATA} ? length($range->{DATA}) : 0 ;
	my ($start_quote, $end_quote) = $range->{IS_COMMENT} ? ('"', '"') : ('<', '>') ;
		
	$range->{SOURCE} = $range_source  if $range->{IS_BITFIELD} ;
		

	if($range->{IS_BITFIELD}) 
		{
		$range->{COLOR} = $range_source->[1] ;
		push @found_bitfields, $self->get_bitfield_lines($range) ;
		next ;
		}
	
	$range->{COLOR} = $self->get_default_color($range->{COLOR}) ;
	
	if($room_left == $self->{DATA_WIDTH})
		{
		push @lines,  @found_bitfields ;
		@found_bitfields = () ;
		}
	
	# remember what range we process in case next range is bitfield
	unless($range->{IS_COMMENT})
		{
		$range_source = [$range->{NAME}, $range->{COLOR}]  ;
		}
	
	my $dumped_data = 0 ;
	
	if(0 == $data_length && $self->{DISPLAY_RANGE_NAME})
		{
		my $display_range_name = 0 ;
		
		if($range->{IS_COMMENT})
			{
			$display_range_name++ if $self->{DISPLAY_COMMENT_RANGE} ;
			}
		else
			{
			$display_range_name++ if $self->{DISPLAY_ZERO_SIZE_RANGE} ;
			}
				
		if($display_range_name)
			{
			my $name_size_quoted = $max_range_name_size - 2 ;
			$name_size_quoted =  2 if $name_size_quoted < 2 ;
			
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME' => $start_quote . sprintf("%.${name_size_quoted}s", $range->{NAME}) . $end_quote,
				'RANGE_NAME_COLOR' => $range->{COLOR},
				},
				{
				'RANGE_NAME_COLOR' => undef,
				'RANGE_NAME' => ', ',
				} ;
			}
		}
		
	if($range->{IS_HEADER}) 
		{
		$range->{NAME} =  '@' . $range->{NAME} ;
		$range->{DATA} = '0' x $self->{DATA_WIDTH} ;
		
		# justify on the right
		$self->_dump_range_horizontal(0, $range, $line, $last_range, $current_offset, $dumped_data, $room_left, $room_left) ;
		$line->{NEW_LINE}++ ;
		push @lines, $line ;

		# display header
		$line = {} ;
		push @lines, $self->get_information(\@lines, $range->{COLOR}) ;
		
		# justify on the left
		$line = {} ;
			
		my $left_pad_size = $self->{DATA_WIDTH} - $room_left ;
		$self->_dump_range_horizontal(0, $range, $line, $last_range, $current_offset -$left_pad_size , $dumped_data, $left_pad_size, $self->{DATA_WIDTH}) ;
		
		next ;
		}
		
	if($range->{IS_SKIP}) 
		{
		$range->{NAME} =  '>>' . $range->{NAME} ;
		$range->{DATA} = ' '  x $self->{DATA_WIDTH} ;
		
		my $size_to_dump = min($room_left, $data_length - $dumped_data) || 0 ;
		$room_left -= $size_to_dump ;

		# justify on the right
		$self->_dump_range_horizontal(0, $range, $line, $last_range, $current_offset, $dumped_data, $size_to_dump, $room_left) ;
		
		my $data_left = $data_length - $size_to_dump ;
		$current_offset += $size_to_dump ;
		
		if ($data_left)
			{
			# justify on the left
			$line->{NEW_LINE}++ ;
			push @lines, $line ;
			
			my $lines_to_skip = int($data_left / $self->{DATA_WIDTH}) ;
			my $data_bytes_on_line = $data_left - ($lines_to_skip * $self->{DATA_WIDTH}) ;
			my $left_data_offset = $current_offset + ($lines_to_skip * $self->{DATA_WIDTH}) ;
			
			$line = {} ;
			$self->_dump_range_horizontal(0, $range, $line, $last_range, $left_data_offset, $dumped_data, $data_bytes_on_line, $self->{DATA_WIDTH}) ;
			
			$room_left = $self->{DATA_WIDTH} - $data_bytes_on_line ;
			$current_offset += $data_left ;
			}
			
		next ;
		}
		
	while ($dumped_data < $data_length)
		{
		my $size_to_dump = min($room_left, $data_length - $dumped_data) || 0 ;
		
		$room_left -= $size_to_dump ;
		
		$self->_dump_range_horizontal(1, $range, $line, $last_range, $current_offset, $dumped_data, $size_to_dump, $room_left) ;
		
		$dumped_data += $size_to_dump ;
		$current_offset += $size_to_dump ;
		
		if($room_left == 0 || $last_range == $range)
			{
			$line->{NEW_LINE}++ ;
			push @lines, $line ;
			
			$line = {} ;
			$room_left = $self->{DATA_WIDTH} ;
			
			push @lines,  @found_bitfields ;
			@found_bitfields = () ;
			}
		}
	}

if(@found_bitfields)
	{
	push @lines,  @found_bitfields ;
	@found_bitfields = () ;
	}

return \@lines ;
}

#-------------------------------------------------------------------------------

sub _split_vertical
{

=head2 [P] _split_vertical($collected_data)

Split the collected data into vertical lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> -  An Array  containing column elements

I<Exceptions>

=cut

my ($self, $collected_data) = @_ ;

my @lines ;
my $line = {} ;
my $wrapped_line = 0 ;

my $current_offset = 0 ;
my $total_dumped_data =  $self->{OFFSET_START} ;
my $room_left = $self->{DATA_WIDTH} ;

my $lines_since_header = 0 ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $user_information_size = $self->{MAXIMUM_USER_INFORMATION_SIZE} ;
my $range_source = ['?', 'white'] ;

my @found_bitfields ;

my $last_range = (grep {!  $_->{IS_BITFIELD}}@{$collected_data})[-1] ;

my @collected_data_to_dump = @{$collected_data} ;

while (my $range = shift @collected_data_to_dump)
	{
	my $data_length = defined $range->{DATA} ? length($range->{DATA}) : 0 ;
	my ($start_quote, $end_quote) = $range->{IS_COMMENT} ? ('"', '"') : ('<', '>') ;
		
	$range->{SOURCE} = $range_source  if $range->{IS_BITFIELD} ;
		
	# vertical mode
		
	$range->{COLOR} = $self->get_default_color($range->{COLOR}) ;
	
	$line = {} ;

	my $dumped_data = 0 ;
	my $current_range = '' ;
	
	if(!$range->{IS_BITFIELD} && 0 == $data_length && $self->{DISPLAY_RANGE_NAME}) # && $self->{DISPLAY_RANGE_NAME})
		{
		my $display_range_name = 0 ;
		
		if($range->{IS_COMMENT})
			{
			$display_range_name++ if $self->{DISPLAY_COMMENT_RANGE} ;
			}
		else
			{
			$display_range_name++ if $self->{DISPLAY_ZERO_SIZE_RANGE} ;
			}
				
		if($display_range_name)
			{
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME_COLOR' => $range->{COLOR},
				'RANGE_NAME' => "$start_quote$range->{NAME}$end_quote",
				} ;
				
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
		}
		
	if($range->{IS_HEADER}) 
		{
		# display the header
		push @lines, $self->get_information(\@lines, $range->{COLOR}) ;
		next ;
		}
	
	if($range->{IS_SKIP}) 
		{
		my $next_data_offset = $total_dumped_data + $data_length - 1 ;
		
		$range->{NAME} = '>>' . $range->{NAME} ;
	
		for my  $field_type 
			(
			['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $range->{NAME} }, $range->{COLOR}, $max_range_name_size] ,
			['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data}, undef, 8],
			['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $next_data_offset}, undef, 8],
			['BITFIELD_SOURCE', sub {' ' x 8}, undef, 8],
			[
			'HEX_DUMP', 
			sub 
				{
				my @bytes = unpack("(H2)*", pack("N", $data_length));
				pluralize("Skipped @bytes byte(s)", $data_length) ;
				},
			$range->{COLOR},
			3 * $self->{DATA_WIDTH},
			],
			[
			'HEXASCII_DUMP', 
			sub 
				{
				my @bytes = unpack("(H2)*", pack("N", $data_length));
				pluralize("Skipped @bytes byte(s)", $data_length) ;
				},
			$range->{COLOR},
			3 * $self->{DATA_WIDTH},
			],
			[
			'DEC_DUMP', 
			sub 
				{
				pluralize("Skipped $data_length byte(s)", $data_length)  ;
				},
			$range->{COLOR},
			4 * $self->{DATA_WIDTH}
			],
			['ASCII_DUMP', sub {$EMPTY_STRING}, $range->{COLOR}, $self->{DATA_WIDTH}],
			['USER_INFORMATION', sub { sprintf '%-20.20s', $range->{USER_INFORMATION} || ''}, $range->{COLOR}, 20],
			)
			{
			my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
			
			if($self->{"DISPLAY_$field_name"})
				{
				my $field_text = $field_data_formater->([]) ;
				my $pad = ' ' x ($field_text_size -  length($field_text)) ;
				
				push @{$line->{$field_name}},
					{
					$field_name . '_COLOR' => $color,
					$field_name =>  $field_text .  $pad,
					} ;
				}
			}
		
		$total_dumped_data += $data_length ;
		
		$line->{NEW_LINE} ++ ;
		push @lines, $line ;
		$line = {};
		
		next ;
		}
		
	while ($dumped_data < $data_length)
		{ 
		last if($range->{IS_BITFIELD}) ;

		my $left_offset = $total_dumped_data % $self->{DATA_WIDTH} ;
		
		if($left_offset)
			{
			# previous range did not end on DATA_WIDTH offset, align
			local $range->{DATA} = '0' x $self->{DATA_WIDTH} ;
			
			$self->_dump_range_vertical(0, $range, $line, 0, 0, $left_offset) ;
				
			$room_left -= $left_offset ;
			}
			
		my $size_to_dump = min($room_left, length($range->{DATA}) - $dumped_data) ;
		$room_left -= $size_to_dump ;
		$self->_dump_range_vertical(1, $range, $line, $dumped_data, $total_dumped_data, $size_to_dump) ;
		
		if($room_left)
			{
			local $range->{DATA} = '0' x $self->{DATA_WIDTH} ;
			
			$self->_dump_range_vertical(0, $range, $line, 0, 0, $room_left) ;
				
			$room_left = 0 ;
			}
			
		$dumped_data += $size_to_dump ;
		$total_dumped_data += $size_to_dump ;

		$line->{NEW_LINE} ++ ;
		push @lines, $line ;
		$line = {};
		$room_left = $self->{DATA_WIDTH} ;
		}
		
	if($range->{IS_BITFIELD})
		{
		push @lines, $self->get_bitfield_lines($range)  ;
		}
	else
		{
		$range_source = [$range->{NAME}, $range->{COLOR}]  ;
		}
	}

if(@found_bitfields)
	{
	push @lines,  @found_bitfields ;
	@found_bitfields = () ;
	}

return \@lines ;
}

#-------------------------------------------------------------------------------

sub _dump_range_horizontal
{
=head2 [P] _dump_range_horizontal(...)

Splits a range into a structure used for horizontal display

I<Arguments> - 

=over 2 

=item * $self - 

=item * $visible - Boolean - wether the range elements will be visible or not. used for alignment

=item * $range - the range structure created by Gather

=item * $line - container for the range strings to be displayed

=item * $last_range - Boolean - wether the range is the last one to be displayed

=item * $total_dumped_data - Integer -  the amount of total data dumped so far

=item * $dumped_data - Integer - the amount of byte dumped from the range so far

=item *  $size_to_dump - Integer - the amount of data to extract from the range

=item * $room_left - Integer - the amount of space left in the line for the dimped data

=back

I<Returns> -  Nothing. Stores the result in the $line argument

I<Exceptions>

=cut

my ($self, $visible, $range, $line, $last_range, $total_dumped_data, $dumped_data, $size_to_dump, $room_left) = @_ ;

my @range_unpacked_data = unpack("x$dumped_data C$size_to_dump", $range->{DATA}) ;
my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
		
for my  $field_type 
	(
	['OFFSET', sub {exists $line->{OFFSET} ? '' : sprintf $self->{OFFSET_FORMAT}, $total_dumped_data}, 'offset', 0],
	['BITFIELD_SOURCE', sub {exists $line->{BITFIELD_SOURCE} ? '' : ' ' x 8}, $self->get_bg_color(), 0],
	['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $range->{COLOR}, 3],
	['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $range->{COLOR}, 4],
	['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $range->{COLOR}, 1],
	['HEXASCII_DUMP', sub {sprintf q~%02x/%c ~ x $size_to_dump, map{$_ < 30 ? ($_, ord('.')) : ($_, $_) } @_}, $range->{COLOR}, 5],
	['RANGE_NAME',sub {sprintf "%.${max_range_name_size}s", $range->{NAME}}, $range->{COLOR}, 0],
	['RANGE_NAME', sub {', '}, undef, 0],
	)
	{
	my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
	
	if($self->{"DISPLAY_$field_name"})
		{
		my $field_text = $field_data_formater->(@range_unpacked_data) ;
		
		my $pad = $last_range == $range ? $pad_size  ? ' ' x ($room_left * $pad_size) : '' : '' ;
		
		my $text = $field_text . $pad ;

		unless($visible)
			{
			if($field_name eq 'ASCII_DUMP' || $field_name eq 'HEX_DUMP'  || $field_name eq 'HEXASCII_DUMP'  || $field_name eq 'DEC_DUMP' )
				{
				$text = ' ' x length($text)
				}
			}
		
		push @{$line->{$field_name}},
			{
			$field_name . '_COLOR' => $color,
			$field_name => $text
			} ;
		}
	}
}

#-------------------------------------------------------------------------------

sub _dump_range_vertical
{
=head2 [P] _dump_range_vertical()

Splits a range into a structure used for vertical display

I<Arguments> - 

=over 2 

=item * $self - 

=item * $visible - Boolean - wether the range elements will be visible or not. used for alignment

=item * $range - the range structure created by Gather

=item * $line - container for the range strings to be displayed

=item * $dumped_data - Integer - the amount of byte dumped from the range so far

=item * $total_dumped_data - Integer -  the amount of total data dumped so far

=item *  $size_to_dump - Integer - the amount of data to extract from the range

=back

I<Returns> -  

I<Exceptions>

=cut

my ($self, $visible, $range, $line, $dumped_data, $total_dumped_data, $size_to_dump) = @_ ;

my @range_data = unpack("x$dumped_data C$size_to_dump", $range->{DATA}) ;
my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $user_information_size = $self->{MAXIMUM_USER_INFORMATION_SIZE} ;

for my  $field_type 
	(
	['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $range->{NAME} ; }, $range->{COLOR}, $max_range_name_size] ,
	['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data}, 'offset', 8],
	['CUMULATIVE_OFFSET', sub {$dumped_data ? sprintf($self->{OFFSET_FORMAT}, $dumped_data) : ''}, 'cumulative_offset', 8],
	['BITFIELD_SOURCE', sub {'' x 8}, undef, 8],
	['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @{$_[0]}}, $range->{COLOR}, 3 * $size_to_dump],
        ['HEXASCII_DUMP', sub {sprintf q~%02x/%c ~ x $size_to_dump, map{$_ < 30 ? ($_, ord('.')) : ($_, $_) } @{ $_[0]}}, $range->{COLOR}, 5 * $size_to_dump],
	['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @{ $_[0] }}, $range->{COLOR}, 4 * $size_to_dump],
	['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @{$_[0]}}, $range->{COLOR}, $size_to_dump],
	['USER_INFORMATION', sub { sprintf "%-${user_information_size}.${user_information_size}s", $range->{USER_INFORMATION} || ''}, $range->{COLOR}, $user_information_size],
	)
	{
	my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
	
	if($self->{"DISPLAY_$field_name"})
		{
		my $field_text = $field_data_formater->(\@range_data) ;
		my $pad = ' ' x ($field_text_size -  length($field_text)) ;
		
		my $text = $field_text .  $pad ;
		
		unless($visible)
			{
			if($field_name eq 'ASCII_DUMP' || $field_name eq 'HEX_DUMP'  || $field_name eq 'DEC_DUMP'  || $field_name eq 'HEXASCII_DUMP' )
				{
				$text = ' ' x length($text) ;
				}
			else
				{
				$text = '' ;
				}
			}
			
		push @{$line->{$field_name}},
			{
			$field_name . '_COLOR' => $color,
			$field_name =>  $text,
			} ;
		}
	}
}

#-------------------------------------------------------------------------------

sub get_bitfield_lines
{

=head2 [P] get_bitfield_lines($bitfield_description)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $self - a Data::HexDump::Range object

=item * $bitfield_description - 

=back

I<Returns> - An Array  containing column elements, 

I<Exceptions> None but will embed an error in the element if any is found

=cut

my ($self, $bitfield_description) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $bitfield_description, '$bitfield_description', QUOTE_VALUES => 1 ;

return unless $self->{DISPLAY_BITFIELDS} ;

my ($line, @lines) = ({}) ;
my $digits_or_hex = '(?:(?:0x[0-9a-fA-F]+)|(?:\d+))' ;

my ($byte_offset, $offset, $size) = $bitfield_description->{IS_BITFIELD} =~ /^\s*(X$digits_or_hex)?\s*(x$digits_or_hex)?\s*(b$digits_or_hex)\s*$/ ;

 if(defined $byte_offset)
	{
	substr($byte_offset, 0, 1, '')  ;
	$byte_offset = hex($byte_offset) if  $byte_offset=~ /^0x/ ;
	}
	
 if(defined $offset)
	{
	substr($offset, 0, 1, '')  ;
	$offset = hex($offset) if  $offset=~ /^0x/ ;
	}
	
 if(defined $size)
	{
	substr($size, 0, 1, '')  ;
	$size = hex($size) if  $size =~ /^0x/ ;
	}

$byte_offset ||= 0 ;
$offset ||= 0 ; $offset += $byte_offset * 8 ;
$size ||= 1 ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $max_bitfield_source_size = $self->{MAXIMUM_BITFIELD_SOURCE_SIZE} ;

my %always_display_field = map {$_ => 1} qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET BITFIELD_SOURCE USER_INFORMATION) ;
my $bitfield_warning_displayed = 0 ;

#~ print DumpTree {length => length($bitfield_description->{DATA}), offset => $offset, size => $size, BF => $bitfield_description} ;
my $ascii_bitfield_dump_sub =
	sub 
	{
	my ($binary, @binary , @chars) ;
	
	if($self->{BIT_ZERO_ON_LEFT})
		{
		@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
		splice(@binary, 0, $offset) ;
		splice(@binary, $size) ;
		}
	else
		{
		@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
		splice(@binary, -$offset) unless $offset == 0 ;
		@binary = splice(@binary, - $size) ;
		}
		
	$binary = join('', @binary) ;
	@chars = map{$_ < 30 ? '.' : chr($_) } unpack("C*", pack("B32", substr("0" x 32 . $binary, -32)));
	
	my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
	splice @chars, 0 , (4 - $number_of_bytes), map {'-'} 1 .. (4 - $number_of_bytes) ;
	
	'.bitfield: '.  join('',  @chars) 
	} ;

for my  $field_type 
	(
	['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", '.' . $_[0]->{NAME} ; }, undef, $max_range_name_size ] ,
	['OFFSET', sub {sprintf '%02u .. %02u', $offset, ($offset + $size) - 1}, undef, 8],
	['CUMULATIVE_OFFSET', sub {''}, undef, 8],
	['BITFIELD_SOURCE', sub {sprintf "%-${max_bitfield_source_size}.${max_bitfield_source_size}s", $_[0]->{SOURCE}[0]}, $bitfield_description->{SOURCE}[1], 8],
	['HEX_DUMP', 
		sub 
		{
		my ($binary, @binary , $binary_dashed) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			
			$binary = join('', @binary) ;
			
			$binary_dashed = '-' x $offset . $binary . '-' x (32 - ($size + $offset)) ;
			$binary_dashed  = substr($binary_dashed , -32) ;
			$binary_dashed = substr($binary_dashed, 0, 8) . ' ' . substr($binary_dashed, 8, 8) . ' ' .substr($binary_dashed, 16, 8) . ' ' .substr($binary_dashed, 24, 8) ;
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			
			$binary = join('',  @binary) ;
			
			$binary_dashed = '-' x (32 - ($size + $offset)) . $binary . '-' x $offset  ;
			$binary_dashed  = substr($binary_dashed , 0, 32) ;
			$binary_dashed = substr($binary_dashed, 0, 8) . ' ' . substr($binary_dashed, 8, 8) . ' ' .substr($binary_dashed, 16, 8) . ' ' .substr($binary_dashed, 24, 8) ;
			}
		
		my $bytes = $size > 24 ? 4 : $size > 16 ? 3 : $size > 8 ? 2 : 1 ;
		
		my @bytes = unpack("(H2)*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @bytes, 0 , (4 - $number_of_bytes), map {'--'} 1 .. (4 - $number_of_bytes) ;
		
		join(' ', @bytes) . ' ' . $binary_dashed;
		},
		
		undef, 3 * $self->{DATA_WIDTH}],
	['HEXASCII_DUMP', 
		sub 
		{
		my $ascii_bitfield_dump = $ascii_bitfield_dump_sub->(@_) ;
	

		my ($binary, @binary , $binary_dashed) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			
			$binary = join('', @binary) ;
			
			$binary_dashed = '-' x $offset . $binary . '-' x (32 - ($size + $offset)) ;
			$binary_dashed  = substr($binary_dashed , -32) ;
			$binary_dashed = substr($binary_dashed, 0, 8) . ' ' . substr($binary_dashed, 8, 8) . ' ' .substr($binary_dashed, 16, 8) . ' ' .substr($binary_dashed, 24, 8) ;
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			
			$binary = join('',  @binary) ;
			
			$binary_dashed = '-' x (32 - ($size + $offset)) . $binary . '-' x $offset  ;
			$binary_dashed  = substr($binary_dashed , 0, 32) ;
			$binary_dashed = substr($binary_dashed, 0, 8) . ' ' . substr($binary_dashed, 8, 8) . ' ' .substr($binary_dashed, 16, 8) . ' ' .substr($binary_dashed, 24, 8) ;
			}
		
		my $bytes = $size > 24 ? 4 : $size > 16 ? 3 : $size > 8 ? 2 : 1 ;
		
		my @bytes = unpack("(H2)*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @bytes, 0 , (4 - $number_of_bytes), map {'--'} 1 .. (4 - $number_of_bytes) ;
		
		join(' ', @bytes) . '    ' . $binary_dashed . '     ' . $ascii_bitfield_dump ;

	
		},
		
		undef, 5 * $self->{DATA_WIDTH}],
	['DEC_DUMP', 
		sub 
		{
		my ($binary, @binary , $value) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			$binary = join('', @binary) ;
			$value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			$binary = join('', @binary) ;
			$value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			}
		
		my @values = map {sprintf '%03u', $_} unpack("W*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @values, 0 , (4 - $number_of_bytes), map {'---'} 1 .. (4 - $number_of_bytes) ;
		
		join(' ',  @values) . ' ' . "value: $value"  ;
		},
		
		$bitfield_description->{COLOR}, 4 * $self->{DATA_WIDTH}],
		
	['ASCII_DUMP',
		$ascii_bitfield_dump_sub,
		undef, $self->{DATA_WIDTH}],
		
	['USER_INFORMATION', 
		sub { sprintf '%-20.20s', $_[0]->{USER_INFORMATION} || ''}, 
		$bitfield_description->{COLOR}, 20],
		
	)
	{
	my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
	
	#~ print "($field_name, $field_data_formater, $color, $field_text_size)\n";
	$color ||= $bitfield_description->{COLOR} ;
	
	if($self->{"DISPLAY_$field_name"})
		{
		my ($bitfield_error, $field_text) = (0) ;
		
		if($always_display_field{$field_name})
			{
			$field_text = $field_data_formater->($bitfield_description) ;
			}
		else
			{
			if($size > 32)
				{
				$self->{INTERACTION}{WARN}
					(
					"Warning: bitfield description '$bitfield_description->{NAME}' is more than 32 bits long ($size)\n"
					)  unless $bitfield_warning_displayed++ ;
					
				$field_text = sprintf("%.${field_text_size}s", "Error: bitfield is more than 32 bits long ($size)") ;
				}
			elsif($EMPTY_STRING eq $bitfield_description->{DATA})
				{
				$self->{INTERACTION}{WARN}
					(
					"Warning: bitfield description '$bitfield_description->{NAME}' can't be applied to empty source\n"
					)  unless $bitfield_warning_displayed++ ;
					
				$field_text = sprintf("%.${field_text_size}s", "Error: Empty source") ;
				}
			elsif(length($bitfield_description->{DATA}) * 8 < ($offset + $size))
				{
				my $bits_missing_message = ($offset + $size) . " bits needed but only " . length($bitfield_description->{DATA}) * 8 . ' bits available' ;
				
				$self->{INTERACTION}{WARN}
					(
					"Warning: bitfield description '$bitfield_description->{NAME}' can't be applied "
					. "to source '$bitfield_description->{SOURCE}[0]':\n"
					. "\t$bits_missing_message\n"
					)  unless $bitfield_warning_displayed++ ;
					
				$field_text = sprintf("%.${field_text_size}s", 'Error: ' . $bits_missing_message) ;
				}
			else
				{
				$field_text = $field_data_formater->($bitfield_description) ;
				}
			}
		
		my $pad_size = $field_text_size -  length($field_text) ;
		push @{$line->{$field_name}},
			{
			$field_name . '_COLOR' => $color,
			$field_name =>  $field_text . ' ' x $pad_size,
			} ;
		}
	}

$line->{NEW_LINE} ++ ;
push @lines, $line ;

return @lines ;
}

#-------------------------------------------------------------------------------

sub add_information
{

=head2 [P] add_information($split_data)

Add information, according to the options passed to the constructor, to the internal data.

I<Arguments> - See L<gather>

=over 2

=item * $split_data - data returned by _gather()

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $split_data) = @_ ;

unshift @{$split_data}, $self->get_information($split_data) ;

}

#-------------------------------------------------------------------------------

sub get_information
{

=head2 [P] get_information($split_data)

Returns information, according to the options passed to the constructor, to the internal data.

I<Arguments> - See L<gather>

=over 2

=item * $split_data - data returned by _gather()

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $split_data, $range_color) = @_ ;
$range_color ||= 'ruler' ,

my @information ;

if($self->{DISPLAY_COLUMN_NAMES})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			my $length = $self->{FIELD_LENGTH}{$field_name} || croak "Error: undefined field length" ;
				
			$information .= sprintf "%-${length}.${length}s ", $field_name
			}
		}
		
	push @information,
		{
		INFORMATION => [ {INFORMATION_COLOR => $range_color, INFORMATION => $information} ], 
		NEW_LINE => 1,
		} ;
	}

if($self->{DISPLAY_RULER})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			for ($field_name)
				{
				/HEX_DUMP/ and do
					{
					$information .= $self->{OFFSET_FORMAT} =~ /x$/
							? join '', map {sprintf '%x  ' , $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1)
							: join '', map {sprintf '%d  ' , $ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;

					$information .= ' ' ;
					last ;
					} ;
					
				/DEC_DUMP/ and do
					{
					$information .= $self->{OFFSET_FORMAT} =~ /x$/
							? join '', map {sprintf '%x   ' , $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1)
							: join '', map {sprintf '%d   ' , $ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;

					$information .= ' ' ;
					last ;
					} ;
					
				/HEXASCII_DUMP/ and do
					{
					$information .= $self->{OFFSET_FORMAT} =~ /x$/
							? join '', map {sprintf '%x    ' , $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1)
							: join '', map {sprintf '%d    ' , $ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				/ASCII_DUMP/ and do
					{
					$information .= $self->{OFFSET_FORMAT} =~ /x$/
							? join '', map {sprintf '%x', $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1)
							: join '', map {$ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				$information .= ' ' x $self->{FIELD_LENGTH}{$field_name}  . ' ' ;
				}
			}
		}
		
	push @information,
		{
		RULER => [ { RULER_COLOR => $range_color, RULER=> $information} ], 
		NEW_LINE => 1,
		} ;
	}
	
return @information ;
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

Copyright Nadim Khemir 2010.

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

L<Data::HexDump::Range>

=cut
