package App::mhping;
our $VERSION = "0.1";

=encoding utf-8

=head1 NAME

mhping - Multiple host ping

=begin HTML

<p>
	<img src="https://raw.github.com/arpadszasz/mhping/master/mhping.jpg"
    width="507" height="214" alt="Screenshot of mhping" />
</p>

=end HTML

=head1 SYNOPSIS

    mhping [options] [systems...]

=head1 DESCRIPTION

mhping is a sysadmin tool that allows You to simultaneously check multiple
hosts for availability. Target hosts can be specified one per line in several
ways (in order of precedence):

=over 4

=item 1.
from command line

=item 2.
from stdin

=item 3.
from a file using the C<-f> option

=back

=head1 OPTIONS

=over 4

=item B<-f, --filename> file

Read list of targets from file or stdin if C<-> is specified as the filename.

=item B<-h, --help>

Print usage message.

=item B<-i, --interval> number

The minimum amount of time between sending ping packets. Default is 1 second.

=item B<-v, --version>

Print C<mhping> version information.

=back

=head1 COMPATIBILITY

This program requires Perl minimum version 5.8.8 with ithreads support to run.
It has been tested on the following minimum setup:

=over 4

=item *
Perl 5.8.8

=item *
threads 1.79

=item *
threads::shared 0.94

=item *
Thread::Queue 2.00

=back

=head1 BUGS

Please report bugs on github: L<https://github.com/arpadszasz/mhping/issues>

=head1 AUTHORS

Árpád Szász

=head1 SEE ALSO

L<ping(8)>
L<fping(8)>
L<mtr(8)>
L<threads>
L<threads::shared>
L<Thread::Queue>

=cut

1;
