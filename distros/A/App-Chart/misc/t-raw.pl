#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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


use strict;
use warnings;
use Gtk2 '-init';
use App::Chart::Gtk2::RawDialog;
use App::Chart::Database;
use App::Chart::DBI;
use Gtk2::Ex::Datasheet::DBI;
use Gtk2::Ex::Units;
use App::Chart::Gtk2::GUI;

if (1) {
  my $dialog = App::Chart::Gtk2::RawDialog->popup ('BHP.AX');
  $dialog->signal_connect (unmap => sub { Gtk2->main_quit; });
  Gtk2->main;
  exit 0;
}


my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->signal_connect (destroy => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (0, 0);
$toplevel->add ($vbox);


my $em = Gtk2::Ex::Units::em($toplevel);
print "$em\n";
my $dbh = App::Chart::DBI->instance;

my $datasheet_def
  = { dbh => $dbh,
      sql => { select   => "date, new, old, note",
               from     => "split",
               order_by => "date"
             },
      vbox => $vbox,
      fields => [ { name          => 'date',
                    x_percent     => 35,
                    # validation    => sub { &validate_first_name(@_); }
                  },
                  { name          => 'new',
                    align         => 'right',
                    x_percent     => 35
                  },
                  { name          => 'old',
                    align         => 'right',
                    x_percent     => 30,
                  },
                  { name          => 'note',
                    align         => 'right',
                    x_percent     => 30,
                  },
                ],
    };

sub validate_date {
  my ($str) = @_;
  return ($str =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/);
}

$datasheet_def
  = { dbh => $dbh,
      sql => { select   => 'ex_date, record_date, pay_date, amount, imputation, qualifier, note',
               from     => 'dividend',
               order_by => 'ex_date',
               where    => 'symbol=?',
               bind_values => [ 'BHP.AX' ],
             },
      vbox => $vbox,
      fields => [ { name          => 'ex_date',
                    # renderer      => 'date',
                    validation    => \&validate_date,
                  },
                  { name          => 'record_date',
                    # renderer      => 'date',
                    validation    => \&validate_date,
                  },
                  { name          => 'pay_date',
                    # renderer      => 'date',
                    validation    => \&validate_date,
                  },
                  { name          => 'amount',
                    align         => 'right',
                    # x_percent     => 35
                  },
                  { name          => 'imputation',
                    align         => 'right',
                    # x_percent     => 30,
                  },
                  { name          => 'qualifier',
                    header_markup => 'Qualifier',
                  },
                  { name          => 'note',
                    # x_percent     => 30,
                  },
                ],
    };

$datasheet_def
  = { dbh => App::Chart::DBI->instance,
      sql => { select   => 'date, open, high, low, close, volume, openint',
               from     => 'daily',
               order_by => 'date',
               where    => 'symbol=?',
               bind_values => [ 'BHP.AX' ],
             },
      vbox => $vbox,
      # treeview => $treeview,
      fields => [ { name       => 'date',
                    validation => \&validate_date,
                    x_absolute => 9 * $em,
                  },
                  { name       => 'open',
                    align      => 'right',
                    x_absolute => 9 * $em,
                  },
                  { name       => 'high',
                    align      => 'right',
                    x_absolute => 9 * $em,
                  },
                  { name       => 'low',
                    align      => 'right',
                    x_absolute => 9 * $em,
                  },
                  { name       => 'close',
                    align      => 'right',
                    x_absolute => 9 * $em,
                  },
                  { name       => 'volume',
                    align      => 'right',
                    x_absolute => 10 * $em,
                  },
                  { name       => 'openint',
                    align      => 'right',
                    x_absolute => 10 * $em,
                  },
                ],
    };

my $treeview = Gtk2::TreeView->new;
$vbox->pack_start ($treeview, 0,0,0);

$datasheet_def = { dbh => $dbh,
                   sql => { select   => 'key, value',
                            from     => 'extra',
                            order_by => 'key ASC',
                            where    => 'symbol=?',
                            bind_values => [ '' ],
                          },
                   treeview => $treeview,
                   fields => [
                              { name => 'key',
                                header_markup => ('Key'),
                                x_absolute    => 15 * $em,
                              },
                              { name => 'value',
                                header_markup => ('Value'),
                                x_absolute    => 15 * $em,
                              },
                             ],
                 };

my $datasheet = Gtk2::Ex::Datasheet::DBI->new ($datasheet_def)
  or die ("Error setting up Gtk2::Ex::Datasheet::DBI\n");


#App::Chart::Gtk2::RawDialog->popup(undef);
$toplevel->show_all;
Gtk2->main;
exit 0;






  #   if (0) {    # too slow
  #     my $scrolled = Gtk2::ScrolledWindow->new;
  #     push @scrolleds, $scrolled;
  #     $scrolled->set (hscrollbar_policy => 'never');
  #     $notebook->append_page ($scrolled, __('Data'));
  # 
  #     my $treeview = $self->{'treeview'} = Gtk2::TreeView->new;
  #     $scrolled->add ($treeview);
  # 
  #     my $datasheet = Gtk2::Ex::Datasheet::DBI->new
  #       ({ dbh => App::Chart::DBI->instance,
  #          sql => { select   => 'date, open, high, low, close, volume, openint',
  #                   from     => 'daily',
  #                   order_by => 'date DESC',
  #                   where    => 'symbol=?',
  #                   bind_values => [ '' ],
  #                 },
  #          treeview => $treeview,
  #          fields => [ { name          => 'date',
  #                        header_markup => __('Date'),
  #                        x_absolute    => $date_width,
  #                        validation    => \&validate_date,
  #                      },
  #                      { name          => 'open',
  #                        header_markup => __('Open'),
  #                        align         => 'right',
  #                        x_absolute    => 9 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                      { name          => 'high',
  #                        header_markup => __('High'),
  #                        align         => 'right',
  #                        x_absolute    => 9 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                      { name          => 'low',
  #                        header_markup => __('Low'),
  #                        align         => 'right',
  #                        x_absolute    => 9 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                      { name          => 'close',
  #                        header_markup => __('Close'),
  #                        align         => 'right',
  #                        x_absolute    => 9 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                      { name          => 'volume',
  #                        header_markup => __('Volume'),
  #                        align         => 'right',
  #                        x_absolute    => 10 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                      { name          => 'openint',
  #                        header_markup => __('Open Int'),
  #                        align         => 'right',
  #                        x_absolute    => 8 * $digit_width,
  #                        validation    => \&validate_number,
  #                      },
  #                    ],
  #        });
  #     $scrolled->{'datasheet'} = $datasheet;
  #     push @{$self->{'datasheets'}}, $datasheet;
  # 
  #     foreach my $column ($treeview->get_columns) {
  #       $column->set (sizing => 'fixed',
  #                     resizable => 1);
  #       foreach my $renderer ($column->get_cell_renderers) {
  #         if (my $subr = $renderer->can('set_fixed_height_from_font')) {
  #           $renderer->set_fixed_height_from_font (1);  # one line high
  #         }
  #       }
  #     }
  #     $treeview->set_fixed_height_mode (1);
  #   }
  
 
