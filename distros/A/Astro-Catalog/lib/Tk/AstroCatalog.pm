package Tk::AstroCatalog;

=head1 NAME

Tk::SourceCatalog - creates a self-standing sources catalog widget

=head1 SYNOPSIS

  use Tk::AstroCatalog;

  $cat = new Tk::AstroCatalog($MW, $addCmd, $upDate, $onDestroy);

=head1 DESCRIPTION

Tk::AstroCatalog creates a non-editable text widget, displaying
sources from a default catalog or user-selected catalog file.

=cut

use 5.004;
use strict;
use Math::Trig qw/pi/;
use Carp;
use Astro::Catalog;
use Astro::Catalog::Star;
use Astro::Coords 0.12;
use Tk;
use Tk::FileSelect;

my $locateBug = 0;
my $BUSY = 0;
my @COLOR_LIST = ('#ffAAAA', '#00ff00', '#ff55ff', '#ffff00', '#00ffff',
'#ff00ff', '#ffffff', '#ff5555', '#55ff55', '#55ffff', '#ffff55');
my $COLOR_INDEX = 0;

use vars qw/$VERSION $FORMAT/;

$VERSION = '4.32';

# Kluge - this is the format of the catalog to be read
# Needs to be given as an option on the FileSelect widget.
$FORMAT = 'JCMT';

=head1 PUBLIC METHODS

Methods available in this class:

=over 4

=item new

Create a new Tk::AstroCatalog object.  A new catalog object will be
created.  Callbacks must be specified for -addCmd and -upDate; a
warning is issued for -onDestroy when it is missing.

  $cat = new Tk::AstroCatalog($MW,
                            -addCmd => $addCmd,
                            -upDate => $upDate,
                            -onDestroy => $onDestroy);

Additionally a pre-existing Astro::Catalog object can be supplied
using the "-catalog" option.

  $cat = new Tk::AstroCatalog($MW,
                            -addCmd => $addCmd,
                            -upDate => $upDate
                            -catalog => $cat,
                           );

The "-transient" option can be used if only a single value is required
from the widget. Default behaviour is for the widget to be
permanent. The "-transient" button does not have a "Done" button on
the screen (ie no button to close the window without a selection)

The "-addCmd" callback is triggered whenever a source is selected
from the widget. If the widget is transient the widget will be
closed after the first add is triggered.

The "-onDestroy" callback is triggered when the "Done" button is
pressed.

The "-upDate" method is triggered whenever the contents of the
catalog widget are refreshed/updated.

It makes more sense for this widget to work like Tk::FileSelect
when used in transient mode since we want to get the answer back
rather than enter an event loop.

The "-customColumns" method can be used to add additional columns
to the display.  This is an array of hashes specifying the
title, width and generator function for each column.  This generating
function will be called with an Astro::Catalog::Item and must
return a string of the given width.

  -customColumns => [{title     => 'Example',
                      width     => 7,
                      generator => sub {
                                     my $item = shift;
                                     return sprintf('%7s', 'test');
                                   }},
                    ]

=cut

###############################################################
#  SourceCatalog creates a windows that displays the contents
#  of a catalog and allows the user to select as many entries
#  in it as the user wishes.
#
sub new {
  my $class = shift;
  croak "CatWin usage: Missing args \n" unless (@_);
  my $MW = shift;
  my %defaults = (
                  -default => 'defaults',
                  -transient => 0,
                  @_);

#  use Data::Dumper;
#  print Dumper(\%defaults);
  croak "Tk::AstroCatalog -addCmd option missing \n" unless(exists $defaults{'-addCmd'});
  croak "Tk::AstroCatalog -upDate option missing \n" unless(exists $defaults{'-upDate'});
  warn "Tk::AstroCatalog -onDestroy option missing \n" unless(exists $defaults{'-onDestroy'});

  my $self = {};

  if (exists $defaults{'-catalog'}) {
    $self->{CatClass} = ref($defaults{'-catalog'});
    $self->{Catalog} = $defaults{'-catalog'};
  } else {
    # use default settings
    $self->{CatClass} = 'Astro::Catalog';
    $self->{Catalog} = $self->{CatClass}->new();
  }

  $self->{UpDate} = undef;
  $self->{Reset} = undef;
  $self->{AddCommand} = undef;
  $self->{Toplevel} = $MW->Toplevel;
  $self->{Selected} = [];
  $self->{Text} = undef;
  $self->{File} = 'default';
  $self->{Transient} = $defaults{'-transient'};
  $self->{RefLabel} = '';

  if (exists $defaults{'-customColumns'}) {
    # Store whole hash rather than just generator function
    # in case we want to add other ways of specifying custom columns.
    my $cols = $self->{CustomColumns} = $defaults{'-customColumns'};
    croak "Tk::AstroCatalog -customColumns must be an array ref"
        unless 'ARRAY' eq ref $cols;

    my $headings = '';
    foreach my $col (@$cols) {
      $headings .= sprintf('%-'.$col->{'width'}.'s ', $col->{'title'});
    }

    $self->{CustomHeadings} = $headings;
    $self->{CustomWidth} = length($headings);
  }
  else {
    $self->{CustomColumns} = undef;
    $self->{CustomHeadings} = '';
    $self->{CustomWidth} = 0;
  }


  bless $self, $class;
  $self->Reset($defaults{'-onDestroy'}) if exists $defaults{'-onDestroy'};
  $self->AddCommand($defaults{'-addCmd'});
  $self->UpDate($defaults{'-upDate'});

  $self->makeCatalog();
  return $self;
}

