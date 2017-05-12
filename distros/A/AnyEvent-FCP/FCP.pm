=head1 NAME

AnyEvent::FCP - freenet client protocol 2.0

=head1 SYNOPSIS

   use AnyEvent::FCP;

   my $fcp = new AnyEvent::FCP;

   # transactions return condvars
   my $lp_cv = $fcp->list_peers;
   my $pr_cv = $fcp->list_persistent_requests;

   my $peers = $lp_cv->recv;
   my $reqs  = $pr_cv->recv;

=head1 DESCRIPTION

This module implements the freenet client protocol version 2.0, as used by
freenet 0.7. See L<Net::FCP> for the earlier freenet 0.5 version.

See L<http://wiki.freenetproject.org/FreenetFCPSpec2Point0> for a
description of what the messages do.

The module uses L<AnyEvent> to find a suitable event module.

Only very little is implemented, ask if you need more, and look at the
example program later in this section.

=head2 EXAMPLE

This example fetches the download list and sets the priority of all files
with "a" in their name to "emergency":

   use AnyEvent::FCP;

   my $fcp = new AnyEvent::FCP;

   $fcp->watch_global (1, 0);
   my $req = $fcp->list_persistent_requests;

TODO
   for my $req (values %$req) {
      if ($req->{filename} =~ /a/) {
         $fcp->modify_persistent_request (1, $req->{identifier}, undef, 0);
      }
   }

=head2 IMPORT TAGS

Nothing much can be "imported" from this module right now.

=head1 THE AnyEvent::FCP CLASS

=over 4

=cut

package AnyEvent::FCP;

use common::sense;

use Carp;

our $VERSION = 0.5;

use Scalar::Util ();

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Util ();

our %TOLC; # tolc cache

sub touc($) {
   local $_ = shift;
   1 while s/((?:^|_)(?:svk|chk|uri|fcp|ds|mime|dda)(?:_|$))/\U$1/;
   s/(?:^|_)(.)/\U$1/g;
   $_
}

sub tolc($) {
   local $_ = shift;
   1 while s/(SVK|CHK|URI|FCP|DS|MIME|DDA)([^_])/$1\_$2/;
   1 while s/([^_])(SVK|CHK|URI|FCP|DS|MIME|DDA)/$1\_$2/;
   s/(?<=[a-z])(?=[A-Z])/_/g;
   lc
}

=item $fcp = new AnyEvent::FCP key => value...;

Create a new FCP connection to the given host and port (default
127.0.0.1:9481, or the environment variables C<FREDHOST> and C<FREDPORT>).

If no C<name> was specified, then AnyEvent::FCP will generate a
(hopefully) unique client name for you.

The following keys can be specified (they are all optional):

=over 4

=item name => $string

A unique name to identify this client. If none is specified, a randomly
generated name will be used.

=item host => $hostname

The hostname or IP address of the freenet node. Default is C<$ENV{FREDHOST}>
or C<127.0.0.1>.

=item port => $portnumber

The port number of the FCP port. Default is C<$ENV{FREDPORT}> or C<9481>.

=item timeout => $seconds

The timeout, in seconds, after which a connection error is assumed when
there is no activity. Default is C<7200>, i.e. two hours.

=item keepalive => $seconds

The interval, in seconds, at which keepalive messages will be
sent. Default is C<540>, i.e. nine minutes.

These keepalive messages are useful both to detect that a connection is
no longer working and to keep any (home) routers from expiring their
masquerading entry.

=item on_eof => $callback->($fcp)

Invoked when the underlying L<AnyEvent::Handle> signals EOF, currently
regardless of whether the EOF was expected or not.

=item on_error => $callback->($fcp, $message)

Invoked on any (fatal) errors, such as unexpected connection close. The
callback receives the FCP object and a textual error message.

=item on_failure => $callback->($fcp, $type, $backtrace, $args, $error)

Invoked when an FCP request fails that didn't have a failure callback. See
L<FCP REQUESTS> for details.

=back

=cut

