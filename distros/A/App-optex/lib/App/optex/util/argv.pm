package App::optex::util::argv;

1;

package util::argv;

use v5.10;
use strict;
use warnings;
use utf8;
use Encode;
use Data::Dumper;

my($mod, $argv);
sub initialize { ($mod, $argv) = @_ }

binmode STDIN,  ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";

sub argv (&) {
    my $sub = shift;
    @$argv = $sub->(@$argv);
}

=head1 NAME

util - optex argument utility modules

=head1 SYNOPSIS

optex command -Mutil::argv

=head1 DESCRIPTION

This module is a collection of sample utility functions for command
B<optex>.

Function can be called with option declaration.  Parameters for the
function are passed by name and value list: I<name>=I<value>.  Value 1
is assigned for the name without value.

In this example,

    optex -Mutil::function(debug,message=hello,count=3)

option I<debug> has value 1, I<message> has string "hello", and
I<count> also has string "3".

=head1 FUNCTION

=over 4

=cut

######################################################################
######################################################################

sub times {
    my %opt = @_;
    my $count = $opt{count} // 2;
    argv {
	map {
	    my $dup = $opt{suffix} // '';
	    ( $_, ($_ . $dup) x ($count - 1) );
	} @_;
    }
}

=item B<times>(I<count>=I<n>,I<suffix>=I<str>)

Multiply each arguments.  Default I<count> is 2.

    % optex echo -Mutil::times(count=3) 1 2 3
    1 1 1 2 2 2 3 3 3

Put I<suffix> to duplicated arguments.

    % optex echo -Mutil::times(suffix=.bak) a b c
    a a.bak b b.bak c c.bak

=cut

######################################################################

sub rev_arg {
    argv { reverse @_ };
}

=item B<rev_arg>()

Reverse arguments.

=cut

######################################################################

my @persist;

sub proc {
    argv {
	for (@_) {
	    my($command) = /^ \<\( (.*) \) $/x or next;
	    my $tmp = new Tmpfile;
	    $tmp->write(`$command`)->rewind;
	    push @persist, $tmp;
	    $_ = $tmp->path;
	}
	@_;
    }
}

=item B<proc>()

Process substitution.

    % optex diff -Mutil::argv::proc= '<(date)' '<(date -u)'

=cut

######################################################################
######################################################################

=back

=cut

1;

package Tmpfile;

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

__DATA__
