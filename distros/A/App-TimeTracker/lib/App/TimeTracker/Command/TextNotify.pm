package App::TimeTracker::Command::TextNotify;
use strict;
use warnings;
use 5.010;

# ABSTRACT: App::TimeTracker post mac desktop integration plugin

use Moose::Role;
use App::TimeTracker::Utils qw(pretty_date);

after [ 'cmd_start', 'cmd_stop', 'cmd_current', 'cmd_continue' ] => sub {
    my $self = shift;
    $self->_update_text_notify();
};

sub _update_text_notify {
    my $self = shift;

    my $notify_file = $self->home->file('current.txt');

    if ( my $task = App::TimeTracker::Data::Task->current( $self->home ) ) {
        my $fh   = $notify_file->openw();
        my $text = $task->project . ' since ' . pretty_date( $task->start );

        if (   $task->can('rt_id')
            && $task->rt_id )
        {
            $text .= "\nRT" . $task->rt_id;
            $text .= ": " . $task->description if $task->description;
        }
        elsif ( my $desc = $task->description ) {
            $text .= $desc;
        }
        print $fh $text;
        say $text;
        $fh->close;
    }
    else {
        $notify_file->remove()
            if -e $notify_file;
    }
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TimeTracker::Command::TextNotify - App::TimeTracker post mac desktop integration plugin

=head1 VERSION

version 2.028

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2018 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
