package Apache::TieBucketBrigade;

use 5.008001;

use strict;
use warnings;

use Apache::Connection ();
use APR::Bucket ();
use APR::Brigade ();
use APR::Util ();
use APR::Const -compile => qw(SUCCESS EOF);
use Apache::Const -compile => qw(OK MODE_GETLINE);
use APR::Const -compile => qw(NONBLOCK_READ POLLIN TIMEUP);
use APR::Socket ();
use IO::WrapTie;
use Apache::Filter;
use IO::File;

use base qw(IO::WrapTie::Slave Class::Data::Inheritable);
#our @ISA = qw

our $VERSION = '0.05';

__PACKAGE__->mk_classdata('handles');
__PACKAGE__->{handles} = {};

use ex::override
    GLOBAL_select =>
    sub {
        if (@_ == 1) {
            #ignore selecting filehandle
            my $sh = shift;
            unless (ref($sh)) {
                my $caller = caller();
                $sh = \*{$caller .'::'. $sh};
            }
            return CORE::select();
        }
        elsif (@_ == 4) {
            my @bits = @_;
            foreach my $fn (keys %{__PACKAGE__->{handles}} ) {
                #check each phony fileno in our array to see if it matches
                my $rin = vec($bits[0],$fn,1) if $bits[0];
                my $win = vec($bits[1],$fn,1) if $bits[1];
                my $ein = vec($bits[2],$fn,1) if $bits[2];
                if ($rin or $win or $ein) {
                    my $fh = __PACKAGE__->{handles}->{$fn}->{apache};
                    my $conn = $fh->connection;
                    my $pool = $conn->pool;
                    my $sock = $conn->client_socket;

                    my $timeout = $bits[3];
                    $timeout = -1 unless defined $timeout;
                    $timeout = $timeout * 1_000_000 if $timeout > 0;

                    # XXX: APR::Socket->poll() really should return
                    # the number of sockets successfully polled along with
                    # the time left. We have to fake it here.
                    my $rc = $sock->poll($pool, $timeout, APR::POLLIN);
                    if($rc == APR::SUCCESS) {
                        return wantarray ? (1, $bits[3]) : 1;
                    }
                    elsif($rc == APR::TIMEUP) {
                        return wantarray ? (0, 0) : 0;
                    }
                    else {
                        die "Failed to poll socket: " .
                            APR::Error::strerror($rc);
                    }
                }
            }

            #if we haven't returned by now then it's just a normal
            #select on some other fileno, use CORE::select
            return
                CORE::select($_[0],$_[1],$_[2],$_[3]);
        }
        else {
            #some idiot doesn't know how to use select
            die "WTF ?";
        }
};


sub TIEHANDLE {
    my $invocant = shift;
    my $connection = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {                            
        @_,
    };
    bless $self, $class;
    $self->{bbin} = APR::Brigade->new($connection->pool,
                                      $connection->bucket_alloc);
    $self->{bbout} = APR::Brigade->new($connection->pool,
                                       $connection->bucket_alloc);
    $self->{connection} = $connection;
    return $self;
}

sub PRINT {
    my $self = shift;
    my $bucket;
    foreach my $line (@_) {
        $bucket = APR::Bucket->new($line);
        $self->{bbout}->insert_tail($bucket);
    }

    my $bkt = APR::Bucket::flush_create($self->{connection}->bucket_alloc);
    $self->{bbout}->insert_tail($bkt);
    $self->{connection}->output_filters->pass_brigade($self->{bbout});
}

sub WRITE {
    my $self = shift;
    my ($buf, $len, $offset) = @_;
    return undef unless $self->PRINT(substr($buf, $offset, $len));
    return length substr($buf, $offset, $len);
}

sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    $self->PRINT(sprintf($fmt, @_));
}

sub READLINE {
    my $self = shift;
    my $out;
    my $last = 0;
    while (1) {
        my $rv = $self->{connection}->input_filters->get_brigade(
            $self->{bbin}, Apache::MODE_GETLINE);
        if ($rv != APR::SUCCESS && $rv != APR::EOF) {
            die "get_brigade: " . APR::strerror($rv);
            last;
        }
        last if $self->{bbin}->is_empty;
        while (!$self->{bbin}->is_empty) {
            my $bucket = $self->{bbin}->first;
            $bucket->remove;
            last if ($bucket->is_eos);
            my $data;
            my $status = $bucket->read($data, APR::NONBLOCK_READ);
            $out .= $data;
            last unless $status == APR::SUCCESS;
            if (defined $data) {
                $last++ if $data =~ /[\r\n]+$/;
                last if $last;
            }
        }
        last if $last;
    }
    return undef unless defined $out;
    return $out if $out =~ /[\r\n]+$/;
    return $out;
}

sub GETC {
    my $self = shift;
    my $char;
    $self->READ($char, 1, 0);
    return undef unless $char;
    return $char;
}

