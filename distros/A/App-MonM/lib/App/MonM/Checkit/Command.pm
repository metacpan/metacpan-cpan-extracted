package App::MonM::Checkit::Command; # $Id: Command.pm 133 2022-09-09 07:49:00Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit::Command - Checkit Command subclass

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    <Checkit "foo">

        Enable  yes
        Type    command
        Command     ls -la
        Target      content
        IsTrue      !!perl/regexp (?i-xsm:README)

        # . . .

    </Checkit>

Or with STDIN pipe:

    <Checkit "foo">

        Enable   yes
        Type     command
        Command  perl
        Content  "print q/Oops/"
        Target   content
        IsTrue   Oops
        Timeout  5s

        # . . .

    </Checkit>

=head1 DESCRIPTION

Checkit Command subclass

=head2 check

Checkit method.
This is backend method of L<App::MonM::Checkit/check>

Returns:

=over 4

=item B<code>

The exit status code (ERRORLEVEL, EXITCODE)

=item B<content>

The STDOUT response content

=item B<error>

The STDERR response content

=item B<message>

OK or ERROR value, see "status"

=item B<source>

Command string

=item B<status>

0 if error occured (code != 0); 1 if no errors found (code == 0)

=back

=head1 CONFIGURATION DIRECTIVES

The basic Checkit configuration options (directives) detailed describes in L<App::MonM::Checkit/CONFIGURATION DIRECTIVES>

=over 4

=item B<Command>

    Command  "perl -w"

Defines full path to external program (command line)

Default: none

=item B<Content>

    Content     "print q/Blah-Blah-Blah/"

Sets the content for command STDIN

Default: no content

=item B<Timeout>

    Timeout    1m

Defines the execute timeout

Default: off

=back

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK::Util qw/ execute /;
use CTK::ConfGenUtil;
use App::MonM::Util qw/getTimeOffset run_cmd/;

sub check {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type && $type eq 'command';

    # Init
    my $to = CTK::Timeout->new(); # Create the timeout object
    my $command = lvalue($self->config, 'command') || '';
    my $content = lvalue($self->config, 'content') // '';
       $content = undef unless length $content;
    my $timeout = getTimeOffset(lvalue($self->config, 'timeout') || 0);
    unless (length($command)) {
        $self->status(0);
        $self->source("NOOP");
        $self->message('Command not specified');
        return;
    }
    $self->source($command);

    # Run command
    my $r = run_cmd($command, $timeout, $content);
    $self->status($r->{status});
    $self->message($r->{message});
    $self->code($r->{code});
    $self->content($r->{stdout});
    $self->error($r->{stderr});

    return;
}

1;

__END__
