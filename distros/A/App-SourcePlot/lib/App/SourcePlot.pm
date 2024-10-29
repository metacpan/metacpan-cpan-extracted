package App::SourcePlot;

=head1 NAME

App::SourcePlot - Implements Souce Plot application

=head1 SYNOPSIS

    use App::SourcePlot;
    App::SourcePlot::run_sourceplot_gui();

=head1 DESCRIPTION

This module contains the implementation of the Source Plot application,
which can be launched using the L<sourceplot> command.

Source Plot is a simple astronomical source plotter designed to
display a plot of astronomical sources on adjustable axes.

=cut

use strict;
#use warnings;

our $VERSION = '1.32';

use Config::IniFiles;
use Tk;
use Tk::Balloon;
use Tk::FileSelect;
use App::SourcePlot::Plotter::Tk;
use DateTime;
use DateTime::Format::Strptime;
use App::SourcePlot::Source;
use File::HomeDir;
use File::ShareDir qw/dist_file/;
use File::Spec;
use Tk::AstroCatalog;
use Astro::PAL;
use Astro::Telescope;
use Math::Trig;
use Astro::Coords::Planet 0.05;

#global variables that will be used....

my $locateBug = 0;

my $MW;
my $TIME;
my @SOURCE_LIST = ();
my @planets = map {ucfirst($_)} Astro::Coords::Planet::planets();

my $CATALOG_OPEN;
my $EDIT_OPEN;

my $LAST_COMMAND;
my @UNDO_LIST;
my $undoBut;
my $cBut;
my $TimeLap = 30000;    # time between white dot updates
my $dotSizeX = 4;
my $dotSizeY = 4;

my @axes = (
    'Time',
    'Elevation',
    'Air Mass',
    'Azimuth',
    'Parallactic Angle',
);

my %defaults = (
    TEL => 'JCMT',
    XAXIS => 'Time',
    YAXIS => 'Elevation',
    TIME => '1:30:00'
);

my $plotter;
my $TEL;
my $X_AXIS;
my $Y_AXIS;
my $DATE;
my $telObject;
my ($minX, $minY);
my ($maxX, $maxY);
my $TELPOSN = undef;

my $NUM_POINTS = 97;
my $BUSY = 0;

my $TIMER;
my @COLOR_LIST = qw/#ffaaaa #00ff00 #ff55ff #ffff00 #00ffff #ff00ff #ffffff #ff5555 #55ff55 #55ffff #ffff55/;
my $COLOR_INDEX = 0;

my $EditWin = {};
my $CatWin = {};

#setup dimensions
my $xplot_default = 590;
my $xborder = 50;
my $yplot_default = 550;
my $yborder = 30;

my $RESPONSE;
my $H_LIGHT = undef;
my $H_WIDTH = 3;

my $optBut;
my $dateBut;
my $eBut;
my $defaults = undef;
my $balloon;

=head1 METHODS

=over 4

=item B<run_sourceplot_gui>

Initializes the Source Plot GUI application and enters the Tk main loop.

Accepts the following arguments in hash form:

=over 4

=item date

The UT date.  Should be in the format YYYY-MM-DD or YYYY/MM/DD.

=back

=cut

sub run_sourceplot_gui {
    my %arg = @_;

    # setting up default values for Source Plot Options
    my $defaults_file = File::Spec->catfile(
        File::HomeDir->my_home(), '.splotcfg');

    if (-e $defaults_file) {
        # Set the "fallback" section to allow reading of defaults
        # files from previous versions of SourcePlot.
        $defaults = Config::IniFiles->new(
            -file => $defaults_file,
            -fallback => 'Options',
        );
    }

    unless (defined $defaults) {
        print STDERR $_, "\n" foreach @Config::IniFiles::errors;

        $defaults = Config::IniFiles->new();
        $defaults->SetFileName($defaults_file);
    }

    $TEL = $defaults->val('Options', 'TEL', $defaults{'TEL'});
    $X_AXIS = $defaults->val('Options', 'XAXIS', $defaults{'XAXIS'});
    $Y_AXIS = $defaults->val('Options', 'YAXIS', $defaults{'YAXIS'});
    $TIME = $defaults->val('Options', 'TIME', $defaults{'TIME'});
    $telObject = Astro::Telescope->new($TEL);

    $TELPOSN = $arg{'telposn'} if exists $arg{'telposn'};

    ##### global windows

    $MW = MainWindow->new();
    $MW->positionfrom('user');
    $MW->geometry('+0+90');
    $MW->title('Source Plot');
    $MW->resizable(1, 1);
    $MW->iconname('Source Plot');
    $MW->update;

    $EditWin->{'Changeable'} = 1;
    $CatWin->{'Changeable'} = 0;

    #create the balloon used for help
    $balloon = $MW->Balloon();

    # set the date to the current date
    my ($mo, $md, $yr);
    if (exists $arg{'date'}) {
        unless ($arg{'date'} =~ /^(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})$/) {
            print STDERR "Please enter the date in the format YYYY-MM-DD\n";
            exit 1;
        }
        ($yr, $mo, $md) = ($1, $2, $3);
    }
    else {
        (undef, undef, undef, $md, $mo, $yr, undef, undef, undef) = gmtime(time);
        $mo ++;  # this catches the month up to the current date
        $yr += 1900;
    }
    $DATE = sprintf('%4d/%02d/%02d', $yr, $mo, $md);

    my $canFrame = $MW->Frame(
        -takefocus => 1,
    );

    # Create a canvas and calculate the world to pixel ratio
    $plotter = App::SourcePlot::Plotter::Tk->new($canFrame, $xplot_default, $yplot_default);
    $plotter->setBackground('black');
    $plotter->worldCenter($xborder, $yplot_default - $yborder);
    $plotter->usingWorld(1);

    my $buttonFrame = $MW->Frame(
        -takefocus => 1,
    );

    my $exitBut = $buttonFrame->Button(
        -text => 'Exit',
        -width => 8,
        -command => sub {
            destroy $MW;
        },
    )->pack(-side => 'right');
    $balloon->attach($exitBut, -balloonmsg => "Press to Exit program");

    my $printBut = $buttonFrame->Button(
        -text => 'Print',
        -width => 8,
        -command => sub {
            my $choice = 'printer';

            my $Top = $MW->Toplevel();
            $Top->title('Source Plot Printer Options');
            $Top->resizable(0, 0);
            my $radf = $Top->Frame()->pack(-padx => 10, -pady => 10, -side => 'top');
            my $tf = $Top->Frame(
                -relief => 'groove',
                -borderwidth => 2,
            )->pack(-padx => 10, -side => 'top');

            # create the radio button for the file option
            my $radbut = $radf->Radiobutton(
                -text => "To File",
                -value => 'file',
                -variable => \$choice,
            );
            $radbut->grid(-column => 0, -row => 0, -padx => 10);

            # create the print radio button
            my $radbut2 = $radf->Radiobutton(
                -text => "To Printer",
                -value => 'printer',
                -variable => \$choice,
            );
            $radbut2->grid(-column => 1, -row => 0, -padx => 10);

            # create the file entry
            $tf->Label(
                -text => "Filename",
                -justify => 'right',
            )->grid(-sticky => 'e', -column => 2, -row => 0);
            my $fileEnt = $tf->Entry(
                -relief => 'sunken',
                -width => 20,
            )->grid(-column => 3, -row => 0, -padx => 10, -pady => 5);

            # create the printer options box
            $tf->Label(
                -text => "Printer Command",
                -justify => 'right',
            )->grid(-column => 2, -row => 1, -sticky => 'e');
            my $printerEnt = 'lp';
            $tf->Entry(
                -relief => 'sunken',
                -textvariable => \$printerEnt,
                -width => 20,
            )->grid(-column => 3, -row => 1, -padx => 10, -pady => 5);

            # create the print button
            my $bf = $Top->Frame()->pack(-side => 'bottom', -pady => 10, -padx => 10);
            $bf->Button(
                -text => 'Print',
                -width => 8,
                -command => sub {
                    tagOnOff('white', 1, 'dark green');
                    tagOnOff('black', 1, 'white');
                    foreach my $source (@SOURCE_LIST) {
                        tagOnOff($source->name(), 1, 'dark green');
                    }
                    if ($choice eq 'printer') {
                        $plotter->printCanvas($choice, $printerEnt, $MW);
                    }
                    else {
                        $plotter->printCanvas($choice, $fileEnt->get, $MW);
                    }
                    tagOnOff('white', 1, 'white');
                    tagOnOff('black', 1, 'black');
                    foreach my $source (@SOURCE_LIST) {
                        tagOnOff($source->name(), 1, $source->color());
                    }
                    destroy $Top;
                },
            )->pack(-side => 'right', -padx => 10);

            my $optBut = $bf->Button(
                -text => 'Cancel',
                -width => 8,
                -command => sub {
                    destroy $Top;
                },
            )->pack(-side => 'right', -padx => 10);

            $Top->update;
            $Top->grab;
        },
    )->pack(-side => 'right');
    $balloon->attach($printBut, -balloonmsg => 'Press to print the graph');

    $optBut = $buttonFrame->Button(
        -text => 'Options',
        -width => 8,
        -command => \&changeOpt,
    )->pack(-side => 'left');
    $balloon->attach($optBut, -balloonmsg => 'Press to change the x and y axes');

    $dateBut = $buttonFrame->Button(
        -text => 'UT Date',
        -width => 8,
        -command => \&changeDate
    )->pack(-side => 'left');
    $balloon->attach($dateBut, -balloonmsg => 'Press to change the UT date');

    print "made it to just before the menu button, planet\n" if $locateBug;

    $eBut = $buttonFrame->Button(
        -text => 'Edit',
        -width => 8,
        -command => sub {
            if (! $EDIT_OPEN) {
                $EDIT_OPEN = 1;
                &editSource();
            }
        },
    )->pack(-side => 'left');
    $balloon->attach($eBut, -balloonmsg => 'Press to open the Edit Window');

    $cBut = $buttonFrame->Button(
        -text => 'Catalog',
        -width => 8,
        -command => sub {
            if (! $CATALOG_OPEN) {
                open_catalog();
            }
        },
    )->pack(-side => 'left');
    $balloon->attach($cBut, -balloonmsg => 'Press to open the Catalog Window');

    $canFrame->gridRowconfigure(0, -weight => 1);
    $canFrame->gridColumnconfigure(0, -weight => 1);

    $canFrame->grid(-row => 0, -column => 0, -sticky => 'nsew');
    $buttonFrame->grid(-row => 1, -column => 0, -sticky => 'nsew', -padx => 3, -pady => 3);

    $MW->gridRowconfigure(0, -weight => 1);
    $MW->gridColumnconfigure(0, -weight => 1);

    print "made it to just before the windows come up\n" if $locateBug;

    $MW->update;

    $eBut->configure(-state => 'disabled');
    &editSource();
    open_catalog();
    $EDIT_OPEN = 1;

    plot();
    calcTime();

    # Trigger the "plot" routine when the canvas is resized so that the plot
    # is redrawn to fit the new size.
    $canFrame->bind('<Configure>' => sub {
        plot();
    });

    if (defined $arg{'plugins'}) {
        foreach my $plugin (@{$arg{'plugins'}}) {
            $plugin->initialize($MW,
                -addCmd => \&addCommand,
            );
        }
    }

    print "made it to just before the main loop\n" if $locateBug;

    MainLoop;
}

=item B<open_catalog>

Creates an Astro::Catalog object by reading the JCMT catalog which is
distributed with this module.  This catalog is then passed to the
constructor of Tk::AstroCatalog to open a catalog window.

Also sets the C<$CATALOG_OPEN> variable and disables the catalog button.

=cut

sub open_catalog {
    my $astrocat = Astro::Catalog->new(
        Format => 'JCMT',
        File => dist_file('App-SourcePlot', 'jcmt.cat'),
        ReadOpt => {incplanets => 0},
    );
    my $catalog = Tk::AstroCatalog->new(
        $MW,
        -addCmd => \&addCommand,
        -onDestroy => \&reset,
        -upDate => \&update_status,
        -catalog => $astrocat,
    );
    $catalog->fillWithSourceList('full');
    $CATALOG_OPEN = 1;
    $cBut->configure(-state => 'disabled');
}

=item B<reset>

Resets status relating to the catalog window.

Clears the C<$CATALOG_OPEN> variable and enables the catalog button.

