package CGI::SSI_Parser;

use strict;
use POSIX;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw(fssi sssi);
$VERSION = '0.01';

use vars qw($recursive $debug);

$recursive = 0;
$debug = 0;

my $error_msg = '[an error occurred while processing this directive]';
my $SIZEFMT_BYTES = 0;	# sizefmt = bytes
my $SIZEFMT_KMG = 1;	# sizefmt = abbrev
my $sizefmt = $SIZEFMT_KMG;
my $timefmt = "%c";	# current locale's default
my($starting_sequence, $ending_sequence) = ('<!--#', '-->');
my($real_path, $virtual_path);


# Usage:         ssi_init();
#
sub ssi_init {
	my(@real_path, @virtual_path);
	my $i;

	unless (defined($ENV{'DOCUMENT_ROOT'}) ||
		defined($ENV{'SCRIPT_FILENAME'}) ||
		defined($ENV{'SCRIPT_NAME'})) {
		print FOUT $error_msg;
		return 0;
	}

	@real_path = reverse split(/\//, $ENV{'SCRIPT_FILENAME'});
	pop(@real_path);
	@virtual_path = reverse split(/\//, $ENV{'SCRIPT_NAME'});
	pop(@virtual_path);

	for ($i=0; (($i <= $#virtual_path) && ($virtual_path[$i] eq $real_path[$i])); $i++) {
	}

	$real_path = "/" . join("/", reverse @real_path[$i..$#real_path]);
	$virtual_path = "/" . join("/", reverse @virtual_path[$i..$#virtual_path]);

#	$file =~ s/^$virtual_path/$real_path\//o;
#	warn($file) if ($debug);
}

# Usage:         ssi_config_errmsg($line);
#
sub ssi_config_errmsg {
	my $line = shift;

	$error_msg = $line;
}

# Usage:         ssi_config_sizefmt($line);
#
sub ssi_config_sizefmt {
	my $line = shift;

	if ($line eq "bytes") {
		$sizefmt = $SIZEFMT_BYTES;
	} elsif ($line eq "abbrev") {
		$sizefmt = $SIZEFMT_KMG;
	}
}

# Usage:         ssi_config_timefmt($line);
#
sub ssi_config_timefmt {
	my $line = shift;

	$timefmt = $line;
}

# Usage:         ssi_echo_var($line);
#
sub ssi_echo_var {
	my $line = shift;

	if ($line eq "DATE_GMT") {
		print FOUT strftime($timefmt, gmtime(time));
	} elsif ($line eq "DATE_LOCAL") {
		print FOUT strftime($timefmt, localtime(time));
	} elsif ($line eq "DOCUMENT_NAME") {
		print FOUT "(none)";
	} elsif ($line eq "DOCUMENT_URI") {
		print FOUT "(none)";
	} elsif ($line eq "LAST_MODIFIED") {
		print FOUT "(none)";
	} else {
		print FOUT "(none)";
	}
}

# Usage:         ssi_exec_cgi($file);
#
sub ssi_exec_cgi {
	my $file = shift;
	my $line;
	local(*FIN);

	$file =~ s/^$virtual_path/$real_path\//o;

	open(FIN, "$file|");
	unless($line = join("", <FIN>)) {
		warn("Can't run $file\n") if ($debug);
		print FOUT $error_msg;
		return;
	}
	$line =~ /\r?\n\r?\n/o;
	$line = $';
	if ($recursive) {
		sssi($line);
	} else {
		print FOUT $line;
	}
	close(FIN);
}

# Usage:         ssi_exec_cmd($file);
#
sub ssi_exec_cmd {
	my $file = shift;
	my $line;
	local(*FIN);

	open(FIN, "$file|");
	unless($line = join("", <FIN>)) {
		print FOUT $error_msg;
		return;
	}
	if ($recursive) {
		sssi($line);
	} else {
		print FOUT $line;
	}
	close(FIN);
}

# Usage:         ssi_fsize_file($file);
#
sub ssi_fsize_file {
	my $file = shift;
	my $size;

	$size = (stat("$file"))[7];
	if ($sizefmt == $SIZEFMT_KMG) {
		if ($size/1048576 >= 1) { # 1024*1024
			$size = sprintf("%.1fM", $size/1048576);
		} else {
			$size = ceil($size/1024) . "k";
		}
	}
	print FOUT $size;
}

# Usage:         ssi_fsize_virtual($file);
#
sub ssi_fsize_virtual {
	my $file = shift;

	$file = "$ENV{'DOCUMENT_ROOT'}/$file";
	ssi_fsize_file($file);
}

# Usage:         ssi_flastmod_file($file);
#
sub ssi_flastmod_file {
	my $file = shift;
	my $lastmod;

	$lastmod = (stat("$file"))[9];
	$lastmod = strftime($timefmt, localtime($lastmod));
	print FOUT $lastmod;
}

# Usage:         ssi_flastmod_virtual($file);
#
sub ssi_flastmod_virtual {
	my $file = shift;

	$file = "$ENV{'DOCUMENT_ROOT'}/$file";
	ssi_flastmod_file($file);
}

# Usage:         ssi_include_file($file);
#
sub ssi_include_file {
	my $file = shift;
	my $line;
	local(*FIN);

	unless(open(FIN, $file)) {
        print FOUT $error_msg;
        warn("Can't open file $file: $!");
        return;
	}
	$line = join("", <FIN>);
	if ($recursive) {
		sssi($line);
	} else {
		print FOUT $line;
	}
	close(FIN);
}

# Usage:         ssi_include_virtual($file);
#
sub ssi_include_virtual {
	my $file = shift;

	$file = "$ENV{'DOCUMENT_ROOT'}/$file";
	ssi_include_file($file);
}

# Usage:         ssi_printenv();
#
sub ssi_printenv {
	foreach (sort keys(%ENV)) {
		print "$_=$ENV{$_}\n";
	}
}

# Usage:         parse_ssi($ssi);
#
sub parse_ssi {
	my $ssi = shift;
	my($element, @attr);

	$ssi =~ /^(\w+)/;
	$element = $1;
	$ssi = $';
	$ssi =~ s/^\s+//;
	if ($element eq "config") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "errmsg") {
				ssi_config_errmsg($2);
			} elsif ($1 eq "sizefmt") {
				ssi_config_sizefmt($2);
			} elsif ($1 eq "timefmt") {
				ssi_config_timefmt($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "echo") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "var") {
				ssi_echo_var($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "exec") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "cgi") {
				ssi_exec_cgi($2);
			} elsif ($1 eq "cmd") {
				ssi_exec_cmd($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "fsize") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "file") {
				ssi_fsize_file($2);
			} elsif ($1 eq "virtual") {
				ssi_fsize_virtual($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "flastmod") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "file") {
				ssi_flastmod_file($2);
			} elsif ($1 eq "virtual") {
				ssi_flastmod_virtual($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "include") {
		while ($ssi =~ /(\w+)="(.*[^\\])"/) {
			if ($1 eq "file") {
				ssi_include_file($2);
			} elsif ($1 eq "virtual") {
				ssi_include_virtual($2);
			} else {
				print FOUT $error_msg;
			}
			$ssi = $';
		}
	} elsif ($element eq "printenv") {
		if ($ssi eq "") {
			ssi_printenv();
		} else {
			print FOUT $error_msg;
		}
	} elsif ($element eq "set") {
		print FOUT $error_msg;
	} else {
		print FOUT $error_msg;
	}
}

# Usage:         fssi($file);
#
sub fssi {
	my $file = shift;
	my($line, $ssi);
	local(*FIN, *FOUT);
	my $inside = 0;

	*FOUT = *STDOUT;

	ssi_init() || return 0;

	unless(open(FIN, $file)) {
		print FOUT $error_msg;
		warn("Can't open file $file: $!");
		return;
	}

	while ($line = <FIN>) {
		if ($inside) {
			if ($line =~ /$ending_sequence/) {
				$inside = 0;
				$ssi .= $`;
				$line = $';
				$ssi =~ s/^\s+//s;
				$ssi =~ s/\s+$//s;
				$ssi =~ s/\s+/ /s;
				# execute SSI
				warn("SSI: $ssi.\n") if ($debug);
				parse_ssi($ssi);
				$ssi = '';
				redo;
			} else {
				$ssi .= $line;
			}
		} else {
			if ($line =~ /$starting_sequence/) {
				$inside = 1;
				print FOUT $`;
				$line  = $';
				redo;
			} else {
				print FOUT $line;
			}
		}
	}

	close(FIN);
}

# Usage:         sssi($line);
#
sub sssi {
	my $line = shift;
	my $ssi;
	local(*FIN, *FOUT);
	my $inside = 0;

	*FOUT = *STDOUT;

	ssi_init() || return 0;

	while (1) {
		if ($inside) {
			if ($line =~ /$ending_sequence/) {
				$inside = 0;
				$ssi .= $`;
				$line = $';
				$ssi =~ s/^\s+//s;
				$ssi =~ s/\s+$//s;
				$ssi =~ s/\s+/ /s;
				# execute SSI
				warn("SSI: $ssi.\n") if ($debug);
				parse_ssi($ssi);
				$ssi = '';
				redo;
			} else {
				$ssi .= $line;
			}
		} else {
			if ($line =~ /$starting_sequence/) {
				$inside = 1;
				print FOUT $`;
				$line  = $';
				redo;
			} else {
				print FOUT $line;
				last;
			}
		}
	}
}

1;
__END__

=head1 NAME

CGI::SSI_Parser - Implement SSI for Perl CGI

=head1 SYNOPSIS

  use CGI::SSI_Parser;

  $CGI::SSI_Parser::recursive = 1;

  fssi($filename);
  sssi($string);

=head1 DESCRIPTION

CGI::SSI_Parser is used in CGI scripts for parsing SSI directives in files or
string variables, and fully implements the functionality of apache's
mod_include module.

It is an alternative to famous Apache::SSI modules, but it doesn't require
mod_perl. This is an advantage to those who are using public hosting services.
There is a disadvantage, however - the module consumes much memory, and
I don't recommend using it on heavy-loaded sites (currently it's being used
on a site with 10000 hits, and I consider this as a limit). I hope to get
rid of this disadvantage by the time the release comes out (currently
it's beta).

=head2 SSI Directives

This module supports the same directives as mod_include. For methods listed
below but not documented, please see mod_include's online documentation at
http://httpd.apache.org/docs/mod/mod_include.html .

=over 4

=item * config

=item * echo

This directive is not fully supported in current version.

=item * exec

=item * fsize

=item * flastmod

=item * include

=item * printenv

=item * set

This directive is not supported in current version.

=item * perl

This directive is not supported in current version.

=item * if

=item * elif

=item * else

=item * endif

These four directives are not supported in current version.

=back

=head2 Outline Usage

First you need to load the CGI::SSI_Parser module:

  use CGI::SSI_Parser;

You need to specify the following when processing of all nested directives
is needed (default value - 0):

 $CGI::SSI_Parser::recursive = 1;

To parse file or string you need to use:

  fssi($filename);
  sssi($string);

The result is printed to STDOUT.

=head1 TO DO

Full implementation of all SSI directives.

Optimize memory consumption.

=head1 AUTHOR

Vadim Y. Ponomarenko, vp@istc.kiev.ua

=head1 SEE ALSO

mod_include, perl(1).

=cut
