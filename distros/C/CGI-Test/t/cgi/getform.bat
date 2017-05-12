@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15

use CGI qw/:standard :no_xhtml/;

local $CGI::LIST_CONTEXT_WARN = 0;

my $content = '';

my $method = param("method") || request_method();
my $action = param("action") || url();

$content .= start_html("$method form");
$content .= h1("$method form");
$content .= start_form(
	-action  => $action,
	-method  => $method eq "POST" ? "POST" : "GET",
	-enctype => param("enctype") eq "M" ?
			"multipart/form-data" : "application/x-www-form-urlencoded",
);

my $counter = param("counter") + 1;
param("counter", $counter);

$content .= hidden("counter");
$content .= hidden("enctype");

$content .= "Title: " . radio_group(
	-name		=> "title",
	-values		=> [qw(Mr Ms Miss)],
	-default	=> 'Mr'
) . br;

$content .= "Name: " . textfield("name") . br;

$content .= "Skills: " . checkbox_group(
	-name		=> "skills",
	-values		=> [qw(cooking drawing teaching listening)],
	-defaults	=> ['listening'],
) . br;

$content .= "New here: " . checkbox(
	-name		=> "new",
	-checked	=> 1,
	-value		=> "ON",
	-label		=> "click me",
) . br;

$content .= "Color: " . popup_menu(
	-name		=> "color",
	-values		=> [qw(white black green red blue)],
	-default	=> "white",
) . br;

$content .= "Note: " . textarea("note") . br;

$content .= "Prefers: " . scrolling_list(
	-name		=> "months",
	-values		=> [qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)],
	-size		=> 5,
	-multiple	=> 1,
	-default	=> [qw(Jul)],
) . br;

$content .= "Password: " . password_field(
	-name		=> "passwd",
	-size		=> 10,
	-maxlength	=> 15,
) . br;

$content .= "Portrait: " . filefield(
	-name		=> "portrait",
	-size		=> 30,
	-maxlength	=> 80,
) . br;

$content .= p(
	reset(),
	defaults("default"),
	submit("Send"),
	image_button(
		-name	=> "img_send",
		-alt	=> "GO!",
		-src	=> "go.png",
		-width	=> 50,
		-height	=> 30,
		-border	=> 0,
	),
);

$content .= end_form;
$content .= end_html;

print header(
    -Content_Length => length $content,
);

print $content;

__END__
:endofperl
