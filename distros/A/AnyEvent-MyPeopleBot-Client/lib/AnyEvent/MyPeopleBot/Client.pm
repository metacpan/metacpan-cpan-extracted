package AnyEvent::MyPeopleBot::Client;
{
  $AnyEvent::MyPeopleBot::Client::VERSION = '0.0.2';
}
# Abstract: MyPeopleBot API in an event loop

use Moose;
use namespace::autoclean;

use AnyEvent;
use AnyEvent::HTTP::ScopedClient;

has apikey => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub profile {
    my ($self, $buddyId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/profile/buddy.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { buddyId => $buddyId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub buddys {
    my ($self, $groupId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/group/members.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { groupId => $groupId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub send {
    my ($self, $id, $msg, $cb) = @_;

    my $which = $id =~ /^B/ ? 'buddy' : 'group';
    my %params = (
        $which . 'Id' => $id,
        content       => $msg,
    );

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/$which/send.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            \%params,
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

sub exit {
    my ($self, $groupId, $cb) = @_;

    my $client = AnyEvent::HTTP::ScopedClient->new("https://apis.daum.net/mypeople/group/exit.json?apikey=" . $self->apikey);
    $client->header('Accept', 'application/json')
        ->post(
            { groupId => $groupId },
            sub {
                my ($body, $hdr) = @_;

                return if ( !$body || $hdr->{Status} !~ /^2/ );
                print "$body\n" if $ENV{DEBUG};
                $cb->($body) if $cb;
            }
        );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AnyEvent::MyPeopleBot::Client

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use AnyEvent::HTTPD;
    use AnyEvent::Mepeople::Client;
    my $client = AnyEvent::MyPeopleBot::Client->new(
        apikey => 'xxxx',
    );

    my $httpd = AnyEvent::HTTPD->new(port => 8080);
    $httpd->reg_cb(
        '/' => sub {
            my $action  = $req->parm('action');
            my $buddyId = $req->parm('buddyId');
            my $groupId = $req->parm('groupId');
            my $content = $req->parm('content');

            $req->respond({ content => [ 'text/plain', "AnyEvent::MyPeopleBot::Client" ]});
            if ($action =~ /^sendFrom/) {
                $client->send($buddyId || $groupId, 'hi', sub {
                    my $json = shift;
                    print "$json\n";
                });
            }
        }
    );

    $httpd->run;

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
