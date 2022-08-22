package App::InvestSim::GUI;

use 5.022;
use strict;
use warnings;

use App::InvestSim::Config ':all';
use App::InvestSim::Finance;
use App::InvestSim::LiteGUI ':all';
use App::InvestSim::Values ':all';
use CLDR::Number;
use File::Spec::Functions;
use Text::Wrap ();
use Tkx;

# All entry aligned in a column should have the same width (in number of
# characters), for simplicity we are using the same width everywhere.
use constant ENTRY_WIDTH => 10;

my $cldr = CLDR::Number->new(locale => 'fr-FR');
my $cldr_currency = $cldr->currency_formatter(currency_code => 'EUR', maximum_fraction_digits => 0);
my $cldr_percent = $cldr->percent_formatter(minimum_fraction_digits => 1);
my $cldr_decimal = $cldr->decimal_formatter();

sub format_euro {
  my ($val) = @_;
  $val = 0 unless $val;  # Cover the case where $val is undef or '' (also 0).
  return $cldr_currency->format($val);
}

sub format_percent {
  my ($val) = @_;
  $val = 0 unless $val;  # Cover the case where $val is undef or '' (also 0).
  return $cldr_percent->format($val / 100);
}

sub format_year {
  my ($val) = @_;
  $val = 0 unless $val;  # Cover the case where $val is undef or '' (also 0).
  return '1 an' if $val == 1;
  return "${val} ans";
}

sub format_surface {
  my ($val) = @_;
  $val = 0 unless $val;  # Cover the case where $val is undef or '' (also 0).
  return $cldr_decimal->format($val).' m²';
}

# Force-refresh the content of all entry field.
my @all_refresh_actions; # a list of sub-reference to execute
sub refresh_all_fields {
  Tkx::focus('.');
  map { $_->() } @all_refresh_actions;
  calculate_all();
}

# Callback called when one of our validated fields gets the focus.
# widget is the widget itself (the object, not the Tk path), $var is a scalar
# reference to the variable holding the un-decorated value. $right_justified is
# true if the field should be right justified when not edited.
# This replaces the beautified content of the entry, with the raw content for
# editing.
sub focus_in_field {
  my ($widget, $var, $right_justified) = @_;
  $widget->m_delete(0, 'end');
  $widget->m_insert(0, $$var);
  $widget->m_configure(-justify => 'left') if $right_justified;
  $widget->m_configure(-validate => 'key');
}

# Callback called when one of our validated fields lose the focus. Arguments are
# the same as for focus_in_field, with the addition of $refresh which is a method
# called to format the raw value into a better looking string.
# This replaces the raw content of the entry with the beautified text.
sub focus_out_field {
  my ($widget, $var, $right_justified, $refresh) = @_;
  $widget->m_configure(-validate => 'none');
  # Todo: check here that the widget is in a valid state before proceeding.
  $$var = $widget->m_get() =~ s/,/./r;
  $refresh->();
  $widget->m_configure(-justify => 'right') if $right_justified;
  calculate_all();
}

# Receives a ttk_entry widget, a var reference and a field type (euro, percent,
# or year) and setup the entry so that it edits that variable with a beautified
# display corresponding to the type. $textvar can be undef or a scalar
# reference that gets the beautified content of the field.
sub setup_entry {
  my ($widget, $var, $format, $validate, $textvar) = @_;
  my $right_justified = (Tkx::SplitList($widget->m_configure('-justify')))[-1] eq 'right';
  my $refresh = sub {
    $widget->m_delete(0, 'end');
    $widget->m_insert(0, $format->($$var));
    $$textvar = $format->($$var) if $textvar;
  };
  push @all_refresh_actions, $refresh;
  $widget->g_bind("<FocusIn>", sub { focus_in_field($widget, $var, $right_justified) });
  $widget->g_bind("<FocusOut>", sub { focus_out_field($widget, $var, $right_justified, $refresh) });
  # The validation function will receive the new string and the event 'key' or
  # 'forced' (could be 'focusin' or 'focusout' but we don't validate on these
  # event).
  $widget->m_configure(-validate => 'none', -validatecommand => [ sub { $has_changes = 1; $validate->(@_) }, Tkx::Ev('%P', '%V')]);
}

