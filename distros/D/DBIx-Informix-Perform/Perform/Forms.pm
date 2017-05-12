
package DBIx::Informix::Perform::Forms;

use strict;

use base qw(Curses::Forms);

use Curses;			# for KEY_STAB
use Carp;

#  Altered version of execute to let us move backward.
sub execute {
  my $self = shift;
	my $mwh = shift;
  my $conf = $self->{CONF};
  my @taborder = @{$$conf{TABORDER}};
  my $widgets = $self->{WIDGETS};
  my $subforms = $self->{SUBFORMS};
  my $focused = $$conf{FOCUSED} || $taborder[0] || undef;
  my %taborder = map {($taborder[$_], $_)} (0..$#taborder); # name look-up
  my ($i, $obj, $key, $oderived, $dwh, $cwh);
  $$conf{'REDRAW'} = 0;

  # Create the window if this is not a derived window
  unless ($$conf{DERIVED}) {
    $mwh = $self->_formwin;
    $self->{LEVEL} = 1;

    # Save the old value of DESTORY and temporarily set it to false
    $oderived = $$conf{DERIVED};
    $$conf{DERIVED} = 1;

    # Call ourself again
    $key = $self->execute($mwh);
    $self->_relwin();

    # Restore the DERIVED value and exit
    $$conf{DERIVED} = $oderived;
    $self->{LEVEL} = 0;
    return $key;
  }

  # Take an early exit if there's nothing listed in the tab order
  unless ($#taborder > -1) {
    carp ref($self), ":  Must have a widget to give focus to!";
    return 0;
  }

  # Set the EXIT flag to false
  $$conf{EXIT} = 0;

  # Find the index of the focused widget
  #  $i = 0;
#    until ($i > $#taborder || $focused eq $taborder[$i]) {
#      ++$i;
#    }
#    $i = 0 if $i > $#taborder;
  $i = $taborder{$focused};

  $self->{MWH} = $mwh;
  $dwh = $self->_canvas($mwh, $self->_geometry);
  $self->_init($dwh);
  $cwh = $self->_canvas($dwh, $self->_cgeometry);
  $cwh->keypad(1);
  Curses::define_key("\c[[Z", KEY_STAB); # for some reason not recognized.
  Curses::timeout(250);		# quarter-second wait for ESC sequence.
  Curses::raw();		# catch ctrl-C

  $self->draw($mwh, 1);		# draw form at beginning of execute.

  # Start the loop
  while (1) {

    $obj = exists $$widgets{$taborder[$i]} ?  $$widgets{$taborder[$i]} :
      $$subforms{$taborder[$i]};
    $focused = $$conf{FOCUSED} = $taborder[$i];

    unless (defined $obj) {
      carp ref($self), ":  No such form or widget to focus!";
      return 0;
    }

    # Draw the form if needed
    if ($$conf{REDRAW}){
	$self->draw($mwh, 1);
	$$conf{REDRAW} = 0;
    }

    # Call the OnEnter routine if present
    &{$obj->{OnEnter}}($self) if defined $obj->{OnEnter};
    {
	my $newfocus = $$conf{FOCUSED};
	if ($newfocus ne $focused) {
	    #  Whoa!  Focus warp.  DON'T EXECUTE THE FIELD.
	    $i = $taborder{$newfocus};
	    $focused = $newfocus;
	    next;
	}
    }

    # Execute
    $key = $obj->execute($cwh);
    # $self->draw($mwh);

    # Call the OnExit routine if present
    &{$obj->{OnExit}}($self, $key) if defined $obj->{OnExit};
    $obj->draw($cwh);		# un-cursor it.

    # Exit if specified
    last if $$conf{EXIT};

    {
	my $newfocus = $$conf{FOCUSED};
	if ($newfocus ne $focused) {
	    #  Whoa!  Focus warp.
	    $i = $taborder{$newfocus};
	    $focused = $newfocus;
	}
	# Otherwise, move the focus where appropriate
	elsif (!$$conf{DONTSWITCH}) {
	    $i += $key eq KEY_STAB ? -1 : 1;
	}
    }
    $$conf{DONTSWITCH} = 0;
    $i = 0 if $i > $#taborder;
    $i = $#taborder if $i < 0;

    # Exit if this is the last widget on a subform
    # NOT IN PERFORM, WE DON'T.
    # last if ($$conf{SUBFORM} && $focused eq $taborder[$#taborder]);
  }

  $cwh->delwin;
  $dwh->delwin;

  # Reset the EXIT and DESTROY flags
  $$conf{EXIT} = 0;
  $$conf{FOCUSED} = $taborder[$i];

  return $key;
}

1;
