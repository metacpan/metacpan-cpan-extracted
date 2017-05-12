package Apache::PrettyPerl;

use strict;
use warnings;
use vars qw/$VERSION/;

use Apache::Const qw/:common/;
use Apache::RequestRec;
use Apache::RequestIO;
use Apache::RequestUtil;
use Apache::Response;
use File::Basename qw/basename/;

$VERSION = '2.10';

# You can set colors here. Use HTML color names or codes
# (like #ff0000 being red).
our %Colors =
(
	foreground	=> 'silver',
	background	=> 'black',
	links		=> 'white',
	
	comment	=> 'navy',
	escaped	=> 'purple',
	keyword	=> 'yellow',
	number	=> 'red',
	pod	=> 'navy',
	regex	=> 'red',
	string	=> 'red',
	variable=> 'aqua'
);

our @KeyWords =
qw(
	while until for foreach unless if elsif else do
	package use no require import and or eq ne cmp
	abs accept alarm atan2 bind binmode bless
	caller chdir chmod chomp chop chown chr
	chroot close closedir connect continue cos
	crypt dbmclose dbmopen defined delete die
	dump each endgrent endhostent endnetent
	endprotoent endpwent endservent eof eval 
	exec exists exit exp fcntl fileno flock
	fork format formline getc getgrent getgrgid
	getgrnam gethostbyaddr gethostbyname gethostent
	getlogin getnetbyaddr getnetbyname getnetent
	getpeername getpgrp getppid getpriority
	getprotobyname getprotobynumber getprotoent
	getpwent getpwnam getpwuid getservbyname
	getservbyport getservent getsockname
	getsockopt glob gmtime goto grep hex index
	int ioctl join keys kill last lc lcfirst
	length link listen local localtime log
	lstat map map mkdir msgctl msgget msgrcv
	msgsnd my next oct open opendir ord our pack
	pipe pop pos print printf prototype push
	quotemeta rand read readdir readline
	readlink readpipe recv redo ref rename
	reset return reverse rewinddir rindex
	rmdir scalar seek seekdir select semctl
	semget semop send setgrent sethostent
	setnetent setpgrp setpriority setprotoent
	setpwent setservent setsockopt shift shmctl 
	shmget shmread shmwrite shutdown sin sleep
	socket socketpair sort splice split sprintf
	sqrt srand stat study sub substr symlink
	syscall sysopen sysread sysread sysseek
	system syswrite tell telldir tie tied
	time times truncate uc ucfirst umask undef
	unlink unpack unshift untie utime values
	vec wait waitpid wantarray warn write
);

our @Buffer = ();
our $BufferFill = 0;
our $alrm = chr (7);
our $Tabsize = 8;

sub handler
{
	my $req = shift;
	my $filename = $req->filename ();
	my $dl = 0;
	my $dl_ok = 0;
	my $data;
	my $mtime;

	if (!-e $filename)
	{
		return (NOT_FOUND);
	}

	if (!-r $filename)
	{
		return (FORBIDDEN);
	}

	$mtime = (stat ($filename))[9] or return (SERVER_ERROR);

	if ($req->dir_config ('AllowDownload'))
	{
		my $conf = lc ($req->dir_config ('AllowDownload'));

		if (($conf eq 'on') or ($conf eq 'true')
				or ($conf eq 'yes'))
		{
			$dl_ok = 1;
		}
	}

	if ($req->args ())
	{
		my %args = $req->args ();

		if (exists ($args{'download'})
				and ($dl_ok))
		{
			$req->content_type ("text/perl-script");
			$dl = 1;
		}
		else
		{
			$req->content_type ("text/html");
		}
	}
	else
	{
		$req->content_type ("text/html");
		
		if ($req->dir_config ('TabSize'))
		{
			my $tmp = $req->dir_config ('TabSize');
			$tmp =~ s/\D//g;

			if ($tmp)
			{
				$Tabsize = $tmp;
			}
		}
	}

	$req->set_last_modified ($mtime);
	$req->set_etag ();

	if ($req->header_only ())
	{
		return (OK);
	}

	$data = $req->slurp_filename ();

	if ($dl)
	{
		$req->print ($$data);
	}
	else
	{
		$req->print (get_head ($req));

		if ($dl_ok)
		{
			$req->print (get_dl_link ($req));
		}
		$req->print (perl2html ($$data));
		$req->print (get_foot ());
	}

	return (OK);
}

