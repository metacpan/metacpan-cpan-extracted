package Bot::JabberBot;

use strict;

=head1 NAME

    Bot::JabberBot - simple jabber bot base class 

=head1 SYNOPSIS

  use Bot::JabberBot;
  Bot::JabberBot->new( server => 'jabber.earth.li',
                       port => 5222,              # (default)
                       nick => 'jabberbot',
                       password => 'foo',
                       resource => 'foo')->run();
  
=cut 

use Jabber::Connection;
use Jabber::NodeFactory;
use Class::MethodMaker new_hash_init => 'new', get_set => [ qw{ server port nick password resource name username session session_length roster }];

our $VERSION = '0.02';

sub connect {
    my $self = shift;
    return $self->c;
}

sub c {
    my $self = shift;
    return $self->{c} if $self->{c};
    my $server = $self->server || 'localhost';
    my $port = $self->port || '5222';
    $self->{c} = Jabber::Connection->new(server => $server.':'.$port,
				       log => 1);
    print "Logging in to $server:$port...\n";
    return $self->{c};
}

sub nf {
    my $self = shift;
    return $self->{nf} if $self->{nf};
    $self->{nf} = Jabber::NodeFactory->new(fromstr => 1);
}

sub run {
    my $self = shift;
    my $c = $self->connect;
    die "oops: ".$c->lastError unless $c->connect();

    $c->register_handler('message',sub { return $self->message(@_) });
    $c->register_handler('presence',sub { return $self->presence(@_) });
    $c->register_handler('iq',sub { return $self->handle_iq(@_) });

    $c->auth($self->nick,$self->password,$self->resource);
    $c->send('<presence/>');
    $self->request_roster;
    $c->start;
}

sub stop {
    my $self = shift;
    print "Exiting...\n";
    $self->c->disconnect();
    exit(0);
}

sub message {
    my ($self,$in) = @_;
    my $said;

    $said->{body} = $in->getTag('body')->data;
    $said->{who} = $in->attr('from');

    my $reply = $self->said($said);

    if ($reply) { 
	my $response;
	if (ref $reply eq 'HASH') {
	    $response = $reply->{body};
	}
	else { $response = $reply; }

	$self->say({ who => $said->{who},
		     body => $response,
		     type => $in->attr('type')});  
		   
    }
}

sub said {
    # override
}

sub say {
    my ($self,$say) = @_;
    my $out = $self->nf->newNodeFromStr('<message><body>'.$say->{body}.'</body></message>');
    $out->attr('to',$say->{who});
    my $type = $say->{type} || 'chat';
    $out->attr('type',$type);
    $self->c->send($out);
}

sub presence {
    my ($self,$in) = @_;
    
    my $type = $in->attr('type');
    if ($type eq 'subscribe') {
	my $message = "<presence to='".$in->attr('from')."' type='subscribed'/>";
	my $node = $self->nf->newNodeFromStr($message);
	$self->c->send($node);
	$message = "<presence to='".$in->attr('from')."' type='subscribe'><status>I would like to add you to my roster.</status></presence>";
	my $node = $self->nf->newNodeFromStr($message);
	$self->c->send($node);
	my $roster = $self->roster;
	push @{$roster}, $in->attr('from');
	$self->roster($roster);
    }
}
 
sub handle_iq {
    my ($self,$in) = @_;

    my $type = $in->attr('id');
    if ($type =~ m/roster_1/) {
	my @roster;
	my $query = $in->getTag('query');
	my @items = $query->getTag('item');
	foreach (@items) {
	    if ($_->attr('jid') =~ m/\@/) {
		push @roster, $_->attr('jid');
	    }
	}
	$self->roster(\@roster);
    }
} 

sub update_session {
    my ($self,$said) = @_;
    my $session = $self->session;
    my $dialogue = $session->{$said->{who}} || [ ];
    my $session_length = $self->session_length || '8';
    if (scalar(@{$dialogue}) > 8) {
	pop @{$dialogue};
    }
    push @{$dialogue}, $said->{body};
    $session->{$said->{who}} = $dialogue;
    $self->session($session);
}

sub request_roster {
    my ($self) = @_;
    my $request = $self->nf->newNodeFromStr('<iq id="roster_1" type="get"><query xmlns="jabber:iq:roster"/></iq>');
    $self->c->send($request);
} 

=head1 DESCRIPTION

a very simple Jabber bot base class, which shares interface with the Bot::BasicBot 
class for IRC bots. this allows me to take Bot::BasicBot subclasses and replace the 
base class with 

    use base qw( Bot::JabberBot );

and they Just Work. also provides some jabber-specific features; the bot requests
the Roster of jabberids whose presence it wants to know about; and when it it sent a
jabber subscription request, it automatically accepts it and adds the requester to
its roster.

=head1 METHODS

      new(%args);
	 Creates a new instance of the class.  Name value pairs may be
passed which will have the same effect as calling the method of that name
with the value supplied.

      run();
	 Runs the bot.  Hands the control over to the Jabber::Connection object 

      said({ who => 'test@jabber.org', body => 'foo'}) 
 
           This is the main method that you'll want to override in your sub-
class - it's the one called by default whenever someone sends a message.
You'll be passed a reference to a hash that contains these arguments:

            { who => [jabberid of message sender],
              body => [body text of message }

You should return what you want to say.  This can either be a sim-
ple string or a hashref that contains values that are compatible with say
(just changing the body and returning the structure you were passed works
very well.)

           Returning undef will cause nothing to be said.

      say({who => 'test@jabber.org', body => 'bar'})
  
           Say something to someone.

      roster();
           
           Returns an array ref of jabberids whose presence is registered with the bot.

     session();

           A session get-set is provided to store per-user session information.
Nothing is put in here by default.

=head1 BOT JABBER ACCOUNTS

To use a Bot::JabberBot you must register an account for it with a jabber 
server through a regular client, and set up transports to other IM accounts
in this way. i thought of doing this automatically, but decided it would
be spammy and might lead to bot abuse.    

=head1 AUTHOR

    Jo Walsh  E<lt>jo@london.pm.orgE<gt>

=head1 CREDITS
    
    Simon Kent - maintainer of Bot::BasicBot
    Mark Fowler - original author of Bot::BasicBot
    DJ Adams - author of Jabber::Connection
    Tom Hukins - patched 0.02
    everyone on #bots and #pants

=head1 SEE ALSO

    <L>Bot::BasicBot
    <L>Jabber::Connection
    <L>Jabber::NodeFactory

=cut 

1;
