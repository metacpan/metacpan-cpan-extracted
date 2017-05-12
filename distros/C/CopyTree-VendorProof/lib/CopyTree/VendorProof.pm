package CopyTree::VendorProof;

use 5.008000;
use strict;
use warnings;



# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CopyTree::VendorProof ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our $VERSION = '0.0013';

use Carp();
use Data::Dumper;
# Preloaded methods go here.

sub new{
	my $class = shift;
	
	bless  {source =>{}, destination =>{}}, $class;

}
sub reset{
	my $inst=shift;
	$inst->{'source'}={};
	$inst ->{'destination'} = {};
	return $inst;

}	
sub src {
	my $self_inst = shift;
	Carp::croak ("src can only be used by a VendorProof instance\n") if (! ref $self_inst eq 'CopyTree::VendorProof');
		my $path = shift;
		my $cp_inst =shift; #IMPORTANT: objects cannot be hash keys or it will be sringified
		$self_inst -> {'source'}{$path}= $cp_inst;
	return $self_inst;
}


sub dst {
	my $self_inst = shift;
	Carp::croak ("dst can only be used by a VendorProof instance\n") if (! ref $self_inst eq 'CopyTree::VendorProof');
	my @keys = keys %{$self_inst ->{'destination'}};
	if (@_){

		my $path = shift;
		my $cp_inst =shift; #IMPORTANT: objects cannot be hash keys or it will be sringified
		if (@keys){#  We cannot use  $self_inst ->{'destination'} , since even if it's an empty hash ref, it is defined.
			Carp::croak ("you cannot have more than one destination. Previous destination is [".
					#$self_inst ->{'destination'}{$keys[0]}. "]");
					$keys[0]. "]");
		}
		#$keys[0]=$cp_inst;
		$keys[0]=$path;
		$self_inst -> {'destination'}{$keys[0]}=$cp_inst;
	}
	#returns the inst and the path
	#else { return ($keys[0], $self_inst ->{'destination'}{$keys[0]}) }
	else { 
		if ($keys[0]){

			if ($keys[0] ne ''){
				return ($keys[0], $self_inst ->{'destination'}{$keys[0]});
			}
			else {Carp::croak("dest file is defined as '' (nothing)")}
		}
		else {Carp::croak("dest file is not defined.")}

	}

}
sub cp{
	my $inst=shift;
	my ($destpath, $destinst) = $inst ->dst;
	if (!$destpath or ! ref $destinst){
		Carp::croak("no valid destination instance\n");#dest path error is handled in $inst->dst
	}
	my $desttype = $destinst->is_fd ($destpath) ;
	#sanity check first, see if dest is a file and we have multi source or source that is dir
	my $totsrc =keys %{ $inst ->{'source'} };

	if($totsrc >1 and $desttype eq 'f'){
		Carp::croak("multi source and/or dir source cannot go into a file\n");
	}
	my @srcpaths = keys %{ $inst ->{'source'} };
	Carp::croak("you don't have a source") if (! @srcpaths);

	for my $srcpath (@srcpaths ){
		my $srcinst = $inst ->{'source'} ->{$srcpath};
		my $srctype = $srcinst -> is_fd($srcpath);
		#############D to D copy###############
		if ($srctype eq 'd'){
			if ($desttype ne 'd'){
				Carp::croak("you cannot copy a dir [$srcpath] into a non / non-existing dir [$destpath]\n");
			}
			my $srcbasedir = $srcpath;
			$srcbasedir =~s/.+\///; #takes last dirname, no parent
#			print $srcbasedir. "\n";
			my $srctree_no_srcdir =$srcinst->ls_tree($srcpath);
			$destinst-> cust_mkdir("$destpath/$srcbasedir"); #creates source dir under dest dir
			my ($files, $dirs) = $destinst ->ls_tree_fdret("", $srctree_no_srcdir);
		#	print Dumper $files; #/dwsfolder/new folder/1anovaSigNoMTC.with anno.csv',
		#	print Dumper $dirs; #'/dwsfolder/new folder',
			$destinst ->cust_mkdir("$destpath/$srcbasedir$_") for @$dirs;
			$inst ->copy_meth_deci($srcinst, $destinst, $srcpath, "$destpath/$srcbasedir", $_) for @$files;

		} #end if $srctype eq 'd'
		##############F to F / D copy#############
		elsif ($srctype eq 'f'){
			#file to file copy, file exists, overwrite with destpath.
			if ($desttype eq 'f' or $desttype eq 'pd'){
				print ("overwriting $destpath with $srcpath \n") if ($desttype eq 'f');
				$inst ->copy_meth_deci($srcinst, $destinst, $srcpath, $destpath,'' );

			}
			#file to dir copy, create source's basename under dest
			elsif ($desttype eq 'd'){
				my $source_no_parent = $srcpath;
				$source_no_parent =~s/.+\///; #deletes dir part of path, leaving only filename
				$inst-> copy_meth_deci($srcinst, $destinst, $srcpath, "$destpath/$source_no_parent", '');
			}

			else {
				Carp::carp ("destination type unclear [$desttype] for $destpath\n");
			}

		}
		else{
			Carp::carp ("source file [$srcpath] does not exist\n");
		}

	} #for my $srcinst

}
#evaluates source inst and dest inst, if same, use local copy meths, if diff, use remote copy meths
#this reduces network traffic 
sub copy_meth_deci{
	my $cp_inst =shift;
	my $srcinst=shift;
	my $destinst=shift;
	my $srcpath=shift;
	my $destpath_basedir=shift;
	my $filefromfiles=shift;
	if ((ref $destinst) ne (ref $srcinst)){
		$destinst ->write_from_memory($srcinst ->read_into_memory("$srcpath$filefromfiles") , "$destpath_basedir$filefromfiles");
	}  
		#reduces network traffic
	else{
		$destinst->copy_local_files("$srcpath$filefromfiles", "$destpath_basedir$filefromfiles");
	}

}

