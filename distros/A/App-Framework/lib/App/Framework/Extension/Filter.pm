package App::Framework::Extension::Filter ;

=head1 NAME

App::Framework::Extension::Filter - Script filter application object

=head1 SYNOPSIS

  use App::Framework '::Filter' ;


=head1 DESCRIPTION

Application that filters a file or files to produce some other output


=head2 Application Subroutines

This extension modifies the normal call flow for the application subroutines. The extension calls the subroutines
for each input file being filtered. Also, the main 'app' subroutine is called for each of the lines of text in the input file.

The pseudo-code for the extension is:

    FOREACH input file
        <init variables, state HASH>
        call 'app_start' subroutine 
        FOREACH input line
	        call 'app' subroutine 
        END
        call 'app_end' subroutine 
	END

For each input file, a state HASH is created and passed as a reference to the application subroutines. The state HASH contains
various values maintained by the extension, but the application may add it's own additional values to the HASH. These values will 
be passed unmodified to each of the application subroutine calls.

The state HASH contains the following fields:

=over 4

=item * num_files

Total number of input files.

=item * file_number

Current input file number (1 to B<num_files>)

=item * file_list

ARRAY ref. List of input filenames.

=item * vars

HASH ref. Empty HASH created so that any application-specific variables may be stored here.

=item * line_num

Current line number of line being processed (1 to N).

=item * output_lines

ARRAY ref. List of the output lines that are to be written to the output file (maintained by the extension).

=item * file

Current file name of the file being processed.

=item * line

String of line being processed.

=item * output

Special variable used by application to tell extension what to output (see L</Output>).

=back

The state HASH reference is passed to all 3 of the application subroutines. In addition, the input line of text is also passed
to the main 'app' subroutine. The interface for the subroutines is:

=over 4

=item B<app_start($app, $opts_href, $state_href)>

Called once for each input file. Called at the start of processing. Allows any setting up of variables stored in the state HASH.

Arguments are:

=over 4

=item I<$app> - The application object

=item I<$opts_href> - HASH ref to the command line options (see L<App::Framework::Feature::Options> and L</Filter Options>)

=item I<$state_href> - HASH ref to state

=back

=item B<app($app, $opts_href, $state_href, $line)>

Called once for each input file. Called at the start of processing. Allows any setting up of variables stored in the state HASH.

Arguments are:

=over 4

=item I<$app> - The application object

=item I<$opts_href> - HASH ref to the command line options (see L<App::Framework::Feature::Options> and L</Filter Options>)

=item I<$state_href> - HASH ref to state

=item I<$line> - Text of input line

=back

=item B<app_end($app, $opts_href, $state_href)>

Called once for each input file. Called at the end of processing. Allows for any end of file tidy up, data sorting etc.

Arguments are:

=over 4

=item I<$app> - The application object

=item I<$opts_href> - HASH ref to the command line options (see L<App::Framework::Feature::Options> and L</Filter Options>)

=item I<$state_href> - HASH ref to state

=back

=back 


=head2 Output

By default, each time the extension calls the 'app' subroutine it sets the B<output> field of the state HASH to undef. The 'app'
subroutine must set this field to some value for the extension to write anything to the output file.

For examples, the following simple 'app' subroutine causes all input files to be output uppercased:

	sub app
	{
		my ($app, $opts_href, $state_href, $line) = @_ ;
		
		# uppercase
		$state_href->{output} = uc $line ;	
	}

If no L</outfile> option is specified, then all output will be written to STDOUT. Also, normally the output is written line-by-line after each line has been processed. If the L</buffer>
option has been specified, then all output lines are buffered (into the state variable L</output_lines>) then written out at the end of processing all input. Similarly, if the L</inplace>
option is specified, then buffering is used to process the complete input file then overwrite it with the output.

=head2 Outfile option

The L</outfile> option may be used to set the output filename. This may include variables that are specific to the Filter extension, where the variables value is updated for each
input file being processed. The following Filter-sepcific variables may be used:

		$filter{'filter_file'} = $state_href->{file} ;
		$filter{'filter_filenum'} = $state_href->{file_number} ;
		my ($base, $path, $ext) = fileparse($file, '\..*') ;
		$filter{'filter_name'} = $base ;
		$filter{'filter_base'} = $base ;
		$filter{'filter_path'} = $path ;
		$filter{'filter_ext'} = $ext ;

