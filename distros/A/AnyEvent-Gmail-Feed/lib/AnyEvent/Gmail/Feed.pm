package AnyEvent::Gmail::Feed;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use AnyEvent;
use AnyEvent::HTTP;
use MIME::Base64;
use XML::Atom::Feed;

sub new {
    my ($class, %args) = @_;

    my $username = delete $args{username};
    my $password = delete $args{password};
    my $label    = delete $args{label};
    my $interval = delete $args{interval} || 60;

    unless ($username && $password) {
        die "both username and password are required";
    }

    my $self = bless {}, $class;

    my $auth = MIME::Base64::encode( join(":", $username, $password) );
    my $headers = {Authorization => "Basic $auth"};
    my $uri = 'https://mail.google.com/mail/feed/atom/';
    $uri .= $label . '/' if $label; ## 'unread' or whatever

    my %seen;

    my $timer;
    my $checker; $checker = sub {
        http_get $uri, headers => $headers, sub {
            my ($body, $hdr) = @_;
            return unless $body;
            my $feed = XML::Atom::Feed->new(\$body) or return;
            for my $e ($feed->entries) {
                unless ($seen{$e->id}) {
                    ($args{on_new_entry} || sub {})->($e);
                };
                $seen{$e->id}++;
            }
            $timer = AnyEvent->timer( after => $interval, cb => $checker);
        };
    };
    $checker->();
    return $self;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::Gmail::Feed - Subscribe to Gmail feed

=head1 SYNOPSIS

  use AnyEvent;
  use AnyEvent::Gmail::Feed;

  AnyEvent::Gmail::Feed->new(
      username => $user,     #required
      password => $pass,     #required
      label    => $label,    #optional (eg. 'unread')
      interval => $interval, #optional (60s by default)
      on_new_entry => sub {
          my $entry = shift; #XML::Atom::Entry instance
          use Data::Dumper; warn Dumper $entry->as_xml;
      },
  );
  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent::Gmail::Feed is an AnyEvent consumer which checks GMail unread messages

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::Feed>

L<AnyEvent>

L<AnyEvent::HTTP>

L<XML::Atom::Entry>

L<http://code.google.com/apis/gdata/faq.html#GmailAtomFeed>

=cut
