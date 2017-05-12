# Copyright 2007, 2008, 2009, 2010, 2011, 2013, 2014 Kevin Ryde

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

package App::Chart::Gtk2::ViewStyleDialog;
use 5.010;
use strict;
use warnings;
use Glib::Ex::ConnectProperties;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::View;

# uncomment this to run the ### lines
#use Smart::Comments;

use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { notify => \&_do_notify,
               show   => \&_do_show },
  properties => [Glib::ParamSpec->scalar
                 ('viewstyle',
                  'viewstyle',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->object
                 ('view',
                  'view',
                  'Blurb.',
                  'App::Chart::Gtk2::View',
                  Glib::G_PARAM_READWRITE),
                ];

use constant RESPONSE_SAVE => 0;

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: View Style'));
  $self->add_buttons ('gtk-ok'     => 'ok',
                      'gtk-save'   => RESPONSE_SAVE,
                      'gtk-cancel' => 'cancel',
                      'gtk-help'   => 'help');
  $self->signal_connect (response => \&_do_response);
  my $vbox = $self->vbox;

  $vbox->pack_start (Gtk2::Label->new
                     ("Warning, this dialog is not quite right."),
                     0,0,0);

  my $hbox = Gtk2::HBox->new (0, 0);
  $vbox->pack_start ($hbox, 0, 0, 0);

  my $adjust_splits = $self->{'adjust_splits'}
    = Gtk2::CheckButton->new_with_label (__('Adj splits'));
  $adjust_splits->set_tooltip_text (__('Whether to adjust past prices to the current share capital basis'));
  $hbox->pack_start ($adjust_splits, 0, 0, Gtk2::Ex::Units::em($hbox));

  my $adjust_dividends = $self->{'adjust_dividends'}
    = Gtk2::CheckButton->new_with_label (__('Adj dividends'));
  $adjust_dividends->set_tooltip_text (__('Whether to adjust past prices down for dividends paid out'));
  $adjust_dividends->signal_connect (toggled => \&_do_button_toggled);
  $hbox->pack_start ($adjust_dividends, 0, 0, Gtk2::Ex::Units::em($hbox));

  my $adjust_imputation = $self->{'adjust_imputation'}
    = Gtk2::CheckButton->new_with_label (__('Adj imputation'));
  $adjust_imputation->set_tooltip_text (__('Whether to adjust past prices down for any imputation credits attached to dividends (only applicable when dividend adjustments selected)'));
  $adjust_imputation->signal_connect (toggled => \&_do_button_toggled);
  # only applicable when divs enabled
  Glib::Ex::ConnectProperties->new ([$adjust_dividends,'active'],
                                    [$adjust_imputation,'sensitive']);
  $hbox->pack_start ($adjust_imputation, 0, 0, Gtk2::Ex::Units::em($hbox));

  my $adjust_rollovers = $self->{'adjust_rollovers'}
    = Gtk2::CheckButton->new_with_label (__('Adj rollovers'));
  $adjust_rollovers->set_tooltip_text (__('Whether to adjust past prices up for front month futures contract rollovers'));
  $hbox->pack_start ($adjust_rollovers, 0, 0, Gtk2::Ex::Units::em($hbox));
  $adjust_rollovers->signal_connect (toggled => \&_do_button_toggled);

  my $lower_hbox = Gtk2::HBox->new;
  $vbox->pack_end ($lower_hbox, 0,0,0);
  $vbox->pack_end (Gtk2::HSeparator->new, 0,0,0);

  my $add_graph = $self->{'add_graph'}
    = Gtk2::Button->new_with_label (__('Add Graph'));
  $add_graph->signal_connect (clicked => \&_do_add_graph);
  $lower_hbox->pack_start ($add_graph, 0,0,0);

  $self->set_viewstyle (App::Chart::Gtk2::View::DEFAULT_VIEWSTYLE);
  $vbox->show_all;
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'viewstyle') {
    return $self->get_viewstyle;
  } else {
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'viewstyle') {
    $self->set_viewstyle ($newval);
  } else {
    $self->{$pname} = $newval;
  }
}

