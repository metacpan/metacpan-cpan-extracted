package App::Framework::Base::SearchPath ;

=head1 NAME

App::Framework::Base::SearchPath - Searchable path

=head1 SYNOPSIS

use App::Framework::Base::SearchPath ;


=head1 DESCRIPTION

Provides a simple searchable path under which to locate files or directories. 

When trying the read a file/dir, looks in each location in the path stopping at the first found.

When writing a file/dir, attempts to write into each location in the path until can either (a) write, or (b) runs out of search path
 

=cut

use strict ;

our $VERSION = "1.000" ;

#============================================================================================
# USES
#============================================================================================
use File::Path ;

use App::Framework::Base::Object::ErrorHandle ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA = qw(App::Framework::Base::Object::ErrorHandle) ; 

#============================================================================================
# GLOBALS
#============================================================================================

=head2 FIELDS

The following fields should be defined either in the call to 'new()', as part of a 'set()' call, or called by their accessor method
(which is the same name as the field):


=over 4

=item B<dir_mask> - directory creation mask

When the write_path is searched, any directories created are created using this mask [default = 0755]

=item B<env> - environment HASH ref

Any paths that contain variables have the variables expanded using the standard environment variables. Specifying
this HASH ref causes the variables to be replaced from this HASH before looking in the envrionment.

=item B<path> - search path

A comma seperated list (in scalar context), or an ARRAY ref list of paths to be searched (for a file)

=item B<write_path> - search path for writing

A comma seperated list (in scalar context), or an ARRAY ref list of paths to be searched (for a file) when writing. If not set, then
B<path> is used.


=back

=cut


my %FIELDS = (
	# user settings
	'dir_mask'		=> 0755,
	'env'			=> {},
	
	# Object Data
	'path'			=> undef,	# dummy field - causes _path to be set
	'write_path'	=> undef,	# dummy field - casues _write_path to be set
	
	'_path'			=> [],
	'_write_path'	=> undef,
) ;



#============================================================================================

=head2 CONSTRUCTOR

=over 4

=cut

#============================================================================================

=item B< new([%args]) >

Create a new SearchPath object.

The %args are specified as they would be in the B<set> method, for example:

	'mmap_handler' => $mmap_handler

The full list of possible arguments are :

	'fields'	=> Either ARRAY list of valid field names, or HASH of field names with default values 

=cut

sub new
{
	my ($obj, %args) = @_ ;
	
	my $class = ref($obj) || $obj ;

	# Create object
	my $this = $class->SUPER::new(%args) ;

#$this->debug(2) ;
$this->_dbg_prt(["new this=", $this], 10) ;

	return($this) ;
}



#============================================================================================

=back

=head2 CLASS METHODS

=over 4

=cut

#============================================================================================

#-----------------------------------------------------------------------------

=item B< init_class([%args]) >

Initialises the SearchPath object class variables.

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

=item B< path([$path]) >

Get/set the search path. When setting, can either be:

=over 4

=item * comma/semicolon seperated list of directories

=item * ARRAY ref to list of directories

=back

When getting in scalar context returns comma seperated list; otherwise returns an ARRAY.

=cut

sub path
{
	my $this = shift ;
	my ($path_ref) = @_ ;

	$path_ref ||= '' ;
$this->_dbg_prt(["path($path_ref)\n"]) ;
$this->_dbg_prt(["this=", $this], 10) ;
	
	my $list_aref = $this->_access_path('_path', $path_ref) ;

	return wantarray ? @$list_aref : join ',', @$list_aref ;
}

#----------------------------------------------------------------------------

=item B< write_path([$path]) >

Get/set the write path. Set the path for writing file/dir. If this is not set then
uses 'path'. You can set this to something different to ensure that created files
are limited to user home directory (for example). 

When setting, can either be:

=over 4

=item * comma/semicolon seperated list of directories

=item * ARRAY ref to list of directories

=back


When getting in scalar context returns comma seperated list; otherwise returns an ARRAY.

=cut

sub write_path
{
	my $this = shift ;
	my ($path_ref) = @_ ;

	$path_ref ||= '' ;
$this->_dbg_prt(["write_path($path_ref)\n"]) ;
$this->_dbg_prt(["this=", $this], 10) ;
	
	# get write path..
	my $list_aref = $this->_access_path('_write_path', $path_ref) ;
	
	# ..or use 'path'
	$list_aref = $this->_access_path('_path') unless defined($list_aref) ;
	
	return wantarray ? @$list_aref : join ',', @$list_aref ;
}


