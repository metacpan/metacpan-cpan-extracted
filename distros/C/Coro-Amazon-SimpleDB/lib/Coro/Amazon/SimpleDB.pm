package Coro::Amazon::SimpleDB;
use common::sense;

$Coro::Amazon::SimpleDB::VERSION = 0.04;

use EV;
use AnyEvent;
use Coro;
use Coro::AnyEvent;

use Carp qw(croak carp);
use Scalar::Util qw(blessed);
use List::Util qw(first);

use Amazon::SimpleDB::Client;
use Amazon::SimpleDB::Model::BatchPutAttributesRequest;
use Amazon::SimpleDB::Model::CreateDomainRequest;
use Amazon::SimpleDB::Model::DeleteAttributesRequest;
use Amazon::SimpleDB::Model::DeleteDomainRequest;
use Amazon::SimpleDB::Model::DomainMetadataRequest;
use Amazon::SimpleDB::Model::GetAttributesRequest;
use Amazon::SimpleDB::Model::ListDomainsRequest;
use Amazon::SimpleDB::Model::PutAttributesRequest;
use Amazon::SimpleDB::Model::SelectRequest;



use Moose;

has 'aws_access_key' => (is => 'rw');
has 'aws_secret_access_key' => (is => 'rw');
has 'domain_name' => (is => 'rw');
has 'sdb' => (is => 'ro', lazy_build => 1);
has 'pending' => (is => 'ro', default => sub { {} });

has 'DEBUG' => (is => 'rw', default => !1);

no Moose;



REPLACE_AMAZON_SIMPLEDB_CLIENT_HTTPPOST: {
    package Amazon::SimpleDB::Client;
    use common::sense;
    use AnyEvent::HTTP;
    use HTTP::Request;
    use HTTP::Response;

    # The only mention of a time-out in Amazon::SimpleDB::Client is in
    # reference to a select operation.  I'm using the value from there
    # (5 seconds) as the default time-out for HTTP requests, as it
    # seems reasonable.  The setting is dynamic, but is used prior to
    # putting HTTP request coros into wait state so it should do the
    # expected thing if it's changed.  Caveat emptor.

    our $HTTP_REQUEST_TIMEOUT = 5;

    # Replace the _httpPost method in Amazon::SimpleDB::Client to use
    # an HTTP lib which does non-blocking requests better than
    # Coro::LWP.  This dangerously violates Amazon::SimpleDB::Client's
    # encapsulation and has some code copied from the original
    # _httpPost.  There is a chance that changes to Amazon's module
    # could break this.

    no warnings 'redefine';

    sub _httpPost {
	my ($self, $parameters) = @_;
        my $response = undef;
        http_request
            POST    => $self->{_config}{ServiceURL},
            body    => join('&', map { $_ . '=' . $self->_urlencode($parameters->{$_}, 0) } keys %{$parameters}),
            timeout => $HTTP_REQUEST_TIMEOUT,
            headers => { 'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8' },
            sub {
                my ($body, $headers) = @_;
                $response = HTTP::Response->new(@{$headers}{qw( Status Reason )});
                $response->content($body);
                $response->header($_, $headers->{$_})
                    for grep { !/[[:upper:]]/ } keys %{$headers};
            };
        # We need to put this coro to sleep until the response is returned.
        while (not defined $response) { Coro::AnyEvent::sleep 0.1 }
        return $response;
    }
}


ADD_DISPATCH_HELPER_METHODS: {
    # These methods are helpers so we can do method mapping via real
    # dispatch.  It would be nice if Amazon's library could do this
    # dispatching for us.
    sub Amazon::SimpleDB::Model::BatchPutAttributesRequest::client_request_method { 'batchPutAttributes' }
    sub Amazon::SimpleDB::Model::CreateDomainRequest::client_request_method { 'createDomain' }
    sub Amazon::SimpleDB::Model::DeleteAttributesRequest::client_request_method { 'deleteAttributes' }
    sub Amazon::SimpleDB::Model::DeleteDomainRequest::client_request_method { 'deleteDomain' }
    sub Amazon::SimpleDB::Model::DomainMetadataRequest::client_request_method { 'domainMetadata' }
    sub Amazon::SimpleDB::Model::GetAttributesRequest::client_request_method { 'getAttributes' }
    sub Amazon::SimpleDB::Model::ListDomainsRequest::client_request_method { 'listDomains' }
    sub Amazon::SimpleDB::Model::PutAttributesRequest::client_request_method { 'putAttributes' }
    sub Amazon::SimpleDB::Model::SelectRequest::client_request_method { 'select' }
}



