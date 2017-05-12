package TestApp::View::DataSection;
use Moose; extends 'Catalyst::View::MicroTemplate::DataSection';
sub _build_section { 'TestApp' }

package TestApp;

use strict;
use warnings;

use Catalyst qw/-Debug/;

__PACKAGE__->config(
    name         => 'TestApp',
    default_view => 'DataSection',
);

__PACKAGE__->setup;


sub test :Local {
    my ($self, $c) = @_;
    $c->res->body("test");
}

sub datasection :Local {
    my ($self, $c) = @_;
    $c->stash->{username} = 'masakyst';
}

sub end : ActionClass('RenderView') {}

1;

__DATA__

@@ datasection.mt
hello <?= $_[0]->{username} ?>
