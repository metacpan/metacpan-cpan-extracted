package Chandra::Nav;

use strict;
use warnings;
use Object::Proto;
use Chandra;
use Chandra::Component;
use Chandra::Element;

our $VERSION = '0.25';

BEGIN {
    Object::Proto::define('Chandra::Nav',
        extends => 'Chandra::Component',
        'items:ArrayRef:required',
        'type:Str:default(sidebar)',       # sidebar | topbar
        'collapsible:Bool:default(0)',
        'collapsed:Bool:default(0)',
        '_active:Str',
    );
    Object::Proto::import_accessors('Chandra::Nav', 'nav_');
}

sub render {
    my ($self) = @_;
    my $type  = nav_type $self;
    my $items = nav_items $self;
    my $collapsed = nav_collapsed $self;
    my $active = nav__active $self;

    my $class = "chandra-nav chandra-nav-$type";
    $class .= ' chandra-nav-collapsed' if $collapsed;

    my $wrap = Chandra::Element->new({ tag => 'div', class => 'chandra-nav-wrap' });

    if (nav_collapsible($self) && $type eq 'sidebar') {
        $wrap->add_child(Chandra::Element->new({
            tag => 'button', class => 'chandra-nav-toggle',
            data => "\x{2630}",
            'data-action' => 'toggle',
        }));
    }

    my $nav = Chandra::Element->new({ tag => 'nav', class => $class });
    my $ul = Chandra::Element->new({ tag => 'ul', class => 'chandra-nav-list' });

    for my $item (@$items) {
        if ($item->{separator}) {
            $ul->add_child(Chandra::Element->new({
                tag => 'li', class => 'chandra-nav-separator',
            }));
            next;
        }

        my $is_active = defined $active && defined $item->{route}
                        && $active eq $item->{route};
        my $li_class = 'chandra-nav-item';
        $li_class .= ' chandra-nav-active' if $is_active;

        my $li = Chandra::Element->new({ tag => 'li', class => $li_class });

        my $route = $item->{route} // '';
        $route =~ s/'/\\'/g;
        my $a = Chandra::Element->new({
            tag => 'a',
            class => 'chandra-nav-link',
            'data-action' => "navigate:$route",
        });

        if ($item->{icon}) {
            $a->add_child(Chandra::Element->new({
                tag => 'span', class => 'chandra-nav-icon',
                data => $item->{icon},
            }));
        }

        $a->add_child(Chandra::Element->new({
            tag => 'span', class => 'chandra-nav-label',
            data => $item->{label} // '',
        }));

        if ($item->{badge}) {
            $a->add_child(Chandra::Element->new({
                tag => 'span', class => 'chandra-nav-badge',
                data => $item->{badge},
            }));
        }

        $li->add_child($a);
        $ul->add_child($li);
    }

    $nav->add_child($ul);
    $wrap->add_child($nav);
    return $wrap->render;
}

sub on_navigate {
    my ($self, $route) = @_;
    nav__active $self, $route;
    my $app = $self->_app;
    if ($app && $app->can('navigate')) {
        $app->navigate($route);
    }
    $self->update;
}

sub on_toggle {
    my ($self) = @_;
    nav_collapsed $self, !nav_collapsed($self);
    $self->update;
}

sub css {
    return <<'CSS';
.chandra-nav-wrap { position: relative; display: flex; flex-direction: column; flex-shrink: 0; height: 100%; }
.chandra-nav { font-family: inherit; }
.chandra-nav-list { list-style: none; margin: 0; padding: 0; }

/* Sidebar */
.chandra-nav-sidebar {
    width: 220px;
    min-width: 220px;
    background: var(--chandra-surface, #f5f5f5);
    border-right: 1px solid var(--chandra-border, #e0e0e0);
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    padding: 8px 0;
    transition: width 0.2s, min-width 0.2s;
}
.chandra-nav-sidebar.chandra-nav-collapsed {
    width: 52px;
    min-width: 52px;
    padding: 8px 0;
}
.chandra-nav-sidebar.chandra-nav-collapsed .chandra-nav-label,
.chandra-nav-sidebar.chandra-nav-collapsed .chandra-nav-badge { display: none; }
.chandra-nav-sidebar.chandra-nav-collapsed .chandra-nav-link {
    justify-content: center;
    padding: 10px 0;
}
.chandra-nav-sidebar .chandra-nav-link {
    display: flex; align-items: center; gap: 10px;
    padding: 10px 16px; color: var(--chandra-text, #212121);
    text-decoration: none; cursor: pointer;
    transition: background 0.15s;
}
.chandra-nav-sidebar .chandra-nav-link:hover { background: var(--chandra-hover, #e8e8e8); }
.chandra-nav-sidebar .chandra-nav-active .chandra-nav-link {
    background: var(--chandra-selected, #e3f2fd);
    color: var(--chandra-primary, #2196F3);
    font-weight: 600;
}
.chandra-nav-separator { border-top: 1px solid var(--chandra-border, #e0e0e0); margin: 4px 12px; }
.chandra-nav-toggle {
    width: 52px; border: none;
    background: transparent;
    font-size: 1.1em; cursor: pointer;
    color: var(--chandra-text-muted, #757575);
    flex-shrink: 0;
    text-align: center;
}
.chandra-nav-icon { font-size: 1.1em; flex-shrink: 0; width: 24px; text-align: center; }
.chandra-nav-badge {
    margin-left: auto; background: var(--chandra-primary, #2196F3);
    color: #fff; padding: 1px 8px; border-radius: 10px; font-size: 0.75em;
}

/* Topbar */
.chandra-nav-topbar {
    background: var(--chandra-surface, #f5f5f5);
    border-bottom: 1px solid var(--chandra-border, #e0e0e0);
    padding: 0 8px;
}
.chandra-nav-topbar .chandra-nav-list { display: flex; gap: 0; }
.chandra-nav-topbar .chandra-nav-link {
    display: flex; align-items: center; gap: 6px;
    padding: 12px 16px; color: var(--chandra-text, #212121);
    text-decoration: none; cursor: pointer;
    border-bottom: 2px solid transparent;
    transition: border-color 0.15s, color 0.15s;
}
.chandra-nav-topbar .chandra-nav-link:hover { color: var(--chandra-primary, #2196F3); }
.chandra-nav-topbar .chandra-nav-active .chandra-nav-link {
    color: var(--chandra-primary, #2196F3);
    border-bottom-color: var(--chandra-primary, #2196F3);
    font-weight: 600;
}
.chandra-nav-topbar .chandra-nav-separator { display: none; }
CSS
}

1;

__END__

=head1 NAME

Chandra::Nav - Navigation component (sidebar/topbar)

=head1 SYNOPSIS

    use Chandra::Nav;

    my $nav = Chandra::Nav->new(
        type  => 'sidebar',
        items => [
            { label => 'Dashboard', icon => "\x{1F4CA}", route => '/' },
            { label => 'Users',     icon => "\x{1F465}", route => '/users' },
            { separator => 1 },
            { label => 'Settings',  icon => "\x{2699}",  route => '/settings' },
        ],
        collapsible => 1,
    );

    $app->theme('dark');
    $app->css(Chandra::Nav->css);
    $app->set_content('<div style="display:flex;height:100vh;"><div id="nav"></div><div id="content" style="flex:1;padding:20px;"></div></div>');
    $nav->mount($app, '#nav');

=head1 SEE ALSO

L<Chandra::Tabs>, L<Chandra::Component>, L<Chandra::App>

=cut
