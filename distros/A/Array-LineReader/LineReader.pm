package Array::LineReader;

use 5.005;
use strict;
use warnings;
use Carp;
use IO::File;
use Tie::Array;
require DynaLoader;

use vars qw( @ISA $VERSION );
@ISA = qw(Tie::Array);

=head1 NAME

Array::LineReader - Access lines of a file via an array

=head1 SYNOPSIS

  use Array::LineReader;
  my @lines;
  
  # Get the content of every line as an element of @lines:
  tie @lines, 'Array::LineReader', 'filename';
  print scalar(@lines);		# number of lines in the file
  print $lines[0];		# content of the first line
  print $lines[-1];		# content of the last line
  ...
  
  # Get the offset and content of every line as array reference via the elements of @lines:
  tie @lines, 'Array::LineReader', 'filename', result=>[];
  print scalar(@lines);		# number of lines in the file
  print $lines[5]->[0],":",$lines[5]->[1];	# offset and content of the 5th line
  print $lines[-1]->[0],":",$lines[-1]->[1];	# offset and content of the last line
  ...
  
  # Get the offset and content of every line as hash reference via the elements of @lines:
  tie @lines, 'Array::LineReader', 'filename', result=>{};
  print scalar(@lines);		# number of lines in the file
  print $lines[4]->{OFFSET},":",$lines[4]->{CONTENT};	# offset and content of the 4th line
  print $lines[-1]->{OFFSET},":",$lines[-1]->{CONTENT};	# offset and content of the last line
  ...

=cut

BEGIN {
	$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
}

=head1 VERSION and VOLATILITY

	$Revision: 1.1 $
	$Date: 2004/06/10 18:17:23 $

=head1 DESCRIPTION

Array::LineReader gives you the possibility to access lines of some file by the
elements of an array.
This modul inherites methods from C<Tie::Array> (see L<Tie::Array>).
You save a lot of memory, because the file's content is read only on demand, i.e. in 
the case you access an element of the array. The offset and length of all the lines 
is hold in memory as long as you tie your array.

The underlying file is opened for reading in binary mode.
(Yes, there are some OSs, that make a difference in 
interpreting the C<EOL>-sequence, i.e. C<End-Of-Line> and the C<EOF>-character, i.e.
C<End-Of-File> what is the character C<"\x1A">).
The bytes read are neigther translated nor suppressed.

Lines are build up to and including the C<EOL>-sequence.
The C<EOL>-sequence is assumed to be C<"\x0D\x0A"> or C<"\x0A\x0D"> or C<"\x0D"> or
C<"\x0A">.

The file is not closed until you C<untie> the array.

It's up to you to define the kind of access:

=head2 Access content by element

	tie @lines, 'Array::LineReader', 'filename';

You get the content of every line of the file by the elements of the array C<@lines>:

	print "@lines";

=head2 Access offset and content by array references

	tie @lines, 'Array::LineReader', 'filename', result=>[];

You get offset and content of every line of the file via the elements of the array C<@lines>:

	foreach (@lines){
		print $_->[0],":";	# offset
		print $_->[1];		# content
	}

=head2 Access offset and content by hash references

	tie @lines, 'Array::LineReader', 'filename', result=>{};

You get offset and content of every line of the file via the elements of the array C<@lines>:

	foreach (@lines){
		print $_->{OFFSET},":";	# offset
		print $_->{CONTENT};	# content
	}

=head1 METHODS

=head2 TIEARRAY

=over 4

=item TIEARRAY Create this class

Overwrites the method C<TIEARRAY> of C<Tie::Array> (see L<Tie::Array>). You never should have to call it.
It is used to create this class.

This method croaks if the C<filename> is missing.
It croaks too if the additional parameters do not have the form of a hash,
i.e. have an odd number.

The file is opened in binary mode for reading only. If the file does not exist or can not
be opened you will get an emtpy array without a warning.

The offset of every line and its length is hold in arrays corresponding to the lines of the file.
The content of a given line is read only if you access the corresponding element of the tied array.

=back

=cut

sub TIEARRAY{
	my $class = shift;
	croak "Usage: tie \@lines, 'Array::LineReader', 'filename' [, result=>type_of_result]\n" unless @_;
	my $filename = shift;
	my $self = {};
	$self->{PARMS} = {result=>''};
	croak "Odd number of parameters to be used in a hash!\n" unless scalar(@_) % 2 == 0;
	$self->{PARMS} = {@_} if @_;	# carps if odd number of parameters
	$self->{FH} = undef;
	if (-f $filename){
		$self->{FH} = new IO::File;
		$self->{FH}->open($filename) or $self->{FH} = undef;
		binmode($self->{FH}) if $self->{FH};
	}
	$self->{OFFSETS} = [0];
	$self->{LENGTHS} = [0];
	$self->{EOF} = 1 unless $self->{FH};
	bless $self, $class;
}

=head2 FETCHSIZE

=over 4

=item FETCHSIZE Define the size of the tied array.

Overwrites the method C<FETCHSIZE> of C<Tie::Array> (see L<Tie::Array>). You never should have to call it.
This method is called any time the size of the underlying array has to be defined.

The size of the tied array is defined to be the number of B<lines read so far>.

Lets have an example:

	tie @lines, 'Array::LineReader', 'filename';
	$line5 = $lines[4];	# access the 5th line.
	print scalar(@lines);	# prints: 5
	$lastline = $lines[-1];	# access the last line of the file
	print scalar(@lines);	# prints: number of lines in the file

=back

=cut

