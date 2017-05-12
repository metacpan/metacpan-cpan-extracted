# --*-Perl-*--
# $Id: PBib.pm 24 2005-07-19 11:56:01Z tandler $
#

=head1 NAME

PBib::PBib - Something like BibTeX, but written in perl and designed to be extensible in three dimensions: bibliographic databases (e.g. BibTeX, OpenOffice), document file formats (e.g. Word, RTF, OpenOffice), styles (e.g. ACM, IEEE)

=head1 SYNOPSIS

	use PBib::PBib;
	use Biblio::Biblio;
	my $bib = new Biblio::Biblio();
	my $pbib = new PBib::PBib('refs' => $bib->queryPapers());
	$pbib->convertFile($file);

=head1 DESCRIPTION

I wrote PBib to have something like BibTex for MS Word that can use a various sources for bibliographic references, not just BibTex files, but also database systems. Especially, I wanted to use the StarOffice bibliographic database.

Now, PBib can be extended in a couple of dimensions:

=over

=item - bibliographic styles

such as ACM style or IEEE style.

=item - document format

such as Plain text, (La)TeX, Word, RTF, OpenOffice

=item - bibliographic database format

such as bibtex, refer, tib, but also database systems with different mappings to database fields.

=back

=head1 QUICK START

=head2 SETUP BIBLIOGRAPHY DATABASE

Once you've installed the distribution you have to set up a bibliography database in order to start using PBib and PBibTk.

Several formats are supported:

=over

=item - Perl:DBI databases

You can configure the database schema to use, see F<conf/default.pbib>, F<conf/OOo-table.pbib> and some for DBMSs, see
F<conf/mysql.pbib>, F<conf/adabas.pbib>.
You can C<include> the files in your F<site.pbib> file if you are
using one of these systems.

=item - bibtex files

=item - several other file types that are supported by the bp package.

=back

I'd recommend to use a mysql database, this works fine for me.
See the config/sample user.pbib file for some examples.

You should specify your default settings in a user.pbib file, which is searched for at a couple of places, e.g. you home directory. (Check that the HOME environment variable on windows is set.) In case you want to provide defaults for your organization, use the local.pbib file.

You can adapt the mapping of PBib fields to DB fields, see file config/OOo-table.pbib for an example if you want to use a OpenOffice.org bibliography database.

No support is given to edit the bibliography database, as there are lots of tools around. Check docs/Edit_Bibliography.sxw for a OpenOffice.org document to edit a bibliography database. (That's the form that I use.) Ensure that it's attached to the correct database (Tools>>Data Sources, Edit>>Exchange Database).


=head2 CREATE INPUT DOCUMENTS

=over

=item Cite references

In your documents, use [[Cite-Key]] (Double brackets) to place references in the document. These will be replaced by PBib to a reference according to the selected style, e.g. (Tandler, 2004).

The CiteKey is the key defined in the bibliography database.

=item Generate the list of references used

Use [{}] as the place holder for the list of references.

=back

See L<PBib::Intro> for a more detailed description.
You can find sample files in the test folder F<t>.

=head2 Supported document formats

=over

=item - MS Word .doc, .rtf

.doc will be converted to .rtf before processing (requires MS Word to be installed)

=item - Plain Text

TeX input is currently handled as plain text, there is no specific style for TeX yet.

=item - OpenOffice .sxw

OpenOffice Text (.sxw) uses actually a zipped XML document. (You need the L<Archive::Zip> and L<XML::Parser> modules to use this.)

=back

Not yet supported:

=over

=item  LaTeX and TeX

Should generate s.th. similar to BibTeX. But wait, if you write with TeX, you can I<use> BibTeX!

For now, this is treated as plain text.

=item HTML

For now, this is treated as plain text.

At minimum, the correct character encoding should be ensured and 
some formatting for the References section.

=item XML

There is support for XML, but of course the generic XML support is very limited. Maybe, support DocBook, or provide an easy way to specify the tags to be used.

=back

=head2 RUN PBIB

Provided scripts as front ends for the modules:


bin/pbib.pl <<filename>>

Process an input document and write the converted output to a new file
called I<filename>C<-pbib.>I<ext>.


bin/PBibTk.pl [<<optional filename>>]

Open a Tk GUI that allows you to browse you bibliography database and browse the items referenced in your document.


=head1 SUCCESS STORIES ;-)

I've used PBib/PBibTk to format citations and generate the bibliography for my thesis and several other papers; 
in fact, I wrote it as I couldn't find another tool that matched my requirements. 
To get an idea of the scope that PBib can handle: My thesis references about 360 papers, there are >900 entries in the database, the thesis converted to a RTF file is about 50MB. Maybe, you want to have a look at 
L<http://elib.tu-darmstadt.de/diss/000506> or 
L<http://ipsi.fraunhofer.de/ambiente/publications/>.

