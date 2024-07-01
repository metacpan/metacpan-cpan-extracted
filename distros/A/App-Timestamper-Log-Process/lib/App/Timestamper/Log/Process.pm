package App::Timestamper::Log::Process;
$App::Timestamper::Log::Process::VERSION = '0.2.0';
use 5.014;
use strict;
use warnings;
use autodie;

use bigint;

use Carp                ();
use File::ReadBackwards ();
use Getopt::Long        qw( GetOptionsFromArray  );

# use parent qw(ParentClass);

sub _argv
{
    my $self = shift;

    if (@_)
    {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}

sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my ( $self, $args ) = @_;
    $self->_argv( $args->{argv} // ( die "no argv key" ) );

    return;
}

my $NUM_DIGITS = 16;
my $LOW_BASE   = 10;
my $HIGH_BASE  = 1;
foreach my $e ( 1 .. $NUM_DIGITS )
{
    $HIGH_BASE *= $LOW_BASE;
}
my $OUT_NUM_DIGITS = 8;
my $TO_OUT_BASE    = 1;
foreach my $e ( 1 .. ( $NUM_DIGITS - $OUT_NUM_DIGITS ) )
{
    $TO_OUT_BASE *= $LOW_BASE;
}

sub run
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();

    my $mode = shift(@$argv);

    if ( ( $mode eq "from_start" ) or ( $mode eq "from-start" ) )
    {
        return $self->_mode_from_start();
    }
    elsif ( ( $mode eq "time" ) )
    {
        return $self->_mode_time();
    }
    else
    {
        Carp::confess("Unknown mode '$mode'!");
    }

    return;
}

sub _calc_ticks_and_data_str
{
    my ( $self, $line ) = @_;
    chomp $line;
    if ( my ( $seconds, $dotdigits, $data_str ) =
        ( $line =~ m#\A([0-9]+)((?:\.(?:[0-9]){0,16})?)\t([^\n]*\z)#ms ) )
    {
        my $ticks = $seconds * $HIGH_BASE;
        if ( $dotdigits =~ s#\A\.##ms )
        {
            $dotdigits .=
                scalar( "0" x ( $NUM_DIGITS - length($dotdigits) ) );
            $ticks += ( 0 + $dotdigits );
        }
        return ( $ticks, $data_str );
    }
    else
    {
        die "The line is formatted wrong";
    }
}

sub _mode_from_start
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();
    my $output_fn;
    my $ret = GetOptionsFromArray( $argv, "output|o=s" => ( \$output_fn ), )
        or Carp::confess($!);
    my $input_fn = shift(@$argv);
    if ( not defined($input_fn) )
    {
        die "Must specify an input file-path!";
    }
    if (@$argv)
    {
        die "Leftover command-line arguments after the input filename";
    }

    my $USE_STDOUT = ( not( defined($output_fn) and ( $output_fn ne "-" ) ) );

    my $out;
    if ($USE_STDOUT)
    {
        ## no critic
        open $out, ">&STDOUT";
        ## use critic
    }
    else
    {
        open $out, ">", $output_fn;
    }
    open my $in, "<", $input_fn;
    my $start;

    while ( my $line = <$in> )
    {
        chomp $line;
        my ( $ticks, $data_str ) = $self->_calc_ticks_and_data_str($line);
        if ( not defined($start) )
        {
            $start = $ticks;
        }
        my $distance     = $ticks - $start;
        my $dist_seconds = $distance / $HIGH_BASE;
        my $dist_dot     = $distance % $HIGH_BASE;
        $dist_dot /= $TO_OUT_BASE;
        $out->printf(
            "%d\.%0*d\t%s\n", $dist_seconds, $OUT_NUM_DIGITS,
            $dist_dot,        $data_str
        );
    }

    close($in);
    if ( not $USE_STDOUT )
    {
        close($out);
    }

    return;
}

sub _mode_time
{
    my ( $self, ) = @_;

    my $argv = $self->_argv();
    my $output_fn;
    my $ret = GetOptionsFromArray( $argv, "output|o=s" => ( \$output_fn ), )
        or Carp::confess($!);
    my $USE_STDOUT = ( not( defined($output_fn) and ( $output_fn ne "-" ) ) );

    my $out;
    if ($USE_STDOUT)
    {
        ## no critic
        open $out, ">&STDOUT";
        ## use critic
    }
    else
    {
        open $out, ">", $output_fn;
    }
    while (@$argv)
    {
        my $input_fn = shift(@$argv);
        if ( not defined($input_fn) )
        {
            die "Must specify an input file-path!";
        }

        open my $in, "<", $input_fn;
        my $start;

        {
            my $line = <$in>;
            my ( $ticks, $data_str ) = $self->_calc_ticks_and_data_str($line);
            die if ( defined($start) );
            $start = $ticks;
        }

        close($in);

        my $end_ticks;
        {
            my $bw_in = File::ReadBackwards->new($input_fn)
                or Carp::confess("can't open $input_fn backwards $!");
            my $line = $bw_in->readline();
            $bw_in->close();
            my ( $ticks, $data_str ) = $self->_calc_ticks_and_data_str($line);
            $end_ticks = $ticks;
        }
        my $distance     = $end_ticks - $start;
        my $dist_seconds = $distance / $HIGH_BASE;
        my $dist_dot     = $distance % $HIGH_BASE;
        $dist_dot /= $TO_OUT_BASE;
        $out->printf(
            "%d\.%0*d\t%s\n", $dist_seconds, $OUT_NUM_DIGITS,
            $dist_dot,        $input_fn,
        );
    }

    if ( not $USE_STDOUT )
    {
        close($out);
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Timestamper::Log::Process - various filters and queries for
L<App::Timestamper> logs.

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 my $app_obj = App::Timestamper::Log::Process->new({argv => [@ARGV],});

Instantiate a new application object.

=head2 $app_obj->run()

Run the application based on the Command-Line (“CLI”) arguments.

=head1 MODES

=head2 from_start

    timestamper-log-process from_start --output zero-based.ts.log.txt absolute-timestamps.ts.log.txt

Start the timestamps from 0 by negating the one on the first line.

=head2 time

    timestamper-log-process time --output run-times-of-log-files.txt [files]

Calculate the wallclock times, from-start-to-finish, of one or more timestamper log files.

( Added in v0.2.0 . ).

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Timestamper-Log-Process>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Timestamper-Log-Process>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Timestamper-Log-Process>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Timestamper-Log-Process>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Timestamper-Log-Process>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Timestamper::Log::Process>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-timestamper-log-process at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Timestamper-Log-Process>. You will be automatically notified of any
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

This software is Copyright (c) 2024 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