sub ls_tree{
	my $class_inst = shift;
	my $fullpath = shift; #this path is the full path
	
	my ($files,$dirs) = $class_inst->fdls( 'fdarrayrefs', $fullpath); #returns full path
	my %structure;
		
#starts inf loop of recursive case
	if( @$dirs) {
		for (@$dirs){
			my $itemfullpath= $_;
			s/^\Q$fullpath\E\/?// ;# $_ now carries no root path, and does not start with a slash
			$structure{$_}=$class_inst->ls_tree($itemfullpath);
		}
	#DO NOT return, otherwise @$files will be omitted in the first level
	}
#base case of no dirs under existing:
	#DO NOT use else, becuase even with @$dirs, we still need to populate @$files
	#if else is accidentally used, it only returns files at the last level
	for (@$files){
		s/^\Q$fullpath\E\/?// ;
		$structure {$_} =undef;
	}
	return \%structure;

}
sub path{
	my $inst =shift;
	my $path =shift;
	if ($path and $path ne ''){ #and is lower precedence than &&
		$inst ->{'path'} =$path;
		return $inst;
	}
	elsif ($inst ->{'path'} ne ''){
		return $inst ->{'path'};
	}	
	else {Carp::croak("you must set a path through \$inst ->SUPER::path('someplace/something') to use this\n")}
}
sub fdls_ret{
	my $inst = shift;
	my $lsoption =shift;
	my ($files, $dirs)=@_;
	my @results;
	if ($lsoption eq 'f'){
		return @$files;
	}
	elsif ($lsoption eq 'd'){
		return @$dirs;
	}
	elsif ($lsoption eq 'fdarrayrefs'){
		return ($files, $dirs);
	}
	elsif ($lsoption eq ''){
		push @results, @$files if (@$files);
		push @results, @$dirs if (@$dirs);
		return @results;
	}
	else {Carp::croak("wrong options: 'f', 'd', 'fdarrayrefs' allowable for lsoption\n")}

}
sub ls_tree_fdret{
	my $inst = shift;
	Carp::croak("ls_tree_fdret item must be an instance, not a class\n") unless (ref $inst);
	my $inst_root_path =shift;
	my $hashref = shift;
	my $files=shift; #this is only for the recursive action. no need for first call
	my $dirs=shift;#this is only for the recursive action. no need for first call
	$files =[] if (!ref $files);
	$dirs =[] if (!ref $dirs);

		$inst_root_path =~s/\/$//; #removes trailing slashes, if any
		for (keys %$hashref){
			if (ref $hashref->{$_}){
#			  print "$_ is dir, gonna push $inst_root_path/$_\n";
				push @$dirs, "$inst_root_path/$_";
				#since we pass refs into the recursive structure, updates to $files and $dirs are automatically reflected
				my ($newfiles, $newdirs)= $inst->ls_tree_fdret("$inst_root_path/$_", $hashref->{$_}, $files, $dirs);
			}
			else{
#			  print "$_ is file, gonna push $inst_root_path/$_\n";
				push @$files, "$inst_root_path/$_";

			}
		}#end for keys hashref
		return ($files, $dirs);

}



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CopyTree::VendorProof - Perl extension for generic copying.  This module's intented purpose is to facilitate file / dir copies between different types of remote systems that frequently use very different syntax for similar functions.  For example, Microsoft SharePoint's SOAP protocols and the Opentext Livelink's WebDAV protocols both support copy functions, but it is tedious to automate the movement of Livelink files into a SharePoint site.