=cut

sub reset {
    $CATALOG_OPEN = 0;
    $cBut->configure(-state => 'normal');
}

=item B<addCommand>

This is the subroutine which is provided to C<Tk::AstroCatalog> to be called
when a source should be added to the display.

It recieves an C<Astro::Coords> object and uses it to construct an enclosing
C<App::SourcePlot::Source> object.

=cut

sub addCommand {
    my $selected = shift;

    if (@{$selected}) {
        my $source;
        $LAST_COMMAND = 'Add';
        @UNDO_LIST = ();

        $undoBut->configure(-state => 'normal') if $EDIT_OPEN;

        foreach my $coords (@$selected) {
            $source = App::SourcePlot::Source->new($coords);

            if (! isWithin($source, @SOURCE_LIST)) {
                my $s = $source->copy();
                $s->color(getColor());
                push @SOURCE_LIST, $s;
                push @UNDO_LIST, $source->copy();
            }
        }
        if ($EDIT_OPEN) {
            fillWithSourceList($EditWin, 'full');
        }
        plot();
    }
}

=item B<waitForResponse>

Waits until the C<$RESPONSE> variable has been changed.

=cut

sub waitForResponse {
    $RESPONSE = 'NOTHING';
    while ($RESPONSE == 'NOTHING') {
        $MW->update;
    }
    return 0 if $RESPONSE == -1;
    return $RESPONSE;
}

=item B<isWithin>

Checks whether a source is already part of a list. The source is compared
to sources from the list by invoking the C<summary> method on their
C<Astro::Coords> objects.

    next if isWithin($source, @list);

=cut

sub isWithin {
    my $element = shift;
    my @array = @_;
    my $len = @array;
    foreach (@array) {
        if ($element->coords()->summary() eq $_->coords()->summary()) {
            return 1;
        }
    }
    return 0;
}

=item B<remove>

Removes entries from the list which match the given source.  The comparison
is performed in the same way as C<isWithin>.

    remove($source, \@list)

=cut

sub remove {
    my $element = shift;
    my $array = shift;
    my $len = @$array;
    my @temp;
    my $flag = 0;

    for (my $index = 0; $index < $len; $index ++) {
        if ($element->coords()->summary() eq $$array[$index]->coords()->summary()) {
            $flag = -1;
        }
        else {
            $temp[$index + $flag] = $$array[$index];
        }
    }

    @$array = @temp;
}

=item B<update_status>

Invokes the update method of the main window.

=cut

sub update_status {
    $MW->update;
}

=item B<changeDate>

Changes the date to a new date.

=cut

sub changeDate {
    $dateBut->configure(-state => 'disabled');

    my @months = qw/
        January February March April May June July August
        September October November December/;

    my $name;

    my $Top = $MW->Toplevel;
    $Top->title('Source Plot UT Date');
    $Top->resizable(0, 0);
    my $topFrame = $Top->Frame(
        -relief => 'groove',
        -borderwidth => 2,
    )->pack(-padx => 10, -pady => 10);

    # create the day entry
    $topFrame->Label(-text => "Day:")->grid(-column => 0, -row => 0);
    my $dayEnt = $topFrame->Entry(
        -relief => 'sunken',
        -width => 10,
    )->grid(-column => 1, -row => 0, -padx => 10, -pady => 5);

    # create the month menu button
    $topFrame->Label(
        -text => "Month:",
    )->grid(-column => 0, -row => 1, -padx => 5, -pady => 5);

    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y/%m/%d',
        time_zone => 'UTC',
        on_error => 'croak');

    my $dt = $strp->parse_datetime($DATE);
    my $monthEnt = $months[$dt->month() - 1];

    my $mb = $topFrame->Menubutton(
        -text => $monthEnt,
        -relief => 'raised',
        -width => 10);

    foreach $name (@months) {
        $mb->command(
            -label => $name,
            -command => sub {
                $mb->configure(-text => $name);
                $monthEnt = $name;
            },
        );
    }
    $mb->grid(-column => 1, -row => 1, -padx => 10, -pady => 5, -sticky => 'w');

    # create the year entry
    $topFrame->Label(
        -text => 'Year:',
    )->grid(-column => 0, -row => 2, -padx => 5, -pady => 5);

    my $yearEnt = $topFrame->Entry(
        -relief => 'sunken',
        -width => 10,
    )->grid(-column => 1, -row => 2, -padx => 10, -pady => 5);
    $yearEnt->bind('<KeyPress-Return>' => sub {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%Y %B %d',
            on_error => 'croak');

        my $dt = $strp->parse_datetime(
            $monthEnt
            . ' ' . $dayEnt->get()
            . ' ' . $yearEnt->get());

        $DATE = $dt->strftime('%Y/%m/%d');

        destroy $Top;
    });

    # create the update subroutine
    my $complete = sub {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%B %d %Y',
            on_error => 'croak');

        my $dt = $strp->parse_datetime(
            $monthEnt
            . ' ' . $dayEnt->get()
            . ' ' . $yearEnt->get());

        $DATE = $dt->strftime('%Y/%m/%d');

        foreach my $source (@SOURCE_LIST) {
            $source->erasePoints();
        }

        plot();
    };

    # create the apply button
    my $F = $Top->Frame->pack();
    my $buttonF = $F->Frame->pack(-side => 'left', -padx => 5, -pady => 10);
    my $okBut = $buttonF->Button(
        -text => 'Apply',
        -command => $complete,
    )->pack(-side => 'left');
    $okBut->bind('<KeyPress-Return>' => $complete);

    # create the accept button
    $buttonF = $F->Frame->pack(-side => 'right', -padx => 5, -pady => 10);
    my $okBut = $buttonF->Button(
        -text => 'Accept',
        -command => sub {
            &$complete;
            destroy $Top;
        },
    )->pack(-side => 'right');
    $okBut->bind('<KeyPress-Return>' => sub {
        &$complete;
        destroy $Top;
    });

    # create the cancel button
    my $canBut = $buttonF->Button(
        -text => 'Cancel',
        -command => sub {
            destroy $Top;
        },
    )->pack(-side => 'right');
    $canBut->bind('<KeyPress-Return>' => sub {
        destroy $Top;
    });

    # Closing the window should reset $dateBut.
    $Top->bind('<Destroy>', sub {
        my $widget = shift;
        return unless $widget == $Top;
        $dateBut->configure(-state => 'normal');
    });

    $dayEnt->insert(0, $dt->day());
    $yearEnt->insert(0, $dt->year());

    $MW->update;
}

=item B<changeOpt>

Displays a window allowing the options to be changed.

=cut

