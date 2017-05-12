# --*-Perl-*--
# $Id: BP.pm 25 2005-09-17 21:45:54Z tandler $
#

=head1 NAME

Biblio::BP - Package Frontend for bp (Perl Bibliography Package)

=head1 SYNOPSIS

  use Biblio::BP;

=head1 DESCRIPTION

well, I guess it\'s better if you check the source or the original docs
for now .... sorry ... ;-)

=cut

package Biblio::BP;
use 5.006;
#no strict;  # for strange AUTOLOAD method call ...
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 25 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use YYYY;
#use vars qw(@ISA);
#@ISA = qw(YYYY);
## now: use base YYYY

# used modules
use FileHandle;
use File::Basename;
use File::Spec;

# used own modules
use Biblio::Util;

# module variables
#use vars qw(mmmm);

#
#
# module initialization
#
#
BEGIN {
	if( defined $ENV{'BPHOME'} ) {
		unshift(@INC, $ENV{'BPHOME'});
	} else {
		my $dir = $INC{'Biblio/BP.pm'};
		die("Cannot find Biblio/BP.pm in %INC") unless $dir;
		$dir = File::Spec->catdir(dirname($dir), 'bp', 'lib');
		die("Cannot find the bp/lib directory of the Biblio::BP module in $dir")
			unless -d $dir;
		unshift @INC, $dir;
	}
	require "bp.pl";
}


# set some useful defaults ...
# automatically detect format:
Biblio::BP::format("auto");
# print warnings, exit on errors:
Biblio::BP::errors("print", "exit");

=head1 METHODS

=over

=cut

#
#
# export to file
#
# the caller should set the output format before calling export.
#

=item $no_items = export($outfile, $refs)

=cut

sub export {
	my ($outfile, $refs) = @_;
	print STDERR 'exporting ', scalar(keys %$refs), " references\n";
	if( ! Biblio::BP::open('>' . $outfile) ) {
		print STDERR "Could not open $outfile for writing\n";
		return undef;
	}
	#print Dumper $refs->{'CACM.CFW-LessonsLearned'};
	foreach my $refID (keys(%$refs)) {
		my $ref = $refs->{$refID};
		print STDERR "$refID - ";
		#  print Dumper $ref;
		
		# convert entries from pbib to bp's canon format
		my %can = Biblio::BP::pbib_to_canon(%{$ref});
		
		# convert from canon to output format and implode
		#  to a single string replresentation
		my $record = Biblio::BP::implode(Biblio::BP::fromcanon(%can));
		#  print STDERR "$record\n";
		Biblio::BP::write($outfile, $record);
	}
	
	Biblio::BP::close('>' . $outfile);
	
	print STDERR "\ndone";
	Biblio::BP::print_error_totals();
	print STDERR "\n";
	return scalar(keys %$refs);
}


#
#
# import & convert from pbib to bp canon format
#
#

=item $refs = import($args, @files)

 $args = {
	-category => 'default-category',
	-citekey => 1 # create new canonical citekey
	}

=cut

sub import {
	my ($args, @files) = @_;
	my $default_category = $args->{'-category'};
	my $create_citekey = $args->{'-citekey'};

	Biblio::BP::format("auto", "canon:8859-1");
	my ($informat, $outformat) = Biblio::BP::format();
	print STDERR "Using bp, version ", Biblio::BP::doc('version'), ".\n";
	print STDERR "Reading: $informat  Writing: $outformat\n";
	print STDERR "Default category: $default_category\n" if $default_category;
	print STDERR "\n";

	my ($fmt, $lastfmt);
	my ($ref, $rn, @refs); $rn=0;
	foreach my $file (@files) {
		print STDERR "Import $file ...\n";
		$fmt = Biblio::BP::open($file);
		next unless defined $fmt;
		while ( defined($ref = Biblio::BP::readpbib(undef, undef, $default_category)) ) {
		$rn++;
		print $ref->{'CiteKey'}, "\n";
		#  print Dumper $ref;
		if( $create_citekey || $ref->{'CiteKey'} =~ /^\d+$/ ) {
			my $key = Biblio::Util::defaultCiteKey($ref, $create_citekey);
			print "-> $key\n";
			$ref->{'CiteKey'} = $key;
		}
		push @refs, $ref;
	}
	print STDERR "$rn records read from $file";
	Biblio::BP::print_error_totals();
	print STDERR ".\n";
	Biblio::BP::close();
	return \@refs;
}




}

