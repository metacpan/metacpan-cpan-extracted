package CORBA::MICO::IR;

#--------------------------------------------------------------------
# IR browser. Public methods:
#   prepare        - should be called before browser is going to be displayed
#                    this method takes some time forcing some operations
#                    which normaly may be executed in background.
#   widget         - return main IR browser widget
#   do_iteration   - do a background iteration.
#   activate       - callback will be called each time objects window
#                    becomes active
#   show_IDL       - show IDL representation of IR object
#   show_IDL_by_id - show IDL representation of IR object (by repoid)
#   export_to_DIA       - export inheritance for an interface to DIA
#   export_to_DIA_by_id - export inheritance for an interface to DIA (by repoid)
#   show_inheritance       - show inheritance for an interface
#   show_inheritance_by_id - show inheritance for an interface (by repoid)
#--------------------------------------------------------------------
use Gtk2 '1.140';
use CORBA::MICO;
use CORBA::MICO::IREntry;
use CORBA::MICO::IRRoot;
use CORBA::MICO::Hypertext;
use CORBA::MICO::Pixtree;
use CORBA::MICO::IR2Dia;
use CORBA::MICO::BGQueue;
use CORBA::MICO::Misc qw(status_line_create status_line_write);
use Carp;

use strict;

use constant TREE_TITLE_COLUMN => 0;
use constant TREE_UDATA_COLUMN => 1;

use vars qw($serial $menu_item_IDL $menu_item_iheritance $menu_item_DIA
            $menu_item_search $menu_item_search_re $menu_item_expand_all);

use vars qw($DEBUG);
#$DEBUG=1;

#--------------------------------------------------------------------
# Create new IR browser object
# In: $ir_node    - CORBA IR object
#     $topwindow  - tolevel window
#     $statusline - status line widget 
#     $bg_sched   - background processing scheduler
#     $menu       - main menu object
#--------------------------------------------------------------------
sub new {
  my ($type, $ir_node, $topwindow, $statusline, $bg_sched, $menu) = @_;
  my $class = ref($type) || $type;
  my $root_ir = new CORBA::MICO::IRRoot($ir_node);
  my $self = {};
  bless $self, $class;
  $self->init_browser($root_ir, $topwindow, $statusline, $bg_sched, $menu);
  return $self;
}

#--------------------------------------------------------------------
#   prepare: should be called before browser is going to be displayed
#             this method takes some time forcing some operations
#             which normaly may be executed in background.
#--------------------------------------------------------------------
sub prepare {
  my $self = shift;
  my $uppers = $self->{'BG_UPPER'};
  my $ctree = $self->{'CTREE'};
  $ctree->hide();
  while( $#$uppers >= 0 ) {
    $self->do_iteration();
  }
  $ctree->show();
}

#--------------------------------------------------------------------
#   widget  - return main IR browser widget
#--------------------------------------------------------------------
sub widget {
  my $self = shift;
  return $self->{'WIDGET'};
}

#--------------------------------------------------------------------
# do_iteration - do a background iteration.
# Background processing: retrieve IR objects information
# for nodes and put it to buffered area
# $self->$queue contains nodes having non-processed IR objects
# Return values: TRUE  - keep the object in the background queue
#                FALSE - remove the object from the background queue
#--------------------------------------------------------------------
sub do_iteration {
  my ($self) = @_;

  # process upper level entries first (if any)
  my $ctree = $self->{'CTREE'};
  my $uppers = $self->{'BG_UPPER'};
  my $status_line = $self->{'SLINE'};
  my $queue = $self->{'BG_QUEUE'};
  if( $#$uppers >= 0 ) {
    my $entry = shift @$uppers;
    my $ename = shift @$entry;
    my $root_ir = $self->{'ROOT'};
    status_line_write($status_line, "IR:  $ename...");
    my $contents = ir_contents($root_ir, @$entry);
    if( $#$contents >= 0 ) {
      my $node = add_tree_node($self, $ctree, undef, [$ename], 
                               0, [undef, $contents, undef, $self]);
      if( defined($ctree) ) {
        # Add node for background processing
        push(@$queue, $node);
      }
    }
    status_line_write($status_line, "");
    return 1;
  }

  my $node = shift @$queue;
  unless( defined($node) ) {
    status_line_write($status_line, "IR:  Background processing completed");
    return 0;                           # Remove handler if queue is empty
  }
  my $model = $self->{'MODEL'};
  my ($desc, $ud) = $model->get($node, 
                                TREE_TITLE_COLUMN,
                                TREE_UDATA_COLUMN);
  my $contents = $ud->[1];              # IR node children
  return 1 unless defined $contents;    # Do nothing if no children
  if( @$contents == 0 ) {
    $ud->[1] = undef;                   # Array empty -> undef it & do nothing
    return 1;
  }
  my $buffered = $ud->[2];
  if( not defined($buffered) ) {
    $buffered = [];                     # No buffered area yet -> create it
    $ud->[2] = $buffered;
  }
  # process a child
  my $child = shift @$contents;
  my $chname = $child->shname();
  status_line_write($status_line, "IR:  $chname...");
  my $bnode = create_node($ctree, $node, $child, $chname, $queue, $self);
  push(@$queue, $node);                 # Push node to the end of queue
  return 1;
}

#--------------------------------------------------------------------
#   activate     - callback will be called each time objects window
#                  becomes active
#--------------------------------------------------------------------
sub activate {
  my ($self) = @_;
  my $menu = $self->{'MENU'};
  $menu->activate_id($self->{'ID'});
  $self->mask_menu();
}