sub changeOpt {
    my $name;
    my $telEnt = $TEL;
    my ($tb, $tb2);

    $optBut->configure(-state => 'disabled');

    my $Top = $MW->Toplevel;
    $Top->title('Source Plot Options');
    $Top->resizable(0, 0);
    my $topFrame = $Top->Frame(
        -relief => 'groove',
        -borderwidth => 2,
    )->pack(-padx => 10, -pady => 10);

    # place the telescope menuButton
    $topFrame->Label(-text => 'Telescope:')->grid(-column => 0, -row => 0);
    my $f = $topFrame->Frame()->grid(-column => 1, -row => 0, -padx => 10, -pady => 5, -sticky => 'w');
    my $f2 = $topFrame->Frame()->grid(-column => 1, -row => 1, -padx => 10, -pady => 5, -sticky => 'w');
    $tb = $f->Menubutton(
        -text => $telEnt,
        -relief => 'raised',
        -width => 15,
    )->pack(-side => 'left');
    $tb->cascade(-label => 'A - C', -underline => 0);
    $tb->cascade(-label => 'D - F', -underline => 0);
    $tb->cascade(-label => 'G - I', -underline => 0);
    $tb->cascade(-label => 'J - L', -underline => 0);
    $tb->cascade(-label => 'M - O', -underline => 0);
    $tb->cascade(-label => 'P - R', -underline => 0);
    $tb->cascade(-label => 'S - U', -underline => 0);
    $tb->cascade(-label => 'V - X', -underline => 0);
    $tb->cascade(-label => 'Y - Z', -underline => 0);

    my $cm = $tb->cget('-menu');
    my $ac = $cm->Menu;
    my $df = $cm->Menu;
    my $gi = $cm->Menu;
    my $jl = $cm->Menu;
    my $mo = $cm->Menu;
    my $pr = $cm->Menu;
    my $su = $cm->Menu;
    my $vx = $cm->Menu;
    my $yz = $cm->Menu;

    $tb->entryconfigure('A - C', -menu => $ac);
    $tb->entryconfigure('D - F', -menu => $df);
    $tb->entryconfigure('G - I', -menu => $gi);
    $tb->entryconfigure('J - L', -menu => $jl);
    $tb->entryconfigure('M - O', -menu => $mo);
    $tb->entryconfigure('P - R', -menu => $pr);
    $tb->entryconfigure('S - U', -menu => $su);
    $tb->entryconfigure('V - X', -menu => $vx);
    $tb->entryconfigure('Y - Z', -menu => $yz);

    foreach $name ($telObject->telNames()) {
        if ($name =~ /^[A-Ca-c]/) {
            $ac->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[D-Fd-f]/) {
            $df->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[G-Ig-i]/) {
            $gi->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[J-Lj-l]/) {
            $jl->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[M-Om-o]/) {
            $mo->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[P-Rp-r]/) {
            $pr->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[S-Us-u]/) {
            $su->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[V-Xv-x]/) {
            $vx->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
        elsif ($name =~ /^[Y-Zy-z]/) {
            $yz->command(
                -label => $name,
                -command => sub {
                    $tb->configure(-text => $name);
                    $telEnt = $name;
                },
            );
        }
    }

    # place the middle time field
    $topFrame->Label(
        -text => 'Center Time (in HST):',
    )->grid(-column => 0, -row => 2, -padx => 5, -pady => 5);

    my $timeEnt = $TIME;
    $topFrame->Entry(
        -relief => 'sunken',
        -textvariable => \$timeEnt,
        -width => 10,
    )->grid(-column => 1, -row => 2, -padx => 10, -pady => 5);

    # place the y-axis menuButton
    $topFrame->Label(
        -text => 'y-axis:',
    )->grid(-column => 0, -row => 4, -padx => 5, -pady => 5);

    my $yEnt = $Y_AXIS;
    my $yb = $topFrame->Menubutton(
        -text => $yEnt,
        -relief => 'raised',
        -width => 15);
    foreach $name (@axes) {
        $yb->command(
            -label => $name,
            -command => sub {
                $yb->configure(-text => $name);
                $yEnt = $name;
            },
        );
    }
    $yb->grid(-column => 1, -row => 4, -padx => 10, -pady => 5, -sticky => 'w');

    # inserting cascading choices

    # place the x-axis menuButton
    $topFrame->Label(
        -text => 'x-axis:',
    )->grid(-column => 0, -row => 3, -padx => 5, -pady => 5);
    my $xEnt = $X_AXIS;
    my $xb = $topFrame->Menubutton(
        -text => $xEnt,
        -relief => 'raised',
        -width => 15,
    );
    foreach $name (@axes) {
        $xb->command(
            -label => $name,
            -command => sub {
                $xb->configure(-text => $name);
                $xEnt = $name;
            },
        );
    }
    $xb->grid(-column => 1, -row => 3, -padx => 10, -pady => 5, -sticky => 'w');

    # place the Apply button
    my $F = $Top->Frame->pack();
    my $buttonF = $F->Frame->pack(-side => 'left', -padx => 5, -pady => 10);
    $buttonF->Button(
        -text => 'Apply',
        -command => sub {
            $X_AXIS = $xEnt;
            $Y_AXIS = $yEnt;
            if ($TEL ne $telEnt || $TIME ne $timeEnt) {
                foreach (@SOURCE_LIST) {
                    $_->erasePoints();
                }
            }
            else {
                foreach (@SOURCE_LIST) {
                    $_->eraseTimeDot();
                }
            }
            $TIME = $timeEnt;
            $TIME =~ s/^\s+//;
            $TIME =~ s/\s+$//;
            $TIME =~ s/\s+/:/g;
            $TEL = $telEnt;
            $telObject->name($TEL);
            plot();
        },
    )->pack(-side => 'left');

    # place the ok button
    $buttonF = $F->Frame->pack(-side => 'right', -padx => 5, -pady => 10);
    $buttonF->Button(
        -text => 'Accept',
        -command => sub {
            $X_AXIS = $xEnt;
            $Y_AXIS = $yEnt;
            if ($TEL ne $telEnt || $TIME ne $timeEnt) {
                foreach (@SOURCE_LIST) {
                    $_->erasePoints();
                }
            }
            else {
                foreach (@SOURCE_LIST) {
                    $_->eraseTimeDot();
                }
            }
            $TIME = $timeEnt;
            $TIME =~ s/^\s+//;
            $TIME =~ s/\s+$//;
            $TIME =~ s/\s+/:/g;
            $TEL = $telEnt;
            $telObject->name($TEL);
            plot();
            destroy $Top;
        },
    )->pack(-side => 'right');

    # place the cancel button
    $buttonF->Button(
        -text => 'Cancel',
        -command => sub {
            destroy $Top;
        },
    )->pack(-side => 'right');

    # Closing the window should reset $optBut.
    $Top->bind('<Destroy>', sub {
        my $widget = shift;
        return unless $widget == $Top;
        $optBut->configure(-state => 'normal');
    });

    $buttonF->Button(
        -text => 'Save Setting',
        -command => sub {
            $X_AXIS = $xEnt;
            $Y_AXIS = $yEnt;
            $TEL = $telEnt;
            $TIME = $timeEnt;
            $defaults->newval('Options', 'TEL', $TEL);
            $defaults->newval('Options', 'XAXIS', $X_AXIS);
            $defaults->newval('Options', 'YAXIS', $Y_AXIS);
            $defaults->newval('Options', 'TIME', $TIME);
            $defaults->RewriteConfig();
        },
    )->pack(-side => 'right');
    $MW->update;
}

=item B<addPlanetSource>

Adds a planet source into the plotting list.  The planet number
is currently unused.

    addPlanetSource($name, $number);

=cut

sub addPlanetSource {
    my $name = shift;
    my $number = shift;
    my $source = App::SourcePlot::Source->new($name);
    if (! isWithin($source, @SOURCE_LIST)) {
        $source->color(getColor());
        push @SOURCE_LIST, $source;
    }
}

=item B<getSource>

Prompts the user to enter source coords and name.
Can specify previous source object to edit.

Returns a Source object.

=cut

sub getSource {
    my $source = shift;
    my @Epocs = qw/RJ RB GA AZ/;
    my $name;

    my $Top = $MW->Toplevel;
    $Top->title('Source Plot');
    $Top->resizable(0, 0);
    my $topFrame = $Top->Frame(
        -relief => 'groove',
        -borderwidth => 2,
        -width => 50,
    )->pack(-padx => 10, -fill => 'x', -ipady => 10, -pady => 10);

    $topFrame->Label(
        -text => 'Name:',
    )->grid(-column => 0, -row => 0);
    my $nameEnt = $topFrame->Entry(
        -relief => 'sunken',
        -width => 15,
    )->grid(-column => 1, -row => 0, -padx => 10, -pady => 3);
    $nameEnt->insert(0, $source->name());

    $topFrame->Label(
        -text => 'Ra:',
    )->grid(-column => 0, -row => 1);
    my $raEnt = $topFrame->Entry(
        -relief => 'sunken',
        -width => 15,
    )->grid(-column => 1, -row => 1, -padx => 10, -pady => 3);
    $raEnt->insert(0, $source->ra()) unless $source->is_blank();

    $topFrame->Label(
        -text => 'Dec:',
    )->grid(-column => 0, -row => 2);
    my $decEnt = $topFrame->Entry(
        -relief => 'sunken',
        -width => 15
    )->grid(-column => 1, -row => 2, -padx => 10, -pady => 3);
    $decEnt->insert(0, $source->dec()) unless $source->is_blank();

    $topFrame->Label(
        -text => 'Epoc:',
    )->grid(-column => 0, -row => 3, -padx => 5, -pady => 5);
    my $epocEnt = $source->is_blank() ? $Epocs[0] : $source->epoc();
    my $epocB = $topFrame->Menubutton(
        -text => $epocEnt,
        -relief => 'raised',
        -width => 15,
    );

    foreach $name (@Epocs) {
        $epocB->command(
            -label => $name,
            -command => sub {
                $epocB->configure(-text => $name);
                $epocEnt = $name;
            },
        );
    }
    $epocB->grid(-column => 1, -row => 3, -padx => 10, -pady => 5, -sticky => 'w');

    my $buttonF = $Top->Frame->pack(-padx => 10, -pady => 10);
    $buttonF->Button(
        -text => 'Ok',
        -command => sub {
            $source->configure($nameEnt->get(), $raEnt->get(), $decEnt->get(), $epocEnt);
            destroy $Top;
            $RESPONSE = 1;
        },
    )->pack(-side => 'right');
    $buttonF->Button(
        -text => 'Cancel',
        -command => sub {
            destroy $Top;
            $RESPONSE = -1;
        },
    )->pack(-side => 'right');
    $Top->update;
    $Top->grab;
}

=item B<editSource>

Edits the existing source list.

=cut

sub editSource {
    my (@selected) = ();
    my $udeb = 0;  #debugger

    $eBut->configure(-state => 'disabled');

    my $Top = $MW->Toplevel();
    $Top->geometry('+600+90');
    $Top->title('Source Plot: Edit Window');
    $Top->resizable(1, 1);
    my $topFrame = $Top->Frame(
        -relief => 'groove',
        -borderwidth => 2,
        -width => 50,
    )->grid(-column => 0, -row => 0, -padx => 3, -pady => 3, -sticky => 'nsew');

    # create the header
    my $head = $topFrame->Text(
        -wrap => 'none',
        -relief => 'flat',
        -foreground => 'midnightblue',
        -width => 50,
        -height => 1,
        -font => '-*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*',
        -takefocus => 0,
    )->grid(-sticky => 'ew', -row => 0);

    my $title = sprintf "%5s  %-16s  %-12s  %-13s  %-4s", 'Index', 'Name',
        'Ra', 'Dec', 'Epoc';
    $head->insert('end', $title);
    $head->configure(-state => 'disabled');

    # create the scollable text
    my $T = $topFrame->Scrolled(
        'Text',
        -scrollbars => 'e',
        -background => '#333333',
        -wrap => 'none',
        -width => 60,
        -height => 15,
        -font => '-*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*',
        -setgrid => 1,
    )->grid(-sticky => 'nsew', -row => 1);
    $T->bindtags(qw/widget_demo/); # remove all bindings but dummy "widget_demo"

    $topFrame->gridRowconfigure(1, -weight => 1);
    $topFrame->gridColumnconfigure(0, -weight => 1);

    # create the done button
    my $buttonF = $Top->Frame->grid(-column => 0, -row => 1, -padx => 3, -pady => 3, -sticky => 'nsew');
    my $doneBut = $buttonF->Button(
        -text => 'Done',
        -width => 4,
        -command => sub {
            destroy $Top;
        },
    )->pack(-side => 'right');
    $balloon->attach($doneBut, -balloonmsg => "Press to close the Edit Window");

    # Closing the window should reset $eBut.
    $Top->bind('<Destroy>', sub {
        my $widget = shift;
        return unless $widget == $Top;
        $eBut->configure(-state => 'normal');
        $EDIT_OPEN = 0;
    });

    # create the On / Off button
    my $OOBut = $buttonF->Button(
        -text => 'ON/Off',
        -width => 5,
        -command => sub {
            my $source;
            foreach $source (@selected) {
                if ($source->active()) {
                    tagOnOff($source->name(), 0);
                    $source->active(0);
                    $T->tag(
                        'configure',
                        'd' . $source->index(),
                        -foreground => 'black'
                    );
                }
                else {
                    tagOnOff($source->name(), 1, $source->color(), 'yellow');
                    $source->active(1);
                    $T->tag(
                        'configure',
                        'd' . $source->index(),
                        -foreground => $source->color()
                    );
                }
            }
            @selected = ();
        },
    )->pack(-side => 'left');
    $balloon->attach($OOBut, -balloonmsg => "Press to turn the selected\nsources On/Off");

    # create the delete all button
    my $manipF = $buttonF->Frame->pack(-side => 'left', -padx => 30);
    my $DABut = $manipF->Button(
        -text => 'Delete All',
        -width => 8,
        -command => sub {
            $LAST_COMMAND = 'Delete';
            foreach my $source (@SOURCE_LIST) {
                tagOnOff($source->name(), 1, $source->color(), 'yellow');
                $source->active(1);
                $EditWin->{Text}->tagDelete('d' . $source->index());
            }
            @UNDO_LIST = @SOURCE_LIST;
            $undoBut->configure(-state => 'normal') if $EDIT_OPEN;
            @SOURCE_LIST = ();
            @selected = ();
            fillWithSourceList($EditWin, 'full');
            plot();
        },
    )->pack(-side => 'left');
    $balloon->attach($DABut, -balloonmsg => "Press to delete all sources\nfrom the Edit Window");

    # create the delete button
    my $delBut = $manipF->Button(
        -text => 'Delete',
        -width => 6,
        -command => sub {
            my $len = @selected;
            $LAST_COMMAND = 'Delete';
            @UNDO_LIST = ();
            if ($len > 0) {
                $undoBut->configure(-state => 'normal');
            }
            else {
                $undoBut->configure(-state => 'disabled');
            }
            foreach my $source (@selected) {
                tagOnOff($source->name(), 1, $source->color(), 'yellow');
                $source->active(1);
                push @UNDO_LIST, $source;
                $plotter->delete('l' . $source->name());
                $plotter->delete('fo' . $source->name());
                $plotter->delete('t' . $source->name());
                $plotter->delete('time' . $source->name());
                $plotter->delete('ttimeDot' . $source->name());
                $plotter->delete('ltimeDot' . $source->name());
                $plotter->delete('timeDot' . $source->name());
                $EditWin->{Text}->tagDelete('d' . $source->index());
                remove($source, \@SOURCE_LIST);
            }
            @selected = ();
            fillWithSourceList($EditWin, 'full');
        },
    )->pack(-side => 'left');
    $balloon->attach($delBut, -balloonmsg => "Press to delete the\nselected sources");

    # create the delete button
    $undoBut = $manipF->Button(
        -text => 'Undo',
        -command => sub {
            if ($LAST_COMMAND eq 'Add') {
                print "Last command was add\n" if $udeb;
                foreach my $source (@UNDO_LIST) {
                    remove($source, \@SOURCE_LIST);
                    print "removing " . $source->name . "\n" if $udeb;
                }
            }
            elsif ($LAST_COMMAND eq 'Delete') {
                print "Last command was removed\n" if $udeb;
                foreach my $source (@UNDO_LIST) {
                    push(@SOURCE_LIST, $source);
                    print "Adding " . $source->name . "\n" if $udeb;
                }
            }
            elsif ($LAST_COMMAND eq 'Change') {
                print "Last command was changed\n" if $udeb;
                my $source = pop(@UNDO_LIST);
                my $orig = pop(@UNDO_LIST);
                print "Reconfiguring " . $source->name . "\n" if $udeb;
                $source->configure($orig);
                print "Clearing " . $source->name . "\n" if $udeb;
                $source->erasePoints();
            }
            $LAST_COMMAND = '';
            @UNDO_LIST = ();
            @selected = ();
            $undoBut->configure(-state => 'disabled') if $EDIT_OPEN;
            fillWithSourceList($EditWin, 'full');
            plot();
        },
    )->pack(-side => 'left');
    $undoBut->configure(-state => 'disabled') if $EDIT_OPEN;
    $balloon->attach($undoBut, -balloonmsg => "Press to undo the last\nmajor command");

    # create the add button
    my $newBut = $manipF->Button(
        -text => 'New',
        -width => 4,
        -command => sub {
            my $source = App::SourcePlot::Source->new();
            &getSource($source);
            my $res = &waitForResponse();
            if ($res && ! isWithin($source, @SOURCE_LIST)) {
                $source->color(getColor());
                push @SOURCE_LIST, $source;
                fillWithSourceList($EditWin, 'full');
                $LAST_COMMAND = 'Add';
                @UNDO_LIST = ();
                $undoBut->configure(-state => 'normal') if $EDIT_OPEN;
                push @UNDO_LIST, $source;
                plot();
            }
        },
    )->pack(-side => 'left');
    $balloon->attach($newBut, -balloonmsg => "Press to manually\nadd a source");

    # create the planet button
    my $planBut = $manipF->Menubutton(
        -text => 'Planets',
        -width => 7,
        -relief => 'raised',
    );
    {
        my $k = 0;
        foreach my $plan (@planets) {
            my $c = $k;
            $planBut->command(
                -label => $plan,
                -command => sub {
                    &addPlanetSource($plan, $c);
                    print "$TEL is tel  \n" if $locateBug;
                    fillWithSourceList($EditWin, 'full');
                    plot();
                }
            );
            $k ++;
        }
    }
    $planBut->command(
        -label => 'All',
        -command => sub {
            my $j = 0;
            foreach (@planets) {
                &addPlanetSource($_, $j);
                $j ++;
            }
            fillWithSourceList($EditWin, 'full');
            plot();
        }
    );
    $planBut->pack(-side => 'left');
    $balloon->attach($planBut, -balloonmsg => "Press to add a planet\nto the plot");

    $Top->gridRowconfigure(0, -weight => 1);
    $Top->gridColumnconfigure(0, -weight => 1);

    $EditWin->{'Window'} = $Top;
    $EditWin->{'Text'} = $T;
    $EditWin->{'Selected'} = \@selected;
    $EditWin->{'Sources'} = \@SOURCE_LIST;

    fillWithSourceList($EditWin, 'full');

    $MW->update;
}

=item B<fillWithSourceList>

Fills a Text box with the list of current sources.

=cut

sub fillWithSourceList {
    my (@bold, @normal);
    my $Window = shift;
    my $T = $Window->{'Text'};
    my $selected = $Window->{'Selected'};
    my $arrayOfSources = $Window->{'Sources'};
    my $task = shift;
    my $sort = shift;
    my $index = shift;
    my (@sources);
    my ($source);
    my @entered = ();
    my ($line, $itag);

    @sources = @$arrayOfSources;

    if (defined $sort) {
        for ($sort) {
            /unsorted/ and do {@sources = @$arrayOfSources; last;};
            /name/ and do {@sources = sort by_name @$arrayOfSources; last;};
            /ra/ and do {@sources = sort by_ra @$arrayOfSources; last;};
            /dec/ and do {@sources = sort by_dec @$arrayOfSources; last;};
            die "Unknown value for form variable \$sort \n";
        }
    }

    # Enable infobox for access
    $T->configure(-state => 'normal');

    # Clear the existing widgets
    if (defined $task && $task eq 'full') {
        $T->delete('1.0', 'end');
        foreach my $source (@sources) {
            $T->tagDelete('d' . $source->index());
        }
    }

    # Set up display styles
    if ($T->depth > 1) {
        @bold = ('-background' => '#eeeeee', '-relief' => 'raised', '-borderwidth' => 1);
        @normal = ('-background' => undef, '-relief' => 'flat');
    }
    else {
        @bold = ('-foreground' => 'white', '-background' => 'black');
        @normal = ('-foreground' => undef, '-background' => undef);
    }
    $T->tag(configure => 'normal', '-foreground' => 'blue');
    $T->tag(configure => 'inactive', '-foreground' => 'black');
    $T->tag(configure => 'selected', '-foreground' => 'red');
    foreach (@COLOR_LIST) {
        $T->tag('configure', $_, '-foreground' => $_);
    }

    # Insert the current values
    if (defined $task && $task eq 'full') {
        my $len = @sources;
        for ($index = 0; $index < $len; $index ++) {
            $source = $sources[$index];
            $source->index($index);
            $line = $source->dispLine();
            if (&isWithin($source, @$selected)) {
                inswt($T, "$line\n", "d$index", 'selected');
            }
            else {
                if ($source->active()) {
                    if ($source->color() ne '') {
                        inswt($T, "$line\n", "d$index", $source->color());
                    }
                    else {
                        inswt($T, "$line\n", "d$index", 'normal');
                    }
                }
                else {
                    inswt($T, "$line\n", "d$index", 'inactive');
                }
            }
        }

        $len = @sources;
        for ($itag = 0; $itag < $len; $itag ++) {
            my $dtag = "d$itag";
            $T->tag(
                'bind', $dtag,
                '<Any-Enter>' => sub {
                    shift->tag('configure', $dtag, @bold);
                    if ($Window->{'Changeable'} && $sources[substr($dtag, 1, 99)]->active()) {
                        $plotter->configureTag(
                            'l' . $sources[substr($dtag, 1, 99)]->name(),
                            -width => 3);
                    }
                },
            );
            $T->tag(
                'bind', $dtag,
                '<Any-Leave>' => sub {
                    shift->tag('configure', $dtag, @normal);
                    if ($Window->{'Changeable'} && $sources[substr($dtag, 1, 99)]->active()) {
                        $plotter->configureTag(
                            'l' . $sources[substr($dtag, 1, 99)]->name(),
                            -width => 1);
                    }
                },
            );
            $T->tag(
                'bind', $dtag,
                '<ButtonRelease-1>' => sub {
                    if (! $BUSY) {
                        if (! &isWithin($sources[substr($dtag, 1, 99)], @$selected)) {
                            shift->tag('configure', $dtag,
                                -foreground => 'red');
                            push @$selected, $sources[substr($dtag, 1, 99)];
                        }
                        else {
                            if ($sources[substr($dtag, 1, 99)]->color() ne '') {
                                shift->tag('configure', $dtag,
                                    -foreground => $sources[substr($dtag, 1, 99)]->color()
                                );
                            }
                            else {
                                shift->tag('configure', $dtag,
                                    -foreground => 'blue');
                            }
                            &remove($sources[substr($dtag, 1, 99)], $selected);
                        }
                    }
                },
            );
            if ($Window->{'Changeable'}) {
                $T->tag(
                    'bind', $dtag,
                    '<Double-1>' => sub {
                        my $source = $sources[substr($dtag, 1, 99)];
                        $LAST_COMMAND = 'Change';
                        @UNDO_LIST = ($source->coords());
                        &getSource($source);
                        my $res = &waitForResponse();
                        if ($res) {
                            $undoBut->configure(-state => 'normal')
                                if $EDIT_OPEN;
                        }
                        else {
                            $undoBut->configure(-state => 'disabled')
                                if $EDIT_OPEN;
                        }
                        push @UNDO_LIST, $source;
                        $source->erasePoints();
                        fillWithSourceList($EditWin, 'full');
                        plot();
                    },
                );
            }
            else {
                $T->tag(
                    'bind', $dtag,
                    '<Double-1>' => sub {
                        $BUSY = 1;
                        my $source = $sources[substr($dtag, 1, 99)];
                        push @$selected, $source;
                        $LAST_COMMAND = 'Add';
                        @UNDO_LIST = ();
                        $undoBut->configure(-state => 'normal') if $EDIT_OPEN;
                        $MW->update();
                        my $T = shift;

                        foreach $source (@$selected) {
                            if (! isWithin($source, @SOURCE_LIST)) {
                                my $s = $source->copy();
                                $s->color(getColor());
                                push(@SOURCE_LIST, $s);
                                push(@UNDO_LIST, $s);
                            }
                            $T->tag(
                                'configure',
                                'd' . $source->index(),
                                -foreground => 'blue',
                            );
                        }
                        @$selected = ();
                        if ($EDIT_OPEN) {
                            fillWithSourceList($EditWin, 'full');
                        }
                        plot();
                        $BUSY = 0;
                    },
                );
            }
        }
    }

    $T->mark('set', insert => '1.0');

    # Disable access to infobox
    $T->configure(-state => 'disabled');
}

=item B<plot>

Plots the graphs, including axis.

=cut

sub plot {
    print "Entered plot\n" if $locateBug;
    my $xplot = $plotter->width;
    my $yplot = $plotter->height;
    $plotter->usingWorld(0);
    $plotter->worldCenter($xborder, $yplot - $yborder);
    $plotter->usingWorld(1);
    my ($xworldRatio, $yworldRatio);
    my $debug = 0;
    $TIME =~ s/^\s+//;
    $TIME =~ s/\s+$//;
    $TIME =~ s/\s+/:/g;
    my ($timeH, $min, $sec) = split /:/, $TIME, 3;
    my $XSpaceForTime = 0;
    my $YSpaceForTime = 0;
    my $special = 0;
    my $lstDiffX;
    my $lstDiffY;

    $XSpaceForTime = $xborder if $Y_AXIS =~ /time/i;
    $YSpaceForTime = $yborder if $X_AXIS =~ /time/i;
    $timeH += $min / 60 + $sec / 3600;

    #clear the plot
    $plotter->clean();

    # calc the world coords
    print "    Calculating the world coordinate system\n" if $locateBug;
    if ($X_AXIS =~ /time/i) {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%Y/%m/%d %H:%M:%S',
            on_error => 'croak');

        my $dt = $strp->parse_datetime($DATE . ' ' . $TIME);

        $dt->subtract(hours => 2);

        my ($lst, $mjd) = ut2lst(
            $dt->year(), $dt->month(), $dt->day(),
            $dt->hour(), $dt->minute(), $dt->second(),
            $telObject->long_by_rad());

        $dt->add(hours => 1);

        my ($lst2, $mjd2) = ut2lst(
            $dt->year(), $dt->month(), $dt->day(),
            $dt->hour(), $dt->minute(), $dt->second(),
            $telObject->long_by_rad());

        if ($lst2 < $lst) {
            $lst2 += 2 * pi;
        }

        $lstDiffX = $lst2 - $lst;
        $xworldRatio = (24 * $lstDiffX) / ($xplot - $xborder * 2 - $XSpaceForTime);
        $minX = $lst;
        $maxX = $lst + 24 * $lstDiffX;
        print "x-axis is time\n" if $debug;
    }
    elsif ($X_AXIS =~ /air mass/i) {
        $xworldRatio = 90 / ($xplot - $xborder * 2 - $XSpaceForTime);
        $minX = 0;
        $maxX = 90;
        print "x-axis is ele\n" if $debug;
    }
    elsif ($X_AXIS =~ /elevation/i) {
        $xworldRatio = 90 / ($xplot - $xborder * 2 - $XSpaceForTime);
        $minX = 0;
        $maxX = 90;
        print "x-axis is ele\n" if $debug;
    }
    elsif ($X_AXIS =~ /azimuth/i) {
        $xworldRatio = 360 / ($xplot - $xborder * 2 - $XSpaceForTime);
        $minX = 0;
        $maxX = 360;
        print "x-axis is pa\n" if $debug;
    }
    elsif ($X_AXIS =~ /parallactic angle/i) {
        $xworldRatio = 360 / ($xplot - $xborder * 2 - $XSpaceForTime);
        $minX = -180;
        $maxX = 180;
        print "x-axis is az\n" if $debug;
    }
    else {
        print "ERROR:  X axis undefined!!\n\n";
        $minX = 0;
        $maxX = 0;
    }
    if ($Y_AXIS =~ /time/i) {
        my $strp = DateTime::Format::Strptime->new(
            pattern => '%Y/%m/%d %H:%M:%S',
            on_error => 'croak');

        my $dt = $strp->parse_datetime($DATE . ' ' . $TIME);

        $dt->subtract(hours => 2);

        my ($lst, $mjd) = ut2lst(
            $dt->year(), $dt->month(), $dt->day(),
            $dt->hour(), $dt->minute(), $dt->second(),
            $telObject->long_by_rad());

        $dt->add(hours => 1);

        my ($lst2, $mjd2) = ut2lst(
            $dt->year(), $dt->month(), $dt->day(),
            $dt->hour(), $dt->minute(), $dt->second(),
            $telObject->long_by_rad());

        if ($lst2 < $lst) {
            $lst2 += 2 * pi;
        }

        $lstDiffY = $lst2 - $lst;
        $yworldRatio = (-24 * $lstDiffY) / ($yplot - $yborder * 2 - $YSpaceForTime);
        $maxY = $lst + 24 * $lstDiffY;
        $minY = $lst;
        print "y-axis is time\n" if $debug;
    }
    elsif ($Y_AXIS =~ /air mass/i) {
        $yworldRatio = -90 / ($yplot - $yborder * 2 - $YSpaceForTime);
        $maxY = 90;
        $minY = 0;
        print "y-axis is ele\n" if $debug;
    }
    elsif ($Y_AXIS =~ /elevation/i) {
        $yworldRatio = -90 / ($yplot - $yborder * 2 - $YSpaceForTime);
        $maxY = 90;
        $minY = 0;
        print "y-axis is ele\n" if $debug;
    }
    elsif ($Y_AXIS =~ /azimuth/i) {
        $yworldRatio = -360 / ($yplot - $yborder * 2 - $YSpaceForTime);
        $minY = 0;
        $maxY = 360;
        print "y-axis is az\n" if $debug;
    }
    elsif ($Y_AXIS =~ /parallactic angle/i) {
        $yworldRatio = -360 / ($yplot - $yborder * 2 - $YSpaceForTime);
        $minY = -180;
        $maxY = 180;
        print "y-axis is pa\n" if $debug;
    }
    else {
        print "ERROR:  Y axis undefined!!\n\n";
        $minY = 0;
        $maxY = 0;
    }
    if ((($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /elevation/i))
            || (($X_AXIS =~ /azimuth/i) && ($Y_AXIS =~ /elevation/i))
            || (($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /air mass/i))
            || (($X_AXIS =~ /azimuth/i) && ($Y_AXIS =~ /air mass/i))) {
        $yworldRatio = -180 / ($yplot - $yborder * 2);
        $xworldRatio = 180 / ($xplot - $xborder * 2);
        $minY = 0;
        $maxY = 180;
        $minX = 0;
        $maxX = 180;
        $plotter->usingWorld(0);
        $plotter->worldCenter($xplot / 2, $yplot / 2);
        $plotter->usingWorld(1);

        if (($X_AXIS =~ /elevation/i) || ($Y_AXIS =~ /elevation/i)) {
            $special = 1;
        }
        else  {
            # air mass case
            $special = 2;
        }
        print "axes is special\n" if $debug;
    }
    print "    Setting the world coordinate system\n" if $locateBug;
    $plotter->worldToPixRatio($xworldRatio, $yworldRatio);
    $plotter->worldAtZero($minX, $minY);

    # draw the grid lines - x axis
    $plotter->fontColor('White');
    $plotter->drawColor('dark green');
    if (($special == 1) || ($special == 2)) {
        # draw the angle grid lines
        for (my $z = 0; $z < 360; $z += 15) {
            my $tz = (90 - $z) * pi / 180;
            my $x = 92 * cos $tz;
            my $y = 92 * sin $tz;
            $plotter->drawLine(0, 0, $x, $y, 'grid');
        }
        #label the angle grid lines
        for (my $z = 0; $z < 360; $z += 15) {
            my $tz = (90 - $z) * pi / 180;
            my $x = 95 * cos $tz;
            my $y = 95 * sin $tz;
            if ($z == 0) {
                $plotter->drawText($x, $y, 'N', 'twhite');
            }
            elsif ($z == 90) {
                $plotter->drawText($x, $y, 'E', 'twhite');
            }
            elsif ($z == 180) {
                $plotter->drawText($x, $y, 'S', 'twhite');
            }
            elsif ($z == 270) {
                $plotter->drawText($x, $y, 'W', 'twhite');
            }
            else {
                $plotter->drawText($x, $y, $z, 'twhite');
            }
        }

        # draw the outside circle
        $plotter->drawColor('white');
        $plotter->penWidth(2);
        $plotter->drawOval(-90, -90, 90, 90, 'owhite');
        $plotter->penWidth(1);

        if ($special == 1)  {
            # elevation -azimuth case

            # draw the elevation labels
            $plotter->drawColor('dark green');
            my $texty = $plotter->toWy(5) - $plotter->toWy(0);
            for (my $i = 0; $i < 90; $i += 10) {
                $plotter->drawOval(-$i, -$i, $i, $i, 'grid');
                $plotter->drawText(0, $i - $texty, 90 - $i, 'twhite');
            }

            $plotter->usingWorld(0);
            $plotter->worldCenter($xborder, $yplot - $yborder);
            $plotter->usingWorld(1);
        }
        if ($special == 2)  {
            # azimuth - air mass case

            # draw the elevation labels
            $plotter->drawColor('dark green');
            my $ytext = $plotter->toWx(5) - $plotter->toWx(0);
            for (qw/1.0 1.25 1.5 1.75 2.0 3.0 4.0 5.0/) {
                my $new_el = 90 - am_to_deg($_);
                $plotter->drawOval(-$new_el, -$new_el, $new_el, $new_el, 'grid');
            }
            $plotter->drawText(0, 0, 1.0, 'twhite');
            $plotter->drawText(0, 39, 1.25, 'twhite');
            $plotter->drawText(0, 50, 1.5, 'twhite');
            $plotter->drawText(0, 57, 1.75, 'twhite');
            $plotter->drawText(0, 61, 2.0, 'twhite');
            $plotter->drawText(0, 71, 3.0, 'twhite');
            $plotter->drawText(0, 76, 4.0, 'twhite');
            $plotter->drawText(0, 80, 5.0, 'twhite');
            $plotter->usingWorld(0);
            $plotter->worldCenter($xborder, $yplot - $yborder);
            $plotter->usingWorld(1);
        }
    }
    elsif ($X_AXIS =~ /time/i) {
        my $ho = $timeH - 8;
        for (my $hour = $minX + $lstDiffX * 4; $hour < $maxX; $hour += $lstDiffX * 4) {
            my $tel = $telObject;
            $plotter->drawLine($hour, $minY, $hour, $maxY, 'grid');

            # calculate the HST time
            my $ti = $ho;
            $ti -= 24 if $ti >= 24;
            $ti += 24 if $ti < 0;
            my ($h, $m) = split(/\./, $ti);
            $m = ('.' . $m) * 60;
            $m = '0' . $m if $m < 10;
            my $y = $plotter->toWy($yplot - $yborder * 3 / 2);
            $plotter->drawText($hour, $y, sprintf("%2s:%2s", $h, $m), 'twhite');

            # calculate the ut time
            my $uh = $h + 10;
            $uh -= 24 if $uh >= 24;
            my $uy = $plotter->toWy($yborder / 2);
            $plotter->drawText($hour, $uy, sprintf("%2s:%2s", $uh, $m), 'twhite');

            #calculate the lst time
            my $lst;
            my $si = '+';
            my @parts;
            $si = '-' if ($hour < 0);
            $lst = $hour;
            while ($lst > 2 * pi) {
                $lst -= 2 * pi;
            }
            my ($si, @hms) = palDr2tf(2, $lst);
            my ($lh, $lm, $ls, undef) = @hms;
            $lm += 1 if $ls >= 30;
            if ($lm >= 60) {
                $lm -= 60;
                $lh += 1;
                $lh -= 24 if $lh > 24;
            }
            $lm = '0' . $lm if $lm < 10;
            my $ly = $plotter->toWy($yborder * 3 / 2);
            $plotter->drawText($hour, $ly, sprintf("%2s:%2s", $lh, $lm), 'twhite');
            $ho += 4;
        }
    }
    elsif ($X_AXIS =~ /elevation/i) {
        my $y = $plotter->toWy($yplot - $yborder - 10);
        for (my $deg = $minX + 20; $deg < $maxX; $deg += 10) {
            $plotter->drawLine($deg, $minY, $deg, $maxY, 'grid');
            $plotter->drawText($deg, $y, $deg, 'twhite');
        }
    }
    elsif ($X_AXIS =~ /air mass/i) {
        my $dAt12 = 90 - (180 / pi * acos(1 / 1.25));
        my $dAt15 = 90 - (180 / pi * acos(1 / 1.5));
        my $dAt17 = 90 - (180 / pi * acos(1 / 1.75));
        my $dAt3 = 90 - (180 / pi * acos(1 / 3));
        my $dAt4 = 90 - (180 / pi * acos(1 / 4));
        my $dAt5 = 90 - (180 / pi * acos(1 / 5));
        $plotter->drawLine(30, $minY, 30, $maxY, 'grid');
        $plotter->drawLine($dAt12, $minY, $dAt12, $maxY, 'grid');
        $plotter->drawLine($dAt15, $minY, $dAt15, $maxY, 'grid');
        $plotter->drawLine($dAt17, $minY, $dAt17, $maxY, 'grid');
        $plotter->drawLine($dAt3, $minY, $dAt3, $maxY, 'grid');
        $plotter->drawLine($dAt4, $minY, $dAt4, $maxY, 'grid');
        $plotter->drawLine($dAt5, $minY, $dAt5, $maxY, 'grid');

        my $y = $plotter->toWy($yplot - $yborder - 10);
        $plotter->drawText($dAt12, $y, '1.25', 'twhite');
        $plotter->drawText($dAt15, $y, '1.5', 'twhite');
        $plotter->drawText($dAt17, $y, '1.75', 'twhite');
        $plotter->drawText(30, $y, '2', 'twhite');
        $plotter->drawText($dAt3, $y, '3', 'twhite');
        $plotter->drawText($dAt4, $y, '4', 'twhite');
        $plotter->drawText($dAt5, $y, '5', 'twhite');
    }
    elsif ($X_AXIS =~ /azimuth/i) {
        for (my $deg = $minX + 40; $deg < $maxX; $deg += 40) {
            $plotter->drawLine($deg, $minY, $deg, $maxY, 'grid');
            my $y = $plotter->toWy($yplot - $yborder - 10);
            $plotter->drawText($deg, $y, $deg, 'twhite');
        }
    }
    elsif ($X_AXIS =~ /parallactic angle/i) {
        for (my $deg = $minX + 40; $deg < $maxX; $deg += 40) {
            $plotter->drawLine($deg, $minY, $deg, $maxY, 'grid');
            my $y = $plotter->toWy($yplot - $yborder - 10);
            $plotter->drawText($deg, $y, $deg, 'twhite');
        }
    }

    # draw the grid lines - y axis
    if (($special == 1) || ($special == 2)) {
    }
    elsif ($Y_AXIS =~ /time/i) {
        my $ho = $timeH - 8;
        for (my $hour = $minY + $lstDiffY * 4; $hour < $maxY; $hour += $lstDiffY * 4) {
            # draw the time lines
            my $tel = $telObject;
            $plotter->drawLine($minX, $hour, $maxX, $hour, 'grid');

            # calculate the HST time
            my $ti = $ho;
            $ti -= 24 if $ti >= 24;
            $ti += 24 if $ti < 0;
            my ($h, $m) = split(/\./, $ti);
            $m = ('.' . $m) * 60;
            $m = '0' . $m if $m < 10;
            $m = '0' . $m if $m < 10;
            my $x = $plotter->toWx($xborder * 3 / 2);
            $plotter->drawText($x, $hour, sprintf("%2s:%2s", $h, $m), 'twhite');

            # calculate the ut time
            my $uh = $h + 10;
            $uh -= 24 if $uh >= 24;
            my $ux = $plotter->toWx($xplot - $xborder / 2);
            $plotter->drawText($ux, $hour, sprintf("%2s:%2s", $uh, $m), 'twhite');

            # calculate the lst time
            my $lst;
            my $si = '+';
            my @parts;
            $si = '-' if ($hour < 0);
            $lst = $hour;
            while ($lst > 2 * pi) {
                $lst -= 2 * pi;
            }
            my ($si, @hms) = palDr2tf(2, $lst);
            my ($lh, $lm, $ls, undef) = @hms;
            $lm += 1 if $ls >= 30;
            if ($lm >= 60) {
                $lm -= 60;
                $lh += 1;
                $lh -= 24 if $lh > 24;
            }
            $lm = '0' . $lm if $lm < 10;
            my $lx = $plotter->toWx($xplot - $xborder * 3 / 2);
            $plotter->drawText($lx, $hour, sprintf("%2s:%2s", $lh, $lm), 'twhite');
            $ho += 4;
        }
    }
    elsif ($Y_AXIS =~ /elevation/i) {
        for (my $deg = $minY + 20; $deg < $maxY; $deg += 10) {
            $plotter->drawLine($minX, $deg, $maxX, $deg, 'grid');
            my $x = $plotter->toWx($xborder + 10);
            $plotter->drawText($x, $deg, $deg, 'twhite');
        }
    }
    elsif ($Y_AXIS =~ /air mass/i) {
        my $dAt12 = 90 - (180 / pi * acos(1 / 1.25));
        my $dAt15 = 90 - (180 / pi * acos(1 / 1.5));
        my $dAt17 = 90 - (180 / pi * acos(1 / 1.75));
        my $x = $plotter->toWx($xborder + 15);
        for my $am (qw/1 2 3 4 5/) {
            my $dAt = 90 - (180 / pi * acos(1 / $am));
            $plotter->drawLine($minX, $dAt, $maxX, $dAt, 'grid');
            $plotter->drawText($x, $dAt, $am, 'twhite');
        }
        $plotter->drawLine($minX, $dAt12, $maxX, $dAt12, 'grid');
        $plotter->drawLine($minX, $dAt15, $maxX, $dAt15, 'grid');
        $plotter->drawLine($minX, $dAt17, $maxX, $dAt17, 'grid');
        $plotter->drawText($x, $dAt12, '1.25', 'twhite');
        $plotter->drawText($x, $dAt15, '1.5', 'twhite');
        $plotter->drawText($x, $dAt17, '1.75', 'twhite');
    }
    elsif ($Y_AXIS =~ /azimuth/i) {
        for (my $deg = $minY + 40; $deg < $maxY; $deg += 40) {
            $plotter->drawLine($minX, $deg, $maxX, $deg, 'grid');
            my $x = $plotter->toWx($xborder + 10);
            $plotter->drawText($x, $deg, $deg, 'twhite');
        }
    }
    elsif ($Y_AXIS =~ /parallactic angle/i) {
        for (my $deg = $minY + 40; $deg < $maxY; $deg += 40) {
            $plotter->drawLine($minX, $deg, $maxX, $deg, 'grid');
            my $x = $plotter->toWx($xborder + 10);
            $plotter->drawText($x, $deg, $deg, 'twhite');
        }
    }

    if (! $special) {
        # erase any mess under the y axis or to the left of the x axis
        my $bottom = $plotter->toWy($yplot + 10);
        my $top = $plotter->toWy(-10);
        my $west = $plotter->toWx(-10);
        my $east = $plotter->toWx($xplot + 10);
        $plotter->drawColor('black');
        $plotter->drawBox($west, $maxY, $east, $top, 'foblack');
        $plotter->drawBox($west, $minY, $east, $bottom, 'foblack');
        $plotter->drawBox($west, $bottom, $minX, $top, 'foblack');
        $plotter->drawBox($maxX, $bottom, $east, $top, 'foblack');

        # plot the axes and graphs - last to make look neat
        print "    Plotting the grid border and labels\n" if $locateBug;
        $plotter->drawColor('White');
        $plotter->fontColor('White');
        $plotter->drawLine($minX, $minY, $minX, $maxY, 'lwhite');
        $plotter->drawLine($minX, $minY, $maxX, $minY, 'lwhite');
        $plotter->drawLine($maxX, $minY, $maxX, $maxY, 'lwhite');
        $plotter->drawLine($minX, $maxY, $maxX, $maxY, 'lwhite');
        $plotter->raiseAbove('lwhite', 'foblack');
        $plotter->raiseAbove('twhite', 'foblack');
    }

    # label the axes
    $plotter->usingWorld(0);
    if ($special) {
    }
    elsif ($X_AXIS =~ /time/i) {
        $plotter->drawText($xplot / 2, $yplot - $yborder / 2, 'HST', 'twhite');
        $plotter->drawText($xplot / 2, $yborder, 'UT', 'twhite');
        $plotter->drawText($xplot / 2, $yborder * 2, 'LST', 'twhite');
        $plotter->drawLine($xborder, $yborder, $xplot - $xborder, $yborder, 'lwhite');
        $plotter->drawLine($xborder, $yborder, $xborder, $yborder + $YSpaceForTime, 'lwhite');
        $plotter->drawLine($xplot - $xborder, $yborder, $xplot - $xborder, $yborder + $YSpaceForTime, 'lwhite');
    }
    elsif ($X_AXIS =~ /elevation/i) {
        $plotter->usingWorld(1);
        my $yoff = $maxY + $plotter->toWy(5) - $plotter->toWy(0);
        my $toff = $plotter->toWy(10) - $plotter->toWy(0);
        $plotter->drawLine(30, $maxY, 30, $yoff, 'lwhite');
        my $dAt12 = 90 - (180 / pi * acos(1 / 1.25));
        my $dAt15 = 90 - (180 / pi * acos(1 / 1.5));
        my $dAt17 = 90 - (180 / pi * acos(1 / 1.75));
        my $dAt3 = 90 - (180 / pi * acos(1 / 3));
        my $dAt4 = 90 - (180 / pi * acos(1 / 4));
        my $dAt5 = 90 - (180 / pi * acos(1 / 5));
        $plotter->drawLine($dAt12, $maxY, $dAt12, $yoff, 'lwhite');
        $plotter->drawLine($dAt15, $maxY, $dAt15, $yoff, 'lwhite');
        $plotter->drawLine($dAt17, $maxY, $dAt17, $yoff, 'lwhite');
        $plotter->drawLine($dAt3, $maxY, $dAt3, $yoff, 'lwhite');
        $plotter->drawLine($dAt4, $maxY, $dAt4, $yoff, 'lwhite');
        $plotter->drawLine($dAt5, $maxY, $dAt5, $yoff, 'lwhite');
        $plotter->drawText(90, $maxY + $toff, '1', 'twhite');
        $plotter->drawText(30, $maxY + $toff, '2', 'twhite');
        $plotter->drawText($dAt12, $maxY + $toff, '1.25', 'twhite');
        $plotter->drawText($dAt15, $maxY + $toff, '1.5', 'twhite');
        $plotter->drawText($dAt17, $maxY + $toff, '1.75', 'twhite');
        $plotter->drawText($dAt3, $maxY + $toff, '3', 'twhite');
        $plotter->drawText($dAt4, $maxY + $toff, '4', 'twhite');
        $plotter->drawText($dAt5, $maxY + $toff, '5', 'twhite');
        $plotter->usingWorld(0);
        $plotter->drawText($xplot / 2, $yborder / 2, 'Air Mass', 'twhite');
        $plotter->drawText($xplot / 2, $yplot - $yborder / 2, 'Elevation', 'twhite');
    }
    elsif ($X_AXIS =~ /air mass/i) {
        $plotter->usingWorld(1);
        my $yoff = $maxY + $plotter->toWy(5) - $plotter->toWy(0);
        my $toff = $plotter->toWy(10) - $plotter->toWy(0);
        for (my $deg = $minX + 20; $deg < $maxX; $deg += 20) {
            $plotter->drawLine($deg, $maxY, $deg, $yoff, 'lwhite');
            $plotter->drawText($deg, $maxY + $toff, $deg, 'twhite');
        }
        $plotter->usingWorld(0);
        $plotter->drawText($xplot / 2, $yborder / 2, 'Elevation', 'twhite');
        $plotter->drawText($xplot / 2, $yplot - $yborder / 2, 'Air Mass', 'twhite');
    }
    elsif ($X_AXIS =~ /azimuth/i) {
        $plotter->drawText($xplot / 2, $yplot - $yborder / 2, 'Azimuth', 'twhite');
    }
    elsif ($X_AXIS =~ /parallactic angle/i) {
        $plotter->drawText($xplot / 2, $yplot - $yborder / 2, 'Parallactic Angle', 'twhite');
    }

    if ($special) {
    }
    elsif ($Y_AXIS =~ /time/i) {
        $plotter->usingWorld(1);
        my $y = $plotter->toPy(4) - $plotter->toPy(0);
        $plotter->usingWorld(0);
        $plotter->drawText($xborder / 2, $yplot / 2 + $y / 2, 'HST', 'twhite');
        $plotter->drawText($xplot - $xborder, $yplot / 2 + $y / 2, 'UT', 'twhite');
        $plotter->drawText($xplot - $xborder * 2, $yplot / 2 + $y / 2, 'LST', 'twhite');
        $plotter->drawLine($xplot - $xborder, $yborder, $xplot - $xborder, $yplot - $yborder, 'lwhite');
        $plotter->drawLine($xplot - $xborder, $yborder, $xplot - $xborder - $XSpaceForTime, $yborder, 'lwhite');
        $plotter->drawLine($xplot - $xborder, $yplot - $yborder, $xplot - $xborder - $XSpaceForTime, $yplot - $yborder, 'lwhite');
    }
    elsif ($Y_AXIS =~ /elevation/i) {
        $plotter->usingWorld(1);
        my $xoff = $maxX - ($plotter->toWx(5) - $plotter->toWx(0));
        my $toff = $plotter->toWx(15) - $plotter->toWx(0);
        my $dAt12 = 90 - (180 / pi * acos(1 / 1.25));
        my $dAt15 = 90 - (180 / pi * acos(1 / 1.5));
        my $dAt17 = 90 - (180 / pi * acos(1 / 1.75));
        my $dAt3 = 90 - (180 / pi * acos(1 / 3));
        my $dAt4 = 90 - (180 / pi * acos(1 / 4));
        my $dAt5 = 90 - (180 / pi * acos(1 / 5));
        my $dAt1 = 90 - (180 / pi * acos(1));
        my $dAt2 = 90 - (180 / pi * acos(1 / 2));
        $plotter->drawLine($maxX, $dAt1, $xoff, $dAt1, 'lwhite');
        $plotter->drawLine($maxX, $dAt2, $xoff, $dAt2, 'lwhite');
        $plotter->drawLine($maxX, $dAt12, $xoff, $dAt12, 'lwhite');
        $plotter->drawLine($maxX, $dAt15, $xoff, $dAt15, 'lwhite');
        $plotter->drawLine($maxX, $dAt17, $xoff, $dAt17, 'lwhite');
        $plotter->drawLine($maxX, $dAt3, $xoff, $dAt3, 'lwhite');
        $plotter->drawLine($maxX, $dAt4, $xoff, $dAt4, 'lwhite');
        $plotter->drawLine($maxX, $dAt5, $xoff, $dAt5, 'lwhite');
        $plotter->drawText($maxX - $toff, 90, '1', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt2, '2', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt12, '1.25', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt15, '1.5', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt17, '1.75', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt3, '3', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt4, '4', 'twhite');
        $plotter->drawText($maxX - $toff, $dAt5, '5', 'twhite');
        $plotter->usingWorld(0);
        $plotter->drawTextVert($xplot - $xborder / 2, $yplot / 2, 'Air Mass', 'twhite');
        $plotter->drawTextVert($xborder / 2, $yplot / 2, 'Elevation', 'twhite');
    }
    elsif ($Y_AXIS =~ /air mass/i) {
        $plotter->usingWorld(1);
        my $xoff = $maxX - ($plotter->toWx(5) - $plotter->toWx(0));
        my $x = $plotter->toWx($xplot - $xborder - 10);
        for (my $deg = $minY + 20; $deg < $maxY; $deg += 20) {
            $plotter->drawText($x, $deg, $deg, 'twhite');
            $plotter->drawLine($maxX, $deg, $xoff, $deg, 'twhite');
        }
        $plotter->usingWorld(0);
        $plotter->drawTextVert($xplot - $xborder / 2, $yplot / 2, 'Elevation', 'twhite');
        $plotter->drawTextVert($xborder / 2, $yplot / 2, 'Air Mass', 'twhite');

    }
    elsif ($Y_AXIS =~ /azimuth/i) {
        $plotter->drawTextVert($xborder / 2, $yplot / 2, 'Azimuth', 'twhite');
    }
    elsif ($Y_AXIS =~ /parallactic angle/i) {
        $plotter->drawTextVert($xborder / 2, $yplot / 2, 'Parallactic Angle', 'twhite');
    }
    $plotter->usingWorld(1);

    # now interact them
    print "    Plotting the grid lines\n" if $locateBug;
    if (($X_AXIS eq $Y_AXIS)
            || (($X_AXIS =~ /elevation/i)
                && ($Y_AXIS =~ /air mass/i))
            || (($X_AXIS =~ /air mass/i)
                && ($Y_AXIS =~ /elevation/i))) {
        $plotter->drawColor('purple');
        $plotter->drawLine($minX, $minY, $maxX, $maxY);
    }
    else {
        my ($y, $mo, $d) = split(/\//, $DATE, 3);
        my @points = ();
        my $Top;
        foreach my $source (@SOURCE_LIST) {
            if ($source->active()) {
                $source->calcPoints($DATE, $TIME, $NUM_POINTS, $MW, $telObject);
                if ($X_AXIS =~ /time/i) {
                    if (($Y_AXIS =~ /elevation/i) || ($Y_AXIS =~ /air mass/i)) {
                        @points = $source->time_ele_points();
                    }
                    elsif ($Y_AXIS =~ /azimuth/i) {
                        @points = $source->time_az_points();
                    }
                    elsif ($Y_AXIS =~ /parallactic angle/i) {
                        @points = $source->time_pa_points();
                    }
                }
                elsif (($X_AXIS =~ /elevation/i) || ($X_AXIS =~ /air mass/i)) {
                    if ($Y_AXIS =~ /time/i) {
                        @points = $source->ele_time_points();
                    }
                    elsif ($Y_AXIS =~ /azimuth/i) {
                        @points = $source->ele_az_points();
                    }
                    elsif ($Y_AXIS =~ /parallactic angle/i) {
                        @points = $source->ele_pa_points();
                    }
                }
                elsif ($X_AXIS =~ /azimuth/i) {
                    if ($Y_AXIS =~ /time/i) {
                        @points = $source->az_time_points();
                    }
                    elsif (($Y_AXIS =~ /elevation/i) || ($Y_AXIS =~ /air mass/i)) {
                        @points = $source->ele_az_points();
                    }
                    elsif ($Y_AXIS =~ /parallactic angle/i) {
                        @points = $source->az_pa_points();
                    }
                }
                elsif ($X_AXIS =~ /parallactic angle/i) {
                    if ($Y_AXIS =~ /time/i) {
                        @points = $source->pa_time_points();
                    }
                    elsif (($Y_AXIS =~ /elevation/i) || ($Y_AXIS =~ /air mass/i)) {
                        @points = $source->pa_ele_points();
                    }
                    elsif ($Y_AXIS =~ /azimuth/i) {
                        @points = $source->pa_az_points();
                    }
                }

                $plotter->penWidth($source->lineWidth());
                $plotter->penWidth($H_WIDTH) if ($H_LIGHT == $source);
                $plotter->drawColor($source->color());
                print "color plotted is " . $source->color() . "\n" if $debug;

                my @times = $source->time_ele_points();
                if (($special == 1) || ($special == 2)) {
                    my $i;
                    my $len = @points;
                    my @newpoints = ();
                    my $prevr;
                    my $prevt;
                    my $dotColor = "#55ffff";
                    for ($i = 0; $i < $len; $i += 2) {
                        my $r = $points[$i];
                        $r = 90 - $r;
                        my $theta = $points[$i + 1];
                        $theta = (90 - $theta) * pi / 180;
                        my $x = 90 + $r * cos $theta;
                        my $y = 90 + $r * sin $theta;
                        my $len2 = @newpoints;
                        if ($r < 90) {
                            if ($len2 == 0 && defined $prevr && $prevr > 90) {
                                my $dr = 90 - $r;
                                my $pdr = $prevr - 90;
                                my $nt = $dr / ($dr + $pdr) * ($prevt - $theta) + $theta;
                                my $x2 = 90 + 90 * cos $nt;
                                my $y2 = 90 + 90 * sin $nt;
                                push @newpoints, $x2;
                                push @newpoints, $y2;
                            }
                            if ($r > 60 && defined $prevr && $prevr < 60) {
                                my $time = $timeH - 12 + int($i / 2) * (24 / ($NUM_POINTS - 1));
                                $time += 24 if $time < 0;
                                $time -= 24 if $time > 24;
                                my ($h, $m) = split /\./, $time;
                                $m = ('.' . $m) * 60;
                                $m = '0' . $m if $m < 10;
                                $h = '0' . $h if $h < 10;
                                $time = sprintf "%2s:%2s", $h, $m;
                                $plotter->fontColor('#ffff00');
                                $plotter->drawText($x, $y + 3, "$time", 'time' . $source->name());
                                $plotter->drawFillOval($x - 1, $y - 1, $x + 1, $y + 1, 'fo' . $source->name());
                            }
                            elsif ($r < 60 && defined $prevr && $prevr > 60) {
                                my $time = $timeH - 12 + int($i / 2) * (24 / ($NUM_POINTS - 1));
                                my $di = 24 / ($NUM_POINTS - 1);
                                $time -= $di;
                                $time += 24 if $time < 0;
                                $time -= 24 if $time > 24;
                                my ($h, $m) = split /\./, $time;
                                $m = ('.' . $m) * 60;
                                $m = '0' . $m if $m < 10;
                                $h = '0' . $h if $h < 10;
                                $time = sprintf "%2s:%2s", $h, $m;
                                my $x2 = 90 + $prevr * cos $prevt;
                                my $y2 = 90 + $prevr * sin $prevt;
                                $plotter->fontColor('#ffff00');
                                $plotter->drawText($x2, $y2 + 3, "$time", 'time' . $source->name());
                                $plotter->drawFillOval($x2 - 1, $y2 - 1, $x2 + 1, $y2 + 1, 'fo' . $source->name());
                            }
                            $plotter->drawFillOval($x - .5, $y - .5, $x + .5, $y + .5, 'fo' . $source->name());
                            push @newpoints, $x;
                            push @newpoints, $y;
                        }
                        elsif ($len2 > 0 && defined $prevr && $prevr < 90) {
                            my $dr = $r - 90;
                            my $pdr = 90 - $prevr;
                            my $nt = $dr / ($dr + $pdr) * ($prevt - $theta) + $theta;
                            $x = 90 + 90 * cos $nt;
                            $y = 90 + 90 * sin $nt;
                            $plotter->fontColor($source->color());
                            $plotter->drawTextFromLeft($x + 5, $y, $source->name(), 't' . $source->name());
                            push @newpoints, $x;
                            push @newpoints, $y;
                            $plotter->drawSmoothLine(@newpoints, 'l' . $source->name());
                            @newpoints = ();
                        }
                        elsif (defined $len2 and $len2 >= 4) {
                            $plotter->drawSmoothLine(@newpoints, 'l' . $source->name());
                            @newpoints = ();
                        }
                        $prevr = $r;
                        $prevt = $theta;
                    }
                    @points = @newpoints;
                }
                else {
                    # give the points some labels
                    my $max = $points[1];
                    my $xm = $points[0];
                    my $len = @points;
                    my $xw = $plotter->toWx(1) - $plotter->toWx(0);
                    my $yw = $plotter->toWy(1) - $plotter->toWy(0);
                    for (my $i = 1; $i < $len; $i += 2) {
                        my $x = $points[$i - 1];
                        my $y = $points[$i];
                        $plotter->drawFillOval($x - $xw, $y - $yw, $x + $xw, $y + $yw, 'fo' . $source->name());
                        if ($points[$i] > $max) {
                            $max = $points[$i];
                            $xm = $points[$i - 1];
                        }
                    }
                    my $ya = $plotter->toWy(5) - $plotter->toWy(0);
                    $plotter->fontColor($source->color());
                    $plotter->drawTextFromLeft($xm, $max - $ya, $source->name(), 't' . $source->name());

                    my @second = ();
                    my $prevx = $points[0];
                    my $prevy = $points[1];
                    my $plotNow = 0;
                    for (my $i = 3; $i < $len; $i += 2) {
                        my $x = $points[$i - 1];
                        my $y = $points[$i];
                        my $plotx = $x;
                        my $ploty = $y;
                        my $plotxn = $x;
                        my $plotyn = $y;
                        push(@second, $prevx);
                        push(@second, $prevy);

                        if ($Y_AXIS =~ /parallactic angle/i) {
                            if ($prevy < -80 && $y > 80) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $ploty = $y - 360;
                                    $plotyn = $prevy + 360;
                                    $plotNow = 1;
                                }
                            }
                            elsif ($y < -80 && $prevy > 80) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $ploty = $y + 360;
                                    $plotyn = $prevy - 360;
                                    $plotNow = 1;
                                }
                            }
                        }
                        elsif ($X_AXIS =~ /parallactic angle/i) {
                            if ($prevx < -80 && $x > 80) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $plotx = $x - 360;
                                    $plotxn = $prevx + 360;
                                    $plotNow = 1;
                                }
                            }
                            elsif ($x < -80 && $prevx > 80) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $plotx = $x + 360;
                                    $plotxn = $prevx - 360;
                                    $plotNow = 1;
                                }
                            }
                        }
                        if ($Y_AXIS =~ /azimuth/i) {
                            if ($prevy < 100 && $y > 260) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $ploty = $y - 360;
                                    $plotyn = $prevy + 360;
                                    $plotNow = 1;
                                }
                            }
                            elsif ($y < 100 && $prevy > 260) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $ploty = $y + 360;
                                    $plotyn = $prevy - 360;
                                    $plotNow = 1;
                                }
                            }
                        }
                        elsif ($X_AXIS =~ /azimuth/i) {
                            if ($prevx < 100 && $x > 260) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $plotx = $x - 360;
                                    $plotxn = $prevx + 360;
                                    $plotNow = 1;
                                }
                            }
                            elsif ($x < 100 && $prevx > 260) {
                                my $len2 = @second;
                                if ($len2 > 0) {
                                    $plotx = $x + 360;
                                    $plotxn = $prevx - 360;
                                    $plotNow = 1;
                                }
                            }
                        }

                        if ($plotNow) {
                            $plotNow = 0;
                            push @second, $plotx;
                            push @second, $ploty;
                            $plotter->drawSmoothLine(@second, 'l' . $source->name());
                            @second = ();
                            push @second, $plotxn;
                            push @second, $plotyn;
                        }
                        elsif ($i == $len - 1) {
                            push @second, $x;
                            push @second, $y;
                        }

                        $prevx = $x;
                        $prevy = $y;
                    }
                    @points = @second;

                }
                my $len2 = @points;
                $plotter->drawSmoothLine(@points, 'l' . $source->name())
                    if ($len2 > 0);

                my @bold = (
                    '-background' => "#bbbbbb",
                    '-foreground' => 'black',
                    '-relief' => 'raised',
                    '-borderwidth' => 1,
                );
                my @normal = (
                    '-background' => undef,
                    '-foreground' => $source->color(),
                    '-relief' => 'flat',
                );
                $plotter->bindTag(
                    'l' . $source->name(),
                    '<Any-Enter>' => sub {
                        my $s = $source;
                        if ($s->active()) {
                            $EditWin->{'Text'}->tag('configure', 'd' . $s->index(), @bold)
                                if $EDIT_OPEN;
                            $plotter->configureTag('l' . $s->name(), -width => 3);
                        }
                    },
                );
                $plotter->bindTag(
                    'l' . $source->name(),
                    '<Any-Leave>' => sub {
                        my $s = $source;
                        if ($s->active()) {
                            $EditWin->{'Text'}->tag('configure', 'd' . $s->index(), @normal)
                                if $EDIT_OPEN;
                            $plotter->configureTag('l' . $s->name(), -width => 1);
                        }
                    },
                );
            }
            $plotter->penWidth(1);

            #calculate where the time dots go.
            calcTime($source);

            if ($plotter->existTag('foblack')) {
                if ($plotter->existTag('timeDot' . $source->name())) {
                    $plotter->raiseAbove('timeDot' . $source->name(), 'l' . $source->name());
                    $plotter->raiseAbove('foblack', 'timeDot' . $source->name());
                }
                elsif ($plotter->existTag('l' . $source->name())) {
                    $plotter->raiseAbove('foblack', 'l' . $source->name());
                }
                $plotter->raiseAbove('t' . $source->name(), 'foblack')
                    if $plotter->existTag('t' . $source->name());
                $plotter->raiseAbove('lwhite', 'foblack');
                $plotter->raiseAbove('twhite', 'foblack');
            }
            else {
                $plotter->raiseAbove('lwhite', 'l' . $source->name())
                    if $plotter->existTag('l' . $source->name());
                $plotter->raiseAbove('twhite', 'l' . $source->name())
                    if $plotter->existTag('l' . $source->name());
            }
        }

        calcTime('TelescopePosition');

        if (defined $Top) {
            destroy $Top;
        }
        $plotter->penWidth(1);
    }

    print "Exit plot\n" if $locateBug;
}

