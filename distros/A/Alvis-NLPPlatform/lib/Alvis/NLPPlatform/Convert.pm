package Alvis::NLPPlatform::Convert;

#  The name
# of the directory if defined, in the proirity order, from the variable
# C<SPOOLDIR> in the section C<CONVERTERS>, C<SPOOLDIR> in the section
# C<alvis_connection>. If any name can be determine, 

#     if (defined $config->{"CONVERTERS"}->{"SPOOLDIR"}) {
# 	$ODIR = $config->{"CONVERTERS"}->{"SPOOLDIR"};
#     } else {
# 	if (defined $config->{"alvis_connection"}->{"SPOOLDIR"}) {
# 	    $ODIR = $config->{"alvis_connection"}->{"SPOOLDIR"};
# 	} else {


use strict;
use warnings;
use utf8;
no utf8;

use Alvis::NLPPlatform::Document;
use File::MMagic;
use File::Basename;
use File::Path qw(mkpath);
use File::Touch;

use Data::Dumper;
use Cwd;

our $VERSION=$Alvis::NLPPlatform::VERSION;

sub load_MagicNumber
{
    my $config = shift;

    my $mm = new File::MMagic; # use internal magic file

    print STDERR "Loading complementary magic number ... ";
    
    open FILEM, $config->{"CONVERTERS"}->{"SupplMagicFile"} or die "No such file or directory\n";

    my $line;
    while($line = <FILEM>) {
	chomp $line;
	$line =~ s/\s*\#.*//;
	$line =~ s/^\s*//;
	
	if ($line ne "") {
	    $mm->addMagicEntry($line);
	}
    }
    print STDERR "done\n";

    return($mm);
}

sub conversion_file_to_alvis_xml
{

#    warn join("|", @_) . "\n";
    my $file = shift;
    my $AlvisConv = shift;
    my $config = shift;
    my $mm = shift;


    my $outfile = $config->{ALVISTMP} . "/" . basename($file) . ".out";
    my $infile = $file;
    my $outfile_path;

    my $outdata;
    
    my $type = &get_type_file($infile, $mm);

    if (($type !~ /xml/i) && ($type !~ /html/i)) {

	print STDERR "Conversion of file ...\n";

# 	print Dumper $config;
	
	if ((defined $config->{"CONVERTERS"}->{$type}) && ($config->{"CONVERTERS"}->{$type} ne "")) {
	    
	    print STDERR "Converting to HTML ...\n" ;
	    

	    my $commandline = $config->{"CONVERTERS"}->{$type} . " \"$infile\" > \"$outfile\"";
	    
	    warn "Convertion line : $commandline\n";
	    
	    `$commandline`;
	    
	    print STDERR "done\n";
	    return &conversion_file_to_alvis_xml($outfile, $AlvisConv, $config, $mm);
	} else {
	    print STDERR "No convertion to HMTL to do: already in HTML, unknown type or no specified converter\n";
	    return 0;
	    }
    } else {
	if ($type =~ /html/i) {
	    # calling Alvis convert
	    return &html2alvis($infile, $AlvisConv, $config);
	} elsif ($type =~ /xml/i) {
	    # checking if it is a xhtml or not
	    my $xmlns = Alvis::NLPPlatform::Document::getnamespace($infile);


	    if (defined $xmlns) {
		if ($xmlns eq "http://www.w3.org/1999/xhtml") {
		    # if xhtml calling Alvis convert
		    return &html2alvis($infile, $AlvisConv, $config);
		} else {
	    # if xml, 
            #         check if it is an alvis file
            #         if not, try to use a stylesheet
		    if ($xmlns eq "http://alvis.info/enriched/") {
			print STDERR "Already in XML Alvis\n";
			$outfile_path = Alvis::NLPPlatform::Document::get_language_from_file($infile, "$outfile.lang", $config);
# 			print STDERR "Outfile is $outfile (i.e. $outfile_path)\n";
			return &outputting_alvis_from_file($outfile_path, $AlvisConv, $config);
		    } else {
			# use of a stylesheet conversion
			($xmlns, $outdata) = &applying_stylesheet($infile, $xmlns, $config);
			if ($xmlns ne "default") {
			    # CAREFUL not tested yet !
			    $outdata = Alvis::NLPPlatform::Document::get_language_from_data($outdata);
			    return &outputting_alvis($outdata, $AlvisConv, $config);
			} else {
			    return &outputting_empty_xmlns_file($outdata, $outfile . ".out", $AlvisConv, $config, $mm);
			}
		    }
		}
		
	    } else {
		# use of a default stylesheet conversion
		($xmlns,$outdata) = &applying_stylesheet($infile, "default", $config);
		return &outputting_empty_xmlns_file($outdata, $outfile . ".out", $AlvisConv, $config, $mm);
	    }
	}
    }
}

