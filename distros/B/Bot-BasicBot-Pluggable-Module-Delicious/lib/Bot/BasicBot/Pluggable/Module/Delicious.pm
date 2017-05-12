package Bot::BasicBot::Pluggable::Module::Delicious;
use warnings;
use strict;
use Carp;
use vars qw( $VERSION );
$VERSION = '0.011';

use Bot::BasicBot::Pluggable::Module;
use base qw(Bot::BasicBot::Pluggable::Module);
use Net::Delicious;
use Regexp::Common 'RE_URI';

=head1 NAME

Bot::BasicBot::Pluggable::Module::Delicious - A Simple URL catcher for Bot::BasciBot::Pluggable

=head1 SYNOPSIS

    use Bot::BasicBot::Pluggable::Module::Delicious

    my $bot = Bot::BasicBot::Pluggable->new(...);

    $bot->load("Delicious");
    my $delicious_handler = $bot->handler("Delicious");
    $delicious_handler->set($url, $user, $pswd);

=head1 DESCRIPTION

A plugin module for L<Bot::BasicBot::Pluggable> to grab, and store URLs from
and IRC channel to a delicious account.

=head1 USAGE


=head1 BUGS


=head1 SUPPORT


=head1 AUTHOR

	Franck Cuny
	CPAN ID: FRANCKC
	tirnanog
	franck@breizhdev.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

=over 4

=item * L<Bot::BasicBot::Pluggable>

=item * L<Bot::BasicBot::Pluggable::Module::Google>

=back 

=cut

sub init {
    my $self = shift;
}

sub said {
    my ($self, $mess, $pri) = @_;
    my ($url, $tags, @url);

    return unless $pri == 2;
    
    $self->{body}    = $mess->{body};
    $self->{who}     = $mess->{who};
    $self->{channel} = $mess->{channel};

    if ($self->{body} =~ /^!addurl/) {
        $self->find_url_and_tags($self->{body});
    } elsif ( $self->{body} =~ /^!tag\s([^\s]+)\s?(\d+)?$/) {
        $self->search_tags($1, $2);
    } else {
        $self->find_url($self->{body});    
    }
}

sub help {
    my ($self) = @_;
    my $mess;
    $mess  = "I find url(s) in text and add them to the delicious account(".$self->{delicious_url}.")\n";
    $mess .=": !addurl url tag1 tag2\n";
    $mess .=": !tag tagname\n";
    $mess .=": I can catch url on the fly, if they are followed by a ([tag]) I add a tag, if there is a nolog I  don't log the url\n";
    return $mess;
}

sub search_tags{
    my ($self, $tag, $limit) = @_;
    $limit = ($limit && $limit < 10) ? $limit : 5;
    foreach my $post ($self->{delicious}->recent_posts({
        tag   => $tag,
        count => $limit,
    })){
        $self->tell($self->{channel}, $self->{who}.": ".$post);
    }
    sleep 1;
}

sub find_url_and_tags {
    my ($self, $body) = @_;
    my $url_re = RE_URI;
    $body =~ s/^!addurl\s//;
    my ($url, $tags) = split " ", $body, 2;
    if ($url =~ /($url_re)/) {
        $self->add_to_delicious($1, $tags);
    }
}

sub find_url {
    my ($self, $body) = @_;
    my $url_re = RE_URI;
    my @url;
    while ($body =~ /($url_re)/g) {
        my $url = $1;
        return if ($body =~ /nolog/);
        if ($body =~ /(?:\[|\()(.*)(?:\]|\))/) {
            my $tags = $1;
            $self->add_to_delicious($url, $tags);
        } else {
            $self->add_to_delicious($url);
        }
    }
}

sub add_to_delicious {
    my ($self, $url , $tags) = @_;
    warn "on a $url et $tags";
    $tags = "fromirc" unless $tags;
    $self->{delicious}->add_post({
        url  => $url,
        tags => $tags." by_".$self->{who},
        description => $url,
    });
    sleep 1;
}

sub set {
    my ($self, $delicious_url, $user, $pswd) = @_;

    croak "Error: no delicious url specified"    unless $delicious_url;
    croak "Error: no delicious user specied"     unless $user;
    croak "Error: no delicious password specied" unless $pswd;    
    
    $self->{delicious_url}  = $delicious_url;
    $self->{delicious}      = Net::Delicious->new({
        user => $user,
        pswd => $pswd,
        debug=> 1,
    });
    return $self;
}

1;
