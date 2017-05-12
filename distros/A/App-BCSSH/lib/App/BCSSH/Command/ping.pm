package App::BCSSH::Command::ping;
use strictures 1;

use App::BCSSH::Message;

sub new { bless { agent => $ENV{SSH_AUTH_SOCK} }, $_[0] }

sub run {
    my $self = shift;
    my $agent = $self->{agent} or return;
    return App::BCSSH::Message::ping($agent);
}

1;
__END__

=head1 NAME

App::BCSSH::Command::ping - Check if a bcssh proxy is available

=head1 SYNOPSIS

    bcssh ping && alias vim='bcssh vi --'

=cut
