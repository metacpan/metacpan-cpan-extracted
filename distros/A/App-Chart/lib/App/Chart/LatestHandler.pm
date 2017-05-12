# Latest quotes download handlers.

# Copyright 2007, 2008, 2009, 2010, 2011, 2014, 2016, 2017 Kevin Ryde

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

package App::Chart::LatestHandler;
use 5.010;
use strict;
use warnings;
use Carp;
use Encode;
use Encode::Locale;  # for coding system "locale"
use List::Util;
# use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::Sympred;

# uncomment this to run the ### lines
# use Smart::Comments;

our @handler_list = ();

sub new {
  my $class = shift;
  my $self = bless ({ @_ }, $class);
  App::Chart::Sympred::validate ($self->{'pred'});
  push @handler_list, $self;
  # highest priority first, and 'stable' for order added among equal
  use sort 'stable'; # lexical in 5.10
  @handler_list = sort { ($b->{'priority'} || 0) <=> ($a->{'priority'} || 0) }
    @handler_list;
  return $self;
}

sub handler_for_symbol {
  if (@_ != 2) { croak "wrong number of arguments"; }
  my ($class, $symbol) = @_;
  App::Chart::symbol_setups ($symbol);
  return List::Util::first { $_->{'pred'}->match($symbol) } @handler_list;
}

sub download {
  my ($class, $orig_symbol_list, $orig_extra_list) = @_;
  $orig_extra_list ||= [];
  ### LatestHandler download()
  ### $orig_symbol_list
  ### $orig_extra_list

  my (@symbol_list, @extra_list);
  {
    # delete duplicates and any extra_list already in symbol_list
    my %hash;
    @symbol_list = grep {!$hash{$_}++} @$orig_symbol_list;
    @extra_list  = grep {!$hash{$_}++} @$orig_extra_list;
  }

  foreach my $symbol (@symbol_list, @extra_list) {
    App::Chart::symbol_setups ($symbol);
  }

  while (@symbol_list) {
    ### LatestHandler considering: "@symbol_list"
    my @this_list = (shift @symbol_list);

    my $handler = $class->handler_for_symbol ($this_list[0]);
    if (! $handler) {
      print "No latest handler for \"",$this_list[0],"\"\n";
      next;
    }
    my $pred = $handler->{'pred'};
    my $max_symbols = $handler->{'max_symbols'} || 1_000_000;

    foreach my $list (\@symbol_list, \@extra_list) {
      for (my $i = 0; @this_list < $max_symbols && $i < @$list; ) {
        my $symbol = $list->[$i];
        if ($pred->match ($symbol)) {
          push @this_list, $symbol;
          splice @$list, $i,1;
        } else {
          $i++;
        }
      }
    }

    my $proc = $handler->{'proc'};
    my $trace;
    unless (do {
      local $SIG{'__DIE__'} =
        (# $App::Chart::option{'verbose'} &&
         eval { require Devel::StackTrace; 1 }
         ? sub {
           { local $@; $trace = Devel::StackTrace->new; }
           die $@;
         }
         : $SIG{'__DIE__'});
      eval { $proc->(\@this_list); 1 };
    }) {
      my $err = $@;
      unless (utf8::is_utf8($err)) { $err = Encode::decode('locale',$err); }
      say "Latest download error: ", $err;
      if (defined $trace) {
        say $trace->as_string;
      }
    }
  }
}

sub expand_arguments {
  my ($args) = @_;
  my @symbol_list = ();
  foreach my $arg (@$args) {
    if (ref $arg) {
      push @symbol_list, $arg->symbols;
    } else {
      push @symbol_list, App::Chart::Download::symbol_glob ($arg);
    }
  }
  return @symbol_list;
}

sub command_line_download {
  my ($class, $args) = @_;
  my @symbol_list = expand_arguments ($args);
  $class->download (\@symbol_list, []);
}



1;
__END__

=for stopwords intraday undef

=head1 NAME

App::Chart::LatestHandler -- latest quotes download handler object

=head1 SYNOPSIS

 use App::Chart::LatestHandler;

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::LatestHandler->new (...) >>

Create and register a new intraday image handler.  The return is a new
C<App::Chart::LatestHandler> object, though usually this is not of interest
(only all the handlers later with C<handlers_for_symbol> below).

    my $pred = App::Chart::Sympred::Suffix->new ('.NZ');

    App::Chart::LatestHandler->new
      (pred => $pred,
       proc => \&latest_download);

=item C<< App::Chart::LatestHandler->handler_for_symbol ($symbol) >>

Return the C<App::Chart::LatestHandler> object which handles C<$symbol>, or
return undef if none.

=item C<< App::Chart::LatestHandler->download ($symbol_list, $extra_list) >>


=back
