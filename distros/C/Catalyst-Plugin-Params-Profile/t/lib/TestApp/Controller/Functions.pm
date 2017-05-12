package TestApp::Controller::Functions;

use strict;
use base qw/Catalyst::Controller/;
use Data::Dumper;

sub noregister : Local {
    my ($self,$c) = @_;

    $c->res->body('noregister')
            if !$c->get_profile('method' => 'noregister');
}

TestApp->register_profile(
        method  => 'register',
        profile => {
                required => [ 'test' ],
            }
    );
sub register : Local {
    my ($self,$c) = @_;

    $c->res->body('register')
            if $c->get_profile(method => 'register');
}

TestApp->register_profile(
        method  => 'novalidate',
        profile => {
                required => [ 'test' ],
            }
    );
sub novalidate : Local {
    my ($self,$c, %args) = @_;

    $c->res->body('novalidate')
            if !$c->validate('params' => \%args);
}

sub describe : Local {
    my ($self,$c, %args) = @_;
    $c->res->body('describe')
            if $c->_describe_pp_plaintext(
                    profile => 'TestApp::Controller::Functions::validate'
                ) =~ /test/;
}

TestApp->register_profile(
        method  => 'validate',
        profile => {
                required => [ 'test' ],
            }
    );
sub validate : Local {
    my ($self,$c) = @_;

    my %args = %{ $c->req->params };
    $c->res->body('validate')
            if $c->validate('params' => \%args);
}

TestApp->register_profile(
        method  => 'checkparams',
        profile => {
                required => [ qw/een twee/ ],
                optional => [ qw/drie/ ],
                constraint_methods => {
                        een     => qr/^\w+$/,
                        twee    => qr/^\d+$/,
                        drie    => qr/^\d$/,
                    },
            }
    );

sub checkparams : Local {
    my ($self, $c) = @_;

    my $opts = $c->check_params or
        (
            $c->res->body('invalid_params'),
            return
        );

    $c->res->body('validated_params : ' . Dumper($opts));
    return;

}

TestApp->register_profile(
        method  => 'checkparamsunkn',
        profile => 'checkparams',
    );

sub checkparamsunkn : Local {
    my ($self, $c) = @_;

    my $opts = $c->check_params('allow_unknown' => 1) or
        (
            $c->res->body('invalid_params'),
            return
        );

    $c->res->body('validated_params : ' . Dumper(\$opts));
    return;

}

TestApp->register_profile(
        method  => 'checkparamspc',
        profile => {
                een     => {
                        required    => 1,
                        allow       => qr/^\w+$/,
                    },
                twee    => {
                        required    => 1,
                        allow       => qr/^\d+$/,
                    },
                drie    => {
                        allow       => qr/^\d$/,
                    },
            }
    );

sub checkparamspc : Local {
    my ($self, $c) = @_;

    my $opts = $c->check_params or
        (
            $c->res->body('invalid_params'),
            return
        );

    $c->res->body('validated_params : ' . Dumper($opts));
    return;

}

TestApp->register_profile(
        method  => 'checkparamsunknpc',
        profile => 'checkparamspc',
    );

sub checkparamsunknpc : Local {
    my ($self, $c) = @_;

    my $opts = $c->check_params('allow_unknown' => 1) or
        (
            $c->res->body('invalid_params'),
            return
        );

    $c->res->body('validated_params : ' . Dumper(\$opts));
    return;

}

1;