sub READ {
#this buffers however many unused bytes are read from the bucket
#brigade into $self->{'_buffer'}.  Repeated calls should retreive anything
#left in the buffer before more stuff is received
    my $self = shift;
    my $bufref = \$_[0];
    my (undef, $len, $offset) = @_;
    my $out = $self->{'_buffer'} if defined $self->{buffer};
    my $last = 0;
    while (1) {
        my $rv = $self->{connection}->input_filters->get_brigade(
            $self->{bbin}, Apache::MODE_GETLINE);
        if ($rv != APR::SUCCESS && $rv != APR::EOF) {
            my $error = APR::strerror($rv);
            die "get_brigade: " . APR::strerror($rv);
            last;
        }
        last if $self->{bbin}->is_empty;
        while (!$self->{bbin}->is_empty) {
            my $bucket = $self->{bbin}->first;
            $bucket->remove;
            $last++ and last if ($bucket->is_eos);
            my $data;
            my $status = $bucket->read($data, APR::NONBLOCK_READ);
            $out .= $data;
            $last++ and last unless $status == APR::SUCCESS;
            $last++ and last unless defined $data;
            if (defined $out) {
                $last++ if length $out >= $len;
                last if $last;
            }
        }
        last if $last;
    }
    $self->{bbin}->destroy;
    if (length $out > $len) {
        $self->{'_buffer'} = substr $out, $len + $offset;
        $out = substr $out, $offset, $len;
    }
    $$bufref .= $out;
    return length $out
}

sub CLOSE {
#close the socket and clean up the Sneaky globals
    my $self = shift;
    my $c = $self->{connection};
    my $sock = $c->client_socket;
    delete __PACKAGE__->{handles}->{$self->{fileno}};
    return $sock->close;
}

sub OPEN {
   return shift;
}

sub FILENO {
#gets a unique fileno from new_tmpfile but pretends that this is the fileno
#for the apache brigade.  Stores the fake filehandle in a global so that it
#won't go away until cleanup.
#stores the real filehandle in the same global array so that we can look it up
#by fileno later, and store the fileno in the object so we can look it up
#there later for destruction of the global
#this might cause all sorts of resource problems
    my $self = shift;
    return $self->{fileno} if defined $self->{fileno};
    my $fh = IO::File->new_tmpfile;
    my $fn = fileno($fh);

    __PACKAGE__->{handles}->{$fn} = {fake => $fh,
                                     apache => $self};

    $self->{fileno} = $fn;
    return fileno($fh);
}

sub connection {
    my $self = shift;
    return $self->{connection};
}

1;

package IO::WrapTie::Master;
#this is some sketchy shit

no warnings;

*IO::WrapTie::Master::autoflush = sub {
    shift;
    return !$_[0];
};
  
# Check out the IO::Handle documentation for the blocking() method
# to read how this function is supposed to work.
*IO::WrapTie::Master::blocking = sub {
    my $h = shift;
    my $new_blocking = shift;
    my $c = $h->connection();
    my $sock = $c->client_socket;

    my $old_blocking = $sock->opt_get(APR::SO_NONBLOCK);
    if(defined $new_blocking) {
        $sock->opt_set(APR::SO_NONBLOCK, !$new_blocking);
        return $old_blocking;
    }
    else {
        return $old_blocking;
    }
};

use warnings;

1;

__END__

=head1 NAME

Apache::TieBucketBrigade - Perl extension which ties an IO::Handle to Apache's
Bucket Brigade so you can use standard filehandle type operations on the 
brigade.

=head1 SYNOPSIS

  use Apache::Connection ();
  use Apache::Const -compile => 'OK';
  use Apache::TieBucketBrigade;
  
  sub handler { 
      my $FH = Apache::TieBucketBrigade->new_tie($c);
      my @stuff = <$FH>;
      print $FH "stuff goes out too";
      $FH->print("it's and IO::Handle too!!!");
      Apache::OK;
  }

=head1 DESCRIPTION

This module has one usefull method "new_tie" which takes an Apache connection
object and returns a tied IO::Handle object.  It should be used inside a 
mod_perl protocol handler to make dealing with the bucket brigade bitz 
easier.  FILENO will emulate a real fileno (using FILE::IO::new_tmpfile) and
overrides CORE::select so that 4 arg select will work as expected 
(APR::Socket->poll underneath).  IO::Handle::blocking will also work to set
BLOCKING or NONBLOCKING, however autoflush is a noop.  New to this version,
closing the filehandle will actually close the connection.  Note that several
things here are a bit hackish, and there is the potential for resource problems
since twice as many real file descriptors are used if FILENO is used then 
would otherwise be if I didn't have to fake it.

This module requires mod_perl 1.99_18 or greater (so that support for 
APR::Socket->poll is included) otherwise it won't work.

=head2 EXPORT

None

=head2 BUGS

Many, I know for a fact everything other than readline, write, close, fileno
and tiehandle doesn't work properly.  The above are probably buggy as hell.
Also the test suite is just broken.  As soon as I fix it the above bugs should
be resolved.

=head1 SEE ALSO

IO::Stringy
mod_perl
IO::Handle

=head1 AUTHOR

mock E<lt>mock@obscurity.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Will Whittaker and Ken Simpson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
