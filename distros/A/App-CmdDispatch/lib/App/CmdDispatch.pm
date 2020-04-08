package App::CmdDispatch;

use warnings;
use strict;

use Config::Tiny;
use Term::ReadLine;
use App::CmdDispatch::IO;
use App::CmdDispatch::Table;

our $VERSION = '0.44';

sub new
{
    my ( $class, $commands, $options ) = @_;

    $options ||= {};
    die "Command definition is not a hashref.\n" unless ref $commands eq ref {};
    die "No commands specified.\n" unless keys %{$commands};
    die "Options parameter is not a hashref.\n" unless $options and ref $options eq ref {};

    $options = { %{$options} };
    my $config_file = delete $options->{config};
    my $aliases;
    my $self = bless { config => $options }, $class;
    $self->{_command_sorter} = delete $self->{config}->{command_sort}
        if $self->{config}->{command_sort} && 'CODE' eq ref $self->{config}->{command_sort};
    if( defined $config_file )
    {
        die "Supplied config is not a file.\n" unless -f $config_file;
        $self->_initialize_config( $config_file );
    }
    $aliases = delete $self->{config}->{alias};
    $aliases = {} unless ref $aliases eq ref {};

    $commands = $self->_setup_commands( $commands );

    # TODO - replace the hard-coded Table module name with a parameter.
    my $table = App::CmdDispatch::Table->new( $commands, $aliases );
    if( $self->{_helper} )
    {
        $self->{_helper}->normalize_command_help( $table );
        $self->{_command_sorter} ||= ( ref $self->{_helper} )->can( "sort_commands" );
    }
    $self->{table} = $table;
    $self->_initialize_io_object();
    $self->{_command_sorter} ||= sub { return ( sort @_ ); };

    return $self;
}

sub get_config { return $_[0]->{config}; }

sub run
{
    my ( $self, $cmd, @args ) = @_;

    eval {
        $self->{table}->run( $self, $cmd, @args );
        1;
    } or do
    {
        my $ex = $@;
        if( ref( $ex ) =~ /\AApp::CmdDispatch::Exception/ )
        {
            $self->_print( $ex->why(), "\n" );
            $self->command_hint;
        }
        else
        {
            die $ex;
        }
    };
    return;
}

sub command_list
{
    my ( $self ) = @_;
    return $self->{_command_sorter}->( $self->{table}->command_list() );
}

sub command_hint
{
    my ( $self ) = @_;
    return $self->{_helper}->hint() if defined $self->{_helper};
    $self->_print( "Commands: ", join( ', ', $self->command_list() ), "\n" );
    return;
}

sub hint
{
    my ( $self, $arg ) = @_;
    eval {
        $self->run( 'hint', $arg );
        1;
    } or do
    {
        return $self->{_helper}->hint( $arg ) if defined $self->{_helper};
        $self->_print( "Commands: ", join( ', ', $self->command_list() ), "\n" );
    };
    return;
}

sub help
{
    my ( $self, $arg ) = @_;
    eval {
        $self->run( 'help', $arg );
        1;
    } or do
    {
        return $self->{_helper}->help( $arg ) if defined $self->{_helper};
        $self->_print( "Commands: ", join( ', ', $self->command_list() ), "\n" );
    };
    return;
}

sub alias_list { return $_[0]->{table}->alias_list(); }

sub shell
{
    my ( $self ) = @_;

    $self->_print( "Enter a command or 'quit' to exit:\n" );
    while ( my $line = $self->_prompt( '> ' ) )
    {
        chomp $line;
        next unless $line =~ /\S/;
        last if $line eq 'quit';
        $self->run( split /\s+/, $line );
    }
    return;
}

sub _print
{
    my $self = shift;
    return $self->{io}->print( @_ );
}

sub _prompt
{
    my $self = shift;
    return $self->{io}->prompt( @_ );
}

sub _initialize_config
{
    my ( $self, $config_file ) = @_;
    my $conf = Config::Tiny->read( $config_file );
    %{ $self->{config} } = (
        ( $conf->{_} ? %{ delete $conf->{_} } : () ),    # first extract the top level
        %{$conf},                # Keep any multi-levels that are not aliases
        %{ $self->{config} },    # Override with supplied parameters
    );
    return;
}

sub _initialize_io_object
{
    my ( $self ) = @_;

    my $io = delete $self->{config}->{'io'};
    if( !defined $io )
    {
        eval {
            $io = App::CmdDispatch::IO->new();
        } or do {
            $io = App::CmdDispatch::MinimalIO->new();
        };
        die "Unable to create an IO object for CmdDispatch.\n" unless defined $io;
    }
    elsif( !_is_valid_io_object( $io ) )
    {
        die "Object supplied as io parameter does not supply correct interface.\n";
    }

    $self->{io} = $io;
    return;
}

sub _is_valid_io_object
{
    my ( $io ) = @_;
    return unless ref $io;
    return 2 == grep { $io->can( $_ ) } qw/print prompt/;
}

