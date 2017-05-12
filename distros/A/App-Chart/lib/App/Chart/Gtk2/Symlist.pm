# Copyright 2007, 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Symlist;
use 5.008;
use strict;
use warnings;
use Carp 'carp','croak';
use Gtk2;
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::TreeModelBits;
use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

use constant DEBUG => 0;

use base 'App::Chart::Gtk2::Ex::ListStore::DragByCopy';

use App::Chart::Gtk2::Ex::ListStoreDBISeq;
use Glib::Object::Subclass
  'App::Chart::Gtk2::Ex::ListStoreDBISeq',
  interfaces => [ 'Gtk2::TreeDragSource',
                  'Gtk2::TreeDragDest' ],
  signals => { row_changed    => \&_do_row_changed,
               row_inserted   => \&_do_row_inserted,
               row_deleted    => \&_do_row_deleted },

  properties => [ Glib::ParamSpec->string
                  ('key',
                   'key',
                   'The symlist database key.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('name',
                   'name',
                   'The symlist name.',
                   '', # default
                   Glib::G_PARAM_READWRITE) ];

our %instances;  # key => symlist

my %key_to_class = (all        => 'App::Chart::Gtk2::Symlist::All',
                    favourites => 'App::Chart::Gtk2::Symlist::Favourites',
                    historical => 'App::Chart::Gtk2::Symlist::Historical',
                    alerts     => 'App::Chart::Gtk2::Symlist::Alerts');

use constant { COL_SYMBOL => 0,
               COL_NOTE   => 1 };

App::Chart::chart_dirbroadcast()->connect
  ('symlist-list-changed', \&_do_symlist_list_changed);

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'key'} = '';
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  $self->set_property (where   => { key => 'dummy' },
                       columns => [ 'symbol', 'note' ],
                       table   => 'symlist_content',
                       dbh     => $dbh);

  # class closure no good as of Perl-Gtk2 1.221, must connect to self
  $self->signal_connect (rows_reordered => \&_do_rows_reordered);

  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-content-inserted', \&_do_content_inserted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-content-deleted', \&_do_content_deleted, $self);
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('symlist-content-reordered', \&_do_content_reordered, $self);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;

  my $pname = $pspec->get_name;
  if ($pname eq 'name') {
    return $self->name;
  } else {
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($pname eq 'key') {
    my $key = $newval;
    $instances{$key} = $self;
    # Scalar::Util::weaken ($instances{$key});
    $self->set_property (where => { key => $key });
    delete $self->{'name'};
  }
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  while (my ($key, $value) = each %instances) {
    if (! defined $value || $value == $self) {
      delete $instances{$key};
    }
  }
}

sub new_from_key {
  my ($class, $key) = @_;
  if (! defined $key) { return undef; }
  my $self = $class->new_from_key_maybe ($key);
  if (! $self) {
    carp 'No such symlist key ',$key;
  }
  return $self;
}
sub new_from_key_maybe {
  my ($class, $key) = @_;
  if (! defined $key) { return undef; }
  if (my $self = $instances{$key}) { return $self; }
  if (! defined App::Chart::Database::read_notes_single
      ('SELECT seq FROM symlist WHERE key=?', $key)) {
    return undef;
  }
  return _new_from_known_key ($key);
}

# sub new_from_pos {
#   my ($class, $seq) = @_;
#   my $key = App::Chart::Database::read_notes_single
#     ('SELECT key FROM symlist WHERE seq=?', $seq);
#   if (! $key) { croak "No symlist at position $seq"; }
#   return _new_from_known_key ($key);
# }

sub _new_from_known_key {
  my ($key) = @_;
  if (my $self = $instances{$key}) { return $self; }

  my $class = $key_to_class{$key} || 'App::Chart::Gtk2::Symlist::User';
  require Module::Load;
  Module::Load::load ($class);
  my $self = $class->new (key => $key);
  $instances{$key} = $self;
  #
  # can cause excess re-reading
  # Scalar::Util::weaken ($instances{$key});
  #
  return $self;
}

