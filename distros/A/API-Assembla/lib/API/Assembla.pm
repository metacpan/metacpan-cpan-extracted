package API::Assembla;
BEGIN {
  $API::Assembla::VERSION = '0.03';
}
use Moose;

use DateTime::Format::ISO8601;
use LWP::UserAgent;
use URI;
use XML::XPath;

use API::Assembla::Space;
use API::Assembla::Ticket;

# ABSTRACT: Access to Assembla API via Perl.


has '_client' => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;
        return LWP::UserAgent->new;
    }
);


has 'password' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);


has 'url' => (
    is => 'ro',
    isa => 'URI',
    lazy => 1,
    default => sub {
        my $self = shift;
        return URI->new('https://www.assembla.com/');
    }
);


has 'username' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);


sub get_space {
    my ($self, $id) = @_;

    my $req = $self->make_req('/spaces/'.$id);
    my $resp = $self->_client->request($req);

    # print STDERR $resp->decoded_content;

    my $xp = XML::XPath->new(xml => $resp->decoded_content);

    my $space = $xp->find('/space')->pop;
    my $name = $space->findvalue('name')."";

    return API::Assembla::Space->new(
        id => $space->findvalue('id').'',
        created_at => DateTime::Format::ISO8601->parse_datetime($space->findvalue('created-at').''),
        name => $name,
        description => $space->findvalue('description').'',
    );
}


sub get_spaces {
    my ($self) = @_;

    my $req = $self->make_req('/spaces/my_spaces');
    my $resp = $self->_client->request($req);

    # print STDERR $resp->decoded_content;

    my $xp = XML::XPath->new(xml => $resp->decoded_content);

    my $spaces = $xp->find('/spaces/space');

    my %objects = ();
    foreach my $space ($spaces->get_nodelist) {

        my $name = $space->findvalue('name')."";

        $objects{$name} = API::Assembla::Space->new(
            id => $space->findvalue('id').'',
            created_at => DateTime::Format::ISO8601->parse_datetime($space->findvalue('created-at').''),
            name => $name,
            description => $space->findvalue('description').'',
        );
    }

    return \%objects;
}


sub get_ticket {
    my ($self, $id, $number) = @_;

    my $req = $self->make_req('/spaces/'.$id.'/tickets/'.$number);
    my $resp = $self->_client->request($req);

    # print STDERR $resp->decoded_content;

    my $xp = XML::XPath->new(xml => $resp->decoded_content);

    my $ticket = $xp->find('/ticket')->pop;

    return API::Assembla::Ticket->new(
        id => $ticket->findvalue('id').'',
        created_on => DateTime::Format::ISO8601->parse_datetime($ticket->findvalue('created-on').''),
        description => $ticket->findvalue('description').'',
        number => $ticket->findvalue('number').'',
        priority => $ticket->findvalue('priority').'',
        status_name => $ticket->findvalue('status-name').'',
        summary => $ticket->findvalue('summary').''
    );
}



sub get_tickets {
    my ($self, $id) = @_;

    my $req = $self->make_req('/spaces/'.$id.'/tickets');
    my $resp = $self->_client->request($req);

    # print STDERR $resp->decoded_content;

    my $xp = XML::XPath->new(xml => $resp->decoded_content);

    my $tickets = $xp->find('/tickets/ticket');

    my %objects = ();
    foreach my $ticket ($tickets->get_nodelist) {

        my $id = $ticket->findvalue('id').'';

        $objects{$id} = API::Assembla::Ticket->new(
            id => $id,
            created_on => DateTime::Format::ISO8601->parse_datetime($ticket->findvalue('created-on').''),
            description => $ticket->findvalue('description').'',
            number => $ticket->findvalue('number').'',
            priority => $ticket->findvalue('priority').'',
            status_name => $ticket->findvalue('status-name').'',
            summary => $ticket->findvalue('summary').''
        );
    }

    return \%objects;
}

sub make_req {
    my ($self, $path) = @_;

    my $req = HTTP::Request->new(GET => $self->url.$path);
    $req->header(Accept => 'application/xml');
    $req->authorization_basic($self->username, $self->password);
    return $req;
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

API::Assembla - Access to Assembla API via Perl.

=head1 VERSION

version 0.03

=head1 UNDER CONSTRUCTION

API::Assembla is not feature-complete.  It's a starting point.  The Assembla
API has LOTS of stuff that this module does not yet contain.  These features
will be added as needed by the author or as gifted by thoughtful folks who
write patches! ;)

=head1 SYNOPSIS

    use API::Assembla;

    my $api = API::Asembla->new(
        username => $username,
        password => $password
    );

    my $href_of_spaces = $api->get_spaces;
    # Got an href of API::Assembla::Space objects keyed by space id
    my $space = $api->get_space($space_id);
    # Got an API::Assembla::Space object

    my $href_of_tickets = $api->get_tickets;
    # Got an href of API::Assembla::Space objects keyed by ticket id
    my $ticket = $api->get_ticket($space_id, $ticket_number);
    # Got an API::Assembla::Ticket object

=head1 DESCRIPTION

API::Assembla is a Perl interface to L<Assembla|http://www.assembla.com/>, a
ticketing, code hosting collaboration tool.

=head1 ATTRIBUTES

=head2 password

The password to use when logging in.

=head2 url

The URL to use when working with the api.  Defaults to

  http://www.assembla.com

=head2 username

The username to use when logging in.

=head1 METHODS

=head2 get_space ($id)

Get Space information.

=head2 get_spaces

Get Space information.  Returns a hashref of L<API::Assembla::Space> objects
keyed by the space's name.

=head2 get_tickets ($space_id, $number)

Get Tickets for a space information.

=head2 get_tickets ($space_id)

Get Tickets for a space information.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