This module defines standard (base class) methods for recursive copy operations, and relies on other modules to present protocol specific copy functions (like the SharePoint ones) as supplemental copy methods for the main module.  Therefore, all this module has to do is take care of the logistics of recursive copy.

To illustrate this, imagine that the SharePoint file system is a flathead screw, and our local file system is a Philips screw.  This particular module (CopyTree::VendorProof) would be a power drill - which is to say that it is utterly useless on its own.  To drive the flathead or the Phillips screw, you'd need a flathead bit (SharePoint::SOAPHandler) or a Phillips bit (CopyTree::VendorProof::LocalFileOp), which you buy at the local hardware store, or in our case, free from cpan.  The power drill is your base class that will spin things, and the bits are helper modules that provide specific methods so you can drive specific screws into the wall.

This module will enable copying between:

[a local computer and a remote file system] 

or 

[a remote file system and itself] 

or 

[local computer to local computer]

or

[various remote systems]. 

An example remote system would be Microsoft's SharePoint file 
storage, which takes commands via https.

The supported (very basic, but recursive) copy functionalities mimics
the unix 

	cp -rf

command - copies SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.

=head1 SYNOPSIS

#first, define the master copy instance (your power drill):

	use CopyTree::VendorProof;

	my $cpobj = CopyTree::VendorProof->new;

#second, define subsidiary connector instances (your drill bit):

	use SharePoint::SOAPHandler;
	my $sharepointobj = SharePoint::SOAPHandler ->new; 

#third, define the local connector instance (another drill bit):

	use CopyTree::VendorProof::LocalFileOp;
	my $localfileobj = CopyTree::VendorProof::LocalFileOp ->new;

#set up connection parameters for connectors (here SharePoint):
#(So your drill bit doesn't have the standard hex end, but instead, it has a rounded end with two slots poking out. We need a slot to hex adaptor for the drill bit.)

#do not include protocol ('https://')

	$sharepointobj ->sp_creds_domain('spserver.spdomain.org:443'); 
	$sharepointobj ->sp_creds_user('DOMAIN_NAME_CAPS\username');
	$sharepointobj ->sp_creds_password('ch1ckens');
	$sharepointobj ->sp_authorizedroot('https://spserver.spdomain.org:443/someroot/dir_under_which_Shared_Documents_appear'); 

#define source(s) along with their object type(s) for the master instance (decide which screws you want to unscrew out of the wall, and what kinda bits you need for the screw types)

