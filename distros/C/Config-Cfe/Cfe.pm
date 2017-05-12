# $Id: Cfe.pm,v 1.49 2002/06/03 10:22:08 jh Exp $

#	Copyright 2001 Jörgen Hägg
#	You may distribute under the terms of the GNU General Public License.

=head1 NAME

Config::Cfe - File configuration module

=head1 SYNOPSIS

use Config::Cfe;

=head1 DESCRIPTION

This module contains functions that ease updating
small text files, usually konfiguration files.
Will complain if the file is more than 100000 lines (configurable).

It is inspired from cfengine, but does only the editing, cfengine
can do much more.


=head1 is_sunos is_sunos4 is_sunos5
is_freebsd is_linux is_debian
is_i386 is_i486 is_i586 is_i686

Boolean test functions

=cut

package Config::Cfe;
use strict;
use vars qw($VERSION @ISA @EXPORT $debug $verbose $par);

($VERSION) = '$Revision: 1.49 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Carp;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(read_file write_file abort_file new_file
	par_os_type par_os_rev par_mach_type
	locate incr goto_top goto_end
	append insert append_file delete_all delete_to delete_n delete_file
	find_str eval_to eval_all eval_n add_list
	eval_where replace_all
	exec_where
	set_comment
	comment_where comment_to comment_n uncomment_where uncomment_to
	uncomment_n set_debug 
	insert_sect append_sect start_sect end_sect delete_sect find_sect
	uncomment_sect comment_sect get_sect
	is_sunos4 is_sunos5 is_freebsd is_sunos is_linux
	is_i386 is_i486 is_i586 is_i686
	is_debian
	curr_line last_line list_lines get_line
	cfe_version
	);

my (@verb_save);

=head1 predefined functions

A few predefined boolean functions are available
for easy architecture checking:

 Function	True if this is
 _________________________________________
 is_debian	a Debian GNU/Linux system, returns the actual version
 is_linux	a Linux system
 is_i386	a 386-based system
 is_i486	a 486-based system
 is_i586	a 586-based system
 is_i686	a 686-based system
 is_sunos	a SunOS system
 is_sunos4	a SunOS 4 system
 is_sunos5	a SunOS 5 system
 is_freebsd	a FreeBSD system

=head1 predefined parameter functions

These functions returns some interesting values about the OS.

 Function	Returns
 _________________________________
 par_os_type	OS type from 'uname'
 par_os_rev	OS revision from 'uname', modified to integer
 par_mach_type	OS architecture from 'uname'

=cut

######################################################################

=head1 cfe_version [minimal version]

Returns the current version of the B<cfe>-module.
If called with a version number, cfe will die if B<cfe> is less than
this version.

=cut

sub cfe_version {
	my ($min_vers) = @_;

	my $rev = '$Revision: 1.49 $';
	my ($v) = $rev =~ /:\s+([\d\.]+)/;
	my $ndv = sprintf("%.3f", $v);
	$ndv =~ s/\.//;
	my $min_ndv = sprintf("%.3f", $min_vers);
	$min_ndv =~ s/\.//;

	if ($min_vers > 0 && $ndv < $min_ndv) {
		croak sprintf("This program requires Config::Cfe ".
			"version %.3f or greater, abort\n", $min_vers);
	}
	$ndv;
}

######################################################################

=head1 set_debug [debug [verbose]]

If B<debug> is non-zero then B<write_file> will write
the new file but B<not> rename the file from I<file.new> to I<file>.
B<verbose> greater than 0 will print out debug info.

 Example:

 use Getopt::Std;
 getopt('dv');

 $host = hostname;
 set_debug($opt_d, $opt_v);

=cut

sub set_debug {
	$debug = $_[0];
	$verbose = $_[1];
	for my $i (@verb_save) {
		print $i if $verbose;
	}
	@verb_save = ();
}

=head1 new_file filename

Start editing a new file, will overwrite any existing file.
A new file will get file mode 0666 & umask.

=cut