#
#

our @nameFields = qw/
	Authors
	Editors
	AuthorPseudonym
	/;

### unused??
our %aliasFields = qw/
	Author	Authors
	Editor	Editors
	/;

### unused??
our %aliasCiteTypes = qw/
	techreport	report
	/;


our %pbibFields = qw(
	bibdate		BibDate
	bibsource	BibSource
	bibnote	BibNote
	category	Category
	citealias	CiteAliases
	citealiases	CiteAliases
	crossref	CrossRef
	xref		CrossRef
	origcitetype	OrigCiteType
	pbibcitetype	PBibCiteType
	identifier	Identifier
	file		File
	pbibnote	PBibNote
	isbn		ISBN
	issn		ISSN
	url			Source
	pdf			PDF
	html		HTML
	ps			PS
	source		SourceType
	recommendation	Recommendation
	email		AuthorEMail
	project		Project
	subject		Subject
	accessmonth	AccessMonth
	accessyear	AccessYear
	doi			DOI
	abstract	Abstract
	);

# "-" -> Range, i.e. can contain "--" etc.
# "*" -> List, separated by "," or ";"
### not yet used ....
our %pbibFieldTypes = qw(
	AuthorEMail		EMail*
	AuthorURL		URL*
	Authors			Name*
	BibDate			Date
	BibSource		URL*
	DOI				URL
	Editors			Name*
	Pages			String-*
	PDF				URL*
	Source			URL*
	);

=item $rec = readpbib($file, $format, $default_category)

read a record from the current bp input file (via BP::read()) and
convert it to a pbib compliant paper hash reference
(or undef for EOF)

=cut

sub readpbib {
	my ($file, $format, $default_category) = @_;
	my ($record, $rn, %rec);
	$file = $bib'glb_Ifilename unless defined $file;
	$record = Biblio::BP::read(@_);
	unless( defined $record  ) { return undef; }
	
	chop $record;
	%rec = Biblio::BP::explode($record);
	%rec = Biblio::BP::tocanon(%rec);

#	print $rec{'CiteKey'}, "\n";

	# convert Authors field etc. from canon to pbib format
	%rec = Biblio::BP::canon_to_pbib(%rec);
	
	# ... BibDate/BibSource field
	if(  ! defined $rec{'BibDate'}  ) {
	  $rec{'BibDate'} = localtime();
	}
	#  if(  ! defined $rec{'BibSource'}  ) {
	  #  $rec{'BibSource'} = $file;
	#  }
	# ... Category field
	if(  ! defined $rec{'Category'}  && defined $default_category) {
	  $rec{'Category'} = $default_category;
	}
	
	#### ???
	if( defined $ref{'PBibNote'} ) {
		delete $ref{'PBibNote'};
	}
	
	# ... remove abstract ...
	if( defined $rec{'Abstract'} ) {
		# it's simply too long for my stupid databse ...
		delete $rec{'Abstract'};
	}

	return \%rec;
}


my %pbib_to_canon_types = qw(
	booklet		book
	collection		book
	conference	inproceedings
	incollection	inbook
	journal		article
	masterthesis	thesis
	phdthesis		thesis
	techreport		report
	email		misc
	video			misc
	speech		misc
	talk			inproceedings
	poster		inproceedings
	patent		misc
	avmaterial		misc
	web			misc
	);

=item %rec = pbib_to_canon(%rec)

Convert pbib record to bp's canon format