#SOAPHandler objects always takes Shared Documents/ as start of a path

	$cpobj -> src('Shared Documents/somedir', $sharepointobj);

#add another SharePoint source:

	$cpobj -> src('Shared Documents/somefile', $sharepointobj);

#add a local source:

	$cpobj -> src('/home/username/Documents/somedir', $localfileobj);

#define destination along with its object type
#(where do you want your new screw to go in, and what type)

	$cpobj -> dst('/home/username/Documents', $localfileobj);

#issue the cp method to complete copy
#(undo the old screws, and insert the new one, using correct bits)

	$cpobj ->cp;
	$cpobj ->reset; #clears all src and dst

=head1 IDIOSYNCRASIES 

Some idiosyncrasies of this module is demonstrated using the unix cp command:

=head2 single file source

	cp path/src.file dst

If dst does not exist as a file or directory, it is treated as the new file name of src.file, and this operation is essentially a mv command.  If dst exists as a file, it is overwritten.  If dst exists as a dir, the basename of path/src.file is copied into the dir, and we get dst/src.file.

=head2 single dir source

	cp path/src.dir dst

If dst is a file, cp fails.  If dst does not exist as a dir, cp fails.  If dst exists as a dir, the basename of path/src.dir is copied into dst, and we get dst/src.dir.

=head2 mlti mixed source

	cp path/src.dir path2/file dst

If dst is a file, cp fails.  If dst does not exist as a dir, cp fails.  If dst exists as a dir, the basename of all files and dirs are copied into dst, and we get dst/src.dir and dst/file.

Note that in the cases where cp is allowed to proceed, and existing files will be overwritten.  This behavior relies on the subclasses write_from_memory and copy_local_files

=head1 HINT

Before jumping straight into copying the files and directories
that you desire, you might want to do a couple of things to 
avoid hitting connection issues vs file permission issues.

As a rule, always verify that you can actually connect to your 
remote resource first, and list the files that you want to copy.

For example, if I wanted to copy a file from SharePoint, I would
connect to it first by:

	#for most corporate environments, this is needed for sharepoint:	
	delete $ENV{'https_proxy'};
	
	use SharePoint::SOAPHandler;
	my $sharepointobj = SharePoint::SOAPHandler ->new; 

	#do not include protocol ('https://') for sp_cred_domain
	$sharepointobj ->sp_creds_domain('spserver.spdomain.org:443'); 
	$sharepointobj ->sp_creds_user('DOMAIN_NAME_CAPS\username');
	$sharepointobj ->sp_creds_password('ch1ckens');
	$sharepointobj ->sp_authorizedroot('https://spserver.spdomain.org:443/someroot/dir_under_which_Shared_Documents_appear'); 
	
	print "$_\n" for @{$sharepointobj ->fdls('', 'Shared_Documents')};

This enables me to see what's under Shared_Documents (or other dirs
that you may otherwise specify underneath it), to avoid typing
in the wrong file name and getting a vague 'denied' message.

=cut

=head1 DESCRIPTION

This module provides a generic interface to implement a copy method between [a local computer and a remote file system] or [a remote file system and itself] or [local computer to local computer] or [various remote file systems]. 

The supported (very basic) copy functionalities mimics the unix cp command - copies SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.

This whole project arose when I needed to automate file transfers between a locally mounted file system (be it just local files or samba) and a remote Microsoft SharePoint server.  Since at the time of writing (mid 2011), there wasn't a way to locally mount SharePoint directories that's connected through https, I'd decided to write connector modules for it.  Half way down the process, it occurred to me that this will not be the last time some vendor provides a non-standard interface for their services, so I reorganized this module to be adaptable to changes - as long as I can establish some basic functions of single file transfer, I can plug this module in and do more complex stuff such as copy entire directories.

