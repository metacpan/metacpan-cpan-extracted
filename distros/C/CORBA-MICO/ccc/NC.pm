package CORBA::MICO::NC;

#--------------------------------------------------------------------
# Name context browser. Public methods:
#   prepare      - should be called before browser is going to be displayed
#                  this method takes some time forcing some operations
#                  which normaly may be executed in background.
#   widget       - return main NC browser widget
#   do_iteration - do a background iteration.
#   activate     - callback will be called each time objects window
#                  becomes active
#--------------------------------------------------------------------
use Gtk2 '1.140';
use CORBA::MICO;
use CORBA::MICO::NCEntry;
use CORBA::MICO::NCRoot;
use CORBA::MICO::Hypertext;
use CORBA::MICO::Pixtree;
use CORBA::MICO::BGQueue;
use CORBA::MICO::IR;
use CORBA::MICO::Misc qw(status_line_create status_line_write);

use strict;

use constant TREE_TITLE_COLUMN => 0;
use constant TREE_UDATA_COLUMN => 1;

use vars qw($serial $menu_item_IDL $menu_item_iheritance $menu_item_DIA);

use vars qw($DEBUG);
#$DEBUG=1;

#--------------------------------------------------------------------
# Create new NS browser object
# In: $nc         - root name context object
#     $topwindow  - tolevel window
#     $ir_browser - global IR browser object
#     $statusline - status line widget 
#     $bg_sched   - background processing scheduler
#     $menu       - main menu object
#--------------------------------------------------------------------
sub new {
  my ($type, $orb, 
      $nc, $ir_browser, $topwindow, $statusline, $bg_sched, $menu) = @_;
  my $class = ref($type) || $type;
  my $root_nc = new CORBA::MICO::NCRoot($nc);
  my $self = {};
  bless $self, $class;
  $self->init_browser($orb, $root_nc, 
                      $ir_browser, $topwindow, $statusline, $bg_sched, $menu);
  return $self;
}

#--------------------------------------------------------------------
#   prepare: should be called before browser is going to be displayed
#             this method takes some time forcing some operations
#             which normaly may be executed in background.
#--------------------------------------------------------------------
sub prepare {
  my $self = shift;
  if( not $self->{'ROOT_PREPARED'} ) {
    my $ctree = $self->{'CTREE'};
    $self->do_iteration();
    $self->{'ROOT_PREPARED'} = 1;
  }
}

#--------------------------------------------------------------------
#   widget  - return main NC browser widget
#--------------------------------------------------------------------
sub widget {
  my $self = shift;
  return $self->{'WIDGET'};
}

