package App::MonM::Notifier::Channel::Command; # $Id: Command.pm 60 2019-07-14 09:57:26Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::Command - monotifier command channel

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    <Channel MyCommand>
        Type    Command

        # Real To and From
        To      testuser
        From    root

        # Options
        #Encoding base64

        <Headers>
            X-Foo foo
            X-Bar bar
        </Headers>

        Command "grep MIME > t.msg"

    </Channel>

=head1 DESCRIPTION

This module provides command method that send the content
of the message to an external program

=head2 DIRECTIVES

=over 4

=item B<Command>

Defines full path to external program

Default: none

=item B<From>

Sender address or name

=item B<To>

Recipient address or name

=item B<Type>

Defines type of channel. MUST BE set to "Command" value

=back

About other options (base) see L<App::MonM::Notifier::Channel/DIRECTIVES>

=head2 METHODS

=over 4

=item B<process>

For internal use only!

=back

=head1 EXAMPLE

Script example:

    #!/usr/bin/perl -w
    use strict;
    use utf8;

    my @in;
    while(<>) {
      chomp;
      push @in, $_;
    }

    print join "\n", @in;

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM::Notifier>, L<App::MonM::Notifier::Channel>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK::Util qw/ execute /;
use CTK::ConfGenUtil;

sub process {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type eq 'command';
    my $message = $self->message;
    unless ($message) {
        $self->error("Incorrect Email::MIME object");
        return;
    }

    my $command = value($self->config, "command") || value($self->config, "script");
    unless ($command) {
        $self->error("Command string incorrect");
        return;
    }

    my $data = $message->as_string;

    # Run command
    my $exe_err = '';
    my $exe_out = execute($command, $data, \$exe_err);
    my $stt = ($? >> 8);
    my $exe_stt = $stt ? 0 : 1;
    $self->status($exe_stt);
    $self->error(sprintf("Exitval=%d; Error=%s", $stt, $exe_err)) unless $exe_stt;

    return;
}

1;

__END__
