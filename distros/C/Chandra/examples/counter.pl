#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use Chandra::Component;

# ── Define a Counter component ─────────────────────────────

package Counter;
use Object::Proto;

BEGIN {
    Object::Proto::define('Counter',
        extends => 'Chandra::Component',
        'count:Int:default(0)',
        'label:Str:default(Count)',
        'step:Int:default(1)',
    );
    Object::Proto::import_accessors('Counter');
}

sub render {
    my ($self) = @_;
    my $count = $self->count;
    my $label = $self->label;
    return qq{<div>
        <div style="text-align:center; padding: 40px">
            <h1>$label</h1>
            <p style="font-size:72px; margin:20px 0; color:var(--chandra-primary);">$count</p>
            <div style="display:flex; gap:8px; justify-content:center;">
                <button class="chandra-btn-danger" data-action="decrement"
                    style="font-size:24px; padding:10px 30px;">
                    -
                </button>
                <button class="chandra-btn-secondary" data-action="reset"
                    style="font-size:24px; padding:10px 30px;">
                    Reset
                </button>
                <button class="chandra-btn-primary" data-action="increment"
                    style="font-size:24px; padding:10px 30px;">
                    +
                </button>
            </div>
        </div>
    </div>};
}

sub _check_milestone {
    my ($self) = @_;
    my $count = $self->count;
    my $app = $self->_app;
    return unless $app;

    if ($count > 0 && $count % 5 == 0) {
        $app->toast("Milestone: $count clicks!", type => 'success');
    } elsif ($count < 0 && $count % 5 == 0) {
        $app->toast("Gone negative: $count", type => 'warning');
    }
}

sub on_increment {
    my ($self) = @_;
    $self->count($self->count + $self->step);
    $self->update;
    $self->_check_milestone;
}

sub on_decrement {
    my ($self) = @_;
    $self->count($self->count - $self->step);
    $self->update;
    $self->_check_milestone;
}

sub on_reset {
    my ($self) = @_;
    my $prev = $self->count;
    $self->count(0);
    $self->update;
    if ($prev != 0) {
        my $app = $self->_app;
        $app->toast("Reset from $prev", type => 'info', action => {
            label   => 'Undo',
            handler => sub {
                $self->count($prev);
                $self->update;
            },
        }) if $app;
    }
}

# ── Run the app ────────────────────────────────────────────

package main;
use Chandra::App;
use Chandra::Component;

my $app = Chandra::App->new(
    title  => 'Counter Component',
    width  => 400,
    height => 350,
   debug => 1,
);

$app->theme('dark');

my $counter = Counter->new(label => 'Clicks', step => 1);

$app->set_content('<div id="root"></div>');
$counter->mount($app, '#root');

$app->on_reload(sub {
    Chandra::Component->reset;
    $counter->mount($app, '#root');
});

$app->run;