#----------------------------------------------------------------------

=item B< read_filepath($file) >

Search through the search path attempting to read I<$file>. Returns the file
path to the readable file if found; otherwise returns undef

=cut

sub read_filepath
{
	my $this = shift ;
	my ($file) = @_ ;

$this->_dbg_prt(["get read_filepath($file)\n"]) ;
$this->_dbg_prt(["this=", $this], 10) ;
	
	my @dirs = $this->path() ;
	my $path = undef ;
	
	foreach my $d (@dirs)
	{
		my $f = File::Spec->catfile($d, $file) ;
$this->_dbg_prt([" + check $f\n"]) ;
		if (-f "$f")
		{
$this->_dbg_prt([" + + found file\n"]) ;
			$path = $f ;
			last ;
		}
	}

	return $path ;
}

#----------------------------------------------------------------------

=item B< write_filepath($file) >

Search through the search path attempting to write I<$file>. Returns the file
path to the writeable file if found; otherwise returns undef

=cut

sub write_filepath
{
	my $this = shift ;
	my ($file) = @_ ;

$this->_dbg_prt(["write_filepath($file)\n"]) ;
$this->_dbg_prt(["this=", $this], 10) ;
	
	my @dirs = $this->write_path() ;
	my $path = undef ;

	$this->_dbg_prt(["Find dir to write to from $file ...\n"]) ;
	
	foreach my $d (@dirs)
	{
		my $found=1 ;

		$this->_dbg_prt([" + processing $d\n"]) ;

		# See if dir exists
		if (!-d $d)
		{
			# See if this user can create the dir
			eval {
				mkpath([$d], $this->debug, $this->dir_mask) ;
			};
			$found=0 if $@ ;

			$this->_dbg_prt([" + $d does not exist - attempt to mkdir=$found : $@\n"]) ;
		}		

		if (-d $d)
		{
			$this->_dbg_prt([" + $d does exist ...\n"]) ;

			# See if this user can write to the dir
			if (open my $fh, ">>$d/$file")
			{
				close $fh ;

				$this->_dbg_prt([" + + Write to $d/$file succeded\n"]) ;
			}
			else
			{
				$this->_dbg_prt([" + + Unable to write to $d/$file - aborting this dir\n"]) ;

				$found = 0;
			}
		}		
		
		if ($found)
		{
			$path = File::Spec->catfile($d, $file) ;
			last ;
		}
	}

	$this->_dbg_prt(["Searched $file : write path=".($path?$path:"")."\n"]) ;
	
	return $path ;
}




#============================================================================================
# PRIVATE METHODS 
#============================================================================================

#----------------------------------------------------------------------------
# get/set paths
sub _access_path
{
	my $this = shift ;
	my ($name, $path_ref) = @_ ;

	$path_ref ||= '' ;
$this->_dbg_prt(["_access_path($name, $path_ref)\n"]) ;

	if ($path_ref)
	{
		# Set new value
		my @dirs ;
		if (ref($path_ref) eq 'ARRAY')
		{
			# list
			@dirs = @$path_ref ;
		}
		else
		{
			# comma/semicolon seperated list
			@dirs = split /[,;]/, $path_ref ;
		}

$this->_dbg_prt([" + dirs=", \@dirs]) ;
$this->_dbg_prt(["this=", $this], 10) ;
		
		my $vars_href = $this->env ;
$this->_dbg_prt([" + env=", $vars_href]) ;
		
		## expand directories
		foreach my $d (@dirs)
		{
			# Replace any '~' with $HOME
			$d =~ s/~/\$HOME/g ;
			
			# Now replace any vars with values from the environment
			$d =~ s/\$(\w+)/$vars_href->{$1} || $ENV{$1} || $1/ge ;
			
			# Ensure path is clean
			$d = File::Spec->rel2abs($d) ;

$this->_dbg_prt([" + + dir=$d\n"]) ;

		}
			
		# save value
		$this->$name(\@dirs) ;		
	}

$this->_dbg_prt([" + now this=", $this], 2);

	## return latest settings
	return $this->$name() ;
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


