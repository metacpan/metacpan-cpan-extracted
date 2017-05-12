package Mac::AFDialogs;

$VERSION = "0.1a";
sub Version { $VERSION; }

require 5.004;
use strict;

use Mac::Events;
use Mac::Windows;
use Mac::Dialogs;
use Mac::Controls;

sub new {
   my $class = shift;
   my $self = {};
   bless $self, $class;
   return $self;
}

sub refresh {
   my $self = shift;
   
   delete $self->{'back'};
   delete $self->{'cont'};
   delete $self->{'abort'};
   delete $self->{'value'};
}

sub standardHandling {
   my $self = shift;
   my $win = shift;
   my $nodispose = shift;
   
   SetDialogDefaultItem $win->window, 3;
   SetDialogCancelItem  $win->window, 2;
   
   $win->item_hit(2, sub { $self->{'back'} = 1; });	
   $win->item_hit(3, sub { $self->{'cont'} = 1; });
   
   WaitNextEvent until (!$win->window || defined($self->{'back'}) || defined($self->{'cont'}));

   if (!$self->{'back'} && !$self->{'cont'}) {
      $self->{'abort'} = 1;
   }
   $win->dispose() if (!$nodispose);
}

sub simpleDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
   );

   $self->standardHandling($win);
}

sub textEntryDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $value = shift;
   $value = "" if (!$value);
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kEditTextDialogItem, new Rect(300, 50, 535, 95), $value]
   );

   SelectDialogItemText $win->window, 4;
   $self->{'value'} = $value;
   $self->standardHandling($win, 1);
   if ($self->{'cont'}) {
      $self->{'value'} = $win->item_text(4);
   }
   $win->dispose();
}

sub numberEntryDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $value = shift;
   $value = "" if (!$value);
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kEditTextDialogItem, new Rect(300, 50, 535, 95), $value]
   );

   $self->{'value'} = $value;
   while ($win->window && !$self->{'cont'} && !$self->{'back'}) {
      SelectDialogItemText $win->window, 4;
      $self->standardHandling($win, 1);
      if ($self->{'cont'}) {
         my $v = $win->item_text(4);
         if ($v =~ /[\+\-]\d+/) {
            $self->{'value'} = $v;
         } elsif ($v =~ /\d+/) {
            $self->{'value'} = "+$v";
         } else {
            MacPerl::Answer("Bitte geben Sie eine Zahl ein!");
            delete $self->{'cont'};
         }
      }
   }
   $win->dispose();
}

sub extendedTextEntryDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $value = shift;
   my $desc = shift;
   my $pattern = shift;
   $desc = "" if (!$desc);
   $value = "" if (!$value);
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kEditTextDialogItem, new Rect(300, 70, 535, 115), $value],
      [kStaticTextDialogItem, new Rect(300, 10, 535, 60), $desc]
   );

   $self->{'value'} = $value;
   while ($win->window && !$self->{'cont'} && !$self->{'back'}) {
      SelectDialogItemText $win->window, 4;
      $self->standardHandling($win, 1);
      if ($self->{'cont'}) {
         my $v = $win->item_text(4);
         if ($pattern) {
            if ($v =~ /$pattern/) {
               $self->{'value'} = $v;
            } else {
               MacPerl::Answer("Bitte halten Sie das Format ein!");
               delete $self->{'cont'};
            }
         } else {
            $self->{'value'} = $v;
         }
      }
   }
   $win->dispose();
}

sub extendedNumberEntryDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $value = shift;
   my $desc = shift;
   my $von = shift;
   my $bis = shift;
   $desc = "" if (!$desc);
   $value = "" if (!$value);
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kEditTextDialogItem, new Rect(300, 70, 535, 115), $value],
      [kStaticTextDialogItem, new Rect(300, 10, 535, 60), $desc]
   );

   $self->{'value'} = $value;
   while ($win->window && !$self->{'cont'} && !$self->{'back'}) {
      SelectDialogItemText $win->window, 4;
      $self->standardHandling($win, 1);
      if ($self->{'cont'}) {
         my $v = $win->item_text(4);
         if ($v =~ /[\+\-]\d+/) {
            if (($v >= $von) && ($v <= $bis)) {
               $self->{'value'} = $v;
            } else {
               MacPerl::Answer("Bitte halten Sie den Bereich ein!");
               delete $self->{'cont'};
            }
         } elsif ($v =~ /\d+/) {
            if (($v >= $von) && ($v <= $bis)) {
               $self->{'value'} = "+$v";
            } else {
               MacPerl::Answer("Bitte halten Sie den Bereich ein!");
               delete $self->{'cont'};
            }
         } else {
            MacPerl::Answer("Bitte geben Sie eine Zahl ein!");
            delete $self->{'cont'};
         }
      }
   }
   $win->dispose();
}

