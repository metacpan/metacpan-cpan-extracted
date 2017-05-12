package CopyTree::VendorProof::LocalFileOp;

use 5.008000;
use strict;
use warnings;

#our @ISA = qw(CopyTree::VendorProof); #if this weren't commented out, the use base below won't work

our $VERSION = '0.0013';
use Carp ();
use File::Basename ();
use MIME::Base64 ();
use Data::Dumper;
use base qw(CopyTree::VendorProof);#for the @ISAs
#use base happens at compile time, so we don't get the runtime error of our, saying that
#Can't locate package CopyTree::VendorProof for @SharePoint::SOAPHandler::ISA at (eval 8) line 2.


# Preloaded methods go here.

sub new {
	my $class =shift;
	my $path = shift;
	$path =~s/\/$// unless (!$path or $path eq '/');
	my $hashref;
	$hashref = bless {path => $path}, $class;
	return $hashref;
}

#lists files and / or dirs of a dir
sub fdls {
	my $inst = shift;
	
	unless (ref $inst ){
		Carp::croak("fdls item must be an instance, not a class\n");	
	}
	my $lsoption =shift;
	my $path =shift;
	$path =~s/\/$// unless (!$path or $path eq '/'); #removes trailing /

	$lsoption ='' if !($lsoption);
	$path = $inst ->SUPER::path if (!$path);
	my $dirH;
	opendir ($dirH, $path) or Carp::carp ("ERROR in local_ls cannot open dirH to $path $!\n");
	my @itemsnoparent =readdir $dirH;
	closedir $dirH;
	my @results;
	my @files;
	my @dirs;
	for (@itemsnoparent){
		next if  ($_ eq '.' or $_ eq '..');
		push @files, $path.'/'.$_ if (-f "$path/$_");
		push @dirs, $path.'/'.$_ if (-d "$path/$_");
	}
	$inst ->SUPER::fdls_ret ($lsoption, \@files, \@dirs);
}

sub is_fd{
	my $class_inst=shift;
	my $query = shift;
	if (-d $query){
		return 'd';
	}
	elsif (-f $query){
		return 'f';
	}
	else {
		my $parent = File::Basename::dirname($query);
		if (-d $parent){
			return 'pd';
		}
		else{return 0}
	}
}
#memory is a ref to a scalar, in bin mode
sub read_into_memory{
	my $inst=shift;
	my $sourcepath = shift;
	$sourcepath =~s/\/$// unless $sourcepath eq '/';
	$sourcepath=$inst->SUPER::path if (!$sourcepath);
	my $binfile;
	open my $readFH, "<", $sourcepath or  Carp::carp("cannot read sourcepath [$sourcepath] $!\n");
	binmode ($readFH);
	{#slurp
		local $/ =undef;
		$binfile = <$readFH>;
	}
	close $readFH;
	return \$binfile;

}
#memory is a ref to a scalar, in bin mode
sub write_from_memory{
	my $inst=shift;
	my $bincontentref = shift;
	my $dest = shift;
	$dest = $inst ->SUPER::path if (!$dest);
	open my $outFH, ">","$dest" or Carp::carp("cannot write to dest [$dest] $!\n");
	binmode ($outFH);
	print $outFH $$bincontentref ;
	close $outFH;


}

sub copy_local_files {
	my $inst = shift;
	my $source = shift;
	my $dest = shift;
	open my $inFH, "<", $source or Carp::carp( "cannot open source fh $source $!\n");
	open my $ouFH, ">", $dest or Carp::carp( "cannot open dest fh $dest $!\n");
	binmode ($inFH);
	binmode ($ouFH);
	{
		local $/=undef; #slurp 
		my $content = <$inFH>;
		print $ouFH $content;
	}
	close $inFH;
	close $ouFH;
}

