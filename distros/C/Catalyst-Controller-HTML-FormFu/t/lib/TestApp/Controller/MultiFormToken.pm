package TestApp::Controller::MultiFormToken;

use strict;
use warnings;
use base 'Catalyst::Controller::HTML::FormFu';

__PACKAGE__->config(
    { 'Controller::HTML::FormFu' => { request_token_enable => 1 } } );

sub multiformtoken : Chained : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'multiform.tt';
}

sub formconfig : Chained('multiformtoken') : Args(0) :
    MultiFormConfig('multiform/formconfig') {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};
    $multi->action('/multiformtoken/formconfig');
    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = join "\n",
            map { sprintf "%s: %s", $_, $params->{$_} } keys %$params;

        $c->stash->{message} = 'Complete';
    }
}

sub file_upload : Chained('multiformtoken') : Args(0) : MultiFormConfig {
    my ( $self, $c ) = @_;

    my $multi = $c->stash->{multiform};

    if ( $multi->complete ) {
        my $params = $multi->current_form->params;

        $c->stash->{results} = '';

        for ( keys %$params ) {
            my $upload = $params->{$_};

            my $size     = $upload->size;
            my $length   = length $upload->slurp;
            my $filename = $upload->filename;
            my $type     = $upload->type;

            $c->stash->{results} .= <<END;
param: $_, size: $size, length: $length, filename: $filename, type: $type
END
        }

        $c->stash->{message} = 'Complete';
    }
}

1;