=item B<am_to_deg>

Converts air mass to degrees.

=cut

sub am_to_deg {
    (180 / pi) * asin(1 / $_[0]);
}

=item B<getColor>

Returns a color.

=cut

sub getColor {
    my $color = $COLOR_LIST[$COLOR_INDEX];
    my $len = @COLOR_LIST;
    $COLOR_INDEX ++;
    $COLOR_INDEX = $COLOR_INDEX % $len;
    return $color;
}

=item B<calcTime>

Draws a dot at the current time on each source.

=cut

sub calcTime {
    $TIMER->cancel if defined $TIMER;
    my $so = shift;

    my ($sources, $telsource);
    if (defined $so) {
        if (ref $so) {
            $sources = [[$so, 'drawFillOval', 1]];
        }
        elsif ('TelescopePosition' eq $so) {
            $sources = [];
            $telsource = $TELPOSN->get_position() if defined $TELPOSN;
        }
        else {
            die 'Unexpected source parameter';
        }
    }
    else {
        $sources = [map {[$_, 'drawFillOval', 1]} @SOURCE_LIST];
        $telsource = $TELPOSN->get_position() if defined $TELPOSN;
    }

    if (defined $telsource) {
        $telsource->color('#ffffff');
        push @$sources, [$telsource, 'drawOval', 3];
    }

    my $timeBug = 0;
    my ($ss, $mm, $hh, $md, $mo, $yr, $wd, $yd, $isdst) = gmtime(time);
    $mo ++;  # this catches the month up to the current date
    $mo = '0' . $mo if length($mo) < 2;
    $md = '0' . $md if length($md) < 2;
    $mm = '0' . $mm if length($mm) < 2;
    $ss = '0' . $ss if length($ss) < 2;
    $yr += 1900;
    my ($sety, $setm, $setd) = split(/\//, $DATE);

    if ((! $yr =~ /$sety/) || $setm != $mo || $setd != $md) {
        return;
    }
    print "The gm time is $hh:$mm:$ss and date is $yr\/$mo\/$md\n" if $timeBug;

    #calculate the local time
    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y/%m/%d %H:%M:%S',
        on_error => 'croak');

    my $dt = $strp->parse_datetime("$yr\/$mo\/$md $hh:$mm:$ss");

    $dt->subtract(hours => 10);

    my $t = $dt->strftime('%H:%M:%S');
    my $d = $dt->strftime('%Y/%m/%d');

    $plotter->drawColor('white');
    foreach my $sourceinfo (@$sources) {
        my ($source, $plotstyle, $radiusscale) = @$sourceinfo;
        next unless $source->active();

        $plotter->delete('timeDot' . $source->name());

        print "Real time = $TIME and real date = $DATE\n" if $timeBug;
        print "Date = $d and time = $t before calcpoint\n" if $timeBug;
        my ($lst, $ele, $az, $pa, $elex, $eley, $azx, $azy) = $source->calcPoint($d, $t, $telObject);

        if ($lst < $minX) {
            $lst += 2 * pi;
        }
        elsif ($lst > $maxX) {
            $lst -= 2 * pi;
        }

        my ($x, $y);

        if ($X_AXIS =~ /time/i) {
            $x = $lst;
        }
        elsif (($X_AXIS =~ /elevation/i) || ($X_AXIS =~ /air mass/i)) {
            $x = $ele;
        }
        elsif ($X_AXIS =~ /azimuth/i) {
            $x = $az;
        }
        elsif ($X_AXIS =~ /parallactic angle/i) {
            $x = $pa;
        }

        if ($Y_AXIS =~ /time/i) {
            $y = $lst;
        }
        elsif (($Y_AXIS =~ /elevation/i) || ($Y_AXIS =~ /air mass/i)) {
            $y = $ele;
        }
        elsif ($Y_AXIS =~ /azimuth/i) {
            $y = $az;
        }
        elsif ($Y_AXIS =~ /parallactic angle/i) {
            $y = $pa;
        }

        if ((($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /elevation/i))
                || (($X_AXIS =~ /azimuth/i) && ($Y_AXIS =~ /elevation/i))
                || (($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /air mass/i))
                || (($Y_AXIS =~ /air mass/i) && ($X_AXIS =~ /azimuth/i))) {
            $x = $ele;
            $y = $az;
        }

        $source->timeDotX($x);
        $source->timeDotY($y);

        $elex = $plotter->toWx($elex) - $plotter->toWx(0);
        $eley = $plotter->toWy($eley) - $plotter->toWy(0);
        $azx = $plotter->toWx($azx) - $plotter->toWx(0);
        $azy = $plotter->toWy($azy) - $plotter->toWy(0);

        # draw the time dot
        if ($ele > 0) {
            $source->AzElOffsets($elex, $eley, $azx, $azy);
            plot_time_dot($source, $plotstyle, $radiusscale);
        }
    }

    $TIMER = $MW->after($TimeLap, \&calcTime);
}