#--------------------------------------------------------------------
# Show IDL representation of IR object
# In: $name          - name of object
#     $hypertext_obj - object of class CORBA::MICO::Hypertext to be used
#                      to show IDL (undef - use own hypertext object)
#--------------------------------------------------------------------
sub show_IDL {
  my ($self, $name, $hypertext_obj) = @_;
  $hypertext_obj ||= $self->{'TEXT'};
  CORBA::MICO::Hypertext::hypertext_show($hypertext_obj, $name,
                                         \&hypertext_cb, $self, \&htprepost_cb);
}  

#--------------------------------------------------------------------
# Show IDL representation of IR object by repoid
# In: $repoid        - repoid of object
#     $hypertext_obj - object of class CORBA::MICO::Hypertext to be used
#                      to show IDL (undef - use own hypertext object)
#--------------------------------------------------------------------
sub show_IDL_by_id {
  my ($self, $repoid, $hypertext_obj) = @_;
  my $entry = $self->{'ROOT'}->entry_by_id($repoid);
  if( not defined($entry) ) {
    CORBA::MICO::Misc::warning("Can't find interface for $repoid");
  }
  else {
    $self->show_IDL($entry->name(), $hypertext_obj);
  }
}  

#--------------------------------------------------------------------
# Export inheritance tree for an interface to DIA
# In: $name          - name of interface
#     $ir_node       - corresponding IR node object
#--------------------------------------------------------------------
sub export_to_DIA {
  my ($self, $name, $ir_node) = @_;
  if( $ir_node->kind() eq 'dk_Interface' ) {
    export_to_dia($name, [$ir_node]);
  }
  elsif( $ir_node->kind() eq 'dk_Module' ) {
    export_to_dia($name, $ir_node->contents('dk_Interface'));
  }
}

#--------------------------------------------------------------------
# Export inheritance tree for an interface to DIA (by repoid)
# In: $repoid        - repoid of interface
#--------------------------------------------------------------------
sub export_to_DIA_by_id {
  my ($self, $repoid) = @_;
  my $entry = $self->{'ROOT'}->entry_by_id($repoid);
  if( not defined($entry) ) {
    CORBA::MICO::Misc::warning("Can't find interface for $repoid");
  }
  else {
    $self->export_to_DIA($entry->name(), $entry);
  }
}

#--------------------------------------------------------------------
# Show inheritance for an interface
# In: $name          - name of interface
#     $ir_node       - corresponding IR node object
#--------------------------------------------------------------------
sub show_inheritance {
  my ($self, $name, $ir_node) = @_;
  if( $ir_node->kind() eq 'dk_Interface' ) {
    show_interface_tree($name, [$ir_node]);
  }
  elsif( $ir_node->kind() eq 'dk_Module' ) {
    show_interface_tree($name, $ir_node->contents('dk_Interface'));
  }
}

#--------------------------------------------------------------------
# Show inheritance for an interface by repoid
# In: $repoid        - repoid of interface
#--------------------------------------------------------------------
sub show_inheritance_by_id {
  my ($self, $repoid) = @_;
  my $entry = $self->{'ROOT'}->entry_by_id($repoid);
  if( not defined($entry) ) {
    CORBA::MICO::Misc::warning("Can't find interface for $repoid");
  }
  else {
    $self->show_inheritance($entry->name(), $entry);
  }
}

