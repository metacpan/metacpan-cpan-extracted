# Copyright 2008, 2009, 2010, 2011, 2017 Kevin Ryde

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

package App::Chart::Gtk2::Job::Latest;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use App::Chart::Gtk2::Job;
use App::Chart::Latest;

# uncomment this to run the ### lines
# use Smart::Comments;

use Glib::Object::Subclass
  'App::Chart::Gtk2::Job',
  signals => { notify => \&_do_notify },
  properties => [ Glib::ParamSpec->boxed
                  ('symbol-list',
                   'Symbol list',
                   'Arrayref of share symbols.',
                   'Glib::Strv',
                   Glib::G_PARAM_READWRITE),
                ];

our %inprogress = ();

sub type {
  return __('Latest');
}

sub start_symlist {
  my ($class, $symlist) = @_;
  ### Job-Latest start_symlist()
  require App::Chart::Gtk2::Symlist;
  return $class->start ([$symlist->interested_symbols]);
}

sub start_for_view {
  my ($class, $symbol, $symlist) = @_;
  my $symbol_list = [ $symbol ];
  my $extra_list = [ ];
  if ($symlist) {
    my $l = $symlist->symbol_listref;
    my @l = List::MoreUtils::after {$_ eq $symbol} @$l;
    push @$symbol_list, shift @l;
    push @$extra_list, splice @l,0,9;
    @l = List::MoreUtils::before {$_ eq $symbol} @$l;
    if (@l) { push @$extra_list, $l[-1]; }
  }
  $class->start ($symbol_list, $extra_list);
}

sub start {
  my ($class, $symbol_list, $extra_list) = @_;
  ### Job-Latest start()
  ### $symbol_list
  ### $extra_list

  my $new_symbol_list = [ grep {defined && !/^\s*$/ && !$inprogress{$_}}
                          @$symbol_list ];
  if (! @$new_symbol_list) {
    ### all still inprogress
    return $inprogress{$symbol_list->[0]};
  }
  $symbol_list = $new_symbol_list;
  $extra_list  = [ grep {!$inprogress{$_}} @$extra_list ];

  my $name = (@$extra_list
              ? __x('Latest {symbol_list} (and maybe {extra_list})',
                    symbol_list => form_symbol_list($symbol_list),
                    extra_list  => form_symbol_list($extra_list))
              : __x('Latest {symbol_list}',
                    symbol_list => form_symbol_list($symbol_list)));

  my $job = $class->SUPER::start
    (args        => [ 'latest', $symbol_list, $extra_list ],
     name        => $name,
     symbol_list => $symbol_list);
  foreach my $symbol (@$symbol_list) {
    $inprogress{$symbol} = $job;
  }
  ### Job-Latest latest-changed for inprogress: "@$symbol_list"
  my %symbol_hash;
  @symbol_hash{@$symbol_list} = ();
  App::Chart::chart_dirbroadcast()->send_locally
      ('latest-changed', \%symbol_hash);
  return $job;
}

# 'notify' class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### Job-Latest notify(): $pname
  ### value: $self->get($pname)

  if ($pname eq 'status') {
    if (! $self->is_stoppable) {
      my $symbol_list = $self->{'symbol_list'};
      delete @inprogress{@$symbol_list};
      ### Job-Latest latest-changed for done: "@$symbol_list"

      my %symbol_hash;
      @symbol_hash{@$symbol_list} = ();  # hash slice
      App::Chart::chart_dirbroadcast()->send_locally
          ('latest-changed', \%symbol_hash);
    }
  }
  return shift->signal_chain_from_overridden(@_);
}

sub find {
  my ($class, $symbol) = @_;
  return $inprogress{$symbol};
}

sub form_symbol_list {
  my ($symbol_list) = @_;
  my @list = @$symbol_list[0 .. min ($#$symbol_list, 4)];
  if (@list < @$symbol_list) { push @list, __('...'); }
  return join (' ', @list);
}

1;
__END__
