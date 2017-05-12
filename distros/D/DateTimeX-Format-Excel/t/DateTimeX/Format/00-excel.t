#########1 Test File for DateTimeX::Format::Excel 5#########6#########7#########8#########9
#!perl
use	Test::Most tests => 156;
use	Test::Moose;
use	Capture::Tiny qw( capture_stderr );
use	DateTime;
use	lib	'../../../lib',;
BEGIN{
	$ENV{PERL_TYPE_TINY_XS} = 0;
	#~ $ENV{ Smart_Comments } = '###';
}
if( $ENV{Smart_Comments} ){
	use Smart::Comments -ENV;
	### Smart-Comments turned on for DateTimeX-Format-Excel Test ...
}
$| = 1;
use	DateTimeX::Format::Excel;
my  (
			$test_instance, $capture, $x, @answer,
	);
my 			$row = 0;
my 			@class_attributes = qw(
				system_type
			);
my  		@instance_methods = qw(
				new
				get_system_type
				set_system_type
				parse_datetime
				format_datetime
			);
my			$question_ref = [
				1, 100, 41255, 41255.5, 61, 60, 0, 39793.5,
				DateTime->new( year => 2012, month => 12, day => 12, hour => 12 ),
			];
my			$answer_ref = [
				'1900-01-01T00:00:00',
				'1900-04-09T00:00:00',
				'2012-12-12T00:00:00',
				'2012-12-12T12:00:00',
				'1900-03-01T00:00:00',
				'1900-01-01T00:00:00',
				qr/\Q-1900-February-29- is not a real date\E/,
				qr/\Q-1900-January-0- is not a real date\E/,
				'1904-03-02T00:00:00',
				'1904-03-01T00:00:00',
				'1904-01-01T00:00:00',
				'2012-12-12T12:00:00',

				'1899-12-30T00:00:00','1899-12-31T00:00:00',1,2,3,4,5,6,7,8,9,10,11,
				12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,
				30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,
				51,52,53,54,55,56,57,58,59,61,62,63,

				'1903-12-30T00:00:00','1903-12-31T00:00:00',0,1,2,3,4,5,6,7,8,9,10,11,
				12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,
				35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,
				58,59,60,61,62,63
			];
### <where> - easy questions ...
map{
has_attribute_ok
			'DateTimeX::Format::Excel', $_,
										"Check that DateTimeX::Format::Excel has the -$_- attribute"
} 			@class_attributes;

### <where> - harder questions ...
lives_ok{
			$test_instance = DateTimeX::Format::Excel->new;
}										"Prep a new DateTimeX::Format::Excel instance";
map{
can_ok		$test_instance, $_,
} 			@instance_methods;

### <where> - hardest questions ...
			map{
is			$test_instance->parse_datetime( $question_ref->[$_] ), $answer_ref->[$_],
										"Check for correct Windows Excel date epoch parsing of: " .
										$question_ref->[$_] . " (" . $answer_ref->[$_] . ')';
			}( 0..4 );
is			$test_instance->parse_datetime( "" ), "",
										"Check for correct Windows Excel date epoch parsing of an empty string";
			map{
				$capture = capture_stderr{
is			$test_instance->parse_datetime( $question_ref->[$_] ), $answer_ref->[($_-1)],
										"Check for the correct Windows Excel date epoch when parsing: " .
										$question_ref->[$_] . ' (' . $answer_ref->[($_-1)] . ')';
				};
like		$capture, $answer_ref->[($_+1)],
										"... and check that it throws the correct error message";
			}(5..6);
lives_ok{	$test_instance->set_system_type( 'apple_excel' ) }
										"Set the system to an Apple Excel Epoch";
			map{
is			$test_instance->parse_datetime( $question_ref->[$_] ), $answer_ref->[($_+4)],
										"Check for correct Apple Excel date epoch when parsing: " .
										$question_ref->[$_] . " (" . $answer_ref->[($_+4)] . ')';
			}(4..7);
is			$test_instance->format_datetime( $question_ref->[8] ), $question_ref->[7],
										"Check for correct Apple Excel epoch generation for DateTime instance: " .
										$question_ref->[8] . " (" . $question_ref->[7] . ')';
lives_ok{	$test_instance->set_system_type( 'win_excel' ) }
										"Set the system to a Windows Excel Epoch";
is			$test_instance->format_datetime( $question_ref->[8] ), $question_ref->[3],
										"Check for correct Windows Excel epoch generation for DateTime instance: " .
										$question_ref->[8] . " (" . $question_ref->[3] . ')';
			my $date_instance = DateTime->new( year => 1899, month => 12, day => 30 );
			map{
is			$test_instance->format_datetime( $date_instance ), $answer_ref->[$_],
										"Check for correct Windows Excel epoch generation for DateTime instance: " .
										$date_instance. " (" . $answer_ref->[$_] . ')';
			$date_instance->add( days => 1 );
			}(12..75);
lives_ok{	$test_instance->set_system_type( 'apple_excel' ) }
										"Set the system to an Apple Excel Epoch";
			$date_instance = DateTime->new( year => 1903, month => 12, day => 30 );
			map{
is			$test_instance->format_datetime( $date_instance ), $answer_ref->[$_],
										"Check for correct Apple Excel epoch generation for DateTime instance: " .
										$date_instance . " (" . $answer_ref->[$_] . ')';
			$date_instance->add( days => 1 );
			}(76..141);
explain 								"...Test Done";
done_testing();
