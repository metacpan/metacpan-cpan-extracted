package App::cdif::Command;

use v5.14;
use warnings;
use utf8;
use Carp;
use Fcntl;
use IO::File;
use IO::Handle;
use Data::Dumper;

use parent "App::cdif::Tmpfile";

our $debug;
sub debug {
    my $obj = shift;
    if (@_) {
	$debug = shift;
    } else {
	$debug;
    }
}

sub new {
    my $class = shift;
    my $obj = $class->SUPER::new;
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
    my $pid = (my $fh = IO::File->new)->open('-|') // die "open: $@\n";
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
    my $stdin = $obj->{STDIN} //= do {
	my $fh = new_tmpfile IO::File or die "new_tmpfile: $!\n";
	$fh->fcntl(F_SETFD, 0) or die "fcntl F_SETFD: $!\n";
	binmode $fh, ':encoding(utf8)';
	$fh;
    };
    $stdin->seek(0, 0)  or die "seek: $!\n";
    $stdin->truncate(0) or die "truncate: $!\n";
    $stdin->print($data);
    $stdin->seek(0, 0)  or die "seek: $!\n";
    $obj;
}

1;
