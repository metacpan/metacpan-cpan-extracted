package Bot::Jabbot::Module::Logger;
use base qw(Bot::Jabbot::Module);
use warnings;
use strict;
use DateTime;
use utf8;

sub muc {
    my ($self,$msg) = @_;
    my $body=$msg->any_body;
    my $from=$msg->from_nick;
    my $chan=$msg->room->jid;
    return unless defined $body;
    my $dt = DateTime->now;
    open OUTFILE,">>logs/$chan.".$dt->ymd.".log";
    binmode OUTFILE, ":utf8";
    print OUTFILE "[".$dt->hms."] <$from> $body\n";
    close OUTFILE;
    return;
}
1;