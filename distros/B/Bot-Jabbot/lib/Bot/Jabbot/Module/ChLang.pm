package Bot::Jabbot::Module::ChLang;
use base qw(Bot::Jabbot::Module);
use warnings;
use strict;

sub muc {
    my ($self,$msg,$mynick,$bot) = @_;
    my $body=$msg->any_body;
    my $nick=$msg->from_nick;

    return unless defined $body;
    my $role=$msg->room->get_user($nick)->role;
    $body=lc($body);
    
    if ($body=~m/!lang ([a-z]{2})/ && $role eq 'moderator') {
        my $lang=$1;
        $bot->setlang($lang);
        return $self->loc("language changed to %1",$lang);
    }
}
1;