#--------------------------------------------------------------------
# Prepare widgets, internal data, start timeout handler
# In: $root_ir   - IRRoot
#     $topwindow - toplevel widget
#     $sline     - status line widget
#     $bg_sched  - background processing scheduler
#     $menu       - main menu object
#--------------------------------------------------------------------
sub init_browser {
  my ($self, $root_ir, $topwindow, $sline, $bg_sched, $menu) = @_;
  
  # Determine MICO version
  my $ai = $root_ir->entry_by_id('IDL:omg.org/CORBA/AbstractInterfaceDef:1.0');
  my $is_235 = not $ai;

  # Vertical box: pane
  my $vbox = new Gtk2::VBox;

  # Menu
  my $menu_id = "IR_$serial"; ++$serial;
  $menu->add_item($menu_id, $menu_item_IDL,
                            undef, \&show_IDL_cb, $self);
  $menu->add_item($menu_id, $menu_item_iheritance,
                            undef, \&show_inheritance_cb, $self);
  $menu->add_item($menu_id, $menu_item_DIA,
                            undef, \&export_to_DIA_cb, $self);
  $menu->add_item($menu_id, $menu_item_search,
                            '<control>F', \&search_cb, [$self, 0]);
  $menu->add_item($menu_id, $menu_item_search_re,
                            '<control>R', \&search_cb, [$self, 1]);
  $menu->add_item($menu_id, $menu_item_expand_all,
                            undef, \&expand_all_cb, $self);
  # Create paned window: left-tree, right-text
  my $paned = new Gtk2::HPaned;
  $vbox->pack_start($paned, 1, 1, 0);
  $vbox->show_all();

  # Create scrolled window for CTree
  my $scrolled = new Gtk2::ScrolledWindow(undef,undef);
  $scrolled->set_policy( 'automatic', 'automatic' );
  $paned->add($scrolled);

  # Create ctree widget (use Gtk2::TreeView instead of Gtk::CTree)
  my $model = Gtk2::TreeStore->new('Glib::String', 'Glib::Scalar');
  my $ctree = Gtk2::TreeView->new;
  $ctree->set_model($model);
  my $selection = $ctree->get_selection;
  $selection->set_mode ('browse');
  my $cell = Gtk2::CellRendererText->new;
  my $column = Gtk2::TreeViewColumn->new_with_attributes('',
                              $cell, 'text' => TREE_TITLE_COLUMN);
  $ctree->append_column($column);
  # disable incremental search
  $ctree->set_enable_search(0);
  # search by regexp
  $ctree->set_search_equal_func(\&CORBA::MICO::Misc::ctree_std_search, $self);
  # and use popup search via CTRL_F/CTRL_R
  #$ctree->signal_connect(
  #               key_press_event => \&CORBA::MICO::Misc::ctree_kpress, $self);

  $scrolled->add($ctree);

  # Create text window for IDL-representation of selected items
  my $hptext = CORBA::MICO::Hypertext::hypertext_create(1);
  $paned->add2($hptext);

  $paned->set_position(200);
  $scrolled->show();
  $ctree->show();
  $paned->show();
  $bg_sched->add_entry($self);
  $ctree->signal_connect('destroy',
                     sub { $self->close();$bg_sched->remove_entry($self); 1; });
  $selection->signal_connect(changed => \&row_selected, $self);
  $ctree->signal_connect(row_expanded => \&row_expanded, $self);
  $ctree->signal_connect(row_activated => \&row_activated, $self);

  $self->{'TOPWINDOW'} = $topwindow;    # toplevel window
  $self->{'SLINE'}     = $sline;        # status line
  $self->{'TEXT'}      = $hptext;       # hypertext text widget
  $self->{'MENU'}      = $menu;         # global menu
  $self->{'NOIDL'}     = 0;             # global menu
  $self->{'ID'}        = $menu_id;      # unique ID (for menu items)
  $self->{'ROOT'}      = $root_ir;      # IRRoot
  $self->{'CTREE'}     = $ctree;        # CTree widget
  $self->{'NODE'}      = undef;         # current (selected) row 
  $self->{'MODEL'}     = $model;        # tree model
  $self->{'WIDGET'}    = $vbox;         # main window
  $self->{'VER_2_3_5'} = $is_235;       # MICO version 2.3.5 or lower
  $self->{'IR_ITEMS'}  = {};            # hash -> IR object name => IR object
  $self->{'BG_QUEUE'}  = [];            # queue for background processing
  $self->{'BG_UPPER'}  = [              # top items of CTree (for background
      ['Modules',    'dk_Module'],      # processing): [name, type1, type2,...]
      ['Interfaces', 'dk_Interface'],
      ['Values',     'dk_Value'],
      ['Types',      'dk_Struct', 'dk_Union', 'dk_Enum', 'dk_Alias',
                     'dk_String', 'dk_Wstring', 'dk_Fixed',
                     'dk_Sequence', 'dk_Array', 
                     'dk_Typedef', 'dk_Primitive', 'dk_Native', 
                     'dk_Attribute', 'dk_ValueMember'],
      ['Constants',  'dk_Constant']
  ];
}                         

#--------------------------------------------------------------------
# get value of 'any' (translate boolean values to string representation)
#--------------------------------------------------------------------
sub any_value {
  my $any = shift;
  my $kind = tc_unalias($any->type());
  my $retval = $any->value();
  if( $kind eq "tk_boolean" ) {
    $retval = $retval ? "TRUE" : "FALSE";
  }
  elsif ( $kind eq "tk_string" ) {
    $retval = qq("$retval");
  }
  elsif ( $kind eq "tk_wstring" ) {
    $retval = qq(L"$retval");
  }
  return $retval;
}

#--------------------------------------------------------------------
# unalias typecode, return corresponding TCKind
#--------------------------------------------------------------------
sub tc_unalias {
  my $tc = shift; 
  while( $tc->kind() eq "tk_alias" ) {
    $tc = $tc->content_type();
  }
  return $tc->kind();
}

#--------------------------------------------------------------------
# Get full qualified name of IR object
#--------------------------------------------------------------------
sub get_abs_name {        
  my $ir_node = shift;
  my ($ret) = $ir_node->_get_absolute_name() =~ /^\s*:*(.*)/;
  return $ret;
}

#--------------------------------------------------------------------
# tc_name: return string representation of type
#--------------------------------------------------------------------
my %named_types = (
    'tk_objref'	                => 1,
    'tk_struct'	                => 1,
    'tk_union'	                => 1,
    'tk_enum'	                => 1,
    'tk_alias'	                => 1,
    'tk_except'	                => 1,
    'tk_native'	                => 1,
    'tk_abstract_interface'	=> 1,
    'tk_value'	                => 1,
    'tk_value_box'              => 1
);
sub tc_name {
  my ($tc, $items, $root_ir) = @_;
  my $k = $tc->kind();
  if( defined($named_types{$k}) ) {
    # find full-qualified name of user-defined type
    my $repoid = $tc->id();
    if( $repoid ) {
      my $ir_node = $root_ir->entry_by_id($repoid); 
      if( $ir_node ) {
        my $ret = $ir_node->name();
        if( defined($items) ) {
          $items->{$ret} = $ir_node->ir_node();
          $ret = join('', CORBA::MICO::Hypertext::item_prefix, 
                          $ret,
                          CORBA::MICO::Hypertext::item_suffix);
        }
        return $ret;
      }
    }
    return $tc->name();
  }
  $k =~ s/^tk_//;
  if( $k eq "string" or $k eq "wstring") {
    my $l = $tc->length();
    return $l ? "$k <$l>" : $k;
  }
  if( $k eq "sequence" ) {
    my $l = $tc->length();
    my $content = tc_name($tc->content_type(), $items, $root_ir);
    return $l ? "$k <$content,$l>" : "$k <$content>";
  }
  if( $k eq "array" ) {
    my $l = $tc->length();
    my $content = tc_name($tc->content_type(), $items, $root_ir);
    return "$content [$l]";
  }
  if( $k eq "fixed" ) {
    return "$k<" . $tc->fixed_digits() . "," . $tc->fixed_scale() . ">";
  }
  return $k;
}

