package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use CatalystX::Menu::Suckerfish;
use Data::Dumper;

__PACKAGE__->config(namespace => q{});

my $frozen_tree = <<'EOF';
{
    'About us' => {
        'children' => {},
        'menutitle' => 'About us',
        'uri' => bless( do{\(my $o = 'http://localhost/about/us')}, 'URI::http' )
    },
    'Main' => {
        'children' => {
            'Public' => {
                'children' => {},
                'menutitle' => 'A public function',
                'uri' => bless( do{\(my $o = 'http://localhost/public')}, 'URI::http' )
            }
        }
    }
};
EOF

sub begin :Private {
    my ($self, $c) = @_;

    my $menu = CatalystX::Menu::Suckerfish->new(
        context => $c,
        ul_id => 'navlist',
        ul_class => 'navmenu',
        menupath_attr => 'MenuPath',
        menutitle_attr => 'MenuTitle',
        top_order => [qw(Main * Help)],
        text_container => { element => 'span', attrs => { class => 'menulabel' } },
    );

    $c->stash->{menu} = $menu->output;

    # generate a menu for use with Filament Group iPod menu jQuery plugin
    $menu = CatalystX::Menu::Suckerfish->new(
        context => $c,
        menupath_attr => 'MenuPath',
        top_order => [qw(Main * Help)],
        ul_container => { element => 'div', attrs => { id => 'divid', class => 'hidden' } },
        text_container => { element => 'a', attrs => { href => '#' } },
    );

    $c->stash->{menu_in_div} = $menu->output;
}

sub index :Path :Args(0) {
    my ($self, $c) = @_;
}

sub menu :Local {
    my ($self, $c) = @_;
    $c->res->body($c->stash->{menu});
}

sub menu_in_div :Local {
    my ($self, $c) = @_;
    $c->res->body($c->stash->{menu_in_div});
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
