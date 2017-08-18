=head1 NAME

AnyEvent::DBI::Slave - implement AnyEvent::DBI child/server processes

=head1 SYNOPSIS

   # this module is normally loaded automatically

=head1 DESCRIPTION

This module contains the code that implements the DBI server part of
C<AnyEvent::DBI>. It is normally loaded automatically into each child
process, but can be loaded explicitly to save memory or startup time
(search for C<AnyEvent::DBI::Slave> in the L<AnyEvent::DBI> manpage).

=cut

package AnyEvent::DBI::Slave;

use common::sense;

use DBI ();
use Convert::Scalar ();
use CBOR::XS ();
use AnyEvent ();

our $VERSION = '3.0';

# this is the forked server code, could/should be bundled as it's own file

our $DBH;
our $STH;

sub req_pid {
   [1, $$]
}

sub req_open {
   my (undef, $dbi, $user, $pass, %attr) = @{+shift};

   $DBH = DBI->connect ($dbi, $user, $pass, \%attr) or die $DBI::errstr;

   [1, 1]
}

sub req_attr {
   my (undef, $attr_name, @attr_val) = @{+shift};

   $DBH->{$attr_name} = $attr_val[0]
      if @attr_val;

   [1, $DBH->{$attr_name}]
}

sub req_exec {
   my (undef, $st, @args) = @{+shift};
   $STH = $DBH->prepare_cached ($st, undef, 1)
      or die [$DBI::errstr];

   my $rv = $STH->execute (@args)
      or die [$STH->errstr];

   [1, $STH->{NUM_OF_FIELDS} ? $STH->fetchall_arrayref : undef, $rv]
}

sub req_stattr {
   my (undef, $attr_name) = @{+shift};

   [1, $STH->{$attr_name}]
}

sub req_begin_work {
   [1, $DBH->begin_work || die [$DBI::errstr]]
}

sub req_commit {
   [1, $DBH->commit     || die [$DBI::errstr]]
}

sub req_rollback {
   [1, $DBH->rollback   || die [$DBI::errstr]]
}

sub req_func {
   my (undef, $arg_string, $function) = @{+shift};
   my @args = eval $arg_string;

   die "error evaling \$dbh->func() arg_string: $@"
      if $@;

   my $rc = $DBH->func (@args, $function);
   return [1, $rc, $DBI::err, $DBI::errstr];
}

sub serve($$) {
   my ($fork_fh, $version, $fh) = @_;

   $0 = "dbi slave";

   close $fork_fh;

   if ($VERSION != $version) {
      Convert::Scalar::write_all $fh, CBOR::XS::encode_cbor
         [undef, "AnyEvent::DBI version mismatch ($VERSION vs. $version)"];
      return;
   }

   eval {
      my $cbor = new CBOR::XS;
      my $rbuf;

      while (Convert::Scalar::extend_read $fh, $rbuf, 16000) {
         for my $req ($cbor->incr_parse_multiple ($rbuf)) {
            my $wbuf = eval { CBOR::XS::encode_cbor  $req->[0]($req) };
            $wbuf = CBOR::XS::encode_cbor [undef, ref $@ ? ("$@->[0]", $@->[1]) : ("$@", 1)]
               if $@;

            Convert::Scalar::write_all $fh, $wbuf
               or die "unable to write results";
         }
      }
   };
}

=head1 SEE ALSO

L<AnyEvent::DBI>.

=head1 AUTHOR AND CONTACT

   Marc Lehmann <schmorp@schmorp.de> (current maintainer)
   http://home.schmorp.de/

   Adam Rosenstein <adam@redcondor.com>
   http://www.redcondor.com/

=cut

1
