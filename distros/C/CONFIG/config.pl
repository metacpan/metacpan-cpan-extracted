#! /usr/bin/perl  

#####################################################################
# config.pl
# Copyright (c) 1999,2000 by Markus Winand        <mws@fatalmind.com>
#
# Administrative tool for configuring/debuging CONFIG:: related
# problems
#
# $Id: config.pl,v 1.2 2000/04/12 20:44:05 mws Exp $
#

use strict;
use CONFIG::Plain;
use CONFIG::Hash;
use CGI;
use English;
use Cwd;
use HTML::Entities;

#####################################################################
# MODE
#     LIST (or no CGI parameter)
#         -> make a list of open configs
#     INFO 
#         -> shows the fileinfo (filename in FILE)
#     ERROR
#         -> shows the errors in FILE
#     SHOW
#         -> displays the file FILE (with includes)
#     LINE
#         -> shows a input line (FILE/LINE) and all errors in this line) 
#     OPEN
#         -> opens a new file
#     CLOSE
#         -> deletes a caches file
my $query = CGI->new;
my $mode;

print $query->header;
print("<HTML><HEAD><TITLE>CONFIG::</TITLE></HEAD>\n".
      	"<BODY BGCOLOR=\"WHITE\">".
	"<TABLE WIDTH=100%> <TR>".
	"<TD ALIGN=LEFT><FONT SIZE=7>CONFIG::  controller</FONT></TD>".
	"<TD ALIGN=RIGHT>PID: <FONT SIZE=7 COLOR=RED>$PID</FONT></TD>".
	"</TR> </TABLE> <HR>");


if (defined $query->param('MODE')) {
	$mode = $query->param('MODE');
	if ($mode eq "LIST") {
		list_open_configs($query);
	} elsif ($mode eq "INFO") {
		print file_info($query);
	} elsif ($mode eq "ERROR") {
		print show_errors_plain($query);
	} elsif ($mode eq "LINE") {
		print show_line($query);
	} elsif ($mode eq "SHOW") {
		print show_file($query);
	} elsif ($mode eq "CLOSE") {
		print close_file($query);
	} elsif ($mode eq "OPEN") {
		if (defined $query->param('FILE')) {
			# do open
			print do_open($query);
		} else {
			# send open form
			print show_open_form();
		}
	}
} else {
	list_open_configs($query);
}


print <<END_OF_HTML;
<hr>
<table width=100%><tr>
<td align=left>[ <a href="config.pl?MODE=LIST">List</A> | <a href="config.pl?MODE=OPEN">Open File</A> | <a href="http://www.fatalmind.com/download.html">CONFIG:: home</A> ]</td>
<td align=right>&copy; 1999, 2000 by <a href="mailto:mws\@fatalmind.com">mws</a>
</tr></table></BODY></HTML>

END_OF_HTML

sub close_file($) {
	my ($query) = @_;

	undef $CONFIG::Plain::already_open_configs{$query->param('FILE')};

	list_open_configs($query);
	return "";
}

sub do_open ($) {
	my ($query) = @_;
	my $v;
	my %CONFIG;

	$CONFIG{COMMENT} = "";
	foreach $v ($query->param('CONFIG_COMMENT')) {
		$CONFIG{COMMENT} .= "$v ";
	}

	$CONFIG{REMOVETRAILINGBLANKS} = $query->param('CONFIG_REMOVETRAILINGBLANKS');
	$CONFIG{DELEMPTYLINE} = $query->param('CONFIG_DELEMPTYLINE');
	$CONFIG{ESCAPE} = $query->param('CONFIG_ESCAPE');
	if ($query->param("MODULE") eq "Hash") {
		$v = CONFIG::Hash->new($query->param("FILE"),\%CONFIG);
	} else {
		$v = CONFIG::Plain->new($query->param("FILE"),\%CONFIG);
	}
	return file_info($query);
}


