package Bot::BasicBot::Pluggable::Module::LongURLs;
use Bot::BasicBot::Pluggable::Module;
use base qw(Bot::BasicBot::Pluggable::Module);

use warnings;
use strict;

require WWW::Shorten;

sub help {
    my ($self, $mess) = @_;
    return "I hate long URLs.";
}

sub init {
    my $self = shift;
    $self->set("user_max_length", 100) unless defined($self->get("user_max_length"));
    $self->set("user_shorten_service", 'Metamark') unless defined($self->get("user_shorten_service"));
}


sub said {
    my ($self, $mess, $pri) = @_;
    return unless ($pri == 0);

    my $service = $self->get("user_shorten_service");
    if (!defined $self->{_old_service} || $self->{_old_service} ne $service) 
    {
        no warnings 'redefine';
        eval { WWW::Shorten->import($service); };
        if ($@) {
            $self->{Bot}->reply($mess, "Trying to use $service didn't work: $@");
            $self->{_old_service} = undef;
            return;        
        }
        $self->{_old_service} = $service;        
    }


    my $body = $mess->{body};
 
	return unless defined $body;
    return if $body =~ /phobos.apple.com/;   
    return unless $body =~ m!(http://\S+)!;
    return unless length($1) > $self->get("user_max_length");
    my $long = $1;
    my $short = $long;
    
    unless ($short =~ s!a\d+.\w.akamai\w*.net/\w+/\w+/\w+/\w+/!!) {
      $short = makeashorterlink($long) or return;
    }
    return unless length($short) < length($long);
    return unless $short;
    
    $self->{Bot}->reply($mess, "urgh. long url. Try $short");

}

1;
