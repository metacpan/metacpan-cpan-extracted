# Copyright 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2017 Kevin Ryde

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


# ENHANCE-ME:
# remember which latests sent, only give 'update' for them


package App::Chart::EmacsMain;
use 5.010;
use strict;
use warnings;
use Encode;
use Encode::Locale;  # for coding system "locale"
use IO::Handle;
use Lisp::Reader;
use Lisp::Printer ('lisp_print');
use Lisp::Symbol ('symbol');
use POSIX ();
use Regexp::Common 'whitespace';
use Locale::TextDomain 'App-Chart';

use App::Chart;

# set this to 1 for development debugging prints
use constant { DEBUG => 0,
               DEBUG_TTY_FILENAME => '/dev/tty7' };


use constant PROTOCOL_VERSION => 102;
my $emacs_fh;

# reopen $fd on $filename with $omode a POSIX::O_WRONLY() etc value
# return $fd on success, or undef with $! set on error
sub fdreopen {
  my ($fd, $filename, $omode) = @_;
  my $file_fd = POSIX::open ($filename, $omode);
  if (! defined $fd) { return undef; }
  # print "fdreopen $fd $filename, via $file_fd\n";

  if (! defined POSIX::dup2 ($file_fd, $fd)) {
    {
      local $!;
      POSIX::close ($file_fd);
    }
    return undef;
  }
  if (! defined POSIX::close ($file_fd)) { return undef; }
  return $fd;
}

sub main {
  my ($class) = @_;

  # subprocess unbuffered and utf8
  binmode (STDIN, ':utf8') or die;

  # dup-ed to a new descriptor to talk to emacs
  open $emacs_fh, '>&STDOUT' or die;
  $emacs_fh->autoflush(1); # emacs_write() does single-string prints

  # ENHANCE-ME: use one of the IO::Capture or via layer or whatnot to get
  # perl prints to STDOUT/STDERR and send them up to an emacs buffer, or
  # message area
  #
  # stdout/stderr fds 1 and 2 put to /dev/null to discard other prints
  my $devnull = File::Spec->devnull;
  fdreopen (1, $devnull, POSIX::O_WRONLY())
    // die "Cannot send STDOUT to $devnull: ", Glib::strerror($!);
  POSIX::dup2 (1, 2) // die;

  if (DEBUG) {
    # fds 1 and 2 changed (again) to DEBUG_TTY_FILENAME, if it's possible to
    # open that
    if (fdreopen (1, DEBUG_TTY_FILENAME, POSIX::O_WRONLY())) {
      POSIX::dup2 (1, 2) // die "Cannot dup fd 1 to fd 2: $!";

      print "EmacsMain started, emacs_fh fd=",fileno($emacs_fh),
        ", diagnostics on ",DEBUG_TTY_FILENAME,"\n";
      print "  STDOUT fd ",fileno(STDOUT),", STDERR fd ",fileno(STDERR),"\n";
      STDOUT->autoflush(1);
      STDERR->autoflush(1); # probably true already
    }
  }


  # initial message
  emacs_write (symbol('init'), 'UTF-8', PROTOCOL_VERSION);

  my $mainloop = Glib::MainLoop->new;
  STDIN->blocking(0);
  Glib::IO->add_watch (fileno(STDIN), ['in', 'hup', 'err'], \&_do_read,
                       $mainloop);

  $Lisp::Reader::SYMBOLS_AS_STRINGS = 1;

  my $dirb = App::Chart::chart_dirbroadcast();
  $dirb->listen;
  $dirb->connect ('delete-symbol', \&completions_update);
  $dirb->connect ('symlist-content-changed',  \&_do_symlist_content_changed);
  $dirb->connect ('symlist-content-inserted', \&_do_symlist_content_inserted);
  $dirb->connect ('symlist-content-deleted',  \&_do_symlist_content_deleted);
  $dirb->connect ('symlist-content-reordered',\&_do_symlist_content_reordered);
  $dirb->connect ('symlist-list-changed',     \&_do_symlist_list_changed);

  $dirb->connect ('latest-changed', \&send_update);
  $dirb->connect ('data-changed', \&send_update);

  Glib->install_exception_handler (\&exception_handler);
  ## no critic (RequireLocalizedPunctuationVars)
  $SIG{'__WARN__'} = \&exception_handler;
  $mainloop->run;
}