sub get_viewstyle {
  my ($self) = @_;
  my $vbox = $self->vbox;
  return { adjust_splits     => $self->{'adjust_splits'}->get_active,
           adjust_dividends  => $self->{'adjust_dividends'}->get_active,
           adjust_imputation => $self->{'adjust_imputation'}->get_active,
           adjust_rollovers  => $self->{'adjust_rollovers'}->get_active,
           graphs => [ map { $_->isa('App::Chart::Gtk2::GraphStyleWidget')
                               ? ($_->get_graphstyle)
                                 : () }
                       $vbox->get_children ]
         };
}

sub set_viewstyle {
  my ($self, $viewstyle) = @_;
  ### ViewStyleDialog set_viewstyle(): $viewstyle

  require Glib::Ex::FreezeNotify;
  my $freezer = Glib::Ex::FreezeNotify->new ($self);

  foreach my $field (qw(adjust_splits adjust_dividends adjust_imputation
                        adjust_rollovers)) {
    $self->{$field}->set_active ($viewstyle->{$field})
  }

  my $vbox = $self->vbox;
  my @graphs = grep {$_->isa('App::Chart::Gtk2::GraphStyleWidget')}
    $vbox->get_children;
  my $graphstyles = ($viewstyle->{'graphs'} ||= []);
  while (@graphs > @$graphstyles) {
    $vbox->remove (pop @graphs);
  }
  foreach my $i (0 .. $#$graphstyles) {
    if (my $graph = $graphs[$i]) {
      $graph->set_graphstyle ($graphstyles->[$i]);
    } else {
      my $graph = $graphs[$i] = App::Chart::Gtk2::GraphStyleWidget->new
        (graphstyle => $graphstyles->[$i]);
      $graph->signal_connect (notify => \&_do_graphstyle_notify);
      $graph->signal_connect (delete_graph => \&_do_graphstyle_delete);
      $vbox->pack_start ($graph, 0,0,
                         0.25 * Gtk2::Ex::Units::line_height($self));
    }
    $graphs[$i]->{'i'} = $i;
  }
  $vbox->show_all;
  $self->notify ('viewstyle');
}

sub _do_button_toggled {
  my ($origin) = @_;
  my $self = $origin->get_ancestor(__PACKAGE__);
  ### ViewStyleDialog _do_button_toggled(): $origin
  $self->notify ('viewstyle');
}

sub _do_response {
  my ($self, $response) = @_;

  if ($response eq RESPONSE_SAVE) {
    $self->save;

  } elsif ($response eq 'ok') {
    $self->save;
    $self->hide;

  } elsif ($response eq 'cancel') {
    $self->hide;

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','View Style'), $self);
  }
}

# 'show' class closure
sub _do_show {
  my ($self) = @_;
  $self->load;
  return shift->signal_chain_from_overridden(@_);
}

sub load {
  my ($self) = @_;
  require App::Chart::Gtk2::View;
  $self->set_viewstyle (App::Chart::Gtk2::View::viewstyle_read());
}
sub save {
  my ($self) = @_;
  require App::Chart::Gtk2::View;
  App::Chart::Gtk2::View::viewstyle_write ($self->get_viewstyle);
}

# 'notify' signal class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  $self->signal_chain_from_overridden ($pspec);

  if ($pspec->get_name eq 'viewstyle') {
    if (my $view = $self->{'view'}) {
      $view->set (viewstyle => $self->get_viewstyle);
    }
  }
}

sub _do_graphstyle_notify {
  my ($graphstylewidget, $pspec) = @_;
  my $self = $graphstylewidget->get_ancestor(__PACKAGE__) || return;
  if ($pspec->get_name eq 'graphstyle') {
    ### ViewStyleDialog _do_graphstyle_notify() change
    $self->notify ('viewstyle');
  }
}

