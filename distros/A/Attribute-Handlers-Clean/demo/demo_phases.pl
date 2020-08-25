#! /usr/local/bin/perl -w

use Attribute::Handlers::Clean;
use Data::Dumper 'Dumper';

sub Beginner : ATTR(SCALAR,BEGIN,END)
	{ print STDERR "Beginner: ", Dumper \@_}

sub Checker : ATTR(CHECK,SCALAR)
	{ print STDERR "Checker: ", Dumper \@_}

sub Initer : ATTR(SCALAR,INIT)
	{ print STDERR "Initer: ", Dumper \@_}

package Other;
main->import;
# Or:
# use your_class;

my $x :Initer(1) :Checker(2) :Beginner(3);
my $y :Initer(4) :Checker(5) :Beginner(6);
