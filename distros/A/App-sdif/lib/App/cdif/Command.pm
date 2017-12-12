package App::cdif::Command;

use strict;
use warnings;
use Carp;

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
    $obj->data(join "\n", map { scalar `$_` } $obj->command);
    $obj->date(ctime());
    $obj;
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
