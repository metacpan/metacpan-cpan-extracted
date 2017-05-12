package Data::Sheet;

use 5.012001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Preloaded methods go here.

sub new {
	my $class = shift;
	my ($w, $h, $init) = @_;
	my $self = {
		width   => defined $w    ? $w    : 1,
		height  => defined $h    ? $h    : 1,
		initVar => defined $init ? $init : 0, 
		table1  => [],
		table2  => [],
		flag    => 0, 
	};
	# Initialize
	for(my $i = 0; $i < ($self->{width} * $self->{height}); $i++) {
		push(@{ $self->{table1} }, $self->{initVar});
		push(@{ $self->{table2} }, $self->{initVar});
	}
	return bless($self, $class);
}

sub resize {
	my $self = shift;
	my ($w, $h) = @_;
	my ($now_x, $now_y);
	# initialize data
	$self->{flag} == 1 ?
		$self->{table2} = [] : #initialize table2
		$self->{table1} = [];
	for(my $i = 0; $i < ($w * $h); $i++) {
		if($self->{flag} == 1) { #if using table1
			push(@{$self->{table2}}, $self->{initVar});
		}
		else {
			push(@{$self->{table1}}, $self->{initVar});
		}
	}
	# copying data 
	my $i = 0;
	while(1) {
		$now_x = $i % $self->{width};
		$now_y = int($i / $self->{width});
		if($now_x >= $self->{width} || 
			$now_y >= $self->{height}) {
			last;
		}
		if($self->{flag} == 1) {
			$self->{table2}[$now_x + $now_y * $w] 
				= $self->{table1}[$i];
		} else {
			$self->{table1}[$now_x + $now_y * $w] 
				= $self->{table2}[$i];
		}
		$i++;
	};
	# change flag
	if($self->{flag} == 1) {
		$self->{flag} = 0;
	}
	elsif($self->{flag} == 0) {
		$self->{flag} = 1;
	}
	# Resize 
	$self->{width} = $w;
	$self->{height} = $h;
}

sub setCell {
	my $self = shift;
	my ($x, $y, $var) = @_;
	if($self->{width} * $self->{height} < $x * $y) {
		# bad status
		return undef;
	}
	else {
		$self->{flag} == 1 ?
			$self->{table1}[$y * $self->{width} + $x] = $var :
			$self->{table2}[$y * $self->{width} + $x] = $var;
		# good status
		return 0;
	}
}

sub getCell {
	my $self = shift;
	my ($x, $y) = @_;
	if($self->{width} * $self->{height} < $x * $y) {
		return undef;
	}
	else {
		$self->{flag} == 1 ?
			return $self->{table1}[$y * $self->{width} + $x] :
			return $self->{table2}[$y * $self->{width} + $x];
	}
}

sub printSheet {
	my $self = shift;
	for(my $j = 0; $j < $self->{height}; $j++) {
		for(my $i = 0; $i < $self->{width}; $i++) {
			$self->{flag} == 1 ?
			print "[@{ $self->{table1} }[$j
				* $self->{width} + $i]]" :
			print "[@{ $self->{table2} }[$j 
			     	* $self->{width} + $i]]";
		}
		print "\n";
	}
}

sub turnRight {
	my $self = shift;
	my ($now_x, $now_y);
	my ($new_x, $new_y);
	# initialize data
	$self->{flag} == 1 ?
		$self->{table2} = [] : 
		$self->{table1} = [];
	for(my $i = 0; $i < ($self->{width} * $self->{height}); $i++) {
		if($self->{flag} == 1) { #if using table1
			push(@{$self->{table2}}, $self->{initVar});
		}
		else {
			push(@{$self->{table1}}, $self->{initVar});
		}
	}
	# copy Data
	my $i = 0;
	while($i < ($self->{width} * $self->{height})) {
		# Calc current position
		$now_x = $i % $self->{width};
		$now_y = int($i / $self->{width});
		# Calc new position
		$new_x = ($self->{height} - 1 - $now_y);
		$new_y = $now_x;
		if($self->{flag} == 1) {
			$self->{table2}[$new_x + $new_y * $self->{height}] 
				= $self->{table1}[$i];
		} else {
			$self->{table1}[$new_x + $new_y * $self->{height}] 
				= $self->{table2}[$i];
		}
		$i++;
	};
	($self->{width}, $self->{height}) = 
		($self->{height}, $self->{width});
	#change Flag
	if($self->{flag} == 1) {
		$self->{flag} = 0;
	}
	else {
		$self->{flag} = 1;
	}
}