=cut

sub pbib_to_canon {
	my (%rec) = @_;
	
	# Institution --> Organization
	if( $rec{'Institution'} && ! $rec{'Organization'} ) {
		$rec{'Organization'} = $rec{'Institution'};
		delete $rec{'Institution'};
	}
	
	# convert names
	foreach my $f (@nameFields) {
		next unless $rec{$f};
		$rec{$f} = Biblio::BP::Util::mname_to_canon($rec{$f});
	}
	
	### convert new CiteTypes:
	### patent, phdthesis, masterthesis, incollection, web, techreport, ...
	my $CiteType = $rec{'CiteType'};
	if( defined $CiteType ) {
		if( defined $pbib_to_canon_types{$CiteType} ) {
			# unsupported bp type
			$rec{'PBibCiteType'} = $CiteType;
			$rec{'CiteType'} = $pbib_to_canon_types{$CiteType};
		}
		
		# adapt fields for techreport
		if( $CiteType =~ /report$/ && ! defined $rec{'ReportNumber'} ) {
			$rec{'ReportNumber'} = $rec{'Number'};
			delete $rec{'Number'};
		}
		
		# adapt fields for thesis
		if( $CiteType eq 'phdthesis' && ! defined $rec{'ReportType'} ) {
			$rec{'ReportType'} = 'Ph.D. thesis';
		}
		if( $CiteType eq 'masterthesis' && ! defined $rec{'ReportType'} ) {
			$rec{'ReportType'} = 'masterthesis';
		}
	} else {
		$rec{'CiteType'} = 'inproceedings';
	}
	
	return %rec;
}

=item %rec = canon_to_pbib(%rec)

Convert record in bp's canon format to pbib's format.

=cut

sub canon_to_pbib {
	my (%rec) = @_;

	# ... lower case field names
	foreach my $f (keys %pbibFields) {
	  if( defined $rec{$f} && ! defined $rec{$pbibFields{$f}} ) {
	    $rec{$pbibFields{$f}} = $rec{$f};
	    delete $rec{$f};
	  }
	}

	# ... Name format
	##### ToDo: check, if the pbib quoted format needs to be used
	##### e.g. /Da Campo/Sandra/
	foreach my $f (@nameFields) {
		next unless $rec{$f};
		$rec{$f} = Biblio::BP::Util::canon_to_name($rec{$f}, 'plain');
#print "\n$f = $rec{$f}\n\n";
	}
	
	# ... char set & bp's meta stuff
	#  foreach my $f (keys(%rec)) {
		#  hm.
	#  }
	Biblio::BP::format("canon:canon", "canon:utf8");
	%rec = Biblio::BP::fromcanon(%rec); # e.g. to convert the charset
	
	# ... CiteType
	if( ! defined $rec{'PBibCiteType'} && defined $rec{'OrigCiteType'} ) {
		$rec{'PBibCiteType'} = $rec{'OrigCiteType'};
		delete $rec{'OrigCiteType'};
	}
	###### ToDo: check for "OrigCiteType" field & adapt CiteType
	if( defined $rec{'PBibCiteType'} ) {
		$rec{'CiteType'} = $rec{'PBibCiteType'};
		delete $rec{'PBibCiteType'};
	}

	### temp only!!!!
	###### --> move to Biblio::Database!
	if( defined($rec{'PBibNote'}) ) {
		my @fields = split(/\r?\n/, $rec{'PBibNote'});
#print STDERR $rec{'CiteKey'}, $rec{'PBibNote'}, "\n";
		#my $dump =0;
		my @notes;
		foreach my $f (@fields) {
			if( $f =~ /^([a-z]+)=\s*(.*)\s*$/i ) {
				$rec{$1} = $2; #$dump = 1;
			} else {
				push @notes, $f;
			}
		}
		if( @notes ) {
			$rec{'PBibNote'} = join("\n", @notes);
		} else {
			delete $rec{'PBibNote'};
		}
		#print Dumper \%rec if $dump;
	}

	return %rec;
}