sub plot_time_dot {
    my $source = shift;
    my $plotstyle = shift;
    my $radiusscale = shift;

    my ($elex, $eley, $azx, $azy) = $source->AzElOffsets();

    $plotter->drawColor($source->color());
    if ((($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /elevation/i))
            || (($X_AXIS =~ /azimuth/i) && ($Y_AXIS =~ /elevation/i))
            || (($Y_AXIS =~ /azimuth/i) && ($X_AXIS =~ /air mass/i))
            || (($Y_AXIS =~ /air mass/i) && ($X_AXIS =~ /azimuth/i))) {
        my $sX = my $sY = 2 * $radiusscale;
        my $r = 90 - $source->timeDotX();
        if ($r < 90) {
            my $theta = (90 - $source->timeDotY()) * pi / 180;
            my $x2 = 90 + $r * cos $theta;
            my $y2 = 90 + $r * sin $theta;
            $plotter->$plotstyle($x2 - $sX, $y2 - $sY, $x2 + $sX, $y2 + $sY, 'timeDot' . $source->name());
            $plotter->bindTag(
                'timeDot' . $source->name(),
                '<Any-Enter>' => sub {
                },
            );
            $plotter->bindTag(
                'ltimeDot' . $source->name(),
                '<Any-Leave>' => sub {
                },
            );
        }
    }
    else {
        my ($sX, $sY) = $plotter->toW($dotSizeX, $dotSizeY);
        $sX = ($sX - $plotter->toWx(0)) * $radiusscale;
        $sY = ($sY - $plotter->toWy(0)) * $radiusscale;
        my $x2 = $source->timeDotX();
        my $y2 = $source->timeDotY();
        if ($x2 ne '' && $y2 ne '') {
            $plotter->$plotstyle($x2 - $sX, $y2 - $sY, $x2 + $sX, $y2 + $sY, 'timeDot' . $source->name());
            $plotter->bindTag(
                'timeDot' . $source->name(),
                '<Any-Enter>' => sub {
                    $plotter->drawColor($source->color());
                    $plotter->drawFillOval($x2 - $sX, $y2 - $sY, $x2 + $sX, $y2 + $sY, 'ltimeDot' . $source->name());
                    # draw AZ-EL pointers
                    $plotter->drawColor('red');
                    $plotter->fontColor('red');
                    $plotter->penWidth(2);
                    $plotter->drawLine($x2 - $elex, $y2 - $eley, $x2, $y2, 'ltimeDot' . $source->name());
                    $plotter->drawLine($x2 - $azx, $y2 - $azy, $x2, $y2, 'ltimeDot' . $source->name());
                    $plotter->penWidth(1);
                    my ($xoff, $yoff) = $plotter->toW(7, 7);
                    $xoff -= $plotter->toWx(0);
                    $yoff -= $plotter->toWy(0);
                    $plotter->drawText($x2 - $elex - $xoff, $y2 - $eley - $yoff, 'El', 'ltimeDot' . $source->name());
                    # and RA-Dec box
                    my $bx = 1.5 * sqrt($azx * $azx + $elex * $elex);
                    my $by = 1.5 * sqrt($azy * $azy + $eley * $eley);
                    $plotter->drawLine($x2 - $bx, $y2 - $by, $x2 - $bx, $y2 + $by, 'ltimeDot' . $source->name());
                    $plotter->drawLine($x2 - $bx, $y2 + $by, $x2 + $bx, $y2 + $by, 'ltimeDot' . $source->name());
                    $plotter->drawLine($x2 + $bx, $y2 + $by, $x2 + $bx, $y2 - $by, 'ltimeDot' . $source->name());
                    $plotter->drawLine($x2 + $bx, $y2 - $by, $x2 - $bx, $y2 - $by, 'ltimeDot' . $source->name());
                    $plotter->drawText($x2, $y2 - 1.2 * $by, 'R.A.', 'ltimeDot' . $source->name());
                    $plotter->drawText($x2 - 1.12 * $bx, $y2 + 0.2 * $by, 'D', 'ltimeDot' . $source->name());
                    $plotter->drawText($x2 - 1.1 * $bx, $y2, 'e', 'ltimeDot' . $source->name());
                    $plotter->drawText($x2 - 1.1 * $bx, $y2 - 0.2 * $by, 'c', 'ltimeDot' . $source->name());
                    $plotter->fontColor($source->color());
                },
            );
            $plotter->bindTag(
                'ltimeDot' . $source->name(),
                '<Any-Leave>' => sub {
                    $plotter->delete('ltimeDot' . $source->name());
                },
            );
        }
    }
}

