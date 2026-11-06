package Chandra::Breadcrumb;

use strict;
use warnings;
use Object::Proto;
use Chandra;
use Chandra::Component;
use Chandra::Element;

our $VERSION = '0.31';

BEGIN {
    Object::Proto::define('Chandra::Breadcrumb',
        extends => 'Chandra::Component',
        'items:ArrayRef:required',         # [{ label, route }]
        'separator:Str',
    );
    Object::Proto::import_accessors('Chandra::Breadcrumb', 'bc_');
}

sub BUILD {
    my ($self) = @_;
    $self->Chandra::Component::BUILD;
    bc_separator $self, "\x{203A}" unless defined bc_separator $self;
}

sub render {
    my ($self) = @_;
    my $items = bc_items $self;
    my $sep   = bc_separator $self;

    my $nav = Chandra::Element->new({ tag => 'nav', class => 'chandra-breadcrumb' });
    my $ol = Chandra::Element->new({ tag => 'ol', class => 'chandra-breadcrumb-list' });

    for my $i (0 .. $#$items) {
        my $item = $items->[$i];
        my $li = Chandra::Element->new({ tag => 'li', class => 'chandra-breadcrumb-item' });

        if ($i < $#$items && $item->{route}) {
            my $route = $item->{route};
            $route =~ s/'/\\'/g;
            $li->add_child(Chandra::Element->new({
                tag => 'a', class => 'chandra-breadcrumb-link',
                data => $item->{label} // '',
                'data-action' => "navigate:$route",
            }));
        } else {
            $li->add_child(Chandra::Element->new({
                tag => 'span', class => 'chandra-breadcrumb-current',
                data => $item->{label} // '',
            }));
        }

        if ($i < $#$items) {
            $li->add_child(Chandra::Element->new({
                tag => 'span', class => 'chandra-breadcrumb-sep',
                data => $sep,
            }));
        }

        $ol->add_child($li);
    }

    $nav->add_child($ol);
    return $nav->render;
}

sub on_navigate {
    my ($self, $route) = @_;
    my $app = $self->_app;
    $app->navigate($route) if $app && $app->can('navigate');
}

sub css {
    return <<'CSS';
.chandra-breadcrumb-list {
    list-style: none; margin: 0; padding: 0;
    display: flex; align-items: center; gap: 0;
    font-size: 0.9em;
}
.chandra-breadcrumb-item { display: flex; align-items: center; }
.chandra-breadcrumb-link {
    color: var(--chandra-primary, #2196F3);
    text-decoration: none; cursor: pointer;
}
.chandra-breadcrumb-link:hover { text-decoration: underline; }
.chandra-breadcrumb-current { color: var(--chandra-text-muted, #757575); }
.chandra-breadcrumb-sep {
    margin: 0 8px;
    color: var(--chandra-text-muted, #999);
}
CSS
}

1;

__END__

=head1 NAME

Chandra::Breadcrumb - Breadcrumb navigation component

=head1 SYNOPSIS

    use Chandra::Breadcrumb;

    my $crumbs = Chandra::Breadcrumb->new(
        items => [
            { label => 'Home',  route => '/' },
            { label => 'Users', route => '/users' },
            { label => 'Alice' },
        ],
    );

    $app->css(Chandra::Breadcrumb->css);
    $crumbs->mount($app, '#breadcrumb');

=head1 METHODS

=over 4

=item C<new(items => \@items, separator => $text)>

Each item is a hash with a C<label> and, for all but the last, a C<route>.
The separator defaults to a single right-pointing angle quotation mark.

=item C<BUILD>

Sets the default separator after the component's own C<BUILD>.

=item C<render>

The trail, with links for the items that have a route.

=item C<on_navigate($route)>

Navigates the app when it can.

=item C<css>

The breadcrumb's stylesheet.

=item C<prototype>, C<set_prototype>

Object::Proto's prototype accessors.

=back

=head1 SLOT ACCESSORS

=over 4

=item C<items>, C<separator> - the slots as methods

=item C<bc_items>, C<bc_separator>, C<bc__cid>, C<bc__app>, C<bc__selector>, C<bc__mounted>, C<bc__children>, C<bc__parent> - the slot functions

=back

=head1 SEE ALSO

L<Chandra::Nav>, L<Chandra::Tabs>, L<Chandra::Component>

=cut