sub new {
   my $class = shift;

   my $rand = join "", map chr 0x21 + rand 94, 1..40; # ~ 262 bits entropy

   my $self = bless {
      host       => $ENV{FREDHOST} || "127.0.0.1",
      port       => $ENV{FREDPORT} || 9481,
      timeout    => 3600 * 2,
      keepalive  => 9 * 60,
      name       => time.rand.rand.rand, # lame
      @_,
      queue      => [],
      req        => {},
      prefix     => "..:aefcpid:$rand:",
      idseq      => "a0",
   }, $class;

   {
      Scalar::Util::weaken (my $self = $self);

      $self->{kw} = AE::timer $self->{keepalive}, $self->{keepalive}, sub {
         $self->{hdl}->push_write ("\n");
      };

      our $ENDMESSAGE = qr<\012(EndMessage|Data)\012>;

      # these are declared here for performance reasons
      my ($k, $v, $type);
      my $rdata;
         
      my $on_read = sub {
         my ($hdl) = @_;

         # we only carve out whole messages here
         while ($hdl->{rbuf} =~ /\012(EndMessage|Data)\012/) {
            # remember end marker
            $rdata = $1 eq "Data"
               or $1 eq "EndMessage"
               or return $self->fatal ("protocol error, expected message end, got $1\n");

            my @lines = split /\012/, substr $hdl->{rbuf}, 0, $-[0];

            substr $hdl->{rbuf}, 0, $+[0], ""; # remove pkg

            $type = shift @lines;
            $type = ($TOLC{$type} ||= tolc $type);

            my %kv;

            for (@lines) {
               ($k, $v) = split /=/, $_, 2;
               $k = ($TOLC{$k} ||= tolc $k);
    
               if ($k =~ /\./) {
                  # generic, slow case
                  my @k = split /\./, $k;
                  my $ro = \\%kv;

                  while (@k) {
                     $k = shift @k;
                     if ($k =~ /^\d+$/) {
                        $ro = \$$ro->[$k];
                     } else {
                        $ro = \$$ro->{$k};
                     }
                  }

                  $$ro = $v;

                  next;
               }

               # special comon case, for performance only
               $kv{$k} = $v;
            }
    
            if ($rdata) {
               $_[0]->push_read (chunk => delete $kv{data_length}, sub {
                  $rdata = \$_[1];
                  $self->recv ($type, \%kv, $rdata);
               });

               last; # do not tgry to parse more messages
            } else {
               $self->recv ($type, \%kv);
            }
         }
      };

      $self->{hdl} = new AnyEvent::Handle
         connect  => [$self->{host} => $self->{port}],
         timeout  => $self->{timeout},
         on_read  => $on_read,
         on_eof   => sub {
            if ($self->{on_eof}) {
               $self->{on_eof}($self);
            } else {
               $self->fatal ("EOF");
            }
         },
         on_error => sub {
            $self->fatal ($_[2]);
         },
      ;

      Scalar::Util::weaken ($self->{hdl}{fcp} = $self);
   }

   $self->send_msg (client_hello =>
      name             => $self->{name},
      expected_version => "2.0",
   );

   $self
}

sub fatal {
   my ($self, $msg) = @_;

   $self->{hdl}->shutdown;
   delete $self->{kw};
   
   if ($self->{on_error}) {
      $self->{on_error}->($self, $msg);
   } else {
      die $msg;
   }
}

sub identifier {
   $_[0]{prefix} . ++$_[0]{idseq}
}

sub send_msg {
   my ($self, $type, %kv) = @_;

   my $data  = delete $kv{data};

   if (exists $kv{id_cb}) {
      my $id = $kv{identifier} ||= $self->identifier;
      $self->{id}{$id} = delete $kv{id_cb};
   }

   my $msg = (touc $type) . "\012"
             . join "", map +(touc $_) . "=$kv{$_}\012", keys %kv;

      sub id {
         my ($self) = @_;


      }

   if (defined $data) {
      $msg .= "DataLength=" . (length $data) . "\012"
            . "Data\012$data";
   } else {
      $msg .= "EndMessage\012";
   }

   $self->{hdl}->push_write ($msg);
}

sub on {
   my ($self, $cb) = @_;

   # cb return undef - message eaten, remove cb
   # cb return 0 - message eaten
   # cb return 1 - pass to next

   push @{ $self->{on} }, $cb;
}

sub _push_queue {
   my ($self, $queue) = @_;

   shift @$queue;
   $queue->[0]($self, AnyEvent::Util::guard { $self->_push_queue ($queue) })
      if @$queue;
}