=over 4

=item I<filter_file> - Input full file path

=item I<filter_base> - Basename of input file (excluding extension)

=item I<filter_name> - Alias for L</filter_base>

=item I<filter_path> - Directory path of input file

=item I<filter_ext> - Extension of input file

=item I<filter_filenum> - Input file number (starting from 1)

=back


NOTE: Specifying these variables for options at the command line will require you to escape the variables per the operating system you are using (e.g. use single quotes ' ' around
the value in Linux).

For example, with the command line arguments:

    -outfile '/tmp/$filter_name-$filter_filenum.txt' afile.doc /doc/bfile.text

Processes './afile.doc' into '/tmp/afile-1.txt', and '/doc/bfile.text' into '/tmp/bfile-2.txt'


=head2 Example

As an example, here is a script that filters one or more HTML files to strip out unwanted sections (they are actually Doxygen HTML files
that I wanted to convert into a pdf book):

    #!/usr/bin/perl
    #
    use strict ;
    use App::Framework '::Filter' ;
    
    # VERSION
    our $VERSION = '1.00' ;
    
        ## Create app
        go() ;
    
    #----------------------------------------------------------------------
    sub app_begin
    {
        my ($app, $opts_href, $state_href, $line) = @_ ;
    
        # force in-place editing
        $app->set(inplace => 1) ;
    
        # set to start state
        $state_href->{vars} = {
            'state'        => 'start',
        } ;
    }
    
    #----------------------------------------------------------------------
    # Main execution
    #
    sub app
    {
        my ($app, $opts_href, $state_href, $line) = @_ ;
    
        my $ok = 1 ;
        if ($state_href->{'vars'}{'state'} eq 'start')
        {
            if ($line =~ m/<!-- Generated by Doxygen/i)
            {
                $ok = 0 ;
                $state_href->{'vars'}{'state'} = 'doxy-head' ;
            }
        }
        elsif ($state_href->{'vars'}{'state'} eq 'doxy-head')
        {
            $ok = 0 ;
            if ($line =~ m/<div class="contents">/i)
            {
                $ok = 1 ;
                $state_href->{'vars'}{'state'} = 'contents' ;
            }
        }
        elsif ($state_href->{'vars'}{'state'} eq 'contents')
        {
            if ($line =~ m/<hr size="1"><address style="text-align: right;"><small>Generated/i)
            {
                $ok = 0 ;
                $state_href->{'vars'}{'state'} = 'doxy-foot' ;
            }
        }
        elsif ($state_href->{'vars'}{'state'} eq 'doxy-foot')
        {
            $ok = 0 ;
            if ($line =~ m%</body>%i)
            {
                $ok = 1 ;
                $state_href->{'vars'}{'state'} = 'end' ;
            }
        }
    
        # only output if ok to do so
        $state_href->{'output'} = $line if $ok ;
    }
    
    
    #=================================================================================
    # SETUP
    #=================================================================================
    __DATA__
    
    [SUMMARY]
    Filter Doxygen created html removing frames etc.
    
    [DESCRIPTION]
    B<$name> does some stuff.


The script takes in HTML of the form:

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
    <html><head><meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
    <title>rctu4_test: File Index</title>
    <link href="doxygen.css" rel="stylesheet" type="text/css">
    <link href="tabs.css" rel="stylesheet" type="text/css">
    </head><body>
    **<!-- Generated by Doxygen 1.5.5 -->
    **<div class="navigation" id="top">
    **  <div class="tabs">
    **    <ul>
    ..
    **  </div>
    **</div>
    <div class="contents">
    <h1>File List</h1>Here is a list of all files with brief descriptions:<table>
      <tr><td class="indexkey">src/<a class="el" href="rctu4__tests_8c.html">rctu4_tests.c</a></td><td class="indexvalue"></td></tr>
      <tr><td class="indexkey">src/common/<a class="el" href="ate__general_8c.html">ate_general.c</a></td><td class="indexvalue"></td></tr>
    ...
    
      <tr><td class="indexkey">src/tests/<a class="el" href="test__star__daisychain__specific_8c.html">test_star_daisychain_specific.c</a></td><td class="indexvalue"></td></tr>
      <tr><td class="indexkey">src/tests/<a class="el" href="test__version__functions_8c.html">test_version_functions.c</a></td><td class="indexvalue"></td></tr>
    </table>
    
    </div>
    
    **<hr size="1"><address style="text-align: right;"><small>Generated on Fri Jun 5 13:43:31 2009 for rctu4_test by&nbsp;
    **<a href="http://www.doxygen.org/index.html">
    **<img src="doxygen.png" alt="doxygen" align="middle" border="0"></a> 1.5.5 </small></address>
    </body>
    </html>

