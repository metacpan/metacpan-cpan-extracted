=head1 NAME

DBIx::Informix::Perform::DigestPer  -  "Perform" screen file digester

Digests an Informixoid .per file and make a string suitable for
writing to a file or just eval'ing.

=head1 MODULE VERSION

0.0.1

=head1 SYNOPSIS

    use DBIx::Informix::Perform::DigestPer;
    $desc = digest(*INFILE_HANDLE);
    # now do the right thing with $desc

    shell>  perl -MDBIx::Informix::Perform::DigestPer -e'digest_file("foo.per")'
    # writes file foo.pps or named in 2nd argument.
    # now read and do the right thing with foo.pps

=head1 REQUIREMENTS

Data::Dumper

=head1 DESCRIPTION

Digests an Informix "Perform" screen descriptor file into a form usable by 
the Perform emulator B<Perform.pm>.  May be used inline or to write a file.

Among other things, it digests the screen layout into a series of Curses 
widget specs, as either Label or TextField types.

The output string/file is evaluable Perl source code, which 
sets four variables:

$db: name of database

$screen: screen descriptor, a hash including a Curses::Forms spec.
	Form fields' widgets are named as labelled (e.g. 'f000').

$tables: array of table names.

$attrs:  hash of field names to [table column attributes] .
	The 'attributes' string is unparsed.

=cut

package DBIx::Informix::Perform::DigestPer;
use strict;
use base 'Exporter';

use vars qw(@EXPORT_OK $VERSION %HEADING_WORDS);

BEGIN
{
    @EXPORT_OK = qw(digest digest_file);
    $VERSION = '0.0.2';

    %HEADING_WORDS =
	map { ($_, 1) } qw(screen tables attributes instructions end);
}

use Data::Dumper;

=head2  digest

   digest (IOHandle_Ref)

Digests an Informix .per file into a string that evaluates to a Perform
descriptor.

=cut


sub digest			#
{
    shift  if ($_[0] eq __PACKAGE__);
    my $ioh = shift;

    my $parser = new DBIx::Informix::Perform::DigestPer::Parser($ioh);
    my $word;
    my ($db, $tables, $atts, $instrs);
    my $screens = [];
    while ($word = $parser->readword('true')) {
	if ($word eq 'database') {
	    $db = read_database($parser);
	}
	elsif ($word eq 'screen') {
	    push (@$screens, read_screen($parser)); # might return many
	}
	elsif ($word eq 'tables') {
	    $tables = read_tables($parser);
	}
	elsif ($word eq 'attributes') {
	    $atts = read_attributes($parser);
	}
	elsif ($word eq 'instructions') {
	    $instrs = read_instructions($parser);
	}
    }

    return outputstring($db, $screens, $tables, $atts, $instrs);
}


sub read_database
{
    my $parser = shift;

    return $parser->readword();	# just the name.
}