#
#  Common data manipulation functions
#

=item Catalog

Returns and sets the Astro::Catalog object.

  $catalog = $cat->Catalog();
  $cat->Catalog(new Astro::Catalog(...));

=cut

sub Catalog {
        my $self = shift;
        if(@_)
        {
                my $cat = shift;
                if (UNIVERSAL::isa($cat,'Astro::Catalog'))
                {
                  $self->{Catalog} = $cat;
                }
                else
                {
                  croak "Tk::AstroCatalog: Catalog must be of type Astro::Catalog \n";
                }
        }
        return $self->{Catalog};
}

=item AddCommand

returns and sets the AddCommand callback code for the catalog

  $addCommand = $cat->AddCommand();
  $cat->AddCommand($addCommand);

=cut

sub AddCommand
{
        my $self = shift;
        if(@_)
        {
                my $cmd = shift;
                if (ref($cmd) eq 'CODE')
                {
                        $self->{AddCommand} = $cmd;
                }
                else
                {
                        croak "CatWin: AddCommand must be of type Code Ref \n";
                }
        }
        return $self->{AddCommand};
}

=item UpDate

returns and sets the UpDate callback code for the catalog

  $update = $cat->UpDate();
  $cat->UpDate($update);

Called whenever the contents of the text widget are redisplayed.
The first argument will be the current object.

=cut

sub UpDate
{
        my $self = shift;
        if(@_)
        {
                my $cmd = shift;
                if (ref($cmd) eq 'CODE')
                {
                        $self->{upDate} = $cmd;
                }
                else
                {
                        croak "CatWin: upDate must be of type Code Ref \n";
                }
        }
        return $self->{upDate};
}

=item Reset

returns and sets the onDestroy callback code for the catalog

  $reset = $cat->Reset();
  $cat->Reset($reset);

=cut

sub Reset
{
        my $self = shift;
        if(@_)
        {
                my $cmd = shift;
                if (ref($cmd) eq 'CODE')
                {
                        $self->{Reset} = $cmd;
                }
                else
                {
                        croak "CatWin: Reset must be of type Code Ref \n";
                }
        }
        return $self->{Reset};
}

=item Toplevel

returns and sets the name of the Toplevel

  $toplevel = $cat->Toplevel();
  $cat->Toplevel($top);

=cut

sub Toplevel
{
        my $self = shift;
        if(@_)
        {
                $self->{Toplevel} = shift;
        }
        return $self->{Toplevel};
}

=item Transient

returns and sets whether the widget should be destroyed after the
next Add.

  $toplevel = $cat->Transient();
  $cat->Transient($top);

=cut

sub Transient
{
        my $self = shift;
        if(@_)
        {
                $self->{Transient} = shift;
        }
        return $self->{Transient};
}

=item Text

returns and sets the name of the Text

  $text = $cat->Text();
  $cat->Text($text);

=cut

sub Text {
        my $self = shift;
        if(@_)
        {
                my $cat = shift;
                if (UNIVERSAL::isa($cat,'Tk::Frame'))
                {
                        $self->{Text} = $cat;
                }
                else
                {
                        croak "CatWin: Text widget must be of type Tk::Frame \n";
                }
        }
        return $self->{Text};
}

=item RefLabel

Configure the text displayed in the reference label widget.
Usually a summary of the reference position.

  $self->RefLabel