And removes the lines beginning '**'.

The script does in-place updating of the HTML files and can be run as:

    filter-script *.html

=cut

use strict ;
use Carp ;

our $VERSION = "1.001" ;





#============================================================================================
# USES
#============================================================================================
use File::Path ;
use File::Basename ;
use File::Spec ;
use App::Framework::Core ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
use App::Framework::Extension ;
our @ISA ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 ADDITIONAL COMMAND LINE OPTIONS

This extension adds the following additional command line options to any application:

=over 4

=item B<-skip_empty> - Skip blanks

Do not process empty lines (lines that contain only whitespace)

=item B<-trim_space> - Trim spaces

Remove spaces from start and end of lines

=item B<-trim_comment> - Trim comments

Remove any comments from the line, starting from the comment string to the end of the line

=item B<-inplace> - In-place filter

Read file, process, then overwrite original input file with processed output

=item B<-outdir> - Specify output directory

Write file(s) into specified directory rather that into same directory as input file

=item B<-outfile> - Specify output file

Specify the output filename, which may include variables (see L</Output Filename>)

=item B<-comment> - Specify command string 

Specify the comment start string. Used in conjuntion with L</-trim_comment>.

=back

=cut

# Set of script-related default options
my @OPTIONS = (
	['skip_empty',			'Skip blanks', 		'Do not process empty lines', ],
	['trim_space',			'Trim spaces',		'Remove spaces from start/end of line', ],
	['trim_comment',		'Trim comments',	'Remove comments from line'],
	['inplace',				'In-place filter',	'Read file, process, then overwrite input file'],
	['outdir=s',			'Output directory',	'Write files into specified directory (rather than into same directory as input file)'],
	['outfile=s',			'Output filename',	'Specify the output filename which may include variables'],
	['comment=s',			'Comment',			'Specify the comment start string', '#'],
) ;

=head2 COMMAND LINE ARGUMENTS

This extension sets the following additional command line arguments for any application:

=over 4

=item B<file> - Input file(s)

Specify one of more input files to be processed. If no files are specified on the command line then reads from STDIN.

=back

=cut

# Arguments spec
my @ARGS = (
	['file=f*',				'Input file(s)',	'Specify one (or more) input file to be processed']
) ;

our $class_debug=0;

#============================================================================================

=head2 FIELDS

Note that the fields match with the command line options.

=over 4

=item B<skip_empty> - Skip blanks

Do not process empty lines (lines that contain only whitespace)

=item B<trim_space> - Trim spaces

Remove spaces from start and end of lines

=item B<trim_comment> - Trim comments

Remove any comments from the line, starting from the comment string to the end of the line

=item B<inplace> - In-place filter

Read file, process, then overwrite original input file with processed output

=item B<buffer> - Buffer output

Store output lines into a buffer, then write out file at end of processing

=item B<outdir> - Specify output directory

Write file(s) into specified directory rather that into same directory as input file

=item B<outfile> - Specify output file

Specify the output filename, which may include variables (see L</Output Filename>)

=item B<comment> - Specify command string 

Specify the comment start string. Used in conjuntion with L</trim_comment>.

=item B<out_fh> - Output file handle 

Read only. File handle of current output file.

=back

=cut

my %FIELDS = (
	## Object Data
	'skip_empty'	=> 0,
	'trim_space'	=> 0,
	'trim_comment'	=> 0,
	'comment'		=> '#',
	'buffer'		=> 0,
	'inplace'		=> 0,
	'outfile'		=> undef,
	'outdir'		=> undef,
	
	## internal
	'out_fh'		=> undef,
	
	'_filter_state'		=> {},
	'_filter_opts'		=> undef,
) ;

#============================================================================================

=head2 CONSTRUCTOR METHODS

=over 4

=cut

#============================================================================================

=item B<new([%args])>

Create a new App::Framework::Extension::Filter.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	## create object dynamically
	my $this = App::Framework::Core->inherit($class, %args) ;