sub show_open_form() {

	return <<"END_OF_HTML";

<div align=center>
<form action="config.pl" method="get">
<table>
<tr><th align=right>Filename: </th><td><input name="FILE"></td></tr>
<tr><th align=right>Module: </th><td>
<input type=radio  name=MODULE value=Plain checked>Plain<br>
<input type=radio  name=MODULE value=Hash>Hash</td></tr>

<tr><th align=right> Comment style (Plain): </th><td>
<input type=checkbox name=CONFIG_COMMENT value="sh" checked>sh<br>
<input type=checkbox name=CONFIG_COMMENT value="C" checked>C<br>
<input type=checkbox name=CONFIG_COMMENT value="C++" checked>C++<br>
<input type=checkbox name=CONFIG_COMMENT value="asm">asm<br>
<input type=checkbox name=CONFIG_COMMENT value="pascal">pascal<br>
<input type=checkbox name=CONFIG_COMMENT value="sql">sql<br>
<input type=checkbox name=CONFIG_COMMENT value="regexp">regexp <input name=CONFIG_COMMENT_REGEXP><br>
</td></tr>
<tr><th align=right>Delete empty lines: </th><td><input type=checkbox name=CONFIG_DELEMPTYLINE value="1" checked></td></TR>
<tr><th align=right>Escape Character: </th><td><input name=CONFIG_ESCAPE value="\\\\"></td></tr>
<tr><th align=right>Remove trailing blanks: </th><td><input type=checkbox name=CONFIG_REMOVETRAILINGBLANKS value="1" checked></td></tr>
<tr><th align=right>Allow redefnitions (Hash):</th><td><input type=checkbox name=CONFIG_ALLOWREDEFINE checked></td></tr>
<tr><th align=right>Case sensetive Keys (Hash):</th><td><input type=checkbox name=CONFIG_CASEINSENSITIVE checked></td></tr>
<tr><th align=right>Key regular expressioen (Hash):</th><td><input name=CONFIG_KEYREGEXP value="^(\\S+)"></td></tr>
<tr><th align=right>Hash regular expressioen (Hash):</th><td><input name=CONFIG_HASHREGEXP value="\\s+(.*)\$"></td></tr>
<tr><th align=right>Substitue New Line (Hash):</th><td><input name=CONFIG_SUBSTITUTENEWLINE value="\\n"></td></tr>

<tr><td colspan=2 align=center><input type=submit value="Open">&nbsp;<input type=reset value="Reset"></td></tr>
</table>
<input type=hidden name=MODE value=OPEN>
</form>
</div>
END_OF_HTML
}
sub show_file($) {
	my ($query) = @_;
	my $filename = $query->param('FILE');
	my $pwd;
	my $file;
	my $outtext;
	my $line;
	my $i;

        if ($filename !~ /^\//) {
                $pwd = getcwd;
                chomp($pwd);
                $filename = $pwd ."/". $filename;
        }
	$outtext = "FILE: <FONT SIZE=+1><B>$filename</B></FONT><BR><p>\n";

	if (is_open($filename)) {
		$file = CONFIG::Plain->new($filename);
	
		$i = 1;
	
		$outtext .= "<table cellpadding=10 bgcolor=\"#FFFFE0\"><tr><td><pre>";

		while (defined ($line = $file->getline)) {
			chomp($line);
			if ($line eq "") {
				$line = " ";
			}
			$outtext .= sprintf("%s\n",HTML::Entities::encode($line));

			$i++
		}	
		
		$outtext .= "</pre></td></tr></table>";

	} else {
		$outtext .="<p><font color=red>File not loaded</font><br>\n";
	}
	
	return $outtext;
	
}

sub show_line($) {
	my ($query) = @_;
	my $filename = $query->param('FILE');
	my $src_file = $query->param('SRCFILE');
	my $src_line = $query->param('SRCLINE');
	my $outtext;
	my $pwd;
	my $file;
	my $line;
	my $i;
	my $filelines;
	
        if ($filename !~ /^\//) {
                $pwd = getcwd;
                chomp($pwd);
                $filename = $pwd ."/". $filename;
        }
	
	$outtext = "FILE: <FONT SIZE=+1><B>$filename</B></FONT><BR><p>\n";

	if (is_open($filename)) {
		$file = CONFIG::Plain->new($src_file);
		
		$filelines = $file->file_lines;

		for ($i = (($src_line - 2 > 0) ? $src_line - 2 : 1);
		     $i < (( $src_line + 3 <= $filelines) ?  $src_line +3 : $filelines); $i++) {

	
	
		$outtext .= sprintf(
			    "<table width=100\% bgcolor=%s cellpadding=0 cellspacing=0>".
			    "<tr><td><b>&nbsp;%s:%d>&nbsp;</b>%s</td></tr></table>\n",
			    ($i != $src_line ? "#FFFFE0":"#FFE0FF"),
			    $src_file, $i, 
			    encode_entities($file->getline_unparsed($i)));
		}
	} else {
		$outtext .="<p><font color=red>File not loaded</font><br>\n";
	}
	
	return $outtext;
}


sub list_open_configs($) {
	my ($query) = @_;
	my $file;
	my @configs;
	my $i = 0;

	@configs = CONFIG::Plain::open_configs;

	foreach $file (@configs) {
		$i++;
		print("$i.) <A HREF=\"".$query->url."?MODE=INFO&FILE=$file\">$file</A>".
			" [ <a HREF=\"".$query->url."?MODE=CLOSE&FILE=$file\">Close</A> ] (".CONFIG::Plain::config_type($file).")<br>");		
	}

	if ($i == 0) {
		printf("<B> No Files Open</B><br>");
	}

}

sub is_open($) {
	my ($filename) = @_;
	my @configs;

	@configs = CONFIG::Plain::open_configs;

	return in_list($filename, @configs);
}

