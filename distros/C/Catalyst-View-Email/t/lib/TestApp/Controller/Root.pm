package  # Hide from PAUSE
    TestApp::Controller::Root;

use base qw(Catalyst::Controller);

use Encode;

sub default : Private {
    my ( $self, $c ) = @_;

    $c->res->body(qq{Nothing Here});
}

sub email : Global('email') {
    my ($self, $c, @args) = @_;

    my $time = $c->req->params->{time} || time;

    $c->stash->{email} = {
        to      => 'test-email@example.com',
        from    => 'no-reply@example.com',
        subject => 'Email Test',
        body    => "Email Sent at: $time"
    };

    $c->forward('TestApp::View::Email');

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Email Failed');
    } else {
        $c->res->body('Plain Email Ok');
    }
}

sub email_app_config : Global('email_app_config') {
    my ($self, $c, @args) = @_;

    my $time = $c->req->params->{time} || time;

    $c->stash->{email} = {
        to      => 'test-email@example.com',
        from    => 'no-reply@example.com',
        subject => 'Email Test',
        body    => "Email Sent at: $time"
    };

    $c->forward('TestApp::View::Email::AppConfig');

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Email Failed');
    } else {
        $c->res->body('Plain Email Ok');
    }
}

sub template_email : Global('template_email') {
    my ($self, $c, @args) = @_;

    $c->stash->{time} = $c->req->params->{time} || time;

    $c->stash->{email} = {
        to           => 'test-email@example.com',
        from         => 'no-reply@example.com',
        subject      => 'Just a test',
        content_type => 'multipart/alternative',
        templates => [
            {
                template        => 'text_plain/test.tt',
                content_type    => 'text/plain',
            },
            {
                view            => 'TT',
                template        => 'text_html/test.tt',
                content_type    => 'text/html',
            },
        ],
    };

    $c->forward('TestApp::View::Email::Template');    

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Template Email Failed');
    } else {
        $c->res->body('Template Email Ok');
    }
}

sub template_email_single : Global('template_email_single') {
    my ($self, $c, @args) = @_;

    $c->stash->{time} = $c->req->params->{time} || time;

    $c->stash->{email} = {
        to           => 'test-email@example.com',
        from         => 'no-reply@example.com',
        subject      => 'Just a test',
        content_type => 'multipart/alternative',
        templates =>  {
            view            => 'TT',
            template        => 'text_html/test.tt',
            content_type    => 'text/html',
        },
        
    };

    $c->forward('TestApp::View::Email::Template');    

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Template Email Failed');
    } else {
        $c->res->body('Template Email Ok');
    }
}

sub template_email_utf8 : Global('template_email_utf8') {
    my ($self, $c, @args) = @_;

    $c->stash->{time} = $c->req->params->{time} || time;

    $c->stash->{chars} = decode('utf-8', "✔ ✈ ✉");

    $c->stash->{email} = {
        to           => 'test-email@example.com',
        from         => 'no-reply@example.com',
        subject      => 'Just a test',
        content_type => 'multipart/alternative',
       templates => [
            {
                template        => 'text_plain/test.tt',
                content_type    => 'text/plain',
                charset      => 'utf-8',
                encoding     => 'quoted-printable',
            },
            {
                view            => 'TT',
                template        => 'text_html/test_utf8.tt',
                content_type    => 'text/html',
                charset      => 'utf-8',
                encoding     => 'quoted-printable',
             },
        ],
    };

    $c->forward('TestApp::View::Email::Template');    

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Template Email Failed');
    } else {
        $c->res->body('Template Email Ok');
    }
}



sub template_email_app_config : Global('template_email_app_config') {
    my ($self, $c, @args) = @_;

    $c->stash->{time} = $c->req->params->{time} || time;

    $c->stash->{template_email} = {
        to      => 'test-email@example.com',
        from    => 'no-reply@example.com',
        subject => 'Just a test',
        templates => [
            {
                template        => 'text_plain/test.tt',
                content_type    => 'text/plain',
            },
            {
                view            => 'TT',
                template        => 'text_html/test.tt',
                content_type    => 'text/html',
            },
        ],
    };

    $c->forward('TestApp::View::Email::Template::AppConfig');

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Template Email Failed');
    } else {
        $c->res->body('Template Email Ok');
    }
}

sub mason_email : Global('mason_email') {
    my ($self, $c, @args) = @_;

    $c->stash->{time} = $c->req->params->{time} || time;

    $c->stash->{email} = {
        to      => 'test-email@example.com',
        from    => 'no-reply@example.com',
        subject => 'Just a test',
        templates => [
            {
                view            => 'Mason',
		        template        => 'text_plain/test.m',
                content_type    => 'text/plain',
            },
            {
                view            => 'Mason',
                template        => 'text_html/test.m',
                content_type    => 'text/html',
            },
        ],
    };

    $c->forward('TestApp::View::Email::Template');    

    if ( scalar( @{ $c->error } ) ) {
        $c->res->status(500);
        $c->res->body('Mason Email Failed');
    } else {
        $c->res->body('Mason Email Ok');
    }
}


1;
