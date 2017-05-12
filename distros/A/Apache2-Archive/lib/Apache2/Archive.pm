package Apache2::Archive;


use strict;
use Archive::Tar;
use Apache2::Log;
use Apache2::Const;
use Apache2::Util ();
use Apache2::Status;
use Apache2::SubRequest ();

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.2';


sub handler{
	my $r = shift;
	my $t;
	#$t->{Files};			# Contains info on all the files in the archive
	#$t->{FileInfo};		# contains info on archive file itself
	#$t->{filename};		# Canonical name of the archive file itself
	#$t->{template};		# The template file (one line per array entry)
	#$t->{Tar};				# The Archive::Tar object for the archive
	#$t->{SizeLimit};	# The Maximum tar file size allowed. After opening a file larger
						# that this, the processes will terminate to free memory.
	$t->{Tar} = new Archive::Tar;
	$t->{SizeLimit} = $r->dir_config('SizeLimit');
	
	##
	# Get the template file for later use
	##	

	&getTemplateFile($t,$r->dir_config('Template'));
	
	##
	# Create the Tar object;
	##
	
	
	$t->{filename} = $r->filename;
	unless (-e $t->{filename} && -r $t->{filename}) {
		return Apache2::Const::NOT_FOUND;
	}
	my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat($t->{filename});

	($t->{FileInfo}->{'name'}) = $t->{filename} =~ m!(([^/\\]|\\\/)+)$!;
	$t->{FileInfo}->{'date'} = &getDatestring($mtime, $r->dir_config('Months'));
	$t->{FileInfo}->{'rawsize'} = -s $t->{filename};
	$t->{FileInfo}->{'size'} = &getSizestring($t->{FileInfo}->{'rawsize'});
	$t->{FileInfo}->{'view_location'} = $r->uri . "/display/" . $t->{FileInfo}->{'name'};
	$t->{FileInfo}->{'compressed'} = 1 if $t->{FileInfo}->{'name'} =~ /\.gz$/;
	if (! $t->{Tar}->read($t->{filename}, $t->{FileInfo}->{'compressed'})){
		&error_response($t,$r);
		return Apache2::Const::SERVER_ERROR;
	}
	

	
	@{$t->{Files}} = $t->{Tar}->list_files(['name','mtime','size']);

	&response($t,$r);

	# We check to see if we need to kill ourselves
	
	if ($t->{SizeLimit} >0 && $t->{FileInfo}->{'rawsize'} > ($t->{SizeLimit} * 1024))
	{
	#	my $log = $r->log();
		if (getppid() > 1) # check we aren't the parent process.
		{
	#		$log->warn("Apache2::Archive is ending this process because SizeLimit reached. Just letting you know.");
			$r->child_terminate;
    	}
    }
	return Apache2::Const::OK;
}

sub response{
	my $t = shift;
	my $r = shift;
	
	if ($r->path_info =~ m!^/display/!){
		&display($t,$r);
	}
	else{
		&draw_menu($t,$r);		
	}
}
##
# This extracts the file specified in the path info and dumps it
# to stdout. 
##

sub display {
	my $t = shift;
	my $r = shift;
	my $filename;
	
	## 
	# We need to get both the actual file ($file) and the name without
	# any path ($filename). We use $filename to find out the mime type.
	##
	
	my $file = $r->path_info;
	($filename) = $file =~ m!/([^/]+)$!;
	$file =~ s!^/display/!!;
	$file =~ s!\*\*!\./!g; # hack because tar components with ./ at the front get mangled in path_info handling
		
	##
	# This returns the content type. You need to set up a subrequest
	# And then run the (hypothetical) lookup against it.
	##
	
	my $subr = $r->lookup_uri("/$filename");
	my $ct = $subr->content_type;
	
	if(! defined $ct){
		$ct = 'text/plain';
	}
	
	##
	# Create and send the response
	##
	
	$r->content_type($ct);

	#$r->print("file was $file\n path was", $r->path_info);
	$r->print($t->{Tar}->get_content($file));
}


sub draw_menu {
	my $t = shift;
	my $r = shift;
	my $i = 0;
	my $dataline;
	$r->content_type("text/html");
	
	###
	## This loops through each line of the template file. When it sees
	## The StartData tag it captures the $dataline out and generates
	## the table. Otherwise, it just prints the line of the template file
	###
	
	while ($i < @{$t->{template}}){
		if ($t->{template}->[$i] =~ /##\s*StartData/){
			$i++;
			while ($t->{template}->[$i] !~ /##\s*EndData/){
				chomp($t->{template}->[$i]);
				$dataline .= $t->{template}->[$i];
				$i++;
			}
			&draw_data_table($t,$r,$dataline);
		}
		else{
			if ($t->{template}->[$i] =~ /##\w+/){
				$t->{template}->[$i] = do_value_subs($t,$t->{template}->[$i]);
			}
			$r->print($t->{template}->[$i]);
		}
		$i++;
	}
		
	
}