sub outputting_empty_xmlns_file
{
    my $outdata = shift;
    my $outfile = shift;
    my $AlvisConv = shift ;
    my $config = shift;
    my $mm = shift;

    warn "Openning $outfile\n";
    open OUTFILE, ">$outfile";
    binmode(OUTFILE, ":utf8");
    print OUTFILE $outdata;
    close OUTFILE;
    return &conversion_file_to_alvis_xml($outfile, $AlvisConv, $config, $mm);
    
}


sub applying_stylesheet
{
    my $file = shift;
    my $xmlns = shift;
    my $config = shift;

#     my $xslt_proc = XML::XSLT->new ($stylesheet, warnings => 1);

#     $xslt_proc->transform ($file);
#     print $xslt_proc->toString;

   # maybe change for XML::DOM::Lite::XSLT engine

    if (!exists $config->{"CONVERTERS"}->{"STYLESHEET"}->{$xmlns}) {
	$xmlns = "default";
    }
    my $command = $config->{"CONVERTERS"}->{"STYLESHEET"}->{$xmlns} . " $file";
    print STDERR "Applying the stylesheet : " . $config->{"CONVERTERS"}->{"STYLESHEET"}->{$xmlns} . "\n";

    my $outdata;
    $outdata = `$command`;
    
    return ($xmlns,$outdata);
#    $xslt_proc->dispose();

}

sub get_type_file
{
    my $file = shift;
    my $mm = shift;

    print STDERR "Determining the type of the file " . $file . ": ";
    
    my $type = $mm->checktype_filename($file);

    if ($file =~ /.ppt$/i) {
	$type = "application/powerpoint";
	warn "Getting the type thanks to the extension\n";
    }
    if ($file =~ /.xls$/i) {
	$type = "application/vnd.ms-excel";
	warn "Getting the type thanks to the extension\n";
    }
    # if msword may be it should be relevant to check the extension, to better determine the type
    $type =~ s/;.*//;
    if (($type eq "message/rfc822") || ($file =~ /^x-system\/x-unix;/)) {
	if ($file =~ /.tex$/i) {
	    $type = "text/x-tex";
	    warn "Getting the type thanks to the extension\n";
	}
    }
    print STDERR "Type file: $type\n";
    return($type);

}

sub html2alvis_init
{
    my $config = shift;

    my $ODir;

    my $NPerOurDir=1000;
#      my $MetaEncoding='iso-8859-1';
      my $MetaEncoding='UTF-8';
    my $HTMLEncoding=undef;'iso-8859-1';
    my $HTMLEncodingFromMeta='utf-8';
    my $IncOrigDoc=1;

    if (defined $config->{"ALVISTMP"}) {
	$ODir = $config->{"ALVISTMP"};
    } else {
	$ODir = ".";
    }


    warn "Outdir is $ODir\n";

    print STDERR "Initialisation of the Alvis converter ...";

    my $C=Alvis::Convert->new(outputRootDir=>$ODir,
			  outputNPerSubdir=>1000,
			  outputAtSameLocation=>0,
			  metaEncoding=>$MetaEncoding,
			  sourceEncoding=>$HTMLEncoding,
			  includeOriginalDocument=>$IncOrigDoc,
                          sourceEncodingFromMeta=>$HTMLEncodingFromMeta);

    $C->init_output();
    my $i = 0;
    while (-f "$ODir/0/$i.alvis") { $i++;};
    warn "Starting  at $i\n";
    $C->{outputN} = $i;
    print STDERR "done\n";
    return($C);
}

