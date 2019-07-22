package DataLoader::Test;

=encoding utf8

=head1 NAME

DataLoader::Test - unit test utilities

=head1 DESCRIPTION

Contains utilities used across multiple unit tests.

=head1 EXPORTED FUNCTIONS

=over

=cut

use v5.14;
use warnings;

use AnyEvent;
use Test::More;

use DataLoader;

use Exporter 'import';
our @EXPORT_OK = qw(
    is_promise_ok
    await
    make_test_loader
    id_loader
);

=item is_promise_ok ( OBJECT, [MESSAGE] )

Asserts that OBJECT is a Promise.

=cut

sub is_promise_ok {
    my ($obj, $message) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    isa_ok( $obj, 'Mojo::Promise', $message );
}

=item await ( PROMISE, [TIMEOUT] )

Converts a Promise into an AnyEvent condvar and waits for its completion.
Returns the resolved value or (if rejected) throws an exception.

Because unit tests are not event-loop aware, there is a default timeout of 1
second (which may be overriden). This is an easier alternative to wrapping each
unit test in a timeout.

=cut

sub await {
    my ($promise, $timeout) = @_;
    $timeout ||= 1;

    my $cv = AE::cv;
    my $timer = AE::timer $timeout, 0, sub { $cv->croak("timed out") };
    $promise->then(sub { $cv->send(@_) })
            ->catch(sub { $cv->croak(@_) });
    return $cv->recv;
}

=item (loader, calls_ref) = make_test_loader ( function, %options )

Accepts a function that takes a key C<$_> and returns some value, or a
L<DataLoader::Error>.

Wraps the function into a loader that executes that function against all
incoming keys and returns a resolved Promise with the result, and also
logs each set of keys required to an arrayref. For example, if the
data loader is called twice: first with ('1') and second with ('1','2')
the arrayref will be C<[[1], [1,2]]>.

Any options in C<%options> are passed to the L<DataLoader> constructor.

Returns a 'tuple' of the L<DataLoader> object and the arrayref.

=cut

sub make_test_loader(&@) {
    my ($fn, %options) = @_;
    my @load_calls;
    my $loader = DataLoader->new(sub {
        my @keys = @_;
        push @load_calls, \@keys;
        my @values = map { $fn->() } @keys;
        return Mojo::Promise->resolve(@values);
    }, %options);

    return ($loader, \@load_calls);
}

=item (loader, calls_ref) = id_loader ( %options )

Returns (loader, calls_ref) for a loader that simply returns keys as values.

i.e. await($id_loader->load(1)) == 1

=cut

sub id_loader {
    my %options = @_;
    return make_test_loader { $_ } %options;
}

1;

=back

=cut
