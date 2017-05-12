package App::plackbench;
$App::plackbench::VERSION = '0.5';
use strict;
use warnings;
use autodie;
use v5.10;

use HTTP::Request qw();
use List::Util qw( reduce );
use Plack::Test qw( test_psgi );
use Plack::Util qw();
use Scalar::Util qw( reftype );
use Time::HiRes qw( gettimeofday tv_interval );

use App::plackbench::Stats;

my %attributes = (
    app       => \&_build_app,
    count     => 1,
    warm      => 0,
    fixup     => sub { [] },
    post_data => undef,
    psgi_path => undef,
    uri       => undef,
);
for my $attribute (keys %attributes) {
    my $accessor = sub {
        my $self = shift;

        # $self is a coderef, so yes.. call $self on $self.
        return $self->$self($attribute, @_);
    };

    no strict 'refs';
    *$attribute = $accessor;
}

sub new {
    my $class = shift;
    my %stash = @_;

    # $self is a blessed coderef, which is a closure on %stash. I might end up
    # replacing this with a more typical blessed hashref. But, I don't think
    # it's as awful as it sounds.

    my $self = sub {
        my $self = shift;
        my $key = shift;

        $stash{$key} = shift if @_;

        if (!exists $stash{$key}) {
            my $value = $attributes{$key};

            # If the default value is a subref, call it.
            if (ref($value) && ref($value) eq 'CODE') {
                $value = $self->$value();
            }

            $stash{$key} = $value;
        }

        return $stash{$key};
    };

    return bless $self, $class;
}

sub _build_app {
    my $self = shift;
    return Plack::Util::load_psgi($self->psgi_path());
}

sub run {
    my $self = shift;
    my %args = @_;

    my $app   = $self->app();
    my $count = $self->count();

    my $requests = $self->_create_requests();

    if ( $self->warm() ) {
        $self->_execute_request( $requests->[0] );
    }

    # If it's possible to enable NYTProf, then do so now.
    if ( DB->can('enable_profile') ) {
        DB::enable_profile();
    }

    my $stats = reduce {
        my $request_number = $b % scalar(@{$requests});
        my $request = $requests->[$request_number];

        my $elapsed = $self->_time_request( $request );
        $a->insert($elapsed);
        $a;
    }  App::plackbench::Stats->new(), ( 0 .. ( $count - 1 ) );

    return $stats;
}

sub _time_request {
    my $self = shift;

    my @start = gettimeofday;
    $self->_execute_request(@_);
    return tv_interval( \@start );
}

sub _create_requests {
    my $self = shift;

    my @requests;
    if ( $self->post_data() ) {
        @requests = map {
            my $req = HTTP::Request->new( POST => $self->uri() );
            $req->content($_);
            $req;
        } @{ $self->post_data() };
    }
    else {
        @requests = ( HTTP::Request->new( GET => $self->uri() ) );
    }

    $self->_fixup_requests(\@requests);

    return \@requests;
}

sub _fixup_requests {
    my $self = shift;
    my $requests = shift;

    my $fixups = $self->fixup();
    $fixups = [ grep { reftype($_) && reftype($_) eq 'CODE' } @{$fixups} ];

    for my $request (@{$requests}) {
        $_->($request) for @{$fixups};
    }

    return;
}

sub add_fixup_from_file {
    my $self = shift;
    my $file = shift;

    my $sub = do $file;

    if (!$sub) {
        die($@ || $!);
    }

    if (!reftype($sub) || !reftype($sub) eq 'CODE') {
        die("$file: does not return a subroutine reference");
    }

    my $existing = $self->fixup();
    if (!$existing || !reftype($existing) || reftype($existing) ne 'ARRAY') {
        $self->fixup([]);
    }

    push @{$self->fixup()}, $sub;

    return;
}

sub _execute_request {
    my $self = shift;
    my $request = shift;

    test_psgi $self->app(), sub {
        my $cb       = shift;
        my $response = $cb->($request);
        if ( $response->is_error() ) {
            die "Request failed: " . $response->decoded_content;
        }
    };

    return;
}

1;

__END__

=head1 NAME

App::plackbench - programmatic interface to plackbench

B<See L<plackbench> for the command line tool.>

=head1 SYNOPSIS

    my $bench = App::plackbench->new(
        psgi_path => $psgi_path,
        count     => 5,
        uri       => '/some/path',
    );
    my $stats = $bench->run();

    printf("Averaged %8.3f seconds over %d requests\n", $stats->mean(), $stats->count());

=head1 DESCRIPTION

Class for executing requests on a L<Plack> application and recording stats.

=head1 ATTRIBUTES

=head2 app

Defaults to a L<Plack> app loaded from L<psgi_path>, using L<Plack::Util/load_psgi>.

=head2 count

Number of times to execute the request. Defaults to 1.

=head2 warm

If true, an initial request will be made which won't be included in the stats.
Defaults to false.

=head2 fixup

An arrayref of subroutine references to do any preprocessing of the request.
Each subroutine reference will be called in order (though you shouldn't rely on
that) and passed a reference to the L<HTTP::Request> object.

Each sub will be called once for every unique request. Under a normal GET
request, there will only be one unique request. However if L</post_data> is
being used there will be one unique request for request body.

The return value from the subs is ignored.

=head2 post_data

An arrayref of request bodies. If set, POST requests will be made instead of
GET requests.

If multiple request bodies are set they will be rotated through. This can be
useful, for instance, to cycle through possible values for a field.

=head2 psgi_path

The path to the L<Plack> application to be tested.

=head2 uri

The URI to request on the app.

=head1 CONSTRUCTOR

=head2 C<new(%attributes)>

Returns a new instance of C<App::plackbench>. Any arguments will be used a
attribute settings.

=head1 METHODS

=head2 C<run()>

Executes the requests (using the current attribute settings), and returns an
L<App::plackbench::Stats> object. Takes no arguments.

=head2 C<add_fixup_from_file($file)>

Evaluates C<$file> and appends the returned subroutine reference to L</fixups>.
If the file can't be parsed, or if it doesn't return a subroutine reference the
method will L<die|perlfunc/die>.

=head1 GITHUB

L<https://github.com/pboyd/App-plackbench>

=head1 AUTHOR

Paul Boyd <boyd.paul2@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<plackbench>, L<Plack>
