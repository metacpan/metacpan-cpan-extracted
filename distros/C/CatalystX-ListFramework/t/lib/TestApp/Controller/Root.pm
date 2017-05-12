package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;
use CatalystX::ListFramework;

# Set the actions in this controller to be registered with no prefix
__PACKAGE__->config->{namespace} = '';

sub greeting :Path('/greeting') {
    my ( $self, $c ) = @_;
    $c->res->output('hello');
}

sub list_and_search :Path('/listsearch') {
    my ($self, $c, $kind) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    my $table_columns = 'default';
    my $restrict = {};
    $c->stash->{"myprefixoptions"}->{pager} = 1; # must do this before stash_listing
    $lf->stash_listing($table_columns, 'myprefix', $restrict);
    $c->stash->{template} = 'list-and-search.tt';
    $c->view('TT')->process($c);
   # $c->stash->{"myprefixoptions"}->{deletable} = 1; # only if sure nothing belongs_to us
}

sub list :Path('/list') { # a simplified list, to test against without invoking the search code
    my ($self, $c, $kind) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    my $table_columns = 'default';
    my $restrict = {};
    $lf->stash_listing($table_columns, 'myprefix', $restrict);
    $c->stash->{template} = 'list-simple.tt';
    $c->view('TT')->process($c);
}

sub grid :Path('/grid') {  # TODO - extjs grid view
    my ($self, $c, $kind) = @_;
}

sub detail :Path('/get') {
    my ($self, $c, $kind, $id) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    $lf->stash_infoboxes({'me.id' => [{'=' => $id}]}); 
    $c->stash->{kind} = $kind;
    $c->stash->{id} = $id;  # so that the update form knows what URL to call
    $c->stash->{template} = 'detail.tt';

    if ($kind eq 'album') {
        my $fb2 = CatalystX::ListFramework->new('track', $c);
        $fb2->stash_listing('default', 'myprefix', {'me.fromalbum' => [{'=' => $id}]});
        # $c->stash->{add_to_create} = $id;
        # In one project, we used this to make the create-new userprefs_* link /create/userprefs*/userid so that
        # the newly created thing would be associated with the user we were looking at (&create() took an extra arg).
        # So, TODO We need a proper way of telling the /create form to set 'fromalbum' to the album we're editing.
        $c->stash->{"myprefixoptions"}->{deletable} = 1;
    }

    $c->view('TT')->process($c);
}

sub update :Path('/update') {
    my ($self, $c, $kind, $id) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    $lf->update_from_query({'me.id' => [{'=' => $id}]}); 
    $c->stash->{template} = 'refreshopener.tt';
    $c->view('TT')->process($c);
}

sub create :Path('/create') {
    my ($self, $c, $kind) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    my $id = $lf->create_new; 
    $c->res->redirect($c->uri_for("/get/$kind/$id"));
}

sub delete :Path('/delete') {
    my ($self, $c, $kind, $id) = @_;
    my $lf = CatalystX::ListFramework->new($kind, $c);
    my $rv = $lf->delete_row($id);  # TODO  check rv
    $c->stash->{template} = 'refreshopener.tt';
    $c->view('TT')->process($c);
}

sub complete :Path('/complete') {
    my ($self, $c, $kind, $id_field, $show_field, $query) = @_;  
    $query = $c->req->params->{query} if (defined $c->req->params->{query});
    my $lf = CatalystX::ListFramework->new($kind, $c);
    $lf->stash_json_autocomplete($query, $id_field, $show_field, {});
    $c->view('JSON')->process($c);
}

sub resetdb :Path('/start') {
    my ($self, $c) = @_;
    my $dbfile = "/tmp/__listframework_testapp.sqlite";
    if (-e $dbfile) { unlink $dbfile or die "Failed to unlink $dbfile: $!"; }
    my $dbh = DBI->connect("dbi:SQLite2:dbname=$dbfile","","");

    open my $sql_fh, $c->config()->{'sql_path'}.'/test_app.sql' or die "Can't read SQL file: $!";
    local $/ = "";  ## empty line(s) are delimeters
    while (my $sql = <$sql_fh>) {
        $dbh->do($sql);
    }
    $dbh->disconnect;
    close $sql_fh;
    $c->res->redirect("/listsearch/track");
    #$c->res->output('reset ok');
}

    

1;
