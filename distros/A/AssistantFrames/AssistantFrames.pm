package Mac::AssistantFrames;

$VERSION = "0.1";
sub Version { $VERSION; }

require 5.004;
use strict;
use Mac::AFDialogs;

sub new {
   my $class = shift;
   my $self = {};
   $self->{'answers'} = [];
   $self->{'frames'} = [];
   $self->{'sequence'} = [];
   $self->{'running'} = 1;
   bless $self, $class;
   return $self;
}

sub backupOne {
   my $self = shift;
   my $dlgs = $self->{'frames'};
   my $answers = $self->{'answers'};
   while ($self->getLastFrameRaw() =~ /^\[.*\]$/) {
      pop @$dlgs;
      pop @$answers;
   }
   if (@$dlgs > 0) {
      pop @$dlgs;
      pop @$answers;
   }
}

sub continueOne {
   my $self = shift;
   my $name = shift;
   my $value = shift;
   push @{$self->{'frames'}}, $name;
   push @{$self->{'answers'}}, $value;
}

sub abort {
   my $self = shift;
   my $text = shift;
   $self->{'running'} = 0;
   $self->{'frames'} = [];
   $self->{'answers'} = [];
   if ($text) {
      MacPerl::Answer($text);
   }
}

sub standardAction {
   my $self = shift;
   my $name = shift;
   my $dlg = shift;
   if ($dlg->{'cont'}) {
      $self->continueOne($name, $dlg->{'value'});
      if ($name eq "<finish>") {
         $self->{'running'} = 0;
      }
   } elsif ($dlg->{'back'}) {
      $self->backupOne();
      if ($name eq "<start>") {
         $self->{'running'} = 0;
      }
   } elsif ($dlg->{'abort'}) {
      $self->abort();
   }
}

sub startFrame {
   my $self = shift;
   my $title = shift;
   my $description = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->simpleDialog($title, $description);
   $dlg->{'value'} = "";
   $self->standardAction("<start>", $dlg);
}

sub finishFrame {
   my $self = shift;
   my $title = shift;
   my $description = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->simpleDialog($title, $description);
   $dlg->{'value'} = "";
   $self->standardAction("<finish>", $dlg);
}

sub constantFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $value = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->simpleDialog($title, $description);
   $dlg->{'value'} = $value;
   $self->standardAction($name, $dlg);
}

sub yesnoFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->yesnoDialog($title, $description);
   $self->standardAction($name, $dlg);
}

sub radioFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $values = shift;
   my $labels = shift;
   my $offset = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->radioDialog($title, $description, $values, $labels, $offset);
   $self->standardAction($name, $dlg);
}

sub numberEntryFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $value = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->numberEntryDialog($title, $description, $value);
   $self->standardAction($name, $dlg);
}

sub textEntryFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $value = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->textEntryDialog($title, $description, $value);
   $self->standardAction($name, $dlg);
}

sub extendedTextEntryFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $value = shift;
   my $desc = shift;
   my $pattern = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->extendedTextEntryDialog($title, $description, $value, $desc, $pattern);
   $self->standardAction($name, $dlg);
}

sub extendedNumberEntryFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $value = shift;
   my $desc = shift;
   my $von = shift;
   my $bis = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->extendedNumberEntryDialog($title, $description, $value, $desc, $von, $bis);
   $self->standardAction($name, $dlg);
}

sub singleSelectFrame {
   my $self = shift;
   my $name = shift;
   my $title = shift;
   my $description = shift;
   my $values = shift;
   my $dlg = Mac::AFDialogs->new();
   $dlg->singleSelectDialog($title, $description, $values);
   $self->standardAction($name, $dlg);
}

sub constantHiddenFrame {
   my $self = shift;
   my $name = shift;
   my $value = shift;
   $self->continueOne("[$name]", $value);
}

sub running {
   my $self = shift;
   return $self->{'running'};
}

