package App::optex::Tmpfile;

use strict;
use warnings;
use Carp;
use Fcntl;
use IO::File;
use IO::Handle;

sub new {
    my $class = shift;
    my $fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
    $fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
    bless { FH => $fh }, $class;
}

sub write {
    my $obj = shift;
    my $fh = $obj->fh;
    if (@_) {
	my $data = join '', @_;
	$fh->print($data);
    }
    $obj;
}

sub flush {
    my $obj = shift;
    $obj->fh->flush;
    $obj;
}

sub rewind {
    my $obj = shift;
    $obj->fh->seek(0, 0) or die;
    $obj;
}

sub reset {
    my $obj = shift;
    $obj->rewind;
    $obj->fh->truncate(0);
    $obj;
}

sub fh {
    my $obj = shift;
    $obj->{FH};
}

sub fd {
    my $obj = shift;
    $obj->fh->fileno;
}

sub path {
    my $obj = shift;
    sprintf "/dev/fd/%d", $obj->fd;
}

1;
