package App::financeta::gui::progress_bar;
use strict;
use warnings;
use 5.10.0;

use App::financeta::mo;
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use Prima qw(Application  sys::GUIException Utils );
use POSIX qw(floor);

$|=1;

has owner => undef;
has bar => ( builder => '_build_bar' );
has title => 'Loading...';
has bar_width => 100;
has bar_height => 40;

sub _build_bar {
    my $self = shift;
    $log->debug("Creating progress bar");
    my $bar = Prima::Window->create(
        name => 'progress_bar',
        text => $self->title,
        size => [$self->bar_width, $self->bar_height],
        origin => [0, 0],
        widgetClass => wc::Dialog,
        borderStyle => bs::Dialog,
        borderIcons => 0,
        hint => $self->title,
        showHint => 1,
        centered => 1,
        owner => $self->owner,
        visible => 1,
        pointerType => cr::Wait,
        onPaint => sub {
            my ($w, $canvas) = @_;
            $canvas->color(cl::Blue);
            $canvas->bar(0, 0, $w->{-progress}, $w->height);
            $canvas->color(cl::Back);
            $canvas->bar($w->{-progress}, 0, $w->size);
            my $pct = floor(100 * $w->{-progress} / $w->width);
            if ($pct > 0) {
                $canvas->color(cl::Yellow);
                $canvas->font(size => 10, style => fs::Bold);
                $canvas->text_out(sprintf("%d%%", $pct), 0, 10) if $pct > 0;
            }
        },
        syncPaint => 1,
        onTop => 1,
    );
    $bar->{-progress} = 0;
    $bar->repaint;
    if (defined $bar->owner) {
        $bar->owner->pointerType(cr::Wait);
        $bar->owner->repaint;
    }
    return $bar;
}

sub update {
    my ($self, $val) = @_;
    ## is percentage
    if (defined $val and ($val > 0 and $val < 1)) {
        $self->bar->{-progress} = ($val * $self->bar_width);
    } elsif (defined $val) {#is absolute
        $self->bar->{-progress} = $val;
    } else {
        $self->bar->{-progress} += 5;
    }
    $self->bar->repaint;
    if (defined $self->bar->owner) {
        $self->bar->owner->repaint;
    }
    return $self->bar->{-progress};
}

sub close {
    my $self = shift;
    if (defined $self and defined $self->bar) {
        if (defined $self->bar->owner) {
            $self->bar->owner->pointerType(cr::Default);
            $self->bar->owner->repaint;
        }
        $self->bar->close;
    }
}

sub progress {
    return shift->bar->{-progress};
}

1;
__END__
### COPYRIGHT: 2013-2023. Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 30th Aug 2014
### LICENSE: Refer LICENSE file
