package CatalystX::Test::Most;
use strictures;
no warnings "uninitialized";
use HTTP::Request::Common ( qw{ GET POST DELETE PUT } );
use Test::More;
use Test::Fatal;
our $AUTHORITY = "cpan:ASHLEY";
our $VERSION = "0.05";
our @EXPORT = ( qw{ GET POST DELETE PUT },
                qw{ request ctx_request action_redirect },
                qw{ exception },
                qw{ ctx mech },
                grep { defined &{$_} } @Test::More::EXPORT );

my ( $App, $Args ); # Save for mech.
sub import {
    my $package = shift;
    ( $App, $Args ) = @_;
    my $calling_package = [ caller() ]->[0];

    strictures->import;

    require Catalyst::Test;
    Catalyst::Test->import($App, $Args);

    {
        no strict "refs";
        *{"${calling_package}::$_"} = \&{$_} for @EXPORT;
    }
}

# delete is obviously a problem and the rest should maybe be the uc
# anyway and not export the HTTP::Request::Common ones or something new?
#sub get    { request( GET( @_ ) ); }
#sub put    { request( PUT( @_ ) ); }
#sub post   { request( POST( @_ ) ); }
#sub delete { request( DELETE( @_ ) ); }

sub ctx { [ ctx_request(@_) ]->[1] }

# No args means function call.
sub mech {
    my $self = shift if $_[0] eq __PACKAGE__; # Toss it.
    my @args = ( catalyst_app => +shift || $App );
    push @args, shift if @_;
    require Test::WWW::Mechanize::Catalyst;
    Test::WWW::Mechanize::Catalyst
          ->new( @args );
}

1;

__END__

=pod

=head1 Name

CatalystX::Test::Most - Test base pulling in L<Catalyst::Test>, L<Test::More>, L<Test::Fatal>, and L<HTTP::Request::Common> for unit tests on Catalyst applications.

=head1 Synopsis

 use CatalystX::Test::Most "MyApp";

 subtest "Tests with plain Catalyst::Test" => sub {
     ok request("/")->is_success, "/ is okay";
     is exception { request("/no-such-uri") }, undef,
        "404s do not throw exceptions";
     is request("/no-such-uri")->code, 404, "And do return 404";
 };

 subtest "Tests with Test::WWW::Mechanize::Catalyst" => sub {
    my $mech = mech();
    $mech->get_ok("/", "GET /");
    $mech->content_contains("OHAI", "That's my app all right");
 };

 done_testing();

 #    ok 1 - / is okay
 #    ok 2 - 404s do not throw exceptions
 #    ok 3 - And do return 404
 #    1..3
 # ok 2 - Tests with plain Catalyst::Test
 #    ok 1 - GET /
 #    ok 2 - My app all right
 #    1..2
 # ok 3 - Tests with Test::WWW::Mechanize::Catalyst

=head1 Exported Functions from Other Packages

=head2 Catalyst::Test

Everything, so see its documentation: L<Catalyst::Test>. L<CatalystX::Test::Most> is basically an overloaded version of it.

=head2 Test::More

All of its exported functions; see its documentation: L<Test::More>.

=head2 Test::Fatal

See C<exception> in L<Test::Fatal>.

=head2 Test::WWW::Mechanize::Catalyst

You have easy access to a L<Test::WWW::Mechanize::Catalyst> object. There are no related functions, just the object methods.

=head1 New Functions

=over 4

=item * C<ctx>

This is a wrapper to get the context object. It will only work on local tests (not remote servers).

=item * C<mech>

Get a L<Test::WWW::Mechanize::Catalyst> object. Unless specified, the app name and the arguments are recycled from the C<import> of L<CatalystX::Test::Most>.

=back

=head1 Notes

L<strictures> are exported.

=head1 Copyright and License

Ashley Pond V. Artistic License 2.0.

=cut
