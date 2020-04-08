package App::CmdDispatch::Help;

use warnings;
use strict;

our $VERSION = '0.44';

sub new
{
    my ( $class, $owner, $commands, $config ) = @_;
    $config ||= {};
    die "Command definition is not a hashref.\n" unless ref $commands eq ref {};
    die "No commands specified.\n"               unless keys %{$commands};
    die "Config parameter is not a hashref.\n"   unless ref $config   eq ref {};
    die "Invalid owner object.\n" unless eval { $owner->isa( 'App::CmdDispatch' ); };
    _extend_table_with_help( $commands );
    my %conf = (
        indent_hint => '  ',
        indent_help => '        ',
        _extract_config_parm( $config, 'indent_hint' ),
        _extract_config_parm( $config, 'pre_hint' ),
        _extract_config_parm( $config, 'post_hint' ),
        _extract_config_parm( $config, 'indent_help' ),
        _extract_config_parm( $config, 'pre_help' ),
        _extract_config_parm( $config, 'post_help' ),
        alias_len   => 1,
    );
    return bless { owner => $owner, %conf }, $class;
}

sub _extract_config_parm
{
    my ( $config, $parm ) = @_;
    return unless defined $config->{"help:$parm"};
    return ( $parm => $config->{"help:$parm"} );
}

sub _extend_table_with_help
{
    my ( $commands ) = @_;
    $commands->{help} = {
        code     => \&_dispatch_help,
        clue     => "help [command|alias]",
        abstract => 'Display complete help',
        help     => "Display help about commands and/or aliases. Limit display with the\nargument.",
    };
    $commands->{hint} = {
        code     => \&_dispatch_hint,
        clue     => "hint [command|alias]",
        abstract => 'Display command hints',
        help     => 'A list of commands and/or aliases. Limit display with the argument.',
    };
    return;
}

sub _dispatch_help
{
    my $owner = shift;
    return $owner->{_helper}->help( @_ );
}

sub _dispatch_hint
{
    my $owner = shift;
    return $owner->{_helper}->hint( @_ );
}

sub _hint_string
{
    my ( $self, $cmd, $maxlen ) = @_;
    my $desc = $self->_table->get_command( $cmd );
    return '' unless $desc;
    my $indent = ( $maxlen ? ' ' x ( 3 + $maxlen - length $desc->{clue} ) : '   ' );
    return $desc->{clue} . ( $desc->{abstract} ? $indent . $desc->{abstract} : '' );
}

sub _clue_string
{
    my ( $self, $cmd ) = @_;
    my $desc = $self->_table->get_command( $cmd );
    return '' unless $desc;
    return $desc->{clue};
}

sub _alias_hint
{
    my ($self, $alias) = @_;
    return sprintf "%-$self->{alias_len}s : %s", $alias, $self->_table->get_alias( $alias );
}

sub _help_string
{
    my ( $self, $cmd ) = @_;
    my $desc = $self->_table->get_command( $cmd );

    return '' unless defined $desc->{help};
    return join( "\n", map { $self->{indent_help} . $_ } split /\n/, $desc->{help} );
}

sub _list_command
{
    my ( $self, $code ) = @_;
    $self->_print( "\nCommands:\n" );
    foreach my $c ( $self->{owner}->command_list() )
    {
        # The following should not be possible. But I'll keep this until
        # I'm absolutely certain.
        next if $c eq '' or !$self->_table->get_command( $c );
        $self->_print( $code->( $c ) );
    }
    return;
}

sub _find_longest_alias
{
    my ( $self ) = @_;
    my $len;
    foreach my $c ( $self->{owner}->alias_list() )
    {
        $len = length $c;
        $self->{alias_len} = $len if $len > $self->{alias_len};
    }
    return;
}

sub _list_aliases
{
    my ( $self ) = @_;
    return unless $self->_table->has_aliases;

    $self->_find_longest_alias();
    $self->_print( "\nAliases:\n" );
    foreach my $c ( $self->{owner}->alias_list() )
    {
        $self->_print( $self->{indent_hint} . $self->_alias_hint( $c ) . "\n" );
    }
    return;
}

sub _is_missing { return !defined $_[0] || $_[0] eq ''; }

sub _get_abstract_offset
{
    my ( $self ) = @_;

    my $maxlen = 0;
    my $len;
    foreach my $cmd ( $self->_table->command_list() )
    {
        $len = length $self->_table->get_command( $cmd )->{clue};
        $maxlen = $len if $len > $maxlen;
    }
    return $maxlen;
}

sub hint
{
    my ( $self, $arg ) = @_;

    if( _is_missing( $arg ) )
    {
        my $maxlen = $self->_get_abstract_offset();
        $self->_print( "\n$self->{pre_hint}\n" ) if $self->{pre_hint};
        $self->_list_command(
            sub { $self->{indent_hint}, $self->_hint_string( $_[0], $maxlen ), "\n"; } );
        $self->_list_aliases();
        $self->_print( "\n$self->{post_hint}\n" ) if $self->{post_hint};
        return;
    }

    if( $self->_table->get_command( $arg ) )
    {
        $self->_print( "\n", $self->_hint_string( $arg ), "\n" );
    }
    elsif( $self->_table->get_alias( $arg ) )
    {
        $self->_print( "\n", $self->_alias_hint( $arg ), "\n" );
    }
    elsif( $arg eq 'commands' )
    {
        my $maxlen = $self->_get_abstract_offset();
        $self->_list_command( sub { $self->{indent_hint}, $self->_hint_string( $_[0], $maxlen ), "\n"; } );
    }
    elsif( $arg eq 'aliases' )
    {
        $self->_list_aliases();
    }
    else
    {
        $self->_print( "Unrecognized command '$arg'\n" );
    }

    return;
}

