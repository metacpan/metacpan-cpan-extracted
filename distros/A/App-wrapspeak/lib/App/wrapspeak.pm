package App::wrapspeak;

use Exporter 'import';
@EXPORT_OK = qw(run);

use Modern::Perl;
use IPC::Open3;
use Term::TermKey;
use File::Slurp qw/read_file/;
use Time::HiRes qw( alarm );
use IO::Select;

our $VERSION = '0.1';

=head1 NAME

App::wrapspeak - It speaks for you !

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

This App intends to be a simple wrapper around speech synthesis engines.
Currently, only festival is supported.

By wrapping, it provides pause, rewind and forward functionalities.

=head1 USAGE

wrapspeak.pl text_file_name

=over 4

=item * Space for pause

=item * Any Key resumes while paused.

=item * Left for rewind by 1 sentence.

=item * Right for forward by 1 sentence.

=back

=cut

=head1  SUBS

=head2 run

This is the main subroutine that gets called by the script.

It does the following.

=over 4

=item * Grab all senetences in text.

=item * Open3 a pipe to festival.

=item * Wait, for user to press a key / or for the sentence read by
festival to end.

=item * If use has pressed the Space kye, it waits.
If the user  Left, Right it changes the sentence order.

=item * If the sentence has ended , it goes for the next sentence in the LOOP

=back

=cut


sub run {
    $| = 1;

    my $file = shift @ARGV;

    my $txt = read_file $file;

    my @sentences = split /\./, $txt;

    open3( \*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, 'festival -i' );

    *CHLD_OUT->blocking(0);
    *CHLD_OUT->autoflush(1);
    *CHLD_ERR->blocking(0);
    *CHLD_ERR->autoflush(1);

    my $tk = Term::TermKey->new( \*STDIN );

    my $sel = IO::Select->new();
    $sel->add( \*CHLD_OUT );

    my $sentence_index = 0;

MAIN:
    while (1) {
        my $sentence = $sentences[$sentence_index];
        last MAIN if ( !defined($sentence) );

        print $sentence;
        $sentence =~ s/"/ /;
        *CHLD_IN->print("(SayText \"$sentence\")\n");

        my @err = *CHLD_ERR->getlines();
        if (@err) {
            die @err;
        }

        my $c;
        my $ret;

    LOOP:
        while (1) {
            while ( my @ready = $sel->can_read(0.1) ) {
                my $chld_out = shift @ready;
                my @lines    = $chld_out->getlines();
                if ( grep {/festival>/} @lines ) {
                    last LOOP;
                }
            }
            my $key;
            eval {
                local $SIG{ALRM} = sub { die "alarm\n" };
                alarm 0.3;
                $tk->waitkey($key);
                alarm 0;
            };
            if ($@) {
                die unless $@ eq "alarm\n";
            }
            else {
                my $str = $tk->format_key( $key, 0 );
                if ( $str =~ /Left/ ) {
                    $sentence_index = $sentence_index - 2;
                    say "\nMoved back by 1 sentences";
                    print $sentences[ $sentence_index + 1 ];
                    next LOOP;
                }
                if ( $str =~ /Right/ ) {
                    $sentence_index = $sentence_index + 1;
                    say "\nMoved forward by 1 sentence";
                    print $sentences[$sentence_index];
                    next LOOP;
                }
                elsif ( $str =~ / / ) {
                    say "\n... PAUSED ...";
                    $tk->waitkey( my $key );
                    say "\n...RESUMED...";
                }
            }
        }
        $sentence_index++;
    }
}

=head1 TODO

=over 4

=item * Extend to espeak

=back

=head1 AUTHOR

mucker, C<< <mukcer at gmx.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-wrapspeak at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ap
p-wrapspeak>.  I will be notified, and then you'll automatically be notified of pro
gress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc App::wrapspeak


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-wrapspeak>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-wrapspeak>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-wrapspeak>

=item * Search CPAN

L<http://search.cpan.org/dist/App-wrapspeak/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 mucker.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