sub _do_add_graph {
  my ($button) = @_;
  my $self = $button->get_ancestor(__PACKAGE__);
  my $viewstyle = $self->get_viewstyle;
  push @{$viewstyle->{'graphs'}}, { size => 1,
                                    indicators => [{ key => 'None' }],
                                  };
  $self->set_viewstyle ($viewstyle);
}

sub _do_graphstyle_delete {
  my ($graphstylewidget) = @_;
  my $self = $graphstylewidget->get_ancestor(__PACKAGE__) || return;
  my $i = $graphstylewidget->{'i'};

  my $viewstyle = $self->get_viewstyle;
  my $graphstyles = $viewstyle->{'graphs'};
  splice @$graphstyles, $i,1;
  $self->set_viewstyle ($viewstyle);
}


package App::Chart::Gtk2::GraphStyleWidget;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::GUI;

use Glib::Object::Subclass
  'Gtk2::VBox',
  properties => [Glib::ParamSpec->scalar
                 ('graphstyle',
                  'graphstyle',
                  'Blurb.',
                  Glib::G_PARAM_READWRITE),
                ],
  signals => { delete_graph => { param_types => [],
                                 return_type => undef,
                                 flags => ['action'] },
             };

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->pack_start (Gtk2::HSeparator->new, 0,0,0);

  my $hbox = $self->{'hbox'} = Gtk2::HBox->new (0, 0);
  $self->pack_start ($hbox, 0,0,0);

  my $label = Gtk2::Label->new (__('Graph') . '  ');
  $hbox->pack_start ($label, 0,0,0);

  my $spin_label = Gtk2::Label->new (__('Size'));
  $hbox->pack_start ($spin_label, 0,0,0);

  my $size_adj = $self->{'size_adj'}
    = Gtk2::Adjustment->new (1,        # initial
                             1, 999,   # min,max
                             1,10,     # steps
                             0);       # page_size
  $size_adj->signal_connect (value_changed => \&_do_size_adj_changed,
                             App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
  my $size_spin = Gtk2::SpinButton->new ($size_adj, 10, 0);
  $size_spin->set_tooltip_text
    (__('The size of this graph, relative to the others'));
  $hbox->pack_start ($size_spin, 0,0,0);

  my $delete_button = Gtk2::Button->new_with_label (__('Delete Graph'));
  $hbox->pack_end ($delete_button, 0,0,0);
  $delete_button->signal_connect (clicked => \&_do_delete_graph);

  my $add_button = Gtk2::Button->new_with_label (__('Add Indicator'));
  $hbox->pack_end ($add_button, 0,0,0);
  $add_button->signal_connect (clicked => \&_do_add_indicator);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'graphstyle') {
    return $self->get_graphstyle;
  } else {
    return $self->{$pname};
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'graphstyle') {
    $self->set_graphstyle ($newval);
  } else {
    $self->{$pname} = $newval;
  }
}

sub get_graphstyle {
  my ($self) = @_;
  my $graphstyle = { size => $self->{'size_adj'}->value,
                     indicators => [ map {$_->get('indicatorstyle')}
                                     $self->indicatorstylewidgets ],
                   };

  my $linestyle = ($self->{'linestylecombo'}
                   && $self->{'linestylecombo'}->get('linestyle'));
  if (defined $linestyle) {
    $graphstyle->{'linestyle'} = $linestyle;
  }
  return $graphstyle;
}

