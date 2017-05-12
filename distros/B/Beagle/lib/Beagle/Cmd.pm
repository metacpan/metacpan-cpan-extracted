package Beagle::Cmd;
use Any::Moose;
use Beagle::Util;
extends any_moose('X::App::Cmd');

before 'run' => sub {
    @ARGV = map { defined $_ ? decode( locale => $_ ) : $_ } @ARGV;

    if ( !@ARGV ) {
        my $command =
          $ENV{BEAGLE_DEFAULT_COMMAND}
          ? decode( locale => $ENV{BEAGLE_DEFAULT_COMMAND} )
          : core_config->{default_command};

        if ($command) {
            require Text::ParseWords;
            @ARGV = Text::ParseWords::shellwords($command);
        }
        else {
            @ARGV = 'shell';
        }
    }

    my $cmd = $ARGV[0];

    # default cmd is today
    $cmd = 'today' unless defined $cmd;

    if ( $cmd =~ /--?v(?:ersion)?/ ) {
        $ARGV[0] = 'version';
    }
    elsif ( $cmd eq 'help' || $cmd =~ /^--?h(?:help)?/ ) {
        if ( grep { /^[^-]/ } @ARGV[1..$#ARGV] ) {
            $ARGV[0] = 'help';
        }
        else {
            $ARGV[0] = 'commands';
        }
    }
    elsif ( $cmd eq '.' || $cmd =~ /^-/ ) {
        unshift @ARGV, core_config->{default_command};
    }


    if ( alias()->{$cmd} ) {
        require Text::ParseWords;
        my @words = Text::ParseWords::shellwords( alias()->{$cmd} );

        shift @ARGV;

        unshift @ARGV, @words;
    }

};

sub execute_command {
    my ( $self, $cmd, $opt, @args ) = @_;
    $cmd->validate_args( $opt, \@args );

    for my $key ( keys %$opt ) {
        if ( $key =~ /-/ ) {
            my $new = $key;
            $new =~ s!-!_!g;
            $opt->{$new} = delete $opt->{$key};
        }
    }

    @args = grep { $_ ne '--' } @args;

    $cmd->execute( $opt, \@args );
}

sub command_plugins {
    my $self = shift;
    return uniq grep { $_ ne 'App::Cmd::Command::help' } values %{ $self->_command };
}


no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