sub new_file {
	my ($file) = @_;

#	&lock($file);
	$par->{'file_name'} = $file;
	$par->{'edit'} = $par->{'cur_line'} = 0;
	$par->{'lines'} = [];
	&verbose("new_file", $file);
}

=head1 read_file filename [,1]

Start editing an existing file.
If I<filename> doesn't exist, B<read_file> will
either complain or, if optional second argument is true, create
the file.

=cut

sub read_file {
	my ($file, $exist_flag) = @_;

#	&lock($file);
	if ($exist_flag && !-e $file) {
		&new_file($file);
		$par->{'mode'} = 0666 & umask;
		$par->{'uid'} = $>;
		$par->{'gid'} = $);
		&verbose('read_file', sprintf("mode=0%o, uid=%d, gid=%d",
			$par->{'mode'}, $par->{'uid'}, $par->{'gid'}));
		return;
	}
		
	&get_filemode($file);
	$par->{'file_name'} = $file;
	$par->{'edit'} = $par->{'cur_line'} = 0;
	my $lines = $par->{'lines'} = [];
	unless (-e $file) {
		&verbose("read_file", "$file does not exist");
		return;
	}
	open(FILE, $file) || croak "open $file:$!";
	while(<FILE>) {
		chop;
		push(@$lines, $_);
		croak "too many lines" if @$lines >= $par->{'max_lines'};
	}
	close(FILE);
	&verbose("read_file", "$file, ".(@$lines*1)." lines");
}

=head1 write_file [\%par]

Write the current file if it has been changed.
Control of the file can be done thru the hash parameter B<par>.
The old file will be renamed to B<.>I<filename>B<.cfe>.
Will not rename the final file (I<filename.new>) to I<filename>
if debug is active.

Accepted keys for B<par>:

 key	name			default
 --------------------------------------
 mode	filemode		0666 & umask.
 uid	numeric userid		0
 gid	numeric groupid		0

=cut

sub write_file {
	my (%tpar) = @_;
	my ($tmp, $fsize, $file);

	return unless $par->{'edit'};

	$tpar{'mode'} = $par->{'mode'} unless $tpar{'mode'}; 
	$tpar{'uid'} = $par->{'uid'} unless $tpar{'uid'}; 
	$tpar{'gid'} = $par->{'gid'} unless $tpar{'gid'}; 

	croak "No filename!" unless $file = $par->{'file_name'};
	($tmp = $file) =~ s/$/.new/;
	open(FILEO, ">$tmp") || croak "can't create $tmp:$!";
	chmod $tpar{'mode'}, $tmp;
	chown $tpar{'uid'}, $tpar{'gid'}, $tmp;
	for my $line (@{$par->{'lines'}}) {
		print FILEO "$line\n";
		$fsize += length($line)+1;
	}
	close(FILEO);
	&abort_file("incorrect filesize, abort") if -s $tmp != $fsize;
	unless ($debug) {
		rename($file, ".$file.cfe");
		rename($tmp, $file) || &abort_file("rename $tmp to $file:$!");
	}
	$par->{'lines'} = [];
	&verbose('write_file', "wrote $file, ".
		(@{$par->{'lines'}}*1)." lines, $fsize bytes");
#	&unlock($file);
	&reset_par;
}

=head1 abort_file

Quit editing the current file.

=cut

sub abort_file {
	my ($txt) = @_;
	my ($tmp, $fsize, $file);

	croak "No filename!" unless $file = $par->{'file_name'};
	($tmp = $file) =~ s/$/.new/;
	unlink($tmp) || croak "unlink $tmp:$!";
	croak $txt if $txt;
#	&unlock($file);
	&reset_par;
}

=head1 append_file filename

Appends B<filename> at the current line.

=cut

sub append_file {
	my ($file) = @_;
	my (@tmp);

	&verbose("append_file", "**** $file");
	open(FILE, $file) || croak "open $file:$!";
	while(<FILE>) {
		chop;
		push(@tmp, $_);
		&verbose("append_file", $_);
		croak "too many lines"
			if @{$par->{'lines'}} >= $par->{'max_lines'};
	}
	close(FILE);
	&append(@tmp);
}