sub html2alvis
{
    my $filename = shift;
    my $Alvis_converter = shift;
    my $config = shift;

    print STDERR "Converting $filename to ALVIS XML format\n";

    my $meta_txt = &make_meta($filename);

    my $html_txt=$Alvis_converter->read_HTML($filename);

#    print STDERR "==>" .  utf8::is_utf8($html_txt) . "\n";

    if (!defined($html_txt))
    {
	warn "Reading the HTML for basename \"$filename\" failed. " .
	    $Alvis_converter->errmsg();
	$Alvis_converter->clearerr();
	return (1);;
    }

#     print STDERR $html_txt;

    my $alvisXML=$Alvis_converter->HTML($html_txt,$meta_txt);

    if (!defined($alvisXML))
    {
	warn "Obtaining the Alvis version of the " .
	    "HTML version of an article failed. " . $Alvis_converter->errmsg();
	$Alvis_converter->clearerr();
	return 2;
    }
#  	my $e=Alvis::Document::Encoding->new();
# 	my $type_guesser=Alvis::Document::Type->new();
# 	my ($doc_type,$doc_sub_type)=$type_guesser->guess($alvisXML);
# 	my $doc_encoding=$e->guess_and_convert($alvisXML,$doc_type,$doc_sub_type, "UTF-8");
# 	if (!defined($doc_encoding))
# 	{
# 	    die('Cannot guess. ' . $e->errmsg());
# 	}
# 	print STDERR "$doc_type,$doc_sub_type,$doc_encoding\n";
# 	print STDERR $e->guess($alvisXML);
#     warn "Checking the encoding\n";
#     if (!Encode::is_utf8($alvisXML)) {
# 	warn "Not a UTF-8, assume to be a latin-1 document\n";
# 	print STDERR "Converting in UTF8...\n";
# 	Encode::from_to($alvisXML, "iso-8859-1", "UTF-8");
# 	print STDERR "done\n";
#     }
#  	print STDERR $alvisXML;
#  	exit;
	
#   my $decoder = Encode::Guess->guess_encoding($alvisXML, /UTF-8/);
#     if (!ref($decoder)) {
# 	warn "Not a UTF-8, assume to be a latin-1 document\n";
# 	print STDERR "Converting in UTF8...\n";
# 	$alvisXML = $decoder->decode($alvisXML);
# # 	Encode::from_to($alvisXML, "iso-8859-1", "UTF-8");
# 	print STDERR "done\n";
#     } else {
# 	warn "Document is already in UTF-8 :-)\n";
#     }

# TO SEE HOW TO REMOVE CONCAT of foot and head
#     if ($alvisXML !~ /^\s*<\?xml /) {
# 	my $xmlhead = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
# 	my $xmlfoot = "</documentCollection>\n";
# 	$alvisXML = Alvis::NLPPlatform::Document::get_language_from_data($xmlhead . $alvisXML . $xmlfoot);
#     } else {
#     print STDERR $alvisXML;

	$alvisXML = Alvis::NLPPlatform::Document::get_language_from_data($alvisXML);
#      print STDERR $alvisXML;

#     }
#      print STDERR $alvisXML;

#     return &outputting_alvis($xmlhead . $alvisXML . $xmlfoot, $Alvis_converter, $config);
    return &outputting_alvis($alvisXML, $Alvis_converter, $config);

#     print STDERR "\t done\n";

#     return 0;
}

sub outputting_alvis_from_file
{
    my $alvisfile = shift;
    my $Alvis_converter = shift;
    my $config = shift;

    open ALVISFILE, $alvisfile or die "No such file: $alvisfile\n";
#       binmode(ALVISFILE, ":utf8");
    binmode ALVISFILE; # XXXX

    local $/ = undef;

    my $alvisfile_data = <ALVISFILE>;
    close ALVISFILE;

    my $docs = Alvis::NLPPlatform::Document::get_documentRecords($alvisfile_data);

#     print STDERR "doc_list : $docs\n";

#    return &outputting_alvis($alvisfile_data, $Alvis_converter, $config);
    return &outputting_alvis($docs, $Alvis_converter, $config);

}

