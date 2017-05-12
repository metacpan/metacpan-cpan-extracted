package App::JobLog::Command::add;
$App::JobLog::Command::add::VERSION = '1.042';
# ABSTRACT: log an event

use App::JobLog -command;
use Modern::Perl;
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use autouse 'App::JobLog::Time'         => qw(now);
use Class::Autouse qw(App::JobLog::Log);

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $tags = $opt->tag;
    unless ($tags) {
        $tags = [] if $opt->clear_tags;
    }
    my $log        = App::JobLog::Log->new;
    my ($last)     = $log->last_event;
    my $is_ongoing = $last && $last->is_open;
    $log->append_event(
        $tags ? ( tags => $tags ) : (),
        description => [ join ' ', @$args ],
        time        => now
    );
    if ( $is_ongoing && _different_day( $last->start, now ) ) {
        say 'Event spans midnight. Perhaps you failed to close the last event.';
    }
}

sub _different_day {
    my ( $d1, $d2 ) = @_;
    return !( $d1->year == $d2->year
        && $d1->month == $d2->month
        && $d1->day == $d2->day );
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' <description of event>' }

sub abstract { 'log an event' }

sub full_description {
    <<END;
Log an event. E.g.,

  @{[prog_name($0)]} @{[__PACKAGE__->name]} munging the widget

All arguments that are not parameter values are concatenated as a description
of the event. Logging an event simultaneously marks the end of the previous
event. Events may be tagged to mark such things as client, grant, or 
project.
END
}

sub options {
    return (
        [
            'tag|t=s@',
'tag the event; multiple tags are acceptable; e.g., -t foo -t bar -t quux',
        ],
        [
            'clear-tags|T',
            'inherit no tags from preceding event; '
              . 'this is equivalent to -t ""; '
              . 'this option has no effect if any tag is specified',
        ],

    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error('no description provided') unless @$args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::add - log an event

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job add --help
 job <command>
 
 job add <description of event>
 	-t --tag          tag the event; multiple tags are acceptable; e.g.,
 	                  -t foo -t bar -t quux
 	-T --clear-tags   inherit no tags from preceding event; this is
 	                  equivalent to -t ""; this option has no effect if
 	                  any tag is specified
 	--help            this usage screen
 houghton@NorthernSpy:~$ job add -T -t foo -t bar -t quux Staring into the Abyss.
 houghton@NorthernSpy:~$ job a Getting stared back at.

=head1 DESCRIPTION

B<App::JobLog::Command::add> is the command you'll use most often. It appends an event to the log.

=head2 TAGS

You may optionally attach categories to tasks with tags. Any string can be a tag but to make the output readable you'll want them
to be short. Also, in the logs tags are delimited by whitespace and separated from the timestamp and description by colons, so
these characters will be escaped with a slash. If you edit the log by hand and forget to escape these characters the log will
still parse but you will be surprised by the summaries you get.

You may specify multiple tags, but each one needs its own B<--tag> flag.

If you don't specify otherwise the new event will inherit the tags of the previous event, so you will need to apply
the B<--clear-tags> option to prevent this. The reasoning behind this feature is that you change tags seldom but change tasks
often so inheriting tags by default saves labor.

=head1 SEE ALSO

L<App::JobLog::Command::done>, L<App::JobLog::Command::resume>, L<App::JobLog::Command::modify>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