=head1 list_lines [from_line [to_line]]

This is a debug function, it will list all current lines to stdout.

=cut

sub list_lines {
	my ($from, $to) = @_;
	my ($i);

	my $lines = $par->{'lines'};
	$from = 0 if $from eq '';
	$to = @$lines if $to eq '';

	for ($i = $from; $i < $to; $i++) {
		printf STDOUT "%3d: %s\n", $i, $lines->[$i];
	}
}
######################################################################

=head1 get_line from_line [to_line]

B<get_line> will return a pointer to an array with the
lines from I<from_line> up to, not including I<to_line>,
or the specified line if I<to_line> isn't specified.
The array is a copy of the real lines, any changes to this
array will be lost.

=cut

sub get_line {
	my ($from, $to) = @_;
	my $ret = [];

	croak "no start line defined" if !defined $from;
	my $lines = $par->{'lines'};
	return $lines->[$from] if !defined $to;

	my $i;
	for ($i = $from; $i < $to; $i++) {
		push(@$ret, $lines->[$i]);
	}
	return $ret;
}
######################################################################

=head1 locate regexp

Search for I<regexp>, returns true at the first occurance.
B<locate> always starts at the beginning.

=cut

sub locate {
	my ($regexp) = @_;
	my ($n, $x);

	$n = $par->{'cur_line'} = &find_row(0, $regexp);
	$x = '*found*: '.$par->{'lines'}->[$n] if $n >= 0;
	&verbose("locate", "'$regexp': $x");
	return $n >= 0;
}

=head1 incr [[-]n]

Increments the line pointer, negative values allowed.
Returns the new line number.

=cut

sub incr {
	my ($n) = @_;

	$n = 1 unless $n;
	carp("outside file"), return
		if $par->{'cur_line'}+$n > @{$par->{'lines'}};
	$par->{'cur_line'} += $n;
	&verbose("incr", "$n, cur_line: ".$par->{'cur_line'});
	$par->{'cur_line'};
}

=head1 goto_top

Set the first line to be the current line.

=cut

sub goto_top {
	$par->{'cur_line'} = 0;
	&verbose("goto_top", "beginning");
}

=head1 goto_end

Set the last line to be the current line.

=cut

sub goto_end {
	$par->{'cur_line'} = @{$par->{'lines'}}-1;
	&verbose("goto_end", "eof");
}

=head1 curr_line [N]

Returns the current line number.
Sets the current line number if arg B<N> exist;

=cut

sub curr_line {
	if (@_) {	
		$par->{'cur_line'} = shift;
	}
	return $par->{'cur_line'};
}

=head1 last_line

Returns the last line number.

=cut

sub last_line {
	return @{$par->{'lines'}}*1-1;
}
######################################################################

=head1 append line1 [line2 [...]]

Appends one or more lines after the current line.
The line pointer will point to the last appended line.

=cut

sub append {
	my @new = &split_cr(@_);

	&verbose("append", '**** start') if @new > 1;
	splice(@{$par->{'lines'}}, $par->{'cur_line'}+1, 0, @new);
	$par->{'cur_line'} += @new;
	&verbose("append", @new, "**** end");
	++$par->{'edit'};
}

=head1 insert line1 [line2 [...]]

Inserts one or more lines before the current line.
The line pointer will point to the first inserted line.

=cut

sub insert {
	my @new = &split_cr(@_);

	&verbose("insert", '**** start') if @new > 1;
	splice(@{$par->{'lines'}}, $par->{'cur_line'}, 0, @new);
	&verbose("insert", @new, "**** end, cur_line: ".$par->{'cur_line'});
	++$par->{'edit'};
}

######################################################################

=head1 add_list prefix listpointer [separator [newlinestring [suffix [length]]]]

