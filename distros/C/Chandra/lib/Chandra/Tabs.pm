package Chandra::Tabs;

use strict;
use warnings;
use Object::Proto;
use Chandra;
use Chandra::Component;
use Chandra::Element;

our $VERSION = '0.28';

BEGIN {
    Object::Proto::define('Chandra::Tabs',
        extends => 'Chandra::Component',
        'tabs:ArrayRef:required',          # [{ label, content => sub{}, badge }]
        'on_change:CodeRef',
        '_active_index:Int:default(0)',
    );
    Object::Proto::import_accessors('Chandra::Tabs', 'tabs_');
}

sub render {
    my ($self) = @_;
    my $tabs   = tabs_tabs $self;
    my $active = tabs__active_index $self;
    my $cid    = $self->_cid;

    my $wrap = Chandra::Element->new({ tag => 'div', class => 'chandra-tabs' });

    # Tab headers
    my $header = Chandra::Element->new({ tag => 'div', class => 'chandra-tabs-header' });
    for my $i (0 .. $#$tabs) {
        my $tab = $tabs->[$i];
        my $cls = 'chandra-tab';
        $cls .= ' chandra-tab-active' if $i == $active;

        my $btn = Chandra::Element->new({
            tag => 'button', class => $cls,
            'data-action' => "select_tab:$i",
        });

        $btn->add_child(Chandra::Element->new({
            tag => 'span', data => $tab->{label} // "Tab $i",
        }));

        if ($tab->{badge}) {
            $btn->add_child(Chandra::Element->new({
                tag => 'span', class => 'chandra-tab-badge',
                data => $tab->{badge},
            }));
        }

        $header->add_child($btn);
    }
    $wrap->add_child($header);

    # Active tab content
    my $body = Chandra::Element->new({
        tag => 'div', class => 'chandra-tabs-body',
        id => "${cid}_tab_body",
    });

    if ($active >= 0 && $active <= $#$tabs) {
        my $content = $tabs->[$active]{content};
        if (ref $content eq 'CODE') {
            my $html = $content->();
            $body->add_child(Chandra::Element->new({ tag => 'div', raw => $html }));
        } elsif (defined $content) {
            $body->add_child(Chandra::Element->new({ tag => 'div', raw => $content }));
        }
    }
    $wrap->add_child($body);

    return $wrap->render;
}

sub on_select_tab {
    my ($self, $index) = @_;
    $index = int($index);
    my $tabs = tabs_tabs $self;
    return if $index < 0 || $index > $#$tabs;

    tabs__active_index $self, $index;

    my $cb = tabs_on_change $self;
    $cb->($index, $tabs->[$index]{label}) if $cb;

    $self->update;
}

sub active_index {
    my ($self) = @_;
    return tabs__active_index $self;
}

sub css {
    return <<'CSS';
.chandra-tabs { font-family: inherit; }
.chandra-tabs-header {
    display: flex;
    border-bottom: 1px solid var(--chandra-border, #e0e0e0);
    gap: 0;
}
.chandra-tab {
    padding: 10px 20px;
    border: none;
    background: transparent;
    color: var(--chandra-text-muted, #757575);
    cursor: pointer;
    font-size: inherit;
    font-family: inherit;
    border-bottom: 2px solid transparent;
    transition: color 0.15s, border-color 0.15s;
    display: flex;
    align-items: center;
    gap: 6px;
}
.chandra-tab:hover { color: var(--chandra-text, #212121); }
.chandra-tab-active {
    color: var(--chandra-primary, #2196F3);
    border-bottom-color: var(--chandra-primary, #2196F3);
    font-weight: 600;
}
.chandra-tab-badge {
    background: var(--chandra-primary, #2196F3);
    color: #fff;
    padding: 1px 8px;
    border-radius: 10px;
    font-size: 0.75em;
    font-weight: normal;
}
.chandra-tabs-body { padding: 16px 0; }
CSS
}

1;

__END__

=head1 NAME

Chandra::Tabs - Tab component

=head1 SYNOPSIS

    use Chandra::Tabs;

    my $tabs = Chandra::Tabs->new(
        tabs => [
            { label => 'General',  content => sub { '<p>General settings</p>' } },
            { label => 'Advanced', content => sub { '<p>Advanced options</p>' } },
            { label => 'Plugins',  content => sub { '<p>Plugin list</p>' }, badge => 3 },
        ],
        on_change => sub { my ($index, $label) = @_; print "Tab: $label\n" },
    );

    $app->css(Chandra::Tabs->css);
    $tabs->mount($app, '#content');

=head1 SEE ALSO

L<Chandra::Nav>, L<Chandra::Component>

=cut
