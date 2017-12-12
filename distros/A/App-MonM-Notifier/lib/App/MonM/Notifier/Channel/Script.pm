package App::MonM::Notifier::Channel::Script; # $Id: Script.pm 29 2017-11-20 12:21:02Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel::Script - monotifier script channel

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Channel;

    # Create channel object
    my $channel = new App::MonM::Notifier::Channel;

    # Send message via file channel
    $channel->script(
        {
            id      => 1,
            to      => "anonymous",
            from    => "sender",
            subject => "Test message",
            message => "Content of the message",
            headers => {
                       "X-Foo"  => "Extended eXtra value",
                },
        },
        {
            encoding => 'base64', # Default: 8bit
            content_type => undef, # Default: text/plain
            charset => undef, # Default: utf-8

            script => '/usr/bin/script.pl', # Default: none
        }) or warn( $channel->error );

    # See error
    print $channel->error unless $channel->status;

=head1 DESCRIPTION

This module provides "script" method that send the content
of the message to an external program

    my $status = $channel->script( $data, $options );

The $data structure (hashref) describes body of message, the $options
structure (hashref) describes parameters of the connection via external modules

=head2 DATA

It is a structure (hash), that can contain the following fields:

=over 8

=item B<id>

Contains internal ID of the message. This ID is converted to an X-Id header

=item B<to>

Recipient address or name

=item B<from>

Sender address or name

=item B<subject>

Subject of the message

=item B<message>

Body of the message

=item B<headers>

Optional field. Contains eXtra headers (extension headers). For example:

    headers => {
            "bcc" => "bcc\@example.com",
            "X-Mailer" => "My mailer",
        }

=back

=head2 OPTIONS

It is a structure (hash), that can contain the following fields:

=over 8

=item B<script>

Defines full path to external program

Default: none

=back

About other options (base) see L<App::MonM::Notifier::Channel/OPTIONS>

=head2 METHODS

=over 8

=item B<init>

For internal use only!

Called from base class. Returns initialize structure

=item B<handler>

For internal use only!

Called from base class. Returns status of the operation

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

    exit;

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<App::MonM::Notifier::Channel>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Try::Tiny;

use vars qw/$VERSION/;
$VERSION = '1.01';

sub init {
    return (
        type => "Script",
    )
}
sub handler {
    my $self = shift;
    my $data = shift;
    my $options = shift;

    #print Dumper([$self, $data, $options]);

    my $program = $options->{script};
    return $self->error("Script incorrect") unless $program;

    my $prx;
    $options->{io} = \$prx;
    $self->default($data, $options);

    #print $prx;

    my ($out, $err, $q);
    try {
        $out = execute( $program, $prx, \$err, 1 );
        $q = 1;
    } catch {
        $err = sprintf("Can't execute %s. %s", $program, $_);
    };

    $self->{trace}  = _trace("SCRIPT", $program);
    $self->{trace} .= _trace("STDIN", $prx) if defined($prx) && length($prx);
    $self->{trace} .= _trace("STDOUT", $out) if defined($out) && length($out);
    $self->{trace} .= _trace("STDERR", $err) if defined($err) && length($err);
    if ($q) {
        return $self->error($err) if $err;
    } else {
        return $self->error($err);
    }

    1;
}

sub _trace {
    my $n = shift || 'DATA';
    my $s = shift;
    my @r;
    push @r, sprintf("-----BEGIN %s-----", $n);
    push @r, $s if defined $s;
    push @r, sprintf("-----END %s-----", $n);
    return join "\n", @r, "";
}


1;