#--------------------------------------------------------------------
# prm_mode: return string representation of operation parameter mode
#--------------------------------------------------------------------
my %prm_mode_remap = (
    'PARAM_IN'    => 'in',
    'PARAM_OUT'   => 'out',
    'PARAM_INOUT' => 'inout'
);

sub prm_mode {
  my $mode = shift;
  return $prm_mode_remap{$mode};
}

#--------------------------------------------------------------------
# opn_mode: return string representation of operation mode
#--------------------------------------------------------------------
sub opn_mode {
  my $mode = shift;
  return (defined($mode) and $mode eq "OP_ONEWAY") ? "oneway " : "";
}

#--------------------------------------------------------------------
# attr_mode: return string representation of attribute mode
#--------------------------------------------------------------------
sub attr_mode {
  my $mode = shift;
  return (defined($mode) and $mode eq "ATTR_READONLY") ? "readonly " : "";
}

#--------------------------------------------------------------------
# create_list: create a list from array of objects
# 3 arguments:
#  $src_objs: reference to list of objects,
#  $prefix: string will be prepended to return value (if it is not empty)
#  $postfix: string will be appended to return value (if it is not empty)
#  $sep: list separator (", " by default)
#  $callback: function returning description of object (_get_name by default)
#--------------------------------------------------------------------
sub create_list {
  my ($src_objs, $prefix, $postfix, $sep, $callback) = @_;
  $prefix = ""                         if !defined($prefix);
  $postfix = ""                        if !defined($postfix);
  $sep = ", "                          if !defined($sep);
  $callback = sub { $_[0]->_get_name } if !defined($callback);
  my @list;
  foreach my $child (@$src_objs) {
    my $desc = &$callback($child);
    push(@list, $desc) if $desc;
  }
  return @list ? ($prefix . join($sep, @list) . $postfix) : "";
}

#--------------------------------------------------------------------
# IR nodes processing
#--------------------------------------------------------------------
#                kind                 handler      flag: 1-container/0-else
my %ir_nodes = (
              'dk_Exception'   => [\&create_exception,   1],
              'dk_Interface'   => [\&create_interface,   1],
              'dk_Module'      => [\&create_module,      1],
              'dk_Repository'  => [\&create_repository,  1],
              'dk_Struct'      => [\&create_struct,      1],
              'dk_Value'       => [\&create_value,       1],
              'dk_Union'       => [\&create_union,       0],
              'dk_Attribute'   => [\&create_attribute,   0],
              'dk_Constant'    => [\&create_constant,    0],
              'dk_Operation'   => [\&create_operation,   0],
              'dk_Typedef'     => [\&create_typedef,     0],
              'dk_Alias'       => [\&create_alias,       0],
              'dk_Enum'        => [\&create_enum,        0],
              'dk_Primitive'   => [\&create_primitive,   0],
              'dk_String'      => [\&create_string,      0],
              'dk_Sequence'    => [\&create_sequence,    0],
              'dk_Array'       => [\&create_array,       0],
              'dk_Wstring'     => [\&create_wstring,     0],
              'dk_Fixed'       => [\&create_fixed,       0],
              'dk_ValueBox'    => [\&create_valuebox,    0],
              'dk_ValueMember' => [\&create_valuemember, 0],
              'dk_Native'      => [\&create_native,      0],
              'dk_AbstractInterface'   => [\&create_abstract_interface,   1],
              'dk_LocalInterface'      => [\&create_local_interface,      1],
              );

#--------------------------------------------------------------------
# subroutines preparing node descriptions for IR objects
#--------------------------------------------------------------------
sub create_exception {
  my($ir_node, $name, $items, $self) = @_;
  my @retarray = ("exception $name");
  my $members = $ir_node->_get_members();
  my $tail = defined($items) ? ";" : "";
  my $root_ir = $self->{'ROOT'};
  for my $member (@$members) {
    push(@retarray, tc_name($member->{"type"}, 
                            $items, $root_ir) . " $member->{name}" . $tail);
  }
  return \@retarray;
}

#--------------------------------------------------------------------
sub create_interface {
  my($ir_node, $name, $items, $self) = @_;
  my $is_abstract = $self->{'VER_2_3_5'} && $ir_node->_get_is_abstract();
  create_any_interface($ir_node, $name, $items, $self, $is_abstract);
}

#--------------------------------------------------------------------
sub create_abstract_interface {
  my($ir_node, $name, $items, $self) = @_;
  create_any_interface($ir_node, $name, $items, $self, 1);
}

#--------------------------------------------------------------------
sub create_local_interface {
  my($ir_node, $name, $items, $self) = @_;
  create_any_interface($ir_node, $name, $items, $self, 0, 1);
}

#--------------------------------------------------------------------
sub create_any_interface {
  my($ir_node, $name, $items, $self, $is_abstract, $is_local) = @_;
  my $ret = '';
  $ret = 'abstract ' if $is_abstract;
  $ret = 'local ' if $is_local;
  #$ret .= "interface $name";
  $ret .= "interface " . $ir_node->_get_name();
  my $parents = $ir_node->_get_base_interfaces();
  if( defined($items) ) {
    my @inames;
    foreach my $itf (@$parents) {
      my $aname = $itf->_get_absolute_name();
      $items->{$aname} = $itf;
      push(@inames, CORBA::MICO::Hypertext::item_prefix . $aname . CORBA::MICO::Hypertext::item_suffix);
    }
    $ret .= (': ' . join(', ', @inames)) if $#$parents >= 0;
    my $contents = $ir_node->contents("dk_all", 1);
    $ret .= ' {};' unless @$contents;
  }
  else {
    $ret .= create_list($parents, ": ");
  }
  return [$ret];
}

