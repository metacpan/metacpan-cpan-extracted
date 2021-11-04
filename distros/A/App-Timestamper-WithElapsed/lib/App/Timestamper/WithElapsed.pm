package App::Timestamper::WithElapsed;
$App::Timestamper::WithElapsed::VERSION = '0.6.1';
use strict;
use warnings;
use 5.014;
use autodie;

# -------------------------
#
# timestamper-with-elapsed.pl
#
# Based on the synopses of https://metacpan.org/release/IO-Async
# by PEVANS (Paul Evans) and relicensed as MIT License with his
# permission. Thanks!

use Getopt::Long 2.37 qw/ GetOptionsFromArray /;
use Time::HiRes qw/ time /;

use IO::Async::Stream          ();
use IO::Async::Loop            ();
use IO::Async::Timer::Periodic ();

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _absolute
{
    my $self = shift;

    if (@_)
    {
        $self->{_absolute} = shift;
    }

    return $self->{_absolute};
}

sub _from_start
{
    my $self = shift;

    if (@_)
    {
        $self->{_from_start} = shift;
    }

    return $self->{_from_start};
}

sub _output_fn
{
    my $self = shift;

    if (@_)
    {
        $self->{_output_fn} = shift;
    }

    return $self->{_output_fn};
}

sub _init
{
    my ( $self, $args ) = @_;
    my $argv = ( $args->{argv} // [] );

    my $absolute;
    my $from_start;
    my $help;
    my $output_fn;
    GetOptionsFromArray(
        $argv,
        'absolute!'   => \$absolute,
        'from-start!' => \$from_start,
        'h|help'      => \$help,
        'o|output=s'  => \$output_fn,
    ) or die $!;
    if ($help)
    {
        print <<"EOF";
$0 - timestamps with "elapsed since last updates

--from-start     Display the time that has passed since the start of the process
                 rather than absolute epoch time.

--absolute       Display the from-start time instead of the elapsed-since-last
                 -line time.

--help           This help display.
EOF
        exit;
    }
    $self->_absolute($absolute);
    $self->_from_start($from_start);
    $self->_output_fn($output_fn);
    return;
}

sub run
{
    my $self = shift;
    my $loop = IO::Async::Loop->new;
    my $out_fh;
    if ( defined( my $output_fn = $self->_output_fn ) )
    {
        open $out_fh, ">:encoding(utf-8)", $output_fn;
        $out_fh->autoflush(1);
    }

    my $last_line_time = time();
    my $init_time      = $self->_from_start ? ( $last_line_time + 0 ) : 0;
    STDOUT->autoflush(1);
    my $timer = IO::Async::Timer::Periodic->new(
        interval => 0.1,

        on_tick => scalar(
            $self->_absolute()
            ? sub {
                my $t = time();
                printf "\r%.8f since start", $t - $init_time;

                return;
                }
            : sub {
                my $t = time();
                printf "\r%.8f elapsed", $t - $last_line_time;

                return;
            }
        ),
    );
    my $out = sub {
        my $t = shift;
        my $l = shift;
        chomp $l;
        my $s = sprintf( "%.8f    %s", $t - $init_time, $l );
        printf "\r%-70s\n", $s;
        if ( defined $out_fh )
        {
            $out_fh->printf( "%.8f\t%s\n", $t, $l );
        }
        return;
    };

    my $stream = IO::Async::Stream->new(
        read_handle => \*STDIN,
        on_read     => sub {
            my ( $self, $buffref, $eof ) = @_;

            while ( $$buffref =~ s/\A([^\n]*\n)//ms )
            {
                my $l = $1;
                my $t = time();
                $out->( $t, $l );
                $last_line_time = $t;
            }

            if ($eof)
            {
                $out->( time(), $$buffref );
                $loop->stop();
                if ( defined $out_fh )
                {
                    close $out_fh;
                }
            }

            return 0;
        }
    );

    $loop->add($stream);
    $timer->start();
    $loop->add($timer);
    $loop->run();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Timestamper::WithElapsed - display the timestamp STDIN lines were received and the elapsed
seconds since the last received line.

=head1 VERSION

version 0.6.1

=head1 SYNOPSIS

    $ [process] | perl -MApp::Timestamper::WithElapsed -e 'App::Timestamper::WithElapsed->new->run'

=head1 METHODS

=head2 new

Constructor

=head2 run

Run the application .

=head1 CREDITS

Based on the synopses of L<https://metacpan.org/release/IO-Async>
by PEVANS (Paul Evans) and relicensed as MIT License with his
permission. Thanks!

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Timestamper-WithElapsed>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Timestamper-WithElapsed>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Timestamper-WithElapsed>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Timestamper-WithElapsed>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Timestamper-WithElapsed>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Timestamper::WithElapsed>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-timestamper-withelapsed at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Timestamper-WithElapsed>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-Timestamper>

  git clone git://github.com/shlomif/App-Timestamper.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/App-Timestamper/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
