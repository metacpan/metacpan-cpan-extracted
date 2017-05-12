package Bot::Cobalt::Plugin::Silly;
$Bot::Cobalt::Plugin::Silly::VERSION = '0.031002';
sub new { die __PACKAGE__." is just a placeholder. See POD." }

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Silly - Silly Bot::Cobalt plugins

=head1 DESCRIPTION

A collection of completely silly L<Bot::Cobalt> plugins; these can be 
add to your C<plugins.conf> to do very useless stuff.

In fact, most of them don't even do useless stuff on their own, but 
rather bridge other stuff that does useless stuff.

For an added bonus, they're all hastily-written, too!

=over

=item *

L<Bot::Cobalt::Plugin::Silly::AutoOpAll>
AutoOp *all* users that join a channel.

=item *

L<Bot::Cobalt::Plugin::Silly::BoneEasy>
Generate pickup lines from L<Bone::Easy>

=item *

L<Bot::Cobalt::Plugin::Silly::DailyFail>
Enlightening newspaper headlines; bridges L<Acme::Daily::Fail>

=item *

L<Bot::Cobalt::Plugin::Silly::LOLCAT>
Bridge L<POE::Filter::LOLCAT> to translate text into LOLCAT

=item *

L<Bot::Cobalt::Plugin::Silly::MakeMoneyAtHome>
Bridge L<Acme::MakeMoneyAtHome> to offer useful suggestions on ways to make
money at home

=item *

L<Bot::Cobalt::Plugin::Silly::OutputLOLCAT> 
LOLCAT-enabled bot output filter

=item *

L<Bot::Cobalt::Plugin::Silly::OutputLeet>
Leetspeak output filter (bridges L<Acme::LeetSpeak>)

=item *


L<Bot::Cobalt::Plugin::Silly::Reverse>
Reverse a string.

=item *

L<Bot::Cobalt::Plugin::Silly::Rot13>
Rot13 a string.

=back

=head1 CONTRIBUTING

I'd be happy to review contributed Silly plugins to potentially add 
more uselessness to this distribution.

Send them off to <avenj@cobaltirc.org>, please.

The only real requirement is that they not do much of anything anyone 
might find productive.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