sub set_graphstyle {
  my ($self, $graphstyle) = @_;
  $self->{'size_adj'}->set_value ($graphstyle->{'size'} // 1);

  my $linestyle = $graphstyle->{'linestyle'};
  if (defined $linestyle) {
    require App::Chart::Gtk2::LineStyleComboBox;
    my $linestylecombo = ($self->{'linestylecombo'} ||= do {
      my $combo = App::Chart::Gtk2::LineStyleComboBox->new (visible => 1);
      $combo->signal_connect (changed => \&_do_linestyle_combo_changed);
      my $hbox = $self->{'hbox'};
      $hbox->pack_start ($combo, 0,0, Gtk2::Ex::Units::em($combo));
      $hbox->reorder_child ($combo, 3);
      $combo;
    });
    $linestylecombo->set(linestyle => $linestyle);
  } else {
    delete $self->{'linestylecombo'};
  }

  my $indicators = $graphstyle->{'indicators'};
  my @indicatorwidgets = $self->indicatorstylewidgets;
  while (@indicatorwidgets > @$indicators) {
    $self->remove (pop @indicatorwidgets);
  }
  for (my $i = 0; $i < @$indicators; $i++) {
    my $indicatorstylewidget = $indicatorwidgets[$i] || do {
      my $w = App::Chart::IndicatorStyleWidget->new
        (visible => 1,
         type => (defined $linestyle ? 'average' : 'indicator'));
      $w->signal_connect ('notify::indicatorstyle',
                          \&_do_indicatorstyle_notify, $i);
      $self->pack_start ($w, 0,0,0);
      $w;
    };
    $indicatorstylewidget->set (indicatorstyle => $indicators->[$i])
  }
  ### indicatorstylewidgets: join(' ',$self->indicatorstylewidgets)
}

sub _do_size_adj_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### GraphStyleWidget _do_size_adj_changed()
  $self->notify ('graphstyle');
}

sub _do_linestyle_combo_changed {
  my ($combo) = @_;
  my $self = $combo->get_ancestor (__PACKAGE__);
  ### GraphStyleWidget _do_linestyle_combo_changed(): "$combo"
  $self->notify ('graphstyle');
}

sub _do_add_indicator {
  my ($button) = @_;
  my $self = $button->get_ancestor(__PACKAGE__) || return;
  ### GraphStyleWidget _do_add_indicator()

  my $graphstyle = $self->get_graphstyle;
  push @{$graphstyle->{'indicators'}}, { key     => 'None',
                                         ma_days => 20,
                                       };
  ### GraphStyleWidget _do_add_indicator(): $graphstyle
  $self->set_graphstyle ($graphstyle);
}
sub _do_delete_graph {
  my ($button) = @_;
  my $self = $button->get_ancestor(__PACKAGE__) || return;
  ### GraphStyleWidget _do_delete_graph()
  $self->signal_emit('delete_graph');
}

sub indicatorstylewidgets {
  my ($self) = @_;
  return grep {$_->isa('App::Chart::IndicatorStyleWidget')} $self->get_children;
}

sub _do_indicatorstyle_notify {
  my ($indicatorstylewidget, $pspec, $n) = @_;
  my $self = $indicatorstylewidget->get_ancestor(__PACKAGE__) || return;
  ### GraphStyleWidget _do_indicatorstyle_notify()

  my $graphstyle = $self->get_graphstyle;
  $graphstyle->{'indicators'}->[$n]
    = $indicatorstylewidget->get('indicatorstyle');
  $self->notify ('graphstyle');
}


package App::Chart::IndicatorStyleWidget;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::IndicatorInfo;

