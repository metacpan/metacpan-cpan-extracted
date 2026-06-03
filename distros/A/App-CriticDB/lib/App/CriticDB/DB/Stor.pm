package App::CriticDB::DB::Stor;
use strict;
use warnings;

use parent 'App::CriticDB::DB';

use Carp qw/confess/;
use Fcntl qw/:flock/;
use File::Temp qw//;
use Storable qw/nstore_fd fd_retrieve/;

our $VERSION='0.0.6';

sub storfileUnchanged {
	my ($self)=@_;
	return !$self->_fileNewer($$self{file},$$self{mtime});
}

sub read {
	my ($self)=@_;
	if($$self{mtime}&&!$self->_fileNewer($$self{file},$$self{mtime})) { return $self }
	if(!-e $$self{file}) { return $self->_init() }
	$$self{mtime}=time();
	open(my $fh,'<',$$self{file}) or confess("Read failed on $$self{file}:  $!");
	flock($fh, LOCK_SH) or confess("Cannot lock $$self{file} for reading:  $!");
	$$self{store}=fd_retrieve($fh);
	flock($fh, LOCK_UN);
	close($fh);
	return $self;
}

sub write {
	my ($self,$fn)=@_;
	if(!$$self{file})    { confess("Filename has not been specified") }
	if(!-e $$self{file}) { delete($$self{mtime}) }
	my ($fh,$tmpname,$lockfh);
	my $failed=sub {
		my ($message,$raw)=@_;
		if($tmpname) { unlink($tmpname) }
		if($lockfh)  { flock($lockfh,LOCK_UN); close($lockfh) }
		if($message) { confess("Failed to $message") }
		confess($raw);
	};
	$fh=File::Temp->new(TEMPLATE=>"$$self{file}-XXXXXXXX",UNLINK=>0,SUFFIX=>'.tmp',PERMS=>(0666&(~umask())));
	$tmpname=$fh->filename();
	nstore_fd($$self{store},$fh)    or &$failed("write to $tmpname");
	close($fh)                      or &$failed("fully write to $tmpname");
	open($lockfh,'>>',$$self{file}) or &$failed("open $$self{file}:  $!",undef($lockfh));
	flock($lockfh,LOCK_EX)          or &$failed("lock $$self{file} for writing:  $!");
	$self->storfileUnchanged()      or &$failed(0,"File changed underneath us, not yet handled");
	rename($tmpname,$$self{file})   or &$failed("rename $tmpname to $$self{file}:  $!");
	flock($lockfh, LOCK_UN);
	close($lockfh);
	$$self{mtime}=time();
	return $self;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB::Stor - Storable database for App::CriticDB

=head1 VERSION

Version 0.0.6

=head1 SYNOPSIS

  my $db=App::CriticDB::DB->new(mode=>'file',file=>'path.stor',type=>'storable');
  $db->store($filename,@violations);
  $db->write();

=head1 DESCRIPTION

Provides reading and writing of L<Storable> databases of L<Perl::Critic> violations for L<App::CriticDB>.  File locking prevents other processes from reading during writes.  Timestamps are checked to ensure other processes haven't updated the datafile; note that most systems only provide one-second resolution, but overwrites will be corrected with subsequent runs.  Complete file loss during crashing is guarded by writing to a temporary file and moving it into place.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
