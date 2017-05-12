#########1 Test File for DateTimeX::Format::Excel::Types    6#########7#########8#########9
#!perl
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	#~ $ENV{ Smart_Comments } = '###';
}
if( $ENV{ Smart_Comments } ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for testing DateTimeX-Format-Excel-Types ...
}
$| = 1;
use	Test::Most tests => 14;
use	Test::Moose;
use	DateTime;
use	lib '../../../../lib',;
use	DateTimeX::Format::Excel::Types qw(
		DateTimeHash
		DateTimeInstance
		HashToDateTime
		ExcelEpoch
		SystemName
);
my  (
			$position,
	);
my 			$row = 0;
my			$question_ref =[
				{ year => 2014 },
				DateTime->new( year => 1900 ),
				59.125,
				#~ RecursiveType,
				undef,
				'apple_excel',
			];
my			$bad_value_ref =[
				{ day => 32 },
				DateTimeInstance,
				-1,
				#~ DateTime->new( year => 1900 ),
				"",
				'linux_excel',
			];
my			$answer_ref = [
				qr/\QReference {"day" => 32} did not pass type constraint "DateTimeHash"\E/,
				qr/\Q) did not pass type constraint "DateTimeInstance"\E/,
				qr/\Q--1- is less than 0\E/,
				qr/\Q-- is not a Number\E/,
				qr/\QValue "linux_excel" did not pass type constraint "SystemName"\E/,
				qr/\QHello World\E/,
			];
### <where> - harder questions ...
							$position = 0;
ok			DateTimeHash->( $question_ref->[$position] ),
							"Check that a good value passes DateTimeHash: $question_ref->[$position]";
dies_ok{	DateTimeHash->( $bad_value_ref->[$position] ) }
							"Check that a bad value fails DateTimeHash: $bad_value_ref->[$position]";
like		$@, $answer_ref->[$position++],
							"... and check for the correct error message";
ok			DateTimeInstance->( $question_ref->[$position] ),
							"Check that a good value passes DateTimeInstance: $question_ref->[$position]";
dies_ok{	DateTimeInstance->( $bad_value_ref->[$position] ) }
							"Check that a bad value fails DateTimeInstance: $bad_value_ref->[$position]";
like		$@, $answer_ref->[$position++],
							"... and check for the correct error message";
ok			ExcelEpoch->( $question_ref->[$position] ),
							"Check that a good value passes ExcelEpoch: $question_ref->[$position]";
dies_ok{	ExcelEpoch->( $bad_value_ref->[$position] ) }
							"Check that a bad value fails ExcelEpoch: $bad_value_ref->[$position]";
like		$@, $answer_ref->[$position++],
							"... and check for the correct error message";
dies_ok{	ExcelEpoch->( $bad_value_ref->[$position] ) }#""
							"Check that a bad value fails ExcelEpoch: $bad_value_ref->[$position]";#
like		$@, $answer_ref->[$position++],
							"... and check for the correct error message";
ok			SystemName->( $question_ref->[$position] ),
							"Check that a good value passes SystemName: $question_ref->[$position]";
dies_ok{	SystemName->( $bad_value_ref->[$position] ) }
							"Check that a bad value fails SystemName: $bad_value_ref->[$position]";
like		$@, $answer_ref->[$position++],
							"... and check for the correct error message";
explain 								"...Test Done";
done_testing();