Append a list after the current line.
The result is one or more lines starting with B<prefix> and
the list joined by B<separator>. If the line is too long it will
be broken into several separated by B<newlinestring>.
Default for B<separator> is 'B<:>' and for B<newlinestring> 'B<\\\n>'.
Default for B<length> is 75.
Example:

 @list = qw(/bin /usr/bin /usr/local/bin);
 add_list PATH= \@list;

 will look like this:

 PATH=/bin:/usr/bin:/usr/local/bin

=cut

sub add_list {
	my ($prefix, $list, $sep, $newl, $suffix, $max) = @_;
	my ($str, $newstr, $new, $cnt, @new);

	$max = 75 unless $max;
	$newl = "\\\n" unless $newl;
	$sep = ':' unless $sep;
	$str = $prefix;
	my $i;
	for ($i = 0; $i < @$list; $i++) {
		$new = $list->[$i];
		$str .= $sep if $cnt++;
		if (length($str)+length($new) > $max) {
			push(@new, $str);
			$str = '';
		}
		$str .= $new;
	}
	push(@new, $str) if $str;
	$newstr = join($newl, @new);
	$newstr .= $suffix;
	&verbose("add_list", $newstr);
	&append($newstr);
}

######################################################################

=head1 delete_all regexp

Deletes all lines containing B</regexp/>.
Returns the deleted lines.
If B<regexp> is a pointer to a function or a anonymous function, it
will be executed with current line number and a pointer to the
current line as argument. The line will be deleted if the function
returns true.

=cut

sub delete_all {
	my ($regexp) = @_;
	my (@del, $lines, $new);
	my $line = 0;

	&verbose("delete_all", "**** $regexp");
	$lines = $par->{'lines'};
	$new = [];

	for (my $i = 0; $i < @$lines; $i++) {
		$_ = $lines->[$i];
		if (ref($regexp) =~ /CODE/) {
			my $del = &$regexp($i, \$lines->[$i]);
			if ($del) {
				&verbose("deleted", "$i:$_");
				push(@del, $_);
			}
			else {
				push(@$new, $_);
			}
			next;
		}
		unless (/$regexp/) {
			push(@$new, $_);
		}
		else {
			&verbose("deleted", "$i:$_");
			push(@del, $_);
		}
	}
	$par->{'lines'} = $new;
	$par->{'edit'} += @del*1;
	return @del;
}

=head1 delete_to regexp

Deletes all lines from the current to the line
matching B<regexp>.
Returns '' if regexp not found, otherwhise returns the
deleted lines.
Current line will be the line preceding the deleted area.

=cut

sub delete_to {
	my ($regexp) = @_;
	my (@d, $i, $line,  $cur);

	my $cur = $par->{'cur_line'};
	my $last = &find_row($cur, $regexp);
	return 0 unless $last >= 0;

	my @d = splice(@{$par->{'lines'}}, $cur, $last-$cur+1);
	$par->{'cur_line'}--;
	&verbose("delete_to", "*** $regexp", @d);
	$par->{'edit'} += @d*1;
	return @d;
}

=head1 delete_n N

Deletes B<N> lines from the current.
Deletes to the end of file if N equal C<end>.
Returns the deleted lines;
Current line will be the line preceding the deleted area.

=cut

sub delete_n {
	my ($n) = @_;
	my (@d);

	$n = &last_line+1 if $n eq 'end';
	@d = splice(@{$par->{'lines'}}, $par->{'cur_line'}, $n);
	&verbose("delete_n", $n, @d);
	$par->{'cur_line'}--;
	return @d;
	$par->{'edit'}++;
}

=head1 delete_file

Deletes all lines.

=cut

sub delete_file {
	$par->{'lines'} = [];
	$par->{'edit'}++;
}

######################################################################

=head1 find_str regexp

B<find_str> returns true if any line matching B<regexp> is found.
Current line is not changed.

=cut

sub find_str {
	my ($regexp) = @_;

	return &find_row(0, $regexp) >= 0;
}

######################################################################

=head1 eval_to regexp exp