#--------------------------------------------------------------------
sub mk_if_tree {
  my $ir_node = shift;
  my $parents = $ir_node->parents();
  my @if_tree = ();
  my $i = 0;
  foreach my $p (@$parents) {
    $if_tree[$i][0] = $p->name();
    $if_tree[$i][1] = mk_if_tree($p);
    $i++;
  }
  return \@if_tree; 
}

#--------------------------------------------------------------------
sub create_module {
  my($ir_node, $name) = @_;
  return ["module $name"];
}

#--------------------------------------------------------------------
sub create_repository {
  my($ir_node, $name) = @_;
  return ["Repository $name"];
}

#--------------------------------------------------------------------
sub create_struct {
  my($ir_node, $name, $items, $self) = @_;
  my @retarray = ("struct $name");
  my $members = $ir_node->_get_members();
  my $tail = defined($items) ? ";" : "";
  my $root_ir = $self->{'ROOT'};
  for my $member (@$members) {
    push(@retarray, 
     tc_name($member->{"type"}, $items, $root_ir) . " $member->{name}" . $tail);
  }
  return \@retarray;
}

#--------------------------------------------------------------------
sub create_value {
  my($ir_node, $name, $items, $self) = @_;
  my $ret = "";
  $ret .= "abstract " if( $ir_node->_get_is_abstract() );
  $ret .= "custom "   if( $ir_node->_get_is_custom() );
  $ret .= "valuetype $name";

  # prepare list of parents
  my $prefix .= ": ";
  $prefix .= "trancatable " if $ir_node->_get_is_truncatable();
  my $base = $ir_node->_get_base_value();
  $ret .= "$prefix $base " if defined($base);
  $ret .= create_list($ir_node->_get_abstract_base_values(), 
                                                    $base ? ", " : $prefix);
  $ret .= create_list($ir_node->_get_supported_interfaces(), " supports ");
  my @retarray = ($ret);
  my $tail = defined($items) ? ";" : "";
  my $inits = $ir_node->_get_initializers();
  my $root_ir = $self->{'ROOT'};
  foreach my $i (@$inits) {
    # create factory desc: 'factory <name> (in <param_type> param_name, ...)'
    my $fact = create_list(
         $i->{"members"},                         # objects
         "",                                      # prefix
         "",                                      # postfix
         ", ",                                    # separator
         sub {          
         "in " .  tc_name($_[0]->{"type"}, $items, $root_ir) . " $_[0]->{name}";
         }                                        # callback
       );
    push(@retarray, "factory $i->{name}(" . $fact . ")" . $tail);
  }
  if( $items and @retarray == 1 ) {
    my $contents = $ir_node->contents("dk_all", 1);
    $retarray[0] .= ' {};' unless @$contents;
  }
  return \@retarray;
}

#--------------------------------------------------------------------
sub create_union {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $dtype = tc_name($ir_node->_get_discriminator_type(), $items, $root_ir);
  my @retarray = ("union $name switch($dtype)");
  my $tail = defined($items) ? ";" : "";
  my $members = $ir_node->_get_members();
  for my $member (@$members) {
    my $type = $member->{"type"};
    my $val = any_value($member->{"label"});
    my $alt;
    if( $member->{"label"}->type()->kind() eq "tk_octet" and $val == 0 ) {
      $alt = "default: " .  
              tc_name($type, $items, $root_ir) . " $member->{name}$tail";
    }
    else {
      $alt = "case $val: " . 
              tc_name($type, $items, $root_ir) . " $member->{name}$tail";
    }
    push(@retarray, $alt);
  }
  return \@retarray;
}

#--------------------------------------------------------------------
sub create_attribute {
  my($ir_node, $name, $items, $self) = @_;
  my $tail = defined($items) ? ";" : "";
  my $root_ir = $self->{'ROOT'};
  return [  attr_mode($ir_node->_get_mode)
          . "attribute "
          . tc_name($ir_node->_get_type(), $items, $root_ir) . " $name$tail"];
}

#--------------------------------------------------------------------
sub create_constant {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $tail = defined($items) ? ";" : "";
  return ["const " . tc_name($ir_node->_get_type(), $items, $root_ir) .
          " $name = " .  any_value($ir_node->_get_value()) . $tail];
}

#--------------------------------------------------------------------
sub create_operation {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $tail = defined($items) ? ";" : "";
  my $res = opn_mode($ir_node->_get_mode())           # operation mode
          . tc_name($ir_node->_get_result(),
                    $items, $root_ir)                 # result type
          . " $name(";                                # opertion name

  # create list of params: 'in <param_type> <param_name>, ...'
  my $list = create_list(
       $ir_node->_get_params(),                 # objects
       "",                                      # prefix
       "",                                      # postfix
       ", ",                                    # separator
       sub {          
             prm_mode($_[0]->{"mode"}) . " " .
             tc_name($_[0]->{"type"}, $items, $root_ir) .
             " $_[0]->{name}";
       }                                        # callback
     );
  $res .= $list . ")";

  # create list of exceptions 'raises( <name>, ... )'
  $res .= create_list(
                      $ir_node->_get_exceptions(),                  # objects
                      " raises(",                                   # prefix
                      ")",                                          # postfix
                      ", ",                                         # separator
                      sub { tc_name($_[0]->_get_type(),
                                    $items, $root_ir); }            # callback
                     );
  # create context list 'context( <name>, ... )'
  $res .= create_list(
                      $ir_node->_get_contexts(),               # objects
                      " context(",                             # prefix
                      ")",                                     # postfix
                      ", ",                                    # separator
                      sub { "\"$_[0]\""; }                     # callback
                     );
  return [$res . $tail];
}

