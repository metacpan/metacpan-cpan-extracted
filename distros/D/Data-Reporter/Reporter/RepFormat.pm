package RepFormatPtr;
use strict;
use Carp;
sub Printf($$@) {
	my ($self, $format, @args) = @_;
	my $str = sprintf($format, @args);
	Print($self, $str);
}

sub Commify($$) {
	my ($self, $str) = @_;

	return "" unless(defined($str));
	croak "Incorrect format ($str) to put commas"
   			if ($str !~ /([+-]{0,1})(\d+)(\.{0,1})(\d*)/);
	my $sign = "";
	$sign = $1 if (defined($1));
	my $integerpart = $2;
	my $decimalpart = "";
	$decimalpart = "\.$4" if ($4 ne "");
	my $size = length($str);

	$integerpart = reverse $integerpart;
	$str = "";
	while ($integerpart ne "") {
		if (length($integerpart) > 3) {
			$str .= substr($integerpart, 0, 3);
			$str .= ",";
			substr($integerpart, 0, 3) = "";
		} else {
			$str .= substr($integerpart, 0, length($integerpart));
			$integerpart = "";
		}
	}

	$str = $sign . (reverse $str) . $decimalpart;
	my $espaces = "";
	$espaces = " " x ($size - length($str)) if ($size >= length($str));
	$str = $espaces . $str;
	return $str;
}

sub MVPrintf($$$$@) {
	my ($self, $x, $y, $format, @args) = @_;
	Move($self, $x, $y);
	Printf($self, $format, @args);
}

package Data::Reporter::RepFormat;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	FORMAT_HEADER
);
$VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined RepFormat macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Data::Reporter::RepFormat $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RepFormat	- Allows text formatting with simple instructions, mapping to a user-defined grid (the sheet).

=head1 SYNOPSIS

	use Data::Reporter::RepFormat;

	$sheet = new Data::Reporter::RepFormat($cols, $rows);
	$sheet->Move(0,3);
	$sheet->Print('123');
	$sheet->Out();
	$sheet->Clear();
	$sheet->Printf('%010d', 12);
	$sheet->MVPrint(0, 3, '123');
	$sheet->MVPrintf(0, 1, '%3.2f', 79.123);
	$sheet->Nlines();
	$sheet->Getline(20);
	$sheet->Copy($source_sheet);
	$sheet->Center('hello', 10);
	my $pic = $sheet->ToPicture('$$$,999, 999', 1234.56);
	$value = $sheet->Commify('1234567.89');

=head1 DESCRIPTION

=item new($cols, $rows)

Creates a new RepFormat object. This function receives two parameters: columms and rows of the sheet.

=item $sheet->Move($col, $row)

Moves cursor to the indicated position

=item $sheet->Print($string)

Puts $string at the current cursor position.

=item $sheet->Out([$handle])

Moves the sheet information to target output. If $handle is not specified, then STDOUT is used.

=item $sheet->Clear()

Clears the sheet

=item $sheet->Printf(format, argument)

Prints using printf style format

=item $sheet->MVPrint($col, $row, $string)

Moves, then Prints

=item $sheet->MVPrintf($col, $row, format, argument)

Moves, then Prints (using printf style format)

=item $sheet->Nlines()

Returns the number of lines in the sheet, discarding the last blank lines

=item $sheet->getX()

Returns current column position (X)

=item $sheet->getY()

Returns current row position (Y)

=item $sheet->Getline($index)

Returns the $index row 

=item $sheet->Copy($source_sheet)

Appends $source_sheet in $sheet

=item $sheet->Center($string, $size)

Returns a string with size = $size having $string centered in it. This function uses spaces to pad on both sides.

=item $sheet->Commify($number);

Returns $number as a string with commas (123456789.90 -> 123,456,789.90)

*NOTE This function will be no longer supported in next releases. Use PrintP instead.

=item $sheet->printP($string, $picture);

Puts a string at the current position with $string in the specified $picture.

There are two clases of pictures: strings and numerical

=over 

=item strings

The following table list the text edit format characters:


Character			Description						
X             		Use character in field			 
B             		Insert blank           			
~(tilde)      		Skip character in field			

examples

Mask				value			Display
(xxx)bxxx-xxxx		2169910551		(216) 991-0551
xxx-xx-xxxx   		123456789 		123-45-6789
~~xx~xx       		ABCDEFGHIJ		CDFG

=back

=over

=item numerical

The following table list the numerical edit format characters:

Character			Description							
8				Digit, zero fill to the rigth of 
				the decimal point trim leading 
				blanks (left justify the number)
9				Digit, zero fill to the right of 
				the decimal point, space fill to
				the left					
0				Digit, zero fill to the left
$				Dollar sign, optionally floats to 
				the right					
B				Treated as a "9", but if a value
				is zero, the field is converted
				to blanks
V				Implied decimal point
MI				Entered at the end of the mask
				causes a minus to be displayed at
				the right of the number
PR				Entered at teh end of the mask
				causes angle brackets (<>) to be
				displayed around the number if 
				the number is negative
PS				Entered at the end of the mask
				causes parentheses to display
				around the number if the number
				is negative
PF				Entered at the end of the mask
				causes floating parentheses to
				display around teh number if 
				the number is negative
.				Decimal point
,				Comma

examples

Mask				value			Display		
999.99        		34.568    		      34.57   
9,999,999v99  		123,456.78		 123,456.78
8,888,888.88  		123,456,78		123,456.78 
9,999           	1234       		      1,234	
09999           	1234       		      01234	 
9999            	12345      		       **** 
9999mi          	-123       		       123-	 
9999pr           	-123       		     < 123>	
9999ps          	-123       		     ( 123)	
9999pf           	-123       		     ( 123)	

=back

=item $sheet->MVPrintP($col, $row, $string, $pic)

Moves, then PrintP

=cut
