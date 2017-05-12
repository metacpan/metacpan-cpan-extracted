use strict;
use warnings;

use Test::More tests => 29;

use Algorithm::Easing::Mediator;
use Algorithm::Easing::Linear;
use Algorithm::Easing::Bounce;
use Algorithm::Easing::Circular;
use Algorithm::Easing::Cubic;
use Algorithm::Easing::Exponential;
use Algorithm::Easing::Quadratic;
use Algorithm::Easing::Quartinion;
use Algorithm::Easing::Quintonion;
use Algorithm::Easing::Sinusoidal;
use Algorithm::Easing::Backdraft;

use Time::HiRes qw(usleep);

use feature 'say';

select (STDOUT);
$|++;

sub test_ease_in {
    my ($name, $ease, $max) = @_;
    # total time for eased translation as a real positive integer value
    my $d = 1.0;
    
    # begin
    my $b = 0;
    
    # change
    my $c = 80;
    
    # time passed in seconds as a real positive integer between each frame
    my $frame_time = 0.0025;

    my ($mediator,$x,$old_x) = (Algorithm::Easing::Mediator->new(kind => $ease),0,-1);
    
    print "\nTesting ${name} ease in.";
    print "\n";
    
    for (my $t = 0; $t <= $d + $frame_time; $t += $frame_time) {
        $x = $mediator->ease_in($t,$b,$c,$d);
        $x += 80 - $max;
        if ($x != $old_x && $x < 80 && $x > 0) {
            my ($line, $pad) = ('', '');
            $line = '#' x sprintf('%i', $x);
            $pad = ' ' x sprintf('%i', 80 - $x) if $x <= 80;
            print "\b" x 80;
            print sprintf("%s%s", $line, $pad);
            usleep(sprintf("%i",$frame_time * 1000));
        }
        $old_x = $x;
    }
    
    print "\n";
    
    ok(sprintf("%i",$x) >= 80,"The ${name} ease in test has completed with successful result.");
    
    1;
}

sub test_ease_both {
    my ($name, $ease, $max) = @_;
    
    # total time for eased translation as a real positive integer value
    my $d = 1.0;
    
    # begin
    my $b = 0;
    
    # change
    my $c = 80;
    
    # time passed in seconds as a real positive integer between each frame
    my $frame_time = 0.0025;

    my ($mediator,$x,$old_x) = (Algorithm::Easing::Mediator->new(kind => $ease),0,-1);
    
    print "\nTesting ${name} ease in and out.";
    print "\n";
    
    for (my $t = 0; $t <= $d + $frame_time; $t += $frame_time) {
        $x = $mediator->ease_both($t,$b,$c,$d);
        $x += 80 - $max;
        if ($x != $old_x && $x < 80 && $x > 0) {
            my ($line, $pad) = ('', '');
            $line = '#' x sprintf('%i', $x);
            $pad = ' ' x sprintf('%i', 80 - $x) if $x <= 80;
            print "\b" x 80;
            print sprintf("%s%s", $line, $pad);
            usleep(sprintf("%i",$frame_time * 1000));
        }
        $old_x = $x;
    }
    
    print "\n";
    
    ok(sprintf("%i",$x) >= 80,"The ${name} ease in and out test was completed with successful results.");
    
    1;
}


sub test_ease_out {
    my ($name, $ease, $max) = @_;
    # total time for eased translation as a real positive integer value
    my $d = 1.0;
    
    # begin
    my $b = 0;
    
    # change
    my $c = 80;
    
    # time passed in seconds as a real positive integer between each frame
    my $frame_time = 0.0025;

    my ($mediator,$x,$old_x) = (Algorithm::Easing::Mediator->new(kind => $ease),0,-1);
    
    print "\nTesting ${name} ease out.";
    print "\n";
    
    for (my $t = 0; $t <= $d + $frame_time; $t += $frame_time) {
        $x = $mediator->ease_out($t,$b,$c,$d);
        $x += 80 - $max;
        if ($x != $old_x && $x < 80 && $x > 0) {
            my ($line, $pad) = ('', '');
            $line = '#' x sprintf('%i', $x);
            $pad = ' ' x sprintf('%i', 80 - $x) if $x <= 80;
            print "\b" x 80;
            print sprintf("%s%s", $line, $pad);
            usleep(sprintf("%i",$frame_time * 1000));
        }
        $old_x = $x;
    }
    
    print "\n";
    
    ok(sprintf("%i",$x) >= 80,"The ${name} ease out test was completed with succesful result.");
    
    1;
}

test_ease_in('linear', Algorithm::Easing::Linear->new,80);
test_ease_in('bounce', Algorithm::Easing::Bounce->new,80);

# TODO : test_ease_in('circular', Algorithm::Easing::Circular->new,79);

test_ease_in('cubic', Algorithm::Easing::Cubic->new,80);
test_ease_in('exponential', Algorithm::Easing::Exponential->new,79);
test_ease_in('quadratic', Algorithm::Easing::Quadratic->new,79);
test_ease_in('quartinion', Algorithm::Easing::Quartinion->new,79);
test_ease_in('quintonion', Algorithm::Easing::Quintonion->new,80);
test_ease_in('sinusoidal', Algorithm::Easing::Sinusoidal->new,79);
test_ease_in('backdraft', Algorithm::Easing::Backdraft->new, 79);

test_ease_out('linear', Algorithm::Easing::Linear->new,80);
test_ease_out('bounce', Algorithm::Easing::Bounce->new,80);
test_ease_out('circular', Algorithm::Easing::Circular->new,79);
test_ease_out('cubic', Algorithm::Easing::Cubic->new,80);
test_ease_out('exponential', Algorithm::Easing::Exponential->new,79);
test_ease_out('quadratic', Algorithm::Easing::Quadratic->new,79);
test_ease_out('quartinion', Algorithm::Easing::Quartinion->new,79);
test_ease_out('quintonion', Algorithm::Easing::Quintonion->new,80);
test_ease_out('sinusoidal', Algorithm::Easing::Sinusoidal->new,79);
test_ease_out('backdraft', Algorithm::Easing::Backdraft->new,79);

test_ease_both('linear', Algorithm::Easing::Linear->new,80);
test_ease_both('bounce', Algorithm::Easing::Bounce->new,80);
test_ease_both('circular', Algorithm::Easing::Circular->new,79);
test_ease_both('cubic', Algorithm::Easing::Cubic->new,80);
test_ease_both('exponential', Algorithm::Easing::Exponential->new,79);
test_ease_both('quadratic', Algorithm::Easing::Quadratic->new,79);
test_ease_both('quartinion', Algorithm::Easing::Quartinion->new,79);
test_ease_both('quintonion', Algorithm::Easing::Quintonion->new,80);
test_ease_both('sinusoidal', Algorithm::Easing::Sinusoidal->new,79);
test_ease_both('backdraft', Algorithm::Easing::Backdraft->new,79);