package AtomBus;
use Dancer qw(:syntax);
use Dancer::Plugin::DBIC qw(schema);

use Atompub::DateTime qw(datetime);
use UUID::Tiny;
use XML::Atom;
$XML::Atom::DefaultVersion = '1.0';

our $VERSION = '1.0405'; # VERSION

set content_type => 'application/xml';
config->{plugins}{DBIC}{atombus} = config->{atombus}{db};
config->{plugins}{DBIC}{atombus}{schema_class} = 'AtomBus::Schema';
eval { schema->deploy }; # Fails gracefully if tables already exist.

get '/feeds/:feed_title/entries/:entry_id' => sub {
    my $entry_id = 'urn:uuid:' . params->{entry_id};
    my $db_entry = schema->resultset('AtomBusEntry')->find({id => $entry_id});
    return send_error("No such message exists", 404)
        unless $db_entry;
    my $if_none_match = request->header('If-None-Match');
#TODO: support revised entries (i.e. Atompub PUT)
#    my $revision_id = $db_entry->revision_id || $db_entry->id;
    my $revision_id = $db_entry->id;

    # If ETag matches current revision id of entry
    if (my $id = $if_none_match) {
        $id =~ s/^"(.*)"$/$1/; # Remove surrounding quotes
        if ($revision_id eq $id) {
            status 304;
            return '';
        }
    }

    my $entry = _entry_from_db($db_entry);

    _add_etag($revision_id);
    header Vary => 'If-None-Match';

    return $entry->as_xml;
};

get '/feeds/:feed_title' => sub {
    my $feed_title = lc params->{feed_title};
    my $start_after = params->{start_after};
    my $start_at = params->{start_at};
    my $if_none_match = request->header('If-None-Match');
    my $order_id;

    if (my $id = $if_none_match) {
        $id =~ s/^"(.*)"$/$1/; # Remove surrounding quotes
        my $entry = schema->resultset('AtomBusEntry')->find({id => $id});
        $order_id = $entry->order_id if $entry;
    }
    if (my $id = $start_after || $start_at) {
        my $entry = schema->resultset('AtomBusEntry')->find({id => $id});
        return send_error("No such message exists with id $id", 400)
            unless $entry;
        $order_id = $entry->order_id;
    }

    my $db_feed = schema->resultset('AtomBusFeed')->find(
        { title => $feed_title });
    return send_error("No such feed exists named $feed_title", 404)
        unless $db_feed;

    my $feed = XML::Atom::Feed->new;
    $feed->title($feed_title);
    $feed->id($db_feed->id);
    my $person = XML::Atom::Person->new;
    $person->name($db_feed->author_name);
    $feed->author($person);
    $feed->updated($db_feed->updated);
    
    my $self_link = XML::Atom::Link->new;
    $self_link->rel('self');
    $self_link->type('application/atom+xml');
    $self_link->href(request->uri_for(request->path));
    $feed->add_link($self_link);

    #my $hub_link = XML::Atom::Link->new;
    #$hub_link->rel('hub');
    #$hub_link->href('http://184.106.189.98:8080/publish');
    #$feed->add_link($hub_link);

    my %query = (feed_title => $feed_title);
    if ($order_id) {
        $query{order_id} = { '>'  => $order_id } if $if_none_match;
        $query{order_id} = { '>'  => $order_id } if $start_after;
        $query{order_id} = { '>=' => $order_id } if $start_at;
    }
    my $rset = schema->resultset('AtomBusEntry')->search(
        \%query, { order_by => ['order_id'] });
    my $count = config->{atombus}{page_size} || 1000;
    my $last_id;
    while ($count-- && (my $entry = $rset->next)) {
        $feed->add_entry(_entry_from_db($entry));
        $last_id = $entry->id;
    }

    # If ETag was provided and there are no new entries
    if (not $last_id and $if_none_match) {
        status 304;
        return '';
    }

    _add_etag($last_id) if $last_id;
    header Vary => 'If-None-Match';

    return $feed->as_xml;
};

post '/feeds/:feed_title' => sub {
    my $feed_title = lc params->{feed_title};
    my $body = request->body;
    return send_error("Request body is empty", 400)
        unless $body;
    my $entry = XML::Atom::Entry->new(\$body);
    my $updated = datetime->w3cz;
    my $db_feed = schema->resultset('AtomBusFeed')->find_or_create({
        title       => $feed_title,
        id          => _gen_id(),
        author_name => 'AtomBus',
        updated     => $updated,
    }, { key => 'title_unique' });
    my $db_entry = schema->resultset('AtomBusEntry')->create({
        feed_title => $feed_title,
        id         => _gen_id(),
        title      => $entry->title,
        content    => $entry->content->body,
        updated    => $updated,
    });
    $db_feed->update({updated => $updated});
    $entry = _entry_from_db($db_entry);
    _add_etag($entry->id);
    header Location => $entry->link->href;
    content_type 'application/atom+xml;type=entry';
    status 'created';
    return $entry->as_xml;
};

sub _gen_id { 'urn:uuid:' . create_UUID_as_string() }

