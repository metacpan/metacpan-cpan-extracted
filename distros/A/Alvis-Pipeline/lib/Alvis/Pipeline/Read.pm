# $Id: Read.pm,v 1.12 2006/08/14 17:24:04 mike Exp $

package Alvis::Pipeline::Read;
use vars qw(@ISA);
@ISA = qw(Alvis::Pipeline);

use strict;
use warnings;
use IO::File;
use IO::Socket::INET;
use Fcntl qw(:flock);


sub new {
    my $class = shift();
    my(%opts) = @_;

    my $this = bless {}, $class;
    $this->{spooldir} = delete $opts{spooldir}
	or die "new($class) with no spooldir";
    $this->{port} = delete $opts{port}
	or die "new($class) with no port";

    $this->_setopts(sleep => 10, %opts);

    # Asynchronicity: server process accepts pushes and stores them
    $this->log(1, "forking");
    my $pid = fork();
    die "couldn't fork: $!" if !defined $pid;
    if ($pid == 0) {
	# Child process
	$this->_start_server();
	die "_start_server() returned!  It should never do that";
    }

    # Automatic reaper prevents the child going zombie when we kill
    # it.  (Yes, "IGNORE" has a special-case meaning for SIGCHLD.)
    $SIG{CHLD} = 'IGNORE';

    $this->{pid} = $pid;
    $this->log(1, "parent $$ spawned harvesting child, pid=$pid");
    return $this;
}


sub read {
    my $this = shift();
    my($block) = @_;

    $this->log(2, "parent reading from spooldir");
    my $dir = $this->{spooldir};
    my($fh, $lastread, $lastwrite) = $this->_lock_and_read($dir);
    while ($lastread == $lastwrite) {
	$this->_write_and_unlock($dir, $fh, $lastread, $lastwrite);
	return undef if !$block;
	$this->log(2, "no document yet, sleeping");
	sleep $this->option("sleep");
	($fh, $lastread, $lastwrite) = $this->_lock_and_read($dir);
    }

    $lastread++;
    my $filename = "$dir/$lastread";
    my $f2 = new IO::File("<$filename")
	or die "can't read file '$filename': $!";
    binmode $f2, ":utf8";
    my $doc = join("", <$f2>);
    $f2->close();
    unlink($filename);

    $this->_write_and_unlock($dir, $fh, $lastread, $lastwrite);
    return $doc;
}


sub close {
    my $this = shift();

    # We need to kill the child process that is running the OAI server
    # so that its Internet port is cleared for subsequent invocations.
    # Also so that the parent can exit cleanly.
    my $pid = $this->{pid};

    kill 15, $pid;
    sleep 1;

    if (kill 0, $pid) {
	warn "kill -15 failed; killing $pid with rude signal 9";
	kill 9, $pid;
	sleep 1;
    }

    if (kill 0, $pid) {
	die "can't kill child server with pid $pid";
    }
}


sub _start_server {
    my $this = shift();

    $this->log(1, "opening listener on port ", $this->{port});
    my $listener = new IO::Socket::INET(Listen => 1,
					LocalPort => $this->{port},
					Proto => "tcp",
					ReuseAddr => 1)
	or die("can't listen on port '" . $this->{port} . "': $!");

    while (1) {
	$this->log(1, "accepting connection");
	$this->{socket} = $listener->accept()
	    or die "can't accept connection: $!";

	binmode $this->{socket}, ":utf8";
	$this->log(1, "started background process, pid $$");
	while (1) {
	    my $doc = $this->_read();
	    last if !defined $doc;
	    $this->_store_file($doc);
	}
    }
}