#--------------------------------------------------------------------
# do_iteration - do a background iteration.
# Retrieve NC objects information for nodes and put it to buffered area
# $self->$queue contains nodes having non-processed NC objects
# Return values: TRUE  - keep the object in the background queue
#                FALSE - remove the object from the background queue
#--------------------------------------------------------------------
sub do_iteration {
  my ($self) = @_;

  # process upper level entries first (if any)
  my $ctree = $self->{'CTREE'};
  my $root_ok = $self->{'ROOT_PREPARED'};
  my $status_line = $self->{'SLINE'};
  my $queue = $self->{'BG_QUEUE'};
  if( not $root_ok ) {
    my $root_nc = $self->{'ROOT'};
    my $contents = $root_nc->contents();
    if( $#$contents >= 0 ) {
      create_subtree($ctree, undef, $contents, $queue, $self);
    }
    $self->{'ROOT_PREPARED'} = 1;
    return 1;
  }

  if( $#$queue < 0 ) {
    return 0;
  }
  my $node = shift @$queue;
  unless( defined($node) ) {
    status_line_write($status_line, "NS: Background processing completed");
    return 0;                           # Remove handler if queue is empty
  }
  my $model = $self->{'MODEL'};
  my ($desc, $ud) = $model->get($node, 
                                TREE_TITLE_COLUMN,
                                TREE_UDATA_COLUMN);
  my $contents = $ud->[1];              # NC node children
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
  #my $chname = $child->shname();
  my $chname = $child->name();
  status_line_write($status_line, "NS: $chname...");
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
# Prepare widgets, internal data, start timeout handler
# In: $root_nc   - NCRoot
#     $ir_browser - global IR browser object
#     $topwindow - toplevel widget
#     $sline     - status line widget
#     $bg_sched  - background processing scheduler
#     $menu       - main menu object
#--------------------------------------------------------------------
sub init_browser {
  my ($self, $orb, 
      $root_nc, $ir_browser, $topwindow, $sline, $bg_sched, $menu) = @_;
  # Main vertical box: pane
  my $vbox = new Gtk2::VBox;

  # Menu
  my $menu_id = "NC_$serial"; ++$serial;
  $menu->add_item($menu_id, $menu_item_IDL,
                            undef, \&show_IDL_cb, $self);
  $menu->add_item($menu_id, $menu_item_iheritance,
                            undef, \&show_inheritance_cb, $self);
  $menu->add_item($menu_id, $menu_item_DIA,
                            undef, \&export_to_DIA_cb, $self);

  # Paned window: left-tree, right-text
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
  # and use popup search via CTRL_F/CTRL_R
  $ctree->signal_connect(
                 key_press_event => \&CORBA::MICO::Misc::ctree_kpress, $self);
  # search by regexp
  $ctree->set_search_equal_func(\&CORBA::MICO::Misc::ctree_std_search, $self);
  $scrolled->add($ctree);

  # Paned window: hypertext on the top, IOR on the left
  my $paned1 = new Gtk2::VPaned;
  $paned->add2($paned1);

  # Create text window for IDL-representation of selected items
  my $text = CORBA::MICO::Hypertext::hypertext_create(1);
  $paned1->add($text);

  # Text widget for IOR
  my $ior_widget = Gtk2::TextView->new;
  $ior_widget->set_wrap_mode ('char');
  $ior_widget->set_editable(0);
  $ior_widget->set_cursor_visible(0);

  $paned1->add2($ior_widget);
  $paned1->set_position(400);

  $paned->set_position(200);
  $scrolled->show();
  $paned->show();
  $bg_sched->add_entry($self);
  $ctree->signal_connect('destroy', sub { $bg_sched->remove_entry($self); 1; });
  $selection->signal_connect(changed => \&row_selected, $self);
  $ctree->signal_connect(row_expanded => \&row_expanded, $self);
  $ctree->signal_connect(row_activated => \&row_activated, $self);

  $self->{'ORB'}        = $orb;          # ORB
  $self->{'TOPWINDOW'}  = $topwindow;    # toplevel window
  $self->{'SLINE'}      = $sline;        # status line
  $self->{'TEXT'}       = $text;         # hypertext text widget
  $self->{'MENU'}       = $menu;         # global menu
  $self->{'ID'}         = $menu_id;      # unique ID (for menu items)
  $self->{'ROOT'}       = $root_nc;      # NCRoot
  $self->{'CTREE'}      = $ctree;        # CTree widget
  $self->{'NODE'}       = undef;         # current (selected) row 
  $self->{'MODEL'}      = $model;        # tree model
  $self->{'WIDGET'}     = $vbox;         # main window
  $self->{'IR_BROWSER'} = $ir_browser;   # global IR browser object
  $self->{'IOR_WIDGET'} = $ior_widget;   # widget for IOR
  $self->{'IR_ITEMS'}   = {};            # hash -> IR object name => IR object
  $self->{'BG_QUEUE'}   = [];            # queue for background processing
  $self->{'ROOT_PREPARED'}  = 0;         # root node is not prepared yet
}                         

#--------------------------------------------------------------------
# Call appropriate function to create node description,
# insert corresponding node (with ancestors if any) into CTree
#--------------------------------------------------------------------
sub create_node {
  my($ctree, $parent, $nc_node, $name, $queue, $self) = @_;
  my $contents = $nc_node->contents() || [];
  return add_contents_to_node($ctree, $parent, 
                                $nc_node, $name, [ @$contents ], $queue, $self);
  return undef;
}

#--------------------------------------------------------------------
# Create a node with given NC object desc and contents 
#--------------------------------------------------------------------
sub add_contents_to_node {
  my($ctree, $parent, $nc_node, $desc, $contents, $queue, $self) = @_;
  my $ret;
  if( $#$contents >= 0 ) {
    $ret = add_tree_node($self, $ctree,
                         $parent, $desc, 0, [$nc_node, $contents]); 
    my $first = shift @$contents;
    if( @$contents and defined($ctree) ) {
      # Add node for background processing
      push(@$queue, $ret) if @$contents and defined($ctree);
    }  
    create_node($ctree, $ret, $first, $first->name(), $queue, $self); 
  }
  else {
    # leaf entry
    $ret = add_tree_node($self, $ctree, $parent, $desc, 1, [$nc_node, undef]);
  }
  return $ret;
}

#--------------------------------------------------------------------
# Add nodes for list of children($contents)
#--------------------------------------------------------------------
sub create_subtree {
  my($ctree, $parent, $contents, $queue, $self) = @_;
  foreach my $c (@$contents) {
    create_node($ctree, $parent, $c, $c->name(), $queue, $self);
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
              TREE_TITLE_COLUMN,  $desc,
              TREE_UDATA_COLUMN, $rowdata);
  return $ret;
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
# Signal handler: CTree row selected
# args: $selection, $self
#--------------------------------------------------------------------
sub row_selected {
  my ($selection, $self) = @_;
  my $iter = $selection->get_selected();
  $self->{'NODE'} = $iter;
  $self->mask_menu();
  return unless defined($iter);
  my $model = $self->{'MODEL'};
  my ($desc, $ud) = $model->get($iter,
                                TREE_TITLE_COLUMN,
                                TREE_UDATA_COLUMN);
  my $nc_node = $ud->[0];
  #return unless defined $nc_node;
  my $ior = $self->{'ORB'}->object_to_string($nc_node->nc_node());
 # my $ior = $self->{'ORB'}->object_to_string($nc_node->nc_node()) . "\n\n" .
 #           $nc_node->locurl() . "\n" . $nc_node->url();
  my $ior_widget = $self->{'IOR_WIDGET'};
  my $textbuf = $ior_widget->get_buffer();
  $textbuf->set_text($ior);
}

#--------------------------------------------------------------------
# Signal handler: CTree row unselected
# args: $ctree, $self
#--------------------------------------------------------------------
sub row_unselected {
  my ($ctree, $self) = @_;
  $self->{'NODE'} = undef;
  $self->mask_menu();
  my $ior_widget = $self->{'IOR_WIDGET'};
  $ior_widget->set_point(0);
  $ior_widget->forward_delete($ior_widget->get_length());
  CORBA::MICO::Hypertext::hypertext_show($self->{'TEXT'}, undef);
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
    my $nc_node = $ud->[0];
    create_subtree($ctree, $node, $contents, $queue, $self);
    $ud->[1] = undef;   # mark node as fully constructed
  }
  CORBA::MICO::Misc::cursor_restore_to_default($topwindow, 0);
  $ctree->show();
}

#--------------------------------------------------------------------
# Prepare some internal data for callback and call callback handler
# In: $curs_watch - change cursoe to watch if TRUE
#     $callback   - callback handler, must expect parameters:
#                   $self
#                   $name     - name of NC entry
#                   $nc_node  - NC entry object
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
  my $nc_node = $ud->[0];
  return unless defined $nc_node;
  my $name = $nc_node->name();
  return if $curs_watch and CORBA::MICO::Misc::cursor_watch($topwindow, 1);
  &{$callback}($self, $name, $nc_node, @cb_parms);
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
             my ($self, $name, $nc_node) = @_;
             my $repoid = $nc_node->nc_node()->_repoid();
             print "REF: ", ref($nc_node->nc_node()), "\n";
             #my $iface = $nc_node->nc_node()->_get_interface();
             #print "IFACE: ", ref($iface), "\n";
             #my $deasc = $iface->describe_interface();
             #print "IF ID: $desc->{id}, NAME: $desc->{name}\n";
             #print "IF ID: $iface->{id}, NAME: $iface->{name}\n";
             unless($repoid) {
               status_line_write($self->{'SLINE'}, "** Can't get repoid **");
               sleep(1);
               return;
             }
             $self->{'IR_BROWSER'}->show_IDL_by_id($repoid, $self->{'TEXT'});
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
             my ($self, $name, $nc_node) = @_;
             my $repoid = $nc_node->nc_node()->_repoid();
             $self->{'IR_BROWSER'}->show_inheritance_by_id($repoid,
                                                           $self->{'TEXT'});
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
             my ($self, $name, $nc_node) = @_;
             my $repoid = $nc_node->nc_node()->_repoid();
             $self->{'IR_BROWSER'}->export_to_DIA_by_id($repoid,
                                                        $self->{'TEXT'});
           }
  );
}

#--------------------------------------------------------------------
# Enable/disable menu choices according to type of selected IR object
sub mask_menu {
  my $self = shift; 
  my ($idl_ok, $inher_ok) = (0, 0);
  my $selected_node = $self->{'NODE'};
  my $ctree = $self->{'CTREE'};
  my $model = $self->{'MODEL'};
  my $menu = $self->{'MENU'};
  if( defined($selected_node) ) {
   my ($desc, $ud) = $model->get($selected_node, 
                                 TREE_TITLE_COLUMN,
                                 TREE_UDATA_COLUMN);
    my $nc_node = $ud->[0];
    if( defined($nc_node) ) {
      my $kind = $nc_node->kind();
      if( $kind ne 'ncontext') {
        $inher_ok = 1;
        $idl_ok = 1;
      }
    }
  }
  $menu->mask_item($menu_item_IDL, $idl_ok);
  $menu->mask_item($menu_item_iheritance, $inher_ok);
  $menu->mask_item($menu_item_DIA, $inher_ok);
}

#--------------------------------------------------------------------
sub close {
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
1;