sub turnLeft {
	my $self = shift;
	my ($now_x, $now_y);
	my ($new_x, $new_y);
	# initialize data
	$self->{flag} == 1 ?
		$self->{table2} = [] : 
		$self->{table1} = [];
	for(my $i = 0; $i < ($self->{width} * $self->{height}); $i++) {
		if($self->{flag} == 1) { #if using table1
			push(@{$self->{table2}}, $self->{initVar});
		}
		else {
			push(@{$self->{table1}}, $self->{initVar});
		}
	}
	# copy Data
	my $i = 0;
	while($i < ($self->{width} * $self->{height})) {
		# Calc current position
		$now_x = $i % $self->{width};
		$now_y = int($i / $self->{width});
		# Calc new position
		$new_x = $now_y;
		$new_y = ($self->{width} - 1 - $now_x);
		if($self->{flag} == 1) {
			$self->{table2}[$new_x + $new_y * $self->{height}] 
				= $self->{table1}[$i];
		} else {
			$self->{table1}[$new_x + $new_y * $self->{height}] 
				= $self->{table2}[$i];
		}
		$i++;
	};
	($self->{width}, $self->{height}) = 
		($self->{height}, $self->{width});
	#change Flag
	if($self->{flag} == 1) {
		$self->{flag} = 0;
	}
	else {
		$self->{flag} = 1;
	}
}

sub getRow {
	my $self = shift;
	my $row = shift;
	if($row > ($self->{height} - 1) ||
		$row < 0) {
			return undef;
	}
	my @rowArray = ();
	for(my $i = 0; $i < $self->{width}; $i++) {
		$self->{flag} == 1 ?
			push(@rowArray, @{$self->{table1}}[$row * $self->{width} + $i]) :
			push(@rowArray, @{$self->{table2}}[$row * $self->{width} + $i]);
	}
	return @rowArray;
}

sub getCol {
	my $self = shift;
	my $col = shift;
	if($col > ($self->{width} - 1) ||
		$col < 0) {
			return undef;
	}
	my @colArray = ();
	for(my $i = 0; $i < $self->{height}; $i++) {
		$self->{flag} == 1 ?
			push(@colArray, @{$self->{table1}}[$col + $self->{width} * $i]) :
			push(@colArray, @{$self->{table2}}[$col + $self->{width} * $i]);
	}
	return @colArray;
}

sub setRow {
	my ($self,$row,$data) = @_;
	if($row > ($self->{height} - 1) ||
		$row < 0) {
			return 1;
	}
	for(my $i = 0; $i < $self->{width} && $i < ($#{$data} + 1); $i++) {
		if($self->{flag} == 1) {
			@{$self->{table1}}[$row * $self->{width} + $i] = ${$data}[$i];
		}
		else {
			@{$self->{table2}}[$row * $self->{width} + $i] = ${$data}[$i];
		}
	}
	return 0;
}

sub setCol {
	my ($self, $col, $data) = @_;
	if($col > ($self->{width} - 1) ||
		$col < 0) {
			return 1;
	}
	for(my $i = 0; $i < $self->{height} && $i < ($#{$data} + 1); $i++) {
		if($self->{flag} == 1) {
			@{$self->{table1}}[$col + $self->{width} * $i] = ${$data}[$i];
		}
		else {
			@{$self->{table2}}[$col + $self->{width} * $i] = ${$data}[$i];
		}
	}
	return 0;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Data::Sheet - Perl extension for provide DataSheet like data structure.

=head1 SYNOPSIS

  use Data::Sheet;

  # new(width, height, initVar);
  $table = Data::Sheet->new(10, 10, 0);

=head1 DESCRIPTION

Provide table like data structure.

=head1 API

=head2 Constructor

=over

=item new(width, height, initVar)

the new method. Return width * height size sheet object that initialized by initVar.	

=back

=head2 Control Methods

=over

=item resize(newWidth, newHeight)

Resize the sheet.

=item turnRight

Turn Right the sheet.

=item turnLeft

Turn Left the sheet.

=back

=head2 Accessor Methods

=over

=item setCell(x, y, value)

Set value to sheet(x, y) cell.

=item getCell(x, y, value)

Get value from sheet(x, y) cell.

=item setRow(x, values) 

Set row to values.

=item getRow(x)

Get values from sheet's x row.

=item setCol(y, values)

Set column to values

=item getCol(y)

Get values from sheet's y column	

=back

=head2 Other method

=over

=item printSheet

Print sheet simply.

=back

=head1 SEE ALSO

=head1 AUTHOR

Pocket, E<lt>poketo7878@yahoo.co.jp<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pocket

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
