#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Chandra::Canvas;

package MockCanvasApp;
our (%bound, @evals);
sub new { bless {}, shift }
sub bind { my ($self, $name, $code) = @_; $bound{$name} = $code; return $self }
sub eval { my ($self, $js) = @_; push @evals, $js; return 1 }

package main;

# --- every drawing method, serialised ---
{
    my $c = Chandra::Canvas->new(id => 'full', width => 200, height => 100);
    $c->fill_style('#fff')->stroke_style('#000')->line_width(2)->global_alpha(0.5)
      ->line_cap('round')->line_join('bevel')->clear
      ->fill_rect(1, 2, 3, 4)->stroke_rect(1, 2, 3, 4)->clear_rect(1, 2, 3, 4)
      ->fill_circle(5, 5, 2)->stroke_circle(5, 5, 2)
      ->begin_path->move_to(0, 0)->line_to(1, 1)->arc(1, 1, 1, 0, 1)->arc(1, 1, 1, 0, 1, 1)->rect(0, 0, 1, 1)
      ->close_path->fill->stroke->save->restore
      ->translate(1, 1)->rotate(1)->scale(2, 2)
      ->arc_to(0, 0, 1, 1, 1)->bezier_curve_to(0, 0, 1, 1, 2, 2)->quadratic_curve_to(0, 0, 1, 1)
      ->clip->clip('evenodd')->transform(1, 0, 0, 1, 0, 0)->set_transform(1, 0, 0, 1, 0, 0)->reset_transform
      ->miter_limit(4)->global_composite_operation('lighter')
      ->line(0, 0, 1, 1)->rounded_rect(0, 0, 10, 10, 2)->fill_rounded_rect(0, 0, 10, 10, 2)
      ->polygon([ [0, 0], [1, 0], [1, 1] ])->fill_polygon([ [0, 0], [1, 0], [1, 1] ]);
    my $js = $c->_serialize_buffer;
    like($js, qr/lineCap='round'/, 'the line cap is serialised');
    like($js, qr/lineJoin='bevel'/, 'and the line join');
    like($js, qr/globalAlpha=0\.5/, 'and the alpha');
    like($js, qr/strokeRect\(1,2,3,4\)/, 'and strokeRect');
    like($js, qr/clearRect\(1,2,3,4\)/, 'and clearRect');
    like($js, qr/arc\(5,5,2,0,6\.283185307\);_ctx_\w+\.fill\(\)/, 'and the filled circle');
    like($js, qr/arc\(5,5,2,0,6\.283185307\);_ctx_\w+\.stroke\(\)/, 'and the stroked circle');
    like($js, qr/clip\('evenodd'\)/, 'and the clip rule');

    # every command again with its arguments cut off, and some with odd ones
    my @cut = map { [ $_->[0] ] } @{ $c->{_buffer} };
    my @odd = map { [ $_->[0], 5, 5, 5, 5, 5, 5 ] } @{ $c->{_buffer} };
    push @{ $c->{_buffer} }, @cut, @odd, [], ['not an op'], 'not a command', [ $c->{_buffer}[0][0], '1' x 100 ];
    ok(length $c->_serialize_buffer, 'commands with missing, numeric or overlong arguments still serialise');
    $c->_clear_buffer;
    is(scalar @{ $c->{_buffer} }, 0, 'the buffer is cleared');
}

# --- polygons that are not polygons ---
{
    my $c = Chandra::Canvas->new(id => 'poly');
    for my $m (qw(polygon fill_polygon)) {
        eval { $c->$m('not a list') };
        like($@, qr/$m requires arrayref of \[x,y\] pairs/, "$m wants a list");
        eval { $c->$m([ [0, 0] ]) };
        like($@, qr/$m requires at least 2 points/, "$m wants two points");
        eval { $c->$m([ [0, 0], 'not a pair' ]) };
        like($@, qr/$m point 1 must be \[x,y\] arrayref/, "$m wants pairs");
    }
}

# --- clicks, flush and render ---
{
    %MockCanvasApp::bound = ();
    @MockCanvasApp::evals = ();
    my $app = MockCanvasApp->new;
    my $c = Chandra::Canvas->new(id => 'clicky');
    unlike($c->render, qr/addEventListener/, 'no click script before a handler');
    is($c->on_click($app, sub { 'left' }), $c, 'on_click returns the canvas');
    is($c->on_rclick($app, sub { 'right' }), $c, 'on_rclick returns the canvas');
    my $id = $c->id;
    is_deeply([ sort keys %MockCanvasApp::bound ], [ "__canvas_click_$id", "__canvas_rclick_$id" ], 'both are bound under the canvas id');
    like($c->render, qr/addEventListener\('click'/, 'and the click script is rendered');
    $c->fill_rect(0, 0, 1, 1);
    is_deeply([ $c->flush($app) ], [$c], 'flush returns the canvas');
    like($MockCanvasApp::evals[0], qr/fillRect\(0,0,1,1\)/, 'and evaluates the drawing');
    is(scalar @{ $c->{_buffer} }, 0, 'and empties the buffer');
    my $anon = Chandra::Canvas->new;
    $anon->{id} = 5;
    $anon->on_click($app, sub { });
    ok(exists $MockCanvasApp::bound{__canvas_click__canvas_1}, 'a canvas whose id is not a string binds under the default name');
}

# --- broken objects ---
{
    my $c = Chandra::Canvas->new(id => 'broken');
    $c->{_buffer} = 'not a buffer';
    eval { $c->fill };
    like($@, qr/Canvas command buffer not initialized/, 'a lost buffer croaks');
    my $noid = Chandra::Canvas->new;
    delete $noid->{id};
    eval { $noid->_serialize_buffer };
    like($@, qr/Canvas id not set/, 'serialising without an id croaks');
}

done_testing;