# lock so only one $type (arbitrary string) is in flight,
# to work around horribly misdesigned protocol.
sub serialise {
   my ($self, $type, $cb) = @_;

   my $queue = $self->{serialise}{$type} ||= [];
   push @$queue, $cb;
   $cb->($self, AnyEvent::Util::guard { $self->_push_queue ($queue) })
      unless $#$queue;
}

# how to merge these types into $self->{persistent}
our %PERSISTENT_TYPE = (
   persistent_get              => sub { %{ $_[1] } = (type => "persistent_get"    , %{ $_[2] }) },
   persistent_put              => sub { %{ $_[1] } = (type => "persistent_put"    , %{ $_[2] }) },
   persistent_put_dir          => sub { %{ $_[1] } = (type => "persistent_put_dir", %{ $_[2] }) },
   persistent_request_modified => sub { %{ $_[1] } = (%{ $_[1] }, %{ $_[2] }) },
   persistent_request_removed  => sub { delete $_[0]{req}{$_[2]{identifier}} },

   simple_progress             => sub { $_[1]{simple_progress}        = $_[2] }, # get/put

   uri_generated               => sub { $_[1]{uri_generated}          = $_[2] }, # put
   generated_metadata          => sub { $_[1]{generated_metadata}     = $_[2] }, # put
   started_compression         => sub { $_[1]{started_compression}    = $_[2] }, # put
   finished_compression        => sub { $_[1]{finished_compression}   = $_[2] }, # put
   put_fetchable               => sub { $_[1]{put_fetchable}          = $_[2] }, # put
   put_failed                  => sub { $_[1]{put_failed}             = $_[2] }, # put
   put_successful              => sub { $_[1]{put_successful}         = $_[2] }, # put

   sending_to_network          => sub { $_[1]{sending_to_network}     = $_[2] }, # get
   compatibility_mode          => sub { $_[1]{compatibility_mode}     = $_[2] }, # get
   expected_hashes             => sub { $_[1]{expected_hashes}        = $_[2] }, # get
   expected_mime               => sub { $_[1]{expected_mime}          = $_[2] }, # get
   expected_data_length        => sub { $_[1]{expected_data_length}   = $_[2] }, # get
   get_failed                  => sub { $_[1]{get_failed}             = $_[2] }, # get
   data_found                  => sub { $_[1]{data_found}             = $_[2] }, # get
   enter_finite_cooldown       => sub { $_[1]{enter_finite_cooldown}  = $_[2] }, # get
);

sub recv {
   my ($self, $type, $kv, @extra) = @_;

   if (my $cb = $PERSISTENT_TYPE{$type}) {
      my $id  = $kv->{identifier};
      my $req = $_[0]{req}{$id} ||= {};
      $cb->($self, $req, $kv);
      $self->recv (request_changed => $kv, $type, @extra);
   }

   my $on = $self->{on};
   for (0 .. $#$on) {
      unless (my $res = $on->[$_]($self, $type, $kv, @extra)) {
         splice @$on, $_, 1 unless defined $res;
         return;
      }
   }

   if (my $cb = $self->{queue}[0]) {
      $cb->($self, $type, $kv, @extra)
         and shift @{ $self->{queue} };
   } else {
      $self->default_recv ($type, $kv, @extra);
   }
}

sub default_recv {
   my ($self, $type, $kv, $rdata) = @_;

   if ($type eq "node_hello") {
      $self->{node_hello} = $kv;
   } elsif (exists $self->{id}{$kv->{identifier}}) {
      $self->{id}{$kv->{identifier}}($self, $type, $kv, $rdata)
         and delete $self->{id}{$kv->{identifier}};
   }
}

=back

=head2 FCP REQUESTS

The following methods implement various requests. Most of them map
directory to the FCP message of the same name. The added benefit of
these over sending requests yourself is that they handle the necessary
serialisation, protocol quirks, and replies.

All of them exist in two versions, the variant shown in this manpage, and
a variant with an extra C<_> at the end, and an extra C<$cb> argument. The
version as shown is I<synchronous> - it will wait for any replies, and
either return the reply, or croak with an error. The underscore variant
returns immediately and invokes one or more callbacks or condvars later.

