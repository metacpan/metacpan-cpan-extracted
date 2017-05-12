package DBIx::HTMLTable;
$VERSION=0.24;

@EXPORT_OK=qw(&HTMLTable &HTMLTableByRef);

# Table Options
my @options = qw(caption nullfield rs fs);

# HTML 4.0 attributes for table tag.
my @tableattribs = qw(align width cols id class dir title 
		      style onclick ondbclick onmousedown
		      onmouseup onmouseover onmousemove 
		      onmouseout onkeypress onkeydown 
		      onkeyup bgcolor frame rules border 
		      cellspacing cellpadding);

my $nullfield = '&nbsp;';
my $rs = "\n";
my $fs = ",";

sub HTMLTable {
  my ($data, @args) = @_;
  my ($i, $j, @cols, @theads, @trows, $thead,$topdatarow);
  &table_opts (@args);
  my @rows = split /$options->{rs}/, $data;
  @cols = split /$options->{fs}/, $rows[0];
  $thead = $rows[0];

  my $cols = $#cols;

  my $table = &table_tag;
  print $table."\n";
  print qq|<colgroup>\n|;
  foreach my $row (@rows) {
  print qq|<tr>\n|;
  my @trow = split /\,/, $row;
  foreach my $col (@trow) {
      print qq|<td>|;
      if ($col and length $col) {
	  print $col;
      } else {
	  print $options->{nullfield};
      }
      print qq|</td>\n|;
  }
  print qq|</tr>\n|;
  }
  print qq|</colgroup>\n|;
  print qq|</table>\n|;
}

sub HTMLTableByRef {
    my $dataref = $_[0];
    my $opts = $_[1];
    my ($newopts,$newattribs) = &table_opts ($opts);
    my ($i, $j, $nrows, $ncols, @rows);

    foreach (@$dataref) { push @rows, $_ }

    $nrows = $#rows;
    $ncols = scalar @{$rows[0]};

    my $table = &table_tag ($newattribs);
    print $table."\n";

    if (length $newopts->{caption}) {
	print qq|<caption>$newopts->{caption}</caption>\n|;
    }

    print qq|<colgroup>\n|;

    for ( $i = 0; $i <= $nrows; $i++ ) {
      print qq|<tr>\n|;
      for ( $j = 0; $j < $ncols; $j++ ) {
	  if ( not ${$rows[$i]}[$j]  or (${$rows[$i]}[$j] eq '') ) {
            ${$rows[$i]}[$j] = '&nbsp';
          }
	  print "<td>".${rows[$i]}[$j]."</td>\n";
      }
      print qq|</tr>\n|;
  }

  print qq|</colgroup>\n|;
  print qq|</table>\n|;
}

sub table_tag {
    my ($attribs) = @_;
    my $tag = '<table ';
    foreach my $attrib (keys %$attribs) {
	$tag .= ' '.$attrib."\=\"".$attribs->{$attrib}."\"";
    }
    $tag .= '>';
}

# All this does is check that options and attrbutes are valid.
sub table_opts {
    my ($args) = @_;
    my (%newopts,%newattribs);
    foreach my $key (keys %$args) {
	foreach my $opt (@options) {
	    if ($key =~ /$opt/) {
		$newopts{$key} = $args->{$key};
		last;
	    }
	}
    }
    foreach my $key (keys %$args) {
	foreach my $attrib (@tableattribs) {
	    if ($key =~ /$attrib/) {
		$newattribs{$key} = $args->{$key};
		last;
	    }
	}
    }
    return \%newopts, \%newattribs;
}

1;
__END__;

=head1 NAME 

   HTMLTable - Create HTML table from DBI query output.

=head1 SYNOPSIS

    use DBIx::HTMLTable;

    HTMLTable ($data, <options>);

    HTMLTableByRef ($dataref, <options>);

=head1 DESCRIPTION

HTMLTable() formats the results of a DBI query as a HTML table.  The
first argument is the query output formatted as a multi-line string,
with columns delimited by a field separator (a comma by default) and
rows delimited by a record separator (newline by default).  The second
argument is a hash of options and table attributes.  Options and
attributes are described below.

    &DBIx::HTMLTable::HTMLTable ($data, 
				{rs => "\n",
                                fs => ',',
				caption => "Caption Text"});

HTMLTableByRef() takes as its first argument a reference to an array of
array references, as returned by DBI's fetchall_arrayref() and similar
functions.  As with HTMLTable(), the second argument is a hash of valid
options and attributes.

  $tableref = $dbh -> selectall_arrayref( "SELECT \* FROM $db" );
  HTMLTableByRef ($tableref, 
                  {bgcolor => 'white',
                   caption => "$db SELECT Query",
                   border => 2,
                   width => 300});

The file eg/tablequery.cgi is an example CGI script that formats
query output for viewing in a Web browser.

=head1 OPTIONS

Options determine how to interpret data and how to
construct tables.

=over 4

=item rs

HTMLTable only.  Character delimiter for data rows.

=item fs 

HTMLTable only.  Character delimiter for data columns.

=item caption

If the value of this option is a non-empty string, formats
the string as the table's caption.

=back

=head1 TABLE ATTRIBUTES

The following is a brief list of attributes that the HTML 4.0 <TABLE>
tag recognizes.  Refer to the HTML 4.0 specification
(http://www.w3.org/) for detailed information about each attribute.

=over 4

=item align 

=item width 

=item cols 

=item id 

=item class 

=item dir 

=item title

=item style

=item onclick

=item ondbclick

=item onmousedown

=item onmouseup

=item onmouseover

=item onmousemove

=item onmouseout

=item onkeypress

=item onkeydown 

=item onkeyup

=item bgcolor

=item frame

=item rules

=item border

=item cellspacing

=item cellpadding

=back

=head1 VERSION

Version 0.24

=head1 COPYRIGHT

Copyright © 2001-2004 Robert Kiesling, rkies@cpan.org.

Licensed using the same terms as Perl.  Refer to the file,
"Artistic," for information.

=head1 AUTHOR

Robert Kiesling, rkies@cpan.org

=head1 SEE ALSO

DBI(3)

=cut
  
