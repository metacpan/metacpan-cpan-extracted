package CTK::Status; # $Id: Status.pm 193 2017-04-29 07:30:55Z minus $
use strict;

=head1 NAME

CTK::Status - Progressbar's system

=head1 VIRSION

Version 1.25

=head1 HISTORY

=over 8

=item B<1.00>

Init version

=item B<1.20>

On base BeeCDR

=item B<1.21>

Documentation modified

=item B<1.22>

Documentation modified

=item B<1.23>

Documentation modified

=back

=head1 SYNOPSIS

    use Time::HiRes qw ( sleep );
    use CTK::Status;

    my $a = 100;

    print "start...\n";
    CTK::Status::begin('Message blah-blah-blah', *STDOUT); # *STDOUT -- default value
    foreach (1..$a) {
        sleep 0.1;
        CTK::Status::tick($_/$a);
    }
    CTK::Status::end();
    print "finish!!!\n";

=head1 DESCRIPTION

Progressbar's system of your transactions and processes.
Note! Functions of this module are not exported

=head2 begin

    CTK::Status::begin('Message blah-blah-blah', *STDOUT); # *STDOUT -- default value

Begins process

=head2 tick

    foreach (1..$a) {
        sleep 0.1;
        CTK::Status::tick($_/$a);
    }

Show progress state

=head2 end

    CTK::Status::end();

Finishes process

=head1 SEE ALSO

C<perl>, L<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

our $VERSION = '1.25';
use Time::HiRes qw(time);
use Term::ReadKey qw(GetTerminalSize);
use IO::Handle;

my @ANIMATION;

my $message;
my $animation_index = 0;
my $last_p = 0;
my $last_t;
my $last_c;
my $width = 0;
my $cp = *STDOUT;

sub begin {
    $message = shift || '';
    $message .= ' ' if $message;
    $cp = shift || *STDOUT;
    $animation_index = 0;
    @ANIMATION = ("/", "-", "\\", "|");
    $last_c = $ANIMATION[$animation_index];
    $last_p = 0;
    $last_t = time;
    $width = (GetTerminalSize())[0] - 10; # 70
    $width = 70 if $width < 10;


    my $msglen = length($message);
    if (($width - $msglen) > 10) {
       $width -= $msglen;
       print $cp $message;
    } else {
       print $cp $message,"\n";
       $message = '';
    }

    print $cp "[>",(" " x $width),"]$last_c   0",'%',"\b" x 6;
}
sub tick {
    my $p = shift;
    $p = 1 if $p > 1;
    my $t = time;
    my $d = $t - $last_t;

    if ($last_p != $p) {
        # проценты поменялись
        if (int($p) == 1 || $d > 0.5) {
           # Прорисовываем все если процентаж изменился
           my $procent = sprintf "%3.0f%%", $p * 100;
           my $bar = "[".("=" x int($p*$width)).(int($p) < 1 ? ">" : "=").(" " x ($width-int($p*$width)))."]";

           print $cp "\r";
           print $cp $message;
           print $cp $bar;
           print $cp $last_c;
           print $cp " ";
           print $cp $procent;
           print $cp "\b" x (length($last_c.$procent)+1);

           $last_p = $p;
           $last_t = $t;
    }
    if ($d > 0.1) {
            # нужно менять только аниматора
        $animation_index = ($animation_index + 1) % @ANIMATION;
        my $c = $ANIMATION[$animation_index];
        print $cp $c . ("\b" x length($c));
        $last_c = $c;
    }
    }

    STDOUT->flush;
}
sub end {
    my $outcome = "done";
    print $cp "  $outcome\n";
    STDOUT->flush;
}

1;