For example, the call

   $info = $fcp->get_plugin_info ($name, $detailed);

Also comes in this underscore variant:

   $fcp->get_plugin_info_ ($name, $detailed, $cb);

You can thinbk of the underscore as a kind of continuation indicator - the
normal function waits and returns with the data, the C<_> indicates that
you pass the continuation yourself, and the continuation will be invoked
with the results.

This callback/continuation argument (C<$cb>) can come in three forms itself:

=over 4

=item A code reference (or rather anything not matching some other alternative)

This code reference will be invoked with the result on success. On an
error, it will invoke the C<on_failure> callback of the FCP object, or,
if none was defined, will die (in the event loop) with a backtrace of the
call site.

This is a popular choice, but it makes handling errors hard - make sure
you never generate protocol errors!

If an C<on_failure> hook exists, it will be invoked with the FCP object,
the request type (the name of the method), a (textual) backtrace as
generated by C<Carp::longmess>, and arrayref containing the arguments from
the original request invocation and the error object from the server, in
this order, e.g.:

   on_failure => sub {
      my ($fcp, $request_type, $backtrace, $orig_args, $error_object) = @_;

      warn "FCP failure ($type), $error_object->{code_description} ($error_object->{extra_description})$backtrace";
      exit 1;
   },

=item A condvar (as returned by e.g. C<< AnyEvent->condvar >>)

When a condvar is passed, it is sent (C<< $cv->send ($results) >>) the
results when the request has finished. Should an error occur, the error
will instead result in C<< $cv->croak ($error) >>.

This is also a popular choice.

=item An array with two callbacks C<[$success, $failure]>

The C<$success> callback will be invoked with the results, while the
C<$failure> callback will be invoked on any errors.

The C<$failure> callback will be invoked with the error object from the
server.

=item C<undef>

This is the same thing as specifying C<sub { }> as callback, i.e. on
success, the results are ignored, while on failure, the C<on_failure> hook
is invoked or the module dies with a backtrace.

This is good for quick scripts, or when you really aren't interested in
the results.

=back

=cut

our $NOP_CB = sub { };

sub _txn {
   my ($name, $sub) = @_;

   *{$name} = sub {
      my $cv = AE::cv;

      splice @_, 1, 0, $cv, sub { $cv->croak ($_[0]{extra_description}) };
      &$sub;
      $cv->recv
   };

   *{"$name\_"} = sub {
      my ($ok, $err) = pop;

      if (ARRAY:: eq ref $ok) {
         ($ok, $err) = @$ok;
      } elsif (UNIVERSAL::isa $ok, AnyEvent::CondVar::) {
         $err = sub { $ok->croak ($_[0]{extra_description}) };
      } else {
         my $bt = Carp::longmess "AnyEvent::FCP request $name";
         Scalar::Util::weaken (my $self = $_[0]);
         my $args = [@_]; shift @$args;
         $err = sub {
            if ($self->{on_failure}) {
               $self->{on_failure}($self, $name, $args, $bt, $_[0]);
            } else {
               die "$_[0]{code_description} ($_[0]{extra_description})$bt";
            }
         };
      }

      $ok ||= $NOP_CB;

      splice @_, 1, 0, $ok, $err;
      &$sub;
   };
}

=over 4

=item $peers = $fcp->list_peers ([$with_metdata[, $with_volatile]])

=cut

_txn list_peers => sub {
   my ($self, $ok, undef, $with_metadata, $with_volatile) = @_;

   my @res;

   $self->send_msg (list_peers =>
      with_metadata => $with_metadata ? "true" : "false",
      with_volatile => $with_volatile ? "true" : "false",
      id_cb         => sub {
         my ($self, $type, $kv, $rdata) = @_;

         if ($type eq "end_list_peers") {
            $ok->(\@res);
            1
         } else {
            push @res, $kv;
            0
         }
      },
   );
};

=item $notes = $fcp->list_peer_notes ($node_identifier)

=cut

_txn list_peer_notes => sub {
   my ($self, $ok, undef, $node_identifier) = @_;

   $self->send_msg (list_peer_notes =>
      node_identifier => $node_identifier,
      id_cb           => sub {
         my ($self, $type, $kv, $rdata) = @_;

         $ok->($kv);
         1
      },
   );
};

