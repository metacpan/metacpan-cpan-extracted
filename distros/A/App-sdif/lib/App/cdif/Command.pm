package App::cdif::Command;

use strict;
use warnings;
use utf8;
use Carp;
use Fcntl;
use IO::File;
use IO::Handle;
use Data::Dumper;

use parent "App::cdif::Tmpfile";

sub new {
    my $class = shift;
    my $obj = SUPER::new $class;
    $obj->command(@_) if @_;
    $obj;
}

sub command {
    my $obj = shift;
    if (@_) {
	$obj->{COMMAND} = [ @_ ];
	$obj;
    } else {
	@{$obj->{COMMAND}};
    }
}

sub update {
    use Time::localtime;
    my $obj = shift;
    $obj->data(join "\n", map { $obj->execute($_) } $obj->command);
    $obj->date(ctime());
    $obj;
}

sub execute {
    my $obj = shift;
    my $command = shift;
    my @command = ref $command eq 'ARRAY' ? @$command : ($command);
    use IO::File;
    my $pid = (my $fh = new IO::File)->open('-|') // die "open: $@\n";
    if ($pid == 0) {
	if (my $stdin = $obj->{STDIN}) {
	    open STDIN, "<&=", $stdin->fileno or die "open: $!\n";
	    binmode STDIN, ':encoding(utf8)';
	}
	open STDERR, ">&STDOUT";
	exec @command;
	die "exec: $@\n";
    }
    binmode $fh, ':encoding(utf8)';
    do { local $/; <$fh> };
}

sub data {
    my $obj = shift;
    if (@_) {
	$obj->reset->write(shift)->flush->rewind;
	$obj;
    } else {
	$obj->rewind;
	my $data = do { local $/; $obj->fh->getline } ;
	$obj->rewind;
	$data;
    }
}

sub date {
    my $obj = shift;
    @_ ? $obj->{DATE} = shift : $obj->{DATE};
}

sub stdin {
    my $obj = shift;
    $obj->{STDIN};
}

sub setstdin {
    my $obj = shift;
    my $data = shift;
    my $fh = $obj->{STDIN} //= do {
	my $stdin = new_tmpfile IO::File or die "new_tmpfile: $!\n";
	$stdin->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
	binmode $stdin, ':encoding(utf8)';
	$stdin;
    };
    $fh->seek(0, 0)  or die "seek: $!\n";
    $fh->truncate(0) or die "truncate: $!\n";
    $fh->print($data);
    $fh->seek(0, 0)  or die "seek: $!\n";
    $obj;
}

1;