sub get_head
{
	my $req = shift;
	my $uri = $req->uri ();
	my $file = basename ($uri);
	my $temp;
	
	my $retval = <<EOF;
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
        "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<title>Source of $file</title>
<meta name="generator" content="Apahe::PrettyPerl" />
<style type="text/css">
<!--
EOF
	$temp = 'white';
	if (defined ($Colors{'links'}))
	{
		$temp = $Colors{'links'};
	}

	$retval .= <<EOF;
a
{
	color: $temp;
	background-color: transparent;
	text-decoration: none;
	font-weight: bold;
}

a:hover
{
	text-decoration: underline;
}

EOF

	{
		my $bg = 'black';
		my $fg = 'silver';

		if (defined ($Colors{'background'}))
		{
			$bg = $Colors{'background'};
		}
		if (defined ($Colors{'foreground'}))
		{
			$fg = $Colors{'foreground'};
		}

		$retval .= <<EOF;
body
{
	color: $fg;
	background-color: $bg;
}

div.source
{
	font-family: monospace;
	border: 1px solid gray;
	padding: 1em;
}

p.generator
{
	text-align: right;
	font-size: smaller;
}

EOF
	}

	$temp = 'navy';
	if (defined ($Colors{'comment'}))
	{
		$temp = $Colors{'comment'};
	}

	$retval .= <<EOF;
span.comment
{
	color: $temp;
	background-color: transparent;
}

span.error
{
	color: red;
	background-color: yellow;
}
EOF

	my %defaults =
	(
		escaped	=> 'purple',
		keyword	=> 'yellow',
		number	=> 'red',
		pod	=> 'navy',
		regex	=> 'red',
		string	=> 'red',
		variable=> 'aqua'
	);

	for (sort (keys (%defaults)))
	{
		$temp = $defaults{$_};

		if (defined ($Colors{$_}))
		{
			$temp = $Colors{$_};
		}

		$retval .= <<EOF;

span.$_
{
	color: $temp;
	background-color: transparent;
}
EOF
	}

	$retval .= <<EOF;
//-->
</style>
</head>
<body>
<h1>Source of <code>$file</code></h1>
EOF
	return ($retval);
}

sub get_foot
{
	my $retval = <<EOF;
<p class="generator">Generated by <a href="http://amk.lg.ua/~ra/PrettyPerl/">Apache::PrettyPerl $VERSION</a></p>

</body>
</html>
EOF
	return ($retval);
}

sub get_dl_link
{
	my $req = shift;
	my $uri = $req->uri ();
	my $file = basename ($uri);

	my $retval = qq#\n<p><a href="$uri?download">Download <code>$file</code></a></p>\n#;
	return ($retval);
}

sub html_escape
{
	$_ = shift;

	s/&/&amp;/g;
	s/>/&gt;/g;
	s/</&lt;/g;
	s/"/&quot;/g;

	s/  +/'&nbsp;' x length ($&)/ge;
	s/\t/'&nbsp;' x $Tabsize/ge;
	s#\n#<br />\n#sg;

	return ($_);
}
	