#print "Filter - $class ISA=@ISA\n" if $class_debug ;

	## Set options
	$this->feature('Options')->append_options(\@OPTIONS) ;
	
	## Update option defaults
	$this->feature('Options')->defaults_from_obj($this, [keys %FIELDS]) ;

	## Set args
	$this->feature('Args')->append_args(\@ARGS) ;

#$this->debug(2) ;
	
	## hi-jack the app function
	$this->extend_fn(
		'app_fn'		=> sub {$this->filter_run(@_);},
		'app_start_fn'		=> sub {$this->_filter_start(@_);},
		'app_end_fn'		=> sub {$this->_filter_end(@_);},
	) ;

	return($this) ;
}



#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================

#-----------------------------------------------------------------------------

=item B<init_class([%args])>

Initialises the object class variables.

=cut

sub init_class
{
	my $class = shift ;
	my (%args) = @_ ;

	# Add extra fields
	$class->add_fields(\%FIELDS, \%args) ;

	# init class
	$class->SUPER::init_class(%args) ;

}


#============================================================================================

=back

=head2 OBJECT METHODS

=over 4

=cut

#============================================================================================

#----------------------------------------------------------------------------

=item B<filter_run($app, $opts_href, $args_href)>

Filter the specified file(s) one at a time.
 
=cut


sub filter_run
{
	my $this = shift ;
	my ($app, $opts_href, $args_href) = @_ ;

	## save for later
	$this->_filter_opts($opts_href) ;

$this->_dbg_prt(["Args=", $args_href, "Opts=", $opts_href]) ;
	
	# Get command line arguments
	my @args = @{ $args_href->{'file'} || [] } ;
	my @args_fh = @{ $args_href->{'file_fh'} || [] } ;

	## check for in-place editing on STDIN
	if ($opts_href->{inplace})
	{
		if ( (scalar(@args) == 1) && ($args_fh[0] == \*STDIN) )
		{
			$this->throw_fatal("Cannot do in-place editing of standard input") ;
		}
	}

	$this->_dispatch_entry_features(@_) ;

#$this->debug(2) ;

$this->_dbg_prt(["#!# Hello, Ive started filter_run()...\n"]) ;

	## Update from options
	$this->feature('Options')->obj_vars($this, [keys %FIELDS]) ;

	## Set up filter state
	my $state_href = $this->_filter_state ;
	$state_href->{num_files} = scalar(@args) ;
	$state_href->{file_number} = 1 ;
	$state_href->{file_list} = \@args ;
	$state_href->{vars} = {} ;

	## do each file
	for (my $fnum=0; $fnum < $state_href->{num_files}; ++$fnum)
	{

		$state_href->{file_number} = $fnum+1 ;
		$state_href->{outfile} = '' ;
		$state_href->{line_num} = 1 ;
		$state_href->{output_lines} = [] ;
		$state_href->{file} = $args[$fnum] ;

		$this->_dispatch_label_entry_features('file', $app, $opts_href, $state_href) ;
		
		$this->_start_output($state_href, $opts_href) ;
		
		## call application start
		$this->call_extend_fn('app_start_fn', $state_href) ;

		## Process file
		my $fh = $args_fh[$fnum] ;
		my $line ;
		while(defined($line = <$fh>))
		{
			chomp $line ;
			
			## see if line needs processing
			if ($opts_href->{trim_space})
			{
				$line =~ s/^\s+// ;
				$line =~ s/\s+$// ;
			}
			if ($opts_href->{trim_comment} && $opts_href->{comment})
			{
				$line =~ s/$opts_href->{comment}.*$// ;
			}
			
			$state_href->{line} = $line ;
			$state_href->{output} = undef ;
			
			$this->_dispatch_label_entry_features('line', $app, $opts_href, $state_href) ;

			## see if we skip this line
			my $skip = 0 ;
			if ($opts_href->{skip_empty})
			{
				$skip=1 if $line =~ m/^\s*$/ ;
			}

			## call application (if not skipped)
			$this->call_extend_fn('app_fn', $state_href, $line) unless $skip ;
			
			$this->_handle_output($state_href, $opts_href) ;

			$state_href->{line_num}++ ;

			$this->_dispatch_label_exit_features('line', $app, $opts_href, $state_href) ;
		}
		close $fh ;

		## call application end
		$this->call_extend_fn('app_end_fn', $state_href) ;

		$this->_end_output($state_href, $opts_href) ;

#		$state_href->{file_number}++ ;

		$this->_dispatch_label_exit_features('file', $app, $opts_href, $state_href) ;
	}	

	$this->_dispatch_exit_features(@_) ;

}


