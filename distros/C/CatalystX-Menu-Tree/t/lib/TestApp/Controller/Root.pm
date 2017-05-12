package TestApp::Controller::Root;

use base Catalyst::Controller;
use CatalystX::Menu::Tree;

__PACKAGE__->config(namespace => q{});

sub begin :Private {
    my ($self, $c) = @_;

    # this is called in the CatalystX::Menu::Tree subclass
    # e.g.
    # my $menu = CatalystX::Menu::Suckerfish->new(...);
    # $c->session->{menu} = $menu->output;  # stash nested HTML UL element for use in TT View

    require Data::Dumper;

    my $menutree = CatalystX::Menu::Tree->new(
        context => $c,
        menupath_attr => 'MenuPath',
        menutitle_attr => 'MenuTitle',
        add_nodes => [
            {
                menupath => 'Foo/Bar',
                menutitle => 'A foo bar',
                uri => '/foobar',
            },
        ],
    );
    my $tree = $menutree->{tree};
    $c->stash->{tree1} = Data::Dumper->Dump([$tree],['$tree']);


    $menutree = CatalystX::Menu::Tree->new(
        context => $c,
        menupath_attr => 'MenuPath',
        add_nodes => [
            {
                menupath => 'Foo/Bar',
                uri => '/foobar',
            },
        ],
    );
    $tree = $menutree->{tree};
    $c->stash->{tree2} = Data::Dumper->Dump([$tree],['$tree']);
}

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    $c->res->body($c->stash->{menu});
}

sub tree1 :Local {
    my ($self, $c) = @_;

    $c->res->body($c->stash->{tree1});
}

sub tree2 :Local {
    my ($self, $c) = @_;

    $c->res->body($c->stash->{tree2});
}

sub public
:Local
:MenuPath(/Main/Public)
:MenuTitle('A public function')
{
    my ($self, $c) = @_;

    $c->res->body('public action');
}

sub aboutus
:Path(/about/us)
:MenuPath(/About us)
:MenuTitle('About us')
{
    my ($self, $c) = @_;
    $c->res->body('about us action');
}

1;