sub string2html
{
	my $string = shift;
	my $retval = '';

	$string = html_escape ($string);

	if ($string =~ m/^(&quot;|&lt;&lt;[^']|qq.)/)
	{
		$retval = $&;
		$string = $';

		while ($string =~ m/\\(?:[^&]|&[a-z]+;)|[\@\%\&]?\$*\$(?:&[a-z]+;|[^A-Za-z:]|(?:::)?[A-Za-z](?:\w|::)*)/)
		{
			my $match = $&;
			$retval .= $`;
			$string = $';

			if ($match =~ m/^[\$\@\%\&]/)
			{
				$retval .= qq#<span class="variable">$match</span>#;
			}
			else
			{
				$retval .= qq#<span class="escaped">$match</span>#;
			}
		}
		
		$retval .= $string;
		$retval = qq#<span class="string">$retval</span>#;
	}
	elsif ($string =~ m/^('|&lt;&lt;'|q[^qxr])/)
	{
		$retval = $string;
		$retval =~ s#\\[\\']#<span class="escaped">$&</span>#g;
		$retval = qq#<span class="string">$retval</span>#;
	}
	elsif ($string =~ m/^#/)
	{
		$retval = qq#<span class="comment">$string</span>#;
	}
	elsif ($string =~ m/^=/)
	{
		$retval = qq#<span class="pod">$string</span>#;
	}
	else
	{
		$retval = qq#<span class="string">$string</span>#;
	}
	
	return ($retval);
}

sub regex2html
{
	$_ = shift;
	$_ = html_escape ($_);

	s#
		\((?:\?(?:[=!:]|&lt;[=!]|&gt;))?
	|	\[\^?
	|	\\(?:\&\w+;|.)
	|	[\*\+\?\)\]\|]
	#<span class="escaped">$&</span>#gx;

	$_ = qq#<span class="regex">$_</span>#;
	
	return ($_);
}

sub perl2html
{
	my $yet_to_process = join ("\n", @_);
	my $processed = '';

	my @Buffer = ();
	$BufferFill = 0;

	$yet_to_process =~ s/$alrm//g;
	$yet_to_process =~ s/\r//g;

	while ($yet_to_process =~ m!
	(
		["'\#]				# normal strings and comments
	|	[\@\%\$\&]			# variables
	|	\b\d+\b				# numbers
	|	\b(?:m|s|y|tr)[^A-Za-z0-9\s]	# regexen
	|	[\!=]~\s*/			# regex short form
	|	q[qwxr]?[^A-Za-z0-9\s]		# more strings
	|	\w+\s*=>			# hashes
	|	<<(['"]?)\w+\2;?\n		# multi-line strings
	|	\n=\w+				# pod
	|	<\w+>				# filehandles
	)!xso)
	{
		my $match = $&;
		$processed .= $`;
		$yet_to_process = $';
	
		# normal strings
		if ($match eq '"')
		{
			if ($yet_to_process =~ m/^((?:\\.|[^"\\])*)"/s)
			{
				$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm#;
				$yet_to_process = $';

				$Buffer[$BufferFill] = qq#"$1"#;
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		elsif ($match eq "'")
		{
			if ($yet_to_process =~ m/^((?:\\'|[^'])*)'/s)
			{
				$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm#;
				$yet_to_process = $';

				$Buffer[$BufferFill] = qq#'$1'#;
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		# comments
		elsif ($match eq '#')
		{
			if ($yet_to_process =~ m/.*/m)
			{
				$processed .= qq#$alrm!COMMENT!$alrm$BufferFill$alrm#;
				$yet_to_process = $';

				$Buffer[$BufferFill] = '#' . $&;
				$BufferFill++;
			}
			else
			{
				die 'You should NEVER get here!';
			}
		}
		# variables
		elsif ($match =~ m/^[\@\%\$\&]/)
		{
			if (($match eq '&') and ($yet_to_process =~ m/^\&/))
			{
				$processed .= '&&';
				$yet_to_process = $';
			}
			elsif ($yet_to_process =~ m#\$*(?:[^A-Za-z:\s]|(?:::)?[A-Za-z](?:\w|::)*)#)
			{
				$processed .= qq#$alrm!VARIABLE!$alrm$BufferFill$alrm#;
				$yet_to_process = $';

				$Buffer[$BufferFill] = $match . $&;
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		# numbers
		elsif ($match =~ m/^\d+$/)
		{
			$processed .= qq#$alrm!NUMBER!$alrm$BufferFill$alrm#;
			
			$Buffer[$BufferFill] = $match;
			$BufferFill++;
		}
			
		# other strings
		elsif ($match =~ m/^(q[qwxr]?)(.)/)
		{
			my $type = $1;
			my $delim = $2;
			$delim =~ tr/([{</)]}>/;
			$delim = quotemeta ($delim);

			my $tmp = "^((?:\\\\$delim|[^$delim])*)($delim)";

			if ($yet_to_process =~ m/$tmp/s)
			{
				$yet_to_process = $';

				if ($type eq 'qr')
				{
					$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $match;
					$BufferFill++;

					$processed .= qq#$alrm!REGEX!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $1;
					$BufferFill++;

					$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $2;
					$BufferFill++;
				}
				else
				{
					$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $match . $&;
					$BufferFill++;
				}
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		elsif ($match =~ m/^<<(['"]?)(\w+)/)
		{
			my $type = $1;
			my $delim = $2;
			
			if ($yet_to_process =~ m/(.*?\n$delim)([\$\n])/s)
			{
				$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm#;
				$yet_to_process = $2 . $';

				$Buffer[$BufferFill] = $match . $1;
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		elsif ($match =~ m#^(?:[=!]~\s*/|m[^A-Za-z0-9\s])#s)
		{
			my $delim;

			if ($match =~ m#^([=!]~\s*)/#)
			{
				$processed .= $1;
				$delim = '/';
			}
			elsif ($match =~ m/^m(.)/)
			{
				$delim = $1;
			}
			else
			{
				die 'You should NEVER get here!';
			}

			$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
			$Buffer[$BufferFill] = $match;
			$BufferFill++;

			$delim =~ tr/([{</)]}>/;

			
			$delim = quotemeta ($delim);

			my $tmp = "^((?:\\\\$delim|[^$delim])*)($delim" . '[gcimosx]*)';

			if ($yet_to_process =~ m/$tmp/s)
			{
				$yet_to_process = $';
				$processed .= qq#$alrm!REGEX!$alrm$BufferFill$alrm#;
				$Buffer[$BufferFill] = $1;
				$BufferFill++;

				$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
				$Buffer[$BufferFill] = $2;
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		elsif ($match =~ m#^(?:s|y|tr)([^A-Za-z0-9\s])#)
		{
			my $delim = $1;
			$delim =~ tr/([{</)]}>/;
			$delim = quotemeta ($delim);

			$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
			$Buffer[$BufferFill] = $match;
			$BufferFill++;

			my $tmp = "^((?:\\\\$delim|[^$delim])*)($delim)";

			if ($yet_to_process =~ m/$tmp/s)
			{
				$yet_to_process = $';
				$processed .= qq#$alrm!REGEX!$alrm$BufferFill$alrm#;
				$Buffer[$BufferFill] = $1;
				$BufferFill++;

				$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
				$Buffer[$BufferFill] = $2;

				$tmp = '^';

				if ($delim =~ m/^[\)\]\}>]$/)
				{
					if ($yet_to_process =~ m/[\(\[\{<]/)
					{
						$Buffer[$BufferFill] .= $&;

						$tmp .= quotemeta ($&);
						$delim = $&;
						$delim =~ tr/([{</)]}>/;
						$delim = quotemeta ($delim);
					}
					else
					{
						$delim = '';
					}
				}
				$BufferFill++;

				$tmp .= "((?:\\\\$delim|[^$delim])*)($delim" . '[egimosx]*)';

				if ($delim and ($yet_to_process =~ m/$tmp/s))
				{
					$yet_to_process = $';
					$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $1;
					$BufferFill++;

					$processed .= qq#$alrm!KEYWORD!$alrm$BufferFill$alrm#;
					$Buffer[$BufferFill] = $2;
					$BufferFill++;
				}
				else
				{
					# No warning here..
				}
			}
			else
			{
				$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = qq#$match#;
				$BufferFill++;
			}
		}
		# pod
		elsif ($match =~ m#\n=(.*)#m)
		{
			my $type = $1;
			if ($yet_to_process =~ m/(.*?)\n=cut\n/s)
			{
				$processed .= qq#\n$alrm!POD!$alrm$BufferFill$alrm\n#;
				$yet_to_process = $';

				$Buffer[$BufferFill] = "=$type\n$1";
				$BufferFill++;
			}
			else
			{
				$processed .= qq#$alrm!POD!$alrm$BufferFill$alrm#;

				$Buffer[$BufferFill] = $match . $yet_to_process;
				$BufferFill++;

				$yet_to_process = '';
			}
		}
		elsif ($match =~ m/^(\w+)(\s*=>)$/)
		{
			$processed .= qq#$alrm!STRING!$alrm$BufferFill$alrm# . $2;

			$Buffer[$BufferFill] = $1;
			$BufferFill++;
		}
		elsif ($match =~ m#<\w+>#)
		{
			$processed .= qq#$alrm!FILEHANDLE!$alrm$BufferFill$alrm#;
			$Buffer[$BufferFill] = $&;
			$BufferFill++;
		}
		else
		{
			$processed .= qq#$alrm!ERROR!$alrm$BufferFill$alrm#;

			$Buffer[$BufferFill] = qq#$match#;
			$BufferFill++;
		}
	}

	$_ = html_escape ($processed . $yet_to_process);

	my $re;
	{
		my $temp = '';
		$temp = join ('|', map { quotemeta ($_) } (@KeyWords));

		$re = qr#$temp#;
	}

	s#\b($re)\b#<span class="keyword">$1</span>#g;
	
	s#$alrm!STRING!$alrm(\d+)$alrm#string2html ($Buffer[$1])#ge;
	s#$alrm!REGEX!$alrm(\d+)$alrm#regex2html ($Buffer[$1])#ge;
	s#$alrm!(\w+)!$alrm(\d+)$alrm#"<span class=\"\L$1\E\">" . html_escape ($Buffer[$2]) . '</span>'#ge;

	return (qq#\n<div class="source">\n$_</div>\n#);
}

__END__

=head1 NAME

B<Apache::PrettyPerl> - Apache mod_perl PerlHandler for nicer output perl files in the client's browser.

=head1 DESCRIPTION

This is an B<Apache2> B<mod_perl2>-handler that converts perl files on the fly
into syntax highlighted HTML. So your perl scripts/modules will be look nicer.
Also possibly download original perl file (without syntax highlight). 

If you want to use B<Apache1> (and B<mod_perl1>) you need to get
B<Apache::PrettyPerl 2.00>.

=head1 SYNOPSIS

You must be using mod_perl. See http://perl.apache.org/ for details.
For the correct work your apache configuration would contain 
apache directives look like these:

  # in httpd.conf (or any other apache configuration file)
  
  <Files ~ "\.p[lm]$">
    SetHandler		perl-script
    PerlHandler		Apache::PrettyPerl

    # Below here is optional
    PerlSetVar		TabSize 	8
    PerlSetVar		AllowDownload	On
  </Files>

This is only an example of an apache configuration. Most probably you
should place the I<E<lt>FilesE<gt>> directive inside a I<E<lt>DirectoryE<gt>>
directive. Otherwise will be handled all perl files, including CGI and
mod_perl scripts.

=head1 CONFIGURATION DIRECTIVES

All features of the this PerlHandler, will be setting in the
apache confihuration files. For this you can use PerlSetVar
apache directive. For example:

    PerlSetVar	TabSize	8   # inside <Files>, <Location>, ...
			    # apache directives

=over 4

=item TabSize

Setting size of the tab (\t) symbol. Default is 8.

=item AllowDownload

If set to ``on'' a download link will be displayed which allows the
unmodified file to be downloaded. Defaults to ``off''.

=back

=head1 SEE ALSO

L<perl(1)>, L<mod_perl(3)>, L<Apache(3)>

=head1 AUTHORS

Roman Kosenko, Florian octo Forster

=head2 Contact info

  Roman Kosenko:   ra(at)amk.lg.ua
  Florian Forster: octo(at)verplant.org

  Home page: http://amk.lg.ua/~ra/PrettyPerl/

=head2 Copyright

Copyright (c) 2000 Roman Kosenko.
Copyright (c) 2004, 2005 Florian Forster.
All rights reserved.  This package is free software; you can redistribute it
	and/or modify it under the same terms as Perl itself.