sub singleSelectDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $values = shift;
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kButtonDialogItem, new Rect(300, 50, 535, 70), "Auswahl"]
   );
   
   $self->{'value'} = "";
   my $action = sub {
      my $dlg = shift;
      my $item = shift;
      my $v = MacPerl::Pick($title, @$values);
      if (defined($v)) {
         my $h = $dlg->item_control($item);
         SetControlTitle $h, $v;
         $self->{'value'} = $v;
      }
   };
   
   $win->item_hit(4, $action);	

   $self->standardHandling($win);
}

sub yesnoDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my @controls = (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
      [kRadioButtonDialogItem, new Rect(300, 20, 400, 35), "Ja"],
      [kRadioButtonDialogItem, new Rect(300, 50, 400, 65), "Nein"]
   );
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, @controls;

   $win->item_value(4, kControlRadioButtonCheckedValue);
   $win->item_value(5, kControlRadioButtonUncheckedValue);
   $self->{'value'} = "Y";
      
   $win->item_hit(4, sub {
      $win->item_value(4, kControlRadioButtonCheckedValue);
      $win->item_value(5, kControlRadioButtonUncheckedValue);
      $self->{'value'} = "N";
   });

   $win->item_hit(5, sub {
      $win->item_value(4, kControlRadioButtonUncheckedValue);
      $win->item_value(5, kControlRadioButtonCheckedValue);
      $self->{'value'} = "N";
   });

   $self->standardHandling($win);
}

sub radioDialog {
   my $self = shift;
   my $title = shift;
   my $text = shift;
   my $values = shift;
   my $labels = shift;
   my $offset = shift;
   $offset = 1 if (!$offset);
   $offset *= 15;
   
   $self->refresh();
   
   my $bounds = new Rect 50, 50, 600, 300;
   my @controls = (
      [kStaticTextDialogItem, new Rect(10, 10, 280, 290), $text],
      [kButtonDialogItem, new Rect(475, 220, 495, 240), "<"],
      [kButtonDialogItem, new Rect(515, 220, 535, 240), ">"],
   );
   my $y = 10;
   foreach my $v (@$labels) {
      push @controls, [kRadioButtonDialogItem, new Rect(300, $y, 535, $y+$offset), $v];
      $y += $offset;
   }
   my $win = new MacDialog $bounds, $title, 1, floatProc, 1, @controls;

   my $action = sub {
      my $dlg = shift;
      my $item = shift;
      my $i = 4;
      foreach my $v (@$values) {
         if ($i == $item) {
            $dlg->item_value($i, kControlRadioButtonCheckedValue);
            $self->{'value'} = $v;
         } else {
            $dlg->item_value($i, kControlRadioButtonUncheckedValue);
         }
         $i++;
      }
   };
      
   my $i = 4;
   foreach my $v (@$values) {
      $win->item_hit($i, $action);
      $i++;
   }
   
   $action->($win, 4);
   
   $self->standardHandling($win);
}

1;

__END__

=head1 NAME

AFDialogs - GUI-Class to create the dialogs for AssistantFrame

=head1 SYNOPSIS

=head1 DESCRIPTION

This module implements the dialogs for AssistantFrame. You shouldn't need to access
the methods directly without AssistantFrame.

=head1 HISTORY

Starting with version 0.1a this module needs MacPerl 5.1.8r4 minimum.

=head1 COPYRIGHT

  Copyright 1998, Georg Bauer

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from:

 http://www.westfalen.de/hugo/mac/
 
If there are problems with this library, just drop a note to:

 Georg_Bauer@muensterland.org
 
=cut