sub all_lists {
  my ($class) = @_;
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('SELECT key FROM symlist ORDER BY seq ASC');
  my $dbkeys = $dbh->selectcol_arrayref ($sth);
  $sth->finish();

  my @ret = map { _new_from_known_key($_) } @$dbkeys;
  my %got;
  @got{@$dbkeys} = 1;
  foreach my $key (keys %instances) {
    if (! exists $got{$key}) { unshift @ret, $instances{$key}; }
  }
  return @ret;
}

sub key {
  my ($self) = @_;
  return $self->{'key'} || croak;
}
sub can_edit           { return 0; }
sub can_delete_symlist { return 0; }

sub name {
  my ($self) = @_;
  if (! exists $self->{'name'}) {
    $self->{'name'}
      = App::Chart::Database::read_notes_single
        ('SELECT name FROM symlist WHERE key=?', $self->{'key'})
          || __('(No name)');
  }
  return $self->{'name'};
}

# default current symbols
sub interested_symbols {
  my ($self) = @_;
  return $self->symbols;
}

#------------------------------------------------------------------------------
# remote changes

# 'symlist-content-inserted' broadcast handler
sub _do_content_inserted {
  my ($self, $key, $seq) = @_;
  if ($self->key eq $key) {
    $self->reread;
  }
}
# 'symlist-content-deleted' broadcast handler
sub _do_content_deleted {
  my ($self, $key, $seq) = @_;
  if ($self->key eq $key) {
    $self->reread;
  }
}

# 'symlist-content-reordered' broadcast handler
sub _do_content_reordered {
  my ($self, $key) = @_;
  if ($self->key eq $key) {
    $self->reread;
  }
}

# 'symlist-list-changed' broadcast handler
sub _do_symlist_list_changed {
  my ($seq, $key) = @_;
  if (DEBUG) { print "Symlist list changed '$key'\n"; }
  defined $key or return;
  my $symlist = $instances{$key} || return;
  if (DEBUG) { print "  notify $symlist 'name'\n"; }
  delete $symlist->{'name'}; # refetch
  $symlist->notify('name');
}

#------------------------------------------------------------------------------
# local changes applied to database
#
# signal_chain_from_overridden() is done to update the database before
# dirbroadcast()->send is sent, because the local broadcast handlers are
# likely to use ->hash, ->symbol_listref, etc, which will do a ->reread of
# the database contents.
#

# 'row-changed' class closure
sub _do_row_changed {
  my ($self, $path, $iter) = @_;
  delete $self->{'symbol_hash'};
  delete $self->{'symbol_list'};

  $self->signal_chain_from_overridden ($path, $iter);

  if (! $self->{'reading_database'}) {
    my $key = $self->{'key'};
    my ($seq) = $path->get_indices;
    my $symbol = $self->get_value($iter,0);
    local $self->{'reading_database'} = 1;
    App::Chart::chart_dirbroadcast()->send ('symlist-content-changed',$key,$seq,$symbol);
  }
}

# 'row-deleted' class closure
sub _do_row_deleted {
  my ($self, $path) = @_;
  delete $self->{'symbol_hash'};
  delete $self->{'symbol_list'};

  $self->signal_chain_from_overridden ($path);

  if (! $self->{'reading_database'}) {
    my $key = $self->{'key'};
    my ($seq) = $path->get_indices;
    ### Symlist database: "$key delete $seq"
    local $self->{'reading_database'} = 1;
    App::Chart::chart_dirbroadcast()->send ('symlist-content-deleted',
                                           $key, $seq);
  }
}

# 'row-inserted' class closure
sub _do_row_inserted {
  my ($self, $path, $iter) = @_;
  my $symbol = $self->get_value ($iter, COL_SYMBOL);

  delete $self->{'symbol_list'};
  if (my $hash = $self->{'symbol_hash'}) {
    if (defined $symbol) {
      $hash->{$symbol} = 1;
    }
  }

  $self->signal_chain_from_overridden ($path, $iter);

  if (! $self->{'reading_database'}) {
    my $key = $self->{'key'};
    my ($seq) = $path->get_indices;
    ### Symlist database: "$key insert $symbol at $seq"
    App::Chart::chart_dirbroadcast()->send ('symlist-content-inserted',
                                           $key, $seq, $symbol);
  }
}