Returns a reference to a scalar that can be used to associate
the value with a widget.

=cut

sub RefLabel {
  my $self = shift;
  if (@_) {
    $self->{RefLabel} = shift;
  }
  return \$self->{RefLabel};
}

=item CatClass

returns and sets the name of the CatClass

  $class = $cat->CatClass();
  $cat->CatClass($class);

=cut

sub CatClass {
        my $self = shift;
        if(@_)
        {
                $self->{CatClass} = shift;
        }
        return $self->{CatClass};
}

=item Selected

returns the Selected array or the indexed value of this array

  @selected = $cat->Selected();
  $value = $cat->Selected($index);

=cut

sub Selected
{
        my $self = shift;
        if(@_)
        {
                my $index = shift;
                if(@_)
                {
                        $self->{Selected}->[$index] = shift;
                }
                return $self->{Selected}->[$index];
        }
        return $self->{Selected};
}

=item file

returns and sets the File name

  $file = $cat->file();
  $cat->file($filename);

=cut

sub file
{
        my $self = shift;
        if (@_)
        {
                $self->{File} = shift;
        }
        return $self->{File};
}

=item makeCatalog

makeCatalog creates a window that displays the
contents of a catalog and allows the user to select as
many entries as the user wishes.

  $catalog = $cat->makeCatalog();
  $catalog = $cat->makeCatalog($selected);

=cut