sub _id_nss { $_ = shift; s/^urn:uuid://; return $_ }

sub _entry_from_db {
    my $row = shift;
    my $entry = XML::Atom::Entry->new;
    $entry->title($row->title);
    $entry->content($row->content);
    $entry->id($row->id);
    $entry->updated($row->updated);
    my $self_link = XML::Atom::Link->new;
    $self_link->rel('self');
    $self_link->type('application/atom+xml');
    $self_link->href( join( '/', uri_for('/feeds'), $row->feed_title->title, 'entries', _id_nss($row->id) ));
    $entry->add_link($self_link);
    return $entry;
}

sub _add_etag { header ETag => qq("$_[0]") }

# ABSTRACT: An AtomPub server for messaging.


1;

__END__
=pod

=head1 NAME

AtomBus - An AtomPub server for messaging.

=head1 VERSION

version 1.0405

=head1 SYNOPSIS

    use Dancer;
    use AtomBus;
    dance;

=head1 DESCRIPTION

AtomBus is an AtomPub server that can be used for messaging.
The idea is that atom feeds can correspond to conceptual queues or buses.
AtomBus is built on top of the L<Dancer> framework.
It is also pubsubhubbub friendly.

These examples assume that you have configured your web server to point HTTP
requests starting with /atombus to your AtomBus server (see L</DEPLOYMENT>).
To publish an entry, make a HTTP POST request:

    $ curl -d '<entry> <title>allo</title> <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml" >an important message</div>
      </content> </entry>' http://localhost/atombus/feeds/widgets

That adds a new entry to a feed titled widgets.
If that feed didn't exist before, it will be created for you.
To retrieve the widgets feed, make a HTTP GET request:

    $ curl http://localhost/atombus/feeds/widgets

Clients can request only entries that came after the last entry they processed.
They can do this by providing the id of the last message as the start_after
parameter:

    $ curl http://localhost/atombus/feeds/widgets?start_after=42

Alternatively, you can provide a start_at param.  This will retrieve entries
starting with the given id:

    $ curl http://localhost/atombus/feeds/widgets?start_at=42

HTTP ETags are also supported.
The server responds with an ETag header for each request.
The client can provide that ETag as the If-None-Match header.
The following example will work the same as if the client provided a start_after
parameter.
Except that it will return an empty body and a 304 status if there are no new
entries.
This is the behavior that pubsubhubbub recommends
L<http://code.google.com/p/pubsubhubbub/wiki/PublisherEfficiency>.

    $ curl -H 'If-None-Match: "42"' http://localhost/atombus/feeds/widgets

Note that the most messages you will get per request is determined by the
page_size setting.  If you do not specify a page_size setting, it defaults to
1000.  This default may change in the future, so don't count on it.

AtomBus is mostly a proper implementation of the AtomPub protocol and will
validate 100% against L<http://validator.w3.org/feed>.
One point where it diverges from the AtomPub spec is that feed entries are
returned in fifo order.
This is because a message consumer will most likely want to consume messages
in the order that they were published.
In the future, a config setting may be available to reverse the order.

=head1 CONFIGURATION

Configuration can be achieved via a config.yml file or via the set keyword.
To use the config.yml approach, you will need to install L<YAML>.
See the L<Dancer> documentation for more information.
The only required config setting is the dsn.

Example config.yml:

    # Dancer specific config settings
    logger: file
    log: errors

    atombus:
        page_size: 100
        db:
            dsn:  dbi:mysql:database=atombus
            user: joe
            pass: momma

You can alternatively configure the server via the 'set' keyword in the source
code. This approach does not require a config file.

    use Dancer;
    use AtomBus;

    # Dancer specific config settings
    set logger      => 'file';
    set log         => 'debug';
    set show_errors => 1;

    set atombus => {
        page_size => 100,
        db => {
            dsn => 'dbi:SQLite:dbname=/var/local/atombus/atombus.db',
        }
    };

    dance;

=head1 DATABASE

AtomBus is backed by a database.
The dsn in the config must point to a database which you have write privileges
to.
The tables will be created automagically for you if they don't already exist.
Of course that requires create table privileges.
All databases supported by L<DBIx::Class> are supported,
which are most major databases including postgresql, sqlite, mysql and oracle.

=head1 DEPLOYMENT

Deployment is very flexible.
It can be run on a web server via CGI or FastCGI.
It can also be run on any L<Plack> web server.
See L<Dancer::Deployment> for more details.

=head2 FastCGI

AtomBus can be run via FastCGI.
This requires that you have the L<FCGI> and L<Plack> modules installed.
Here is an example FastCGI script.
It assumes your AtomBus server is in the file atombus.pl.

    #!/usr/bin/env perl
    use Dancer ':syntax';
    use Plack::Handler::FCGI;

    my $app = do "/path/to/atombus.pl";
    my $server = Plack::Handler::FCGI->new(nproc => 5, detach => 1);
    $server->run($app);

Here is an example lighttpd config.
It assumes you named the above file atombus.fcgi.

    fastcgi.server += (
        "/atombus" => ((
            "socket" => "/tmp/fcgi.sock",
            "check-local" => "disable",
            "bin-path" => "/path/to/atombus.fcgi",
        )),
    )

Now AtomBus will be running via FastCGI under /atombus.

=head2 Plack

AtomBus can be run with any L<Plack> web server.  Just run:

    plackup atombus.pl

You can change the Plack web server via the -s option to plackup.

=head1 MOTIVATION

I like messaging systems because they make it so easy to create scalable
applications.
Existing message brokers are great for creating message queues.
But once a consumer reads a message off of a queue, it is not available for
other consumers.
I needed a system to publish events such that multiple heterogeneous services
could subscribe to them.
So I really needed a message bus, not a message queue.
I could for example have used something called topics in ActiveMQ,
but I have found ActiveMQ to be broken in general.
An instance I manage has to be restarted daily.
AtomBus on the other hand will be extremely stable, because it is so simple.
It is in essence just a simple interface to a database.
As long as your database and web server are up, AtomBus will be there for you.
And there are many ways to add redundancy to databases and web heads.
Another advantage of using AtomBus is that Atom is a well known standard.
Everyone already has a client for it, their browser.
Aren't standards great!  
By the way, if you just need message queues, try
L<POE::Component::MessageQueue>.
It rocks. If you need a message bus, give AtomBus a shot.

=head1 AUTHOR

Naveed Massjouni <naveedm9@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