sub help
{
    my ( $self, $arg ) = @_;

    if( _is_missing( $arg ) )
    {
        $self->_print( "\n$self->{pre_help}\n" ) if $self->{pre_help};
        $self->_list_command(
            sub {
                $self->{indent_hint}, $self->_clue_string( $_[0] ), "\n",
                    $self->_help_string( $_[0] ), "\n";
            }
        );
        $self->_list_aliases();
        $self->_print( "\n$self->{post_help}\n" ) if $self->{post_help};
        return;
    }

    if( $self->_table->get_command( $arg ) )
    {
        $self->_print( "\n", $self->_clue_string( $arg ),
            "\n", ( $self->_help_string( $arg ) || $self->{indent_help} . "No help for '$arg'" ),
            "\n" );
    }
    elsif( $self->_table->get_alias( $arg ) )
    {
        $self->_print( "\n", $self->_alias_hint( $arg ), "\n" );
    }
    elsif( $arg eq 'commands' )
    {
        $self->_list_command(
            sub {
                $self->{indent_hint}, $self->_clue_string( $_[0] ), "\n",
                    $self->_help_string( $_[0] ), "\n";
            }
        );
    }
    elsif( $arg eq 'aliases' )
    {
        $self->_list_aliases();
    }
    else
    {
        $self->_print( "Unrecognized command '$arg'\n" );
    }

    return;
}

sub normalize_command_help
{
    my ( $self, $table ) = @_;
    foreach my $cmd ( $table->command_list )
    {
        my $desc = $table->get_command( $cmd );
        $desc->{clue} = $cmd unless defined $desc->{clue};
        $desc->{hint} = ''   unless defined $desc->{hint};
        $desc->{help} = ''   unless defined $desc->{help};
    }
    return;
}

sub sort_commands
{
    return ( sort grep { $_ ne 'hint' && $_ ne 'help' } @_ ), 'hint', 'help';
}

sub _print
{
    my ( $self ) = shift;
    return $self->{owner}->_print( @_ );
}

sub _table { return $_[0]->{owner}->{table}; }

1;
__END__

=encoding utf-8

=head1 NAME

App::CmdDispatch::Help - Provide help functionality for the CmdDispatch module

=head1 VERSION

This document describes App::CmdDispatch::Help version 0.44

=head1 SYNOPSIS

    use App::CmdDispatch::Help;

This module is mostly loaded directly by the App::CmdDispatch module when
needed. At present, there are very few reasons for someone to use it directly.

=head1 DESCRIPTION

This module encapsulates the help/hint system for the L<App::CmdDispatch>
module.

=head1 INTERFACE

=head2 App::CmdDispatch::Help->new( $dispatch, $command, $config )

Construct a new object of type C<App::CmdDispatch::Help>. This object can
handle the normal help and hint functionality of the commands in the dispatch
table.

The first parameter is a reference to the L<App::CmdDispatch> object that
contains this Help object. It is used to access the command table and the IO
functionality.

The second parameter is the command hash at the time of creation. In order to
provide appropiate help, the command hash should have a few extra pieces of
information associated with each command. The following keys are extracted
from the description hash of each command.

=over 4

=item clue

This text is a short blurb showing the format of the command.

=item help

This text is a longer piece of text that describes the commands parameters and
functionality.

=back

The third parameter is the configuration hash. This contains some values that
modify the functionality of the help system. The keys of interest are

=over 4

=item help:indent_hint

This string is prepended to the hint for each command. The default value is
2 spaces.

=item help:pre_hint

This string contains text that is displayed before the list of command hints
if the hints for all commands are requested. The default value is empty.

=item help:post_hint

This string contains text that is displayed after the list of command and
alias hints if the hints for all commands and aliases are requested. The
default value is empty.

=item help:indent_help

This string is prepended to the hint for each command. The default value is
8 spaces.

=item help:pre_help

This string contains text that is displayed before the list of command help
if the help for all commands are requested. The default value is empty.

=item help:post_help

This string contains text that is displayed after the list of command and
alias help if the help for all commands and aliases are requested. The
default value is empty.

=back

=head2 hint( $dispatch, $cmd )

This method prints a short hint listing all commands and aliases or just the
hint for the supplied command.

=head2 help( $dispatch, $cmd )

This method prints help for the program or just help on the supplied command.

=head2 normalize_command_help( $table )

This method takes a hash of commands and fills in whatever help/hint
information that it can for the information that is available. Although not
perfect, it does ensure that there is some information for every command.

=head2 sort_commands( @cmds )

This subroutine sorts the list of commands. The resulting list contains all of
the commands except B<help> and B<hint> in sorted order, followed by B<hint>
then B<help>.

=head1 CONFIGURATION AND ENVIRONMENT

C<App::CmdDispatch::Help> requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< wade@anomaly.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, G. Wade Johnson C<< wade@anomaly.org >>. All rights reserved.

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