sub makeCatalog
{
  my $self = shift;
  my $selected = $self->{Selected};
  my $Top = $self->Toplevel;
  $Top->geometry('+600+437');
  $Top->title('Source Plot: Catalog Window');
  $Top->resizable(0,0);

  print "made the catalog window\n" if $locateBug;

  my @Sources;
  my $topFrame = $Top->Frame(-relief=>'groove', -borderwidth =>2, -width =>50)->pack(-padx=>10, -fill => 'x', -ipady=>3, -pady => 10);

  # create the header
  my $headFrame = $topFrame->Frame(-relief=>'flat', -borderwidth =>2)->grid(-row=>0, -sticky=>'nsew', -ipadx => 3);
  my $head = $topFrame->Text(
      -wrap       => 'none',
      -relief     => 'flat',
      -foreground => 'midnightblue',
      -width      => 90 + $self->{'CustomWidth'},
      -height     => 1,
      -font       => '-*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*',
      -takefocus  => 0
  )->grid (-sticky=>'ew', -row =>0);
  my $title = sprintf "%5s  %-16s  %-12s  %-13s  %-4s %-3s %-3s %-5s %s%s",
                      'Index', 'Name', 'Ra', 'Dec', 'Epoc', 'Az', 'El', 'Dist',
                      $self->{'CustomHeadings'}, "Comment";
  $head->insert ('end', $title);
  $head->configure(-state=>'disabled');

  print "just about to make the scrollable text\n" if $locateBug;

  # create the text scrollable window
  my $T = $topFrame->Scrolled('Text',
                              -scrollbars => 'e',
                              -wrap       => 'none',
                              -width      => 100 + $self->{'CustomWidth'},
                              -height     => 15,
                              -font       => '-*-Courier-Medium-R-Normal--*-120-*-*-*-*-*-*',
                              -setgrid    => 1,
                             )->grid(qw/-sticky nsew/);
  $T->bindtags(qw/widget_demo/);  # remove all bindings but dummy "widget_demo"
  $self->Text($T);
  print "just before creating the done button\n" if $locateBug;

  # KLUGE with a global reference label for now
  my $RefLabel = $topFrame->Label( -textvariable => $self->RefLabel,
                                     -width => 64,
                                   )->grid(-sticky=>'nsew',-row=>2);

  # Create button frame
  my $buttonF2 = $Top->Frame->pack(-padx=>10, -fill =>'x');
  my $buttonF = $Top->Frame->pack(-padx=>10, -pady=>10);

  # create the Done button if we are not transient
  if (!$self->Transient) {
    my $dBut = $buttonF->Button(
                                -text         => 'Done',
                                -command      => sub{ $self->destroy }
                               )->pack(-side=>'right');
  }

  # create the Add button
  my $addBut = $buttonF->Button( -text=>'Add',
                    -relief => 'raised',
                    -width        => 7,
                    -command => sub {
                        my $callback = $self->AddCommand;
                        my $selected = $self->Selected;
                        # turn off tags
                        foreach my $one (@$selected) {
                          # KLUGE source does not have index attribute
                          $T->tag('configure', 'd'.$one->{index}, -foreground => 'blue');
                        }
                        #$callback->(@$selected);
                        $callback->($selected);

                        if ($self->Transient) {
                          # game over (should be a sub)
                          $self->destroy;
                        }
                })->pack(-side=>'right', -padx=>20);

  # create the Search button
  my $searchBut;
  $searchBut = $buttonF->Button( -text=>'Search',
                    -relief => 'raised',
                    -width        => 7,
                    -command => sub {
                      $searchBut->configure(-state=>'disabled');
                      $self->getSource($self->Toplevel->Toplevel,$searchBut);
                    })->pack(-side=>'right');

  # declared for the catalog file
  my $catEnt;

  # create the Rescan button
  my $rescanBut = $buttonF->Button( -text=>'Rescan',
                    -relief => 'raised',
                    -width        => 7,
                    -command => sub {
                      $self->file($catEnt->get);
                      # reset current array to original list
                      $self->Catalog->reset_list;
                      $self->fillWithSourceList ('full');
                    })->pack(-side=>'right', -padx =>'20');

  # create the Sort menu
  my $sortmenu = $buttonF->Menubutton(-text=>'Sort by', -relief=>'raised', -width=>7);
  $sortmenu->command(-label=>'Unsorted', -command=> sub {
                        $self->Catalog->sort_catalog('unsorted');
                        $self->fillWithSourceList ('full');
                        });
  $sortmenu->command(-label=>'Id', -command=> sub {
                        $self->Catalog->sort_catalog('id');
                        $self->fillWithSourceList ('full');
                        });
  $sortmenu->command(-label=>'Ra', -command=> sub {
                        $self->Catalog->sort_catalog('ra');
                        $self->fillWithSourceList ('full');
                        });
  $sortmenu->command(-label=>'Dec', -command=> sub {
                        $self->Catalog->sort_catalog('dec');
                        $self->fillWithSourceList ('full');
                        });
  $sortmenu->command(-label=>'Az', -command=> sub {
                        $self->Catalog->sort_catalog('az');
                        $self->fillWithSourceList ('full');
                        });
  $sortmenu->command(-label=>'El', -command=> sub {
                        $self->Catalog->sort_catalog('el');
                        $self->fillWithSourceList ('full');
                        });
  # add sort by distance if we have a reference position
  if ($self->Catalog->reference) {
    $sortmenu->command(-label=>'Distance', -command=> sub {
                         $self->Catalog->sort_catalog('distance');
                         $self->fillWithSourceList ('full');
                       });
    $sortmenu->command(-label=>'Distance in Az', -command=> sub {
                         $self->Catalog->sort_catalog('distance_az');
                         $self->fillWithSourceList ('full');
                       });
  }


  $sortmenu->pack(-side=>'right', -padx=>'20');

  # create the catalog menu button
  my $catB = $buttonF2->Menubutton( -text=>'Catalogs', -relief => 'raised', -width => 8);
  $catB->command(-label =>'Default Catalog', -command=> sub{
                   $self->file ('default');
                   $catEnt->delete ('0','end');
                   $catEnt->insert(0,$self->file);
                   # $MW->update;
                   # No filename for default
                   $self->Catalog($self->CatClass->new(
                                                       Format => $FORMAT,
                                                      ));
                   $self->fillWithSourceList ('full');
                  });
  $catB->command(-label =>'File Catalog', -command=> sub{
                   my $dir;
                   chomp($dir = `pwd`);
                   my $win = $Top->FileSelect(-directory => $dir);;
                   my $file = $win->Show;
                   if (defined $file && $file ne '') {
                     $catEnt->delete ('0','end');
                     $catEnt->insert('0', $file);

                     # Get the current catalogue properties [should be a sub]
                     my $oldcat = $self->Catalog;
                     my ($refc, $canobs);
                     if (defined $oldcat) {
                       $refc = $oldcat->reference;
                       $canobs = $oldcat->auto_filter_observability;
                     }

                     $self->file($file);
                     $self->Catalog($self->CatClass->new(File =>$self->file,
                                                         Format => $FORMAT
                                                        ));

                     # Propogate previous info
                     $self->Catalog->reference( $refc ) if defined $refc;
                     $self->Catalog->auto_filter_observability( $canobs );
                     $self->Catalog->reset_list;

                     $self->fillWithSourceList ('full');
                   }
                  });
  $catB->pack (-side=>'left',-padx =>10);

  # Create the catalog file label
  $buttonF2->Label (
                     -text => "Catalog file:",
                    )->pack(-side=>'left');
  $catEnt = $buttonF2->Entry(-relief=>'sunken',
                                -width=>37)->pack(-side=>'left', -padx =>10);
  $catEnt->bind('<KeyPress-Return>' =>sub {
                  # Get the current catalogue properties [should be a sub]
                  my $oldcat = $self->Catalog;
                  my ($refc, $canobs);
                  if (defined $oldcat) {
                    $refc = $oldcat->reference;
                    $canobs = $oldcat->auto_filter_observability;
                  }

                  $self->file($catEnt->get);
                  if ($catEnt->get eq 'default') {
                    $self->Catalog($self->CatClass->new(
                                                        Format => $FORMAT
                                                       ));
                  } else {
                    $self->Catalog($self->CatClass->new(File => $self->file,
                                                        Format => $FORMAT
                                                       ));
                  }
                  # Propogate previous info
                  $self->Catalog->reference( $refc ) if defined $refc;
                  $self->Catalog->auto_filter_observability( $canobs );
                  $self->Catalog->reset_list;

                  $self->fillWithSourceList ('full');
                });
  $catEnt->insert(0,$self->file);

  print "made it past all the buttons and just about to fill...\n" if $locateBug;
  # if we do not have a catalog yet create one
  unless ($self->Catalog) {
    $self->file($catEnt->get);
    $self->Catalog($self->CatClass->new( File => $self->file,
                                         Format => $FORMAT
                                       ));
  }
  $self->fillWithSourceList ('full');

  return $self;

}

