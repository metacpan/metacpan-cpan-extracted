package CORBA::MICO::CMenu;

use vars qw($serial);
use Carp;

use vars qw($DEBUG);
#$DEBUG=1;

#--------------------------------------------------------------------
# Dynamic menu. Supports a single menu for several 
# objects. Each time an object becomes active
# CMenu automatically rebuilds menu so as it becomes appropriate
# for active object.
#--------------------------------------------------------------------
use Gtk2 '1.140';

#--------------------------------------------------------------------
# Create new menu
# In: $topwindow - toplevel widget
#--------------------------------------------------------------------
sub new {
  my ($type, $topwindow) = @_;
  my $class = ref($type) || $type;
  my $accel_group = new Gtk2::AccelGroup;
  my $menu_name = "<menu_$serial>";
  ++$serial;               
  my $item_factory = new Gtk2::ItemFactory('Gtk2::MenuBar',
                                              $menu_name, $accel_group);
  #$accel_group->attach($topwindow);
  $topwindow->add_accel_group($accel_group);

  my $main_widget = $item_factory->get_widget($menu_name);
  my $self = { 'FACTORY'     => $item_factory,
               'NAME'        => $menu_name,
               'ACCEL_GROUP' => $accel_group,
               'LAST_ACTION' => 0,
               'CURR_ID'     => '',
               'WIDGET'      => $main_widget,
               'ITEMS'       => {} };
  bless $self, $class;
  $self->{'SELFPTR'} = \$self;
  $main_widget->signal_connect('destroy', sub { $self->close(); 1; });
  return $self;
}

#--------------------------------------------------------------------
#   widget  - return main menu widget
#--------------------------------------------------------------------
sub widget {
  my $self = shift;
  return $self->{'WIDGET'};
}

#--------------------------------------------------------------------
# Add a menu item
# In: $id       - ID of object, empty string if item is going to be a global one
#     $path     - name of item (as in GtkItemFactoryEntry)
#     $hotkey   - hotkey (as accelerator in GtkItemFactoryEntry)
#     $callback - callback
#     $cb_data  - callback data
#--------------------------------------------------------------------
sub add_item {
  my($self, $id, $path, $hotkey, $callback, $cb_data) = @_;
  prepare_item($self, $id, $path, $hotkey, 'Item', $callback, $cb_data);
}

#--------------------------------------------------------------------
# Create menu item if it doesn't exist yet
# Return control structure for it
# In: $id       - ID of object, empty string if item is going to be a global one
#     $path     - name of item (as in GtkItemFactoryEntry)
#     $hotkey   - hotkey (as accelerator in GtkItemFactoryEntry)
#     $type     - item type: Item/Branch/LastBranch
#     $callback - callback
#     $cb_data  - callback data
#--------------------------------------------------------------------
sub prepare_item {
  my($self, $id, $path, $hotkey, $type, $callback, $cb_data) = @_;
  my $items = $self->{'ITEMS'};
  my $curr_item;
  if( not exists($items->{$path}) ) {
    $curr_item = { 'TYPE' => $type };
    $items->{$path} = $curr_item;
    my $action = ($type eq 'Item') ? ++$self->{'LAST_ACTION'} : 0;
    $curr_item->{'ACTION'} = $action;
    if( $path =~ m#(^/.*)/[^/]*$# ) {    # dirname
      $self->prepare_item('', $1, undef, 'Branch', undef, undef);
    }  
    my $selfptr = $self->{'SELFPTR'};
    $type = 'LastBranch' if $path =~ m#^/_?Help$#i;
    my $cdata = [$path, $hotkey, undef, $action, "<$type>"];
    if( $type =~ /Item/ ) {
      $cdata->[2] = sub { item_activated_cb($selfptr, $curr_item, @_) };
    }
    $self->{'FACTORY'}->create_item($cdata);
  }
  else {
    $curr_item = $items->{$path};
    if( $curr_item->{'TYPE'} ne $type ) {
      carp "$self->{MENU_NAME}:$path already defined as a $type";
      return undef;
    }
  }
  if( $id and exists($curr_item->{$id}) ) {
    carp "ID $id already defined in menu item $self->{MENU_NAME}:$path";
    return;
  }
  $curr_item->{$id} = [ $callback, $cb_data ];
  return $items;
}

#--------------------------------------------------------------------
# Make unsensitive all menu items except ones having given ID
#--------------------------------------------------------------------
sub activate_id {
  my ($self, $id) = @_;
  my $item_factory = $self->{'FACTORY'};
  my ($key, $items);
  while( ($key, $item) = each %{$self->{'ITEMS'}} ) {
    my $sflag = ($item->{'TYPE'} eq 'Item' and not exists $item->{$id})? 0: 1;
    $self->mask_item($key, $sflag);
  }
  $self->{'CURR_ID'} = $id;
}

#--------------------------------------------------------------------
# make menu item sensitive/unsensitive
# In: $name - item name
#     $flag - TRUE - sensitive, FALSE-unsensitive
#--------------------------------------------------------------------
sub mask_item {
  my ($self, $name, $flag) = @_;
  my $item_factory = $self->{'FACTORY'};
  my $item = $self->{'ITEMS'}->{$name};
  if( not defined($item) ) {
    # carp "No menu item $name";
    return;
  }
  return if exists $item->{''};        # do not mask field if it is global
  my $widget = $item_factory->get_widget_by_action($item->{'ACTION'});
  if( defined($widget) ) {
    $widget->set_sensitive($flag);
  }  
}

#--------------------------------------------------------------------
# Menu callback: item activated
#--------------------------------------------------------------------
sub item_activated_cb {
  my ($selfptr, @args) = @_;
  warn "item_activated_cb" if $DEBUG;
  if( defined($$selfptr) ) {
    $$selfptr->item_activated(@args);
  }  
}

sub item_activated {
  my ($self, $item, $widget, $action) = @_;
  warn "item_activated($self)" if $DEBUG;
  $id = $self->{'CURR_ID'};
  my $cb = $item->{$id};
  if( defined($cb) ) {
    &{$cb->[0]}($cb->[1]);
  }
  elsif( $id ne '' ) {
    # global item: quit, help, etc
    $cb = $item->{''};
    &{$cb->[0]}($cb->[1]) if defined($cb);
  }
}

#--------------------------------------------------------------------
sub close {
  my $self = shift;
  my $selfptr = $self->{'SELFPTR'};
  undef $$selfptr if defined $$selfptr;
  my $items = $self->{'ITEMS'};
  if( defined($items) ) {
    foreach my $k (keys %$items) {
      $items->{$k} = undef;
    }
  }
  foreach my $k (keys %$self) {
    $self->{$k} = undef;
  }
}

#--------------------------------------------------------------------
sub DESTROY {
  my $self = shift;
  warn "DESTROYING $self" if $DEBUG;
}

$serial = 1;
1;