B<eval_to> will evaluate B<exp> on each line up to the line
matching B<regexp>.
Returns true if any line was changed.
B<exp> can be any perl expression like C<'s/bin/usr/'>.
If B<exp> is a pointer to a function or a anonymous function, it
will be executed with current line number and a pointer to the
current line as argument.
Changes to the current line will be preserved.

=cut

sub eval_to {
	my ($regexp, $eval) = @_;
	my ($edit, $i, $line,  $cur, $last);

	$cur = $par->{'cur_line'};
	$last = &find_row($cur, $regexp);
	carp "can't find $regexp" unless $last >= 0;

	my $lines = $par->{'lines'};
	&verbose("eval_to", "$regexp, $eval");
	for ($i = $cur; $i <= $last; $i++) {
		if (eval "\$par->{'lines'}->[\$i] =~ $eval") {
			if (ref($eval) =~ /CODE/) {
				my $tline = $lines->[$i];
				&$eval($i, \$lines->[$i]);
				if ($tline ne $lines->[$i]) {
					&verbose("exec", "$i: ".$lines->[$i]);
					$edit++;
				}
				next;
			}
			$edit++;
			&verbose("eval", "$i: ".$lines->[$i]);
		}
	}
	$par->{'edit'} += $edit;
	return $edit;
}

=head1 eval_all exp

B<eval_all> will evaluate B<exp> on each line in the file.
Returns true if any line was changed.
See B<eval_to>.

=cut

sub eval_all {
	my ($eval) = @_;
	my ($edit, $i, $line,  $cur, $last);

	my $lines = $par->{'lines'};
	&verbose("eval_all", "**** $eval");
	for ($i = 0; $i < @$lines; $i++) {
		if (ref($eval) =~ /CODE/) {
			my $tline = $lines->[$i];
			&$eval($i, \$lines->[$i]);
			if ($tline ne $lines->[$i]) {
				&verbose("exec", "$i: ".$lines->[$i]);
				$edit++;
			}
			next;
		}
		elsif (eval "\$lines->[\$i] =~ $eval") {
			&verbose("eval", "$i: ".$lines->[$i]);
			$edit++;
		}
	}
	$par->{'edit'} += $edit;
	return $edit;
}

=head1 eval_n N exp

B<eval_n> will evaluate B<exp> on B<N> lines from the current line.
Returns true if any line was changed.
A value of 0 will change the current line, 1 will change the current
and the next line.
See B<eval_to>.
Evaluates to the end of file if N equal C<end>.

=cut

sub eval_n {
	my ($n, $eval) = @_;
	my ($edit, $i, $line,  $cur, $last, $start);

	$n = &last_line if $n eq 'end';
	my $lines = $par->{'lines'};
	$start = $par->{'cur_line'};
	$last = $start+$n;
	$last = @$lines-1 if $last >= @$lines;
	&verbose("eval_n", "**** $n,$eval: $start-$last");
	for ($i = $start; $i <= $last; $i++) {
		if (ref($eval) =~ /CODE/) {
			my $tline = $lines->[$i];
			&$eval($i, \$lines->[$i]);
			if ($tline ne $lines->[$i]) {
				&verbose("exec", "$i: ".$lines->[$i]);
				$edit++;
			}
			next;
		}
		if (eval "\$lines->[\$i] =~ $eval") {
			&verbose("eval_n", "$i: ".$lines->[$i]);
			$edit++;
		}
	}
	$par->{'edit'} += $edit;
	return $edit;
}

=head1 eval_where regexp1 exp1 [regexp2 exp2 [...]]

B<eval_where> will evaluate B<exp> for each line
matching B<regexp>. 
Returns true if any line was changed.
See B<eval_to>.

=cut

