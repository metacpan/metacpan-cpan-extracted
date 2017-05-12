package TestApp::Controller::MultiForm;

use strict;
use warnings;
use base 'Catalyst::Controller::HTML::FormFu';

sub multiform : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'multiform.tt';
}

sub formconfig : Chained('multiform') : Args(0) : MultiFormConfig { }

sub formconfig_FORM_COMPLETE {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};

    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = join "\n",
            map { sprintf "%s: %s", $_, $params->{$_} } keys %$params;

        $c->stash->{message} = 'Complete';
    }
}

sub formmethod : Chained('multiform') : Args(0) : MultiFormMethod('_load_form') { }

sub formmethod_FORM_COMPLETE {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};

    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = join "\n",
            map { sprintf "%s: %s", $_, $params->{$_} } keys %$params;

        $c->stash->{message} = 'Complete';
    }
}

sub _load_form : Private {
    return {
        id                       => 'formmethod',
        params_ignore_underscore => 1,

        crypt_args => { '-key' => 'my secret', },

        forms => [
            { element => { name => 'page1' }, },
            { element => { name => 'page2' }, }
        ],
    };
}

sub file_upload : Chained('multiform') : Args(0) : MultiFormConfig { }

sub file_upload_FORM_COMPLETE {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};

    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = '';

        for ( keys %$params ) {
            my $upload = $params->{$_};

            my $size     = $upload->size;
            my $filename = $upload->filename;
            my $type     = $upload->type;

            $c->stash->{results} .= <<END;
param: $_, size: $size, filename: $filename, type: $type
END
        }

        $c->stash->{message} = 'Complete';
    }
}

1;
