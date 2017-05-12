package App::CmdDirs::Traverser::Base;
use strict;
use warnings;

use Term::ANSIColor;

sub new {
    my ($class, $command, $topDir, $dirs) = @_;

    my $self = {};
    bless $self, $class;

    $self->{'command'} = $command;
    $self->{'topDir'} = $topDir;
    $self->{'dirs'} = $dirs;

    return $self;
}

# Return false to skip this directory
sub test {
    # Override this
    return 1;
}

# Run this class' test() on each directory.  If the test passes, descend
# into that directory, run $command, and return to the top directory.
sub traverse {
    my ($self, $quiet) = @_;

    my $command = $self->{'command'};
    my $topDir = $self->{'topDir'};

    my @dirs = @{$self->{'dirs'}};
    foreach my $dir (@dirs) {
        next if ! -d $dir;
        next if ! $self->test($dir);

        # Tell the user what command is going to be run
        unless ($quiet) {
            print color 'bold green';
            print "Performing `$command` in <$dir>\n";
            print color 'reset';
        }

        # Descend into the directory & run the command
        chdir $dir;
        system("$command");
        chdir $topDir;

        print "\n";
    }

    return 1
}

1;
