package Catalyst::Plugin::AutoCRUD::Controller::AJAX;
{
  $Catalyst::Plugin::AutoCRUD::Controller::AJAX::VERSION = '2.143070';
}

use strict;
use warnings;

use base 'Catalyst::Controller';

# we're going to check that calls to this RPC operation are allowed
sub acl : Private {
    my ($self, $c) = @_;
    my $site = $c->stash->{cpac}->{g}->{site};
    my $db = $c->stash->{cpac}->{g}->{db};
    my $table = $c->stash->{cpac}->{g}->{table};

    my $acl_for = {
        create   => 'create_allowed',
        update   => 'update_allowed',
        'delete' => 'delete_allowed',
        dumpmeta      => 'dumpmeta_allowed',
        dumpmeta_html => 'dumpmeta_allowed',
    };
    my $action = [split m{/}, $c->action]->[-1];
    my $acl = $acl_for->{ $action } or return;

    if ($c->stash->{cpac}->{c}->{$db}->{t}->{$table}->{$acl} ne 'yes') {
        my $msg = "Access forbidden by configuration to [$site]->[$db]->[$table]->[$action]";
        $c->log->debug($msg) if $c->debug;

        $c->response->content_type('text/plain; charset=utf-8');
        $c->response->body($msg);
        $c->response->status('403');
        $c->detach();
    }
}

sub base : Chained('/autocrud/root/call') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward('acl');

    my $page   = $c->req->params->{'page'}  || 1;
    my $limit  = $c->req->params->{'limit'} || 10;
    my $sortby = $c->req->params->{'sort'}  || $c->stash->{cpac}->{g}->{default_sort};
    (my $dir   = $c->req->params->{'dir'}   || 'ASC') =~ s/\s//g;

    @{$c->stash}{qw/ cpac_page cpac_limit cpac_sortby cpac_dir /}
        = ($page, $limit, $sortby, $dir);

    $c->stash->{current_view} = 'AutoCRUD::JSON';
}

sub end : ActionClass('RenderView') {}

sub create : Chained('base') Args(0) {
    my ($self, $c) = @_; 
    $c->forward($c->stash->{cpac}->{g}->{backend}, 'create');
}

sub list : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac}->{g}->{backend}, 'list');
}

sub update : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac}->{g}->{backend}, 'update');
}

sub delete : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac}->{g}->{backend}, 'delete');
}

sub list_stringified : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac}->{g}->{backend}, 'list_stringified');
}

# send our generated config back in JSON for debugging
sub dumpmeta : Chained('base') Args(0) {
    my ($self, $c) = @_;

    # strip the SQLT objects
    my $meta = scalar $c->stash->{cpac}->{m}->extra;
    foreach my $t (values %{$c->stash->{cpac}->{m}->t}) {
        $meta->{t}->{$t->name} = scalar $t->extra;
        foreach my $f (values %{$t->f}) {
            $meta->{t}->{$t->name}->{f}->{$f->name} = scalar $f->extra;
        }
    }

    # delete the version as it changes
    delete $c->stash->{cpac}->{g}->{version};

    $c->stash->{json_data} = { cpac => {
        meta => $meta,
        conf => $c->stash->{cpac}->{c},
        global => $c->stash->{cpac}->{g},
    } };

    return $self;
}

# send our generated config back to the user in HTML
sub dumpmeta_html : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $msg = $c->stash->{cpac}->{g}->{version} . ' Metadata Debug Output';

    $c->debug(1);
    $c->error([ $msg ]);
    $c->stash->{dumpmeta} = 1;
    $c->response->body($msg);

    return $self;
}

1;

__END__
