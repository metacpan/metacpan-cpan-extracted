package App::Cleo::Patra;

use strict;
use warnings;

use Term::ReadKey;
use Term::ANSIColor qw(colored);
use File::Slurp qw(read_file);
use Time::HiRes qw(usleep);

use constant PS1 => 'ps1';
use constant PS2 => 'ps2';
our $VERSION = 0.001;

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;

    my $self = {
        shell  => $ENV{SHELL} || '/bin/bash',
        ps1    => colored( ['green'], '(%d)$ '),
        ps2    => colored( ['green'], '> '),
        delay  => 25_000,
        state  => PS1,
        @_,
    };

    return bless $self, $class;
}

#-----------------------------------------------------------------------------

sub run {
    my ($self, $input, $multiline) = @_;

    my $type = ref $input;
#    my @commands_raw = !$type ? read_file($commands_raw)
#        : $type eq 'SCALAR' ? split "\n",    ${$commands_raw}
##: $type eq 'SCALAR' and     $multiline ? split /^\$\s/m,${$commands_raw}
#            : $type eq 'ARRAY' ? @{$commands_raw}
#                : die "Unsupported type: $type";

    my @commands = ();
    if (!$type) {
        if ($multiline) {
            my $data = read_file($input);
            @commands = split /^\$\s/m, $data;
        }
        else {
            @commands = read_file($input);
        }
    }

    open my $fh, '|-', $self->{shell} or die $!;
    $self->{fh} = $fh;
    ReadMode('raw');
    local $| = 1;

    local $SIG{CHLD} = sub {
        print "Child shell exited!\n";
        ReadMode('restore');
        exit;
    };

    chomp @commands;
    @commands = grep { /^\s*[^\#;]\S+/ } @commands;
    @commands = grep { /.+/ } @commands if $multiline;

#    # squeeze multi line commands into one array slot (indicated by ~~~)
#    my @commands = ();
#    for (my $i=0; $i<@commands_raw; $i++) {
#        if ($commands_raw[$i] =~ /[~]{3}(.*)/ and $i != 0) {
#            $commands[@commands - 1] .= "\n$1";
#        }
#        else {
#            push @commands, $commands_raw[$i];
#        }
#    }

    my $continue_to_end = 0;

    CMD:
    for (my $i = 0; $i < @commands; $i++) {

        my $cmd = defined $commands[$i] ? $commands[$i] : die "no command $i";
        chomp $cmd;

        my $keep_going = $cmd =~ s/^\.\.\.//;
        my $run_in_background = $cmd =~ s/^!!!//;

        $self->do_cmd($cmd) and next CMD
            if $run_in_background;

        no warnings 'redundant';
        my $prompt_state = $self->{state};
        print sprintf $self->{$prompt_state}, $i;

        my @steps = split /%%%/, $cmd;
        while (my $step = shift @steps) {

            my $should_pause = !($keep_going || $continue_to_end);
            my  $key  = $should_pause ? ReadKey(0) : '';
            if ($key  =~ /^\d$/) {
                $key .= $1 while (ReadKey(0) =~ /^(\d)/);
            }
            print "\n" if $key =~ m/^[srp]|[0-9]+/;

            last CMD             if $key eq 'q';
            next CMD             if $key eq 's';
            redo CMD             if $key eq 'r';
            $i--, redo CMD       if $key eq 'p';
            $i = $key, redo CMD  if $key =~ /^\d+$/;
            $continue_to_end = 1 if $key eq 'c';

            $step .= ' ' if not @steps;
            my @chars = split '', $step;
            print and usleep $self->{delay} for @chars;
        }

        my $should_pause = !($keep_going || $continue_to_end);
        my  $key  = $should_pause ? ReadKey(0) : '';
        if ($key  =~ /^\d$/) {
            $key .= $1 while (ReadKey(0) =~ /^(\d)/);
        }
        print "\n";

        last CMD             if $key eq 'q';
        next CMD             if $key eq 's';
        redo CMD             if $key eq 'r';
        $i--, redo CMD       if $key eq 'p';
        $i = $key, redo CMD  if $key =~ /^\d+$/;
        $continue_to_end = 1 if $key eq 'c';

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

    ($self->{state} = PS2) and return 1
        if $cmd =~ m{\s+\\$};

    print $fh "kill -14 $$\n";
    $fh->flush;

    # Wait for signal that command has ended
    until ($cmd_is_finished) {}
    $cmd_is_finished = 0;

    $self->{state} = PS1;

    return 1;
}

#-----------------------------------------------------------------------------
1;

=pod

=encoding utf8

=head1 NAME

App::Cleo - Play back shell commands for live demonstrations

=head1 SYNOPSIS

  use App::Cleo::Patra
  my $patra = App::Cleo::Patra->new(%options);
  $patra->run($commands);

=head1 DESCRIPTION

B<Important:>
C<patra> is an experimental fork from C<cleo>.
You should check the current differences from C<App-Cleo> and decide, which one you want to use.
It may be, that in your current time, C<patra> is merged back into C<cleo> or obsolete for other reasons.

App::Cleo::Patra is the back-end for the L<patra> utility.  Please see the L<patra>
documentation for details on how to use this.

=head1 CONSTRUCTOR

The constructor accepts arguments as key-value pairs.  The following keys are
supported:

=over 4

=item delay

Number of microseconds to wait before displaying each character of the command.
The default is C<25_000>.

=item ps1

String to use for the artificial prompt.  The token C<%d> will be substituted
with the number of the current command.  The default is C<(%d)$>.

=item ps2

String to use for the artificial prompt that appears for multiline commands. The
token C<%d> will be substituted with the number of the current command.  The
default is C<< > >>.

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

Boris Däppeb (BORISD) <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT

cleo - Copyright (c) 2014, Imaginative Software Systems

patra - Boris Däppen (BORISD) 2018

=cut
