package TestApp::Controller::Root;

use Moose;
BEGIN { extends 'Catalyst::Controller' }
use CatalystX::Menu::mcDropdown;
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

    my $menu = CatalystX::Menu::mcDropdown->new(
        context => $c,
        ul_id => 'navlist',
        ul_class => 'mcdropdown_menu',
        menupath_attr => 'MenuPath',
        menutitle_attr => 'MenuTitle',
        top_order => [qw(Main * Help)],
        filter => sub {
            my ($c, %action) = @_;
            return
            map { $_, $action{$_} }
            grep { $action{$_}->name =~ /^(?:public|aboutus)$/ }
            keys %action;
        },
    );

    $c->stash->{menu} = $menu->output;
}

sub big_menu :Local {
    my ($self, $c) = @_;

    my $menu = CatalystX::Menu::mcDropdown->new(
        context => $c,
        ul_id => 'navlist',
        ul_class => 'mcdropdown_menu',
        menupath_attr => 'MenuPath',
        menutitle_attr => 'MenuTitle',
        #top_order => [qw(Main * Help)],
    );

    $c->res->body($menu->output);
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

sub accounts
:Local
:MenuPath(/Customer/Accounts)
:MenuTitle('Customer accounts')
{
    my ($self, $c) = @_;

    $c->res->body('customer accounts');
}

sub orders
:Local
:MenuPath(/Customer/Orders)
:MenuTitle('Customer orders')
{
    my ($self, $c) = @_;

    $c->res->body('customer orders');
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
