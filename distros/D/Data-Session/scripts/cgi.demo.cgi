#!/usr/bin/perl

use CGI;

use Data::Session;

use File::Spec;

# ----------------------------------------------

sub generate_html
{
	my($name, $id, $count) = @_;
	$id        ||= '';
	my($title) = "CGI demo for Data::Session";
	return     <<EOS;
<html>
<head><title>$title</title></head>
<body>
	Number of times this script has been run: $count.<br/>
	Current value of $name: $id.<br/>
	<form id='sample' method='post' name='sample'>
	<button id='submit'>Click to submit</button>
	<input type='hidden' name='$name' id='$name' value='$id' />
	</form>
</body>
</html>
EOS

} # End of generate_html.

# ----------------------------------------------

my($q)        = CGI -> new;
my($name)     = 'sid'; # CGI form field name.
my($sid)      = $q -> param($name);
my($dir_name) = '/tmp';
my($type)     = 'driver:File;id:MD5;serialize:JSON';
my($session)  = Data::Session -> new
(
	directory => $dir_name,
	name      => $name,
	query     => $q,
	type      => $type,
);
my($id) = $session -> id;

# First entry ever?

my($count);

if ($sid) # Not $id, which always has a value...
{
	# No. The CGI form field called sid has a (true) value.
	# So, this is the code for the second and subsequent entries.
	# Count the # of times this CGI script has been run.

	$count = $session -> param('count') + 1;
}
else
{
	# Yes. There is no CGI form field called sid (with a true value).
	# So, this is the code for the first entry ever.
	# Count the # of times this CGI script has been run.

	$count = 0;
}

$session -> param(count => $count);

print $q -> header, generate_html($name, $id, $count);

# Calling flush() is good practice, rather than hoping 'things just work'.
# In a persistent environment, this call is mandatory...
# But you knew that, because you'd read the docs, right?

$session -> flush;