=item B<tagOnOff>

Configures all object with the tag name off or on.

=cut

sub tagOnOff {
    my $tag = shift;
    my $turnOn = shift;
    my $color = shift;
    my $color2 = shift;

    if (! $turnOn) {
        $plotter->configureTag('l' . $tag, -fill => 'black');
        $plotter->configureTag('fo' . $tag, -fill => 'black', outline => 'black');
        $plotter->configureTag('o' . $tag, outline => 'black');
        $plotter->configureTag('t' . $tag, -fill => 'black');
        $plotter->configureTag('time' . $tag, -fill => 'black');
        $plotter->configureTag('timeDot' . $tag, -fill => 'black', -outline => 'black');
        if (! ($tag =~ /(white)/i)) {
            $plotter->lowerBelow('l' . $tag, 'grid');
            $plotter->lowerBelow('o' . $tag, 'grid');
            $plotter->lowerBelow('fo' . $tag, 'grid');
            $plotter->lowerBelow('t' . $tag, 'grid');
            $plotter->lowerBelow('time' . $tag, 'grid');
            $plotter->lowerBelow('timeDot' . $tag, 'grid');
        }
    }
    else {
        $plotter->configureTag('l' . $tag, -fill => $color);
        $plotter->configureTag('fo' . $tag, -fill => $color, outline => $color);
        $plotter->configureTag('o' . $tag, outline => $color);
        $plotter->configureTag('timeDot' . $tag, -fill => $color, outline => $color);
        $plotter->configureTag('t' . $tag, -fill => $color);
        if (defined $color2) {
            $plotter->configureTag('time' . $tag, -fill => $color2);
        }
        else {
            $plotter->configureTag('time' . $tag, -fill => $color);
        }
        $plotter->raiseAbove('l' . $tag, 'grid');
        $plotter->raiseAbove('o' . $tag, 'grid');
        $plotter->raiseAbove('fo' . $tag, 'grid');
        $plotter->raiseAbove('t' . $tag, 'grid');
        $plotter->raiseAbove('time' . $tag, 'grid');
        $plotter->raiseAbove('timeDot' . $tag, 'grid');
    }
}