#----------------------------------------------------------------------------
# start
sub _filter_start
{
	my $this = shift ;
	my ($app, $opts_href, @args) = @_ ;

	## Do nothing

}

#----------------------------------------------------------------------------
# end
sub _filter_end
{
	my $this = shift ;
	my ($app, $opts_href, @args) = @_ ;

	## Do nothing
}

#----------------------------------------------------------------------------

=item B<write_output($output)>

Application interface for writing out extra lines
 
=cut


sub write_output
{
	my $this = shift ;
	my ($output) = @_ ;
	
	my $state_href = $this->_filter_state ;
	$state_href->{'output'} = $output ;
	
	$this->_handle_output($state_href, $this->_filter_opts) ;
}


# ============================================================================================
# PRIVATE METHODS
# ============================================================================================

#----------------------------------------------------------------------------

=item B<_start_output($state_href, $opts_href)>

Start of output file
 
=cut


sub _start_output
{
	my $this = shift ;
	my ($state_href, $opts_href) = @_ ;

	$this->set('out_fh' => undef) ;

$this->_dbg_prt(["_start_output\n"]) ;
	
	## do nothing if buffering or in-place editing
	return if ($this->buffer || $this->inplace) ;

$this->_dbg_prt([" + not buffering/inplace\n"]) ;

	# open output file (and set up output dir)
	$this->_open_output($state_href, $opts_href) ;
	
}

#----------------------------------------------------------------------------

=item B<_handle_output($state_href, $opts_href)>

Write out line (if required)
 
=cut


sub _handle_output
{
	my $this = shift ;
	my ($state_href, $opts_href) = @_ ;

	## buffer line(s)
	my $out = $state_href->{output} ;
$this->_dbg_prt(["_handle_output : output=", $out, "\n"]) ;
	push @{$state_href->{output_lines}}, $out if defined($out) ;

	## do nothing if buffering or in-place editing
	return if ($this->buffer || $this->inplace) ;

$this->_dbg_prt([" + not buffering/inplace\n"]) ;

	## ok to write
	$this->_wr_output($state_href, $opts_href, $out) if defined($out)  ;
}


#----------------------------------------------------------------------------

=item B<_end_output($state_href, $opts_href)>

End of output file
 
=cut


sub _end_output
{
	my $this = shift ;
	my ($state_href, $opts_href) = @_ ;

$this->_dbg_prt(["_end_output : buffer=", $this->buffer, ", inplace=", $this->inplace, ", # lines=", scalar(@{$state_href->{output_lines}}),"\n"]) ;

	## if buffering or in-place editing, now need to write file
	if ($this->buffer || $this->inplace)
	{
$this->_dbg_prt([" + writing\n"]) ;

		# open output file (and set up output dir)
		$this->_open_output($state_href, $opts_href) ;

		foreach my $line (@{$state_href->{output_lines}})
		{
			$this->_wr_output($state_href, $opts_href, $line) ;
		}	
	}
	
	# close output file
	$this->_close_output($state_href, $opts_href) ;
}



#----------------------------------------------------------------------------

=item B<_open_output($state_href, $opts_href)>

Open the file (or STDOUT) depending on settings
 
=cut


