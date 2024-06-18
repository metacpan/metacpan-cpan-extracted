package Bot::Telegram::Test::Updates;

use Mojo::Base -strict;
use Test::More;

my @subs;
BEGIN { @subs = qw/updcheck/ }

use subs @subs;
use base 'Exporter';
our @EXPORT = @subs;

sub updcheck {
  my $type = shift;
  my $test = shift;

  sub {
    my ($bot, $update) = @_;
    ok exists $$update{$type}, $test // ();
  }
}

1

__END__

=encoding utf8

=head1 DESCRIPTION

Updates inspection and simulation utilities originally written for the 02-updates test.

=head1 FUNCTIONS

=head2 updcheck

  my $callback = updcheck message => 'this is a message';
  $bot -> on(message => $callback); # pass 'this is a message' if the update is a message and fail it otherwise

Returns a callback for testing updates recognition.