sub eval_where {
	my ($i, $line,  $cur, $last);
	my ($eval, $regexp, $edit);

	my $lines = $par->{'lines'};
	&verbose("eval_where", '**** start');
	while(($regexp = shift) && ($eval = shift)) {
		&verbose("eval", "$regexp, $eval");
		for ($i = 0; $i < @$lines; $i++) {
			if ($lines->[$i] =~ /$regexp/) {
				if (ref($eval) =~ /CODE/) {
					my $tline = $lines->[$i];
					&$eval($i, \$lines->[$i]);
					if ($tline ne $lines->[$i]) {
						&verbose("exec",
							"$i: ".$lines->[$i]);
						$edit++;
					}
					next;
				}
				if (eval "\$lines->[\$i] =~ $eval") {
					&verbose("eval", "$i: ".$lines->[$i]);
					$edit++;
				}
			}
		}
	}
	$par->{'edit'} += $edit;
	return $edit;
}

######################################################################

=head1 replace_all from1 to1 [from2 to2 [...]]

B<replace_all> replaces all occurrences of the string
B<from> with the string B<to>.

=cut

sub replace_all {
	my ($from, $to, $i);
	my ($edit, $lines);

	&verbose("replace_all", '**** start');
	while(($from = shift) && ($to = shift)) {
		&verbose("replace_all", "$from -> $to");
		$lines = $par->{'lines'};
		for ($i = 0; $i < @$lines; $i++) {
			if ($lines->[$i] =~ s/$from/$to/g) {
				&verbose("replace_all", "$i: ".$lines->[$i]);
				$edit++;
			}
		}
	}
	$par->{'edit'} += $edit;
	return $edit;
}

######################################################################

=head1 set_comment [start_comment [end_comment]]

B<set_comment> sets the current comment strings.
B<start_comment> defaults to B<'# '>,
B<end_comment> defaults to B<''>.
Using B<set_comment> whithout arguments will set the
default comment strings again.

=cut

sub set_comment {
	my ($cstart, $cend) = @_;
	
	$cstart = $par->{'cstart'} = '# ' unless $cstart;
	$cend = $par->{'cend'} = '' unless $cend;
	&verbose("set_comment", "$par->{'cstart'}, $par->{'cend'}");
	my $x = ', do not change this line!';

	$par->{'begin_sect'} = $cstart.'CFE begin <%s>'.$x;
	&verbose("set_comment", $par->{'begin_sect'});

	$par->{'end_sect'} = $cstart.'CFE end <%s>'.$x;
	&verbose("set_comment", $par->{'end_sect'});

	$par->{'find_sect'} = '^'.quotemeta($cstart).'CFE %s <%s>';
	&verbose("set_comment", $par->{'find_sect'});
}

=head1 comment_where regexp

B<comment_where> inserts a comment in the beginning of each
line matching B<regexp>.
See also B<set_comment>.

=cut

sub comment_where {
	my ($regexp) = @_;
	my ($cstart, $cend);
	
	&verbose("comment_where", $regexp);
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_where($regexp, "s/^(.*)\$/$cstart\$1$cend/");
}

=head1 comment_to regexp

B<comment_to> inserts a comment in the beginning of each
line from the  current line up to the line
matching B<regexp>.
See also B<set_comment>.

=cut

sub comment_to {
	my ($regexp) = @_;
	my ($cstart, $cend);
	
	&verbose("comment_to", $regexp);
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_to($regexp, "s/^(.*)\$/$cstart\$1$cend/");
}

=head1 comment_n N

B<comment_n> inserts a comment in the beginning of B<N>
lines starting with the current line.
See also B<set_comment>.
Comments to the end of file if N equal C<end>.

=cut

sub comment_n {
	my ($n) = @_;
	my ($cstart, $cend);
	
	&verbose("comment_n", $n);
	$n = last_line if $n eq 'end';
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_n($n, "s/^(.*)\$/$cstart\$1$cend/");
}

=head1 uncomment_where regexp 

B<uncomment_where> removes the comment in the beginning of each
line matching B<regexp>.
See also B<set_comment>.

=cut

sub uncomment_where {
	my ($regexp) = @_;
	my ($cstart, $cend);
	
	&verbose("uncomment_where", $regexp);
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_where($regexp, "s/^$cstart(.*)$cend\$/\$1/");
}

