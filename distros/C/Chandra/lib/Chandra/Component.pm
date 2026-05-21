package Chandra::Component;

use strict;
use warnings;
use Object::Proto;
use Cpanel::JSON::XS ();

our $VERSION = '0.25';

use Chandra;

my $_comp_id_counter = 0;
my %_comp_registry;   # component_id => component object

BEGIN {
    Object::Proto::define('Chandra::Component',
        '_cid:Str',
        '_app:Any',
        '_selector:Str',
        '_mounted:Bool:default(0)',
        '_children:ArrayRef:default([])',
        '_parent:Any:weak',
    );
    Object::Proto::import_accessors('Chandra::Component', 'comp_');
}

sub BUILD {
    my ($self) = @_;
    my $cid = '_comp_' . ++$_comp_id_counter;
    comp__cid $self, $cid;
    $_comp_registry{$cid} = $self;
}

# ── Abstract: override in subclass ─────────────────────────

sub render {
    my ($self) = @_;
    my $children_html = $self->render_children;
    my $cid = $self->_ensure_cid;
    return qq{<div id="$cid">$children_html</div>};
}

# ── Lifecycle ──────────────────────────────────────────────

sub mount {
    my ($self, $app, $selector) = @_;
    comp__app $self, $app;
    comp__selector $self, $selector;

    # Bind the action dispatcher for this component
    my $cid = $self->_ensure_cid;
    $app->bind("_comp_action_$cid", sub {
        my ($action, @args) = @_;
        my $method = "on_$action";
        if ($self->can($method)) {
            return $self->$method(@args);
        }
        warn "Chandra::Component: no handler '$method' on " . ref($self) . "\n";
        return undef;
    });

    # Render and inject
    my $html = $self->_wrap_render;
    $app->update($selector, $html);

    comp__mounted $self, 1;
    $self->on_mount if $self->can('on_mount');

    # Mount children
    for my $child (@{comp__children $self}) {
        my $child_cid = $child->_cid;
        $child->mount($app, "#$child_cid");
    }

    return $self;
}

sub unmount {
    my ($self) = @_;
    my $app = comp__app $self;

    # Unmount children first
    for my $child (@{comp__children $self}) {
        $child->unmount;
    }

    $self->on_unmount if $self->can('on_unmount');

    # Remove from DOM
    my $cid = $self->_ensure_cid;
    if ($app) {
        $app->eval("var _e=document.getElementById('$cid');if(_e)_e.remove();");
    }

    comp__mounted $self, 0;
    comp__app $self, undef;
    delete $_comp_registry{$cid};

    return $self;
}

sub update {
    my ($self) = @_;
    my $app = comp__app $self;
    return $self unless $app && comp__mounted $self;

    my $cid = $self->_ensure_cid;
    my $inner = $self->_render_inner;
    $app->update("#$cid", $inner);

    $self->on_update if $self->can('on_update');

    return $self;
}

# Update only a sub-section of the component by a stable CSS selector.
# The selector is relative to the component's root element.
# The $html should already have actions rewritten.
sub update_part {
    my ($self, $sub_id, $html) = @_;
    my $app = comp__app $self;
    return $self unless $app && comp__mounted $self;

    $html = $self->_rewrite_actions($html);
    $app->update("#$sub_id", $html);

    return $self;
}

# ── Child composition ──────────────────────────────────────

sub child {
    my ($self, $component) = @_;
    comp__parent $component, $self;
    my $children = comp__children $self;
    push @$children, $component;
    comp__children $self, $children;
    return $self;
}

sub render_children {
    my ($self) = @_;
    my $html = '';
    for my $child (@{comp__children $self}) {
        $html .= $child->_wrap_render;
    }
    return $html;
}

# ── Internal ───────────────────────────────────────────────

my %_INPUT_TAGS = map { $_ => 1 } qw(input select textarea);

sub _ensure_cid {
    my ($self) = @_;
    my $cid = comp__cid $self;
    unless ($cid) {
        $cid = '_comp_' . ++$_comp_id_counter;
        comp__cid $self, $cid;
        $_comp_registry{$cid} = $self;
    }
    return $cid;
}