##
# This takes a time in seconds (since 1970 ala unix 'time()' cmd), and an
# optional string containing comma seperated month names. It returns
# a more useful indication of time and date. If no month names are specified,
# it defaults to english three letter abbreviations.
##
sub getDatestring{
	my $Seconds = shift;
	my $Months = shift;
	my @Months;
	if ($Months){
		@Months = split(/,/, $Months);
		unless(@Months == 12){	## Make sure they specified 12 months
			@Months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		}
	}
	else{
		@Months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($Seconds);
	
	return("$mday-$Months[$mon]-$year $hour:$min");
	
}
sub getSizestring{
	my $Bytes = shift;
	my $Kb = int($Bytes/1024) || 1;
	if ($Kb > 1023){
		my $Mb = $Kb/1024;
		## Nasty hack to round to two dp
		$Mb = int($Mb*100)/100;
		return("$Mb Mb");
	}
	else{
		return("$Kb Kb");
	}
}

##
# This gets the template file, or uses its internal one, if there
# is none specified.
##
sub getTemplateFile{
	
	## TODO options to cache this file (i.e. not re-read each time).
	###
	my $t = shift;
	
	if (my $file = shift){
		open(IN, "$file") or die $!;
		while(<IN>){
			push @{$t->{template}}, $_;
		}
		close IN;
	}
	else{
		@{$t->{template}} = split(/\n/, qq(<HTML>\n
<BODY BGCOLOR="#cccccc">\n
<H2>\n
<A HREF=##ArchiveLink>##ArchiveName</A>\n
</H2>\n
##ArchiveDate<BR>\n
##ArchiveSize<BR>\n
This is the contents of the archive:\n
<P>\n
<TABLE border=4 cellpadding=6 cellspacing=2>\n
<TR>\n
<TH>View item</TH><TH>Name</TH><TH>Date</TH><TH>Size</TH>\n
</TR>\n
##StartData\n
<TR>\n
<TD><A HREF=##FileLink>View File</A></TD><TD>##FileName</TD><TD>##FileDate</TD><TD>##FileSize</TD>\n
</TR>\n
##EndData\n
\n
</TABLE>\n
</BODY>\n
</HTML>\n
));
	}
	return 1;
}

sub draw_data_table{
	my $t = shift;
	my $r = shift;
	my $dataline = shift;
	my $moddataline;
	my $date_string;
	my $size_string;
	my $name_string;
	my $view_string;
	my $uri = $r->uri;
	foreach (@{$t->{Files}}){
			$moddataline = $dataline;
			$date_string = getDatestring($_->{'mtime'}, $r->dir_config('Months'));
			$size_string = getSizestring($_->{'size'});			
			$name_string = $_->{'name'};
			$view_string = $name_string;
			$view_string =~ s!\./!\*\*!g;# prevent path_info mangling if ./
			$view_string = $uri . "/display/" . $view_string;
			
			if($_->{'name'} =~ /\/$/) {
				$moddataline =~ s/##FileLink/#/gi;
			} else {
				$moddataline =~ s/##FileLink/$view_string/gi;
			}
			$moddataline =~ s/##FileName/$name_string/gi;
			$moddataline =~ s/##FileDate/$date_string/gi;
			$moddataline =~ s/##FileSize/$size_string/gi;
			
			$moddataline =~ s/##ArchiveDate/$t->{FileInfo}->{'date'}/gi;
			$moddataline =~ s/##ArchiveSize/$t->{FileInfo}->{'size'}/gi;
			$moddataline =~ s/##ArchiveName/$t->{FileInfo}->{'name'}/gi;
			$r->print($moddataline);
	}
}

sub do_value_subs{
	my $t = shift;
	my $line = shift;
	$line =~ s/##ArchiveDate/$t->{FileInfo}->{'date'}/gi;
	$line =~ s/##ArchiveSize/$t->{FileInfo}->{'size'}/gi;
	$line =~ s/##ArchiveName/$t->{FileInfo}->{'name'}/gi;
	$line =~ s/##ArchiveLink/$t->{FileInfo}->{'view_location'}/gi;
	return $line;
}
	

sub error_response{
	my $t = shift;
	my $r = shift;
	my $Err = shift;
	$r->content_type("text/html");

	$r->print("<HTML><BODY><HEAD><TITLE>500 Internal Server Error</TITLE>
				</HEAD><H2>Internal Server Error</H2>The archive file requested
				was not a valid file, or was corrupt.</BODY></HTML>");
	Apache2->warn("Requested file ", $t->{filename}, "is unreadable by Apache2::Archive");
	return;
	
}


1;
__END__

=head1 NAME

Apache2::Archive - Expose archive files through the Apache web server.

=head1 SYNOPSIS

 <Files ~ "\.(tar|tgz|tar\.gz)">
  PerlResponseHandler Apache2::Archive
 </Files>


=head1 DESCRIPTION

Apache2::Archive is a mod_perl 2 extension that allows the Apache HTTP server
to expose tar and tar.gz archives on the fly. When a client requests such an
archive file, the server will return a page displaying information about the 
file that allows the user to view or download individual files from within the
archive.

Apache2::Archive is an almost fidedign port of the Apache2::Archive module by Jon Peterson.

I<Please read the BUGS section before using this on any production server>


=head1 HTTPD CONFIGURATION PARAMETERS

Apache2::Archive is a straightforward replacement for Apache's normal handler
routine. There are currently three optional parameters that alter the way Apache2::Archive
functions. All of these are set using the PerlSetVar directive.

=over 4

=item Months

This should be a comma seperated list of month names for
Apache2::Archive to use when generating dates. This allows you to use names
other than English ones, or to use numbers. If this option is not specified
it will default English three letter abbreviations.

=item Template

This is the location of a template file that Apache2::Archive
should use to generate the information page for the archive. If none is specified
then it will use a built in default. See the section below for how to create a
template file.

=item SizeLimit

This should be a number representing size in Kb. Once Apache has handled any archive
file larger than this number, that Apache process will terminate. This is because
Perl does not return allocated memory to the kernel, and processes tend to grow to
the size of the largest file opened. Since Archive::Tar 0.2, tar
files do not have to be held entirely in memory so this is less of a problem. If
set to 0 or not set, this feature is disabled. You may also want to consider using
Apache::SizeLimit if you OS supports it.

=back

B<EXAMPLE>

 <Files ~ "\.(tar|tgz|tar\.gz)">
 PerlResponseHandler Apache2::Archive
 PerlSerVar Months '1,2,3,4,5,6,7,8,9,10,11,12'
 PerlSetVar Template /any/path/template.html
 PerlSetVar SizeLimit 5000
 </Files>

=head1 TEMPLATE CONFIGURATION FILE

Apache2::Archive can read in an HTML file containing special tags and use that
as a template for its output. The configuration file should be readable by the
httpd process. It does not need to be in the document root. The template file
must contain a special section delimited by ##StartData and ##EndData. This section
httpd process. It does not need to be in the document root. The template file
must contain a special section delimited by ##StartData and ##EndData. This section
is repeated once for each component file in the archive, with any special tags
being substituted with values of the current component file. A list of possible
tags and what they are substituted with is shown below.

The first four tags provide information on the tar file itself, and can be used
anywhere in the template file.

=over 4

I<##ArchiveName>

The name of the archive file currently being viewed.

I<##ArchiveDate>

The last modification date of the archive file currently being viewed.

I<##ArchiveSize>

The size of the archive file currently being viewed.

I<##ArchiveLink>

An absolute URL that allows the user to download the archive file.

I<##StartData>

A file in the archive. This tag should be place on a line by itself.

I<##EndData>

Marks the end of the repeated section. This tag should be placed on a line by
itself.

The next four tags provide information about one of the component files in
the archive. These tags should only be used between the ##StartData and ##EndData
tags.

I<##FileName>

The name of the archived file.

I<##FileDate>

The last modification date of the file.

I<##FileSize>

The size of the file.

I<##FileLink>

An absolute URL that allows the user to download the file.

=back

This example is the template used by default.

	<HTML><BODY BGCOLOR="#cccccc">
	<H2>
	<A HREF=##ArchiveLink>##ArchiveName</A>
	</H2>
	##ArchiveDate<BR>
	##ArchiveSize<BR>
	This is the contents of the archive:
	<P>
	<TABLE border=4 cellpadding=6 cellspacing=2>
	<TR>
	<TH>View item</TH><TH>Name</TH><TH>Date</TH><TH>Size</TH>
	</TR>
	##StartData
	<TR>
		<TD><A HREF=##FileLink>View File</A></TD>
		<TD>##FileName</TD><TD>##FileDate</TD>
		<TD>##FileSize</TD>
	</TR>
	##EndData
	</TABLE></BODY></HTML>

=head1 BUGS

=item MEMORY LEAK

There is a problem with memory leakage. This is greatly
reduced with Archive::Tar 0.2 and later. Still, if you have a busy site, I advise
checking memory consumption, and experimenting with the SizeLimit variable, or with
Apache::SizeLimit. Expect processes to be 10Mb and more.

=item No error checking on template file 

If you create a faulty template file,
the server will attempt to use it regardless and may behave unpredictably.

=item Tar files within tar files

If an archive contains other archives, the
sub-archives are not passed through the Apache2::Archive handler - they are simply
treated as regular files. This is not really a bug per se, more a missing feature.

=item No support for .zip files 

This will be added later.

=back

=head1 AUTHOR

J. Peterson, jon@snowdrift.org, made the original Apache::Archive module. David Moreno, david@axiombox.com, made the port to mod_perl 2.

=head1 COPYRIGHT

Copyright 1998-1999, J. Peterson
Copyright 2008, David Moreno

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

If you have questions or problems regarding use or installation of this module
please feel free to email me directly.

=head1 SEE ALSO

Apache2, Apache::Archive, Archive::Tar, Compress::Zlib, Apache::SizeLimit

=cut
