# FIX_ME get a better name for this.
use 5.6.0;
package DBIx::Informix::Perform::DoTable;

use strict;
use DBIx::Informix::Perform::DButils 'open_db';
use Exporter;

use base 'Exporter';

our $DB;
our @EXPORT_OK = qw(generate_per);

sub generate_per
{
    my $db = shift;
    my $table_name = shift;

    $DB = open_db($db);
    if (0)			# Don't think we really need this...
    { 
	local ($DB->{'RaiseError'},$DB->{'PrintError'}) = (1, 0);
	my $tblh = eval {$DB->table_info('', '%', $table_name, 'TABLE') };
	$tblh ||=    eval { $DB->table_info('', "'%'", $table_name, 'TABLE')};
	my $tblrows = $tblh->fetchall_arrayref({}); # the {} means return hashes.
	my @tblrows = grep { $_->{'TABLE_NAME'} eq $table_name ||
				 $_->{'relname'} eq $table_name}    @$tblrows;
	if (@tblrows > 1) {
	    print STDERR "Please select one table the following:\n";
	    foreach (@tblrows) {
		print STDERR "   ", $_->{'TABLE_NAME'}, $/;
	    }
	    return undef;
	}
    }

    my $colh;
    {
	local ($DB->{'RaiseError'},$DB->{'PrintError'}) = (1, 0);
	# Work around DBD::Pg breakage with wildcards
	$colh = eval {$DB->column_info('', '%', $table_name, '%')}  ||
	    eval {$DB->column_info('', "'%'", $table_name, "'%'")};
    }
    my $colrows = $colh->fetchall_arrayref({});	# {} for row hashes.
    my @colrows = @$colrows;
    my $maxlen = 0;		# length of name, that is.
    grep { my $l = length($_->{'COLUMN_NAME'});
	   $l > $maxlen && ($maxlen = $l) }
      @colrows;
    my $defsize = 75 - $maxlen;
    my $buf = "database $db\n\nscreen\n{\n";
    my $fxxx = "f000";		# Field name counter for roomy fields
    my $ax = "a0";		# Field name counter for short fields
    my $b = "b";		# Field name counter for VERY short fields.
    my @attrs;			# attributes section listings.
    foreach my $col (@colrows) {
	my ($cname, $size, $type)  =
	    @$col{'COLUMN_NAME', 'COLUMN_SIZE', 'DATA_TYPE'};
	if (!defined($size) || $size < 0) {
	    if ($type =~ /char/i) {
		$size = ($$col{'atttypmod'} && $$col{'atttypmod'} - 4)  ||
		    #  other database-specific heuristics here...
		    $defsize;
	    }
	    elsif ($type =~ /date/i) {
		$size = 10;	# e.g. 01-02-2000
	    }
	    elsif ($type =~ /bool/i) {
		$size = 1;
	    }
	    else {
		$size = $defsize;
	    }
	}
	my $fieldname =
	    $size >= 4 ? $fxxx++ :
		$size >= 2 ? $ax++ :
		    $b++;
	my $fnpadding = ' ' x ($size - length($fieldname));
	my $cnpadding = ' ' x ($maxlen - length($cname));
	$buf .=  " $cname:$cnpadding" . " [" . $fieldname . $fnpadding . "]\n";
	push (@attrs,  "    $fieldname = $table_name.$cname;\n");
    }				#  foreach
    $buf .= "}\nend\n\n";
    $buf .= "tables\n\t$table_name\n\n";
    $buf .= "attributes\n" . join('', @attrs) . "\nend\n\n";
    return $buf;
}