sub _action_to_js {
    my ($self, $tag, $action) = @_;
    my $cid = $self->_ensure_cid;
    my ($method, @params) = split /:/, $action;
    my $args = Cpanel::JSON::XS::encode_json([$method, @params]);
    $args =~ s/"/&quot;/g;

    my $invoke = "window.chandra.invoke(&quot;_comp_action_$cid&quot;";

    if ($_INPUT_TAGS{$tag}) {
        if ($tag eq 'select') {
            # Selects fire immediately on change
            return ('onchange',
                "var _a=${args};_a.push(this.value);${invoke},_a)");
        }
        # Text inputs: debounce to avoid re-render on every keystroke
        # which would destroy the focused input
        return ('oninput',
            "clearTimeout(this._cdt);var _el=this;this._cdt=setTimeout(function(){"
            . "var _a=${args};_a.push(_el.value);${invoke},_a)"
            . "},300)");
    }
    return ('onclick', "${invoke},${args})");
}

sub _rewrite_actions {
    my ($self, $html) = @_;
    # Process each opening tag that contains data-action
    $html =~ s{<(\w+)(\s[^>]*?)data-action="([^"]+)"([^>]*)>}{
        my ($tag, $before, $action, $after) = (lc($1), $2, $3, $4);
        my ($event, $js) = $self->_action_to_js($tag, $action);
        "<${tag}${before}${event}=\"${js}\"${after}>"
    }ge;
    return $html;
}

sub _render_inner {
    my ($self) = @_;
    return $self->_rewrite_actions($self->render);
}

sub _wrap_render {
    my ($self) = @_;
    my $cid = $self->_ensure_cid;
    my $inner = $self->_render_inner;

    # Stamp the component ID on the root element
    if ($inner =~ m{id="[^"]*"}) {
        $inner =~ s{id="[^"]*"}{id="$cid"};
    } elsif ($inner =~ m{^(\s*<\w+)}) {
        $inner =~ s{^(\s*<\w+)}{$1 id="$cid"};
    }
    return $inner;
}

# ── Class methods ──────────────────────────────────────────

sub find_component {
    my ($class, $cid) = @_;
    return $_comp_registry{$cid};
}

sub reset {
    my ($class) = @_;
    %_comp_registry = ();
    $_comp_id_counter = 0;
}

1;

__END__

=head1 NAME

Chandra::Component - Reactive UI components for Chandra

=head1 SYNOPSIS

    package MyCounter;
    use Object::Proto;

    BEGIN {
        object 'MyCounter',
            extends => 'Chandra::Component',
            'count:Int:default(0)',
            'label:Str:default(Counter)',
        ;
        Object::Proto::import_accessors('MyCounter');
    }

    sub render {
        my ($self) = @_;
        my $count = $self->count;
        my $label = $self->label;
        return qq{
            <div class="counter">
                <h2>$label: $count</h2>
                <button data-action="increment">+</button>
                <button data-action="decrement">-</button>
            </div>
        };
    }

    sub on_increment { $_[0]->count($_[0]->count + 1); $_[0]->update }
    sub on_decrement { $_[0]->count($_[0]->count - 1); $_[0]->update }

    # Usage:
    my $counter = MyCounter->new(label => 'Clicks');
    $counter->mount($app, '#main');

=head1 DESCRIPTION

C<Chandra::Component> is an Object::Proto-based reactive component system.
Components encapsulate state, rendering, and event handling.

=head2 Lifecycle

=over 4

=item C<mount($app, $selector)> - render + inject into DOM, bind events

=item C<unmount()> - remove from DOM, unbind events

=item C<update()> - re-render the component's DOM subtree

=back

=head2 Lifecycle Hooks (override in subclass)

=over 4

=item C<on_mount()> - called after first render

=item C<on_unmount()> - called before removal

=item C<on_update()> - called after re-render

=back

=head2 Event Binding

Use C<data-action="method_name"> in your HTML. Clicking the element
calls C<on_method_name()> on the component. Parameters can be passed
with C<data-action="method:arg1:arg2">.

=head2 Children

    $parent->child($child_component);

Children are rendered inside the parent and automatically
mounted/unmounted with it.

=head1 SEE ALSO

L<Chandra::App>, L<Chandra::Element>

=cut
