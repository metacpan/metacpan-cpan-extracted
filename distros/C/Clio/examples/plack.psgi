
use Plack::Builder;
use Plack::Middleware::Chunked;

sub authen_cb {
    my($username, $password) = @_;
    return $username eq 'admin' && $password eq 's3cr3t';
}

sub {
    my $app = shift;
    $DB::single=1;
#    return $app;
    return Plack::Middleware::Chunked->wrap($app);
    builder {
#        enable "Auth::Basic", authenticator => \&authen_cb;
        $app;
    };
}