# Debugging methods.


sub _bug_process_message {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse = 1;
    my $message = shift;
    my $result
        = (not defined $message)                             ? '<undef>'
        : (ref $message eq q())                              ? $message
        : (blessed($message) and $message->can('as_string')) ? scalar $message->as_string
        : blessed($message)                                  ? "$message"
        :                                                      Dumper($message)
        ;
    return $result;
}


sub _bug_message {
    my $message_array_ref = shift || [];
    my $caller_level = shift || 0;
    if (ref $message_array_ref ne 'ARRAY') {
        warn "message_array_ref is not an array ref";
        $message_array_ref = [];
    }
    $message_array_ref = [ "something is interesting" ]
        unless @{$message_array_ref};
    my $message = join((defined $, ? $, : q()), map { _bug_process_message($_) } @{$message_array_ref});
    my @caller = caller($caller_level);
    $message .= " at $caller[1] line $caller[2]\n" unless $message =~ /\n/xms;
    return $message;
}


sub bug {
    my $self = shift;
    $self->DEBUG ? print STDERR _bug_message(\@_, 1) : undef;
}



sub _build_sdb {
    my $self = shift;
    my $sdb = Amazon::SimpleDB::Client->new(
        $self->aws_access_key,
        $self->aws_secret_access_key,
    );
    return $sdb;
}


sub _normalize_sdb_request {
    my $self = shift;
    my $request = shift;

    # A scalar is interpreted as a request for an item name in the
    # canonical domain.
    return Amazon::SimpleDB::Model::GetAttributesRequest->new({
        DomainName => $self->domain_name,
        ItemName => $request,
    })
        unless ref $request;

    # A hash ref is interpreted as an argument to a call to the 'new'
    # method of the class specified by the 'RequestType' key.  This
    # key will be removed prior to call 'new', a 'DomainName' key will
    # be added if needed, and the class called may be aliased as
    # specified in the anonymous hash below.
    if (ref $request eq 'HASH') {
        # Copy the request to avoid side effects.
        my %request = (
            DomainName => $self->domain_name,
            %{$request},
        );
        my $type = delete $request{RequestType}
            or croak "missing RequestType in request";
        my $class = {
            BatchPutAttributesRequest => 'Amazon::SimpleDB::Model::BatchPutAttributesRequest',
            batchPutAttributes        => 'Amazon::SimpleDB::Model::BatchPutAttributesRequest',
            CreateDomainRequest       => 'Amazon::SimpleDB::Model::CreateDomainRequest',
            createDomain              => 'Amazon::SimpleDB::Model::CreateDomainRequest',
            DeleteAttributesRequest   => 'Amazon::SimpleDB::Model::DeleteAttributesRequest',
            deleteAttributes          => 'Amazon::SimpleDB::Model::DeleteAttributesRequest',
            DeleteDomainRequest       => 'Amazon::SimpleDB::Model::DeleteDomainRequest',
            deleteDomain              => 'Amazon::SimpleDB::Model::DeleteDomainRequest',
            DomainMetadataRequest     => 'Amazon::SimpleDB::Model::DomainMetadataRequest',
            domainMetadata            => 'Amazon::SimpleDB::Model::DomainMetadataRequest',
            GetAttributesRequest      => 'Amazon::SimpleDB::Model::GetAttributesRequest',
            getAttributes             => 'Amazon::SimpleDB::Model::GetAttributesRequest',
            ListDomainsRequest        => 'Amazon::SimpleDB::Model::ListDomainsRequest',
            listDomains               => 'Amazon::SimpleDB::Model::ListDomainsRequest',
            PutAttributesRequest      => 'Amazon::SimpleDB::Model::PutAttributesRequest',
            putAttributes             => 'Amazon::SimpleDB::Model::PutAttributesRequest',
            SelectRequest             => 'Amazon::SimpleDB::Model::SelectRequest',
            select                    => 'Amazon::SimpleDB::Model::SelectRequest',
        }->{$type} || $type;
        return $class->new(\%request);
    }

    # An Amazon::SimpleDB::Model instance is almost left alone.  The
    # only processing done is adding a DomainName if needed.  This is
    # done directly on the class, so this produces a side-effect.
    if (blessed $request and $request->isa('Amazon::SimpleDB::Model')) {
        # Amazon's class hierarchy is very unfortunate.  It would be
        # nice to handle these as a base class but that's not how it
        # was designed.
        $request->setDomainName($self->domain_name)
            if first { $request->isa("Amazon::SimpleDB::Model::$_") } qw(
                BatchPutAttributesRequest
                DeleteAttributesRequest
                GetAttributesRequest
                PutAttributesRequest
                SelectRequest
            )
            and not $request->isSetDomainName
            ;
        return $request;
    }

    croak "can't normalize '".(ref $request)."' request to an Amazon::SimpleDB::Model";
}