The bibliographic database I used is available in BibTeX format at L<http://tandlers.de/peter/beach/> (with lots of HCI, CSCW, UbiComp references).


=head1 CONFIGURATION

You can configure PBib in a number of ways, e.g. using config files and 
environment variables. For detailed information, please refer to 
module L<PBib::Config>.

You can use a filename.pbib config file to specify specific configuration for a file.

=head2 Environment Variables

=over

=item PBIBDIR

The directory where the PBib scripts are located, e.g. /usr/local/bin.

=item PBIBPATH

Path to look for config files (and also styles), separated by ';'.

=item PBIBSTYLES

Path to look for PBib styles, separated by ';'.

=item PBIBCONFIG

Path to look for PBib config, separated by ';'.

=item HOME

If set, PBib looks for the user's personal config at 

=over

=item $HOME/.pbib/styles

=item $HOME/.pbib/conf

=item $HOME

=back

=item APPDATA

If set, PBib looks for the user's personal config at 

=over

=item $APPDATA/PBib/styles

=item $APPDATA/PBib/conf

=back

$APPDATA points on Windows XP to something like "C:\Documents and Settings\<<user>>\Application Data".

=back

=head2 Config Files

I<ToDo: Explain format of config files ...>, look at L<PBib::Config> and 
the exsamples provided with this distribution.


=head1 DEPENDENCIES

PBib itself consists of three packages that can be used independently:

=over

=item Biblio

Provides an interface to bibliographic databases. The main class is L<Biblio::Biblio>.

L<Biblio::File> uses L<Biblio::BP> and L<Biblio::Util> that encapsulate the "bp" package mentioned above.

=item PBib

Main functionality to process documents that contain references.

PBib uses the format for references returned by Biblio, so it's well designed to be used together. But, PBib can be used with any hash of references that contains the same keys.

The main class is L<PBib::PBib>. The main script is L<pbib.pl>.

=item PBibTk

PBibTk provides a GUI for PBib. It uses PBib and Biblio.

The main class is L<PBibTk::Main>. It is started with the script L<PBibTk.pl>.

=back

I've thought about deploying these as separate packages, but currently I believe that this way it's easier to install and use.

This module requires these other modules and libraries:

=over

=item bp

The Perl Bibliography Package "bp", by Dana Jacobsen (dana@acm.org) is used. An adapted version of it (with some bug fixes and 
enhancements) is included in this distribution.

In fact, bp is really helpful to generate the hashes with literature references from various sources.
Please check http://www.ecst.csuchico.edu/~jacobsd/bib/bp/ and the bp README located in F<lib/Biblio/bp/README>.

=item Config::General

by Thomas Linden <tom@daemon.de>

=item Archive::Zip and XML::Parser

for OpenOffice support.

=back


=cut

package PBib::PBib;
use 5.006;
use strict;
use warnings;
#use English;

use Time::HiRes qw(gettimeofday tv_interval);