sub cust_mkdir{
	my $inst = shift;
	my $path = shift;
	Carp::croak( "should not be mkdiring a root [/]\n" )unless $path ne '/';
	$path =~s/\/$// ; # purposefully disallow mkdir / unless $path eq '/';
	mkdir $path or Carp::carp ("cannot mkdir $path $!\n");

}
sub cust_rmdir{
	my $inst = shift;
	my $path = shift;
	Carp::croak( "should not be rmdiring a root [/]\n" )unless $path ne '/';
	$path =~s/\/$// ; # purposefully disallow rmdir / unless $path eq '/';
	unless (rmdir $path){
		Carp::carp( "the dir [$path] you want to remove is NOT EMPTY $!\n");
		Carp::croak( "wait. you told me to delete something that's not a dir. I'll stop for your protection.\n") if (! -d $path);
		my ($files, $dirs) = $inst ->ls_tree_fdret($path, $inst ->ls_tree($path) );
		print Dumper $files;
		print Dumper $dirs;
		Carp::carp( "danger - going to take out the whole tree under [$path]\n");
		Carp::carp( "going to wait 3 seconds. use Ctrl-c to escape this. Hold down the Ctrl key, and hit 'c'.\n");
		sleep 3;
		for (@$files){
			unlink $_ or Carp::carp ("cannot unlink $_ $!\n");
		}	
		for (@$dirs){
			rmdir $_ or Carp::carp ("cannot rmdir $_ $!\n");
		}
		rmdir $path;
	}
}
sub cust_rmfile {
	my $inst=shift;
	my $filepath=shift;
	Carp::croak("[$filepath] is not a file") if (! -f $filepath);
	unlink $filepath;
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CopyTree::VendorProof::LocalFileOp - Perl extension for providing a local (mounted filesystem) connecter instance for CopyTree::VendorProof.

This module provides CopyTree::VendorProof a connector instance with subclass methods to deal with local file operations.

What?

Oh, yes.  You've probabaly stumbled across this module because you wanted to copy something recursively.  Did you want to move some files into or off your SharePoint file server?  Did you buy Opentext's Livelink EWS and wish to automate some file transfers?  Well, this is kinda the right place, but it gets righter. Check out the documentation on my CopyTree::VendorProof module, where I have a priceless drill and screw analogy for how these modules all work together.  The information on this page is a tad too technical if all you're trying to decide is whether this is the module you need.

=head1 SYNOPSIS

  use CopyTree::VendorProof::LocalFileOp;

To create a LocalFileOp connector instance:

	my $lcfo_inst = CopyTree::VendorProof::LocalFileOp ->new;

To add a source or destination item to a CopyTree::VendorProof instance:

	my $ctvp_inst = CopyTree::VendorProof ->new;
	$ctvp_inst ->src ('some_source_path_of_local_file_system', $lcfo_inst);
	$ctvp_inst ->dst ('some_destination_path_of_local_file_system', $lcfo_inst);
	$ctvp_inst ->cp;


=head1 DESCRIPTION

CopyTree::VendorProof::LocalFileOp does nothing flashy - it merely provides a constructor method (new) and local file operation subclass methods for its parent class, CopyTree::VendorProof.

The subclass methods provided in this connector objects include:

	new
	fdls				
	is_fd
	read_info_memory
	write_from_memory
	copy_local_files
	cust_mkdir
	cust_rmdir
	cust_rmfile

The functionality of these methods are described in 

	CopyTree::VendorProof 

Under the section "Object specific instance methods for the base class CopyTree::VendorProof"

=head1 Instance Methods

This module only contain subclass methods described above.  Since perl knows how to handle local files, there's no point re-writing anything other than present these perl functions as recognizable methods for the parent class.

You shouldn't have to invoke these methods manually.  Consult the documentation of 

	CopyTree::VendorProof 

And look under the section "Object specific instance methods for the base class CopyTree::VendorProof"

=head1 SEE ALSO

CopyTree::VendorProof
SharePoint::SOAPHandler
Livelink::DAV

=head1 AUTHOR

dbmolester, dbmolester de gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by dbmolester

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.10.1 or, at your option, any later version of Perl 5 you may have available.  

=cut