my $currently_selected;
sub set_core_table_selected_state {
  my ($widget) = @_;
  $currently_selected->m_state('!selected') if $currently_selected;
  $currently_selected = $widget;
  $widget->m_state('selected');
}

# Some global variables for some widgets that are accessed by other methods.
my $modes_combobox;
my @core_display_values;
my $display_table;
my $rent_cap_entry;

# Some variables that are linked to widgets, that are set from elsewhere.
my ($total_rent_text, $rent_cap_text, $pinel_worth_text, $notary_fees_text, $total_invested_text);

# How to format the various modes of the drop-down menu.
my @modes_format;

# Add in the given frame in column 0 and 1 a label and an entry text box in the
# given row that is incremented ($row is a ref to a scalar).
sub add_input_entry {
  my ($frame, $row, $key, $text, $format, $tooltip) = @_;
  my (undef, $validate) = @{$values_config{$key}};
  my $var_ref = \$values{$key};
  $frame->new_ttk__label(-text => "${text} :")
    ->g_grid(-column => 0, -row => $$row, -sticky => "e", -padx => "0 2");
  my $e = $frame->new_ttk__entry(-width => ENTRY_WIDTH);
    $e->g_grid(-column => 1, -row => $$row++, -sticky => "we", -pady => 2);
  setup_entry($e, $var_ref, $format, $validate);
  if ($tooltip) {
    local $Text::Wrap::columns = 50;
    $e->g_tooltip__tooltip(Text::Wrap::fill('', '', $tooltip)); 
  }
}