This adaptability resulted in the semi complex model used to invoke a copy.  You basically need at least 2 objects for copy to work.  You need this module (CopyTree::VendorProof) to provide a base class to copy stuff with, but you also need at least one more module to provide data connection methods for retrieving a file, posting a file, listing a directory, and doing some sort of file tests for each protocol (be it a protocol for local file operations or a protocol for sharepoint operations).  In other words, you need an extra module per protocol, so if you want to copy from local to sharepoint, you need to load CopyTree::VendorProof::LocalFileOp (which I wrote) AND SharePoint::SOAPHandler (which I also wrote).  You would add sources and the destination of files or dirs that you wish to copy via (multiple) $vendorproof_instance ->src ($path, $connector_instance) and a single $vendorproof_instance ->dst($destinationpath, $another_connector_instance).  Once you've added all your sources, you would then run $vendorproof_instance ->cp; which would complete the copy operation as per your src, dst definitions.

The copy schemes are similar to unix' cp -rf ; i.e. copies SOURCE to DEST, or multiple SOURCE(s) to DIRECTORY.
Noting that:

=over

=item *

directory copies are recursive, and 
all copies are default overwrite
file names and directory names may contain spaces, and these spaces need not to be escaped.

=back

The primary use of this module is on a linux / unix system that needs to interact with a remote system.

=head1 VendorProof Class Methods

The methods provided in this module (base class) include:

=head2 new

	my $ctvp_inst = CopyTree::VendorProof ->new;

creates a new VendorProof object instance 

=head2 reset

	$ctvp_inst ->reset;

clears any previously set sources and destinations, retuns the instance.

=head2 src

	$ctvp_inst ->src($path, $path_instance)

adds a source and the connector instance of said source you may add multiple sources by invoking this multiple times

=head2 dst

	$ctvp_inst ->dst($dstpath, $dstpath_instance)

adds a destination and its connector instance

=head2 cp

	$ctvp_inst ->cp;

starts copy operation based on the $ctvp_inst->src and $ctvp_inst->dst that's initiated

=head2 copy_meth_deci

internal method - if source and destination are using the same object (for example, both on sharepoint), do not use the local memory as an intermediate data cache

=head2 ls_tree

	$ctvp_inst ->ls_tree($path)

returns a hash ref of the tree structure under $path, which files are undef, and dirs are references to yet another anonymous hash

=head2 ls_tree_fdret 
	
	$ctvp_inst->($root_path_name, $hashref)

takes a $root_path_name and the $hashref returned from a previous $ctvp->ls_tree and returns (\@files, \@dirs) with the $root_path_name added on as the parent of these @files and @dirs

=head2 path

This is not used by the VendorProof instance.  Instead, it provides a base class for connector instances to use to set a $path variable.  Not really used and not extensively tested.

=head2 fdls_ret

This method is provided as a base class for connector instances to use.  It provides common code for fdls methods from different connector objects.
	
Of the aforementioned methods, new, path, and reset are the only methods that do not require additional connector objects to function, although path has the sole function of providing a base class to connector objects.


=head1 Object specific instance methods for the base class CopyTree::VendorProof

Before you start involking CopyTree::VendorProof ->new, you'd better set up class instances for your source(s) and destination.  These class instances will provide class specific methods for file operations, which CopyTree::VendorProof relies on to carry out the cp -rf functionality. Since these are class methods, the first item from @_ is the instance itself, and should be stored in $inst, or whatever you'd like to call it.  The required class methods are described below (note that unless you're writing connecters - other than CopyTree::VendorProof::LocalFileOp or SharePoint::SOAPHandler - you will not need to know these methods, specifically.):

=head2 0. new

which takes no arguments, but blesses an anonymous hash into the data connection object and returns it.  If you're using Moose, it won't allow you to overwrite / redefine the new that's in the parent class, but that's okay. Use the parent class's new, and add a BUILD method that deletes 'source' and 'destination' hash keys, and you're set. If you're lazy, just don't use these keywords. 

=cut

=head2 1. fdls

which takes two arguments:

=over

=item *

$lsoption that's one of 'f', 'd', 'fdarrayrefs', or '', and

a directory path $startpath.

=back

The lsoption is passed to the SUPER class fdls_ret, and is not handled at this level.  

The $startpath should be standardized to start in a certain 'root' directory; for example, in SharePoint::SOAPHandler, it must start with "Shared Documents", and in Livelink::DAV, it must start with a dir right under the webdav root folder.  Spaces are allowed in the path names, and are handled transparently.

This method will generate @files and @dirs, which are lists of files and directories that start with $startpath, And returns 
	
	$self -> SUPER::fdls_ret ($lsoption, \@files, \@dirs),

which is ultimately a listing of the directory content, being one of @files, @dirs, (\@files, \@dirs), or  @files_and_dirs) depending on the options being 'f', 'd', 'fdarrayrefs' or ''