sub outputting_alvis
{
    my $alvisXML = shift;
    my $Alvis_converter = shift;
    my $config = shift;
    my $xmlheadXML = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    my $xmlheaddC = "<documentCollection xmlns=\"http://alvis.info/enriched/\" version=\"1.1\">\n";
    my $xmlfoot = "</documentCollection>\n";

#      print STDERR Dumper $config;

#     print STDERR $alvisXML;

    if ((defined $config->{"CONVERTERS"}->{"StoreInputFiles"}) && ($config->{"CONVERTERS"}->{"StoreInputFiles"} == 0)) {
	print STDERR "Don't store files\n";
	if ($alvisXML =~ /^\s*<documentRecord/) {
	    $alvisXML = $xmlheadXML . $xmlheaddC . $alvisXML . $xmlfoot;
	}
	
	if ($alvisXML !~ /^\s*<\?xml /) {
	    $alvisXML = $xmlheadXML . $alvisXML;
	}
#    	print STDERR "$alvisXML\n";

	return $alvisXML;
    }
    else {
	print STDERR "Store files\n";
#     print STDERR $alvisXML;
	if (!$Alvis_converter->output_Alvis([$alvisXML]))
	{
	    warn "Outputting the Alvis records failed. " . $Alvis_converter->errmsg();
	    $Alvis_converter->clearerr();
	    return 3;
	}
    }
}

sub make_meta
{

    my $filename = shift;

    
    my $meta_txt = "";
    $meta_txt .= "title\ttitle\n";
    $meta_txt .= "date\t";
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();

    $meta_txt .= sprintf("%04d-%02d-%02d %02d:%02d:%02d\n", $year+1900, $mon+1, $mday, $hour, $min, $sec);

    while($filename =~ s/\.out$//){};

    $meta_txt .= "url\tfile://$filename\n";

    return($meta_txt);
}

sub making_spool
{
    my $config = shift;
    my $outputRootDir = shift;

    my $xmlfile;
    my $xml_rec_doc = "";
    my $line;
    my $working_dir = getcwd();
    
    print STDERR "Making the spool ...\n";

    print STDERR "Working dir : $working_dir\n"; 

    mkpath($config->{"alvis_connection"}->{"SPOOLDIR"}) or warn "cannot create directory " . $config->{"alvis_connection"}->{"SPOOLDIR"} . "\n";
    touch($config->{"alvis_connection"}->{"SPOOLDIR"} . "/seq");

    $|=1;

    my $pipe = new Alvis::Pipeline::Read(port => $config->{"alvis_connection"}->{"HARVESTER_PORT"}, spooldir => $config->{"alvis_connection"}->{"SPOOLDIR"},
					 loglevel=>10)
	or die "can't create read-pipe on port " . $config->{"alvis_connection"}->{"HARVESTER_PORT"} . ": $!";

    my $pipe_out = new Alvis::Pipeline::Write(host => "localhost", 
					      port => $config->{"alvis_connection"}->{"HARVESTER_PORT"}, 
					      loglevel => 10)
	or die "can't create ALVIS write-pipe for port '" . $config->{"alvis_connection"}->{"HARVESTER_PORT"} . "': $!";

    my $tmp_spool_dir = $outputRootDir . "/0";

    opendir DIR, $tmp_spool_dir;
    while($xmlfile = readdir DIR) {

	if (($xmlfile ne ".") && ($xmlfile ne "..")) {
	    open XMLFILE, "$tmp_spool_dir/$xmlfile" or die "Cannot open such file ($xmlfile)\n";
	    binmode(XMLFILE, ":utf8");
	    $xml_rec_doc = "";
	    while($line = <XMLFILE>) {
		$xml_rec_doc .= $line;
	    }
	    $pipe_out->write($xml_rec_doc);
	    close XMLFILE;
	    unlink "$tmp_spool_dir/$xmlfile";
	}
    }
    closedir(DIR);

    rmdir($tmp_spool_dir);
    sleep 1;
    $pipe_out->close() or die "Truly unbelievable (1)";
    $pipe->close(); #  or die "Truly unbelievable (2)";
    
    print STDERR "Making the spool ... done\n";
    
    chdir($working_dir);

    return 0;
}



1;

__END__

=head1 NAME

Alvis::NLPPlatform::Convert - Perl extension for converting files in
any format into the ALVIS XML.

=head1 SYNOPSIS

use Alvis::NLPPlatform::Convert;


my %config = &Alvis::NLPPlatform::load_config($rcfile);

my $mm = Alvis::NLPPlatform::Convert::load_MagicNumber(\%config);

my $AlvisConverter = Alvis::NLPPlatform::Convert::html2alvis_init();

Alvis::NLPPlatform::Convert::conversion_file_to_alvis_xml($ARGV[0], $AlvisConverter, \%config, $mm);


=head1 DESCRIPTION

This module provides methods to convert input files into the ALVIS XML
format. It determines the type of the input files according to its
magic number and applies converters. Output files are stored in a
temporary spool.

=head1 METHODS


=head2 load_MagicNumber

    load_MagicNumber(\%config);

This method loads additional information for magic numbers. The file
is defined in the variable C<SupplMagicFile> in the section
C<CONVERTER>.

It returns the object containing the list of magic numbers.

=head2 html2alvis_init

    html2alvis_init(\%config);

The method Initializes the HTML2XML Alvis converter. It also
determines the directory where will store the output files. It is
either the directory by the variable C<ALVISTMP>) or either, by
default, the current directory. The start number of the files is also
determined.