=item destroy

Remove the widget from display. Leaves calling the
Reset handler to the DESTROY method.

=cut

sub destroy {
  my $self = shift;
  my $Top = $self->Toplevel;
  $Top->destroy() if defined $Top && Exists($Top);
}

=item DESTROY

Object destructor. Triggers when the object is destroyed.
Guarantees to destroy the Toplevel widget and does trigger
the onDestroy callback.

=cut

sub DESTROY {
  my $self = shift;
  my $callback = $self->Reset;
  $callback->() if defined $callback;
  my $Top = $self->Toplevel;
  $Top->destroy() if defined $Top && Exists($Top);
}

=item fillWithSourceList

fills a text widget with the list of current sources

  $cat->fillWithSourceList();
  $cat->fillWithSourceList($text,$selected,$task,$index);
  $cat->fillWithSourceList($text,$selected,$task);
  $cat->fillWithSourceList($text,$selected);

Also triggers the UpDate method.

=cut

############################################################
#
#  fills a Text box with the list of current sources
#
sub fillWithSourceList {
  my(@bold, @normal);
  my $self = shift;
  my $T = $self->Text;
  my $selected = $self->Selected;
  my $task = shift;
  my $index = shift;
  my @entered = ();
  my($line,$itag);

  # Retrieve the objects
  # forcing the reference time
  $self->Catalog->force_ref_time;
  my @stars = $self->Catalog->stars;
  my @sources = map { $_->coords } @stars;

  # Enable infobox for access
  $T->configure(-state=>'normal');

  # Clear the existing widgets
  if (defined $task && $task eq 'full') {
    $T->delete('1.0','end');
    foreach my $source (@sources) {
      # KLUGE source does not have index attribute
      if (exists $source->{index} && defined $source->{index}) {
        $T->tagDelete('d'.$source->{index});
      }
    }

    # And clear the current selection
    @$selected = ();

  }

  # Set up display styles
  if ($T->depth > 1) {
    @bold   = (-background => "#eeeeee", qw/-relief raised -borderwidth 1/);
    @normal = (-background => undef, qw/-relief flat/);
  } else {
    @bold   = (qw/-foreground white -background black/);
    @normal = (-foreground => undef, -background => undef);
  }
  $T->tag(qw/configure normal -foreground blue/);
  $T->tag(qw/configure inactive -foreground black/);
  $T->tag(qw/configure selected -foreground red/);
  foreach ( @COLOR_LIST ){
    $T->tag('configure',$_, -foreground => $_);
  }

  # Get a reference coordinate from the object
  my $ref = $self->Catalog->reference;

  # write the label
  if ($ref) {
    my ($az, $el) = $ref->azel();
    my $summary = sprintf("%-15s Az: %3.0f  El: %3.0f", $ref->name,
                          $az->degrees, $el->degrees );
    $self->RefLabel("Reference position: $summary");
  } else {
    # blank it
    $self->RefLabel( '' );
  }

  # Insert the current values
  if (defined $task && $task eq 'full') {
    my $len = @sources;
    for ($index=0; $index < $len; $index++) {
      my $source = $sources[$index];
      # KLUGE source does not have index attribute
      $source->{index} = $index;
      # KLUGE - source summary should add az, el and we should
      # add distance
      my $distance = " --- ";
      if ($ref) {
        my $d = $ref->distance($source);
        if (defined $d) {
          $distance = sprintf("%5.0f", $d->degrees);
        } else {
          $distance = "  Inf";
        }
      }
      my $custom = '';
      if ($self->{'CustomColumns'}) {
        $custom = join(' ', map {$_->{'generator'}->($stars[$index])}
                                @{$self->{'CustomColumns'}}) . ' ';
      }
      $line = sprintf("%-4d  %s %3.0f %3.0f %s %s%s",$index, $source->summary(),
                      $source->az(format=>'d'),
                      $source->el(format=>'d'),
                      $distance,
                      $custom,
                      $source->comment
                     );
      if ($self->isWithin ($source, @$selected)) {
        $self->inswt("$line\n","d$index",'selected');
      } else {
        # KLUGE - source does not really have active or color attributes
        # KLUGE2 - "active" is never set!
        if ($source->{active}) {
          if ($source->{color} ne '') {
            $self->inswt("$line\n","d$index",$source->{color});
          } else {
            $self->inswt("$line\n","d$index",'normal');
          }
        } else {
          $self->inswt("$line\n","d$index",'inactive');
        }
      }
    }

    $len = @sources;
    for ($itag=0; $itag < $len; $itag++) {
      my $dtag = "d$itag";
      $T->tag('bind', $dtag, '<Any-Enter>' =>
              sub {
                shift->tag('configure', $dtag, @bold);
              }
             );
      $T->tag('bind', $dtag, '<Any-Leave>' =>
              sub {
                shift->tag('configure', $dtag, @normal);
              }
             );
      $T->tag('bind', $dtag, '<ButtonRelease-1>' =>
              sub {
                if (!$BUSY){
                  if (! $self->isWithin ($sources[substr($dtag,1,99)], @$selected) ) {
                    shift->tag('configure', $dtag, -foreground => 'red');
                    push (@$selected, $sources[substr($dtag,1,99)]);
                  } else {
                    # KLUGE - no color support in class
                    if ($sources[substr($dtag,1,99)]->{color} ne '') {
                      shift->tag('configure', $dtag, -foreground => $sources[substr($dtag,1,99)]->color());
                    } else {
                      shift->tag('configure', $dtag, -foreground => 'blue');
                    }
                    $self->remove ($sources[substr($dtag,1,99)], $selected);
                  }
                }
              }
             );
        $T->tag('bind', $dtag, '<Double-1>' => sub {
                  $BUSY = 1;
                  my $source = $sources[substr($dtag,1,99)];
                  push (@$selected, $source);
                  my $T = shift;
                 # my $callback = $self->UpDate;
                 # $callback->();
                  my $callback = $self->AddCommand;
                  # turn off tags
                  foreach $source (@$selected) {
                    # KLUGE source does not have index attribute
                        $T->tag('configure', 'd'.$source->{index}, -foreground => 'blue');
                  }
                print " ref(@$selected) is selected \n" if $locateBug;
                my @array = [1..2];
                 # $callback->(@array);
                  $callback->($selected);
                  $BUSY = 0;
                  @$selected = ();

                  $self->destroy if $self->Transient;

                });
    }
  }

  $T->mark(qw/set insert 1.0/);

  # Disable access to infobox
  $T->configure(-state=>'disabled');

  # Trigger an update callback
  $self->UpDate->( $self );
}

