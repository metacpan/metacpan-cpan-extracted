
# Copyright (C) 1996, David Muir Sharnoff

#
# This is not a package.  
#
# use require to get at it if you have to.
#

use vars qw($mailserver);

sub bigdeath
{
	my ($perlerr, $syserr, $bomb, $out, 
		$envr, $query, $pwd, $zero, 
		$argvr, $debug, $mailto) = @_;

	local $SIG{__DIE__} = undef;
	my $cout = $out;
	$cout =~ s/\</&lt;/g;
	$cout =~ s/\>/&gt;/g;

	$mailto = getpwuid($<)
		unless $mailto;

	print <<"";
Content-type: text/html
\n
		<html>
		<head>
		<title>Error!</title>
		</head>
		<body>
		The dynamic web page that you just tried to
		access has failed.  The exact error that it 
		failed with was:
		<xmp>
		$bomb
		</xmp>
		In addition the following may be of interest:
		<xmp>
		\$\@ = $perlerr
		\$! = $syserr
		</xmp>
		There is probably no need to report this error because 
		email has been sent to $mailto with the information below.
		<p>
		Had this CGI run completion, the following 
		would have been output (collected so far):
		<ul>
		<pre><tt>
$cout
		</tt></pre>
		</ul>


	require Net::SMTP;
	my $smtp = Net::SMTP->new($mailserver || 'localhost');

	$smtp->mail($mailto);
	$smtp->to($mailto);
	$smtp->data();

	my $remoteuser = $ENV{'REMOTE_USER'} || 'unknown';
	my $remotehost = $ENV{'REMOTE_ADDR'} || 'unknown';

	$0 =~ m'([^/]+)$';
	my $sn = $1 || $0;

	$smtp->datasend(<<"");
To: $mailto
From: $remoteuser\@$remotehost
Subject: Perl script $sn bombed
\n
Perl script $0 bombed.
\n
Bomb code:
$bomb
\n
\$\@ = $perlerr
\$! = $syserr
\n
Debugging info:
$debug
\n

	my $qs = '';
	if (defined $query) {
		if ($envr->{'REQUEST_METHOD'} =~ /^P/) {
			$qs = $query->query_string();
		}
	}

	my $e ='';
	for (keys %e) {
		my $x = $_;
		my $y = $envr->{$x};
		$x =~ s/'/'"'"'/g;
		$y =~ s/'/'"'"'/g;
		$e .= "\\\n\t'$x'='$y'";
	}
	for ($qs, @$argvr, $zero, $pwd) {
		s/'/'"'"'/g;
	}
	my $ne;


	my $x = '';

	if (defined $query) {
		$x .= "CGI variables:\n\n";

		my $name;
		for $name ($query->param()) {
			my @values = $query->param($name);

			if (@values > 1) {
				$x .= "\t$name\n";	
				my $v;
				for $v (@values) {
					$x .= display_value($smtp, $v, "\n");
				}
			} else {	
				$x .= "\t" . $name . display_value($smtp, $values[0]);
			}
		}
	}

	$x .= <<"";
\n
Repeat with:
\n
/bin/sh <<'END'
#!/bin/sh
cd '$pwd'
echo '$qs' | env - $e $zero @$argvr 
exit $?
'END'
\n



	$smtp->datasend($x);
	$smtp->datasend("\n\noutput so far:\n$out\n");
	$smtp->dataend();
	$smtp->quit();
	print "<xmp>$x</xmp></body></html>\n";

	sub display_value
	{
		my($smtp, $value, $nl) = @_;
		my @lines;
		my $x = '';

		@lines = split("\n", $value);

		for (@lines) {
			s/\r$//;
			s/\r/\\r/g;
			s/\f/\\f/g;
			s/([\0-\37\177-\200])/sprintf("\\x%02x",ord($1))/eg;
		}

		if (@lines > 1) {
			$smtp->datasend("$nl\t\t---- begin\n");
			my $line;
			for $line (@lines) {
				$x .= "\t$line\n";
			}
			$x .= "\t\t----- end\n";
		} else {
			$x .= "$nl\t\t'$lines[0]'\n";
		}
		return $x;
	}

}

1;

