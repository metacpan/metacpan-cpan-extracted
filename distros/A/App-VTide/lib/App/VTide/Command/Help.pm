package App::VTide::Command::Help;

# Created on: 2016-02-05 10:11:54
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Pod::Usage;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('0.1.8');
our $NAME    = 'help';
our $OPTIONS = [
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub run {
    my ($self) = @_;
    my $command = shift @ARGV;

    my $sub = $self->vtide->_generate_sub_command;

    if ($command) {
        # show the help for the command
        my $title  = ucfirst $command;
        my $module = 'App/VTide/Command/' . $title . '.pm';
        pod2usage(
            -verbose  => 1,
            -input    => $INC{$module},
        );
    }
    else {
        # show the list of commands and their descriptions
        for my $cmd (sort keys %$sub) {
            my $title  = ucfirst $cmd;
            my $module = 'App/VTide/Command/' . $title . '.pm';
            require Tie::Handle::Scalar;
            my $out = '';
            tie *FH, 'Tie::Handle::Scalar', \$out;

            pod2usage(
                -verbose  => 99,
                -input    => $INC{$module},
                -exitval  => 'NOEXIT',
                -output   => \*FH,
                -sections => [qw/ NAME /],
            );

            $out =~ s/Name.*?$title/$cmd/xms;
            $out =~ s/\s\s+/ /gxms;
            print "$out\n";
        }
    }

    return;
}

sub auto_complete {
    my ($self) = @_;

    my $env = $self->options->files->[-1];
    my $sub = $self->vtide->_generate_sub_command;

    print join ' ', grep { $env ne 'help' ? /^$env/xms : 1 } sort keys %$sub;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Help - Show help for vtide commands

=head1 VERSION

This documentation refers to App::VTide::Command::Help version 0.1.8

=head1 SYNOPSIS

    vtide help
    vtide help command

  OPTIONS:
      --help        Show this help
      --man         Show full documentation

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Displays help for all available commands and individual commands

=head2 C<auto_complete ()>

Auto completes sub-commands that can have help shown

=head2 C<details_sub ()>

Returns the commands details

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
