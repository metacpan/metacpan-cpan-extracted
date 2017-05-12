#!/usr/bin/perl -w
$| = 1;
use ExtUtils::testlib;

use CGI::AppToolkit;
use strict;

BEGIN {
	print "1..72\n";
}

my $V = 1;

sub compare {
	my $num = shift;
	my $value = shift;
	my $should_be = shift;
	
	my ($filename, $line) = (caller)[1,2];
	
	if ($value eq $should_be) {
		print "'$value'\n" if $V > 1;
		print "ok $num Line: " . $line . "\n";
	} else {
		print "'$value'\nshould be: '$should_be'\n\tat line: $line of file '$filename'\n" if $V;
		print "not ok $num\n";
	}
}

local $^W = 0;

my $T = 1;

my $kit = CGI::AppToolkit->new();

#test text and token 
{
	my $temp = $kit->template(-set => 'Token: {?$token?}');
	compare($T++, $temp->make({'token' => 'token'}), 'Token: token');
}

#test text and token 
{
	my $temp = $kit->template(-set => 'Token: {?$token?}');
	compare($T++, $temp->make({'token' => undef}), 'Token: ');
}

#test text and decision node 
{
	my $temp = $kit->template(-set => 'Decision: {?if $token --?}YES{?-- $token ?}');
	compare($T++, $temp->make({'token' => '01'}),  'Decision: YES');
	compare($T++, $temp->make({'token' => 01}),    'Decision: YES');
	compare($T++, $temp->make({'token' => '0x1'}), 'Decision: YES');
	compare($T++, $temp->make({'token' => undef}), 'Decision: ');
	compare($T++, $temp->make({'token' => ''}),    'Decision: ');
	compare($T++, $temp->make({'token' => '0'}),   'Decision: ');
	compare($T++, $temp->make({'token' => 0}),     'Decision: ');
}

