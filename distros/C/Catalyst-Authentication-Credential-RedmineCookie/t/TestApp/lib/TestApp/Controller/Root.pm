package TestApp::Controller::Root;

use base qw(Catalyst::Controller);

use YAML::Syck;

sub index :Path('/') {
    my ($self, $c) = @_;

    $c->authenticate;
    $c->res->content_type("text/plain; charset=utf-8");

    my sub code { $c->res->write("$_[0]\n@{[ (eval($_[0])||'err:'.$@) =~ s/^/\t/mgr ]}\n\n") }

    code '$c->get_auth_realm("redmine_cookie")->store';
    code '$c->user';

    if ($c->user) {
        code 'ref $c->user';
        code 'ref $c->user->get_object';
        if ($c->get_auth_realm('redmine_cookie')->store =~ /Null/) {
            code 'Dump $c->user';
        }
    }
}

1;