# 'rows-reordered' connected on self
sub _do_rows_reordered {
  my ($self, $path, $iter, $aref) = @_;
  delete $self->{'symbol_hash'};
  delete $self->{'symbol_list'};
  if (! $self->{'reading_database'}) {
    my $key = $self->{'key'};
    if (DEBUG) { print "Symlist database '$key' reorder ",
                   join(' ',@$aref),"\n"; }
    App::Chart::chart_dirbroadcast()->send ('symlist-content-reordered', $key);
  }
}


#------------------------------------------------------------------------------
# contents

sub hash {
  my ($self) = @_;
  return ($self->{'symbol_hash'} ||= do {
    my %hash;
    my $s = $self->symbol_listref;
    @hash{@$s} = (0 .. $#$s);
    \%hash;
  });
}
sub contains_symbol {
  my ($self, $symbol) = @_;
  my $hash = $self->hash;
  return exists $hash->{$symbol};
}

sub symbols {
  my ($self) = @_;
  ### Symlist symbols: "$self"
  return @{$self->symbol_listref};
}
sub symbol_listref {
  my ($self) = @_;
  return ($self->{'symbol_list'} ||= do {
    require Gtk2::Ex::TreeModelBits;
    [ Gtk2::Ex::TreeModelBits::column_contents ($self,COL_SYMBOL) ]
  });
}

sub is_empty {
  my ($self) = @_;
  return $self->length == 0;
}
sub length {
  my ($self) = @_;
  return $self->iter_n_children(undef);
}

#------------------------------------------------------------------------------
# helpers

sub append_or_elevate {
  my ($self, $symbol, $note) = @_;
  if (my $iter = $self->find_symbol_iter ($symbol)) {
    $self->move_before ($iter, $self->get_iter_first);
    return 'elevated';
  } else {
    $self->append_symbol ($symbol, $note);
    return 'appended';
  }
}
sub append_symbol {
  my ($self, $symbol, $note) = @_;
  $self->insert_symbol_at_pos ($symbol, $self->length, $note);
}
sub insert_symbol_at_pos {
  my ($self, $symbol, $seq, $note) = @_;
  if (DEBUG) { print "Symlist insert symbol=$symbol seq=$seq\n"; }
  #   if (! $self->can_edit) {
  #     croak 'Cannot edit symlist "'.$self->{'key'}.'"';
  #   }
  $self->insert_with_values ($seq, 0=>$symbol, 1=>$note);
}

sub delete_symbol {
  my ($self, $symbol) = @_;
  if (DEBUG) { print "Symlist ",$self->{'key'},
                 " delete_symbol $symbol\n"; }
  #   if (! $self->can_edit) {
  #     croak 'Cannot edit symlist "'.$self->{'key'}.'"';
  #   }

  # loop in case multiple copies in the list
  while (my $iter = $self->find_symbol_iter ($symbol)) {
    $self->remove ($iter);
  }
}

# return integer pos or undef
sub find_symbol_pos {
  my ($self, $target_symbol) = @_;
  my $path = $self->find_symbol_path ($target_symbol);
  if (! $path) { return undef; }
  my ($seq) = $path->get_indices;
  return $seq;
}

# return Gtk2::TreePath or undef
sub find_symbol_path {
  my ($self, $target_symbol) = @_;
  my $iter = $self->find_symbol_iter ($target_symbol);
  return $iter && $self->get_path($iter);
}

# return Gtk2::TreeIter or undef
sub find_symbol_iter {
  my ($self, $target_symbol) = @_;
  my $hash = $self->hash;
  if (! exists $hash->{$target_symbol}) {
    return undef;
  }

  my $ret;
  $self->foreach (sub {
                    my ($self, $path, $iter) = @_;
                    my $symbol = $self->get_value($iter,0);
                    if ($symbol eq $target_symbol) {
                      $ret = $iter->copy;
                      return 1; # stop iterating
                    } else {
                      return 0; # keep iterating
                    }
                  });
  return $ret;
}

#------------------------------------------------------------------------------

sub symlist_length {
  my ($key) = @_;
  my $last = App::Chart::Database::read_notes_single
    ('SELECT seq FROM symlist_content WHERE key=? ORDER BY seq DESC LIMIT 1',
     $key);
  if (defined $last) {
    return $last + 1;
  } else {
    return 0;
  }
}

sub next {
  my ($symbol, $symlist) = @_;
  do {
    ($symbol, $symlist) = next_plain ($symbol, $symlist);
    if (DEBUG) { print "got $symbol, $symlist\n"; }
  } while (defined $symbol
           && ! App::Chart::Database->symbol_exists ($symbol));
  return ($symbol, $symlist);
}

sub next_plain {
  my ($symbol, $symlist) = @_;

  if (DEBUG) { print "next from ",$symbol||'undef',
                 " ",$symlist||'undef',"\n"; }
  if ($symbol) {
    my $seq = App::Chart::Database::read_notes_single
      ('SELECT seq FROM symlist_content WHERE key=? AND symbol=?',
       $symlist->key, $symbol);
    if (DEBUG) { print "  is seq ",defined $seq ? $seq : 'undef',"\n"; }
    if (! defined $seq) {
      $seq = App::Chart::Database::read_notes_single
        ('SELECT seq FROM symlist_content WHERE key=? AND symbol>=?
          ORDER BY symbol ASC LIMIT 1',
         $symlist->key, $symbol);
    }
    if (defined $seq) {
      $seq++;
      if (DEBUG) { print "  to seq $seq\n"; }
      $symbol = App::Chart::Database::read_notes_single
        ('SELECT symbol FROM symlist_content WHERE key=? AND seq=?',
         $symlist->key, $seq);
      if (defined $symbol) { return ($symbol, $symlist); }
      if (DEBUG) { print "  not found\n"; }
    }
  }

  if (DEBUG) { print "  next symlist from ",$symlist||'undef',"\n"; }
  my $symlist_num = -1;
  if ($symlist) {
    $symlist_num = App::Chart::Database::read_notes_single
      ('SELECT seq FROM symlist WHERE key=?', $symlist->key);
    if (! defined $symlist_num) { $symlist_num = -1; }
  }
  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('SELECT symlist_content.symbol, symlist.key
      FROM symlist,symlist_content
      WHERE symlist.seq > ?
        AND symlist.key = symlist_content.key
        AND symlist_content.seq = 0
      ORDER BY symlist.seq');
  ($symbol, $symlist) = $dbh->selectrow_array($sth, undef, $symlist_num);
  if (defined $symlist) { $symlist = _new_from_known_key ($symlist); }
  return ($symbol, $symlist);
}

sub previous {
  my ($symbol, $symlist) = @_;
  if (DEBUG) { print "previous from $symbol $symlist\n"; }
  if (! $symbol || ! $symlist) { return (undef, undef); }

 AGAIN:
  {
    my $seq = App::Chart::Database::read_notes_single
      ('SELECT seq FROM symlist_content WHERE key=? AND symbol=?',
       $symlist->key, $symbol);
    if (! defined $seq) {
      $seq = App::Chart::Database::read_notes_single
        ('SELECT seq FROM symlist_content WHERE key=? AND symbol<=?
          ORDER BY symbol ASC LIMIT 1',
         $symlist->key, $symbol);
    }

    if (defined $seq && $seq > 0) {
      $seq--;
      $symbol = App::Chart::Database::read_notes_single
        ('SELECT symbol FROM symlist_content WHERE key=? AND seq=?',
         $symlist->key, $seq);
      if (defined $symbol) { goto FOUND; }
    }
  }

  my $symlist_num = App::Chart::Database::read_notes_single
      ('SELECT seq FROM symlist WHERE key=?', $symlist->key);
  if (! defined $symlist_num) { return (undef, undef); }

  for (;;) {
    $symlist_num--;
    if ($symlist_num < 0) { return (undef, undef); }

    my $key = App::Chart::Database::read_notes_single
      ('SELECT key FROM symlist WHERE seq=?', $symlist_num);
    if (! $key) { return (undef, undef); }
    $symlist = _new_from_known_key ($key);

    $symbol = App::Chart::Database::read_notes_single
      ('SELECT symbol FROM symlist_content WHERE key=? ORDER BY seq DESC LIMIT 1',
       $symlist->key);
    if ($symbol) { last; }
  }

 FOUND:
  if (! App::Chart::Database->symbol_exists ($symbol)) {
    goto AGAIN;
  }
 return ($symbol, $symlist);
}


#------------------------------------------------------------------------------
# drag source
#

# gtk_tree_drag_source_row_draggable ($self, $src_path)
sub ROW_DRAGGABLE {
  my ($self, $src_path) = @_;
  if (DEBUG) { print "Symlist ROW_DRAGGABLE path=",$src_path->to_string,"\n";
               print "  ",$self->can_edit?"yes":"no", ", can_edit\n"; }
  $self->can_edit or do {
    if (DEBUG) { print "  no, cannot edit\n"; }
    return undef;
  };
  if (DEBUG) { print "  super:\n"; }
  return $self->SUPER::ROW_DRAGGABLE ($src_path);
}

#------------------------------------------------------------------------------
# drag dest

# gtk_tree_drag_dest_row_drop_possible
#
sub ROW_DROP_POSSIBLE {
  my ($self, $dst_path, $sel) = @_;
  ### Symlist ROW_DROP_POSSIBLE
  ### to path: $dst_path->to_string
  ### type: $sel->type->name

  $self->can_edit or do {
    ### no, cannot edit
    return 0;
  };
  if ($dst_path->get_depth != 1) {
    ### no, dest path depth: $dst_path->get_depth
    return 0;
  }

  if (defined (my $str = $sel->get_text)) {
    ### yes, can drop text
    return 1;
  }

  if (my ($src_model, $src_path) = $sel->get_row_drag_data) {
    if ($src_model->isa('App::Chart::Gtk2::Symlist')) {
      ### yes, source model is a Symlist
      return 1;
    }
  }

  ### no, not text or symlist row
  return 0;
}

# gtk_tree_drag_dest_drag_data_received
#
sub DRAG_DATA_RECEIVED {
  my ($self, $dst_path, $sel) = @_;
  ### Symlist DRAG_DATA_RECEIVED
  ### to path: $dst_path->to_string
  ### type: $sel->type->name
  ### src model: (($sel->get_row_drag_data)[0])
  ### src path : (($sel->type->name eq 'GTK_TREE_MODEL_ROW') && ($sel->get_row_drag_data)[1]->to_string)

  ### get_text: $sel->get_text
  if (defined (my $str = $sel->get_text)) {
    if ($dst_path->get_depth != 1) {
      ### no, dest path depth: $dst_path->get_depth
      return 0;
    }
    my ($dst_index) = $dst_path->get_indices;
    eval { $self->insert_with_values ($dst_index, COL_SYMBOL, $str); 1 }
      or do {
        ### no, error from insert_with_values(): $@
        return 0;
      };
    ### yes, dropped text
    return 1;
  }

  ### go to SUPER
  return $self->SUPER::DRAG_DATA_RECEIVED ($dst_path, $sel);
}


1;
__END__

=for stopwords arrayref hashref

=head1 NAME

App::Chart::Gtk2::Symlist -- symbol list objects

=head1 SYNOPSIS

 use App::Chart::Gtk2::Symlist;

=head1 FUNCTIONS

=over 4

=item C<< $symlist->symbols() >>

=item C<< $symlist->symbol_listref() >>

=item C<< $symlist->hash() >>

Return the symbols in C<$symlist>, either as a list return, an arrayref, or
a hashref.

=back

=cut
