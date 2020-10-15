package App::SimpleBackuper::StorageLocal;

use strict;
use warnings;

sub new {
	my($class, $path) = @_;
	
	die "Storage path '$path' doesn't exists" if ! -e $path;
	die "Storage path '$path' is not a directory" if ! -d $path;
	
	return bless { path => $path } => $class;
}

sub put {
	my($self, $name, $content_ref) = @_;
	
	open(my $fh, ">", "$self->{path}/$name") or die "Can't write to $self->{path}/$name: $!";
	print $fh $$content_ref;
	close($fh);
	
	return $self;
}

sub get {
	my($self, $name) = @_;
	
	open(my $fh, "<", "$self->{path}/$name") or die "Can't read from $self->{path}/$name: $!";
	my $content = join('', <$fh>);
	close $fh;
	
	return [$content];
}

sub remove {
	my($self, $name) = @_;
	
	unlink("$self->{path}/$name") or die "Can't remove $self->{path}/$name: $!";
	
	return $self;
}

sub listing {
	my($self) = @_;
	my %listing;
	opendir(my $dh, $self->{path}) or die "Can't open directory '$self->{path}': $!";
	while(my $file = readdir($dh)) {
		next if $file eq '..' or $file eq '.';
		$listing{ $file } = -s "$self->{path}/$file";
	}
	closedir($dh);
	
	return \%listing;
}

1;