{
	my $temp = $kit->template(-set => 'Decision elsif: {?if $token --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++,  $temp->make({'token' => '01'}),  'Decision elsif: YES');
	compare($T++, $temp->make({'token' => 01}),    'Decision elsif: YES');
	compare($T++, $temp->make({'token' => '0x1'}), 'Decision elsif: YES');
	compare($T++, $temp->make({'token' => undef}), 'Decision elsif: NO');
	compare($T++, $temp->make({'token' => ''}),    'Decision elsif: NO');
	compare($T++, $temp->make({'token' => '0'}),   'Decision elsif: NO');
	compare($T++, $temp->make({'token' => 0}),     'Decision elsif: NO');
}

{
	my $temp = $kit->template(-set => 'Decision eq: {?if $token=1 --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => '01'}),  'Decision eq: YES');
	compare($T++, $temp->make({'token' => 01}),    'Decision eq: YES');
	compare($T++, $temp->make({'token' => '1x1'}), 'Decision eq: YES');
	compare($T++, $temp->make({'token' => undef}), 'Decision eq: NO');
	compare($T++, $temp->make({'token' => '100'}), 'Decision eq: NO');
	compare($T++, $temp->make({'token' => '0x1'}), 'Decision eq: NO');
	compare($T++, $temp->make({'token' => 0}),     'Decision eq: NO');
}

{
	my $temp = $kit->template(-set => 'Decision string eq: {?if $token=\'string\' --?}YES{?-- $token --?}NO{?-- $token ?}');
	my $string = 'string';
	compare($T++, $temp->make({'token' => 'string'}),   'Decision string eq: YES');
	compare($T++, $temp->make({'token' => $string}),    'Decision string eq: YES');
	compare($T++, $temp->make({'token' => undef}),      'Decision string eq: NO');
	compare($T++, $temp->make({'token' => '100'}),      'Decision string eq: NO');
	compare($T++, $temp->make({'token' => 'strin'}),    'Decision string eq: NO');
	compare($T++, $temp->make({'token' => 'string\n'}), 'Decision string eq: NO');
}

{
	my $temp = $kit->template(-set => 'Decision string not eq: {?if !$token="string" --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 'string'}),   'Decision string not eq: NO');
	compare($T++, $temp->make({'token' => '100'}),      'Decision string not eq: YES');
}

{
	my $temp = $kit->template(-set => 'Decision not eq: {?if !$token=1 --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1}), 'Decision not eq: NO');
	compare($T++, $temp->make({'token' => 0}), 'Decision not eq: YES');
}

{
	my $temp = $kit->template(-set => 'Decision string not eq2: {?if $token!="string" --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 'string'}),   'Decision string not eq2: NO');
	compare($T++, $temp->make({'token' => '100'}),      'Decision string not eq2: YES');
}

{
	my $temp = $kit->template(-set => 'Decision not eq2: {?if $token!=1 --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1}), 'Decision not eq2: NO');
	compare($T++, $temp->make({'token' => 0}), 'Decision not eq2: YES');
}

{
	my $temp = $kit->template(-set => 'Decision string not eq3: {?if !$token!="string" --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 'string'}),   'Decision string not eq3: YES');
	compare($T++, $temp->make({'token' => '100'}),      'Decision string not eq3: NO');
}

{
	my $temp = $kit->template(-set => 'Decision not eq3: {?if !$token!=1 --?}YES{?-- $token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1}), 'Decision not eq3: YES');
	compare($T++, $temp->make({'token' => 0}), 'Decision not eq3: NO');
}

{
	my $temp = $kit->template(-set => 'Decision not eq3: {?if !$token!=1 --?}{?if $token2 --?}YES{?-- $token2 ?}{?-- $token --?}{?if $token2 --?}NO{?-- $token2 ?}{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1, 'token2' => 1}), 'Decision not eq3: YES');
	compare($T++, $temp->make({'token' => 0, 'token2' => 1}), 'Decision not eq3: NO');
}

{
	my $temp = $kit->template(-set => 'test: {?if !$token!=1 --?}YES{?-- $toke2n --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at line 1: {?-- $toke2n --?} out of order');
}

{
	my $temp = $kit->template(-set => 'test: {?if !$token!=1 --?}YES{?-- @token --?}NO{?-- $token ?}');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at line 1: {?-- @token --?} out of order');
}

{
	my $temp = $kit->template(-set => 'test: {?if !$token!=1 --?}YES{?-- $token --?}NO{?-- $toke2n ?}');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at line 1: {?-- $toke2n ?} out of order');
}

{
	my $temp = $kit->template(-set => 'test: {?if !$token!=1 --?}YES{?-- $token --?}NO');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at end of file: missing {?-- $token ?} or </iftoken>');
}

{
	my $temp = $kit->template(-set => 'test: {?@token --?}YES{?-- $token --?}NO');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at line 1: {?-- $token --?} out of order');
}

{
	my $temp = $kit->template(-set => 'test: {?@token --?}YES{?-- @token --?}NO');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at end of file: missing {?-- @token ?} or </repeattoken>');
}

{
	my $temp = $kit->template(-set => 'test: <repeattoken token>YES<else>NO');
	compare($T++, $temp->make({'token' => 1}), '');
	compare($T++, $temp->get_error(), 'Malformed template at end of file: missing {?-- @token ?} or </repeattoken>');
}

{
	my $temp = $kit->template(-set => <<'END_TEST');
This line repeats: {?@r?}{?$num?}{?@z?}.
END_TEST

	compare($T++, $temp->get_error(), 'Malformed template at line 1: multiple {?@z?} style tokens on the same line');
}

{
	my $temp = $kit->template(-set => <<'END_TEST');
{?if $yes --?}
This line repeats: {?@r?}{?$num?}{?-- $yes --?}.
{?-- $yes?}
END_TEST

	compare($T++, $temp->get_error(), 'Malformed template at line 2: {?-- $yes --?} out of order');
}

{
	my $temp = $kit->template(-set => <<'END_TEST');
{?if $yes --?}
This line repeats: {?@r?}{?$num?}{?-- $yes?}.
END_TEST

	compare($T++, $temp->get_error(), 'Malformed template at line 2: {?-- $yes ?} out of order');
}

{
require CGI::AppToolkit::Template::Filter::BR;
require CGI::AppToolkit::Template::Filter::HTML;
require CGI::AppToolkit::Template::Filter::URL;

	my $temp = $kit->template(-set => <<'END_TEST');
This is a full test: '{?$title HTML(-1.345, '2', 'this\'s it', whatever you want, "Words with \"it\"")?}'.
This is a full test: '{?$title BR()?}'.
This is a full test: '{?$title URL?}'.
\{?$title?}
This \line \repeats: {?$_z?}{?@r?}. {?if $yes --?}Yes{?-- $yes --?}No{?-- $yes?} {?if $_odd --?}odd{?-- $_odd?}{?if $_even --?}even{?-- $_even?} {?$_x?}
This should say Yes: {?if $yes --?}Yes{?-- $yes --?}No{?-- $yes?}.
This should say No: {?if !$yes --?}Yes{?-- $yes --?}No{?-- $yes?}.
{?my $t --?}abc{?-- $t?}{?my $z="abc"?}
END_TEST

warn $temp->get_error() if $temp->get_error();

	my $should_be = <<'END_SHOULDBE';
This is a full test: '&lt;b&gt;Hello All!&lt;/b&gt;
'.
This is a full test: '<b>Hello All!</b><br>
'.
This is a full test: '%3Cb%3EHello%20All%21%3C%2Fb%3E%0A'.
{?$title?}
This line repeats: 1. No even 0
This line repeats: 2. Yes odd 1
This line repeats: 3. No even 2
This line repeats: 4. Yes odd 3
This line repeats: 5. No even 4
This line repeats: 6. Yes odd 5
This should say Yes: Yes.
This should say No: No.

END_SHOULDBE

	compare($T++, $temp->make({
			'title' => "<b>Hello All!</b>\n",
			'num'		=> "This shouldn't show up!",
			'r' 		=> [
					{'yes'	=> 0},
					{'no'		=> 1},
					{'yes'	=> 0},
					{'no'		=> 1},
					{'yes'	=> 0},
					{'no'		=> 1},
				],
			'yes' => 1,
		}), $should_be);
	compare($T++, $temp->vars('t'), 'abc');
	compare($T++, $temp->vars('z'), 'abc');
}

{
	my $temp = $kit->template(-set => <<'END_TEST');
This is a full test: '<token name="name" do="HTML(-1.345, '2', 'this\'s it', whatever you want, "Words with \"it\"")">'.
This is a full test: '<token name BR()>'.
This is a full test: '<token name do="BR">'.
\{?$title?} \\escape
This \line \repeats: {?$_z?}<repeattoken name="r"/>. {?if $yes --?}Yes{?-- $yes --?}No{?-- $yes?} {?if $_odd --?}odd{?-- $_odd?}{?if $_even --?}even{?-- $_even?} <token name="_x">
This should say Yes: {?if $yes --?}Yes{?-- $yes --?}No{?-- $yes?}.
This should say No: {?if !$yes --?}Yes{?-- $yes --?}No{?-- $yes?}.
This should say Yes: {?if $num=12 --?}Yes{?-- $num --?}No{?-- $num?}.
This should say Yes: {?if $num>11 --?}Yes{?-- $num --?}No{?-- $num?}.
This should say Yes: {?if $num>=11 --?}Yes{?-- $num --?}No{?-- $num?}.
This should say Yes: {?if $num<=13 --?}Yes{?-- $num --?}No{?-- $num?}.
This should say Yes: {?if $num<13 --?}Yes{?-- $num --?}No{?-- $num?}.

This should say Yes: <iftoken name="yes">Yes<else>No</iftoken>.
This should say No: <iftoken name="yes" comparison=not>Yes<else>No</iftoken>.
This should say Yes: <iftoken name="num" value=13 comparison="lt">Yes<else>No</iftoken>.
This should say Yes: <iftoken name="num" comparison=gt value="11">Yes<else>No</iftoken>.
This should say Yes: <iftoken name="num" value=11 comparison="ge">Yes<else>No</iftoken>.
This should say Yes: <iftoken name="num" value="13" comparison=le>Yes<else>No</iftoken>.
This should say Yes: <iftoken comparison=lt value=13 name=num>Yes<else>No</iftoken>.
{?my $t --?}abc{?-- $t?}{?my $z="abc"?}
END_TEST

warn $temp->get_error() if $temp->get_error();

	my $should_be = <<'END_SHOULDBE';
This is a full test: 'Hello All!
'.
This is a full test: 'Hello All!<br>
'.
This is a full test: 'Hello All!<br>
'.
{?$title?} \escape
This line repeats: 1. No even 0
This line repeats: 2. Yes odd 1
This line repeats: 3. No even 2
This line repeats: 4. Yes odd 3
This line repeats: 5. No even 4
This line repeats: 6. Yes odd 5
This should say Yes: Yes.
This should say No: No.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.

This should say Yes: Yes.
This should say No: No.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.
This should say Yes: Yes.

END_SHOULDBE

	compare($T++, $temp->make({
			'name' => "Hello All!\n",
			'num'		=> "This shouldn't show up!",
			'r' 		=> [
					{'yes'	=> 0},
					{'no'		=> 1},
					{'yes'	=> 0},
					{'no'		=> 1},
					{'yes'	=> 0},
					{'no'		=> 1},
				],
			'yes' => 1,
			'num' => 12,
		}), $should_be);
	compare($T++, $temp->vars('t'), 'abc');
	compare($T++, $temp->vars('z'), 'abc');
}

{
	$kit->template->set_path(qw(./t/templates));
	my $temp = $kit->template('test1.tmpl');

warn $temp->get_error() if $temp->get_error();
	
	my $should_be = '';
	{
		open TEMPL, './t/templates/test1.tmpl.out' || die "Cannot open './t/templates/test1.tmpl.out': $!\n";
		local $/ = undef;
		$should_be = <TEMPL>;
		close TEMPL;
	}

	compare($T++, $temp->make({
			'title'	=> 'Hello All!',
			'test'	=> "z",
			'select' 		=> [
					{'name' => 'A', 'value' => 'a'},
					{'name' => 'B', 'value' => 'b'},
					{'name' => 'C', 'value' => 'c'},
					{'name' => 'D', 'value' => 'd'},
					{'name' => 'E', 'value' => 'e'},
					{'name' => 'F', 'value' => 'f'},
					{'name' => 'G', 'value' => 'g'},
					{'name' => 'H', 'value' => 'h'},
					{'name' => 'I', 'value' => 'i'},
					{'name' => 'J', 'value' => 'j'},
					{'name' => 'K', 'value' => 'k'},
					{'name' => 'L', 'value' => 'l'},
					{'name' => 'M', 'value' => 'm'},
					{'name' => 'N', 'value' => 'n'},
					{'name' => 'O', 'value' => 'o'},
					{'name' => 'P', 'value' => 'p'},
					{'name' => 'Q', 'value' => 'q'},
					{'name' => 'R', 'value' => 'r'},
					{'name' => 'S', 'value' => 's'},
					{'name' => 'T', 'value' => 't'},
					{'name' => 'U', 'value' => 'u'},
					{'name' => 'V', 'value' => 'v'},
					{'name' => 'W', 'value' => 'w'},
					{'name' => 'X', 'value' => 'x'},
					{'name' => 'Y', 'value' => 'y'},
					{'name' => 'Z', 'value' => 'z'},
				],
			't1'		=> 1,
			't2'		=> 1,
			't3'		=> 1,
			't4'		=> 1,
			't5'		=> 1,
			't6'		=> 1,
			't7'		=> 1,
			't8'		=> 1,
			't9'		=> 1,
			't10'		=> 1,
			'num'		=> "This shouldn't show up!",
			'r' 		=> [
					{'num' => 1, 'yes' => 0},
					{'num' => 2},
					{'num' => 3, 'yes' => 0},
					{'num' => 4},
					{'num' => 5, 'yes' => 0},
					{'num' => 6},
				],
			'yes' => 1,
		}), $should_be);
	
	open TMPL2, '>>./t/test1.tmpl.out2' || die "Error: $!";
	print TMPL2 $temp->make({
			'title'	=> 'Hello All!',
			'test'	=> "z",
			'select' 		=> [
					{'name' => 'A', 'value' => 'a'},
					{'name' => 'B', 'value' => 'b'},
					{'name' => 'C', 'value' => 'c'},
					{'name' => 'D', 'value' => 'd'},
					{'name' => 'E', 'value' => 'e'},
					{'name' => 'F', 'value' => 'f'},
					{'name' => 'G', 'value' => 'g'},
					{'name' => 'H', 'value' => 'h'},
					{'name' => 'I', 'value' => 'i'},
					{'name' => 'J', 'value' => 'j'},
					{'name' => 'K', 'value' => 'k'},
					{'name' => 'L', 'value' => 'l'},
					{'name' => 'M', 'value' => 'm'},
					{'name' => 'N', 'value' => 'n'},
					{'name' => 'O', 'value' => 'o'},
					{'name' => 'P', 'value' => 'p'},
					{'name' => 'Q', 'value' => 'q'},
					{'name' => 'R', 'value' => 'r'},
					{'name' => 'S', 'value' => 's'},
					{'name' => 'T', 'value' => 't'},
					{'name' => 'U', 'value' => 'u'},
					{'name' => 'V', 'value' => 'v'},
					{'name' => 'W', 'value' => 'w'},
					{'name' => 'X', 'value' => 'x'},
					{'name' => 'Y', 'value' => 'y'},
					{'name' => 'Z', 'value' => 'z'},
				],
			't1'		=> 1,
			't2'		=> 1,
			't3'		=> 1,
			't4'		=> 1,
			't5'		=> 1,
			't6'		=> 1,
			't7'		=> 1,
			't8'		=> 1,
			't9'		=> 1,
			't10'		=> 1,
			'num'		=> "This shouldn't show up!",
			'r' 		=> [
					{'num' => 1, 'yes' => 0},
					{'num' => 2},
					{'num' => 3, 'yes' => 0},
					{'num' => 4},
					{'num' => 5, 'yes' => 0},
					{'num' => 6},
				],
			'yes' => 1,
		});
	close TMPL2;
	
	compare($T++, $temp->vars('t'), 'abc');
	compare($T++, $temp->vars('z'), 'abc');
	compare($T++, $temp->vars('vt'), 'vartoken test');
	compare($T++, $temp->vars('vt2'), 'vartoken test 2');
}

{

#<token brtest do="BR('{p}')"> segfaults!

	my $temp = $kit->template(-set => <<'END_TEST');
<token name='brtest' do='BR'>
<token name=brtest do="BR('<p>')">
{? $abstest Abs() ?} {? $abstest Abs(1) ?}
{?$htmltest HTML()?}
{?$urltest URL()?} {?$urltest URL("1")?}
END_TEST

warn $temp->get_error() if $temp->get_error();

	my $should_be = <<'END_SHOULDBE';
Hello All!<br>
How's it going?<br>

Hello All!<p>
How's it going?<p>

12 -12
CGI::AppToolkit-&gt;new(name =&gt; &quot;hello&quot;)
abc%3Ddef%20ghi%20jkl%5Cn abc%3Ddef+ghi+jkl%5Cn
END_SHOULDBE

	compare($T++, $temp->make({
			'brtest'		=> "Hello All!\nHow's it going?\n",
			'abstest'		=> -12,
			'moneytest'	=> -12345.678901,
			'htmltest'	=> 'CGI::AppToolkit->new(name => "hello")',
			'urltest'		=> 'abc=def ghi jkl\n',
		}), $should_be);
}
