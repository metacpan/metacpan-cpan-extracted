# Brenton Chapin
package DBIx::Perform::Forms;

use strict;

use base qw(Curses::Forms);

use Curses;			# for KEY_STAB
use Carp;

our $VERSION = '0.691';

sub temp_generate_taborder
{
    my $tbl = shift;
    my $mode = shift;
    my $fl = $DBIx::Perform::GlobalUi->get_field_list;
    my @tabord;

    $fl->reset;
    while (my $fo = $fl->iterate_list) {
       my ($ftag, $ftbl, $fcol) = $fo->get_names; 
       if ($ftbl eq $tbl) {
           next if !$fo->allows_focus($mode);
#           next if ($fo->{displayonly});
#           next if ($fo->{active_tabcol});
#           next if ($fo->{noupdate} && $mode eq 'update');
#           next if ($fo->{noentry} && $mode eq 'add');
           push @tabord, $ftag;
       }
    }
    return @tabord;
}

#  Altered version of execute to let us move backward.
sub execute {
    warn "TRACE: entering Forms::execute\n" if $::TRACE;
    my $self = shift;
    my $mwh = shift;
    my $conf = $self->{CONF};

    my $GlobalUi = $DBIx::Perform::GlobalUi;

    my $app = $GlobalUi->{app_object};
    my $fn = $app->getField('form_name');
    my $form = $app->getForm($fn);
    my $subform = $form->getSubform('DBForm');
    my $mode = $subform->getField('editmode');
#warn "mode = :$mode:\n";
    my $current_table = $GlobalUi->get_current_table_name;
    my @taborder = temp_generate_taborder($current_table, $mode);

    # Take an early exit if there's nothing listed in the tab order
    if (@taborder == 0) {
        $GlobalUi->change_mode_display($subform, 'perform');
        return 0;
    }
warn "taborder = ". join (' ',@taborder). "\n" if $::TRACE;

    my $widgets = $self->{WIDGETS};
    my $subforms = $self->{SUBFORMS};
    my $focused = $$conf{FOCUSED} = 
        $GlobalUi->{focus} || $taborder[0];
    my %taborder = map {($taborder[$_], $_)} (0..$#taborder); # name look-up
    my ($i, $obj, $key, $oderived, $dwh, $cwh);

# Create the window if this is not a derived window
    unless ($$conf{DERIVED}) {
        $mwh = $self->_formwin;
        $self->{LEVEL} = 1;

        # Save the old value of DESTROY and temporarily set it to false
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

    # Set the EXIT flag to false
    $$conf{EXIT} = 0;

    # Find the index of the focused widget
    $i = $taborder{$focused};

    $self->{MWH} = $mwh;
    $dwh = $self->_canvas($mwh, $self->_geometry);
    $self->_init($dwh);
    $cwh = $self->_canvas($dwh, $self->_cgeometry);
    $cwh->keypad(1);
    Curses::define_key("\c[[Z", KEY_STAB); # for some reason not recognized.
    Curses::timeout(250);	# quarter-second wait for ESC sequence.
    Curses::raw();		# catch ctrl-C

    $self->draw($mwh, 1);	# draw form at beginning of execute.

    # Start the loop
    while (1) {

        $obj = exists $$widgets{$taborder[$i]} ?  $$widgets{$taborder[$i]} :
            $$subforms{$taborder[$i]};
        $focused = $$conf{FOCUSED} = $GlobalUi->{focus}
            = $taborder[$i];
#warn "taborder[$i]=" . $taborder[$i] . "\n";

        unless (defined $obj) {
            #change to correct screen
            my $newscrs = DBIx::Perform::get_screen_from_tag($taborder[$i]);
            my $newscr = $$newscrs[0];
            DBIx::Perform::goto_screen("Run$newscr");
            $fn = $app->getField('form_name');
            $form = $app->getForm($fn);
            $subform = $form->getSubform('DBForm');
            $form->setField('FOCUSED', 'DBForm');

            my $table       = $GlobalUi->get_current_table_name;

            $subform->setField('TABORDER', \@taborder);
            $subform->setField('FOCUSED', $taborder[$i]); # first field.
            $subform->setField('editmode', $mode);
            return $key;
        }

warn "enter call :" . $obj->{OnEnter} . "\n" if $::TRACE;
        # Call the OnEnter routine if present
        &{$obj->{OnEnter}}($self) if defined $obj->{OnEnter};
        $GlobalUi->{newfocus} = '' if $GlobalUi->{newfocus} eq $taborder[$i];

        if ($app->{redraw_subform}) {
            $app->{redraw_subform} = 0;
            DBIx::Perform::UserInterface::redraw_subform();
        }

        # Execute
        $key = $obj->execute($cwh);

warn "exit  call :" . $obj->{OnExit} . "\n" if $::TRACE;
        # Call the OnExit routine if present
        &{$obj->{OnExit}}($self, $key) if defined $obj->{OnExit};
warn "returned from exit call\n" if $::TRACE;
        $obj->draw($cwh);		# un-cursor it.

        if ($app->{redraw_subform}) {
            $app->{redraw_subform} = 0;
            DBIx::Perform::UserInterface::redraw_subform();
        }

        # default is to move the focus to the next field
        my $newfocus = $GlobalUi->{newfocus};
        $GlobalUi->{newfocus} = '';
        if ($newfocus) {
	    #  Whoa!  Focus warp.
	    $i = $taborder{$newfocus};
	    $focused = $newfocus;
        }
        elsif ( $key ne "\c[" )  # ESC: not default 
	{
	    $i++;
	}

        # Exit if specified
        last if $$conf{EXIT};

        $$conf{DONTSWITCH} = 0;
        $i = 0 if $i > $#taborder;
        $i = $#taborder if $i < 0;
    }

    $cwh->delwin;
    $dwh->delwin;

    # Reset the EXIT and DESTROY flags
    $$conf{EXIT} = 0;
    $$conf{FOCUSED} = $GlobalUi->{focus} = $taborder[$i];

    warn "TRACE: leaving Forms::execute\n" if $::TRACE;
    return $key;
}

1;