sub _open_output
{
	my $this = shift ;
	my ($state_href, $opts_href) = @_ ;

	$this->set('out_fh' => undef) ;

$this->_dbg_prt(["_open_output\n"]) ;
	
	my $outfile ;
	if ($this->inplace)
	{
		## Handle in-place editing
		$outfile = $state_href->{file} ;
$this->_dbg_prt([" + inplace file=$outfile\n"]) ;
	}
	elsif ($this->outfile)
	{
		## See if writing to dir
		my $dir = $this->outdir ;
		if ($dir)
		{
			## create path
			mkpath([$dir], $this->debug, 0755) ;
		}
		$dir ||= '.' ;
		
		my %opts = $this->options() ;
		my %app_vars = $this->vars() ;
		my %filter ;
		$filter{'filter_fmt'} = $this->outfile ;
		$filter{'filter_file'} = $state_href->{file} ;
		$filter{'filter_filenum'} = $state_href->{file_number} ;
		my ($base, $path, $ext) = fileparse($state_href->{file}, '\..*') ;
		$filter{'filter_name'} = $base ;
		$filter{'filter_base'} = $base ;
		$filter{'filter_path'} = $path ;
		$filter{'filter_ext'} = $ext ;

		$this->expand_keys(\%filter, [\%opts, \%app_vars, \%ENV]) ;
		
		$outfile = $filter{'filter_fmt'} ;
		
$this->_dbg_prt([" + eval=$@\n"]) ;
$this->_dbg_prt([" + outfile=$outfile: dir=$dir fmt=$filter{'filter_fmt'} file=$filter{'filter_file'} num=$filter{'filter_filenum'} base=$base path=$path\n"]) ;
		
		$outfile = File::Spec->catfile($dir, $outfile) ;
	}
	
	## Output file specified?
	if ($outfile)
	{
		$outfile = File::Spec->rel2abs($outfile) ;
		my $infile = File::Spec->rel2abs($state_href->{file}) ;

		if ($outfile eq $infile)
		{
			# In place editing - make sure flag is set
			$this->inplace(1) ;

$this->_dbg_prt([" + inplace $outfile\n"]) ;
		}

#		else
#		{
			## Open output
			open my $outfh, ">$outfile" or $this->throw_fatal("Unable to write \"$outfile\" : $!") ;
			$this->out_fh($outfh) ;

$this->_dbg_prt([" + opened $outfile fh=$outfh\n"]) ;
			
			$state_href->{outfile} = $outfile ;
#		}
		
	}
	else
	{
		## STDOUT
		$this->out_fh(\*STDOUT) ;
	}
}

#----------------------------------------------------------------------------

=item B<_close_output($state_href, $opts_href)>

Close the file if open
 
=cut


sub _close_output
{
	my $this = shift ;
	my ($state_href, $opts_href) = @_ ;

	my $fh = $this->out_fh ;
	$this->set('out_fh' => undef) ;
	
	if ($this->outfile)
	{
		close $fh ;
	}
	else
	{
		## STDOUT - so ignore
	}
}

#----------------------------------------------------------------------------

=item B<_wr_output($state_href, $opts_href, $line)>

End of output file
 
=cut


sub _wr_output
{
	my $this = shift ;
	my ($state_href, $opts_href, $line) = @_ ;

	my $fh = $this->out_fh ;

$this->_dbg_prt(["_wr_output($line) fh=$fh\n"]) ;
	if ($fh)
	{
		print $fh "$line\n" ;
	}
}


# ============================================================================================
# END OF PACKAGE

=back

=head1 DIAGNOSTICS

Setting the debug flag to level 1 prints out (to STDOUT) some debug messages, setting it to level 2 prints out more verbose messages.

=head1 AUTHOR

Steve Price C<< <sdprice at cpan.org> >>

=head1 BUGS

None that I know of!

=cut

1;

__END__



* app_start - allows hash setup
* app_end - allows file creation/tweak
* app
** return output line?
** HASH state auto- updated with:
*** all output lines (so far)
*** regexp match vars (under 'vars' ?)
** app sets HASH 'output' to tell filter what to output (allows multi-line?)
* options
** inplace - buffers up lines then overwrites (input) file
** dir - output to dir
** input file wildcards
** recurse - does recursive file find (ignore .cvs .svn)
** output - can spec filename template ($name.ext)

* Filtering feature
** All extra loading of filter submodules
** Feature options: +Filter(perl c) - specifies extra Filter::Perl, Filter::C modules
* Filter spec:

	(
		('<spec>', <flags>, <code>),
		('<spec>', <flags>, <code>),
		('<spec>', <flags>, <code>),
	)

Each entry perfomed on the line, move on to next entry if no match OR match and (flags & FILTER_CONTINUE) [default]
Calls <code> on match AND (flags & FILTER_CALL); calls app if no <code> specified
Flag bitmasks:
	FILTER_CONTINUE		- allows next entry to be processed if matches; normally stops
	FILTER_CALL			- call code on match
	
<spec> is of the form:

	[<cond>:]/<regexp>/[:<setvars>]

<cond> evaluatable condition that must be met before running the regexp. Variables can be used by name 
(names are converted to $state->{'vars'}{name})

<stevars> colon separated list of variable assignments evaluated on match. Variables used by name (as <cond>). Regexp matches
accessed by $n or \n