sub getLastAnswer {
   my $self = shift;
   my $a = $self->{'answers'};
   if (@$a == 0) {
      return "<empty>";
   } else {
      return @$a[$#{$a}];
   }
}

sub getLastFrameRaw {
   my $self = shift;
   my $dlgs = $self->{'frames'};
   if (@$dlgs == 0) {
      return "<empty>";
   } else {
      return @$dlgs[$#{$dlgs}];
   }
}

sub getLastFrame {
   my $self = shift;
   my $last = $self->getLastFrameRaw();
   if ($last =~ /^\[(.*)\]$/) {
      return $1;
   } else {
      return $last;
   }
}

sub getAnswers {
   my $self = shift;
   return $self->{'answers'};
}

sub joinedAnswers {
   my $self = shift;
   my $sep = shift;
   return join($sep, @{$self->{'answers'}});
}

sub getNumAnswers {
   my $self = shift;
   return scalar @{$self->{'answers'}};
}

sub addToSequence {
   my $self = shift;
   my $clos = shift;
   my $seq = $self->{'sequence'};
   push @$seq, $clos;
}

sub processSequence {
   my $self = shift;
   my $i = 0;
   my $seq = $self->{'sequence'};
   while ($self->running()) {
      &{$seq->[$i]}();
      $i = $self->getNumAnswers();
   }
   if ($self->getLastFrame() eq "<finish>") {
      return $self->getAnswers();
   } else {
      return undef;
   }
}

1;

__END__

=head1 NAME

Mac::AssistantFrames - GUI-Class to build an assistant-like line of frames
resembles the standard OS assistants/wizards.

=head1 SYNOPSIS

This uses a static predefined sequence. This is easy to set up and easy to process.

  use Mac::AssistantFrames;
  
  my $assist = Mac::AssistantFrames->new();
  
  $assist->addToSequence(sub { $assist->startFrame("title", "description"); });
  $assist->addToSequence(sub { $assist->yesnoFrame("title", "description"); });
  $assist->addToSequence(sub { $assist->finishFrame("title", "description"); });
  
  my $res = $assist->processSequence();
  if (defined($res)) {
     print join(":", @$res);
  }

This is for handcoded sequencing through dialogs - this allows a flexible
sequence and shows some more of the methods.

  use Mac::AssistantFrames;

  my $assist = Mac::AssistantFrames->new();

  while ($assist->running()) {
     my $last = $assist->getLastFrame();
     if ($last eq "<empty>") {
        $assist->startFrame("title", "description");
     } elsif ($last eq "<start>") {
        $assist->constantFrame("dlg1", "title", 
                               "description", "value");
     } elsif ($last eq "dlg1") {
        $assist->singleSelectionFrame("dlg2", "title", 
                                      "description", 
                                      ["v1", "v2", "v3"]);
     } elsif ($last eq "dlg2") {
        $assist->constantHiddenFrame("dlg3", "value");
     } elsif ($last eq "dlg3") {
        $assist->finishFrame("title", "description");
     }
  }
  if ($assist->getLastFrame eq "<finish>") {
     print $assist->joinedAnswersr(":"), "\n";
  } else {
     print "aborted\n";
  }

=head1 DESCRIPTION

This Module implements simple assistant style frames for MacPerl. You can use it
if you need to ask the user some questions in sequence to accomplish a task. This
could be done with one dialogbox, too. But the assistant approach is often easier
to understand, especially if the user doesn't know much about the subject at hand.
This is the case most often with configuration of new software packages, where
the user has to be given much more detailed descriptions of what to do as would
fit on a simple dialog.

The AssistantFrame allows backward navigation in case the user erred on some of
his answers. It allows complete backwind of the frames (abortion of the process)
and it has a uniform userinterface that resembles a lot the Mac-style assistants.

=head1 CLASS METHODS

=over 4

=item new()

This constructor creates a new frame sequence object.

=item Version()

This method returns the version of the module.

=back

=head1 METHODS

=over 4

=item running()

This checks if the assistant object is in running state. If the "<start>" frame
is aborted, this is reset to 0. If the "<finish>" frame is accepted, this is
reset to 0.

=item backupOne()

This method backs up one frame. This is internally used, you seldom have to
invoke it yourself.

=item continueOne(name, value)

This method adds a successfull frame to the sequence. This is used internally,
so you shouldn't need to call this yourself.

=item abort([text])

This method stops the assistant. If "text" is given, it creates an alert dialog.
If it is not given, the assistant is just canceled. This can be used to react on
errors in a assistant processing.

=item standardAction(name, dlg)

This method is internally used to process the events from the dialog. Just ignore
it.

=item getLastFrame()

This method returns the last frame the user completed. This is needed to allow
backing up and sequencing correctly. If the sequence of frames is empty, it
returns "<empty>".

=item getLastFrameRaw()

This method is used to get the last frame, as is getLastFrame. Only difference:
getLastFrameRaw delivers the frame-name in "raw" format - names of hidden constant
elements is bracketed in []. This function is used internally to distinguish
frames from constants.

=item getLastAnswer()

This returns the last answer given. It is usefull to make frames dependend on
older frames.

=item getAnswers()

This returns a reference to the array of the answer-strings.

=item joinedAnswers(sep)

This returns a string created by joining all answers together, separated by sep.

=item getNumAnswers()

This returns the number of accumulated answers.

=item addToSequence(closure)

This adds the closure to the sequence array of the assistant. The sequence array
allows a simple processing of a static sequence of frames.

=item processSequence()

This processes the sequence array and returns a reference to the array of answers.

=back

=head1 FRAMES

=over 4

=item startFrame(title, description)

This frame has the special name "<start>". It must be the first frame in the
sequence and should give the user a short introduction into the task at hand. The
user can only abort the sequence if he is at this frame and backs up, or by closing
the window of the current frame (this can be done in any frame). The startframe
produces the empty string as value. Any other frame can take over the rule of the
startframe by giving it the name "<start>".

=item finishFrame(title, description)

This frame has the special name "<finish>". It must be the last frame in the
sequence and should give the user a description of the effect this whole sequence
would have if completed. It produces the empty string as value. Any frame can take
over the rule of the finish-frame by giving it the name "<finish>".

=item constantFrame(dlg, title, description, value)

This frame is just an informational Message that is associated with a constant
value. It is often needed if you have to give more detailed descriptions.

=item constantHiddenFrame(value)

This frame is no frame - it is just a constant value that is spliced into the
answer list. This might be needed by your application, if you want to construct
a string out of the answer-list with join. If backed-up, this frame is ignored.

=item textEntryFrame(dlg, title, description, value)

This frame allows the entry of free text into a frame. This text is then delivered
as answer.

=item extendedTextEntryFrame(dlg, title, description, value, format, [pattern])

This is identical to textEntryFrame, except that it shows some additional description
on the format of the text to be entered. An optional additional parameter gives
you the possibility to give a regexp that must match with the entered string.

=item numberEntryFrame(dlg, title, description, value)

This is identical to textEntryFrame, but it expects you to enter a number and does
check the syntax of your entry. Numbers are always delivered with a sign, even
if that is "+".

=item extendedNumberEntryFrame(dlg, title, description, value, format, from, to)

This is identical to numberEntryFrame, except that you can give an additional
parameter that gives a description about the number to be entered. Two more
additional parameters make a range of numbers you are allowed to enter.

=item yesnoFrame(dlg, title, description)

This frame asks a simple yes-no question. This may be used for asking for optional
parts of the assistant. It delivers a Y or a N as answer.

=item radioFrame(dlg, title, description, values, labels [, offset])

This frame presents a selection using radio buttons. Only one value can be
selected. This is usefull for small selections. The strings from labels are used
for the frame, the strings from values are delivered in the answer. The offset
is used for the positioning of the elements.

=item singleSelectFrame(dlg, title, description, [val1, val2, val3])

This frame allows a single selection out of a list of values. This should be used
if there are more than 5 values to choose from, or if the number of values is
not known at compiletime.

=back

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