=item $fcp->watch_global ($enabled[, $verbosity_mask])

=cut

_txn watch_global => sub {
   my ($self, $ok, $err, $enabled, $verbosity_mask) = @_;

   $self->send_msg (watch_global =>
      enabled        => $enabled ? "true" : "false",
      defined $verbosity_mask ? (verbosity_mask => $verbosity_mask+0) : (),
   );

   $ok->();
};

=item $reqs = $fcp->list_persistent_requests

=cut

_txn list_persistent_requests => sub {
   my ($self, $ok, $err) = @_;

   $self->serialise (list_persistent_requests => sub {
      my ($self, $guard) = @_;

      my @res;

      $self->send_msg ("list_persistent_requests");

      $self->on (sub {
         my ($self, $type, $kv, $rdata) = @_;

         $guard if 0;

         if ($type eq "end_list_persistent_requests") {
            $ok->(\@res);
            return;
         } else {
            my $id = $kv->{identifier};

            if ($type =~ /^persistent_(get|put|put_dir)$/) {
               push @res, [$type, $kv];
            }
         }

         1
      });
   });
};

=item $sync = $fcp->modify_persistent_request ($global, $identifier[, $client_token[, $priority_class]])

Update either the C<client_token> or C<priority_class> of a request
identified by C<$global> and C<$identifier>, depending on which of
C<$client_token> and C<$priority_class> are not C<undef>.

=cut

_txn modify_persistent_request => sub {
   my ($self, $ok, $err, $global, $identifier, $client_token, $priority_class) = @_;

   $self->serialise ($identifier => sub {
      my ($self, $guard) = @_;

      $self->send_msg (modify_persistent_request =>
         global     => $global ? "true" : "false",
         identifier => $identifier,
         defined $client_token   ? (client_token   => $client_token  ) : (),
         defined $priority_class ? (priority_class => $priority_class) : (),
      );

      $self->on (sub {
         my ($self, $type, $kv, @extra) = @_;

         $guard if 0;

         if ($kv->{identifier} eq $identifier) {
            if ($type eq "persistent_request_modified") {
               $ok->($kv);
               return;
            } elsif ($type eq "protocol_error") {
               $err->($kv);
               return;
            }
         }

         1
      });
   });
};

=item $info = $fcp->get_plugin_info ($name, $detailed)

=cut

_txn get_plugin_info => sub {
   my ($self, $ok, $err, $name, $detailed) = @_;

   my $id = $self->identifier;

   $self->send_msg (get_plugin_info =>
      identifier  => $id,
      plugin_name => $name,
      detailed    => $detailed ? "true" : "false",
   );
   $self->on (sub {
      my ($self, $type, $kv) = @_;

      if ($kv->{identifier} eq $id) {
         if ($type eq "get_plugin_info") {
            $ok->($kv);
         } else {
            $err->($kv, $type);
         }
         return;
      }

      1
   });
};

=item $status = $fcp->client_get ($uri, $identifier, %kv)

%kv can contain (L<http://wiki.freenetproject.org/FCP2p0ClientGet>).

ignore_ds, ds_only, verbosity, max_size, max_temp_size, max_retries,
priority_class, persistence, client_token, global, return_type,
binary_blob, allowed_mime_types, filename, temp_filename

=cut

_txn client_get => sub {
   my ($self, $ok, $err, $uri, $identifier, %kv) = @_;

   $self->serialise ($identifier => sub {
      my ($self, $guard) = @_;

      $self->send_msg (client_get =>
         %kv,
         uri        => $uri,
         identifier => $identifier,
      );

      $self->on (sub {
         my ($self, $type, $kv, @extra) = @_;

         $guard if 0;

         if ($kv->{identifier} eq $identifier) {
            if ($type eq "persistent_get") {
               $ok->($kv);
               return;
            } elsif ($type eq "protocol_error") {
               $err->($kv);
               return;
            }
         }

         1
      });
   });
};

=item $status = $fcp->remove_request ($identifier[, $global])

Remove the request with the given isdentifier. Returns true if successful,
false on error.

=cut

_txn remove_request => sub {
   my ($self, $ok, $err, $identifier, $global) = @_;

   $self->serialise ($identifier => sub {
      my ($self, $guard) = @_;

      $self->send_msg (remove_request =>
         identifier => $identifier,
         global     => $global ? "true" : "false",
      );
      $self->on (sub {
         my ($self, $type, $kv, @extra) = @_;

         $guard if 0;

         if ($kv->{identifier} eq $identifier) {
            if ($type eq "persistent_request_removed") {
               $ok->(1);
               return;
            } elsif ($type eq "protocol_error") {
               $err->($kv);
               return;
            }
         }

         1
      });
   });
};

=item ($can_read, $can_write) = $fcp->test_dda ($local_directory, $remote_directory, $want_read, $want_write))

