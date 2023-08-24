package App::VTide::Command::Sessions;

# Created on: 2016-03-22 15:42:06
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English    qw/ -no_match_vars /;
use YAML::Syck qw/ DumpFile LoadFile /;
use Path::Tiny;
use App::VTide::Sessions;
use Data::Dumper qw/Dumper/;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('1.0.5');
our $NAME    = 'sessions';
our $OPTIONS = [
    'dest|d=s',  'global|g', 'session|source|s=s', 'verbose|v+',
    'update|u!', 'test|t!'
];
sub details_sub { return ( $NAME, $OPTIONS ) }

has global => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->options->opt->{global} || !$ENV{VTIDE_NAME};
    },
);
has sessions => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $file =
            $self->global
          ? $App::VTide::Sessions::global_file
          : $App::VTide::Sessions::local_file;
        return App::VTide::Sessions->new( { sessions_file => $file } );
    },
);

sub run {
    my ($self) = @_;

    $self->options->opt->{update} //= 1;
    $self->options->opt->{session} ||= 'current';
    my $local   = !$self->global;
    my $command = 'session_' . ( shift @{ $self->options->files } || 'list' );

    if ( !$self->can($command) ) {
        warn "Unknown command $command!\n";
        return;
    }

    my $session = $self->sessions;

    $self->$command($session);

    return;
}

sub session_list {
    my ( $self, $session ) = @_;
    my $name = $self->options->opt->{session};
    $session ||= $self->sessions;

    if ( $self->options->opt->{verbose} ) {
        print "Sessions:\n";
        for my $name ( sort keys %{ $session->sessions } ) {
            print "  $name\n";
        }
        print "\n";
    }

    print "$name:\n";
    if ( $session->sessions->{$name} ) {
        my $cmd = "vtide session"
          . (
            $name eq 'current'
            ? ''
            : " --session $name"
          );
        for my $i ( 0 ... @{ $session->sessions->{$name} } - 2 ) {
            my $files = $session->sessions->{$name}[$i];

            print "  ", ( join " ", @$files ), "\n";
            if ( $i == 0 ) {
                print "    ('$cmd shift' to run)\n";
            }
            elsif ( $i == @{ $session->sessions->{$name} } - 2 ) {
                print "    ('$cmd pop' to run)\n";
            }
        }
    }
    else {
        print "  Empty\n";
    }
}

sub session_unshift {
    my ($self) = @_;
    return $self->modify_session(
        sub {
            unshift @{ $_[0] }, $self->options->files;
            return;
        }
    );

}

sub session_push {
    my ($self) = @_;
    return $self->modify_session(
        sub {
            push @{ $_[0] }, $self->options->files;
            return;
        }
    );

}

sub session_shift {
    my ($self) = @_;
    return $self->modify_session(
        sub {
            my ($session) = @_;
            warn "running $session->[0][0]\n";
            return shift @$session;
        }
    );
}

sub session_pop {
    my ($self) = @_;
    return $self->modify_session(
        sub {
            my ($session) = @_;
            return pop @$session;
        }
    );
}

sub modify_session {
    my ( $self, $modify ) = @_;
    my $name = $self->options->opt->{session};

    my $session = $self->sessions->sessions;

    my $files = $modify->( $session->{$name} );

    if ( !@{ $session->{$name} } ) {
        delete $session->{$name};
        warn "Empty session removed!\n";
    }

    # TODO work out why update unset with --no-update
    # write the new session out
    if ( $self->options->opt->update ) {
        $self->sessions->write_session();
    }

    if ( !$files ) {
        $self->session_list();
        return;
    }

    my $action = $self->global ? "start" : "edit";
    warn join ' ', 'vtide', $action, @$files;
    system 'vtide', $action, @$files;
    warn join ' ', 'vtide', $action, @$files;
}

sub session_copy {
    my ($self) = @_;
    my $src    = $self->options->opt->{session};
    my $dest   = $self->options->opt->{dest};

    my $session = $self->sessions->sessions;

    if ( !$dest ) {
        warn "No destination name!";
        return;
    }
    $session->{$dest} = [ map { [@$_] } @{ $session->{$src} } ];

    $self->sessions->write_session();
    $self->session_list();
}

sub session_save {
    my ($self)  = @_;
    my $dest    = $self->options->opt->{dest} || 'current';
    my $session = $self->sessions->get_sessions($dest);

    if ( $self->options->opt->{global} ) {
        my @list = map { ( split /:/, $_ )[0] } `tmux ls`;

        push @$session, @list;
    }
    else {
        warn "Haven't yet built local session saving";
    }

    $self->sessions->write_session();
}

sub auto_complete {
    my ( $self, $auto ) = @_;

    my $partial = $ARGV[ $auto - 1 ] || '';
    print join ' ', grep { /^$partial/ } qw/
      copy
      list
      pop
      push
      shift
      unshift
      /;
}

1;

__END__

=head1 NAME

App::VTide::Command::Sessions - Create/Update/List saved vtide sessions

=head1 VERSION

This documentation refers to App::VTide::Command::Sessions version 1.0.5

=head1 SYNOPSIS

    vtide sessions [list] [(-s|--session) name] [-g|--global] [-v|--verbose]
    vtide sessions unshift [(-s|--session) name] [-g|--global] [--no-update] [-v|--verbose]
    vtide sessions push [(-s|--session) name] [-g|--global] [--no-update] [-v|--verbose]
    vtide sessions shift [(-s|--session) name] [-g|--global] [--no-update] [-v|--verbose]
    vtide sessions pop [(-s|--session) name] [-g|--global] [--no-update] [-v|--verbose]
    vtide sessions copy (-s|--source) source_session [-d|--destination] destination_session [-g|--global] [-v|--verbose]
    vtide sessions save [-d|--destination] destination-session-name

    OPTIONS
     -g --global    Look at the global sessions when in side a vtide managed terminal
     -s --session[=]name
                    Look at or modify this session (Default current)
     -s --source[=]name
                    Copy this session
     -d --dest[=]name
                    Replace/add this session
     -u --update    Update sessions (default)
        --no-update Don't update sessions

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
