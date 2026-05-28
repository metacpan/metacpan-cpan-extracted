package App::CriticDB::DB::Stor;
use strict;
use warnings;

use parent 'App::CriticDB::DB';

use Carp qw/confess/;
use Fcntl qw/:flock/;
use Storable qw/nstore_fd fd_retrieve/;

our $VERSION='0.0.4';

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
	if(!$$self{file}) { confess("Filename has not been specified") }
	if((-e $$self{file})&&$self->_fileNewer($$self{file},$$self{mtime})) { confess("File changed underneath us, not yet handled") }
	open(my $fh,'>>',$$self{file}) or confess("Cannot write to $$self{file}:  $!");
	flock($fh, LOCK_EX) or confess("Cannot lock $$self{file} for writing:  $!");
	truncate($fh,0);
	nstore_fd($$self{store},$fh);
	flock($fh, LOCK_UN);
	close($fh);
	$$self{mtime}=time();
	return $self;
}

1;

__END__

=pod

=head1 NAME

App::CriticDB::DB::Stor - Storable database for App::CriticDB

=head1 VERSION

Version 0.0.4

=head1 SYNOPSIS

  my $db=App::CriticDB::DB->new(mode=>'file',file=>'path.stor',type=>'storable');
  $db->store($filename,@violations);
  $db->write();

=head1 DESCRIPTION

Provides reading and writing of L<Storable> databases of L<Perl::Critic> violations for L<App::CriticDB>.  File locking prevents other processes from reading during writes.

=head1 AUTHORS

Brian Blackmore (brian@mediaalpha.com).

=head1 COPYRIGHT

  Copyright (c) 2025--2035, MediaAlpha.com.

This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License Version 3 as published by the Free Software Foundation.

=cut
