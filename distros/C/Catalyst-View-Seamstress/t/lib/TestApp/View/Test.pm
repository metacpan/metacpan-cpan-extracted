package TestApp::View::Test;

use base qw[ Catalyst::View::Seamstress ];

__PACKAGE__->config(
    comp_root => '.',
    fixup => sub{},
    skeleton => 'TestApp::Layouts::skel',
    meat_pack => sub{
        my ($self, $c, $stash, $meat, $skeleton) = @_;

        my $body_elem = $skeleton->look_down('_tag' => 'body');
        my $meat_body = $skeleton->look_down(seamstress => 'replace');

        unless ($meat_body) {
            warn "could not find meat_body";
            die $meat->as_HTML;
        }

        $meat_body->replace_content($meat->content_list);
    }
);
;1;
