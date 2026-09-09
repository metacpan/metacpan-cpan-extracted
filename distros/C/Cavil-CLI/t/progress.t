# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

use Mojo::Base -strict, -signatures;

use Test::More;
use Cavil::CLI::Progress;

sub capture ($enabled, $code) {
  my $buffer = '';
  open my $fh, '>', \$buffer;
  local *STDERR = $fh;
  $code->(Cavil::CLI::Progress->new(enabled => $enabled));
  return $buffer;
}

subtest 'disabled progress is silent' => sub {
  my $out = capture(0, sub ($p) { $p->start('Uploading'); $p->spin for 1 .. 5; $p->finish });
  is $out, '', 'nothing is written when disabled';
};

subtest 'enabled progress writes a self-erasing status line with the label' => sub {
  my $out = capture(1, sub ($p) { $p->start('Uploading') });
  like $out, qr/Uploading/, 'shows the phase label';
  like $out, qr/\r\e\[K/,   'redraws in place with an erase';
};

subtest 'spin keeps the current label and is silent when disabled' => sub {
  my $on = capture(1, sub ($p) { $p->start('Indexing'); $p->spin for 1 .. 3 });
  like $on, qr/Indexing/, 'keeps the label while spinning';
  like $on, qr/\r\e\[K/,  'redraws in place';
  is capture(0, sub ($p) { $p->start('x'); $p->spin }), '', 'nothing when disabled';
};

subtest 'every redraw leads with the spinner, so the line does not flicker or jump' => sub {
  my $out = capture(
    1,
    sub ($p) {
      $p->start('Indexing');
      $p->spin;
      $p->label('Analyzing');    # the stage changes while the review runs
      $p->spin;
    }
  );

  # A redraw that emitted a bare label (no spinner prefix) straight after the erase would blink the spinner out
  # and jump the text left. Every frame must lead with the spinner glyph.
  unlike $out, qr/\r\e\[KIndexing/, 'no frame redraws the label without the spinner in front of it';
  like $out,   qr/Analyzing/,       'the updated stage is shown';
};

subtest 'finish erases the line so it never bleeds into the output' => sub {
  my $out = capture(1, sub ($p) { $p->start('Reviewing'); $p->finish });
  like $out, qr/\r\e\[K$/, 'the last write clears the line';
};

done_testing;
