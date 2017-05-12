package App::JobLog::Command::done;
$App::JobLog::Command::done::VERSION = '1.042';
# ABSTRACT: close last open event

use App::JobLog -command;
use Modern::Perl;
use Class::Autouse 'App::JobLog::Log';

sub execute {
    my ( $self, $opt, $args ) = @_;
    $self->simple_command_check($args);

    my $log = App::JobLog::Log->new;
    my ($last) = $log->last_event;
    if ( $last && $last->is_open ) {
        $log->append_event( done => 1 );
    }
    else {
        say 'No currently open event in log.';
    }
}

sub usage_desc { '%c ' . __PACKAGE__->name }

sub abstract { 'mark current task as done' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::done - close last open event

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job done
 houghton@NorthernSpy:~$ 

=head1 DESCRIPTION

When you invoke L<App::JobLog::Command::add> to append a new event to the log this moment
also marks the end of any previous event. If an event is ongoing and you simply wish to mark its
end -- if you're signing off for the day, for example -- use B<App::JobLog::Command::done>.

=head1 SEE ALSO

L<App::JobLog::Command::add>, L<App::JobLog::Command::resume>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