=item color

returns a color from @COLOR_LIST and increments the latter's index

  $color = $cat->color();

=cut

############################################################
#  returns a color
#
sub getColor {
  my $color = $COLOR_LIST[$COLOR_INDEX];
  my $len = @COLOR_LIST;
  $COLOR_INDEX++;
  $COLOR_INDEX = $COLOR_INDEX % $len;
  return $color;
}

=item error

Displays an error message in Tk

   $cat->error('Error message');

=cut

############################################################
#  Displays an error message in Tk
#
sub error {
  my $MW = shift;
  my $errWin = $MW->Toplevel(-borderwidth=>10);
  $errWin->title('Observation Log Error!');
  $errWin->resizable(0,0);
  $errWin->Button(
     -text         => 'Ok',
     -command      => sub{
       destroy $errWin;
  })->pack(-side=>'bottom');
  my $message = shift;
  $errWin->Label (
    -text => "\nError!\n\n   ".$message."   \n",
    -relief=>'sunken'
  )->pack(-side=>'bottom', -pady => 10);
  $errWin->title(shift) if @_;
  $MW->update;
  $errWin->grab;
}

=item inswt

 inswt inserts text into a given text widget and applies
 one or more tags to that text.

 Parameters:
        $text  -  Text to insert (it's inserted at the "insert" mark)
        $args  -  One or more tags to apply to text.  If this is empty
                  then all tags are removed from the text.

   $cat->inswt($text, $args);

=cut

####################################################################
#
# Insert_With_Tags
#
# The procedure below inserts text into a given text widget and applies
# one or more tags to that text.
#
# Parameters:
#        $text  -  Text to insert (it's inserted at the "insert" mark)
#        $args  -  One or more tags to apply to text.  If this is empty
#                  then all tags are removed from the text.
#
# Returns:  Nothing
#
sub inswt {

    my $self = shift;
    my $w = $self->Text;
    my($text, @args) = @_;
    my $start = $w->index('insert');

    $w->insert('insert', $text);
    foreach my $tag ($w->tag('names', $start)) {
        $w->tag('remove', $tag, $start, 'insert');
    }
    foreach my $i (@args) {
        $w->tag('add', $i, $start, 'insert');
    }

} # end inswt


=item getSource

getSource prompts the user to enter source coords and name
and filters the catalog based on the input provided.

Takes the new top level widget to use, and the search button
to be re-activated when this window closes.

   $obj = $cat->getSource($toplevel, $search_button);

=cut

sub getSource {
  my $self = shift;
  my $Top = shift;
  my $searchButton = shift;
  my @Epocs = ('RJ', 'RB');
  my %distances = (
      '15 degrees' => 15.0,
      '5 degrees'  => 5.0,
      '1 degree'   => 1.0,
      '30\''       => 0.5,
      '15\''       => 0.25,
      '5\''        => 1.0 / 12,
      '1\''        => 1.0 / 60,
      '30\'\''     => 0.5 / 60,
      '15\'\''     => 0.25 / 60,
      '5\'\''      => 1.0 / 12 / 60,
      '1\'\''      => 1.0 / 3600,
  );
  my $name;

  $Top->title('Source Plot');
  $Top->resizable(0,0);
  my $topFrame = $Top->Frame(-relief=>'groove', -borderwidth =>2, -width =>50)->pack(-padx=>10, -fill => 'x', -ipady=>10, -pady => 10);

  $topFrame->Label (
                    -text => "Name:"
                   )->grid(-column=>0, -row=>0);
  my $nameEnt = $topFrame->Entry(-relief=>'sunken',
                                -width=>15)->grid(-column=>1, -row=>0, -padx =>10, -pady=>3);

  $topFrame->Label (
                    -text => "Ra:"
                   )->grid(-column=>0, -row=>1);
  my $raEnt = $topFrame->Entry(-relief=>'sunken',
                                -width=>15)->grid(-column=>1, -row=>1, -padx =>10, -pady=>3);

  $topFrame->Label (
                    -text => "Dec:"
                   )->grid(-column=>0, -row=>2);
  my $decEnt = $topFrame->Entry(-relief=>'sunken',
                                -width=>15)->grid(-column=>1, -row=>2, -padx =>10, -pady=>3);

  $topFrame->Label(-text => 'Distance:')->grid(-column => 0, -row => 3);
  my $distEnt = '1\'';
  my $distB = $topFrame->Menubutton(-text => $distEnt, -relief => 'raised',
                                    -width => 15);
  foreach my $dist (sort {$distances{$b} <=> $distances{$a}} keys %distances) {
      $distB->command(-label => $dist, -command => sub {
          $distB->configure(-text => $dist);
          $distEnt = $dist;
      });
  }
  $distB->grid(-column => 1, -row => 3, -padx => 10, -pady => 5, -sticky => 'w');

  $topFrame->Label (
                    -text => "Epoc:"
                   )->grid(-column=>0, -row=>4, -padx =>5, -pady=>5);
  my $epocEnt = 'RJ';
  my $epocB = $topFrame->Menubutton(-text => $epocEnt, -relief => 'raised',
                                    -width => 15);
  foreach $name (@Epocs) {
    $epocB->command(-label =>$name, -command=> sub{
                   $epocB->configure( -text => $name );
                   $epocEnt = $name;
                 });
  }
  $epocB->grid(-column=>1, -row=>4, -padx =>10, -pady=>5, -sticky=>'w');

  my $buttonF = $Top->Frame->pack(-padx=>10, -pady=>10);
  $buttonF->Button(
                   -text         => 'Ok',
                   -command      => sub{
                     my $name = $nameEnt->get(); undef $name if $name eq '';
                     my $ra   = $raEnt->get();   undef $ra   if $ra   eq '';
                     my $dec  = $decEnt->get();  undef $dec  if $dec  eq '';

                     my $dec_tol = pi * $distances{$distEnt} / 180;
                     my $ra_tol = $dec_tol * 15;

                     # Filter by name if a name was specified.

                     $self->Catalog()->filter_by_id($name) if defined $name;

                     # Use Astro::Catalog's coordinate filter by distance
                     # if possible.

                     if (defined $ra and defined $dec) {

                         my $coord = new Astro::Coords(ra => $ra, dec => $dec,
                             type => $epocEnt eq 'RB' ? 'B1950' : 'J2000');

                         $self->Catalog()->filter_by_distance($dec_tol,
                                                              $coord);
                     }
                     elsif (defined $ra or defined $dec) {
                         # Searching by RA or Dec alone isn't implemented
                         # by Astro::Catalog, so use a callback filter.

                         $ra = Astro::Coords::Angle::Hour->new(
                                 $ra, range => '2PI')->radians()
                             if defined $ra;
                         $dec = Astro::Coords::Angle->new($dec)->radians()
                             if defined $dec;

                         $self->Catalog()->filter_by_cb(sub {
                             my $item = shift;
                             my $coord = $item->coords();
                             my ($item_ra, $item_dec) = map {$_->radians()}
                                 $epocEnt eq 'RB' ? $coord->radec1950()
                                                  : $coord->radec();

                             return ((! defined $ra or
                                        abs($item_ra - $ra) <= $ra_tol)
                                and  (! defined $dec or
                                        abs($item_dec - $dec) <= $dec_tol));
                         });
                     }

                     $self->fillWithSourceList ('full');
                     $Top->destroy();
                   }
                  )->pack(-side=>'right');
  $buttonF->Button(
                   -text         => 'Cancel',
                   -command      => sub{
                     $Top->destroy();
                   }
                  )->pack(-side=>'right');

  $Top->bind('<Destroy>', sub {
      my $widget = shift;
      return unless $widget == $Top;
      $searchButton->configure(-state =>'normal');
  });

  $Top->update;
  $Top->grab;
  return;
}

=item isWithin

  isWithin returns a boolean value as to whether an element is
  within the array specified.

   $obj = $cat->isWithin($element, @array);

=cut

sub isWithin {
  my $self = shift;
  my $element = shift;
  my @array = @_;
  my $len = @array;
  foreach (@array) {
    # KLUGE - need an isEqual method rather than this. Will break
    # for none RA/Dec coordinates. Had to remove epoch check
    if ($element->name() eq $_->name() && $element->ra() eq $_->ra() && $element->dec() eq $_->dec()) {
      return 1;
    }
  }
  return 0;
}

=item remove

   Removes the item passed from the array specified.

   $obj = $cat->remove($element, @array);

=cut

sub remove {
  my $self = shift;
  my $element = shift;
  my $array = shift;
  my $len = @$array;
  my @temp;
  my $flag = 0;

  # KLUGE - epcc no longer required
  for (my $index = 0; $index < $len; $index++) {
    if ($element->name() eq $$array[$index]->name() && $element->ra() eq $$array[$index]->ra() && $element->dec() eq $$array[$index]->dec() ) {
      $flag = -1;
    } else {
      $temp[$index+$flag] = $$array[$index];
    }
  }
  @$array = @temp;

}

=back

=head1 SEE ALSO

L<Astro::Catalog>, L<Astro::Catalog::Star>, L<Astro::Coords>

=head1 COPYRIGHT

Copyright (C) 2013 Science & Technology Facilities Council.
Copyright (C) 1999-2002,2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHOR

Major subroutines and layout originally designed by Casey Best
(University of Victoria) with modifications to create independent
composite widget by Tim Jenness and Pam Shimek (University of
Victoria)

Revamped for Astro::Catalog by Tim Jenness.

=cut

1;
