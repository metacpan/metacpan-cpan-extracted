package Bot::BasicBot::Pluggable::Module::HTTPIRCGW;
use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION = '0.012';

use Bot::BasicBot::Pluggable::Module;
use base qw(Bot::BasicBot::Pluggable::Module);
use LWP::UserAgent;
use URI::Escape;

=head1 NAME

Bot::BasicBot::Pluggable::Module::HTTPIRCGW - A Simple HTTP Action for Bot::BasicBot::Pluggable

=head1 SYNOPSIS

    use Bot::BasicBot::Pluggable::Module::Delicious

    my $bot = Bot::BasicBot::Pluggable->new(...);

    $bot->load("HTTPIRCGW");
    my $HttpIrcGw_handler = $bot->handler("HTTPIRCGW");
    $HttpIrcGw_handler->set($action_file);

    here is an exmple of the action file:
    ^!(fnord)$ # GET=>http://xxx.xxx/fnordtune.php # sub{$web_out=~s/\r\n//g;}
    ^!todo # POST=>http://xxx.xx/wiki/?add_todoTNOnick=$who&text=$body # sub{$web_out = "task added";}
    
    # are delimiters
    first there is a regex for a command
    the action, GET or POST, with the url, in the case of a POST, TNO is the separator
    then a sub with what to do (parsing, result), in the var "$web_out"

=head1 DESCRIPTION

A plugin module for L<Bot::BasicBot::Pluggable> to perform HTTP actions

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

    return unless $pri == 2;

    my $body    = $mess->{body};
    my $who     = $mess->{who};
    my $channel = $mess->{channel};
    my $web_out;    
    my $res;
    
    foreach my $regex (keys %{$self->{hash}}){
        next unless $body =~ /$regex/;
        $body =~ s/$regex//;
        my ($action, $url) = split'=>',$self->{hash}->{$regex}->{cmd};
        my $callback = $self->{hash}->{$regex}->{callback};
        $action =~ s/\s+//g;
        $url    =~ s/\s+//g;
        if ($action eq "GET"){
            my $req = HTTP::Request->new($action, $url);
            $res = $self->{ua}->request($req);   
        } elsif ($action eq "POST") {
            my ($url, $query) = split 'TNO', $url;
            my @res = split '&', $query;
            my %hash;
            foreach (@res) {
                my ($field, $value) = split '=', $_;
                $hash{$field} = eval $value;
            }
            $res = $self->{ua}->post($url, \%hash);
        }
        if ($res->is_success) {
            $web_out = $res->content;
            my $refsub = eval $callback;
            $refsub->();
            return $web_out;
        } else {
            return $res->status_line;
        }
    }
}

sub set {
    my ($self, $file) = @_;
    open HANDLE, $file;
    while(<HANDLE>){
        chomp;
        my ($regex, $cmd, $callback) = split '#',$_;
        $regex =~ s/\s+$//g;
        $self->{hash}->{$regex}->{cmd}      = $cmd;
        $self->{hash}->{$regex}->{callback} = $callback;
    }
    close HANDLE;
    $self->{ua} = LWP::UserAgent->new();
    $self->{ua}->agent("Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr) AppleWebKit/412.7 (KHTML, like Gecko) Safari/412.5");
    return $self;
}

1;