=head1 uncomment_to regexp

B<uncomment_to> removes the comment in the beginning of each
line from the  current line up to the line
matching B<regexp>.
See also B<set_comment>.

=cut

sub uncomment_to {
	my ($regexp) = @_;
	my ($cstart, $cend);
	
	&verbose("uncomment_to", $regexp);
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_to($regexp, "s/^$cstart(.*)$cend\$/\$1/");
}

=head1 uncomment_n N

B<comment_n> inserts a comment in the beginning of B<N>
lines starting with the current line.
See also B<set_comment> and B<eval_n>.
Uncomments to the end of file if N equal C<end>.

=cut

sub uncomment_n {
	my ($n) = @_;
	my ($cstart, $cend);
	
	&verbose("uncomment_n", $n);
	$n = last_line if $n eq 'end';
	$cstart = $par->{'cstart'};
	$cend = $par->{'cend'};
	return &eval_n($n, "s/^$cstart(.*)$cend\$/\$1/");
}
######################################################################

=head1 append_sect section

Start appending a new section by adding a B<CFE> tag named
I<section>.

=cut

sub append_sect {
	my ($section) = @_;

	&verbose("append_sect", $section);
	&append(sprintf($par->{'begin_sect'}, $section));
	$par->{'cur_sect'} = $section;
}

=head1 insert_sect section

Start inserting a new section

=cut

sub insert_sect {
	my ($section) = @_;

	&verbose("start_sect", $section);
	&insert(sprintf($par->{'begin_sect'}, $section));
	$par->{'cur_sect'} = $section;
}
sub start_sect {
	&insert_sect($_[0]);
}

=head1 end_sect

Appends a comment at current line that marks the end of the section.

=cut

sub end_sect {
	carp "No active section!" unless $par->{'cur_sect'};
	&verbose("end_sect", '***');
	&append(sprintf($par->{'end_sect'}, $par->{'cur_sect'}));
	$par->{'cur_sect'} = '';
}

=head1 delete_sect section

Deletes the section name B<section>.
Returns true if section actually was deleted.
Will set the current line.

=cut

sub delete_sect {
	my ($section) = @_;
	
	&verbose("delete_sect", $section);
	return 0 unless &locate(sprintf($par->{'find_sect'},
		'begin', $section));
	return &delete_to(sprintf($par->{'find_sect'}, 'end', $section));
}

=head1 find_sect section

Returns true if B<section> exist.
Will set the current line.

=cut

sub find_sect {
	my ($section) = @_;
	
	&verbose("find_sect", $section);
	return &locate(sprintf($par->{'find_sect'}, 'begin', $section));
}

=head1 comment_sect section

Comment out the section name B<section>.
Will set the current line.

=cut

sub comment_sect {
	my ($section) = @_;
	
	&verbose("comment_sect", $section);
	return 0 unless &locate(sprintf($par->{'find_sect'},
		'begin', $section));
	my $from = &incr();
	my $to = &find_row($from,
		sprintf($par->{'find_sect'}, 'end', $section));
	return unless $to >= $from;
	return &comment_n($to-$from-1);
}

=head1 uncomment_sect section

Enable the section name B<section> by removing the comment string
at the beginning of the lines.  Will set the current line.

=cut

sub uncomment_sect {
	my ($section) = @_;

	&verbose("uncomment_sect", $section);
	return 0 unless &locate(sprintf($par->{'find_sect'},
		'begin', $section));
	my $from = &incr();
	my $to = &find_row($from,
		sprintf($par->{'find_sect'}, 'end', $section));
	return unless $to >= $from;
	return &uncomment_n($to-$from-1);
	
}

=head1 get_sect section

Fetch the content of section named B<section>, return a pointer
to an anonymous array.
Will set the current line.

=cut

