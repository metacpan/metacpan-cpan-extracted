package BGS;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bgs_call bgs_back bgs_wait bgs_break);

our $VERSION = '0.08';

use IO::Select;
use Storable qw(freeze thaw);
use POSIX ":sys_wait_h";


$SIG{CHLD} = "IGNORE";

my $sel = IO::Select->new();

my %callbacks = (); 
my %fh2vpid   = (); 
my %vpid2fh   = (); 
my %vpid2pid  = (); 


sub bgs_call(&$) {
	my ($sub, $callback) = @_;

	pipe my $from_kid_fh, my $to_parent_fh or die "pipe: $!";

	my $kid_pid = fork;
	defined $kid_pid or die "Can't fork: $!";
	my $vpid = $kid_pid;

	if ($kid_pid) {
		$sel->add($from_kid_fh);
		$callbacks{$from_kid_fh} = $callback;
		$fh2vpid{$from_kid_fh} = $vpid;
		$vpid2fh{$vpid} = $from_kid_fh;
		$vpid2pid{$vpid} = $kid_pid;
	} else {
		binmode $to_parent_fh;
		print $to_parent_fh freeze \ scalar $sub->();
		close $to_parent_fh;
		exit;
	}
	return $vpid;
}

sub bgs_back(&) { shift }


sub bgs_wait() {
	local $SIG{PIPE} = "IGNORE";
	my %from_kid;       
	my $buf;            
	my $blksize = 1024; 
 	while ($sel->count()) {
 		foreach my $fh ($sel->can_read()) {
 			my $len = sysread $fh, $buf, $blksize;
 			if ($len) {
 				push @{$from_kid{$fh}}, $buf;
 			} elsif (defined $len) { 
				$sel->remove($fh); 
				close $fh or warn "Kid is existed: $?";

				if (exists $from_kid{$fh}) {
	 				my $r = join "", @{$from_kid{$fh}};
 					delete $from_kid{$fh};
					$callbacks{$fh}->(${thaw $r});
				} else {
					$callbacks{$fh}->();
				}

				my $vpid = $fh2vpid{$fh};
 				delete $callbacks{$fh};
				delete $fh2vpid{$fh};
				if ($vpid) {
					delete $vpid2fh{$vpid};
					delete $vpid2pid{$vpid};
				}

 			} else {
 				die "Can't read '$fh': $!";
 			}
 		}
 	}
}


sub _clean_by_vpid {
	my ($vpid) = @_;
	my $fh = $vpid2fh{$vpid} or return;

	$sel->remove($fh);
	close $fh;

	delete $callbacks{$fh};
	delete $fh2vpid{$fh};
	delete $vpid2fh{$vpid};
	delete $vpid2pid{$vpid};
}


sub bgs_break(;$) {
	my ($vpid) = @_;
	if (defined $vpid) {
		if (my $pid = $vpid2pid{$vpid}) {
			kill 15, $pid;
			1 while waitpid($pid, WNOHANG) > 0;
			_clean_by_vpid($vpid);
		}
	} else {
		local $SIG{TERM} = "IGNORE";
		kill 15, -$$;
		1 while waitpid(-1, WNOHANG) > 0;
		_clean_by_vpid($_) foreach keys %vpid2fh;
	}
}


1;


__END__


=head1 NAME

BGS - Background execution of subroutines in child processes.

=head1 SYNOPSIS

  use BGS;

  my @foo;

  foreach my $i (1 .. 2) {
    bgs_call {
      # child process
      return "Start $i";
    } bgs_back {
      # callback subroutine
      my $r = shift;
      push @foo, "End $i. Result: '$r'.\n";
    };
  }

  bgs_wait();

  print foreach @foo;

=head1 MOTIVATION

The module was created when need to receive information from dozens of
database servers in the shortest time appeared.

=head1 DESCRIPTION

=head2 bgs_call

Child process is created for each subroutine, that is prescribed with
B<bgs_call>, and it executes within this child process.

The subroutine must return either a B<scalar> or a B<reference>!

The answer of the subroutine passes to the callback subroutine as an argument.
If a child process ended without bgs_call value returning, than bgs_back subprogram is called without argument.

bgs_call return vpid (virtual pid) of child process.

=head2 bgs_back

The callback subroutine is described in B<bgs_back> block.

The answer of B<bgs_call> subroutine passes to B<bgs_back> subroutine
as an argument.

=head2 bgs_wait

Call of bgs_wait() reduces to child processes answers wait and
callback subroutines execution.

=head2 bgs_break

kill all or specific child processes.

Call bgs_break($vpid) to kill one process.

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
