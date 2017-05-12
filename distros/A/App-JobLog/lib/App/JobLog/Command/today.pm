package App::JobLog::Command::today;
$App::JobLog::Command::today::VERSION = '1.042';
# ABSTRACT: show what has happened today

use App::JobLog -command;
use Modern::Perl;
use App::JobLog::Command::summary;
use autouse 'App::JobLog::Time' => qw(now);

use constant FORMAT => '%l:%M:%S %p on %A, %B %d, %Y';

sub execute {
    my ( $self, $opt, $args ) = @_;
    $self->simple_command_check($args);

    # display everything done today
    App::JobLog::Command::summary->execute( $opt, ['today'] );
}

sub usage_desc { '%c ' . __PACKAGE__->name . ' %o' }

sub abstract { 'what has happened today' }

sub full_description {
    <<END;
List what has happened today.

This is basically a specialized variant of the @{[App::JobLog::Command::summary->name]} command.
END
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Command::today - show what has happened today

=head1 VERSION

version 1.042

=head1 SYNOPSIS

 houghton@NorthernSpy:~$ job today --help
 job <command>
 
 job today [-f] [long options...]
 	-f --finished     show when you can stop working given hours already
 	                  work; optional argument indicates span to calculate
 	                  hours over or start time; e.g., --finished
 	                  yesterday or --finished payperiod
 	--help            this usage screen
 houghton@NorthernSpy:~$ job to
 Monday,  7 March, 2011
   8:01 am - ongoing  1.33  bar, foo  something to add; and still more                                                                                                  
 
   TOTAL HOURS 1.33
   bar         1.33
   foo         1.33

=head1 DESCRIPTION

B<App::JobLog::Command::today> reviews the current day's events. In this it is completely equivalent to 
L<App::JobLog::Command::summary> given an option like C<today>, C<now>, or whatever might be the current date.

=head1 SEE ALSO

L<App::JobLog::Command::summary>, L<App::JobLog::Command::last>, L<App::JobLog::Command::tags>, L<App::JobLog::Command::configure>,
L<App::JobLog::Command::vacation>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