sub _process_request {
    my $self = shift;
    my $request = $self->_normalize_sdb_request(shift);
    my $method = $request->client_request_method
        or croak "no processing for request of type '".(ref $request)."'";
    return $self->sdb->$method($request);
}


sub add_pending {
    my $self = shift;
    $self->pending->{$_} = $_ for @_;
    return $self;
}

sub remove_pending {
    my $self = shift;
    delete $self->pending->{$_} for @_;
    return $self;
}

sub has_pending { !!%{ shift->pending } }


sub poll {
    my $self = shift;
    async {
        CHECK_LOOP: {
            # Keep polling as long as there are pending requests.
            if ($self->has_pending) {
                Coro::AnyEvent::sleep 0.1;
                redo CHECK_LOOP;
            }
            EV::unloop;
        }
    };
    EV::loop;
    return $self;
}


sub async_requests {
    my ($self, @requests) = @_;

    my $debug = $self->DEBUG;
    require Time::HiRes and Time::HiRes->import('time') if $debug;
    my ($start, $duration) = (0, 0);
    my @responses = ();
    $self->bug("starting async enqueues");
    $start = time() if $debug;
    for ($[ .. $#requests) {
        my $idx = $_;
        my $request = $requests[$idx];
        $self->bug("adding request $request");
        my $coro = async {
            my ($start, $duration) = (0, 0);
            $self->bug("starting request for $request");
            $start = time() if $debug;
            $responses[$idx] = eval { $self->_process_request($request) };
            # Store the exception instead of the response (which
            # should be undef) if there was a problem.
            $responses[$idx] = $@ if $@;
            $duration = time() - $start if $debug;
            $self->bug("completed request for $request in $duration secs");
        };
        $self->add_pending($coro);
        $coro->on_destroy(sub { $self->remove_pending($coro) });
    }
    $duration = time() - $start if $debug;
    $self->bug("completed async enqueues in $duration secs, starting coro polling");
    $self->poll;

    return \@responses;
}


sub async_get_items {
    my ($self, @items) = @_;
    my $responses = $self->async_requests(@items);
    my %items = map {
        my $item_name = $items[$_];
        my $response = $responses->[$_];
        my $attributes
            = (ref $response eq 'Amazon::SimpleDB::Model::GetAttributesResponse') ?
                  {
                      map {
                          defined $_->getName ? ($_->getName, $_->getValue) : ()
                      } @{ $response->getGetAttributesResult->getAttribute }
                  }
            :     $response
            ;
        ($item_name => $attributes);
    } $[ .. $#items;
    return \%items;
}



1;

__END__

=head1 NAME

Coro::Amazon::SimpleDB - Use C<Amazon::SimpleDB::Client> to do asynchronous requests


=head1 VERSION

Version 0.01


=head1 SYNOPSIS

An asynchronous layer on top of Amazon's SimpleDB library.

  use Coro::Amazon::SimpleDB;

  my $sdb = Coro::Amazon::SimpleDB->new;
  $sdb->aws_access_key($aws_access_key_id);
  $sdb->aws_secret_access_key($aws_secret_access_key);
  $sdb->domain_name($aws_simpledb_domain);

  my $attributes = $sdb->async_get_items('name', 'rank', 'serial-number');
  my $full_name = join(' ', @{ $attributes->{name} }{'first', 'last'};


=head1 METHODS

=head2 new

Create and return a new instance.  The usual idiom is:

  my $sdb = Coro::Amazon::SimpleDB->new(
    aws_access_key        => $key,
    aws_secret_access_key => $secret_key,
    domain_name           => $domain,
  );

  # ... do stuff with the instance


=head2 async_requests

The main method of the asynchronous interface.  This method takes a
list of item names, hash refs representing requests, or request
objects and asynchronously requests them then polls and gathers the
results, returning the response objects (or exception objects if the
call failed) in an array ref ordered identically to the corresponding
requests.  The call will succeed even if some or all of the requests
failed.  It is up to the caller to check each entry in the response
array to see if the call succeeded.

This method tries to keep the interface consistent with the
C<Amazon::SimpleDB::Client> interface.  The 2 main differences are the
assumption that a scalar argument is a request for all the attributes
of the item name specified by the value, and an additional key,
RequestType, which must be added to hash refs passed in to specify the
request type.  If an C<Amazon::SimpleDB::Model::*Request> instance is
passed in the correct method in the C<Amazon::SimpleDB::Client>
library is called automatically.

The RequestType key may be the full module name of the request class,
the last part of the request class (e.g. GetAttributesRequest), or the
appropriate method in C<Amazon::SimpleDB::Client> (e.g. getAttributes).

Some examples:

  # $results will contain an array ref of
  # Amazon::SimpleDB::Model::GetAttributes::Reponse objects.
  my $results = $sdb->async_requests(qw( name rank serial-number ));

  # Same as above using hash refs as args.
  my $results = $sdb->async_requests(
    { RequestType => 'getAttributes', ItemName => 'name' },
    { RequestType => 'getAttributes', ItemName => 'rank' },
    { RequestType => 'getAttributes', ItemName => 'serial-number' },
  );

  # Same as above, but manually building our own objects.
  my $name_obj = Amazon::SimpleDB::Model::GetAttributesRequest->new({ ItemName => 'name' });
  my $rank_obj = Amazon::SimpleDB::Model::GetAttributesRequest->new({ ItemName => 'rank' });
  my $sn_obj = Amazon::SimpleDB::Model::GetAttributesRequest->new({ ItemName => 'serial-number' });
  my $results = $sdb->async_requests($name, $rank, $sn);

  # Combining several request types to be executed in a single
  # asynchronous batch.  It is inadvisable to both set and get the
  # same item in a single batch as the value returned is unspecified.
  my $results = $sdb->async_requests(
    { RequestType => 'getAttributes', ItemName => 'the-guide' },
    {
      RequestType => 'getAttributes',
      ItemName => 'heart-of-gold',
      AttributeName => [ 'specs', 'price' ],
    },
    {
      RequestType => 'putAttributes',
      ItemName => 'marvin',
      Attribute => [
        { Name => 'age-in-universe-lifetimes', Value => 2 },
        { Name => 'depression', Value => 'extreme' },
      ],
    },
  );

=head2 async_get_items

This is a convenience method for requesting items.  It takes a list of
item names and will return the corresponding attributes in a hash ref.

If an item with an identical name (either in the same domain or not)
is requested multiple times it is undefined what the final result will
be.

  my @keys = qw( ford arthur zaphod );
  my $results = $sdb->async_get_items(@keys);
  my $total_heads = sum map { $results->{$_}{head_count} } @keys;

=head2 poll

This method will poll the EV event loop until the pending attribute is
empty.  It is usually used internally but is available if users want
to build their own asynchronous calls.

=head2 add_pending

A convenience method to add an item to the pending hash.

=head2 remove_pending

A convenience method to remove an item from the pending hash.

=head2 has_pending

Returns true if there are items in the pending hash.

=head2 bug

A debugging method which will print a message similar to a warn if the
object has its DEBUG attribute set to a true value.  If DEBUG is false
it does nothing and immediately returns undef.


=head1 ATTRIBUTES

=head2 aws_access_key
=head2 aws_secret_access_key

These are the AWS credentials providing access to your account.  These
should be available on security credentials page of the AWS portal.

=head2 domain_name

A default domain to use for requests.  This may be over-ridden in
requests passed as hash refs or objects.

=head2 sdb

The C<Amazon::SimpleDB::Client> object to forward requests through.
This is automatically created when first requested, but may also be
passed in manually.

=head2 pending

A hash ref of pending coros.  This is used internally to poll for
completion of all asynchronous requests.

=head2 DEBUG

If set to a true value, the library will output some debugging and
timing information.


=head1 CAVEATS

The Amazon SimpleDB client is required, but is not currently available
via CPAN.  It is available here as of 2010-10-20:

http://developer.amazonwebservices.com/connect/entry.jspa?externalID=1136


=head1 AUTHOR

Dave Trischuk, C<< <dtrischuk at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-coro-amazon-simpledb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Coro-Amazon-SimpleDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Coro::Amazon::SimpleDB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Coro-Amazon-SimpleDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Coro-Amazon-SimpleDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Coro-Amazon-SimpleDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Coro-Amazon-SimpleDB/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Campus Explorer http://www.campusexplorer.com/

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License Version
3.0 as published by the Free Software Foundation (see
http://www.gnu.org/licenses/gpl.html); or the Artistic License 2.0
(see http://www.opensource.org/licenses/artistic-license-2.0.php).
