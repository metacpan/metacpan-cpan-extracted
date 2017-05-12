#!/usr/local/bin/perl -w

# POD docs at end of file

use strict;

use Carp;
use FileHandle;
use Getopt::Long;

my $debug;
my $help;
GetOptions(
           "help|h"=>\$help,
          );

foreach my $fn (@ARGV) {
    sl2sql($fn);
}
exit 0;

sub sl2sql {
    my $fn = shift;
    my $fh = FileHandle->new($fn) || die("can't open $fn");
    my @domains = ();

    while(<$fh>) {
	chomp;
	s/\%.*//;
	s/\s+$//;
	next unless $_;
	if (/^:(\w+)\s+(.*)/) {
	    my $cmd = $1;
	    my $rest = $2;
	    my $cmt = '';
	    if ($rest =~ /\#\s*(.*)/) {
		$cmt = $1;
		$rest =~ s/\#.*//;
	    }
	    my @args = split(' ', $rest);
	    if ($cmd eq 'domain') {
		my $d = [shift @args, join(' ', @args)];
		push(@$d,
		     $args[0] =~ /^[A-Z]/ ?
		     'primitive' : 'relation');
		push(@$d, $cmt);
		push(@domains, $d);
	    }
	    if ($cmd eq 'import') {
		print "-- $_\n";
		push(@domains, [$args[0], $args[0], 'relation', '']);
	    }
	    
	}
	elsif (/^\#/) {
	    s/\#/\-\-/;
	    print "$_\n";
	}
	else {
	    if (/^(\w+)\((.*)\)\s*(.*)/) {
		my $rel = $1;
		my $argstr = $2;
		my $sep = $3;
		my @cmts = ();
		my @constraints = ();

		if ($sep eq ':-') {
		    while(<$fh>) {
			chomp;
			s/\s+$//;
			last unless $_;
			if (/\s+(.*)/) {
			    my $line = $1;
			    my $last;
			    if ($line =~ /\#\s*(.*)/) {
				push(@cmts, $1);
				$line =~ s/\#.*//;
			    }
			    $line =~ s/\,$//;
			    if ($line =~ /\.$/) {
				$line =~ s/\.$//;
				$last = 1;
			    }
			    if ($line =~ /:(.*)/) {
#				push(@cmts, $1);
			    }
			    else {
				push(@constraints, $line) if $line;
			    }
			    last if $last;
			}
			else {
			    last;  # must have indent
			}
		    }
		    if (@cmts) {
			push(@cmts, '');
		    }
		}

		my @args = split(/,\s*/, $argstr);
		push(@domains, [$rel, $rel, 'relation']);
		my @cols =
		  map {
		      my $col = $_;
		      my $nullable = 0;
		      if ($col =~ /\?$/) {
			  $nullable = 1;
			  $col =~ s/\?$//;
		      }
		      my $type = 'TEXT';
		      my $qual = '';
		      my $cmt = '';

		      if ($col eq '*') {
			  $col = $rel .'_id';
			  $type = "SERIAL";
			  $nullable = 0;
		      }
		      else {
			  my ($d) = grep {$_->[0] eq $col} @domains;
			  if ($d) {
			      $cmt = $d->[3];
			      $type = $d->[1];
			      if ($d->[2] eq 'relation') {
				  $col .= '_id';
				  $qual =
				    sprintf("REFERENCES $type(%s)",
					    $type.'_id');
				  $type = "INTEGER";
			      }
			  }
			  else {
			      warn $col;
			  }
		      }
		      unless ($nullable) {
			  $qual = "NOT NULL $qual";
		      }
		      my $all = sprintf("%-20s %-12s %s",
					$col, $type, $qual);
		      push(@cmts, 
			   sprintf("%-20s: $cmt",
				   $col)) if $cmt;
#		      if ($cmt) {
#			  #			  $all = "-- $cmt\n    $all";
#			  $all = sprintf("%-60s -- $cmt", $all);
#		      }
		      $all;
		  } @args;

		# blank line
		$constraints[0] = "\n$constraints[0]" if @constraints;

		createtable($rel, [@cols, @constraints], [@cmts]);
	    }
	    else {
		warn $_;
	    }
	}
    }

    $fh->close;
}

sub createtable {
    my $tbl = shift;
    my $cols = shift;
    my $cmts = shift || [];
    my $cmtstr =
      join('', map {"-- $_\n"} @$cmts);
    printf "\n\n-- RELATION: $tbl\n--\n$cmtstr--\n";
    printf("CREATE TABLE $tbl (\n%s\n);\n",
	   join(",\n", map { s/\s+$//;s/(\n*)\s*(.*)/$1    $2/;$_} @$cols));
    print "-- ****************************************\n";
}


__END__

=head1 NAME 

stag-sl2sql.pl

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