sub _setup_commands
{
    my ( $self, $commands ) = @_;
    $commands = { %{$commands} };

    return $commands unless $self->{config}->{default_commands};

    foreach my $def ( split / /, $self->{config}->{default_commands} )
    {
        if( $def eq 'shell' )
        {
            $commands->{shell} = {
                code     => \&App::CmdDispatch::shell,
                clue     => 'shell',
                abstract => 'Launch an interactive command shell.',
                help     => 'Execute commands as entered until quit.',
            };
        }
        elsif( $def eq 'help' )
        {
            require App::CmdDispatch::Help;
            $self->{_helper} = App::CmdDispatch::Help->new( $self, $commands, $self->{config} );
        }
        else
        {
            die "Unrecognized default command: '$def'\n";
        }
    }
    return $commands;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::CmdDispatch - Handle command line processing for programs with subcommands

=head1 VERSION

This document describes C<App::CmdDispatch> version 0.44

=head1 SYNOPSIS

    use App::CmdDispatch;

    my %cmds = (
        start => {
            code => sub { my $app = shift; print "start: @_\n"; },
            clue => 'start [what]',
            abstract => 'Start something',
            help => 'Start whatever is to be run.',
        },
        stop => {
            code => sub { my $app = shift; print "stop @_\n"; },
            clue => 'stop [what]',
            abstract => 'Stop something',
            help => 'Stop whatever is to be run.',
        },
        stuff => {
            code => sub { my $app = shift; print "stuff: @_\n"; },
            clue => 'stuff [what]',
            abstract => 'Do stuff',
            help => 'Stuff to do.',
        },
        jump => {
            code => sub { my $app = shift; print "jump: @_\n"; },
            clue => 'jump [what]',
            abstract => 'Jump it',
            help => 'Jump the item requested to be jumped.',
        },
    );

    my $processor = App::CmdDispatch->new( \%cmds );
    $processor->run( @ARGV );

=head1 DESCRIPTION

One way to map a series of command strings to the code to execute for that
string is a dispatch table. The simplest dispatch table maps strings directly
to code refs. A more complicated dispatch table maps strings to objects that
provide a wider interface than just a single function call. I often find I want
more than a single function and less than a full object.

C<App::CmdDispatch> falls in between these two extremes. One thing I always
found that I needed with my dispatch table-driven scripts was decent help that
covered all of the commands. C<App::CmdDispatch> makes each command map to a
hash containing a code reference and some help strings.

Since beginning to use C<git>, I have found C<git>'s alias feature to be
extremely helpful. C<App::CmdDispatch> supports reading aliases from a config
file.

=head1 INTERFACE

=head2 new( $cmdhash, $options )

Create a new C<App::CmdDispatch> object. This method can take one or two
hashrefs as arguments.

=head3 The $cmdhash hash

The first is required and describes the commands.  The second is optional and
provides option information for the C<App::CmdDispatch> object. The keys of the
hash are the command names. Each value is a hash describing the command. The
entries in this description hash are dependent on which features are enabled.
The currently known keys are:

=over 4

=item code

This is the only required key. The value for the key must be a coderef that is
executed when the command is requested. The parameters for the command are a
reference to the C<App::CmdDispatch> object that contains the command and a
list of the parameters that were supplied to the command.

=item clue

This optional parameter provides a clue to the usage of the command. This would
normally be the command name and some indication of the possible parameters. It
is used when either the B<hint> or B<help> features of
L<App::CmdDispatch::Help> are invoked.

If the parameter is not supplied and either B<hint> or B<help> are invoked, the
name of the command is used by default.

=item abstract

This optional parameter gives a short (less than a line) explanation of the
command. The idea is to give a hint of the functionality to remind someone who
is mostly familiar with the commands.

When B<hint> is invoked, the C<abstract> is displayed on the same line as the
C<clue>.

If the parameter is not supplied and B<hint> is invoked, nothing is used by
default.

=item help

This optional parameter gives a fuller explanation of the command. It often
extends across several lines. The idea is to explain the functionality of the
command to someone that is not familiar with it.

When B<help> is invoked, the C<help> text is displayed after the line
containing the C<clue>.

If the parameter is not supplied and B<help> is invoked, nothing is used by
default.

=back

=head3 The $options hash

This hash determines some of the default behavior of the C<App::CmdDispatch>
object.

=over 4

=item config_file

This option is the name of a configuration file that is read using the format
specified in L<Config::Tiny>. This sets default configuration parameters and
aliases.

=item default_commands

This string provides a space separated list of default command behaviors.
The two supported behaviors are:

=over 4

=item help

Provide a B<help> command and a B<hint> command through the
L<App::CmdDispatch::Help> module.

=item shell

Prove a shell interface that loops asking for subcommands. Each command
is executed and contol returns to the loop.

=back

=item io

An object supplying input and output services for the CmdDispatcher. This
object must provide both a C<print> method and a C<prompt> method. See
L<App::CmdDispatch::IO> for more information on the interface.

=item help:*

The options beginning with the string 'help:' are described in the docs for
L<App::CmdDispatch::Help>.

=back

=head2 run( $cmd, @args )

This method looks up the supplied command and executes it.

=head2 command_hint( $cmd )

This method prints a short hint listing all commands and aliases or just the
hint for the supplied command.

=head2 hint( $cmd )

This method prints a short hint listing all commands and aliases or just the
hint for the supplied command.

=head2 help( $cmd )

This method prints help for the program or just help on the supplied command.

=head2 shell()

This method start a read/execute loop which supports running multiple commands
in the same execution of the main program.

=head2 get_config()

This method returns a reference to the configuration hash for the dispatcher.

=head2 command_list()

This method returns the list of commands in a defined order.

=head2 alias_list()

This method returns the list of aliases in sorted order.

=head1 CONFIGURATION AND ENVIRONMENT

C<App::CmdDispatch> can read a configuration file specified in a
L<Config::Tiny> supported format. Should be specified in the config parameter.

=head1 DEPENDENCIES

Config::Tiny
Term::Readline

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-cmddispatch@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

G. Wade Johnson  C<< <wade@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< <wade@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
