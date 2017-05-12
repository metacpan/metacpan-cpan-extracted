package App::JobLog::Command::edit;
$App::JobLog::Command::edit::VERSION = '1.042';
# ABSTRACT: edit the log

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse qw{
  App::JobLog::Log
  App::JobLog::Log::Line
  Digest::MD5
  FileHandle
};
use autouse 'File::Temp'                => qw(tempfile);
use autouse 'File::Copy'                => qw(copy);
use autouse 'App::JobLog::Config'       => qw(editor log);
use autouse 'Getopt::Long::Descriptive' => qw(prog_name);
use autouse 'App::JobLog::TimeGrammar'  => qw(parse);
use autouse 'App::JobLog::Time'         => qw(now);

sub execute {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->close || $opt->validate ) {
        eval {
            my $log = App::JobLog::Log->new;
            if ( $opt->close ) {
                my $time = join ' ', @$args;
                my ($s) = parse($time);
                $self->usage_error(
                    'you may only insert closing times prior to present')
                  unless $s < now;
                my ( $e, $i ) = $log->find_previous($s);
                $self->usage_error('log does not contain appropriate event')
                  unless $e;
                $self->usage_error('no open event at this time')
                  unless $e->is_open;
                $log->insert( $i + 1,
                    App::JobLog::Log::Line->new( time => $s, done => 1 ) );
            }
            if ( $opt->validate ) {
                my $errors = $log->validate;
                _error_report($errors);
            }
        };
        $self->usage_error($@) if $@;
    }
    elsif ( my $editor = editor ) {
        if ( my $log = log ) {
            my ( $fh, $fn ) = tempfile;
            binmode $fh;
            copy( $log, $fh );
            $fh->close;
            $fh = FileHandle->new($log);
            my $md5  = Digest::MD5->new;
            my $md51 = $md5->addfile($fh)->hexdigest;
            system "$editor $log";
            $fh = FileHandle->new($log);
            my $md52 = $md5->reset->addfile($fh)->hexdigest;

            if ( $md51 ne $md52 ) {
                $fh = FileHandle->new( "$log.bak", 'w' );
                copy( $fn, $fh );
                $fh->close;
                say "saved backup log in $log.bak";
                my $errors = App::JobLog::Log->new->validate;
                _error_report($errors);
            }
            else {
                unlink $fn;
            }
        }
        else {
            say 'nothing in log to edit';
        }
    }
    else {
        $self->usage_error('no editor specified') unless $opt->close;
    }
}

sub usage_desc {
    '%c ' . __PACKAGE__->name . ' [--validate] [-c <date and time>]';
}

sub abstract { 'open a text editor to edit the log' }

sub full_description {
    <<END;
Close an open task or open a text editor to edit the log.

Closing an open task is the only edit you'll commonly have to make (it's
easy to forget to close the last task of the day). Fortunately, it is the easiest
edit to perform. You simply type

  @{[prog_name]} @{[__PACKAGE__->name]} --close yesterday at 8:00 pm

for example and @{[prog_name]} will insert the appropriate line if it can do so.
If it can't because there is no open task at the time specified, it will emit a warning
instead.

The date and time parsing is handled by the same code used by the @{[App::JobLog::Command::summary->name]} command,
so what works for one works for the other. One generally does not specify hours and such
for summaries, but @{[prog_name]} will understand most common natural language time expressions.

If you need to do more extensive editing of the log this command will open a text editor
for you and confirm the validity of the log after you save, commenting out
ill-formed lines and printing a warning. This command requires the you
to have set editor configuration parameter to specify a text. 
The text editor must be invokable like so,

  <editor> <file to edit>
  
That is, you must be able to specify the file to edit as an argument. If the editor
requires any additional arguments or options you must provide those via the
environment variable.
END
}

sub options {
    return (
        [
            'close|close-task|c' =>
              'add a "DONE" line to the log at the specified moment'
        ],
        [ 'validate|v' => 'check log for errors, commenting out any found' ],
    );
}

sub _error_report {
    my $errors = shift;

    if ($errors) {
        say "errors found: $errors";
        say 'Error messages have been inserted into the log. Please edit.';
    }
    else {
        say 'log is valid';
    }
}

sub validate {
    my ( $self, $opt, $args ) = @_;

    if ( $opt->close ) {
        $self->usage_error('no time expression provided') unless @$args;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::edit - edit the log

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job edit --help
 job <command>
 
 job edit [--validate] [-c <date and time>]
 	-c --close-task --close  add a "DONE" line to the log at the specified
 	                        moment
 	-v --validate           check log for errors, commenting out any found
 	--help                  this usage screen
 houghton@NorthernSpy:~$ job today
 Monday,  7 March, 2011
   8:01 am - ongoing  4.56  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 4.56
   bar         4.56
   foo         4.56
 houghton@NorthernSpy:~$ job e --close today at 8:05
 houghton@NorthernSpy:~$ job t
 Monday,  7 March, 2011
   8:01 - 8:05 am  0.05  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 0.05
   bar         0.05
   foo         0.05
 houghton@NorthernSpy:~$ job e

A text editor opens up displaying the log. Appropriate edits are performed. The user saves and quits.

 saved backup log in /home/houghton/.joblog/log.bak
 log is valid
 houghton@NorthernSpy:~$ 

=head1 DESCRIPTION

Generally you won't have need to modify the log except through L<App::JobLog::Command::add>, L<App::JobLog::Command::done>,
L<App::JobLog::Command::modify>, or L<App::JobLog::Command::resume>. There will sometimes be glitches, though: you will
be away from the log when you do something or you will quit for the day without having punched out with L<App::JobLog::Command::done>.
This is when you need B<App::JobLog::Command::edit>.

Most of the time you will simply need to add a missing I<DONE> line -- the B<--close> option. For this you need no text editor external to
L<App::JobLog> itself. If you need a full function editor you will need to define the I<editor> parameter using L<App::JobLog::Command::configure>.
Then invoke this command without any options or arguments.

When you invoke the editor, L<App::JobLog> reviews the log after you save, commenting out ill-formed lines and emitting warnings.

=head1 SEE ALSO

L<App::JobLog::Command::modify>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
