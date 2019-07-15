package App::MonM::Checkit::Command; # $Id: Command.pm 80 2019-07-08 10:41:47Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit::Command - Checkit Command subclass

=head1 VIRSION

Version 1.00

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

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

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
$VERSION = '1.00';

use CTK::Util qw/ execute /;
use CTK::ConfGenUtil;

sub check {
    my $self = shift;
    my $type = $self->type;
    return $self->maybe::next::method() unless $type && $type eq 'command';

    # Init
    my $command = value($self->config, 'command') || '';
    my $content = value($self->config, 'content') // '';
    unless (length($command)) {
        $self->status(0);
        $self->source("NOOP");
        $self->message('Command not specified');
        return;
    }
    $self->source($command);

    # Run command
    my $exe_err = '';
    my $exe_out = execute($command, length($content) ? $content : undef, \$exe_err);
    my $stt = $? >> 8;
    my $exe_stt = $stt ? 0 : 1;
    $self->status($exe_stt);
    $self->code($stt);
    $self->message($exe_stt ? "OK" : "ERROR");
    if (defined($exe_out) && length($exe_out)) {
        chomp($exe_out);
        $self->content($exe_out) ;
    }
    if (!$exe_stt && $exe_err) {
        chomp($exe_err);
        $self->error($exe_err);
    } elsif ($stt) {
        $self->error(sprintf("Exitval=%d", $stt));
    }

    return;
}

1;

__END__
