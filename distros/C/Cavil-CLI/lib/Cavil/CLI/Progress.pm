# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI::Progress;
use Mojo::Base -base, -signatures;

use Mojo::Util qw(encode);

# A single self-erasing status line on STDERR, so a long-running check always shows what it is doing without
# touching STDOUT (which carries the report or a JSON pipe). Disabled unless STDERR is a terminal, so CI logs
# stay clean. A phase leads with an animated spinner and a label; set the label to name what is happening and
# call spin() to keep it alive while waiting.
my @SPINNER = ("\x{2839}", "\x{2838}", "\x{283c}", "\x{2834}", "\x{2826}", "\x{2827}", "\x{2807}", "\x{280f}");

has enabled => 0;
has 'label';
has _frame => 0;

# Begin a phase with the given label.
sub start ($self, $label) {
  $self->label($label);
  $self->_draw;
  return $self;
}

# Advance the spinner one frame; called on a timer while a request is in flight so the line shows life.
sub spin ($self) {
  return unless $self->enabled;
  $self->_frame($self->_frame + 1);
  $self->_draw;
}

# Erase the status line, so it never bleeds into the report that follows.
sub finish ($self) {
  return unless $self->enabled;
  $self->_write('');
}

sub _draw ($self) {
  return unless $self->enabled;
  $self->_write($SPINNER[$self->_frame % @SPINNER] . ' ' . ($self->label // ''));
}

sub _write ($self, $text) {
  print STDERR encode('UTF-8', "\r\e[K$text");
}

1;
