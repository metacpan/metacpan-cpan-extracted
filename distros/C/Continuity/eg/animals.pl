#!/usr/bin/perl -w

use strict;
use lib '../lib';
use Continuity;
use Data::Dumper;

use base 'Continuity::RequestHolder';

# This is the A MODIFIED VERSION written by awwaiid.
# The original version was written by Merlyn,
# http://www.perlmonks.org/?node_id=200391

my $info = "dog";

Continuity->new(port => 8080)->loop;

sub main {
  my $self = shift;
  bless $self, __PACKAGE__;

  {
    $self->try($info);
    redo if ($self->yes("play again?"));
  }
  $self->print("<pre>Bye! Here's my DB");
  $self->print(Dumper($info));
}

sub try {
    my $self = $_[0];
    my $this = $_[1];
    if (ref $this) {
      return $self->try($this->{$self->yes($this->{Question}) ? 'Yes' : 'No' });
    }
    if ($self->yes("Is it a $this")) {
      $self->print("I got it!\n");
      return 1;
    };
    $self->print("no!?  What was it then? ");
    chomp(my $new = $self->stdin());
    $self->print("And a question that distinguishes a $this from a $new would be? ");
    chomp(my $question = $self->stdin());
    my $yes = $self->yes("And for a $new, the answer would be...");
    $_[1] = {
             Question => $question,
             Yes => $yes ? $new : $this,
             No => $yes ? $this : $new,
            };
    return 0;
}


sub stdin {
    my $self = shift;
    $self->print(qq{
      <form method=POST>
        <input id=in name=in type=text>
        <script>document.getElementById('in').focus();</script>
      </form>
    });
    $self->next;
    my $in = $self->param('in');
    return $in;
}

sub yes {
    my $self = shift;
    $self->print("@_ (yes/no)?");
    $self->stdin() =~ /^y/i;
}


1;

