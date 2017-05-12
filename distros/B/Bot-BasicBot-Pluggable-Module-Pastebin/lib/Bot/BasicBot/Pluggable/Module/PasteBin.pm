=head1 NAME

Bot::BasicBot::Pluggable::Module::PasteBin - Check at Pastebin.com if some nick from selected channel paste something, and tell into channel the nick and url

=head1 IRC USAGE

None. When the module is loaded, it checks Pastebin.com and tell if someone paste on it using a nick that is on the channel

=head1 VARS

=over 4

=item channel

Defaults to #sao-paulo.pm,  Choose one channel to be the source of nicks

=item pastebin_url

Defaults to http://perl.pastebin.com, choose the url from pastebin.com or pastebin.com like

=item tick

Defaults to 5, the tick time to check the pastebin. 

=back

=head1 REQUIREMENTS

L<HTML::LinkExtractor>

L<LWP::Simple>

L<Time::Local>

=head1 AUTHOR

Frederico Recsky <frederico@gmail.com>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut



package Bot::BasicBot::Pluggable::Module::PasteBin;
use base qw(Bot::BasicBot::Pluggable::Module);

use warnings;
use strict;

use LWP::UserAgent;
use HTML::LinkExtractor;
use Time::Local;
use File::Temp qw/ tempfile tempdir /;

our $VERSION = '0.01';

my $tick_counter = 6;

sub help {
    return "Returns when someone post in Pastebin using the same nick that uses is this channel";
}

sub init {
    
    my $self = shift;
    
    $self->set('user_tick', "5") unless defined ($self->get('user_tick'));
    $self->set("user_pastebin_url", "http://perl.pastebin.com") unless defined ($self->get("user_pastebin_url"));
    
    if (defined $self->get("pastebin_file")){	
	$self->{tmpfile} = $self->get("pastebin_file");
	print "file: $self->{tmpfile}\n";
    }else{
	my ($fh, $filename) = tempfile();
        $self->{tmpfile} = $filename;
	$self->set("pastebin_file", $filename);
	print "new file: $self->{tmpfile}\n";
    }    
        
}

sub tick {
	
    my $self = shift;
    
    my $period = $self->get("user_tick");

    $tick_counter++;
    return if ( $tick_counter < $period); 
    $tick_counter = 0;
    my $time = timelocal (localtime());

    $self->_check_pastebin();

}

sub _check_nick{

    my $self = shift;
    my $nick = shift;
    my $channel = shift;
    
    return undef unless $nick;
    
    my @nicks =  keys %{ $self->{Bot}->{channel_data}->{$channel}};

    for (@nicks){
	next unless $_;	
	return 1 if /$nick/ ; 
    }
    
    return undef;

}

sub _filter_link {
    
    my $self = shift;
    
    my $link = shift;
    
    if ($link =~ /\w{1,9}\"/){    
	$link =~ />([\w|\s]*)</; 
	    my $nick = $1;
        $link =~ /"(.*)"/;
	    my $url = $1;
	$url =~ m#com/(\w*)#;
	    my $id = $1;
        return ($nick, $url, $id);
    }else{
	return undef;
    }
    
}


sub _check_pastebin {

    my $self = shift;
    
    my $url = $self->get("user_pastebin_url");
    
    my $ua = LWP::UserAgent->new;
    $ua->agent("Bot/0.1");
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('query=libwww-perl&mode=dist');
    my $res = $ua->request($req);
    
    my $html = $res->content if $res->is_success;
      
    my $LX = new HTML::LinkExtractor();
    $LX->parse(\$html);
    
    for my $link ( @{ $LX->links }){
        next unless $link->{_TEXT};
        
	my ($nick, $url, $id) = $self->_filter_link($link->{_TEXT});
            
	for my $channel (keys %{ $self->{Bot}->{channel_data}} ){
		next unless ($channel =~ /^\#/);
		if ($self->_check_nick($nick,$channel)){
		    open my $fh , "<",  "$self->{tmpfile}";
		    while(<$fh>){
			chomp;
			return 0 if ($_ =~ /$id/);
		    }
		    close $fh;
		    open $fh, ">>", "$self->{tmpfile}";
			print $fh "$id\n";
		    close $fh;
		    $self->tell($channel, "$nick just paste in pastebin: $url\n");
		}
        }
    }
    
}

1;