For example, if you have a tree structure:

	/home/
	/home/john
	/home/john/notes.txt
	/home/john/punch.mov
	/home/john/picutres
	/home/john/pictures/1.jpg

and your $startdir is /home/john, and your $lsoption is 'f':
You will create

	@files, which is ("/home/john/notes.txt", "/home/john/punch.mov")
	@dirs, which consist of ("/home/john/pictures")

And, the last line of your method (subroutine) will be

	return $self->SUPER::fdls_ret($lsoption, \@files, \@dirs);

=over

=item *

note, if you use Moose, simply return

	$self -> fdls_ret ($lsoption, \@files, \@dirs)

but remember to include an 'extends' statement for the base class:

	extends CopyTree::VendorProof;

=back

=cut 

=head2 2. is_fd

which takes a single argument of a file or dir $path, and returns 

	'd' for directory, 
	'f' for file,
	'pd' for non-existing, but has a valid parent dir,
	'0' for non of the above.

This code will vary by connector modules; most connectors have file test facilities to return 'f' or 'd', but most connectors we have to custom code the 'pd' test.  For connectors that can't tell 'f' or 'd' directly, we have to be creative and do a dir listing of the $path or do a dir listing of the $path's parent to guss what $path is.

=head2 3. read_into_memory

which takes the $sourcepath of a file, and reads (slurps) it into a scalar $binfile #preferably in binmode, and returns it as \$binfile

=head2 4. write_from_memory

which takes the reference to a scalar $binfile (\$binfile)  PLUS a destination path, and writes the scalar to the destination.  Do a is_fd check on destination, and perform no action if the destination exists as directory (base class handles that).  Only (over-)write if destination exists as a file, or create a new file using the destination path.  no return is necessary.  

=head2 5. copy_local_files

which takes the $source and $destination files on the same file system, and copies from $source to $destination.  No return is necessary.  This method is included such that entirely remote operations (limited to the same type of remote system) may transfer faster, without an intermediate 'download to local machine' step. Only proceeds if destination is not a dir.  When destination is a file, it is overwritten, and when it does not exist, it is created using the $destination name. In other words, is_fd should return 'f' or 'pd' to proceed.  

=head2 6. cust_mkdir

which takes a $dirpath and creates the dir.  If the parent of $dirpah does not exist, give a warning and do not do anything

=head2 7. cust_rmdir

which takes a $dirpath and removes the entire dir tree from $dirpath.  
cluck / warns if $dirpath is not a dir. No return is necessary.
	
If your connector does not know how to recursively remove a tree, you may use:

	my ($filesref, $dirsref) = $inst -> ls_tree_fdret( $dirpath, $inst -> ls_tree($dirpath);

to get array references of @files and @dirs under $dirpath, followed by manual removal of such files and dirs.

=over

=item *

Note: ls_tree and ls_tree_fdret are of the parent class CopyTree::VendorProof, and uses the connector specific fdls method from subclasses to complete their functions.

=back

=head2 8. cust_rmfile

which takes a $filepath and removes it.  cluck / warns if $file is not a file. 

=head2 EXPORT

None by default.

=head1 SEE ALSO

Check out 

CopyTree::VendorProof::LocalFileOp 
SharePoint::SOAPHandler
Livelink::DAV

=head1 AUTHOR

dbmolester, dbmolester de gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by dbmolester

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.

=cut