use Glib::Object::Subclass
  'Gtk2::VBox',
  properties => [ Glib::ParamSpec->scalar
                  ('indicatorstyle',
                   'indicatorstyle',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('type',
                   'type',
                   'Indicator type either "indicator" or "average".',
                   '',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $hbox = Gtk2::HBox->new;
  $self->pack_start ($hbox, 0,0,0);

  require App::Chart::Gtk2::IndicatorComboBox;
  my $combo = $self->{'combo'} = App::Chart::Gtk2::IndicatorComboBox->new;
  $combo->signal_connect (changed => \&_do_combo_changed);
  $hbox->pack_start ($combo, 0,0,0);

  my $info_button = $self->{'info_button'}
    = Gtk2::Button->new_from_stock ('gtk-info');
  $info_button->signal_connect (clicked => \&_do_info_button);
  $hbox->pack_end ($info_button, 0,0,0);

  #   my $delete_button = $self->{'delete_button'}
  #     = Gtk2::Button->new_from_stock ('gtk-delete');
  #   $delete_button->signal_connect (clicked => \&_do_delete_button);
  #   $hbox->pack_end ($delete_button, 0,0,0);

  my $parambox = $self->{'parambox'} = Gtk2::HBox->new;
  $parambox->show;
  $self->pack_start ($parambox, 0,0,0);
  $parambox->pack_start (Gtk2::Label->new('     '), 0,0,0);

  $hbox->show_all;
  $parambox->show_all;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;

  if ($pname eq 'indicatorstyle') {
    my $indicatorstyle = $newval;
    $self->{'combo'}->set_key ($indicatorstyle->{'key'});
    $self->{'indicatorstyle'} = { %$newval }; # copy

  } elsif ($pname eq 'type') {
    $self->{'combo'}->set (type => $newval);
  }
}

sub _do_info_button {
  my ($info_button) = @_;
  # supposed to be insensitive when no manual, but check just in case
  my $manual = $info_button->{'manual'} || return;
  my $self = $info_button->get_ancestor(__PACKAGE__) || return;
  require App::Chart::Manual;
  App::Chart::Manual->open ($manual, $self);
}
sub _update_info_tooltip {
  my ($self) = @_;
  my $info_button = $self->{'info_button'};
  my $manual = $info_button->{'manual'} = $self->indicator_info->manual;
  $info_button->set_tooltip_text
    ($manual ? __x('Open the manual at the section "{section}"',
                   section => $manual)
     : undef);
  $info_button->set_sensitive ($manual);
}

sub _do_delete_button {
#  my ($delete_button) = @_;
#  my $self = $delete_button->get_ancestor(__PACKAGE__) || return;
  print "Can't delete indicator yet\n";
}

sub _update_params {
  my ($self) = @_;
  my $indicatorstyle = $self->{'indicatorstyle'};
  my $parameter_info = $self->indicator_info->parameter_info;

  my $parambox = $self->{'parambox'};
  my @paramwidgets = $parambox->get_children;
  shift @paramwidgets; # not the spacer
  while (@paramwidgets > @$parameter_info) {
    $parambox->remove (pop @paramwidgets);
  }

  local $self->{'update_in_progress'} = 1;
  for (my $i = 0; $i < @$parameter_info; $i++) {
    my $paramwidget = ($paramwidgets[$i] || do {
      my $pp = App::Chart::IndicatorParamWidget->new (visible => 1);
      $pp->signal_connect ('notify::paramvalue' => \&_do_paramvalue_changed, $i);
      $parambox->pack_start ($pp, 0,0,0);
      $pp;
    });
    my $paramkey = $parameter_info->[$i]->{'key'};
    my $paramvalue = ($indicatorstyle->{$paramkey}
                      // $parameter_info->[$i]->{'default'});
    require Glib::Ex::FreezeNotify;
    my $freezer = Glib::Ex::FreezeNotify->new ($paramwidget);
    $paramwidget->set (paraminfo => $parameter_info->[$i],
                       paramvalue => $paramvalue);
  }
}

# return a App::Chart::IndicatorInfo
sub indicator_info {
  my ($self) = @_;
  my $indicatorstyle = $self->{'indicatorstyle'};
  return App::Chart::IndicatorInfo->new ($indicatorstyle->{'key'});
}

sub _do_combo_changed {
  my ($combo) = @_;
  my $self = $combo->get_ancestor(__PACKAGE__) || return;
  my $indicatorstyle = $self->{'indicatorstyle'};
  $indicatorstyle->{'key'} = $self->{'combo'}->get('key');
  _update_info_tooltip ($self);
  _update_params ($self);
  $self->notify ('indicatorstyle');
}
sub _do_paramvalue_changed {
  my ($paramwidget, $pspec, $n) = @_;
  ### IndicatorStyleWidget _do_paramvalue_changed()
  my $self = $paramwidget->get_ancestor(__PACKAGE__) || return;

  my $parameter_info = $self->indicator_info->parameter_info;
  my $indicatorstyle = $self->{'indicatorstyle'};

  my $param_key = $parameter_info->[$n]->{'key'};
  my $paramvalue = $paramwidget->get('paramvalue');
  if ($paramvalue == $parameter_info->[$n]->{'default'}) {
    delete $indicatorstyle->{$param_key};
  } else {
    $indicatorstyle->{$param_key} = $paramwidget->get('paramvalue');
  }

  ### indicatorstyle: $self->get('indicatorstyle')
  if (! $self->{'update_in_progress'}) {
    $self->notify('indicatorstyle');
  }
}


package App::Chart::IndicatorParamWidget;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use POSIX ();
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::IndicatorInfo;

use Glib::Object::Subclass
  'Gtk2::HBox',
  properties => [ Glib::ParamSpec->scalar
                  ('paraminfo',
                   'paraminfo',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->scalar
                  ('paramvalue',
                   'paramvalue',
                   'Blurb.',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $label = $self->{'label'} = Gtk2::Label->new ('');
  $self->pack_start ($label, 0,0,0);

  my $adj = $self->{'adj'}
    = Gtk2::Adjustment->new (1,        # initial
                             1, 9999,  # min,max
                             1,10,     # steps
                             0);       # page_size
  $adj->signal_connect (value_changed => \&_do_adj_value_changed,
                        App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;
  ### IndicatorParamWidget SET_PROPERTY: $pname, $newval

  if ($pname eq 'paramvalue') {
    my $paraminfo = $self->{'paraminfo'} // return;
    my $type = $paraminfo->{'type'} // 'integer';
    if ($type eq 'boolean') {
      $self->{'child'}->set_active ($newval);
    } else {
      $self->{'child'}->set_value ($newval);
    }

  } elsif ($pname eq 'paraminfo') {
    my $paraminfo = $self->{'paraminfo'};
    if ($paraminfo) {
      if (my $child = delete $self->{'child'}) {
        $self->remove ($child);
      }

      my $type = $paraminfo->{'type'} // 'integer';
      if ($type eq 'boolean') {
        my $check = $self->{'child'} = Gtk2::CheckButton->new;
        $check->signal_connect ('notify::active',
                                \&_do_checkbutton_changed);
        $self->pack_start ($check, 0,0,0);

      } else {
        # 'integer' or 'float'
        my $step = $paraminfo->{'step'} // 1;
        $self->{'adj'}->set
          (lower          => $paraminfo->{'minimum'} // 0,
           upper          => $paraminfo->{'maximum'} // POSIX::FLT_MAX(),
           page_increment => $step,
           step_increment => $step,
           page_size      => 0);
        $self->{'adj'}->changed;

        my $spin = $self->{'child'}
          = Glib::Object::new ('Gtk2::SpinButton',
                               adjustment => $self->{'adj'},
                               climb_rate => $step,
                               digits => ($paraminfo->{'decimals'}
                                          // ($type eq 'float' ? 1 : 0)),
                               xalign => 1.0);
        $self->pack_start ($spin, 0,0,0);
      }
      $self->{'child'}->show;

      $self->{'label'}->set_text ($paraminfo->{'name'} . ' ');
    }
  }
}

sub _do_adj_value_changed {
  my ($adj, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->{'paramvalue'} = $adj->value;
  $self->notify('paramvalue');
}

sub _do_checkbutton_changed {
  my ($check) = @_;
  my $self = $check->get_ancestor(__PACKAGE__) || return;
  $self->{'paramvalue'} = $check->get_active;
  $self->notify('paramvalue');
}


1;
__END__


# =head1 NAME
# 
# App::Chart::Gtk2::ViewStyleDialog -- view style dialog widget
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Gtk2::ViewStyleDialog;
#  my $dialog = App::Chart::Gtk2::ViewStyleDialog->instance;
#  $dialog->present;
# 
# =head1 WIDGET HIERARCHY
# 
# C<App::Chart::Gtk2::ViewStyleDialog> is a subclass of C<Gtk2::Dialog>.
# 
#     Gtk2::Widget
#       Gtk2::Container
#         Gtk2::Bin
#           Gtk2::Window
#             Gtk2::Dialog
#               App::Chart::Gtk2::ViewStyleDialog
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =cut
