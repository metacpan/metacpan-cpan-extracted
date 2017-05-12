package # hide from PAUSE
    MyApp::Controller;

# inspect the request cookie
if ($c->req->valid_cookie($cname)) {
    # hash is okay, do something here
}
else {
    # hash not okay, invalid cookie!
}

# =================================================================

# this is the basic response cookie,
# the hash is automatically added by the plugin
$c->res->cookies->{$cname} = {
    domain  => 'example.com',
    path    => '/',
    secure  => 1,
};

1;