sub read_screen 
{
    my @screens;
    my $parser = shift;

    my $result = {};
    my $word;
    while ($word = $parser->readword()) {
	if ($word eq 'size') {
	    # read size...
	    my $height = 0 + $parser->readword();
	    my $by = $parser->readword();
	    my $width = 0 + $parser->readword();
	    die "Expected 'by' but got '$by'"
		if ($by ne 'by');
	    $result->{'MINSIZE'} = [ $width, $height];
	}
	elsif ($word eq '{' ) {
	    # read screen format
	    my $widgets = {};
	    my $line;
	    my $lineno = 0;
	    my $labelno = '000';
	    my @fields = ();
	    my $last_line_blank;
	    my $page_split;
	    while (defined($line = $parser->readline()) && $line !~ /\}/) {
		if ($line =~ /^\s*$/){
		    $page_split = 1 if $last_line_blank;
		    $last_line_blank = 1;
		    $lineno++;
		    next;
		}
		while ($line =~ /(\[\s*(\w+)\s*\]|([^\s\[]+\s?)+)/g) {
		    my $pre = $`;
		    my $post = $';
		    my $match = $1;
		    my $id = $2;
		    if ($page_split) {
			push (@screens, { WIDGETS => $widgets,
					  FIELDS => [ @fields ],
					  LINES => $lineno,
				      });
			$widgets = {};
			@fields = ();
			$lineno = 0;
		    }
		    undef $page_split;
		    undef $last_line_blank;
		    my $x = length($pre);  # + $pos
		    if ($id) {
			# it's a field
			my $cols = length($match) - 2;
			if (0) {
			    #  Leading bracket
			    $widgets->{"${id}_openbracket"} = {
				TYPE => 'Label', COLUMNS => 1,
				Y => $lineno, X => $x, VALUE => '[' } ;
			}
			# The field...
			$x++;
			# Note, the OnEnter/OnExit subs must be supplied
			# by the Perform emulator.
			$widgets->{$id} = {
			    TYPE => 'TextField', COLUMNS => $cols,
			    Y => $lineno, X => $x, BORDER => 0};
			$x += $cols;
			if (0) {
			    # Trailing Bracket...
			    $widgets->{"${id}_closebracket"} = {
				TYPE => 'Label', COLUMNS => 1,
				Y => $lineno, X => $x, VALUE => ']' };
			}
			push (@fields, $id);
		    }
		    else {
			# it's a label
			$match =~ s/\s$//; # ignore trailing whitespace
			my $cols = length($match);
			$widgets->{"label_$labelno"} = {
			    TYPE => 'Label', COLUMNS => $cols,
			    Y => $lineno, X => $x, VALUE => $match };
			$labelno++;
		    }
		}
		$lineno++;
	    }
	    push (@screens, { WIDGETS => $widgets,
			      FIELDS => [ @fields ],
			      LINES =>  $lineno} );
	}
	elsif (lc($word) eq 'end') {
  	    return @screens;
  	}
	else {
	    die "Unknown screen section directive '$word'";
	}
    }
    return @screens;
}

sub read_tables
{
    my $parser = shift;
    
    my $line;
    my @tables;
    while ($line = $parser->readline()) {
	push (@tables, $line =~ /(\w+)/g);
    }
    return [ @tables ];
}

sub read_attributes
{
    my $parser = shift;

    my $line;
    my %fields;
    my $lines = '';
    while ($line = $parser->readline()) {
	chomp $line;
	$lines .= ' ' . $line;
	next unless $line =~ /;/;
	my ($name, $cols, $ignore, $ignore1, $attrs) =
	    $lines =~ /\s*(\w+)((\s*=\s*\*?\w+\.\w+)+)\s*(\,\s*(.*))?;/;
	$attrs = ''
	    unless defined($attrs);
	my $collist = [];
	foreach my $colspec (split /\s*=\s*/, $cols) {
	    next unless $colspec;
	    my ($verify, $tbl, $col) = $colspec =~ /(\*)?(\w+)\.(\w+)/;
	    push @$collist, [$tbl, $col, $verify];
	}
	my $attrhash = {};
	while($attrs =~
	      /\s*(\w+)\s*(=\s*(\w+|\"[^\"]*\"|\((\s*\"[^\"]*\"\s*,?)*\)))?,?/g
	      ) {
	    my $atname = uc $1;
	    my $atval = $3;
	    $atval =~ s/^\"(.*)\"$/$1/;
	    $$attrhash{$atname} = defined($atval) ? $atval : 1;
	    if ($4) {		# list entry
		# digest list-valued attribute here.
		if ($atval =~ /^\s*\((\s*\"[^\"]*\",?)*\s*\)\s*$/) {
		    my @vals = $atval =~ /\"([^\"]*)\"/g;
		    my $hash = @vals && +{ map { ($_, 1) } @vals };
		    $$attrhash{"${atname}HASH"} = $hash
			if $hash;
		}
	    }
	}
	# special notice for INCLUDE
	warn "INCLUDE attribute (for field $name) must be a list of " .
	    "double-quoted strings."
		if ($$attrhash{'INCLUDE'} && !$$attrhash{INCLUDEHASH});
	$fields{$name} = [$collist, $attrhash];
	$lines = '';
    }
    return { %fields };
}

sub read_instructions 
{
    my $parser = shift;

    my $line;
    my $instrs = {};
  INSTRUCTION:
    while ($line = $parser->readline()){
	next if $line =~ /^\s*$/;
	last if $line =~ /^\s*end\s*$/i;
	if ($line =~ /^\s*(\w+)\s+master\s+of\s+(\w+)/i) {
	    push (@{$$instrs{MASTERS}}, [$1, $2]);
	}
	elsif ($line =~ /^\s*(before|after)\s+((\w+)\s+)+of\s+(\w+)\s*$/){
	    # control block
	    my $when = $1;
	    my $ops = $2;
	    my $col = $4;
	    my $action;
	    while ($action = $parser->readline()) {
		last if $action =~ /^\s*$/;
		last INSTRUCTION if $action =~ /^\s*end\s*$/i;
		my @action;
		if ((@action = $action =~ /(let)\s+(\w+)\s*=\s*(\w+)\s*(\+)\s*(\w+)/i) ||
		    (@action = $action =~ /(nextfield)\s*=\s*(\w+)/i)) {
		    $action[0] = lc($action[0]);
		    my $actionref = [ @action ];
		    while ($ops =~ /(\w+)/g) {
			my $op = $1;
			push (@{$$instrs{CONTROLS}{$col}{$op}{$when}},
			      $actionref);
		    }
		}
		else {
		    warn "Unrecognized control block action: $action";
		    warn "(only let field = field + field  and  nextfield = field"
			." are supported at this time)";
		}
	    }
	}
	else {
	    warn "Unrecognized instruction line:\n$line\n";
	}
    }
    return $instrs;
}
	
	   
    

sub outputstring
{
    my $db = shift;
    my $screens = shift;
    my $tables = shift;
    my $attrs = shift;
    my $instrs = shift;

    my $form = { db => $db, screens => $screens,
		 tables => $tables, attrs => $attrs,
	         instrs => $instrs };
    my @strs = Data::Dumper->Dump([$form], ['form']);
    return join ($/, 'our $form;', @strs);
}

=head2 digest_file

digest_file  input_filename  [output_filename]

Reads the perform spec file, and writes a Perl Perform Spec file 
with the same basename but extension .pps unless an output filename
is explicitly provided.  Calls "digest" in this package to do the
work.

It's a little clumsy, but one can do a command-line "digestion" by:
 perl -MDBIx::Informix::Perform::DigestPer -e'digest_file "foo.per"' .
Maybe a top-level Perl or shell script should be made for this purpose.

=cut

sub digest_file
{
    my $infile = shift;
    my $outfile = shift;

    unless ($outfile ) {
	$outfile = $infile;
	$outfile .= ".pps"
	    unless $outfile =~ s/\..*$/.pps/;
    }

    open (IN, "< $infile")
	or die "Couldn't open '$infile' for reading: $!";
    open (OUT, "> $outfile")
	or die "Couldn't open '$outfile' for writing: $!";

    my ($str) = digest(*IN);
    print OUT $str;
    print OUT "\n1;\n";		# let it be require'd 
    close(OUT);
}

    



#  Our little word muncher...
package DBIx::Informix::Perform::DigestPer::Parser;

sub new 
{
    my $class = shift;
    my $ioh = shift;

    my $self = bless {}, $class;
    $self->{'ioh'} = $ioh;
    $self->{'tail'} = '';
    return $self;
}

# maybe "read token" would be a better description for this...
sub readword
{
    my $self = shift;
    my $accept_header_word = shift;

    my ($ioh, $tail) = @$self{'ioh','tail'};

    do {
	my ($word) = $tail =~ /(\w+|[^\w\s]+)/;
	if ($word) {
	    return undef
		if $DBIx::Informix::Perform::DigestPer::HEADING_WORDS{lc($word)} &&
		    lc($word) ne 'end' &&
			! $accept_header_word;
	    $self->{'tail'} = $';
	    return $word;
	}
	$tail = <$ioh>;
	chomp $tail;
	$self->{'tail'} = $tail;
    }
    while (defined($tail));
    return undef;
}

sub unread_word {
    my $self = shift;
    my $word = shift;

    $self->{'tail'} = $word . $self->{'tail'};
}

sub readline
{
    my $self = shift;
    my $accept_heading_word = shift;

    my $tail = $self->{'tail'};
    return undef if $tail =~ /^\s*(\w+)\s*$/ &&
	$DBIx::Informix::Perform::DigestPer::HEADING_WORDS{lc($1)} && lc($1) ne 'end' &&
	    !$accept_heading_word;
    $self->{'tail'} = '';
    return $tail if ($tail =~ /\S/);
    my $ioh = $self->{'ioh'};
    my $line = <$ioh>;
    return undef unless defined($line);
    chomp $line;
    return (($self->{'tail'} = $line) && undef)
	if $line =~ /^\s*(\w+)\s*$/ &&
	    $DBIx::Informix::Perform::DigestPer::HEADING_WORDS{lc($1)} && lc($1) ne 'end' &&
		!$accept_heading_word;
    return $line eq '' ? ' ' : $line;
}



1;

