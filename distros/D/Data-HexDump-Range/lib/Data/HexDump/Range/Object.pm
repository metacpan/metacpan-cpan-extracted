
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
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Object - Hexadecial Range Dumper object creation support methods

=head1 SYNOPSIS

=head1 DESCRIPTION

The main goal of this module is to remove non public APIs from the module documentation

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut


#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => 
	[
	qw(
	NAME INTERACTION VERBOSE
	
	DUMP_RANGE_DESCRIPTION
	DUMP_ORIGINAL_RANGE_DESCRIPTION
	GATHERED_CHUNK
	
	FORMAT 
	COLOR 
	START_COLOR
	OFFSET_FORMAT 
	OFFSET_START
	DATA_WIDTH 
	DISPLAY_COLUMN_NAMES
	DISPLAY_RULER
	DISPLAY_OFFSET 
	DISPLAY_CUMULATIVE_OFFSET
	DISPLAY_ZERO_SIZE_RANGE_WARNING
	DISPLAY_ZERO_SIZE_RANGE 
	DISPLAY_COMMENT_RANGE
	
	DISPLAY_RANGE_NAME
	MAXIMUM_RANGE_NAME_SIZE
	DISPLAY_RANGE_SIZE
	
	DISPLAY_ASCII_DUMP
	DISPLAY_HEXASCII_DUMP
	DISPLAY_HEX_DUMP
	DISPLAY_DEC_DUMP
	
	DISPLAY_USER_INFORMATION
	MAXIMUM_USER_INFORMATION_SIZE
	
	DISPLAY_BITFIELDS
	DISPLAY_BITFIELD_SOURCE
	MAXIMUM_BITFIELD_SOURCE_SIZE
	
	BIT_ZERO_ON_LEFT
	COLOR_NAMES 
	ORIENTATION 
	)] ;

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [P] Setup()

Helper sub called by new. This is a private sub.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

if (@setup_data % 2)
	{
	croak "Invalid number of argument '$file_name, $line'!" ;
	}

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;
$self->{NAME} = 'Anonymous';
$self->{FILE} = $file_name ;
$self->{LINE} = $line ;

$self->CheckOptionNames($NEW_ARGUMENTS, @setup_data) ;

%{$self} = 
	(
	%{$self},
	
	VERBOSE => 0,
	DUMP_RANGE_DESCRIPTION => 0,
	DUMP_ORIGINAL_RANGE_DESCRIPTION => 0,
	
	FORMAT => 'ANSI',
	
	COLOR => 'cycle',
	CURRENT_COLOR_INDEX => 0,
	START_COLOR	=> undef,
	
	# --color bw will use the last defined color as color
	COLORS =>
		{
		ASCII => [],
		ANSI => [map {"bright_$_"} 'green', 'yellow', 'cyan', 'magenta', 'blue', 'red', 'green', 'yellow', 'cyan', 'magenta', 'blue', 'red', 'white', ],
		HTML => [map {"bright_$_"} 'green', 'yellow', 'cyan', 'magenta', 'blue', 'red', 'green', 'yellow', 'cyan', 'magenta', 'blue', 'red', 'white', ],
		},
		
	OFFSET_FORMAT => 'hex',
	OFFSET_START => 0,
	
	DATA_WIDTH => 16,
	
	DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
	DISPLAY_ZERO_SIZE_RANGE => 1,
	DISPLAY_COMMENT_RANGE => 1,
	
	DISPLAY_RANGE_NAME => 1,
	MAXIMUM_RANGE_NAME_SIZE => 16,
	DISPLAY_RANGE_SIZE => 1,
	
	DISPLAY_COLUMN_NAMES  => 0 ,
	DISPLAY_RULER => 0,
	
	DISPLAY_OFFSET => 1,
	DISPLAY_CUMULATIVE_OFFSET => 1,

	DISPLAY_HEXASCII_DUMP => 0,

	DISPLAY_HEX_DUMP => 1,
	DISPLAY_DEC_DUMP => 0,
	DISPLAY_ASCII_DUMP => 1,
	DISPLAY_USER_INFORMATION => 0,
	MAXIMUM_USER_INFORMATION_SIZE => 20,

	DISPLAY_BITFIELDS => undef,
	DISPLAY_BITFIELD_SOURCE => 1,
	MAXIMUM_BITFIELD_SOURCE_SIZE => 8,
	BIT_ZERO_ON_LEFT => 0,
	
	ORIENTATION => 'horizontal',
	
	GATHERED => [],
	@setup_data,
	) ;

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;

