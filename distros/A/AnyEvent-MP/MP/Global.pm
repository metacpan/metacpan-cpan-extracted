=head1 NAME

AnyEvent::MP::Global - network backbone services

=head1 SYNOPSIS

   use AnyEvent::MP::Global;

=head1 DESCRIPTION

This module is usually run (or started on) seed nodes and provides a
variety of services to connected nodes, such as the distributed database.

The global nodes form a fully-meshed network, that is, all global nodes
currently maintain connections to all other global nodes.

Loading this module (e.g. as a service) transforms the local node into a
global node. There are no user-servicable parts inside.

For a limited time, this module also exports some AEMP 1.x compatibility
functions (C<grp_reg>, C<grp_get> and C<grp_mon>).

=cut

package AnyEvent::MP::Global;

use common::sense;
use Carp ();
use List::Util ();

use AnyEvent ();

use AnyEvent::MP;
use AnyEvent::MP::Kernel;

AE::log 7 => "starting global service.";

#############################################################################
# node protocol parts for global nodes

package AnyEvent::MP::Kernel;

use JSON::XS ();

# TODO: this is ugly (classical use vars vs. our),
# maybe this should go into MP::Kernel

# "import" from Kernel
our %NODE;
our $NODE;
#our $GLOBAL;
our $SRCNODE; # the origin node id
our %NODE_REQ;
our %GLOBAL_NODE;
our $GLOBAL;

# only in global code
our %GLOBAL_SLAVE;
our %GLOBAL_MON; # monitors {family}

our %GLOBAL_DB;    # all local databases, merged - empty on non-global nodes
our %LOCAL_DBS; # local databases of other nodes (global and slave)
our %LOCAL_DB;  # this node database

# broadcasts a message to all other global nodes
sub g_broadcast {
   snd $_, @_
      for keys %GLOBAL_NODE;
}

# add/replace/del inside a family in the database
# @$del must not contain any key in %$set
sub g_upd {
   my ($node, $family, $set, $del) = @_;

   my $ldb = $LOCAL_DBS{$node}{$family} ||= {};
   my $gdb = $GLOBAL_DB       {$family} ||= {};

   my %local_set; # extra local set's created by deletes

   # add/replace keys
   while (my ($k, $v) = each %$set) {
      #TODO# optimize duplicate gdb-set's, to some extent, maybe
      # but is probably difficult and slow, so don't for the time being.

      $ldb->{$k} =
      $gdb->{$k} = $v;
   }

   my (@del_local, @del_global); # actual deletes for other global nodes / our slaves

   # take care of deletes
   for my $k (@$del) {
      delete $ldb->{$k};

      if (my @other = grep exists $LOCAL_DBS{$_}{$family}{$k}, keys %LOCAL_DBS) {
         # key exists in some other db shard(s)

         # if there is a local one, we have to update
         # otherwise, we update and delete on other globals

         if (my $local = List::Util::first { exists $GLOBAL_SLAVE{$_} } @other) {
            $set->{$k} =
            $gdb->{$k} = $LOCAL_DBS{$local}{$family}{$k}
               unless sv_eq $gdb->{$k}, $LOCAL_DBS{$local}{$family}{$k};

         } else {
            # must be in a global one then
            my $global = List::Util::first { !exists $GLOBAL_SLAVE{$_} } @other;

            push @del_global, $k;

            $local_set{$k} =
            $gdb->{$k}     = $LOCAL_DBS{$global}{$family}{$k}
               unless sv_eq $gdb->{$k}, $LOCAL_DBS{$global}{$family}{$k};
         }
      } else {
         delete $gdb->{$k};

         # this was the only one, so delete locally
         push @del_local, $k;
         # and globally, if it's a local key
         push @del_global, $k if exists $GLOBAL_SLAVE{$node};
      }
   }

   # family could be empty now
   delete $GLOBAL_DB       {$family} unless %$gdb;
   delete $LOCAL_DBS{$node}{$family} unless %$ldb;

   # tell other global nodes any changes in our database
   g_broadcast g_upd => $family, $set, \@del_global
      if exists $GLOBAL_SLAVE{$node} && (%$set || @del_global);

   # tell subscribers we have changed the family
   if (%$set || %local_set || @del_local) {
      @$set{keys %local_set} = values %local_set;

      snd $_ => g_chg2 => $family, $set, \@del_local
         for keys %{ $GLOBAL_MON{$family} };
   }
}

# set the whole (node-local) database - previous value must be empty
sub g_set($$) {
   my ($node, $db) = @_;

   while (my ($f, $k) = each %$db) {
      g_upd $node, $f, $k;
   }
}

# delete all keys from a database
sub g_clr($) {
   my ($node) = @_;

   my $db = $LOCAL_DBS{$node};

   while (my ($f, $k) = each %$db) {
      g_upd $node, $f, undef, [keys %$k];
   }

   delete $LOCAL_DBS{$node};
}

# gather node databases from slaves

# other node wants to make us the master and sends us their db
$NODE_REQ{g_slave} = sub {
   my ($db) = @_
      or return; # empty g_slave is used to start global service

   my $node = $SRCNODE;
   undef $GLOBAL_SLAVE{$node};
   g_set $node, $db;
};

