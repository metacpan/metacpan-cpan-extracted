#!/usr/bin/perl
package C::Analyzer;

BEGIN {
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION = '0.01';
	@ISA     = qw(Exporter);

	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

use strict;
use warnings;

my %calls       = ();
my @calls_table = ();
my @rec_track   = ();

#################### subroutine header begin ####################

=head2 new

 Usage     : my $analyzer = new Analyzer(
 			_inputPath => "/home/sindhu/test/afs", # folder path
            _cppPath => "/usr/bin",	# GNU C preprocessor path
			_inputOption => "dir_and_subdir", # if dir or dir/subdir
			);
 Purpose   : Constructors, Static method that return an object
 Returns   : Object
 Argument  : _inputPath, _inputOption, _cppPath, _functionName 
 Throws    : None
 Comment   : Can be extended for other important inputs as well in future.
See Also   : 

=cut

#################### subroutine header end ####################

sub new {
	my $class  = shift;
	my %params = @_;
	my $self   = {};
	if ( defined( $params{'_inputPath'} ) ) {
		$self->{'_inputPath'} = $params{'_inputPath'};
	}
	else {
		print "Error: Missing file/folder path\n";
		exit;
	}

	if ( defined( $params{'_inputOption'} ) ) {
		$self->{'_inputOption'} = $params{'_inputOption'};
	}
	else {
		init $self->{'_inputOption'} = "dir";
	}
	if ( defined( $params{'_cppPath'} ) ) {
		$self->{'_cppPath'} = $params{'_cppPath'};
	}
	else {
		print "Error: Missing GNU C Processor path\n";
		exit;
	}
	if ( defined( $params{'_cppOptions'} ) ) {
		$self->{'_cppOptions'} = $params{'_cppOptions'};
	}
	else {
		$self->{'_cppOptions'} = "-nostdinc";
	}
	if ( defined( $params{'_functionName'} ) ) {
		$self->{'_functionName'} = $params{'_functionName'};
	}
	else {
		$self->{'_functionName'} = "main";
	}
	if ( defined( $params{'_reportType'} ) ) {
		$self->{'_reportType'} = $params{'_reportType'};
	}
	else {
		$self->{'_reportType'} = "Text";
	}
	if ( defined( $params{'_reportOptions'} ) ) {
		$self->{'_reportOptions'} = $params{'_reportOptions'};
	}
	else {
		$self->{'_reportOptions'} = "fullDetails";
	}
	if ( defined( $params{'_treeType'} ) ) {
		$self->{'_treeType'} = $params{'_treeType'};
	}
	else {
		$self->{'_treeType'} = "callTree";
	}
	bless $self, $class;
}

#################### subroutine header begin ####################

=head2 init

 Usage     : init()
 Purpose   : initializes variables, gets C files in dir/subdirs, 
 			 runs GNU C Preprocessor and updates functions and 
 			 calls in each C file
 Returns   : None
 Argument  : None 
 Throws    : None
 Comment   : None
See Also   : 

=cut

#################### subroutine header end ####################

sub init() {
	my ($self) = @_;
	&clean();
	my $folder  = "";
	my $opt     = "";
	my $cppPath = "";
	my $cppOpts = "";
	my $funName = "";
	my $cfiles;
	my $ppfiles;
	my $cfile;

	$folder  = $self->{_inputPath}   if defined($folder);
	$opt     = $self->{_inputOption} if defined($opt);
	$cppPath = $self->{_cppPath}     if defined($cppPath);
	$cppOpts = $self->{_cppOptions}  if defined($cppOpts);

	$cfiles = &getListOfCFiles( \$folder, \$opt );
	$ppfiles = &runGnuPreprocessor( \$cfiles, \$cppPath, \$cppOpts );
	&identifyFunctionsAndCalls( \$ppfiles, \$opt, \$folder );
	return;
}

#################### subroutine header begin ####################

=head2 calltree

 Usage     : calltree()
 Purpose   : Initial preperations for calltree generation for
 			 user given functions.
 Returns   : None
 Argument  : Takes a reference to list of functions 
 Throws    : None
 Comment   : None
See Also   : 

=cut

#################### subroutine header end ####################

sub calltree() {
	my ( $class, $functions ) = @_;
	my @funclist = ();
	if ( defined($functions) ) {
		@funclist = @{$functions};
	}
	else {
		@funclist = qw(main);
	}
	foreach my $function (@funclist) {
		&prepareCalltreeInit( \$function );
	}
	return;
}

#################### subroutine header begin ####################

=head2 getListOfCFiles

 Usage     : getListOfCFiles()
 Purpose   : Takes folder name and GNU C Preprocessor options
 			 and returns list of C files in dir/subdir
 Returns   : reference to array of C files
 Argument  : folder name and GNU C Preprocessor options 
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub getListOfCFiles() {
	my ( $folder, $opt ) = @_;
	my @cfiles = ();
	my $OS     = $^O;
	$$folder =~ s/\//\\/g;
	if (   ( defined $OS )
		&& ( $OS   eq "MSWin32" )
		&& ( $$opt eq "dir_and_subdir" ) )
	{
		@cfiles = `dir /b /s \"$$folder\*.c\"`;
	}
	if ( ( defined $OS ) && ( $OS eq "MSWin32" ) && ( $$opt eq "dir" ) ) {
		chdir $$folder;
		@cfiles = `dir /b *.c`;
	}
	if (   ( defined $OS )
		&& ( $OS   eq "linux" )
		&& ( $$opt eq "dir_and_subdir" ) )
	{
		my $path = $$folder;
		$path =~ s/\\/\//g;
		chdir $path;
		@cfiles = `find \. -name \*.c`;    

	}
	if ( ( defined $OS ) && ( $OS eq "linux" ) && ( $$opt eq "dir" ) ) {
		chdir $$folder;
		@cfiles = `find *.c`;
	}
	return ( \@cfiles );
}

#################### subroutine header begin ####################

=head2 prepareCalltreeInit

 Usage     : prepareCalltreeInit()
 Purpose   : final preparations for calltree generation
 Returns   : none
 Argument  : function name
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub prepareCalltreeInit() {
	my ($function) = shift;
	my $localtime  = localtime();
	my @calls      = ();
	if ( exists $calls{$$function} ) {
		@calls = @{ $calls{$$function} };
	}
	else {
		print "Function does not exists\n";
		return;
	}
	if ( defined($$function) && defined( $calls[0] ) ) {
		print "<0>$$function$calls[0]\n";
	}
	$| = 1;
	shift(@calls);
	my $calltablelen = scalar(@calls);
	if ( $calltablelen == 0 ) {
		print "Sorry! Function \"$$function\" does not contain any calls";
		return;
	}
	&generateCalltree( $$function, 1 );
	print "\n";
	return;
}

#################### subroutine header begin ####################

=head2 generateCalltree

 Usage     : generateCalltree()
 Purpose   : Functions that actually generates the functional calltree
 Returns   : none
 Argument  : function name and tab count
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub generateCalltree() {
	my ( $function, $tabcount ) = ( shift, shift );
	if ( $calls{$function} ) {
		push( @rec_track, $function );
		my @calls = @{ $calls{$function} };
		shift(@calls);
		foreach my $call (@calls) {
			my $curr_cnt  = $tabcount;
			my $temp_call = $call;

			if ( $temp_call =~ /^\[/ ) {
				next;
			}
			$temp_call =~ /(\w+)\s*\(/;
			$temp_call = $1;
			$temp_call = trim($temp_call);
			my $temp_fun = $function;
			$temp_fun = trim($temp_fun);
			my $is_there = 0;
			foreach my $element (@rec_track) {

				if ( $element eq $temp_call ) {
					$is_there = 1;

					#             $temp_element =  $element;
					last;
				}
			}
			if ( $is_there eq 0 ) {

				my $str = "";
				for ( my $i = 0 ; $i < $tabcount ; $i++ ) {

					print "    ";
					$str = "$str" . "    ";
					$|   = 1;
				}

				if ( $call =~ /^\(/ ) {
					$call = "__double_def" . "$call";
					print "<$tabcount>$call\n";
					$call = "";
				}
				else {
					print "<$tabcount>$call\n";
				}

				$|         = 1;
				$temp_call = $call;
				$temp_call =~ /(\w+)\s*\(/;
				$temp_call = $1;
				$temp_call = trim($temp_call);
				my $tmp = "$str" . "</$temp_call>"
				  if ( defined($temp_call) && defined($str) );
				$tmp = "";

				if ( defined($temp_call) ) {
					&generateCalltree( $temp_call, $tabcount + 1 );
				}

			}
			else {
				my $str = "";
				for ( my $i = 0 ; $i < $tabcount ; $i++ ) {

					print "    ";
					$str = "$str" . "    ";

					$| = 1;
				}

				if ( $call =~ /^\(/ ) {
					$call = "__double_def" . "$call";
					print "<$tabcount>$call ---@\n";
					$call = "";
				}
				else {
					print "<$tabcount>$call\n";
				}

				my $temp_call = $call;
				$temp_call =~ /(\w+)\s*\(/;
				$temp_call = $1;
				$temp_call = trim($temp_call);
				$|         = 1;

			}
		}
	}
	return;
}

#################### subroutine header begin ####################

=head2 runGnuPreprocessor

 Usage     : runGnuPreprocessor()
 Purpose   : runs GNU C preprocessor in the user given path
 Returns   : returns a reference to list of names of preprocessed files
 Argument  : reference of list of C files, CPP Path, Options
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub runGnuPreprocessor() {
	my ( $cfiles, $cppPath, $cppOpts ) = @_;
	my ( $prepfile, $prep_str );
	my @ppfiles = ();
	my $len     = scalar(@$$cfiles);
	my $cnt     = 0;
	foreach my $cfile (@$$cfiles) {
		$cnt++;
		chomp($cfile);
		$cfile =~ s/\\/\//g;
		&progress_bar( $cnt, $len, 50, '=' );
		if ( $cfile =~ /(.*)(\.c|\.C)$/ ) {
			my $stripfile = trim($1);
			$stripfile =~ s/\\/\//g;
			$prepfile = "$stripfile" . "._pp";
		}
		$prep_str =
		    "\"$$cppPath" . "/cpp\"" . " "
		  . "$$cppOpts" . " "
		  . "\"$cfile\"" . " "
		  . "> \"$prepfile\" 2>junk.txt";
		push( @ppfiles, $prepfile );
		system($prep_str);
	}
	print "\n";
	@$$cfiles = ();
	return ( \@ppfiles );
}

#################### subroutine header begin ####################

=head2 identifyFunctionsAndCalls

 Usage     : identifyFunctionsAndCalls()
 Purpose   : initial preperation for parsing each C file to identify
 			 functions and calls
 Returns   : none
 Argument  : reference to list of preprocessor files, options and folder
 			 names.
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub identifyFunctionsAndCalls() {
	my ( $ppfiles, $opt, $folder ) = @_;
	my $fun_calls;
	foreach my $ppfile (@$$ppfiles) {
		$fun_calls = parseCFile( \$ppfile, \$$opt, \$$folder );
		updateHashTable( \$fun_calls );
	}
	return;
}

#################### subroutine header begin ####################

=head2 parseCFile

 Usage     : parseCFile()
 Purpose   : Parser module to identify functions and calls in C files.
 Returns   : reference to array of funs and calls.
 Argument  : reference to filename, options and foldername
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub parseCFile() {
	my ( $infile, $opt_s, $FolderName ) = shift;
	my @t_funs_calls = ();
	my @pplines      = ();
	my $OpenCount    = 0;
	my $CloseCount   = 0;
	my $lno          = 0;
	my $fragment;
	my $filename;
	my $fun;
	open( PPFILE, "<$$infile" ) || die("Cannot open input file $$infile\n");
	@pplines = <PPFILE>;
	close(PPFILE);

	foreach my $ppfile (@pplines) {
		$lno++;
		$ppfile =~ s/\".*\(.*\"/ /g;

		if ( $ppfile =~ /^\#\s*([0-9]+)\s*\"(.*)\s*\"/ ) {
			$lno = $1;
			$lno--;
			$filename = trim($2);
			next;
		}
		while ( $ppfile =~ /(\w+)\s*\(/g ) {
			my $t_fun = $1;
			$t_fun = trim($t_fun);
			if (   ( $t_fun eq "if" )
				|| ( $t_fun eq "for" )
				|| ( $t_fun eq "while" )
				|| ( $t_fun eq "switch" )
				|| ( $t_fun eq "case" )
				|| ( $t_fun eq "int" )
				|| ( $t_fun eq "char" )
				|| ( $t_fun eq "flaot" )
				|| ( $t_fun eq "double" )
				|| ( $t_fun eq "long" )
				|| ( $t_fun eq "short" )
				|| ( $t_fun eq "bit" )
				|| ( $t_fun eq "unsigned" )
				|| ( $t_fun eq "return" ) )
			{
				next;
			}
			if ($opt_s) {
				my $filelength = length($FolderName);
				$fragment = substr $filename, $filelength;
				$fragment = "." . "$fragment";
				if ( $t_fun eq "" ) {
					;
				}
				else {
					$fun = "$t_fun" . "($lno, $fragment)";
				}
			}
			else {
				if ( $t_fun eq "" ) {
					print;
				}
				else {
					$fun = "$t_fun" . "($lno, $filename)";
				}
			}
			push( @t_funs_calls, $fun );
			$fragment = "";
		}
		while ( $ppfile =~ /(;)/g ) {
			push( @t_funs_calls, $1 );
		}
		while ( $ppfile =~ /({)/g ) {
			$OpenCount++;
			push( @t_funs_calls, $1 );
		}
		while ( $ppfile =~ /(})/g ) {
			$CloseCount++;
			push( @t_funs_calls, $1 );
		}
	}
	return ( \@t_funs_calls );
}

#################### subroutine header begin ####################

=head2 updateHashTable

 Usage     : updateHashTable()
 Purpose   : updates function wise calls hash table
 Returns   : reference to hash table containing functions and calls
 Argument  : None
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub updateHashTable() {
	my $fun_calls  = shift;
	my $OpenCount  = 0;
	my $CloseCount = 0;
	my $function;
	my $FUNCTIONFOUND = 0;
	my $item          = -1;
	my $titem;
	my $cnt1 = 0;
	my $call;
	my $fun_remain;

	foreach my $x (@$$fun_calls) {
		$item++;

		if ( $x eq "{" ) {
			$OpenCount++;
		}
		if ( $x eq "}" ) {
			$CloseCount++;
		}
		if (   !defined( @$$fun_calls[$item] )
			|| !defined( @$$fun_calls[ $item + 1 ] ) )
		{
			next;
		}
		$titem = $item + 1;
		if (   ( @$$fun_calls[$item] =~ /(\w+.*)/ )
			&& ( @$$fun_calls[ $item + 1 ] eq "{" )
			&& ( $OpenCount == $CloseCount ) )
		{
			$function = $1;
			$function =~ /(\w+)\s*\(/;
			$function   = $1;
			$function   = trim($function);
			$fun_remain = $';
			$fun_remain = "(" . $fun_remain;
			push( @{ $calls{$function} }, $fun_remain );
			$FUNCTIONFOUND = 1;
		}
		if ( ( $FUNCTIONFOUND == 1 ) && ( $OpenCount != $CloseCount ) ) {
			if ( ( $x eq "{" ) || ( $x eq "}" ) || ( $x eq ";" ) ) {
				next;
			}
			else {
				$call = $x;
				push( @calls_table, $call );
				$call = trim($call);
				if ( defined($call) ) {
					push( @{ $calls{$function} }, $call );
				}
			}
		}
	}

	return;
}

#################### subroutine header begin ####################

=head2 trim

 Usage     : trim()
 Purpose   : trims leading and trailing white spaces in strings
 Returns   : trimmed string
 Argument  : string
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################
sub trim($) {
	my $string = shift;
	$string =~ s/^\s+// if defined($string);
	$string =~ s/\s+$// if defined($string);
	return $string;
}

#################### subroutine header begin ####################

=head2 clean

 Usage     : clean()
 Purpose   : safe exit
 Returns   : none
 Argument  : none
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################
sub clean() {
	%calls       = ();
	@calls_table = ();
	@rec_track   = ();
	return;
}

#################### subroutine header begin ####################

=head2 progress_bar

 Usage     : progress_bar()
 Purpose   : simple and neat progress bar
 Returns   : none
 Argument  : none
 Throws    : None
 Comment   : None
See Also   : 
None

=cut

#################### subroutine header end ####################

sub progress_bar {
	my ( $got, $total, $width, $char ) = @_;
	$width ||= 25;
	$char  ||= '=';
	my $num_width = length $total;
	local $| = 1;
	printf "[%-${width}s] processed [%${num_width}s/%s] (%.2f%%)\r",
	  $char x ( ( $width - 1 ) * $got / $total ) . '>', $got, $total,
	  100 * $got / +$total;
}
#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=head1 NAME

C::Analyzer - Generates C Call Control Flow tree for C source code

=head1 SYNOPSIS

    use warnings;
    use strict;
    use C::Analyzer;

    my @functions  = qw(afs_CheckServers afs_cv2string);
    my $analyzer   = new Analyzer(
        _inputPath => "/home/foo",
        _cppPath   => "/usr/local/bin",
    );
    $analyzer->init();
    # "main" function taken if no parameter passed to this method.
    $analyzer->calltree( \@functions ); 

    $analyzer->clean();

I<The synopsis above only lists the major methods and parameters. Keep checking for new additions>

=head1 DESCRIPTION

Creates Call stack/tree of C source code

=head2 GETTING HELP

If you have questions about Analyzer you can get help from the I<analyzer-users@perl.org> mailing list.  You can get help
on subscribing and using the list by emailing I<analyzer-users-help@perl.org>.

=head2 NOTES

The Analyzer is evolving and there are plans to add more features, so it's good to have the latest copy.

=head2 Architecture of Analyzer

  |-Input folder of C files-|                                |----Call Stack Output---|   

  .------------------------.                                                              
  | 1. #include <stdio.h>  |                       .-.                                    
  | 2.                     |       .-------.       |A|                                    
  | 3. void main(void)     |       | Perl  |       |N|       .------------------------.   
  | 4. {                   |       | script|  |A|  |A|       |<0>main(3, a.c)         |   
  | 5.    foo();           |-------| using |--|P|--|L|-------|    <1>foo(5, a.c)      |   
  | 6. }                   |       | API   |  |I|  |Y|       |        <2>bar(10, a.c) |   
  | 7.                     |       |methods|       |Z|        `-----------------------/    
  | 8. int foo()           |       |       |       |E|                                  
  | 9. {                   |       `-------'       |R|                                    
  | 10.   bar();           |                       `-'                                    
  | 11. }                  |                                                              
  `-----------------------/                                                               

=head2 Outline Usage

=head3 C<mandatory inputs>

 Analyzer expects couple of mandatory inputs. One, folder that contains C/H files. Second, path for GNU C Preprocessor.

 for example:
    my $analyzer   = new Analyzer(
        _inputPath => "/home/foo",
        _cppPath   => "/usr/local/bin",
    );

=head3 C<optional inputs>

 Analyzer expects optional inputs as well. 
 
 It allows directory and sub directory parsing. Default is directory processing. To tell analyzer module to recursively process 
 C files in all directories and sub directories, use _inputOption
 
 for example:
    my $analyzer   = new Analyzer(
        _inputPath => "/home/foo",
        _cppPath   => "/usr/local/bin",
        _inputOption => "dir_and_subdir",
    );

 There is an option to provide additional GNU C Preprocessor options using "_cppOptions"
 
 for example:
    my $analyzer   = new Analyzer(
        _inputPath => "/home/foo",
        _cppPath   => "/usr/local/bin",
        _inputOption => "dir_and_subdir",
        _cppOptions => "-DMACRO1 -DMACRO2",
    );

=head1 BUGS

None.


=head1 SUPPORT

The Analyzer is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.
Please let me know if you could add more features for this module.I will be more than
happy to add them.
	
=head1 AUTHOR

    Sreekanth Kocharlakota
    CPAN ID: bmpOg
    Sreekanth Kocharlakota
    sreekanth@cpan.org
    http://www.languagesemantics.com

=head1 COPYRIGHT

The Analyzer module is Copyright (c) 1994-2007 Sreekanth Kocharlakota. USA.
This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