The method returns the Alvis converter (i.e. from HTML file to Alvis
DTD XML).

=head2 conversion_file_to_alvis_xml

    conversion_file_to_alvis_xml($file,  $AlvisConv, $config, $mm);

The method converts the input file C<$file> into the Alvis XML. Other
arguments are the Alvis converter C<$AlvisConv>, the NLP platform
configuration (C<$config>), providing command lines for convertion,
and additional magic numbers (C<$mm>).

=head2 html2alvis

    html2alvis($file, $Alvis_converter);

The method converts the HTML file C<$file> into the ALVIS XML format
(thanks to the ALVIS converter C<Alvis_converter>) and store the
output file in the temporary spool directory.

It returns a value different of C<0> if it fails.

=head2 make_meta

    make_meta($filename)

The method generates the meta information associated to C<filename>
with default values, i.e. title, date and url, and then returns it.


=head2 outputting_empty_xmlns_file

    outputting_default_xmlns_file($outdata, $outfile, $AlvisConverter, $config, $mm);

The method print the output data C<$output> (defined in a empty XML
namespace) into the temporary file C<outfile>, and carries out the
convertion to the ALVIS XML format, with C<$AlvisConverter>.

Additional parameters are the configuration C<$config> and the
additional magic filter C<$mm>.



=head2 applying_stylesheet

    applying_stylesheet($file, $xmlns, $config);

This method applies the XML style sheet, defined for the namespace
C<$xmlns> given the configuration C<$config>, to the file C<$file>.

The method returns an two element array containing the XML namespace
and the XML data.

=head2 get_type_file

    get_type_file($file, $mm);

The method determines and returns the type of the file C<$file> according to its
magic number (regarding the list C<$mm>) and in the case of "msword",
according to the extension of the file (PowerPoint and Excel.



=head2 outputting_alvis_from_file

    outputting_alvis_from_file($alvisfile, $Alvis_converter, $config);


The method formats and outputs the file C<$alvisfile>. It loads the
file, and applies the ALVIS converter. The language of the document(s)
is identified at this point thanks to the method defined in the
ALVIS::NLPPlatform::Document module.

The C<$config> parameter is the hashtable containing the configuration
variables.

=head2 outputting_alvis

    outputting_alvis($alvisXML, $Alvis_converter, $config);

The method ouputs the data contained in C<$alvisXML> thaks to the
ALVIS converter. The C<$config> parameter is the hashtable containing
the configuration variables.

=head2 making_spool

    making_spool($config, $outputRootDir);

The method generates the spool directory defined in C<$config> from
the C<$outputRootDir>.

# =head1 ENVIRONMENT

=head1 SEE ALSO

Alvis web site: http://www.alvis.info

=head1 AUTHOR

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2007 by Thierry Hamon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.
