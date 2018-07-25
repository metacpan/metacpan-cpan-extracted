package Data::Chronicle::Subscriber;

use 5.014;
use strict;
use warnings;
use Data::Chronicle;
use Date::Utility;
use JSON::MaybeUTF8 qw(encode_json_utf8);
use Moose;

=head1 NAME

Data::Chronicle::Subscriber - Provides callback subscriptions to an efficient data storage for volatile and time-based data

=cut

our $VERSION = '0.19';    ## VERSION

=head1 DESCRIPTION

This module contains helper methods which can be used to store and retrieve information
on an efficient storage with below properties:

=over 4

=item B<Timeliness>

It is assumed that data to be stored are time-based meaning they change over time and the latest version is most important for us.

=item B<Efficient>

The module uses Redis cache to provide efficient data storage and retrieval.

=item B<Persistent>

In addition to caching every incoming data, it is also stored in PostgreSQL for future retrieval.

=item B<Transparent>

This modules hides all the internal details including distribution, caching, and database structure from the developer. He only needs to call a method
to save data and another method to retrieve it. All the underlying complexities are handled by the module.

=back

=head1 EXAMPLE

 my $d = get_some_log_data();

 my $chronicle_w = Data::Chronicle::Writer->new(
    cache_writer   => $writer,
    dbic           => $dbic,
    ttl            => 86400,
    publish_on_set => 1);

 my $chronicle_s = Data::Chronicle::Subscriber->new(
    cache_reader => $subscriber);

 #subscribe to changes to syslog
 $chronicle_s->subscribe("log_files", "syslog", sub { print 'Hello World' });

 #store data into Chronicle - each time we call `set` it will also call
 #the stored subroutine
 $chronicle_w->set("log_files", "syslog", $d);

 #unsubscribe to changes to syslog
 $chronicle_s->unsubscribe("log_files", "syslog");

=cut

=head1 METHODS

=head2 cache_subscriber

cache_subscriber should be an instance of L<RedisDB>.

=cut

has 'cache_subscriber' => (
    is      => 'ro',
    default => undef,
);

=head2 subscribe

Example:

    $chronicle_writer->subscribe("category1", "name1", $code_ref);

=cut

sub subscribe {
    my ($self, $category, $name, $callback) = @_;
    die 'Subscription requires a coderef' if ref $callback ne 'CODE';

    my $key = $self->_generate_key($category, $name);
    return $self->cache_subscriber->subscribe($key, $callback);
}

=head2 unsubscribe

Example:

    $chronicle_writer->unsubscribe("category1", "name1");

=cut

sub unsubscribe {
    my ($self, $category, $name) = @_;

    my $key = $self->_generate_key($category, $name);
    return $self->cache_subscriber->unsubscribe($key);
}

sub _generate_key {
    my ($self, $category, $name) = @_;
    return $category . '::' . $name;
}

no Moose;

=head1 AUTHOR

Binary.com, C<< <support at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-chronicle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Chronicle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Chronicle::Subscriber


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Chronicle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Chronicle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Chronicle>

=item * Search CPAN

L<https://metacpan.org/release/Data-Chronicle/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

1;