my $location = "$self->{FILE}:$self->{LINE}" ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

$self->{MAXIMUM_RANGE_NAME_SIZE} = 4 if$self->{MAXIMUM_RANGE_NAME_SIZE} < 4 ;

$self->{FIELD_LENGTH} =
	{
	OFFSET =>  $self->{OFFSET_FORMAT} =~ /^hex/ ? 8 : 10,
	CUMULATIVE_OFFSET =>  $self->{OFFSET_FORMAT} =~ /^hex/ ? 8 : 10,
	RANGE_NAME =>  $self->{MAXIMUM_RANGE_NAME_SIZE},
	ASCII_DUMP =>  $self->{DATA_WIDTH},
	HEX_DUMP =>  $self->{DATA_WIDTH} * 3,
	DEC_DUMP =>  $self->{DATA_WIDTH} * 4,
	HEXASCII_DUMP => $self->{DATA_WIDTH} * 5,
	USER_INFORMATION =>  20,
	BITFIELD_SOURCE => 8 ,
	} ;

$self->{OFFSET_FORMAT} = $self->{OFFSET_FORMAT} =~ /^hex/ ? "%08x" : "%010d" ;

if($self->{ORIENTATION} =~ /^hor/)
	{
	$self->{DISPLAY_BITFIELDS} = 0 unless defined $self->{DISPLAY_BITFIELDS} ;
	$self->{DISPLAY_BITFIELD_SOURCE} = 0 unless $self->{DISPLAY_BITFIELDS} ;
	
	my @fields = qw(OFFSET) ;
	push @fields, 'BITFIELD_SOURCE' if $self->{DISPLAY_BITFIELD_SOURCE} ;
	push @fields, qw( HEX_DUMP HEXASCII_DUMP DEC_DUMP ASCII_DUMP RANGE_NAME) ;
	
	$self->{FIELDS_TO_DISPLAY} =  \@fields ;
	}
else
	{
	$self->{DISPLAY_BITFIELDS} = 1 unless defined $self->{DISPLAY_BITFIELDS} ;
	
	$self->{FIELDS_TO_DISPLAY} =  
		 [qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP HEXASCII_DUMP DEC_DUMP ASCII_DUMP USER_INFORMATION)] ;
	}

#Todo: verify FORMAT

if(! defined $self->{COLOR} || ($self->{COLOR} ne 'cycle' && $self->{COLOR} ne 'no_cycle' && $self->{COLOR} ne 'bw'))
	{
	$self->{COLOR} ||= 'error!' ;
	$self->{INTERACTION}{DIE}("Error: Invalid color format. Valid formats are 'cycle', 'no_cycle' and 'bw'.\n")  ;
	}

if(! defined $self->{FORMAT} || ($self->{FORMAT} ne 'ANSI' && $self->{FORMAT} ne 'HTML' && $self->{FORMAT} ne 'ASCII'))
	{
	$self->{FORMAT} ||= 'error!' ;
	$self->{INTERACTION}{DIE}("Error: Invalid output format. Valid formats are 'ANSI', 'HTML', and 'ASCII'.\n")  ;
	}

if(defined $self->{GATHERED_CHUNK} && 'CODE' ne ref($self->{GATHERED_CHUNK}))
	{
	$self->{INTERACTION}{DIE}("Error: GATHERED_CHUNK is not a code reference.\n")  ;
	}

if(defined $self->{START_COLOR})
	{
	my $index = 0 ;
	
	for my $color_name (@{$self->{COLORS}{$self->{FORMAT}}})
		{
		last if $color_name eq $self->{START_COLOR} ;
		$index++ ;
		}
		
	$self->{CURRENT_COLOR_INDEX} = $index ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [P] CheckOptionNames()

Verifies the named options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. 

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	$valid_options = { map{$_ => 1} @{$valid_options} } ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("Invalid argument '$valid_options'!") ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->
				(
				"$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'\nValid options:\n\t"
				.  join("\n\t", sort keys %{$valid_options}) . "\n"
				);
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
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

L<Data::Hexdumper>, L<Data::ParseBinary>, L<Convert::Binary::C>, L<Parse::Binary>

=cut
