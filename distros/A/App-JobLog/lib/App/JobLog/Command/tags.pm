package App::JobLog::Command::tags;
$App::JobLog::Command::tags::VERSION = '1.042';
# ABSTRACT: show what tags you have used

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw(App::JobLog::Log);
use autouse 'App::JobLog::TimeGrammar'  => qw(parse);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $events = [];
    eval {
        if (@$args)
        {
            my ( $start, $end ) = parse( join( ' ', @$args ) );
            $events = App::JobLog::Log->new->find_events( $start, $end )
              unless $opt->notes;
            push @$events,
              @{ App::JobLog::Log->new->find_notes( $start, $end ) }
              unless !( $opt->notes || $opt->all );
        }
        else {
            my $method = 'all_events';
            if ( $opt->notes ) {
                $method = 'all_notes';
            }
            elsif ( $opt->all ) {
                $method = 'all_taglines';
            }
            $events = App::JobLog::Log->new->$method;
        }
    };
    $self->usage_error($@) if $@;
    my %tags;
    for my $e (@$events) {
        $tags{$_} = 1 for @{ $e->tags };
    }
    if (%tags) {
        print "\n";
        say $_ for sort keys %tags;
        print "\n";
    }
    else {
        say 'no tags in log';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o [date or date range]' }

sub abstract {
    'list tags employed in log or some subrange thereof';
}

sub full_description {
    <<END
List the tags used to categorize tasks or notes in the log or in a specified range of dates. This allows one to
explore the categorical structure of tasks and notes. By default only tags associated with notes are listed.

The date expressions understood are the same as those understood by the C<summary> command.
END
}

sub options {
    return (
        [
                "Use '@{[prog_name]} help "
              . __PACKAGE__->name
              . '\' to see full details.'
        ],
        [ 'notes|n', 'only list tags used on notes' ],
        [ 'all|a',   'list tags for both notes and tasks' ],
    );
}

sub validate {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error('--notes conflicts will --all')
      if $opt->notes && $opt->all;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::tags - show what tags you have used

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job tags --help
 job <command>
 
 job tags [-an] [long options...] [date or date range]
 	Use 'job help tags' to see full details.
 	-n --notes   only list tags used on notes
 	-a --all     list tags for both notes and tasks
 	--help       this usage screen
 houghton@NorthernSpy:~$ job tags this week

 foo
 
 houghton@NorthernSpy:~$ job tags

 bar
 foo
 quux

=head1 DESCRIPTION

B<App::JobLog::Command::tags> lists the tags applied to tasks anywhere in the log or in a specified
time range. This allows one to examine how tasks have been categorized (and perhaps how they have
been mis-typed).

The time expressions understood are the same as are understood by L<App::JobLog::Command::summary>.

By default note tags are not listed. Use the --notes or --all options if you wish to include these.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::today>, L<App::JobLog::Command::last>, L<App::JobLog::Command::parse>, L<App::JobLog::TimeGrammar>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