#--------------------------------------------------------------------
sub create_typedef {
  my($ir_node, $name, $items) = @_;
  return ["Typedef $name"];
}

#--------------------------------------------------------------------
sub create_alias {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $tail = defined($items) ? ";" : "";
  return [  "typedef "
          . tc_name($ir_node->_get_original_type_def()->_get_type(),
                                                       $items, $root_ir) 
          . " $name$tail"];
}

#--------------------------------------------------------------------
sub create_enum {
  my($ir_node, $name, $items) = @_;
  my $members = $ir_node->_get_members();
  return ["enum $name", @$members] unless defined($items);
  my @retval = ("enum $name");
  foreach my $m (@$members) {
    push(@retval, $m . ",");
  }
  return \@retval;
}

#--------------------------------------------------------------------
sub create_primitive {
  my($ir_node, $name, $items) = @_;
  return ["primitive $name"];
}

#--------------------------------------------------------------------
sub create_string {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  return [tc_name($ir_node->_get_type(), $items, $root_ir) . " $name"];
}

#--------------------------------------------------------------------
sub create_sequence {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  return [tc_name($ir_node->_get_type(), $items, $root_ir) . " $name"];
}

#--------------------------------------------------------------------
sub create_array {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  return [tc_name($ir_node->_get_type(), $items, $root_ir) . " $name"];
}

#--------------------------------------------------------------------
sub create_wstring {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  return [tc_name($ir_node->_get_type(), $items, $root_ir) . " $name"];
}