# 'data-changed' and 'latest-changed'
sub send_update {
  my ($changed) = @_;
  if (DEBUG) { print "Changed: ",join(' ',keys %$changed),"\n"; }
  emacs_write (symbol('update'), [ keys %$changed ]);

  # this is a bit excessive, only really want to know if new symbols have
  # been added to the latest quotes
  completions_update();
}

sub exception_handler {
  my ($msg) = @_;
  # perhaps some modules like LWP will put through a locale $! or similar
  unless (utf8::is_utf8($msg)) { $msg = Encode::decode('locale',$msg); }
  if (DEBUG) { print "Error ", $msg; }

  $msg =~ s/$RE{ws}{crop}//g;      # leading and trailing whitespace

  # $trace->as_string has non-ascii de-fanged to something printable, so it
  # can go straight out
  #
  my $backtrace;
  if (eval { require Devel::StackTrace; }) {
    $backtrace = Devel::StackTrace->new->as_string;
    $msg .= __('See *chart-process-backtrace* buffer');
  }
  emacs_write (symbol('error'), $msg, $backtrace);

  return 1; # stay installed
}

sub emacs_write {
  if (DEBUG >= 2) { require Data::Dumper;
                    print Data::Dumper::Dumper(\@_); }
  if (DEBUG) { print "To emacs: ",lisp_print([@_]),"\n"; }
  print $emacs_fh lisp_print([@_]),"\n";
}

my $buf = '';