sub file_info($) {
	my ($query) = @_;
	my $file = $query->param('FILE');
	my $type ="";
	my $outtext;
	my $object;
	my $error;
	my $line;
	my $pwd;

        if ($file !~ /^\//) {
                $pwd = getcwd;
                chomp($pwd);
                $file = $pwd ."/". $file;
        }
	
	$outtext = "FILE: <FONT SIZE=+1><B>$file</B></FONT><BR>\n";

	if (is_open($file)) {

		$type = CONFIG::Plain::config_type($file);

		if ($type eq "Hash") {
			$object = CONFIG::Hash->new($file);
		} else {
			$object = CONFIG::Plain->new($file);
		}
	
		while (defined ($error = $object->getline_error)) {
			printf("GLOBAL error: $error<br>\n");
		}

		$outtext .= "<b><p>STATISTICS:</b><br>";
		$outtext .= statistics_plain($object); 
	
		$outtext .= "<b><p>CONFIGURATION:</b><br>";
		$outtext .= show_config($object);

		$outtext .= '<p><A HREF="'. $query->url. 
			     "?MODE=ERROR&FILE=$file\">ERRORS: ";
		$outtext .= show_errors_statistic($object) ."</A><br>";

		$outtext .= '<p><a href="'.$query->url."?MODE=SHOW&FILE=$file\">Show File</A>";

	} else {
		$outtext .="<p><font color=red>File not loaded</font><br>\n";
	}
	
	return $outtext;
}

sub show_errors_statistic($) {
	my ($file) = @_;
	my ($err_cnt, $lin_cnt) = (0, 0);

	$file->getline_reset;

	while (defined ($file->getline)) {
		if (defined( $file->getline_error)) {
			$lin_cnt++;
			do {
				$err_cnt++;
			} while (defined ($file->getline_error));
		}
	}

	return sprintf("%d errors in %d lines", $err_cnt, $lin_cnt);
}

sub show_errors_plain($) {
	my ($query) = @_;
	my ($line, $outtext, $error, $filename);
	my $file;
	my $filename = $query->param('FILE');
	my $inc_name;
	my $pwd;	
	my ($srcfile, $srcline);

        if ($filename !~ /^\//) {
                $pwd = getcwd;
                chomp($pwd);
                $filename = $pwd ."/". $filename;
        }

	if (is_open($filename)) {
		$file = CONFIG::Plain->new($filename);

		$outtext = "FILE: <B>$filename</B><br>\n";

		$file->getline_reset;

		while (defined ($line = $file->getline)) {
			$error = $file->getline_error;
			if (defined $error) {
				$outtext .= "<p>\n";
				do {
					$outtext.=sprintf("<font color=red>%s</font><br>\n", $error);
				} while (defined ($error = $file->getline_error));
	
				$srcfile = $file->getline_file;
				$srcline = $file->getline_number;
				$outtext .= sprintf("in     <A HREF=\"".$query->url."?MODE=LINE&FILE=$filename&SRCFILE=%s&SRCLINE=%d\">%s:%d</A><br>\n", 
							$srcfile, $srcline,
						      	$srcfile, $srcline);
				while (defined ($inc_name = $file->getline_file)) {
					$outtext .= sprintf("included from %s:%d<br>\n",
						    $inc_name, 
						    $file->getline_number);
				}
			}
		}
	} else {	
		$outtext .="<p><font color=red>File not loaded</font><br>\n";
	}
	return $outtext;
}

sub statistics_plain($) {
	my ($object) = @_;
	  
	return  "<TABLE>".
	
	   "<TR><TD ALING=RIGHT>File modification time: </TD><TD>". 
		scalar localtime($object->file_last_changed)."</TD></TR>".
	   "<TR><TD ALIGN=RIGHT>File in cache since: </TD><TD>".
		scalar localtime($object->file_last_read).
		"</TD></TR>".
	"<TR><TD ALIGN=RIGHT>File size: </TD><TD>". 
		$object->file_lines. " lines (".
		$object->file_size." bytes)</TD><TR>".
	"<TR><TD ALIGN=RIGHT>Cache size: </TD><TD>". 
		$object->cache_lines. " lines (".
		$object->cache_size." bytes)</TD></TR>".
	"<TR><TD ALIGN=RIGHT>Cached reads: </TD><TD>".
		$object->file_read. "</TD></TR>".
	"</TABLE>";


}


sub show_config($) {
	my ($object) = @_;
	my $key;
	my $outtext;
	my %hash;	
	
	$outtext = "<TABLE>\n";

	%hash = %{$object->file_config};	

	foreach $key (keys %hash) {
		$outtext .= "<TR><TD ALIGN=RIGHT>$key:</TD>";
		$outtext .= "<TD ALIGN=LEFT>$hash{$key}</TD>";
		$outtext .= "</TR>\n";
	}
	$outtext .="</TABLE>\n";
	return $outtext;
}

sub in_list {
	my ($scalar, @list) = @_;
	my $element;
	my $count = 0;

	foreach $element (@list) {
		if ($element eq $scalar) {
			$count ++;
		}	
	}
	return $count;
}