# other global node sends us their database
$NODE_REQ{g_set} = sub {
   my ($db) = @_;

   # need to get it here, because g_set destroys it
   my $binds = $db->{"'l"}{$SRCNODE};

   g_set $SRCNODE, $db;

   # a remote node always has to provide their listeners. for global
   # nodes, we mirror their 'l locally, just as we also set 'g.
   # that's not very efficient, but ensures that global nodes
   # find each other.
   db_set "'l" => $SRCNODE => $binds;
};

# other node (global and slave) sends us a family update
$NODE_REQ{g_upd} = sub {
   &g_upd ($SRCNODE, @_);
};

# slave node wants to know the listeners of a node
$NODE_REQ{g_find} = sub {
   my ($node) = @_;

   snd $SRCNODE, g_found => $node, $GLOBAL_DB{"'l"}{$node};
};

$NODE_REQ{g_db_family} = sub {
   my ($family, $id) = @_;
   snd $SRCNODE, g_reply => $id, $GLOBAL_DB{$family} || {};
};

$NODE_REQ{g_db_keys} = sub {
   my ($family, $id) = @_;
   snd $SRCNODE, g_reply => $id, [keys %{ $GLOBAL_DB{$family} } ];
};

$NODE_REQ{g_db_values} = sub {
   my ($family, $id) = @_;
   snd $SRCNODE, g_reply => $id, [values %{ $GLOBAL_DB{$family} } ];
};

# monitoring

sub g_disconnect($) {
   my ($node) = @_;

   delete $GLOBAL_NODE{$node}; # also done in Kernel.pm, but doing it here avoids overhead

   db_del "'g" => $node;
   db_del "'l" => $node;
   g_clr $node;

   if (my $mon = delete $GLOBAL_SLAVE{$node}) {
      while (my ($f, $fv) = each %$mon) {
         delete $GLOBAL_MON{$f}{$_}
            for keys %$fv;

         delete $GLOBAL_MON{$f}
            unless %{ $GLOBAL_MON{$f} };
      }
   }
}

# g_mon0 family - stop monitoring
$NODE_REQ{g_mon0} = sub {
   delete $GLOBAL_MON{$_[0]}{$SRCNODE};
   delete $GLOBAL_MON{$_[0]} unless %{ $GLOBAL_MON{$_[0]} };

   delete $GLOBAL_SLAVE{$SRCNODE}{$_[0]};
};

# g_mon1 family key - start monitoring
$NODE_REQ{g_mon1} = sub {
   undef $GLOBAL_SLAVE{$SRCNODE}{$_[0]};
   undef $GLOBAL_MON{$_[0]}{$SRCNODE};

   snd $SRCNODE, g_chg1 => $_[0], $GLOBAL_DB{$_[0]};
};

#############################################################################
# switch to global mode

# connect from a global node
sub g_global_connect {
   my ($node) = @_;

   # each node puts the set of connected global nodes into
   # 'g - this causes a big duplication and mergefest, but
   # is the easiest way to ensure global nodes have a list
   # of all other global nodes.
   # we also mirror 'l as soon as we receive it, causing
   # even more overhead.
   db_set "'g" => $node;

   # global nodes send all local databases of their slaves, merged,
   # as their database to other global nodes
   my %db;

   while (my ($k, $v) = each %LOCAL_DBS) {
      next unless exists $GLOBAL_SLAVE{$k};

      while (my ($f, $fv) = each %$v) {
         while (my ($k, $kv) = each %$fv) {
            $db{$f}{$k} = $kv;
         }
      }
   }

   snd $node => g_set => \%db;
}

# overrides request in Kernel
$NODE_REQ{g_global} = sub {
   g_disconnect $SRCNODE; # usually a nop, but not when a normal node becomes global
   undef $GLOBAL_NODE{$SRCNODE}; # same as in Kernel.pm
   g_global_connect $SRCNODE;
};

# delete data from other nodes on node-down
mon_nodes sub {
   if ($_[1]) {
      snd $_[0] => "g_global"; # tell everybody that we are a global node
   } else {
      g_disconnect $_[0];
   }
};

# now, this is messy
AnyEvent::MP::Kernel::post_configure {
   # enable global mode
   $GLOBAL = 1;

   # global nodes are their own masters - this
   # resends global requests and sets the local database.
   master_set $NODE;

   # now add us to the set of global nodes
   db_set "'g" => $NODE;

   # tell other nodes that we are global now
   for (up_nodes) {
      snd $_, "g_global";

      # if the node is global, connect
      g_global_connect $_
         if exists $GLOBAL_NODE{$_};
   }

   # from here on we should be able to act "normally"

   # maintain connections to all global nodes that we know of
   db_mon "'g" => sub {
      keepalive_add $_ for @{ $_[1] };
      keepalive_del $_ for @{ $_[3] };
   };
};

#############################################################################
# compatibility functions for aemp 1.0

package AnyEvent::MP::Global;

use base "Exporter";
our @EXPORT = qw(grp_reg grp_get grp_mon);

sub grp_reg($$) {
   &db_reg
}

sub grp_get($) {
   my @ports = keys %{ $AnyEvent::MP::Kernel::GLOBAL_DB{$_[0]} };

   @ports ? \@ports : undef
}

sub grp_mon($$) {
   my ($grp, $cb) = @_;

   db_mon $grp => sub {
      my ($ports, $add, $chg, $del) = @_;

      $cb->([keys %$ports], $add, $del);
   };
}

=head1 SEE ALSO

L<AnyEvent::MP>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