sub _do_read {
  my ($fd, $conditions, $mainloop) = @_;

  for (;;) {
    if (DEBUG >= 2) { print "  read more at ",length($buf),"\n"; }
    my $got = read STDIN, $buf, 8192, length($buf);
    if (DEBUG >= 2) { print "  got ",$got//'undef'," $!\n"; }
    if (! defined $got) {
      if ($! == POSIX::EWOULDBLOCK()) { last; }  # no more data for now
      if ($!) {
        print STDERR "Read error: ",Glib::strerror($!),"\n";
      }
      $mainloop->quit;
      return 0;
    }
    if ($got == 0) {
      ## no critic (ProhibitExit, ProhibitExitInSubroutines)
      exit 0;
    }
  }

  my ($aref, $endpos) = Lisp::Reader::lisp_read ($buf);
  $buf = substr ($buf, $endpos);

  if (DEBUG) { require Data::Dumper;
               print "Receive: ",Data::Dumper::Dumper($aref);
               print "leaving buf ",length($buf),"\n"; }
  foreach my $list (@$aref) {
    call_command ($list);
  }
  return 1; # stay connected
}

sub call_command {
  my ($list) = @_;
  my $lisp_command = shift @$list;
  my $command = $lisp_command;
  $command =~ tr/-/_/;
  $command = "emacs_command_$command";
  if (DEBUG) { print "Call $command\n"; }
  if (defined &$command) {
    no strict;
    &$command (@$list);
  } else {
    emacs_write (symbol('error'), "Unknown $command ($lisp_command)", undef);
  }
}

#-----------------------------------------------------------------------------
# broadcast handlers

# 'symlist-list-changed' handler
sub _do_symlist_list_changed {
  my ($key, $pos) = @_;
  if ($key eq 'all' || $key eq 'favourites') {
    completions_update();
  }
  emacs_write (symbol('symlist-list-changed'), [ $key ]);
}
# 'symlist-content-changed' handler
sub _do_symlist_content_changed {
  my ($key, $pos) = @_;
  if ($key eq 'all' || $key eq 'favourites') {
    completions_update();
  }
  emacs_write (symbol('symlist-update'), [ $key ]);
}
# 'symlist-content-deleted' handler
sub _do_symlist_content_deleted {
  my ($key, $pos) = @_;
  if ($key eq 'all' || $key eq 'favourites') {
    completions_update();
  }
  emacs_write (symbol('symlist-update'), [ $key ]);
}
# 'symlist-content-inserted' handler
sub _do_symlist_content_inserted {
  my ($key, $pos) = @_;
  if ($key eq 'all' || $key eq 'favourites') {
    completions_update();
  }
  emacs_write (symbol('symlist-update'), [ $key ]);
}
# 'symlist-content-reordered' handler
sub _do_symlist_content_reordered {
  my ($key, $pos) = @_;
  if ($key eq 'all' || $key eq 'favourites') {
    completions_update();
  }
  emacs_write (symbol('symlist-update'), [ $key ]);
}



#-----------------------------------------------------------------------------

# return string for $latest
sub latest_line {
  my ($latest) = @_;
  my $excess = 0;
  my $ret = '';
  my $add = sub {
    my ($width, $str) = @_;
    my $this = sprintf ('%*s', $width, $str//'');
    $excess += length($this) - abs($width);
    while ($excess > 0 && $ret =~ /  $/) {
      $ret = substr ($ret, 0, -1);
      $excess--;
    }
    while ($excess > 0 && length($this) > 1 && $this =~ /^ /) {
      $this = substr ($this, 1);
      $excess--;
    }
    $ret .= $this;
  };
  $add->(-9, $latest->{'symbol'});
  my $bid = $latest->{'bid'};
  my $offer = $latest->{'offer'};
  $add->(7, format_price($bid));
  my $slash = (defined $bid && defined $offer && $bid > $offer ? 'x' : '/');
  $add->(1, $slash);
  $add->(-7, format_price($offer));
  $add->(1, ' ');
  $add->(7, format_price($latest->{'last'}));
  $add->(1, ' ');
  $add->(6, format_price($latest->{'change'}));
  $add->(1, ' ');
  $add->(7, format_price($latest->{'low'}));
  $add->(1, ' ');
  $add->(7, format_price($latest->{'high'}));
  $add->(1, ' ');
  $add->(7, $latest->formatted_volume);
  $add->(1, ' ');
  $add->(7, $latest->short_datetime);
  $add->(1, ' ');

  my @notes;
  if ($latest->{'halt'}) { push @notes, __('halt'); }
  if ($latest->{'limit_up'}) { push @notes, __('limit up'); }
  if ($latest->{'limit_down'}) { push @notes, __('limit down'); }
  if (my $note = $latest->{'note'}) { push @notes, $note; }
  if (my $error = $latest->{'error'}) { push @notes, $error; }
  my $note = join (', ', @notes);
  $add->(length($note), $note);

  return $ret;
}

sub format_price {
  my ($str) = @_;
  if (! defined $str) { return ''; }
  my $nf = App::Chart::number_formatter();
  return eval { $nf->format_number ($str, App::Chart::count_decimals($str), 1) }
    // __('[bad]');
}

sub latest_to_face {
  my ($latest) = @_;
  if ($App::Chart::Gtk2::Job::Latest::inprogress{$latest->{'symbol'}}) {
    return symbol('chartprog-in-progress');
  }
  my $change = $latest->{'change'} || 0;
  if ($change > 0) {
    return  symbol('chartprog-up');
  } elsif ($change < 0) {
    return symbol('chartprog-down');
  }
  return undef;
}

# return element list [$symbol, $string, $face, $help]
sub latest_elem {
  my ($symbol) = @_;
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);

  my $face = latest_to_face($latest);

  my $help = join (' - ', $symbol, $latest->{'name'}//'') . "\n";
  if (my $quote_date = $latest->{'quote_date'}) {
    my $quote_time = $latest->{'quote_time'} || '';
    $help .= __x("Quote: {quote_date} {quote_time}",
                 quote_date => $quote_date,
                 quote_time => $quote_time)
      . "\n";
  }
  if (my $last_date = $latest->{'last_date'}) {
    my $last_time = $latest->{'last_time'} || '';
    $help .= __x("Last:  {last_date} {last_time}",
                 last_date => $last_date,
                 last_time => $last_time);
    $help .= "\n";
  }
  $help .= __x("{location} time; source {source}",
               location => App::Chart::TZ->for_symbol($symbol)->name,
               source => $latest->{'source'});

  return [$symbol, latest_line($latest), $face, $help];
}

#-----------------------------------------------------------------------------
# commands

# send latest lines for SYMBOL-LIST
sub emacs_command_latest_get_list {
  my ($symbol_list) = @_;

  # write in chunks of 20 symbols
  while (@$symbol_list) {
    my @part = splice @$symbol_list, 0, 20;
    emacs_write (symbol('latest-line-list'),
                 [ map { latest_elem($_) } @part ]);
  }
}

sub emacs_command_request_symbols {
  my ($symbol_list) = @_;
  require App::Chart::Gtk2::Job::Latest;
  App::Chart::Gtk2::Job::Latest->start ($symbol_list);
}

sub emacs_command_request_explicit {
  goto &emacs_command_request_symbols;
}

# send the symbols in symlist $key
sub emacs_command_get_symlist {
  my ($key) = @_;
  require App::Chart::Gtk2::Symlist;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  emacs_write (symbol('symlist-list'), symbol($key), $symlist->symbol_listref);
}

sub emacs_command_synchronize {
  my ($n) = @_;
  emacs_write (symbol('synchronize', $n));
}

sub emacs_command_synchronous {
  my ($seq, $func, @args) = @_;
  if (DEBUG) { print "  synchronous to $func\n"; }
  emacs_write (symbol('synchronous'), $seq,
               call_command ([$func, @args]));
}

sub emacs_command_noop {
}


#-----------------------------------------------------------------------------
# symlist manipulations

# (request-symlist KEY)
# Begin a download of latest prices for all symbols in symlist KEY.
#
sub emacs_command_request_symlist {
  my ($key) = @_;
  require App::Chart::Gtk2::Symlist;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  require App::Chart::Gtk2::Job::Latest;
  App::Chart::Gtk2::Job::Latest->start_symlist ($symlist);
}

sub emacs_command_request_explicit_symlist {
  goto &emacs_command_request_symlist;
}

# (symlist-delete KEY POS COUNT)
#
sub emacs_command_symlist_delete {
  my ($key, $pos, $count) = @_;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  foreach (1 .. $count) {
    my $iter = $symlist->iter_nth_child (undef, $pos);
    $symlist->remove ($iter);
  }
}

sub emacs_command_symlist_insert {
  my ($key, $pos, $symbol_list) = @_;
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  foreach my $symbol (@$symbol_list) {
    $symlist->insert_symbol_at_pos ($symbol, $pos++);
  }
}


#-----------------------------------------------------------------------------
# completion - symbols

sub emacs_command_get_completion_symbols {
  my %symbols;

  #   # favourites list symbols
  #   {
  #     require App::Chart::Gtk2::Symlist::Favourites;
  #     if (my $favourites = App::Chart::Gtk2::Symlist::Favourites->instance) {
  #       my $href = $favourites->hash;
  #       %symbols = %$href;  # copy
  #     }
  #   }

  # all database data symbols
  require App::Chart::Database;
  @symbols{App::Chart::Database->symbols_list()} = (); # hash slice

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  foreach my $statement (# all latest record symbols
                         'SELECT symbol FROM latest',
                         # all symbols in all lists
                         'SELECT symbol FROM symlist_content') {
    my $sth = $dbh->prepare_cached($statement);
    my $a = $dbh->selectcol_arrayref ($sth);
    @symbols{@$a} = (); # hash slice
  }
  return [ map {[$_]} sort keys %symbols ];
}

sub completions_update {
  emacs_write (symbol('completion-symbols-update'));
}


#-----------------------------------------------------------------------------
# symlist alist

# the `chart-symlist-alist' data, being a list of elements (NAME KEY
# EDITABLE), is sent up as an asynch, and with a dummy return value
#
# this suits chart-watchlist startup which doesn't want to wait, and
# chart-symlist-alist forced initialization, which does want to wait
#
sub emacs_command_get_symlist_alist {
  #   my $model = App::Chart::Gtk2::SymlistListModel->instance;
  #   my @list;
  #   $model->foreach (sub {
  #                      my ($model, $path, $iter) = @_;
  #                      $model->get_value ($iter, $model->COL_NAME))
  #                      $model->get_value ($iter, $model->COL_KEY))
  #   column_contents$model

  require App::Chart::Gtk2::Symlist;
  emacs_write (symbol('symlist-alist'),
               [ map { my $symlist = $_;
                       [ $symlist->name,
                         symbol($symlist->key),
                         $symlist->can_edit ? symbol('t') : undef ]
                     }
                 App::Chart::Gtk2::Symlist->all_lists ]);
  return undef;
}


#-----------------------------------------------------------------------------
# individual `chart-quote'

# Return [$symbol, $string, $face, $help] intended for display in the
# message area of an `M-x chart-quote' single-symbol quote.
#
# The return is the current latest quote.  Nothing is downloaded.  (That's
# done by a separate `request-explicit'.)
#
# The symbol name and timezone are appended to the $string returned so as to
# show that as a second line in the message area (in GNU emacs which has
# multi-line messages, but not XEmacs circa its 21.4).
# 
sub emacs_command_quote_one {
  my ($symbol) = @_;
  if (DEBUG) { print "  quote-one $symbol\n"; }

  my $elem = latest_elem ($symbol);
  my $extra = '';
  if (length($symbol) > 9) {
    $extra = $symbol;
  }

  # " - name", when the name is available
  my $latest = App::Chart::Latest->get ($symbol);
  if (my $name = $latest->{'name'}) {
    if ($extra) {
      $extra = join (' - ', $extra, $name);
    } else {
      $extra = $name;
    }
  }
  my $timezone = App::Chart::TZ->for_symbol($symbol);
  if ($timezone != App::Chart::TZ->loco) {
    $extra = join ('  ', $extra, '[' . $timezone->name . ']');
  }
  $elem->[1] = join ("\n", $elem->[1], $extra);

  return $elem;
}

#-----------------------------------------------------------------------------
# latest records

sub emacs_command_get_latest_record {
  my ($symbol) = @_;
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);

  return [ symbol('symbol'),     $latest->{'symbol'},
           symbol('name'),       $latest->{'name'},
           symbol('quote-date'), $latest->{'quote_date'},
           symbol('quote-time'), $latest->{'quote_time'},
           symbol('bid'),        $latest->{'bid'},
           symbol('offer'),      $latest->{'offer'},
           symbol('open'),       $latest->{'open'},
           symbol('high'),       $latest->{'high'},
           symbol('low'),        $latest->{'low'},
           symbol('last'),       $latest->{'last'},
           symbol('last-date'),  $latest->{'last_date'},
           symbol('last-time'),  $latest->{'last_time'},
           symbol('change'),     $latest->{'change'},
           symbol('volume'),     $latest->{'volume'},
           symbol('decimals'),   0,
           symbol('note'),       $latest->{'note'},
           symbol('source'),     $latest->{'source'},
           symbol('face'),       latest_to_face($latest),
         ];
}


#-----------------------------------------------------------------------------
# spreadsheet support

# return when SYMBOL-LIST has been downloaded
# (define-public (emacs-command-request-symbols-synchronous symbol-list)
#   (call-with-current-continuation
#    (lambda (cont)
#      (define (callback this-symbol-list)
#        (set! this-symbol-list (remove latest-in-progress? this-symbol-list))
#        (set! symbol-list (lset-difference string=?
# 					  symbol-list this-symbol-list))
#        (if (null? symbol-list)
# 	   (begin
# 	     (notify-disconnect 'latest-update callback)
# 	     (cont #f))))
#      (notify-connect 'latest-update callback)
#      (c-main-enq! latest-request-symbols symbol-list)
#      (c-main-goto-top)))
#   'nil)

1;
__END__

=head1 NAME

App::Chart::EmacsMain -- main loop for Emacs interaction

=head1 SYNOPSIS

 use App::Chart::EmacsMain;
 App::Chart::EmacsMain->main ();

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2014, 2015, 2016, 2017 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
