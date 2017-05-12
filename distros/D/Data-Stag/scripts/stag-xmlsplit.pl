#!/usr/local/bin/perl -w



use Data::Stag qw(:all);
use Data::Stag::XMLParser;
use Getopt::Long;
use strict;

my $split;
my $name;
my $dir;
GetOptions("split|s=s"=>\$split,
	   "name|n=s"=>\$name,
	   "dir|d=s"=>\$dir,
           "parser|format|p=s" => \$parser,
           "errhandler=s" => \$errhandler,
	  );

$errhandler =  Data::Stag->getformathandler($errhandler || 'xml');
my $h = Splitter->new;
my @pargs = (-file=>$fn, -format=>$parser, -handler=>$handler, -errhandler=>$errhandler);
if ($fn eq '-') {
    if (!$parser) {
	$parser = 'xml';
    }
    @pargs = (-format=>$parser, -handler=>$handler, 
	      -fh=>\*STDIN, -errhandler=>$errhandler);
}

$p->handler($h);
$split = $split || shift @ARGV;
$h->split_on_element($split);
$h->name_by_element($name);
if ($dir) {
    `mkdir $dir` unless -d $dir;
    $h->dir($dir);
}
if (!@ARGV) {
    die "no files passed!";
}
foreach my $xmlfile (@ARGV) {
    $p->parse($xmlfile);
}

package Splitter;
use base qw(Data::Stag::BaseHandler);
use Data::Stag qw(:all);

sub dir {
    my $self = shift;
    $self->{_dir} = shift if @_;
    return $self->{_dir};
}

sub split_on_element {
    my $self = shift;
    $self->{_split_on_element} = shift if @_;
    return $self->{_split_on_element};
}

sub name_by_element {
    my $self = shift;
    $self->{_name_by_element} = shift if @_;
    return $self->{_name_by_element};
}

sub i {
    my $self = shift;
    $self->{_i} = shift if @_;
    return $self->{_i} || 0;
}

sub end_event {
    my $self = shift;
    my $ev = shift;
    if ($ev eq $self->split_on_element) {
	my $topnode = $self->popnode;
	my $name_elt = $self->name_by_element;
	my $name;
	if ($name_elt) {
	    $name = stag_findnode($topnode, $name_elt);
	}
	if (!$name) {
	    $self->i($self->i()+1);
	    $name = $ev."_".$self->i;
	}
	my $dir = $self->dir || '.';
	my $fh = FileHandle->new(">$dir/$name.xml") || die;
	my $xml = stag_xml($topnode);
	print $fh $xml;
	$fh->close;
    }
    else {
	return $self->SUPER::end_event($ev, @_);
    }
}

1;
