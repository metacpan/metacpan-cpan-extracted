package App::Countdown;

use 5.010;

use strict;
use warnings FATAL => 'all';

use Time::HiRes qw(sleep time);
use POSIX qw();
use IO::Handle;
use Getopt::Long qw(2.36 GetOptionsFromArray);
use Pod::Usage;
use Carp;

=head1 NAME

App::Countdown - wait some specified time while displaying the remaining time.

=head1 VERSION

Version 0.4.4

=cut

our $VERSION = '0.4.4';


=head1 SYNOPSIS

    use App::Countdown;

    App::Countdown->new({ argv => [@ARGV] })->run();

=head1 SUBROUTINES/METHODS

=head2 new

A constructor. Accepts the argv named arguments.

=head2 run

Runs the program.

=cut

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _delay
{
    my $self = shift;

    if (@_)
    {
        $self->{_delay} = shift;
    }

    return $self->{_delay};
}

my $up_to_60_re = qr/[1-9]|[1-5][0-9]|0[0-9]?/;

sub _get_up_to_60_val
{
    my ($v) = @_;

    ($v //= '') =~ s/\A0*//;

    return (length($v) ? $v : 0);
}

sub _calc_delay
{
    my ($self, $delay_spec) = @_;

    if (my ($n, $qualifier) = $delay_spec =~ /\A((?:[1-9][0-9]*(?:\.\d*)?)|(?:0\.\d+))([mhs]?)\z/)
    {
        return int($n * ($qualifier eq 'h'
                ? (60 * 60)
                : $qualifier eq 'm'
                ? 60
                : 1
            )
        );
    }
    elsif (my ($min, $sec) = $delay_spec =~ /\A([1-9][0-9]*)m($up_to_60_re)s\z/)
    {
        return $min * 60 + _get_up_to_60_val($sec);
    }
    elsif (((my $hour), $min, $sec) =
        $delay_spec =~ /\A([1-9][0-9]*)h(?:($up_to_60_re)m)?(?:($up_to_60_re)s)?\z/
    )
    {
        return (($hour * 60 + _get_up_to_60_val($min)) * 60 + _get_up_to_60_val($sec));
    }
    else
    {
        die "Invalid delay. Must be a positive and possibly fractional number, possibly followed by s, m, or h";
    }
}

sub _init
{
    my ($self, $args) = @_;

    my $argv = [@{$args->{argv}}];

    my $help = 0;
    my $man = 0;
    my $version = 0;
    if (! (my $ret = GetOptionsFromArray(
        $argv,
        'help|h' => \$help,
        man => \$man,
        version => \$version,
    )))
    {
        die "GetOptions failed!";
    }

    if ($help)
    {
        pod2usage(1);
    }

    if ($man)
    {
        pod2usage(-verbose => 2);
    }

    if ($version)
    {
        print "countdown version $VERSION .\n";
        exit(0);
    }

    my $delay = shift(@$argv);

    if (!defined $delay)
    {
        Carp::confess ("You should pass a number of seconds.");
    }

    $self->_delay(
        $self->_calc_delay($delay)
    );

    return;
}

sub run
{
    my ($self) = @_;

    STDOUT->autoflush(1);

    my $delay = $self->_delay;

    my $start = time();
    my $end = $start + $delay;

    my $last_printed;
    while ((my $t = time()) < $end)
    {
        my $new_to_print = POSIX::floor($end - $t);
        if (!defined($last_printed) or $new_to_print != $last_printed)
        {
            $last_printed = $new_to_print;
            print "Remaining $new_to_print/$delay", ' ' x 40, "\r";
        }
        sleep(0.1);
    }

    return;
}

1;

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>, C<< <shlomif at cpan.org> >> .

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/shlomif/App-Countdown/issues> .

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Countdown


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Countdown>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Countdown>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Countdown>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Countdown/>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Neil Bowers

Reporting a typo and a problem with the description not fitting on one line.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of App::Countdown
