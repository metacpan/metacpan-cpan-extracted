package Arepa::Web::Keys;

use strict;
use warnings;

use base 'Arepa::Web::Base';

use English qw(-no_match_vars);
use Encode;

sub index {
    my ($self) = @_;

    my $gpg_homedir = $self->config->get_key('web_ui:gpg_homedir');
    my $gpg_list_keys_cmd = "gpg --homedir '$gpg_homedir' " .
                                "--no-default-keyring --list-keys 2>&1";
    my $gpg_list_keys_output = `$gpg_list_keys_cmd`;
    $self->show_view({ cmd    => $gpg_list_keys_cmd,
                       output => $gpg_list_keys_output });
}

sub import {
    my ($self) = @_;

    $self->_only_if_admin(sub {
        my $gpg_homedir = $self->config->get_key('web_ui:gpg_homedir');
        my $gpg_import_cmd = "gpg --homedir '$gpg_homedir' " .
                                "--no-default-keyring --import";
        my $r = open F, "| $gpg_import_cmd";
        if ($r) {
            print F $self->param("gpgkeys");
            close F;

            $self->redirect_to('generic', controller => 'keys',
                                          action => 'index');
        }
        else {
            $self->show_view({ error => $! });
        }
    });
}

1;
