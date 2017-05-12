package App::JobLog::Command::note;
$App::JobLog::Command::note::VERSION = '1.042';
# ABSTRACT: take a note

use App::JobLog -command;
use Modern::Perl;
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use Class::Autouse qw(App::JobLog::Log);

sub execute {
    my ( $self, $opt, $args ) = @_;
    my $tags = $opt->tag;
    my $log  = App::JobLog::Log->new;
    unless ( $tags || $opt->clear_tags ) {
        my ($last) = $log->last_note;
        $tags = $last->tags if $last;
    }
    $log->append_note(
        $tags ? ( tags => $tags ) : (),
        description => [ join ' ', @$args ],
    );
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' <text of note>' }

sub abstract { 'take a note' }

sub full_description {
    <<END;
Take a note. E.g.,

  @{[prog_name($0)]} @{[__PACKAGE__->name]} remember to get kids from school

All arguments that are not parameter values are concatenated as the note. Notes
have a time but not a duration. See the summary command for how to extract notes
from the log.

Notes may be tagged to assist in search or categorization.
END
}

sub options {
    return (
        [
            'tag|t=s@',
'tag the note; multiple tags are acceptable; e.g., -t foo -t bar -t quux',
        ],
        [
            'clear-tags|T',
            'inherit no tags from preceding note; '
              . 'this is equivalent to -t ""; '
              . 'this option has no effect if any tag is specified',
        ],

    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    $self->usage_error('no note provided') unless @$args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::note - take a note

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job note --help
 job <command>
 
 job note <text of note>
 	-t --tag          tag the note; multiple tags are acceptable; e.g.,
 	                  -t foo -t bar -t quux
 	-T --clear-tags   inherit no tags from preceding note; this is
 	                  equivalent to -t ""; this option has no effect if
 	                  any tag is specified
 	--help            this usage screen
 houghton@NorthernSpy:~$ job note taking a note
 houghton@NorthernSpy:~$ job note -t money taking a note about money
 houghton@NorthernSpy:~$ job n taking another note that will be tagged with 'money'
 houghton@NorthernSpy:~$ job n -T taking a note without any tags

=head1 DESCRIPTION

Notes differ from tasks in several ways:

 * they aren't "on the clock"
 * they don't change the current task
 * they have a timestamp but no duration

They are like tasks in that it is nice to find them by time, tag, text, etc. and they
are well suited to a log format. C<note> is the command that lets you log notes as you
would tasks.

=head2 TAGS

You may optionally attach categories to tasks with tags. Any string can be a tag but to make the output readable you'll want them
to be short. Also, in the logs tags are delimited by whitespace and separated from the timestamp and description by colons, so
these characters will be escaped with a slash. If you edit the log by hand and forget to escape these characters the log will
still parse but you will be surprised by the summaries you get.

You may specify multiple tags, but each one needs its own B<--tag> flag.

If you don't specify otherwise the new note will inherit the tags of the previous note, so you will need to apply
the B<--clear-tags> option to prevent this. The reasoning behind this feature is that when you take notes you frequently take
several in succession and want them all tagged the same way.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