# Build the main window of the app.
sub build {
  my ($res_dir) = @_;
  Tkx::package_require("tooltip");
  Tkx::option_add("*tearOff", 0); # Disable obsolete tear-off menus
  # For how to find existing background style, see: https://tkdocs.com/tutorial/styles.html#insidestyle
  Tkx::ttk__style('map', 'TEntry', -fieldbackground => ['invalid', '#ff0000']);
  Tkx::ttk__style('map', 'TEntry', -fieldbackground => ['readonly', '#eeeeee']);
  Tkx::ttk__style('configure', 'Invalid.TEntry', -foreground => '#ff0000');
  # This style is used for the entry in the main table, to make it clearer that
  # clicking on them has an effect.
  Tkx::ttk__style('map', 'DataTable.TEntry', -foreground => ['selected', '#0000ff']);
  my $root = Tkx::widget->new(".");
  # We start by hiding the root window, we will show it at the end, when all the
  # UI has been built (to avoid an ugly effect where the user sees each control
  # being added quickly to the UI).
  $root->g_wm_withdraw();
  $root->g_wm_resizable(0, 1);  # Disable resizing of the window x.
  # FIXME: Will have to be adapted to work in the PAR package.
  if (Tkx::expr('$tcl_platform(platform)') eq 'windows') {
    $root->g_wm_iconbitmap(catfile($res_dir, 'icon.ico'));
  } else {
    # On Linux, we can’t read .ico files directly.
    my $icon = Tkx::widget->new(Tkx::image_create_photo());
    $icon->read(catfile($res_dir, 'sources', 'icon_32.png'));
    # We could pass several images of different sizes here.
    $root->g_wm_iconphoto($icon);
  }
  
  # We're copying the font used by the TreeView style and adding an 'bold'
  # option to it, it will be used by the 'total' line.
  my $default_treeview_font = Tkx::ttk__style('lookup', 'TreeView', '-font');
  my $treeview_total_font = Tkx::font('create');
  Tkx::font('configure', $treeview_total_font, Tkx::SplitList(Tkx::font('configure', $default_treeview_font)));
  Tkx::font('configure', $treeview_total_font, -weight => 'bold');
  
  # Build the left bar with various parameters.
  {
    my $frame = $root->new_ttk__frame(-padding => 3);
    $frame->g_grid(-column => 0, -row => 0, -rowspan => 3, -sticky => "we");
    
    my $row = 0;
    for my $c (['invested', "Valeur du bien", \&format_euro, "Prix d'achat du bien, hors frais de notaire."],
               ['tax_rate', "Taux d'imposition marginal", \&format_percent],
               ['base_rent', "Loyer brut initial", \&format_euro],
               ['rent_charges', "Charge et gestion locative", \&format_percent],
               ['rent_increase', "revalorisation loyer", \&format_percent],
               ['duration', "Durée d'investissement", \&format_year],
               ['notary_fees', "Frais de notaire", \&format_percent],
               ['loan_insurance', "Assurance décès du prêt", \&format_percent],
               ['other_rate', "Taux de placement autre", \&format_percent],
               ['surface', "Superficie (pondérée)", \&format_surface, "Surface totale habitable, additionnée, le cas échéant, de la moitié des surfaces annexes dans la limite de 8m² (utilisée seulement pour l'application des plafonds 'Pinel')."]) {
      add_input_entry($frame, \$row, @$c);
    }
  }

  # Build the top bar with the loan duration and rate values.
  my @loan_duration_texts;  # Re-used in the core data table.
  {
    my $frame = $root->new_ttk__frame(-padding => 3);
    $frame->g_grid(-column => 1, -row => 0, -sticky => "nwes");
    $frame->g_grid_columnconfigure(0, -weight => 1); 
      
    $frame->new_ttk__label(-text => "Durée d'emprunt (années)")
      ->g_grid(-column => 0, -row => 0, -sticky => "e");
    $frame->new_ttk__label(-text => "Taux d'emprunt")
      ->g_grid(-column => 0, -row => 1, -sticky => "e");
    my $loan_durations = $values{loan_durations};
    my $validate_duration = $values_config{loan_durations}[1];
    my $loan_rates = $values{loan_rates};
    my $validate_rate = $values_config{loan_rates}[1];
    for my $i (0..NUM_LOAN_DURATION-1) {
      my $d = $frame->new_ttk__entry(-width => ENTRY_WIDTH);
      $d->g_grid(-column => $i + 1, -row => 0, -sticky => "we");
      setup_entry($d, \$loan_durations->[$i], \&format_year, $validate_duration, \$loan_duration_texts[$i]);
      my $r = $frame->new_ttk__entry(-width => ENTRY_WIDTH);
      $r->g_grid(-column => $i + 1, -row => 1, -sticky => "we");
      setup_entry($r, \$loan_rates->[$i], \&format_percent, $validate_rate);
    }
  }

  # Build the combo-box with the list of possible values, in its own frame.
  my @modes;
  $modes[MONTHLY_PAYMENT] = "Mensualité de l'emprunt (assurance comprise)";
  $modes_format[MONTHLY_PAYMENT] = \&format_euro;
  $modes[LOAN_COST] = "Cout total de l'emprunt (assurance comprise)";
  $modes_format[LOAN_COST] = \&format_euro;
  $modes[YEARLY_RENT_AFTER_LOAN] = "Revenus locatif net déduit des remboursement, par an";
  $modes_format[YEARLY_RENT_AFTER_LOAN] = \&format_euro;
  $modes[MEAN_BALANCE_LOAN_DURATION] = "Balance mensuelle moyenne de l'opération sur la durée du prêt";
  $modes_format[MEAN_BALANCE_LOAN_DURATION] = \&format_euro;
  $modes[MEAN_BALANCE_OVERALL] = "Balance mensuelle moyenne de l'opération sur la durée de simulation";
  $modes_format[MEAN_BALANCE_OVERALL] = \&format_euro;
  $modes[NET_GAIN] = "Gain Net de l'opération";
  $modes_format[NET_GAIN] = \&format_euro;
  $modes[INVESTMENT_RETURN] = "Rendement de l'opération";
  $modes_format[INVESTMENT_RETURN] = \&format_percent;
  {
    my $frame = $root->new_ttk__frame(-padding => 5);
    $frame->g_grid(-column => 1, -row => 1, -sticky => "nwes");
    $frame->g_grid_columnconfigure(0, -weight => 1); # So that it extends to the whole width.

    $modes_combobox = $frame->new_ttk__combobox(-state => 'readonly', -values => \@modes, -justify => 'center');
    $modes_combobox->g_grid(-column => 0, -row => 0, -sticky => "we");
    $modes_combobox->m_current(MONTHLY_PAYMENT);
    $modes_combobox->g_bind('<<ComboboxSelected>>', \&update_displayed_mode);
  }

  # Build the core table with the computation output.
  {
    my $frame = $root->new_ttk__frame(-padding => 3);
    $frame->g_grid(-column => 1, -row => 2, -sticky => "nwes");
     # So that it extends to the same width as column 0 of the top bar. All other
     # columns have a fixed width that is the same as the matching column in the
     # top bar.
    $frame->g_grid_columnconfigure(0, -weight => 1);

    $frame->new_ttk__label(-text => 'Emprunt \ Durée')
      ->g_grid(-column => 0, -row => 0);
    for my $i (0..NUM_LOAN_DURATION-1) {
      $frame->new_ttk__entry(-width => ENTRY_WIDTH, -textvariable => \$loan_duration_texts[$i], -state => 'readonly', -takefocus => 0)
        ->g_grid(-column => $i + 1, -row => 0, -sticky => "we");
    }
    my $loan_amounts = $values{loan_amounts};
    my $validate_amount = $values_config{loan_amounts}[1];
    for my $j (0..NUM_LOAN_AMOUNT-1) {
      my $w = $frame->new_ttk__entry(-width => ENTRY_WIDTH, -justify => 'right');
      $w->g_grid(-column => 0, -row => $j + 1, -sticky => "we");
      setup_entry($w, \$loan_amounts->[$j], \&format_euro, $validate_amount);
    }
    for my $i (0..NUM_LOAN_DURATION-1) {
      for my $j (0..NUM_LOAN_AMOUNT-1) {
        my $e = $frame->new_ttk__entry(-width => ENTRY_WIDTH, -textvariable => \$core_display_values[$i][$j],
                                       -state => 'readonly', -justify => 'right', -takefocus => 0,
                                       -style => 'DataTable.TEntry');
        $e->g_grid(-column => $i + 1, -row => $j + 1, -sticky => "we");
        $e->g_bind('<FocusIn>', sub { set_core_table_selected_state($e);
                                      update_displayed_table($i, $j) });
      }
    }
  }

  # Build the right bar with some other input values and the output values not 
  # depending on the loan parameters.
  {
    my $frame = $root->new_ttk__frame(-padding => 3);
    $frame->g_grid(-column => 2, -row => 0, -rowspan => 3, -sticky => "we");
    
    my $row = 0;
    
    for my $c (['rent_delay', "Delai de mise en location", \&format_year],
               ['loan_delay', "Durée de franchise de l'emprunt", \&format_year],
               ['application_fees', "Frais de dossier du prêt", \&format_euro],
               ['mortgage_fees', "Frais d'hypothèque", \&format_percent],
               ['social_tax', "CSG + CRDS + Solidarité", \&format_percent]) {
      add_input_entry($frame, \$row, @$c);
    }
    
    # Just some empty white-space between the inputs and the output fields.
    $frame->g_grid_rowconfigure($row++, -minsize => 10);
    
    $frame->new_ttk__label(-text => "Revenus total du loyer (net) :")
      ->g_grid(-column => 0, -row => $row, -sticky => "e", -padx => "0 2");
    $frame->new_ttk__entry(-width => ENTRY_WIDTH, -state => 'readonly', -textvariable => \$total_rent_text, -takefocus => 0)
      ->g_grid(-column => 1, -row => $row++, -sticky => "we", -pady => 2);

    $frame->new_ttk__label(-text => "Plafond du loyer :")
      ->g_grid(-column => 0, -row => $row, -sticky => "e", -padx => "0 2");
    ($rent_cap_entry = $frame->new_ttk__entry(-width => ENTRY_WIDTH, -state => 'readonly', -textvariable => \$rent_cap_text, -takefocus => 0))
      ->g_grid(-column => 1, -row => $row++, -sticky => "we", -pady => 2);

      $frame->new_ttk__label(-text => "Valeur déductible du bien :")
      ->g_grid(-column => 0, -row => $row, -sticky => "e", -padx => "0 2");
    $frame->new_ttk__entry(-width => ENTRY_WIDTH, -state => 'readonly', -textvariable => \$pinel_worth_text, -takefocus => 0)
      ->g_grid(-column => 1, -row => $row++, -sticky => "we", -pady => 2);

    $frame->new_ttk__label(-text => "Frais de notaire :")
      ->g_grid(-column => 0, -row => $row, -sticky => "e", -padx => "0 2");
    $frame->new_ttk__entry(-width => ENTRY_WIDTH, -state => 'readonly', -textvariable => \$notary_fees_text, -takefocus => 0)
      ->g_grid(-column => 1, -row => $row++, -sticky => "we", -pady => 2);

      $frame->new_ttk__label(-text => "Montant total investi :")
      ->g_grid(-column => 0, -row => $row, -sticky => "e", -padx => "0 2");
    $frame->new_ttk__entry(-width => ENTRY_WIDTH, -state => 'readonly', -textvariable => \$total_invested_text, -takefocus => 0)
      ->g_grid(-column => 1, -row => $row++, -sticky => "we", -pady => 2);
  }

  # Build the bottom table.
  $root->g_grid_columnconfigure(1, -weight => 1);
  $root->g_grid_rowconfigure(3, -weight => 1);
  {
    my $frame = $root->new_ttk__frame(-padding => 3, -height => 550);
    $frame->g_grid_propagate(0);
    $frame->g_grid(-column => 0, -row => 3, -columnspan => 3, -sticky => "nwes");
    $frame->g_grid_columnconfigure(0, -weight => 1);
    $frame->g_grid_rowconfigure(0, -weight => 1);
    $display_table = $frame->new_ttk__treeview(-height => ($values{duration} // 20) + 2);
    $display_table->g_grid(-column => 0, -row => 0, -rowspan => 2, -sticky => "nwes");
    
    # We're setting a specific font for items with the tag 'total'.
    $display_table->m_tag('configure', 'total', -font => $treeview_total_font);
    
    #my $hscroll = $frame->new_tk__scrollbar(-orient => "horizontal", -command => [$display_table, "xview"]);
    #$hscroll->g_grid(-column => 0, -row => 1, -sticky => "we");
    my $vscroll = $frame->new_ttk__scrollbar(-orient => "vertical", -command => [$display_table, "yview"]);
    $vscroll->g_grid(-column => 1, -row => 0, -sticky => "ns");
    $frame->new_ttk__sizegrip()->g_grid(-column => 1, -row => 1, -sticky => "se");
    $display_table->configure(-yscrollcommand => [$vscroll, "set"]);
    #$display_table->configure(-xscrollcommand => [$hscroll, "set"]);
    
    my @headings = ('Année', 'Loyer net', 'Placements', 'Principal du prêt', 'Intérêts du prêt', 'Frais du prêt', 'Revenus imposable', 'Déficit déductible', 'Impôt', 'Solde annuel', 'Capital');
    # We're not using the name of the columns (c1, c2, ...) we're only using their
    # index (#0, #1, ...), including #0 the index of the first implicit column.
    $display_table->m_configure(-columns => [map { "c$_" } 1..$#headings ]);
    for my $c (0..$#headings) {
      my $width = Tkx::font_measure(Tkx::ttk__style_lookup('Heading', '-font'), $headings[$c]);
      $display_table->m_heading("#${c}", -text => $headings[$c]);
      $display_table->m_column("#${c}", -width => $width, -anchor => 'e');
    }
  }

  # Finally, we create a small menu.
  {
    my $menu = $root->new_menu;
    $root->configure(-menu => $menu);
    my $file = $menu->new_menu;
    $menu->m_add_cascade(-menu => $file, -label => "Fichier", -underline => 0);
    $file->m_add_command(-label => "Nouveau", -accelerator => 'Ctrl+N', -underline => 0,
                         -command => sub { init_values(); refresh_all_fields() });
    $root->g_bind('<Control-n>', sub { init_values(); refresh_all_fields() });
    $file->m_add_command(-label => "Ouvrir...", -accelerator => 'Ctrl+O', -underline => 0,
                         -command => sub { open_values(); refresh_all_fields() });
    $root->g_bind('<Control-o>', sub { open_values(); refresh_all_fields() });
    $file->m_add_command(-label => "Enregistrer", -accelerator => 'Ctrl+S', -underline => 0, -command => \&save_values);
    $root->g_bind('<Control-s>', \&save_values);
    $file->m_add_command(-label => "Enregistrer sous...", -accelerator => 'Ctrl+Alt+S',  -underline => 12,-command => \&save_values_as);
    $root->g_bind('<Control-Alt-s>', \&save_values_as);
    $file->add_separator();
    $file->m_add_command(-label => "Quitter", -accelerator => 'Alt+F4',  -underline => 0,-command => sub { $root->g_destroy() });
    # The binding for Alt-F4 is automatically supplied by Windows and can't be
    # overriden. It will destroy the window. We catch it as well as the menu entry
    # using the following bind command.
    # If we bind to $root, then the event triggers for all contained widget.
    $root->g_bind('<Destroy>', [sub { autosave() if $_[0] eq '.' }, Tkx::Ev('%W')]);

    my $options = $menu->new_menu;
    $menu->m_add_cascade(-menu => $options, -label => "Options", -underline => 0);
    my $automatic_duration = \$values{automatic_duration};
    $options->m_add_checkbutton(-label => "Durée automatique", -variable => $automatic_duration, -onvalue => 1, -offvalue => 0, -accelerator => 'Ctrl+D');
    $root->g_bind('<Control-d>', sub { $$automatic_duration = 1 - $$automatic_duration });

    my $taxes = $menu->new_menu;
    $menu->m_add_cascade(-menu => $taxes, -label => "Fiscalité", -underline => 1);
    my $pinel_menu = $taxes->new_menu;
    my @pinel_zone = ('Zone A bis', 'Zone A', 'Zone B1', 'Zone B2');
    my $disable_pinel_zone = sub {  
      for my $z (@pinel_zone) {
        $pinel_menu->m_entryconfigure($z, -state => 'disabled');
      }
    };
    my $enable_pinel_zone = sub {
      for my $z (@pinel_zone) {
        $pinel_menu->m_entryconfigure($z, -state => 'normal');
      }
    };
    $taxes->m_add_cascade(-menu => $pinel_menu, -label => "Loi Pinel", -underline => 4);
    my $pinel_duration = \$values{pinel_duration};
    # TODO: test if loading a file with pinel duration 0 results in having the zone disabled correctly.
    $pinel_menu->add_radiobutton(-label => "Non", -variable => $pinel_duration, -value => 0, -command => sub { $disable_pinel_zone->(); calculate_all() });
    $pinel_menu->add_radiobutton(-label => "6 ans", -variable => $pinel_duration, -value => 6, -command => sub { $enable_pinel_zone->(); calculate_all() });
    $pinel_menu->add_radiobutton(-label => "9 ans", -variable => $pinel_duration, -value => 9, -command => sub { $enable_pinel_zone->(); calculate_all() });
    $pinel_menu->add_radiobutton(-label => "12 ans", -variable => $pinel_duration, -value => 12, -command => sub { $enable_pinel_zone->(); calculate_all() });
    $pinel_menu->add_separator();
    
    my $pinel_zone = \$values{pinel_zone};
    for my $i (0..$#pinel_zone) {
      $pinel_menu->add_radiobutton(-label => $pinel_zone[$i], -variable => $pinel_zone,
                                   -value => $i, -command => \&calculate_all);
    }
  }

  # When Return is pressed, we first move the focus, to force a re-computation of
  # the variables holding behind the currently edited field, if any.
  $root->g_bind('<Return>', sub {
      Tkx::focus('.');
      calculate_all();
    });

  # We're done, we can show the UI.
  $root->g_wm_deiconify();
}

# Update the values displayed in the core value table.
my @computed_values; # The output of compute_all()
sub update_displayed_mode {
  my $current_mode = $modes_combobox->m_current();
  $modes_combobox->m_selection('clear');
  my $format = $modes_format[$current_mode];
  for my $i (0..NUM_LOAN_DURATION-1) {
    for my $j (0..NUM_LOAN_AMOUNT-1) {
      $core_display_values[$i][$j] = $format->($computed_values[$i][$j][$current_mode]);
    }
  }
}

sub clear_displayed_table {
  $display_table->m_delete($display_table->m_children(''));
}

# Update the values displayed in the by-year secondary table.
my (@last_update_to_table);
sub update_displayed_table {
  # loan_duration, $loan_amount
  my ($d, $a) = (@_, @last_update_to_table);
  @last_update_to_table = (@_, @last_update_to_table);
  return if @last_update_to_table == 0;  # automatic call before any selection.
  if ($values{automatic_duration} && $values{loan_durations}[$d] != $values{duration}) {
    $values{duration} = $values{loan_durations}[$d];
    refresh_all_fields();
    return; # This method is called back by refresh_all_fields() through calculate_all().
  }
  clear_displayed_table();
  # We don't configure the height of the table unconditionnally because doing so
  # will slightly change the width of the widget for some weird reason. Forcing
  # the width does not work well (and yield some ugly redraw), so we don't do it.
  # All this is unused anyway now that we have verticall scrolling and a set size
  # for the enclosing frame.
  my $current_height = (Tkx::SplitList($display_table->m_configure('-height')))[-1];
  $display_table->m_configure(-height => $values{duration} || 1) if $values{duration} != $current_height;
  my $table = $computed_values[$d][$a][TABLE_DATA];
  for my $i (0..$#$table) {
    my $text = $i ? $i : 'Achat';
    $display_table->m_insert('', 'end', -text => $text, -values => [ map { format_euro($_) } @{$table->[$i]}]);
  }
  $display_table->m_insert('', 'end', -text => 'Total', -tags => 'total',
                           -values => [ (map { format_euro($_) } @{$computed_values[$d][$a][TABLE_TOTAL]}), '']);
}

sub calculate_all {
  if ($values{pinel_duration}) {
    my $rent_cap = App::InvestSim::Finance::pinel_rent_cap();
    $rent_cap_entry->m_configure(-style => ($rent_cap >= $values{base_rent}) ? 'TEntry' : 'Invalid.TEntry');
    $rent_cap_text = format_euro($rent_cap);
    $pinel_worth_text = format_euro(App::InvestSim::Finance::pinel_investment_value());
  } else {
    $rent_cap_text = 'N/A';
    $pinel_worth_text = 'N/A';
  }

  $total_rent_text = format_euro(App::InvestSim::Finance::total_rent());
  $notary_fees_text = format_euro(App::InvestSim::Finance::notary_fees());
  $total_invested_text = format_euro(App::InvestSim::Finance::total_invested());

  my $current_mode = $modes_combobox->m_current();
  $modes_combobox->m_selection('clear');
  for my $i (0..NUM_LOAN_DURATION-1) {
    for my $j (0..NUM_LOAN_AMOUNT-1) {
      $computed_values[$i][$j] = [ App::InvestSim::Finance::calculate($values{loan_amounts}[$j], $values{loan_durations}[$i], $values{loan_rates}[$i]) ];
    }
  }
  update_displayed_table();
  update_displayed_mode();
}

1;
