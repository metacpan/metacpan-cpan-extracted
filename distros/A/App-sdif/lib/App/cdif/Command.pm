package App::cdif::Command;

use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

use parent "App::cdif::Tmpfile";

sub new {
    my $class = shift;
    my $obj = new App::cdif::Tmpfile;
    bless $obj, $class;
    $obj->command(@_) if @_;
    $obj;
}

sub command {
    my $obj = shift;
    if (@_) {
	$obj->{COMMAND} = [ @_ ];
    } else {
	@{$obj->{COMMAND}};
    }
}

sub update {
    use Time::localtime;
    my $obj = shift;
    $obj->data(join "\n", map { execute($_) } $obj->command);
    $obj->date(ctime());
    $obj;
}

sub execute {
    my $command = shift;
    my @command = ref $command eq 'ARRAY' ? @$command : ($command);
    use IO::File;
    my $pid = (my $fh = new IO::File)->open('-|') // die "open: $@\n";
    if ($pid == 0) {
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

1;