=item B<inswt>

The "Insert With Tags" procedure inserts text into a given text widget
and applies one or more tags to that text.

Parameters:

    $w     -  Window in which to insert
    $text  -  Text to insert (it's inserted at the "insert" mark)
    $args  -  One or more tags to apply to text.  If this is empty
              then all tags are removed from the text.

Returns:  Nothing

=cut

sub inswt {
    my ($w, $text, @args) = @_;
    my $start = $w->index('insert');

    $w->insert('insert', $text);
    foreach my $tag ($w->tag('names', $start)) {
        $w->tag('remove', $tag, $start, 'insert');
    }
    foreach my $i (@args) {
        $w->tag('add', $i, $start, 'insert');
    }
}

1;

__END__

=back

=head1 SEE ALSO

L<Astro::Coords>
L<Astro::Catalog>
L<Tk::AstroCatalog>

=head1 AUTHORS

Casey Best (University of Victoria),
Pam Shimek (University of Victoria),
Tim Jenness (Joint Astronomy Centre),
Remo Tilanus (Joint Astronomy Centre),
Graham Bell (Joint Astronomy Centre / East Asian Observatory).

=head1 COPYRIGHT

Copyright (C) 2016-2018 East Asian Observatory.
Copyright (C) 2012, 2013 Science and Technology Facilities Council.
Copyright (C) 1998, 1999 Particle Physics and Astronomy Research
Council. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut
