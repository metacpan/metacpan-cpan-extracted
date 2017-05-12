package App::Cleo;

use strict;
use warnings;

use Term::ReadKey;
use Term::ANSIColor qw(colored);
use File::Slurp qw(read_file);
use Time::HiRes qw(usleep);

our $VERSION = 0.004;

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = {
        shell  => $ENV{SHELL} || '/bin/bash',
        prompt => colored( ['green'], '(%d)$ '),
        delay  => 25_000,
        @_,
    };

    return bless $self, $class;
}

#-----------------------------------------------------------------------------

sub run {
    my ($self, $commands) = @_;

    my $type = ref $commands;
    my @commands = !$type ? read_file($commands)
        : $type eq 'SCALAR' ? split "\n", ${$commands}
            : $type eq 'ARRAY' ? @{$commands}
                : die "Unsupported type: $type";

    open my $fh, '|-', $self->{shell} or die $!;
    $self->{fh} = $fh;
    ReadMode('raw');
    local $| = 1;

    chomp @commands;
    @commands = grep { /^\s*[^\#;]\S+/ } @commands;

    CMD:
    for (my $i = 0; $i < @commands; $i++) {

        my $cmd = $commands[$i];
        chomp $cmd;

        $self->do_cmd($cmd) and next CMD
            if $cmd =~ s/^!!!//;

        print sprintf $self->{prompt}, $i;

        my @steps = split /%%%/, $cmd;
        while (my $step = shift @steps) {

            my $key = ReadKey(0);
            print "\n" if $key =~ m/[srp]/;

            last CMD       if $key eq 'q';
            next CMD       if $key eq 's';
            redo CMD       if $key eq 'r';
            $i--, redo CMD if $key eq 'p';

            $step .= ' ' if not @steps;
            my @chars = split '', $step;
            print and usleep $self->{delay} for @chars;
        }

        my $key = ReadKey(0);
        print "\n";

        last CMD       if $key eq 'q';
        next CMD       if $key eq 's';
        redo CMD       if $key eq 'r';
        $i--, redo CMD if $key eq 'p';

        $self->do_cmd($cmd);
    }

    ReadMode('restore');
    print "\n";

    return $self;
}

#-----------------------------------------------------------------------------

sub do_cmd {
    my ($self, $cmd) = @_;

    my $cmd_is_finished;
    local $SIG{ALRM} = sub {$cmd_is_finished = 1};

    $cmd =~ s/%%%//g;
    my $fh = $self->{fh};

    print $fh "$cmd\n";
    print $fh "kill -14 $$\n";
    $fh->flush;

    # Wait for signal that command has ended
    until ($cmd_is_finished) {}
    $cmd_is_finished = 0;

    return 1;
}

#-----------------------------------------------------------------------------
1;

=pod

=head1 NAME

App::Cleo - Play back shell commands for live demonstrations

=head1 SYNOPSIS

  use App::Cleo
  my $cleo = App::Cleo->new(%options);
  $cleo->run($commands);

=head1 DESCRIPTION

App::Cleo is the back-end for the L<cleo> utility.  Please see the L<cleo>
documentation for details on how to use this.

=head1 CONSTRUCTOR

The constructor accepts arguments as key-value pairs.  The following keys are
supported:

=over 4

=item delay

Number of milliseconds to wait before displaying each character of the command.
The default is C<25_000>.

=item prompt

String to use for the artificial prompt.  The token C<%d> will be substituted
with the number of the current command.  The default is C<(%d)$>.

=item shell

Path to the shell command that will be used to run the commands.  Defaults to
either the C<SHELL> environment variable or C</bin/bash>.

=back

=head1 METHODS

=over 4

=item run( $commands )

Starts playback of commands.  If the argument is a string, it will be treated
as a file name and commands will be read from the file. If the argument is a
scalar reference, it will be treated as a string of commands separated by
newlines.  If the argument is an array reference, then each element of the
array will be treated as a command.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2014, Imaginative Software Systems

=cut