The DDA test in FCP is probably the single most broken protocol - only
one directory test can be outstanding at any time, and some guessing and
heuristics are involved in mangling the paths.

This function combines C<TestDDARequest> and C<TestDDAResponse> in one
request, handling file reading and writing as well, and tries very hard to
do the right thing.

Both C<$local_directory> and C<$remote_directory> must specify the same
directory - C<$local_directory> is the directory path on the client (where
L<AnyEvent::FCP> runs) and C<$remote_directory> is the directory path on
the server (where the freenet node runs). When both are running on the
same node, the paths are generally identical.

C<$want_read> and C<$want_write> should be set to a true value when you
want to read (get) files or write (put) files, respectively.

On error, an exception is thrown. Otherwise, C<$can_read> and
C<$can_write> indicate whether you can reaqd or write to freenet via the
directory.

=cut

_txn test_dda => sub {
   my ($self, $ok, $err, $local, $remote, $want_read, $want_write) = @_;

   $self->serialise (test_dda => sub {
      my ($self, $guard) = @_;

      $self->send_msg (test_dda_request =>
         directory            => $remote,
         want_read_directory  => $want_read  ? "true" : "false",
         want_write_directory => $want_write ? "true" : "false",
      );
      $self->on (sub {
         my ($self, $type, $kv) = @_;

         if ($type eq "test_dda_reply") {
            # the filenames are all relative to the server-side directory,
            # which might or might not match $remote anymore, so we
            # need to rewrite the paths to be relative to $local
            for my $k (qw(read_filename write_filename)) {
               my $f = $kv->{$k};
               for my $dir ($kv->{directory}, $remote) {
                  if ($dir eq substr $f, 0, length $dir) {
                     substr $f, 0, 1 + length $dir, "";
                     $kv->{$k} = $f;
                     last;
                  }
               }
            }

            my %response = (directory => $remote);

            if (length $kv->{read_filename}) {
               if (open my $fh, "<:raw", "$local/$kv->{read_filename}") {
                  sysread $fh, my $buf, -s $fh;
                  $response{read_content} = $buf;
               }
            }

            if (length $kv->{write_filename}) {
               if (open my $fh, ">:raw", "$local/$kv->{write_filename}") {
                  syswrite $fh, $kv->{content_to_write};
               }
            }

            $self->send_msg (test_dda_response => %response);

            $self->on (sub {
               my ($self, $type, $kv) = @_;

               $guard if 0; # reference

               if ($type eq "test_dda_complete") {
                  $ok->(
                     $kv->{read_directory_allowed} eq "true",
                     $kv->{write_directory_allowed} eq "true",
                  );
               } elsif ($type eq "protocol_error" && $kv->{identifier} eq $remote) {
                  $err->($kv->{extra_description});
                  return;
               }

               1
            });

            return;
         } elsif ($type eq "protocol_error" && $kv->{identifier} eq $remote) {
            $err->($kv);
            return;
         }

         1
      });
   });
};

=back

=head2 REQUEST CACHE

The C<AnyEvent::FCP> class keeps a request cache, where it caches all
information from requests.

For these messages, it will store a copy of the key-value pairs, together with a C<type> slot,
in C<< $fcp->{req}{$identifier} >>:

   persistent_get
   persistent_put
   persistent_put_dir

This message updates the stored data:

   persistent_request_modified

This message will remove this entry:

   persistent_request_removed

These messages get merged into the cache entry, under their
type, i.e. a C<simple_progress> message will be stored in C<<
$fcp->{req}{$identifier}{simple_progress} >>:

   simple_progress        # get/put

   uri_generated          # put
   generated_metadata     # put
   started_compression    # put
   finished_compression   # put
   put_failed             # put
   put_fetchable          # put
   put_successful         # put

   sending_to_network     # get
   compatibility_mode     # get
   expected_hashes        # get
   expected_mime          # get
   expected_data_length   # get
   get_failed             # get
   data_found             # get
   enter_finite_cooldown  # get

