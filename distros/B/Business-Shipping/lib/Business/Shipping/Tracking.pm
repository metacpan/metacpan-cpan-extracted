package Business::Shipping::Tracking;

=head1 NAME

Business::Shipping::Tracking

=head1 SYNOPSIS

=head2 Example tracking request for USPS:

 use Business::Shipping::USPS_Online::Tracking;

 my $tracker = Business::Shipping::USPS_Online::Tracking->new();

 $tracker->init(
     test_mode => 1,
 );

 $tracker->tracking_ids('EJ958083578US', 'EJ958083578US');

 $tracker->submit() || logdie $tracker->user_error();
 my $hash = $tracker->results();

 use Data::Dumper;
 print Data::Dumper->Dump([$hash]);

=head1 ABSTRACT

Business::Tracking is an API for tracking shipments

=cut

use Data::Dumper;
use Business::Shipping::Logging;
use Business::Shipping::Config;
use CHI;
use Business::Shipping::Package;
use Any::Moose;
use version; our $VERSION = qv('400');

extends 'Business::Shipping';

has 'is_success' => (is => 'rw');
has 'invalid'    => (is => 'rw');
has 'test_mode'  => (is => 'rw');
has 'user_id'    => (is => 'rw');
has 'password'   => (is => 'rw');
has 'cache_time' => (is => 'rw');
has 'cache'      => (is => 'rw');
has 'cache_config' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { driver => 'File' } },
);

# Used to be a static class attribute
has 'results'       => (is => 'rw', isa => 'HashRef');
has '_tracking_ids' => (is => 'rw', isa => 'ArrayRef');
has 'packages'      => (
    is         => 'rw',
    isa        => 'ArrayRef[Business::Shipping::Package]',
    default    => sub { [Business::Shipping::Package->new()] },
    auto_deref => 1
);

has 'user_agent' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new() },
);

has 'response' => (
    is      => 'rw',
    isa     => 'HTTP::Response',
    default => sub { HTTP::Response->new() },
);

__PACKAGE__->meta()->make_immutable();

sub Required {
    return ($_[0]->SUPER::Required, qw/ user_id password /);
}

sub Optional {
    return ($_[0]->SUPER::Required, qw/ prod_url test_url /);
}

sub _delete_undefined_keys {
    my $hash_ref = shift;

    map {
        if (defined($hash_ref->{$_}) && ref($hash_ref->{$_}) eq 'HASH')
        {
            _delete_undefined_keys($hash_ref->{$_});
            if (scalar(keys %{ $hash_ref->{$_} }) == 0) {
                delete $hash_ref->{$_};
            }
        }
        elsif (defined($hash_ref->{$_})
            && ref($hash_ref->{$_}) eq 'ARRAY')
        {
            foreach my $element (@{ $hash_ref->{$_} }) {
                if (ref($element) eq 'HASH') {
                    _delete_undefined_keys($element);
                }
            }
        }
        elsif (!defined($hash_ref->{$_})) {
            delete $hash_ref->{$_};
        }
    } keys %$hash_ref;
}

=head1 SEE ALSO

L<Business::Shipping::UPS_Online::Tracking>
L<Business::Shipping::USPS_Online::Tracking>

=cut

sub submit {
    my ($self, %args) = @_;
    trace('()');

    $self->init(%args) if %args;
    $self->validate() or return;

    my $cache_results;
    if ($self->cache()) {
        trace('cache enabled');

        my $cache = CHI->new(%{ $self->cache_config });

        foreach my $id (@{ $self->tracking_ids }) {
            my $key = $self->gen_unique_key($id);
            info "cache key = $key\n";

            my $cache_result = $cache->get($key);

            if (defined($cache_result)) {
                $cache_results->{$id} = $cache_result;
            }
            else {
                trace(
                    "Cache miss on id $id, running request manually, then add to cache."
                );
            }
        }

        # Save the results that we have.
        $self->results(%$cache_results);
    }
    else {
        trace('cache disabled');
    }

    my @requests = $self->_gen_request();
    while (my $request = shift @requests) {
        trace('Please wait while we get a response from the server...');
        $self->response($self->_get_response($request));
        trace("response content = " . $self->response()->content());

        if (!$self->response()->is_success()) {

            #
            # If we're getting http errors we should bomb out.
            #
            $self->user_error("HTTP Error. Status line: "
                    . $self->response->status_line
                    . "Content: "
                    . $self->response->content());
            $self->is_success(0);
            last;
        }

        # Only cache if there weren't any errors.

        $self->_handle_response();

        if (scalar(@requests) > 0) {

# Sleep 2 seconds between requests, due to recommendation in USPS tracking document.
# Seems to be prudent for other providers too.
            trace 'sleeping for 2 seconds';
            sleep 2;
        }
    }

    if ($self->cache()) {
        trace('cache enabled, saving results.');

   #TODO: Allow setting of cache properties (time limit, enable/disable, etc.)
        my $new_cache = CHI->new(%{ $self->cache_config });

        foreach my $id ($self->results_keys) {
            my $key = $self->gen_unique_key($id);

# Don't overwrite the result if it was pulled from the cache, otherwise the cache
# would never expire.
            if (exists($cache_results->{$id})) {
                next;
            }
            my $value = $self->results_index($id);
            $new_cache->set($key, $value,
                ($self->cache_time() || "12 hours"));
        }
    }
    else {
        trace('cache disabled, not saving results.');
    }

    $self->is_success(1);

    return $self->is_success();
}

sub validate {
    my ($self) = @_;
    trace '()';

    if (scalar(@{ $self->tracking_ids() }) == 0) {
        $self->invalid(1);
        $self->user_error("No tracking ids passed to track");
        return 0;
    }

    if (!defined($self->user_id)) {
        $self->invalid(1);
        $self->user_error("No user_id specified");
        return 0;

    }

    if (!defined($self->password)) {
        $self->invalid(1);
        $self->user_error("No password specified");
        return 0;

    }

    return 1;
}

sub _get_response {
    trace '()';
    return $_[0]->user_agent->request($_[1]);
}

=head2 tracking_ids

The Class::MethodMaker-based system accepted any number of inputs to assigned
it to the internal arrayref. As part of moving to Any::Moose, this is changed 
to using a real arrayref at _tracking_ids, and providing this tracking_ids()
as syntactic sugar.

=cut

sub tracking_ids {
    my $self = shift;

    # Check for new Any::Moose-style arrayref syntax.
    $self->_tracking_ids($_[0]) if (ref($_[0]) eq 'ARRAY');

    # Old-stay list input
    $self->_tracking_ids(\@_) if @_;

    # Read-only usage.
    return @{ $self->_tracking_ids() }
        if wantarray();

    return $self->_tracking_ids();
}

=head2 results_exists

Backwards-compat for Class::MethodMaker 1.12-style _exists() method.

=cut

sub results_exists {
    my ($self, $key) = @_;
    my $results_hash = $self->results;
    return 1 if exists $results_hash->{$key};
    return 0;
}

1;
__END__

=head1 AUTHOR

Rusty Conover <rconover@infogears.com>

=head1 COPYRIGHT AND LICENCE

Copyright 2004-2007 Infogears Inc. Portions Copyright 2003-2011 Daniel 
Browning <db@kavod.com>. All rights reserved. This program is free 
software; you may redistribute it and/or modify it under the same terms as 
Perl itself. See LICENSE for more info.

=cut