sub get_sect {
	my ($section) = @_;

	&verbose("get_sect", $section);
	return 0 unless &locate(sprintf($par->{'find_sect'},
		'begin', $section));
	my $from = &incr();
	my $to = &find_row($from,
		sprintf($par->{'find_sect'}, 'end', $section));
	return [] unless $to >= $from;
	return &get_line($from, $to);
	
}
######################################################################
# Internal subroutine
# start searching from line 'start' for 'regexp';
# Returns the line number or -1 if not found.
sub find_row {
	my ($start, $regexp) = @_;
	my ($i, $line);

	my $lines = $par->{'lines'};
	my $l = -1;
	for ($i = $start; $i < @$lines; $i++) {
		$l = $i, last if $lines->[$i] =~ /$regexp/;
	}
	return $l;
}
# splits any multilined string and returns an array of
# guaranteed single lines.
sub split_cr {
	my ($i, @new);
	for my $i (@_) {
		push(@new, ''), next if $i eq '';
		push(@new, split(/\n/, $i));
	}
	return @new;
}
# Print out debug info if verbose is active.
# 
sub verbose {
	my ($func, @txt) = @_;
	my ($l, $i);

	
	return if $verbose == 0;
	$l = $par->{'cur_line'};
	for my $i (@txt) {
		push(@verb_save, "$func($l): $i\n"), next if $verbose < 0;
		print "$func($l): $i\n";
	}
}

sub reset_par {
	$par->{'max_lines'} = 100000;
	$par->{'file_name'} = '';
	$par->{'num_lines'} = 0;
	$par->{'lines'} = [];
	$par->{'cur_line'} = 0;
	$par->{'edit'} = 0;
	$par->{'mode'} = 0666 & umask;
	$par->{'uid'} = 0;
	$par->{'gid'} = 0;
	&set_comment;
}
sub get_filemode {
	my ($f) = @_;

	($par->{'mode'}, $par->{'uid'}, $par->{'gid'}) = (stat($f))[2,4,5];
	$par->{'mode'} &= 0777;
	&verbose('get_filemode',
		sprintf("mode=0%o, uid=%d, gid=%d", $par->{'mode'},
			$par->{'uid'}, $par->{'gid'}));
}

sub BEGIN {
	my (%type, $uname, $r, $ostype, $version, $mach_type);

	$par = {};
	&reset_par;
	chop($uname = `uname -srm`);
	($ostype, $version, $mach_type) = split(/\s+/, $uname);
	($r = $version) =~ tr/0-9//cd;
	$r .= '0' if length($r) < 3;
	$r *= 1.0;

	($par->{'os_type'} = $ostype) =~ tr/A-Z/a-z/;
	$par->{'os_rev'} = $r;
	($par->{'mach_type'} = $mach_type) =~ tr/A-Z/a-z/;

	$type{'sunos4'} = $ostype eq 'SunOS' && $version < 5 ? $r : 0;
	$type{'sunos5'} = $ostype eq 'SunOS' && $version > 5 ? $r : 0;
	$type{'freebsd'} = $ostype eq 'FreeBSD' ? $r : 0;
	$type{'sunos'} = $ostype eq 'SunOS' ? $r : 0;
	$type{'linux'} = $ostype eq 'Linux' ? $r : 0;

	$type{$1} = $mach_type =~ /^(i[3-9]86)/ ? $r : 0;

	$verbose = -1;

	if (-f '/etc/debian_version') {
		my $deb;

		open(IN, '/etc/debian_version');
		chop($deb = <IN>);
		close(IN);
		$deb =~ s/\.//;
		$deb .= '0' if length($deb) < 3;
		$type{'debian'} = $deb;
	}
	for my $i (keys %type) {
		&verbose('init', "sub is_$i\{return $type{$i};}");
		eval "sub is_$i\{ &verbose('is_$i','$type{$i}');".
			"return \"$type{$i}\";}";
	}
	for my $i (qw(os_type os_rev mach_type)) {
		&verbose('init', "sub par_$i { return \"$par->{$i}\"; }");
		eval "sub par_$i { ".
			"&verbose('par_$i','$par->{$i}');".
			"return \"$par->{$i}\"; }";
	}
	&set_comment;
	$verbose = 0;
}