In addition, an event (basically a fake message) of type C<request_changed> is generated
on every change, which will be called as C<< $cb->($fcp, $kv, $type) >>, where C<$type>
is the type of the original message triggering the change,

To fill this cache with the global queue and keep it updated,
call C<watch_global> to subscribe to updates, followed by
C<list_persistent_requests_sync>.

   $fcp->watch_global_sync_; # do not wait
   $fcp->list_persistent_requests; # wait

To get a better idea of what is stored in the cache, here is an example of
what might be stored in C<< $fcp->{req}{"Frost-gpl.txt"} >>:

   {
      identifier     => "Frost-gpl.txt",
      uri            => 'CHK@Fnx5kzdrfE,EImdzaVyEWl,AAIC--8/gpl.txt',
      binary_blob    => "false",
      global         => "true",
      max_retries    => -1,
      max_size       => 9223372036854775807,
      persistence    => "forever",
      priority_class => 3,
      real_time      => "false",
      return_type    => "direct",
      started        => "true",
      type           => "persistent_get",
      verbosity      => 2147483647,
      sending_to_network => {
         identifier => "Frost-gpl.txt",
         global     => "true",
      },
      compatibility_mode => {
         identifier    => "Frost-gpl.txt",
         definitive    => "true",
         dont_compress => "false",
         global        => "true",
         max           => "COMPAT_1255",
         min           => "COMPAT_1255",
      },
      expected_hashes    => {
         identifier => "Frost-gpl.txt",
         global     => "true",
         hashes     => {
            ed2k   => "d83596f5ee3b7...",
            md5    => "e0894e4a2a6...",
            sha1   => "...",
            sha256 => "...",
            sha512 => "...",
            tth    => "...",
         },
      },
      expected_mime      => {
         identifier      => "Frost-gpl.txt",
         global          => "true",
         metadata        => { content_type => "application/rar" },
      },
      expected_data_length => {
         identifier      => "Frost-gpl.txt",
         data_length     => 37576,
         global          => "true",
      },
      simple_progress    => {
         identifier      => "Frost-gpl.txt",
         failed          => 0,
         fatally_failed  => 0,
         finalized_total => "true",
         global          => "true",
         last_progress   => 1438639282628,
         required        => 372,
         succeeded       => 102,
         total           => 747,
      },
      data_found           => {
         identifier      => "Frost-gpl.txt",
         completion_time => 1438663354026,
         data_length     => 37576,
         global          => "true",
         metadata        => { content_type => "image/jpeg" },
         startup_time    => 1438657196167,
      },
   }

=head1 EXAMPLE PROGRAM

   use AnyEvent::FCP;

   my $fcp = new AnyEvent::FCP;

   # let us look at the global request list
   $fcp->watch_global_ (1);

   # list them, synchronously
   my $req = $fcp->list_persistent_requests;

   # go through all requests
TODO
   for my $req (values %$req) {
      # skip jobs not directly-to-disk
      next unless $req->{return_type} eq "disk";
      # skip jobs not issued by FProxy
      next unless $req->{identifier} =~ /^FProxy:/;

      if ($req->{data_found}) {
         # file has been successfully downloaded
         
         ... move the file away
         (left as exercise)

         # remove the request

         $fcp->remove_request (1, $req->{identifier});
      } elsif ($req->{get_failed}) {
         # request has failed
         if ($req->{get_failed}{code} == 11) {
            # too many path components, should restart
         } else {
            # other failure
         }
      } else {
         # modify priorities randomly, to improve download rates
         $fcp->modify_persistent_request (1, $req->{identifier}, undef, int 6 - 5 * (rand) ** 1.7)
            if 0.1 > rand;
      }
   }

   # see if the dummy plugin is loaded, to ensure all previous requests have finished.
   $fcp->get_plugin_info_sync ("dummy");

=head1 SEE ALSO

L<http://wiki.freenetproject.org/FreenetFCPSpec2Point0>, L<Net::FCP>.

=head1 BUGS

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