=back

=cut

#
#
# some additional helper functions
#
#
#### --> maybe move this to Biblio.pm or (better?) directly to bp.pl ....!
#
#


sub querySupportedFormats {
	my ($fmts, $csets) = bib::find_bp_files();
	return split(/\s+/, $fmts);
}

sub querySupportedCharsets {
	my ($fmts, $csets) = bib::find_bp_files();
	return split(/\s+/, $csets);
}




our ($logfilename, $loglevel, $logfilehandle);
$loglevel = $bib::opt_default_debug_level;

sub logfilename {
  if( @_ ) {
    $logfilename = $_[0];
	$logfilehandle = undef;
	$loglevel = $_[1] if defined($_[1]);
  }
  return $logfilename;
}
sub logs {
  print STDERR @_, '\n';
  return unless defined($logfilename);
  # open logfile
  unless( defined($logfilehandle) ) {
    $logfilehandle = new FileHandle(">$logfilename")
	  or Biblio::BP::goterror("Can't open logfile $logfilename for writing");
  }
  print $logfilehandle @_, '\n';
}

sub debugs {
  my ($statement, $level, $mod) = @_;
  if( defined($level) && $loglevel ) {
    if( $loglevel == 1 || $level > $loglevel ) {
	  logs($statement);
	}
  }
  return bib::debugs($statement, $level, $mod);
}

sub goterror {
  my($error, $linenum) = @_;
  logs("error: $error");
  return bib::goterror($error, $linenum);
}

sub gotwarn {
  my($warn, $linenum) = @_;
  logs("warning: warn");
  return bib::gotwarn($warn, $linenum);
}

sub print_error_totals {
	my ($w, $e) = Biblio::BP::errors('totals');
	$w && print STDERR (($w == 1) ? " (1 warning)" : " ($w warnings)");
	$e && print STDERR (($e == 1) ? " (1 error)"   : " ($e errors)");
}

#
#
# bp methods
#
#

use vars qw($AUTOLOAD);
sub AUTOLOAD {
#  my $self = shift;
  my ($method) = $AUTOLOAD;
  my (@parameters) = @_;
  $method =~ s/.*:://;
  $method = "bib'$method";
  &bib'debugs("call method $method", 2);
#print "self = $self call <$method> args: <@parameters>\n";
  &$method(@parameters);
}


package Biblio::BP::Util;

#
#
# bp_util methods
#
#

use vars qw($AUTOLOAD);
sub AUTOLOAD {
  my ($method) = $AUTOLOAD;
  my (@parameters) = @_;
  $method =~ s/^.*:://;
  $method = "bp_util'$method";
  &bib'debugs("call method $method", 2);
#print "call <$method> args: <@parameters>\n";
  &$method(@parameters);
}


1;


__END__

=head1 EXPORT