sub FETCHSIZE{
	my $self = shift;
	my $index = $#{$self->{OFFSETS}};	# use current number of elements
	while (!$self->{EOF}){ $self->_readIt($index++); }	# read until EOF
	return $index;	
}

=head2 FETCH

=over 4

=item FETCH access a specified element of the tied array

Overwrites the method C<FETCH> of C<Tie::Array> (see L<Tie::Array>). You never should have to call it.
This method is called any time you want to access a given element of the tied array.

If you access an already known element, the offset of the line to read is sought and the
line is read with the already known length.
If you access a not yet known element, the file is read up to the corresponding line.

Lets have an example:

	tie @lines, 'Array::LineReader', 'filename';
	foreach (@lines){
		print $_;	# access one line after the other
	}
	...
	print $lines[5];	# seeks the offset of the 6th line and reads it

You should use the tie command with additional parameter defining the type of the result,
if you want to have access not only to the content of a line but also to its offset.

	tie @lines, 'Array::LinesReader', 'filename', result=>{};
	print $lines[8]->{OFFSET};	# Offset of the 9th line.
	print $lines[8]->{CONTENT};	# Content of the 9th line.

or to get the offset and content by reference to an array:

	tie @lines, 'Array::LinesReader', 'filename', result=>[];
	print $lines[8]->[0];	# Offset of the 9th line.
	print $lines[8]->[1];	# Content of the 9th line.

=back

=cut

sub FETCH{
	my ($self,$index) = @_;
#	$index = scalar(@{$self->{OFFSETS}}) + $index if $index < 0;	# correct negative index
#	croak "Array index out of bounds" if $index < 0;
	if  ($index > $#{$self->{OFFSETS}}){
		$self->_readUpTo($index);
		$index = $#{$self->{OFFSETS}};
	}
	my $out = $self->_readIt($index);
	for (ref $self->{PARMS}->{result}){
		/^HASH$/  && return {OFFSET=>$self->{OFFSETS}->[$index],CONTENT=>$out};
		/^ARRAY$/ && return [$self->{OFFSETS}->[$index],$out];
	}
	return $out;
}

=head2 DESTROY

=over 4

=item DESTROY 

Overwrites the method C<DESTROY> of C<Tie:Array> (see L<Tie::Array>).
Closes the file to free some memory.

=back

=cut

sub DESTROY{
	my $self = shift;
	close $self->{FH} if $self->{FH};
}

=head2 EXISTS

=over 4

=item EXISTS

Overwrites the method C<EXISTS> of C<Tie::Array> (see L<Tie::Array>).
Returns true if the array's element was already read.

=back

=cut

sub EXISTS{
	my ($self, $index) = @_;
	return ($index >= 0) && ($index < $self->FETCHSIZE());
}

sub _readOnly{ croak "The tied array is readonly and can not be modified in any way\n"; }
*STORE = \&_readonly;
*STORESIZE = \&_readOnly;
*CLEAR = \&_readOnly;
*POP = \&_readOnly;
*PUSH = \&_readOnly;
*SHIFT = \&_readOnly;
*UNSHIFT = \&_readOnly;
*DELETE = \&_readOnly;
*EXTEND = \&_readOnly;
	
sub _readIt{
	my ($self,$index) = @_;
	my $out = undef;
	die "Invalid call of privat method _readIt" if $index > $#{$self->{OFFSETS}};
	return $out unless $self->{FH};
	seek($self->{FH}, $self->{OFFSETS}->[$index], 0);
	if ($index == $#{$self->{OFFSETS}}){
		$self->{EOF} or $out = $self->_readLine();
		if (defined $out){
			$self->{LENGTHS}->[-1] = length($out);
			push(@{$self->{OFFSETS}},tell($self->{FH}));
			push(@{$self->{LENGTHS}},0);
		}
	}else{
		$out = $self->_readLine($self->{LENGTHS}->[$index]);
	}
	return $out;
}

sub _readUpTo{
	my ($self,$index) = @_;
	return unless $self->{FH};
	return if $self->{EOF};
	die "Invalid call of privat method _readUpTo" if $index <= $#{$self->{OFFSETS}};
	for (my $idx = $#{$self->{OFFSETS}}; $idx < $index; $idx++){
		$self->_readIt($idx);
		last if $self->{EOF};
	}
}

sub _readLine{
	my $self = shift;
	my $length = shift || 0;
	my $fh = $self->{FH};
	my $line = "";
	$length && $fh->read($line, $length) && return $line;	# read $length byte if requested
		
	my $c = 0;
	while (defined ($c = $fh->getc) && $c !~ /^[\x0A\x0D]$/){
		$line .= $c;
	}
	if (!defined $c){
		$self->{EOF} = 1;
		return (length($line)) ? $line : $c;
	}
	$line .= $c;
	my $nl = $fh->getc;
	if (defined $nl && ($nl eq $c || $nl !~ /^[\x0A\x0D]$/)){
		$fh->ungetc(ord($nl));
	}elsif(defined $nl && $nl ne $c){
		$line .= $nl;
	}else{
		$self->{EOF} = 1;
	}
	return $line;
}
	
	
1;
__END__

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Array::FileReader>, L<Tie::Array>, L<Tie::File>

=head1 HISTORY

 * $Log: LineReader.pm,v $
 * Revision 1.1  2004/06/10 15:07:37  Bjoern_Holsten
 * First stable (as seems) version
 *

=head1 AUTHOR

Bjoern Holsten E<lt>bholsten + At + cpan + DoT + orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Bjoern Holsten

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