sub _read {
    my $this = shift();

    my $s = $this->{socket}
	or die "$this reading from non-existent socket";

    my $magic = $s->getline();
    return undef if !defined $magic;
    $magic eq "Alvis::Pipeline\n" or die "incorrect magic '$magic'";
    my $version = $s->getline() or die "can't get protocol version: $!";
    $version == 1 or die "unsupported protocol version '$version'";
    my $count = $s->getline() or die "can't get object-length byte-count: $!";
    chomp($count);
    my $buf;
    my $nread = $s->read($buf, $count); ### multiple reads may be necessary
    die "can't read document: $!" if !defined $nread;
    die "document was short: $nread of $count bytes" if $nread != $count;
    my $term = $s->getline() or die "can't get terminator: $!";
    $term eq "--end--\n" or die "incorrect terminator '$term'";

    return $buf;
}


sub _store_file {
    my $this = shift();
    my($doc) = @_;

    $this->log(2, "child writing to spooldir");
    my $dir = $this->{spooldir};
    my($fh, $lastread, $lastwrite) = $this->_lock_and_read($dir);

    $lastwrite++;
    my $filename = "$dir/$lastwrite";
    my $f2 = new IO::File(">$filename")
	or die "can't create new file '$filename': $!";
    binmode $f2, ":utf8";
    $f2->print($doc) or die "can't write '$filename': $!";
    $f2->close() or die "can't close '$filename': $!";

    $this->_write_and_unlock($dir, $fh, $lastread, $lastwrite);
}


# A sequence file called "seq" is maintained in the spool directory,
# and is always locked when read and rewritten.  The invariant it
# preserves between lock-read-write operations is that it contains two
# numbers, space-serarate, followed by a newline.  The first number is
# that of the last document read from the spool directory.  The second
# number is that of the last document written to the spool directory,
# or zero if no document has yet been written.  If the two numbers are
# equal, there are no documents available to be read.
#
# _lock_and_read() and _write_and_unlock() together implement safe
# maintenance of the sequence file.  The former returns a filehandle,
# locked; it is the caller's responsibility to unlock the returned
# filehandle using _write_and_unlock(), like this:
#	($fh, $lastread, $lastwrite) = $this->_lock_and_read($dir);
#	# Do some stuff
#	$this->_write_and_unlock($dir, $fh, $lastread, $lastwrite);
#
sub _lock_and_read {
    my $this = shift();
    my($dir) = @_;

    my $seqfile = "$dir/seq";
    my $fh;
    if (! -d $dir) {
	mkdir($dir, 0777)
	    or die "can't create directory '$dir': $!";
	my $f = new IO::File(">$seqfile")
	    or die "can't create initial '$seqfile': $!";
	$f->close();
    }

    $fh = new IO::File("+<$seqfile")
	or die "can't read '$seqfile': $!";

    flock($fh, LOCK_EX) or die "can't lock '$seqfile': $!";
    seek($fh, 0, SEEK_SET) or die "can't seek to start of '$seqfile': $!";
    my($lastread, $lastwrite);
    my $line = $fh->getline();
    if (defined $line) {
	($lastread, $lastwrite) = ($line =~ /(\d+) (\d+)/);
    } else {
	# File is empty: must have just been created
	$lastread = $lastwrite = 0;
    }

    $this->log(3, "got lastread='$lastread', lastwrite='$lastwrite'");
    return ($fh, $lastread, $lastwrite);
}


sub _write_and_unlock {
    my $this = shift();
    my($dir, $fh, $lastread, $lastwrite) = @_;

    my $seqfile = "$dir/seq";
    use Carp;
    seek($fh, 0, SEEK_SET) or confess "can't seek to start of '$seqfile': $!";
    $fh->print("$lastread $lastwrite\n") or die "can't rewrite '$seqfile': $!";
    flock($fh, LOCK_UN) or die "can't unlock '$seqfile': $!";
    $fh->close() or die "Truly unbelievable";
    $this->log(3, "put lastread='$lastread', lastwrite='$lastwrite'");
}


# Test harness follows
#	my $p = bless {
#	    spooldir => "/tmp/ap",
#	}, "Alvis::Pipeline::Read";
#	
#	if (@ARGV) {
#	    $p->_store_file(join("", @ARGV));
#	} else {
#	    my $doc = $p->read();
#	    die "no document queued" if !defined $doc;
#	    print $doc;
#	}

1;