BEGIN {
    use vars qw($Revision $VERSION);
	# SVN for generating version numbers is somehow strange ...
	# maybe there's a better way?
	my $major = 2; q$Revision: 24 $ =~ /: (\d+)/; my $minor = $1 - 10; $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
#use base qw(YYYY);

# used modules
#use FileHandle;
#use File::Basename;
use Data::Dumper;

# used own modules
use Biblio::BP;

use PBib::Config;

use PBib::Document;

use PBib::ReferenceConverter;
use PBib::ReferenceStyle;
use PBib::BibliographyStyle;
use PBib::BibItemStyle;
use PBib::LabelStyle;

# register extra reference converters
# the reference converters can extend the document classes 
# to specify a different converter.
##### use PBib::ReferenceConverter::MSWord; # to be able to convert word documents
##### PBib::ReferenceConverter::MSWord is not yet working ...



#  binmode(STDOUT, ":locale");
#  binmode(STDERR, ":locale");


=head1 METHODS

These methods are exported.

=over

=cut


#
#
# constructor
#
#

=item $conf = new PBib::PBib(I<options>)

Supported Options:

=over

=item refs


=item config


=item inDoc


=item outDoc


=back

=cut

sub new {
	my $self = shift;
	my $class = ref($self) || $self;
	my %args = @_;
#  foreach my $arg qw/XXX/ {
#    print STDERR "argument $arg missing in call to new $class\n"
#	unless exists $args{$arg};
#  }
	$self = \%args;
	return bless $self, $class;
}

#
#
# access methods
#
#

sub refs { return shift->{'refs'} || {}; }
sub inDoc { return shift->{'inDoc'}; }
sub outDoc { return shift->{'outDoc'}; }
sub config {
	my ($self) = @_;
	my $config = $self->{'config'};
	unless( $config ) {
		$config = new PBib::Config();
		$self->{'config'} = $config;
	}
	return $config;
}
sub beVerbose { my $self = shift; return $self->config()->beVerbose(); }
sub beQuiet { my $self = shift; return $self->config()->beQuiet(); }
sub options { my $self = shift; return $self->config()->options(@_); }
sub option { my ($self, $opt) = @_; return $self->options()->{$opt}; }

#
#
# processing of documents
#
#

=item $conv = $pbib->processFile($infile, $outfile, $config, $refs)

Calls convertFile() & optionally opens result in editor.

=cut

sub processFile {
	my ($self, $infile, $outfile, $config, $refs) = @_;
	$config = $self->config() unless defined $config;
	my $conv = $self->convertFile($infile, $outfile, $config, $refs, @_);
	return unless $conv;
	my $outDoc = $conv->outDoc();
	if( $outDoc && $config->option('pbib.showresult') ) {
		$outDoc->openInEditor();
	}
	return $conv;
}


#
#
# converting
#
#

=item $conv = $pbib->convertFile($infile, $outfile, $config, $refs)

If $infile (filename) is undef, inDoc (document) is used.

If $outfile (filename) is undef, outDoc (document) is used.

If $config or $refs is undef, the default values are used (the ones passed to the constructor).

The converter $conv is passed to the caller.

=cut

sub convertFile {
	my ($self, $infile, $outfile, $config, $refs) = @_;
	$config = $self->config() unless defined $config;
	$refs = $self->refs() unless defined $refs;
	
	my $start_time = [gettimeofday()];
	
	# create documents
	
	my $inDoc = $self->inDoc();
	my $outDoc = $self->outDoc();
	
	if( defined $infile ) {
		$inDoc = new PBib::Document(
			'filename' => $infile,
			'mode' => '<',
			'verbose' => $self->beVerbose(),
			'quiet' => $self->beQuiet(),
			%{$config->{doc} || {}},
			);
		if( ! defined $outfile ) {
			if( $infile =~ /\.(\w+)$/ ) {
				$outfile = $infile;
				$outfile =~ s/\.(\w+)$/-pbib\.$1/;
			} else {
				$outfile = "$infile-pbib";
			}
		}
	}

	if( defined $outfile ) {
		$outDoc = new PBib::Document(
			'filename' => $outfile,
			'mode' => '>',
			'verbose' => $self->beVerbose(),
			'quiet' => $self->beQuiet(),
			%{$config->{doc} || {}},
		);
	}
	
	print STDERR "convert ", $inDoc->filename(), "\nwrite ", $outDoc->filename(), "\n" unless $self->beQuiet();
	
	# read config
	my $options = $config->options('file' => $inDoc->filename());
	
	# create converter and styles
	
	#  print STDERR Dumper $options;
	my $rs = new PBib::ReferenceStyle(%{$options->{'ref'}||{}}, 'verbose' => $self->beVerbose());
	my $bs = new PBib::BibliographyStyle(%{$options->{'bib'}||{}}, 'verbose' => $self->beVerbose());
	my $is = new PBib::BibItemStyle(%{$options->{'item'}||{}}, 'verbose' => $self->beVerbose());
	my $ls = new PBib::LabelStyle(%{$options->{'label'}||{}}, 'verbose' => $self->beVerbose());
	my $conv = new PBib::ReferenceConverter(
		'inDoc'		=> $inDoc,
		'outDoc'	=> $outDoc,
		'refStyle'	=> $rs,
		'labelStyle'	=> $ls,
		'bibStyle'	=> $bs,
		'itemStyle'	=> $is,
		'refOptions' => $options->{'ref'},
		'bibOptions' => $options->{'bib'},
		'itemOptions' => $options->{'item'},
		'labelOptions' => $options->{'label'},
		'verbose' => $self->beVerbose(),
		'quiet' => $self->beQuiet(),
		);
	
	$conv->convert($refs);
	$inDoc->close();
	$outDoc->close();
	
	# remember values
	$self->{'inDoc'} = $inDoc;
	$self->{'outDoc'} = $outDoc;
	$self->{'refs'} = $refs;
	
	my $duration = tv_interval($start_time);
	logStatistics("$outfile.log", $conv, $options, $duration);
	return $conv;
}

=item logStatistics($logfile, $conv, $options, $duration)

Write log file.

=cut

sub logStatistics {
	my ($logfile, $conv, $options, $duration) = @_;

	open LOG, ">:utf8", $logfile;
	print LOG "pbib conversion statistics\n\n";
	
	if( ! defined $conv->inDoc() ) {
		print LOG "There was an error opening the input document.\n";
		close LOG;
		return;
	}
	print LOG "read ", $conv->inDoc()->filename(), "\n";
	print LOG "write ", $conv->outDoc()->filename(), "\n\n";

	my $messages = $conv->messages();
	if( $messages && @$messages ) {
		print LOG "\n\nMessages (", scalar(@$messages), " items)\n====\n\n";
		foreach my $item (@$messages) {
			print LOG "$item\n";
		}
	}
	
	my $todo = $conv->toDoItems();
	if( @$todo ) {
		print LOG "\n\nToDo (", scalar(@$todo), " items)\n====\n\n";
		print STDERR "\n\nToDo (", scalar(@$todo), " items)\n====\n\n" unless $options->{'quiet'};
		foreach my $item (@$todo) {
			my $text = "par $item->{'par'}: $item->{'text'}\n";
			print LOG $text;
			print STDERR $text unless $options->{'quiet'};
		}
	}
	
	my $unknownIDs = $conv->unknownIDs();
	if( @$unknownIDs ) {
		print LOG "\nCAUTION: ", scalar(@$unknownIDs), " unknown references found:\n",
			"===========================================\n\n";
		print STDERR "\nCAUTION: ", scalar(@$unknownIDs), " unknown references found:\n",
			"===========================================\n\n" unless $options->{'quiet'};
		foreach my $r (@$unknownIDs) {
			print LOG "$r\n";
			print STDERR PBib::ReferenceConverter::utf8_to_ascii("$r\n") unless $options->{'quiet'};
		}
	}
	
	my $foundInfo = $conv->foundInfo();
	print LOG "\n", scalar(keys(%$foundInfo)), " references found:\n",
		"===========================================\n\n";
	foreach my $r (keys(%$foundInfo)) { print LOG "$r ($foundInfo->{$r})\n"; }
	
	my $knownIDs = $conv->knownIDs();
	print LOG "\n", scalar(@$knownIDs), " references known:\n",
		"===========================================\n\n";
	foreach my $r (@$knownIDs) { print LOG "$r\n"; }

	if( $options ) {
		print LOG "\n\nOptions:\n";
		if( eval("use YAML; 1") ) {
			# use YAML if available
			print LOG Store($options);
		} else {
			print LOG Dumper($options);
		}
	}
	
	# $duration
	print STDERR "\ndone (", sprintf('%.2f', $duration), " seconds)\n" unless $options->{'quiet'};
	print LOG      "\ndone (", sprintf('%.2f', $duration), " seconds)\n";
	
	close LOG;
}


#
#
# scanning
#
#

=item $pbib->scanFile($infile, $config)

Returns the foundInfo for the $infile.

=cut

sub scanFile {
	my ($self, $infile, $config) = @_;
	my $inDoc = new PBib::Document(
		'filename' => $infile,
		'mode' => '<',
		'verbose' => $self->beVerbose(),
		'quiet' => $self->beQuiet(),
		%{$config->{doc} || {}},
		);
	my $conv = new PBib::ReferenceConverter(
		'inDoc'		=> $inDoc,
		'verbose' => $self->beVerbose(),
		'quiet' => $self->beQuiet(),
		);
	my $foundInfo = $conv->foundInfo();
	$inDoc->close();
	return $foundInfo;
}

=item \%foundIDs = $pbib->filterReferencesForFiles(@files)

Filter the known references to the ones used in @files, a hash reference is returned.
CrossRefs are also included (filterReferences() is used).

=cut

sub filterReferencesForFiles ($@) {
	my ($self, @files) = @_;
	my %foundIDs;
	
	while( my $file = shift(@files) ) {
		my $foundInfo = $self->scanFile($file);
		foreach my $id (keys(%$foundInfo)) {
			$foundIDs{$id} = 1;
		}
	}
	return $self->filterReferences(\%foundIDs);
}

=item $pbib->filterReferences($filter_refs)

Scan the passed refs for the known ones, return a new hash reference with all known references (including CrossRefs).

=cut

sub filterReferences ($$) {
	my ($self, $filter_refs) = @_;
	my $all_refs = $self->refs();
	my @filterIDs = keys(%$filter_refs);
	my %known_refs;
	my $id;
	
	while ($id = shift(@filterIDs)) {
		my $ref = $all_refs->{$id};
		if( ! defined($ref) ) {
			print STDERR "Unkown reference '$id'\n";
		} else {
			$known_refs{$id} = $ref;
			if( exists $ref->{'CrossRef'} ) {
				# if there is a CrossRef field, add all xref IDs
				# to the list of refs to export
				push @filterIDs, split(/,/, $ref->{'CrossRef'});
			}
		}
	}
	
	return \%known_refs;
}

1;


__END__

=back

=head1 AUTHOR

Peter Tandler <pbib@tandlers.de>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2005 P. Tandler

For copyright information please refer to the LICENSE file included in this distribution.

=head1 SEE ALSO

F<bin\pbib.pl>, F<bin\PBibTk.pl>

L<http://tandlers.de/peter/pbib/>
