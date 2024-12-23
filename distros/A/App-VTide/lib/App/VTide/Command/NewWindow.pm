package App::VTide::Command::NewWindow;

# Created on: 2016-03-22 15:42:06
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use YAML::Syck;
use File::chdir;
use Data::Dumper qw/Dumper/;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('1.0.6');
our $NAME    = 'new-window';
our $OPTIONS = [ 'force|f!', 'number|n=s', 'test|t!', 'verbose|v+', ];
our $LOCAL   = 1;
sub details_sub { return ( $NAME, $OPTIONS, $LOCAL ) }

sub run {
    my ($self) = @_;

    my $terminals = $self->config->get->{terminals};
    my $number    = $self->defaults->{number};
    my $term      = $terminals->{$number};

    # list panes in current session
    # $ tmux list-panes -s
    # 1.0: [180x96] [history 3781/4096, 2233336 bytes] %213 (active)
    # 1.1: [180x24] [history 2856/4096, 2107575 bytes] %214
    # 1.2: [180x71] [history 0/4096, 4236 bytes] %216
    # 2.0: [361x96] [history 291/4096, 366910 bytes] %217 (active)
    # 3.0: [361x96] [history 579/4096, 903096 bytes] %218 (active)
    # 4.0: [361x96] [history 1467/4096, 2054430 bytes] %219 (active)
    # 5.0: [361x96] [history 0/4096, 6591 bytes] %220 (active)
    # 6.0: [361x96] [history 0/4096, 6591 bytes] %221 (active)
    # 7.0: [361x96] [history 0/4096, 6591 bytes] %222 (active)
    # 8.0: [361x96] [history 0/4096, 6591 bytes] %223 (active)
    # 9.0: [361x96] [history 0/4096, 6591 bytes] %224 (active)
    # 10.0: [361x96] [history 0/4096, 6591 bytes] %225 (active)

    my $session = $self->get_panes(1);

    if ( $session->{$number} && !$self->defaults->{force} ) {
        system 'tmux', 'select-window', '-t', $number;
        return;
    }

    if ( !$session->{ $number - 1 } ) {
        warn "Sessions will be out of order!\n";
        return if !$self->defaults->{force};
    }

    my @verbose = $self->defaults->{verbose} ? ('--verbose') : ();
    my @test    = $self->defaults->{test}    ? ('--test')    : ();
    $ENV{VTIDE_TERM} = $number;
    if ( $term->{dir} ) {
        $CWD = $term->{dir};
    }
    system 'tmux', 'new-window', "vtide run @test @verbose $number && sleep 15";
    if ( $term->{split} ) {
        system 'vtide', 'split', @test, @verbose, $term->{split};
    }

    #my @panes = keys %{ $self->get_panes()->{''} };
    #for my $pane (@panes) {
    #    next if $pane == 0;

    #    my $letter = 'a' + $pane;
    #    warn "$number$letter";
    #    next if !$terminals->{"$number$letter"};
    #}

    return;
}

sub get_panes {
    my ( $self, $all ) = @_;

    my %session;
    my $session = $all ? ' -s' : '';
    for my $pane (`tmux list-panes $session`) {
        my ( $window, $pane ) = $pane =~ /^(?:(\d+).)?(\d+)/;
        $session{ $window || '' }{$pane}++;
    }

    return \%session;
}

sub auto_complete {
    my ( $self, $auto ) = @_;

    my $env   = $self->options->files->[-1] // '';
    my @files = sort keys %{ $self->config->get->{editor}{files} };

    # TODO complete terminal numbers

    print join ' ',
      grep { $env ne 'vtide' && $env ne 'edit' ? /^$env/xms : 1 } @files;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::NewWindow - Create a new-window in a running App::VTide session

=head1 VERSION

This documentation refers to App::VTide::Command::NewWindow version 1.0.6

=head1 SYNOPSIS

    vtide new-window ([-n|--number] int)

    OPTIONS
     -f --force     Force creating sessions out of order
     -n --number[=](int)
                    The maximum number of new-window sessions to show (Default 10)
     -v --verbose   Show more detailed output
        --help      Show this help
        --man       Show the full man page

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<run ()>

Run the command

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