#
#
# Major functions available for users to call:
#
#
#    format();
#    format($format);
#    format($input_format, $output_format);
#
#    open($file_name);
#    open($file_name, $format);
#
#    close();
#    close($file_name);
#
#    read();
#    read($file_name);
#    read($file_name, $format);
#
#    write($file, $output_string);
#    write($file, $output_string, $format);
#
#    convert($record);
#
#    explode($record);
#    explode($record, $file_name);
#
#    implode(%record);
#    implode(%record, $file_name);
#
#    tocanon(%record);
#    tocanon(%record, $file_name);
#
#    fromcanon(%record);
#    fromcanon(%record, $file_name);
#
#    clear();
#    clear($file_name);
#
#           [ file bp-p-option ]
#
#    stdargs(@ARGV)
#
#    options($general_opts, $converter_opts, $infmt_opts, $outfmt_opts);
#
#    doc($what);
#
#
# Functions available primarily for modules to call:
#
#
#    parse_format($format_string)
#
#           [ file bp-p-debug ]
#
#    panic($string);
#
#    debugs($statement, $level);
#    debugs($statement, $level, $module);
#
#    check_consist();
#
#    debug_dump($what_kind);
#
#    ok_print($variable);
#
#           [ file bp-p-errors ]
#
#    errors($warning_level);
#    errors($warning_level, $error_level);
#    errors($warning_level, $error_level, $header_string);
#
#    goterror($error_message);
#    goterror($error_message, $linenum);
#
#    gotwarn($warning_message);
#    gotwarn($warning_message, $linenum);
#
#           [ file bp-p-dload ]
#
#    load_format($format_name);
#
#    load_charset($charset_name);
#
#    load_converter($converter_name);
#
#    find_bp_files();
#    find_bp_files($rehash);
#
#    reg_format($long_name, $short_name, $pkg_name, $charset_name, @info);
#
#           [ file bp-p-cs ]
#
#    unicode_to_canon($unicode);
#
#    canon_to_unicode($character);
#
#    decimal_to_unicode($number);
#
#    unicode_to_decimal($unicode);
#
#    unicode_name($unicode);
#
#    meta_name($metacode);
#
#    meta_approx($metacode);
#
#    unicode_approx($unicode);
#
#    nocharset($string);
#
#           [ file bp-p-util ]
#
#    bp_util'mname_to_canon($names_string);
#    bp_util'mname_to_canon($names_string, $flag_reverse_author);
#
#    bp_util'name_to_canon($name_string);
#    bp_util'name_to_canon($name_string, $flag_reverse_author);
#
#    bp_util'canon_to_name($name_string);
#    bp_util'canon_to_name($name_string, $how_formatted);
#
#    bp_util'parsename($name_string);
#    bp_util'parsename($name_string, $how_formatted);
#
#    bp_util'parsedate($date_string);
#
#    bp_util'canon_month($month_string);
#
#    bp_util'genkey(%canon_record);
#
#    bp_util'regkey($key);
#


=head1 AUTHOR

Biblio::BP frontend by Peter Tandler (pbib@tandlers.de)

# The bp package is written by Dana Jacobsen (dana@acm.org).
# Copyright 1992-1996 by Dana Jacobsen.
#
# Permission is given to use and distribute this package without charge.
# The author will not be liable for any damage caused by the package, nor
# are any warranties implied.

=head1 SEE ALSO

L<bp>.

=head1 HISTORY

$Log: BP.pm,v $
Revision 1.14  2003/06/12 22:15:52  tandler
improved canon <-> pbib conversion
new querySupportedFormats() querySupportedCharsets()
readpbib() gets format as parameter

Revision 1.13  2003/05/19 13:05:37  tandler
small fixes. don#t use "no strict;" I hope this works as well.

Revision 1.12  2003/04/14 09:43:14  ptandler
import

Revision 1.11  2003/02/20 09:24:52  ptandler
added bibtex fields "project" and "subject"

Revision 1.10  2003/01/27 21:11:31  ptandler
some pod comments

Revision 1.9  2003/01/14 11:06:45  ptandler
support for export using BP

Revision 1.8  2002/11/05 18:27:13  peter
print error totals
convert CiteType from pbib to bp-canon

Revision 1.7  2002/11/03 22:13:06  peter
OrigCiteType & PBibNote handling

Revision 1.6  2002/09/23 11:05:26  peter
default category

Revision 1.5  2002/09/11 10:44:12  peter
BP::readpbib

Revision 1.4  2002/08/22 10:39:19  peter
- include bp_util as BP::Util subs
- some support for conversion between bp's canon and pbib-format

Revision 1.3  2002/06/03 11:39:20  Diss
start work on gotwarn/goterror etc. not really finished ...

Revision 1.2  2002/03/28 13:23:00  Diss
added pbib-export.pl, with some support for bp

Revision 1.1  2002/03/24 18:54:49  Diss
interface to the bp package ... seems to work somehow ...


=cut