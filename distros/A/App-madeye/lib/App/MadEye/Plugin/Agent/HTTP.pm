package App::MadEye::Plugin::Agent::HTTP;
use strict;
use warnings;
use Furl;
use App::MadEye::Plugin::Agent::Base;

our $TIMEOUT = 15;

sub is_dead {
    my ($self, $url) = @_;

    my $ua = Furl->new(
        timeout => $TIMEOUT,
        agent   => $self->config->{config}->{user_agent} || "App::MadEye($App::MadEye::VERSION)",
    );
    my $res = $ua->get($url);

    if ($res->code == 200) {
        if (my $part = $self->config->{config}->{part}) {
            if (index($res->content, $part) >= 0) {
                return; # ok
            } else {
                return "contents does not contain $part";
            }
        } else {
            return 0;
        }
    } else {
        return join( "\n", $res->code, $res->message, $res->content );
    }
}

1;
__END__

=for stopwords HTTP

=head1 NAME

App::MadEye::Plugin::Agent::HTTP - check HTTP

=head1 SCHEMA

    type: map
    mapping:
        target:
            type: seq
            required: yes
            sequence:
                - type: str
        timeout:
            required: yes
            type: int
        user_agent:
            required: no
            type: str
        part:
            required: no
            type: str

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<App::MadEye>, L<Gearman::Client>, L<Gearman::Worker>