#--------------------------------------------------------------------
sub create_fixed {
  my($ir_node, $name, $items, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  return [tc_name($ir_node->_get_type(), $items, $root_ir) . " $name"];
}

#--------------------------------------------------------------------
sub create_valuebox {
  my($ir_node, $name, $items, $self) = @_;
  my $tail = defined($items) ? ";" : "";
  my $root_ir = $self->{'ROOT'};
  return [  "valuetype $name " 
          . tc_name($ir_node->_get_original_type_def()->_get_type(),
                                                        $items, $root_ir) 
          . $tail];
}

#--------------------------------------------------------------------
sub create_valuemember {
  my($ir_node, $name, $items, $self) = @_;
  my $tail = defined($items) ? ";" : "";
  my $vis = ($ir_node->_get_access() == CORBA::PUBLIC_MEMBER()) 
                                               ? "public" : "private";
  my $root_ir = $self->{'ROOT'};
  return ["$vis " . 
          tc_name($ir_node->_get_type(), $items, $root_ir) . " $name$tail"];
}

#--------------------------------------------------------------------
sub create_native {
  my($ir_node, $name, $items) = @_;
  my $tail = defined($items) ? ";" : "";
  return ["native $name$tail"];
}

#--------------------------------------------------------------------
# Call appropriate function to create node description,
# insert corresponding node (with ancestors if any) into CTree
#--------------------------------------------------------------------
sub create_node {
  my($ctree, $parent, $ir_node, $name, $queue, $self) = @_;
#  return undef if $skip_names and $ir_node->repoid() =~ /$skip_names/;
  my $entry = $ir_nodes{ $ir_node->kind() };
  if( defined($entry) ) {
    my $desc = &{$entry->[0]}($ir_node->ir_node(), $name, undef, $self);
    my $contents = $ir_node->contents("dk_all") || [];
    return add_contents_to_node($ctree, $parent, 
                                $ir_node, $desc, [ @$contents ], $queue, $self);
  }
  return undef;
}

#--------------------------------------------------------------------
# Create a node with given IR object desc and contents 
#--------------------------------------------------------------------
sub add_contents_to_node {
  my($ctree, $parent, $ir_node, $desc, $contents, $queue, $self) = @_;
  my $ret;
  #$contents = [ @$contents ];   # make a copy
  if( $#$contents >= 0 ) {
    $ret = add_tree_node($self, $ctree,
                         $parent, $desc, 0, [$ir_node, $contents]); 
    my $first = shift @$contents;
    if( @$contents and defined($ctree) ) {
      # Add node for background processing
      push(@$queue, $ret) if @$contents and defined($ctree);
    }  
    create_node($ctree, $ret, $first, $first->shname(), $queue, $self); 
  }
  else {
    # not container  
    $ret = add_tree_node($self, $ctree, $parent, $desc, 1, [$ir_node, undef]);
  }
  return $ret;
}

#--------------------------------------------------------------------
# Add nodes for list of children($contents)
#--------------------------------------------------------------------
sub create_subtree {
  my($ctree, $parent, $contents, $queue, $self) = @_;
  foreach my $c (@$contents) {
    create_node($ctree, $parent, $c, $c->shname(), $queue, $self);
  }
}

#--------------------------------------------------------------------
# insert into CTree a node with given description & descriptions of children
# desc is a list of descriptions:
#    desc[0]   - description of node
#    desc[1..] - descriptions of children
# Arguments:
#    ctree, parent - ctree & parent node
#    desc - descriptions (see above)
#    is_leaf - TRUE if a node is a leaf, false else
#    rowdata - raw data to be attached to the node
sub add_tree_node {
  my($self, $ctree, $parent, $desc, $is_leaf, $rowdata) = @_;
  $is_leaf = 0 if $#$desc >= 1;
  if( not defined($ctree) ) {
    # Add to buffered area - not really to Ctree
    my %node = ( 'DESC'     => $desc,
                 'IS_LEAF'  => $is_leaf,
                 'DATA'     => $rowdata,
                 'CHILDREN' => [] );
    push(@{$parent->{'CHILDREN'}}, \%node) if defined($parent);
    return \%node;
  }
  # ctree defined -> add directly to the tree
  my $model = $self->{MODEL};
  my $ret = $model->append($parent);
  $model->set($ret,
              TREE_TITLE_COLUMN,  $desc->[0],
              TREE_UDATA_COLUMN, $rowdata);
  shift @$desc;
  foreach my $d (@$desc) {
    add_tree_node($self, $ctree, $ret, [$d], 1);
  }
  return $ret;
}

#--------------------------------------------------------------------
# Signal handler: CTree row selected
# args: $selection, $self
#--------------------------------------------------------------------
sub row_selected {
  my ($selection, $self) = @_;

  my $iter = $selection->get_selected();
  $self->{'NODE'} = $iter;
  $self->mask_menu();
}

#--------------------------------------------------------------------
# Signal handler: CTree row activated: just show IDL
# args: $ctree, $iter, $path, $column, $self
#--------------------------------------------------------------------
sub row_activated {
  my ($ctree, $path, $column, $self) = @_;
  show_IDL_cb($self);
}

#--------------------------------------------------------------------
# Signal handler: CTree row is to be expanded
# args: $ctree, $iter, $path, $self
#--------------------------------------------------------------------
sub row_expanded {
  my ($ctree, $iter, $path, $self) = @_;
  return expand_row($self, $iter);
}

#--------------------------------------------------------------------
# Insert buffered nodes directly to the CTree
#--------------------------------------------------------------------
sub insert_buffered {
  my ($self, $ctree, $parent, $buffered) = @_;
  my $node = add_tree_node($self, $ctree, $parent, 
                           $buffered->{'DESC'},
                           $buffered->{'IS_LEAF'},
                           $buffered->{'DATA'});
  foreach my $bchild (@{$buffered->{'CHILDREN'}}) {
    insert_buffered($self, $ctree, $node, $bchild);
  }
}

#--------------------------------------------------------------------
# Insert corresponding subnodes to a node if there are some ones
# not inserted yet
#--------------------------------------------------------------------
sub expand_row {
  my ($self, $node) = @_;
  my $ctree = $self->{'CTREE'};
  my $queue = $self->{'BG_QUEUE'};
  my $topwindow = $self->{'TOPWINDOW'};
  my $model = $self->{'MODEL'};
  my ($desc, $ud) = $model->get($node,
                                TREE_TITLE_COLUMN,
                                TREE_UDATA_COLUMN);
  my $contents = $ud->[1];
  my $buffered = $ud->[2];
  return 1 unless defined($contents) or defined($buffered);
  return 1 if CORBA::MICO::Misc::cursor_watch($topwindow, 1);
  $ctree->hide();
  if( defined($buffered) ) {
    # insert buffered subnodes (if any)
    foreach my $b (@$buffered) {
      insert_buffered($self, $ctree, $node, $b);
    }
    $ud->[2] = undef;
  }
  if( defined($contents) ) {
    # insert new (unbuffered) subnodes (if any) into CTree
    my $ir_node = $ud->[0];
    create_subtree($ctree, $node, $contents, $queue, $self);
    $ud->[1] = undef;   # mark node as fully constructed
  }
  CORBA::MICO::Misc::cursor_restore_to_default($topwindow, 0);
  $ctree->show();
}

#--------------------------------------------------------------------
# Hypertext handler
# args: item_name, %ir_items
# Returns a list of lines to be shown
sub hypertext_cb {
  my ($name, $self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $items = $self->{'IR_ITEMS'};
  my $ir_node = $root_ir->entry($name);
  my @retval = ("#pragma ID $name \"" . $ir_node->repoid() . '"');
  push(@retval, @{prepare_text($self, $ir_node, $name, $items)});
  return \@retval;
}

#--------------------------------------------------------------------
# Prepare a human-readable representation of IR object to be
# shown in right side text window
#--------------------------------------------------------------------
sub prepare_text {
  my($self, $ir_node, $name, $items) = @_;
  my $entry = $ir_nodes{ $ir_node->kind() };
  return undef unless defined($entry);
  my $desc = &{$entry->[0]}($ir_node->ir_node(), $name, $items, $self);
  if( $entry->[1] ) {
#     container  
    my $contents = $ir_node->contents("dk_all");
    if( $#$contents >= 0 ) {
      foreach my $c (@$contents) {
        my $child_desc = prepare_text($self, $c, $c->shname(), $items);
        push(@$desc, @$child_desc);
      }
    }
  }
  if( @$desc > 1 ) {
    # post-process compound IR object
    $desc->[0] .= " {";
    for( my $i = 1; $i < @$desc; ++$i ) {
      $desc->[$i] =~ s/^/  /;
    }
    push( @$desc, "};" );
  }
  return $desc;
}

#--------------------------------------------------------------------
# Show interface inheritance tree via CORBA::MICO::Pixtree
#--------------------------------------------------------------------
sub show_interface_tree {
  my ($name, $nodes) = @_;
  return unless @$nodes;
  my $dialog = new Gtk2::Window('toplevel');
  $dialog->set_default_size(400, 200);
  $dialog->set_position('mouse');
  my $pixtree = CORBA::MICO::Pixtree::pixtree_create();
  CORBA::MICO::Pixtree::pixtree_show($pixtree, $nodes);
  $dialog->set_title($name);
  $dialog->add($pixtree->[0]);
  $dialog->show_all();
  $dialog->realize();
}

#--------------------------------------------------------------------
# Export interface inheritance tree to DIA
#--------------------------------------------------------------------
sub export_to_dia {
  my ($name, $nodes) = @_;
  return unless @$nodes;
  my ($fname) = $name =~ /.*:(.*)/;
  CORBA::MICO::Misc::select_file("Export $name to DIA",
                   "${fname}.xml", 0,
                   sub { CORBA::MICO::IR2Dia::dump_interface($_[0], $nodes) } );
}

#--------------------------------------------------------------------
# Get contained objects.
# Args: $ir_node - IRRoot object
#       (types)  - types of 'Contained' objects should be retrieved
#--------------------------------------------------------------------
sub ir_contents {
  my $ir_node = shift;
  my @retval = ();
  foreach my $type (@_) {
    my $contents = $ir_node->contents($type, 1);
    push (@retval, @$contents);
  }
  return \@retval;
}

#--------------------------------------------------------------------
# Prepare some internal data for callback and call callback handler
# In: $curs_watch - change cursoe to watch if TRUE
#     $callback   - callback handler, must expect parameters:
#                   $self
#                   $name     - name of IR entry
#                   $ir_node  - IR entry object
#                   @cb_parms - the rest of our parameters
#     @cb_parms   - additional parameters will be passed to callback handler
#--------------------------------------------------------------------
sub call_menu_callback {
  my ($self, $curs_watch, $callback, @cb_parms) = @_;
  my $ctree = $self->{'CTREE'};
  my $topwindow = $self->{'TOPWINDOW'};
  my $selected_node = $self->{'NODE'};
  return unless defined($selected_node);
  my $model = $self->{'MODEL'};
  my ($desc, $ud) = $model->get($selected_node,
                                TREE_TITLE_COLUMN,
                                TREE_UDATA_COLUMN);
  my $ir_node = $ud->[0];
  return unless defined $ir_node;
  my $name = $ir_node->name();
  $self->{'IR_ITEMS'}->{$name} = $ir_node;
  return if $curs_watch and CORBA::MICO::Misc::cursor_watch($topwindow, 1);
  &{$callback}($self, $name, $ir_node, @cb_parms);
  $curs_watch and CORBA::MICO::Misc::cursor_restore_to_default($topwindow, 0);
}

#--------------------------------------------------------------------
# Menu item activated: show IDL
#--------------------------------------------------------------------
sub show_IDL_cb {
  my $self = shift;
  $self->call_menu_callback(
           1,           # cursor watch
           sub {        # show IDL
             my ($self, $name) = @_;
             $self->show_IDL($name);
           }
  );
}

#--------------------------------------------------------------------
# Menu item activated: show tree of inheritance
#--------------------------------------------------------------------
sub show_inheritance_cb {
  my $self = shift;
  $self->call_menu_callback(
           1,           # cursor watch
           sub {        # show inheritance
             my ($self, $name, $ir_node) = @_;
             $self->show_inheritance($name, $ir_node);
           }
  );
}

#--------------------------------------------------------------------
# Menu item activated: export tree of inheritance to DIA
#--------------------------------------------------------------------
sub export_to_DIA_cb {
  my $self = shift;
  $self->call_menu_callback(
           0,           # no cursor watch
           sub {        # export tree of inheritance to DIA
             my ($self, $name, $ir_node) = @_;
             $self->export_to_DIA($name, $ir_node);
           }
  );
}

#--------------------------------------------------------------------
# Menu item activated: expand all
#--------------------------------------------------------------------
sub expand_all_cb {
  my $self = shift;
  $self->{CTREE}->expand_all();
}

#--------------------------------------------------------------------
# Menu item activated: find/find regexp
#--------------------------------------------------------------------
sub search_cb {
  my $ud = shift;
  my ($self, $is_regexp) = @$ud;
  $self->{REGEXP} = $is_regexp;

  if( $self->{CTREE}->has_focus() ) {
    $self->{CTREE}->signal_emit('start_interactive_search');
  }
  else {
    CORBA::MICO::Hypertext::do_search($self->{TEXT}, $is_regexp);
  }
}

#--------------------------------------------------------------------
# Pre/post callback for hypertext
sub htprepost_cb {
  my ($self, $pre) = @_;
  $self->{NOIDL} = $pre;
  mask_menu($self);
}

#--------------------------------------------------------------------
# Enable/disable menu choices according to type of selected IR object
sub mask_menu {
  my $self = shift; 
  my ($idl_ok, $inher_ok) = (0, 0);
  my $selected_node = $self->{'NODE'};
  my $model = $self->{'MODEL'};
  my $menu = $self->{'MENU'};
  if( defined($selected_node) ) {
   my ($desc, $ud) = $model->get($selected_node, 
                                 TREE_TITLE_COLUMN,
                                 TREE_UDATA_COLUMN);
    my $ir_node = $ud->[0];
    if( defined($ir_node) ) {
      $idl_ok = !$self->{NOIDL};
      my $kind = $ir_node->kind();
      if( $kind eq 'dk_Interface' or $kind eq 'dk_Module') {
        $inher_ok = 1;
      }
    }
  }
  $menu->mask_item($menu_item_IDL, $idl_ok);
  $menu->mask_item($menu_item_iheritance, $inher_ok);
  $menu->mask_item($menu_item_DIA, $inher_ok);
}

#--------------------------------------------------------------------
sub close {
  warn "IR::close()" if $DEBUG;
  my $self = shift;
  foreach my $k (keys %$self) {
    $self->{$k} = undef;
  }
}

#--------------------------------------------------------------------
sub DESTROY {
  my $self = shift;
  warn "DESTROYING $self" if $DEBUG;
}

$serial = 0;
$menu_item_IDL = '/Selected/_IDL';
$menu_item_iheritance = '/Selected/I_nheritance';
$menu_item_DIA = '/Selected/_Export to DIA';
$menu_item_expand_all = '/View/Expand all';
$menu_item_search = '/View/Find';
$menu_item_search_re = '/View/Find regexp';
1;
