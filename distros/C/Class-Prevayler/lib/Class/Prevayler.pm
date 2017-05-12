
package Class::Prevayler;
use strict;
use warnings;
use File::Sync qw(fsync sync);
use File::Spec;
use Data::Dumper;
use Carp;
use Class::Prevayler::SystemRecoverer;
use Class::Prevayler::CommandLogger;
use Class::Prevayler::FileCounter;

use constant INSTANCE_DEFAULTS => (
    sync_after_write => 1,
    directory        => './',
    serializer       => sub {
        local ( $Data::Dumper::Indent = 0 );
        local ( $Data::Dumper::Purity = 1 );
        return Data::Dumper->Dump( [ $_[0] ], ['dumped'] );
    },
    deserializer => sub {
        my $dumped;
        eval $_[0];
        return $dumped;
    },
);

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = 0.02;
    @ISA         = qw (Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();

    use Class::MethodMaker
      new_with_init => 'new',
      new_hash_init => 'hash_init',
      get_set       => [
        'sync_after_write',  'directory',
        'serializer',        'deserializer',
        'system',            '_started',
        '_system_recoverer', '_command_logger',
        '_file_counter',
      ];
}

=head1 NAME

Class::Prevayler - Prevayler implementation - www.prevayler.org

=head1 SYNOPSIS

  use Class::Prevayler;

  my $prevayler = Class::Prevayler->new(
			system		=> new Your::System,
			directory 	=> 'prevayler/demo/'
		);

  $prevayler->start();

  my $cmd_obj = Your::Command::Object->new();

  $prevayler->execute( $cmd_obj );

  $prevayler->take_snapshot();

=head1 DESCRIPTION

THIS IS BETA-SOFTWARE!!

Class::Prevayler - aka 'Perlvayler' - is a Perl implementation of the prevayler concept.

You can find an introduction to this concept on www.prevayler.org.

This module overloads the 'time', 'localtime' and 'gmtime' functions to make the system deterministic.

=head1 USAGE


=head2 new

 Usage     : $prevayler->new()
 Purpose   : creates a new object 
 Returns   : the new prevayler-object
 Argument  : you can use key-value pairs to initialize the attributes

=cut

sub init {
    my $self = shift;
    my %values = ( INSTANCE_DEFAULTS, @_ );
    $self->hash_init(%values);
    return;
}

=head2 start

 Usage     : $prevayler->start()
 Purpose   : recovers the old system state
 Returns   : nothing
 Argument  : none
 Comments  : You have to call it before you can use execute(), even if there is no old serialized state

=cut

sub start {
    my $self = shift;
    $self->_system_recoverer()
      || $self->_system_recoverer(
        Class::Prevayler::SystemRecoverer->new(
            directory    => $self->directory(),
            deserializer => $self->deserializer(),
        )
      );

    my $system = $self->_system_recoverer()->recover( $self->system );

    # TODO: create dir if needed

    $self->_file_counter(
        Class::Prevayler::FileCounter->new(
            next_logfile_number => $self->_system_recoverer->next_logfile_number
        )
    );

    $self->system($system);
    $self->_command_logger()
      || $self->_command_logger(
        Class::Prevayler::CommandLogger->new(
            directory    => $self->directory(),
            serializer   => $self->serializer(),
            file_counter => $self->_file_counter(),
        )
      );
    $self->_started(1);
}

sub execute {
=head2 start

 Usage     : $prevayler->execute()
 Purpose   : execute one command object on the system, and log it
 Returns   : nothing
 Argument  : command object
 Comments  : all command objects must implement a 'execute()' method

=cut
    my ( $self, $cmd_obj ) = @_;
    croak "call start() first\n" unless ( $self->_started() );
    my $cmd_obj_clock_recovery =
      Class::Prevayler::ClockRecoveryCommand->new($cmd_obj);
    $self->_command_logger->write_command($cmd_obj_clock_recovery);
    $self->_execute_cmd($cmd_obj_clock_recovery);

    return 1;
}

sub _execute_cmd {
    my ( $self, $cmd_obj ) = @_;
    $cmd_obj->execute( $self->system() );
}

=head2 take_snapshot

 Usage     : $prevayler->take_snapshot()
 Purpose   : produce a serialized image of the system 
 Returns   : nothing
 Argument  : command object
 Comments  : all command objects must implement a 'execute()' method

=cut
sub take_snapshot {
    my ($self) = @_;
    my $filename = File::Spec->catfile( $self->directory,
        sprintf( '%016d', $self->_file_counter->reserve_number_for_snapshot )
          . '.snapshot' );
    local (*FILEHANDLE);
    open( FILEHANDLE, ">$filename" )
      and print FILEHANDLE $self->serializer()->( $self->system() )
      or croak "Couldn't write file $filename : $!";
    ( $self->sync_after_write() && fsync(*FILEHANDLE) && sync() );
    close FILEHANDLE
      or croak "Couldn't close file $filename : $!";
    return;
}


1;    #this line is important and will help the module return a true value

=head2 system

 Usage     : 	$prevayler->system( new My::System )
		my $system = $prevayler->system();
 Purpose   : access to the prevalent system 
 Returns   : returns the actual system if called without argument
 Argument  : new prevalent system


=head2 directory

 Usage     : 	$prevayler->directory( './prevayler/' )
		my $directory = $prevayler->directory();
 Purpose   : sets the directory where all serialized objects are stored 
 Returns   : returns the actual directory if called without argument
 Argument  : new directory


=head2 serializer

 Usage     : 	$prevayler->serializer( \&mySerializer )
		my $serializer = $prevayler->serializer();
 Purpose   : define the serializer. 
		The serializer is called with a structure (an object)
		and returns a string representation of this structure.
		The default serializer is implemented with Data::Dumper.
 Returns   : returns the actual serializer if called without argument
 Argument  : reference to a subroutine

=head2 deserializer

 Usage     : 	$prevayler->deserializer( \&myDeSerializer )
		my $deserializer = $prevayler->deserializer();
 Purpose   : define the deserializer. 
		The deserializer is called with a serialized structure
		and returns this structure.
		The default deserializer is implemented with eval.
 Returns   : returns the actual deserializer if called without argument
 Argument  : reference to a subroutine

=head1 BUGS

- none known, but: this is beta-software, there will be API and fileformat changes.


=head1 AUTHOR

	Nathanael Obermayer
	CPAN ID: nathanael
	natom-pause@smi2le.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

http://www.prevayler.org

=cut

#=head2 sync_after_write
#
# Usage     : 	$prevayler->sync_after_write( 1 )
#		my $sync_state = $prevayler->sync_after_write();
# Purpose   : switches syncing on or off... trade security for speed 
# Returns   : returns the actual state if called without argument
# Argument  : new state ( a false or true value )
#
#
package Class::Prevayler::ClockRecoveryCommand;

BEGIN {
    use Class::MethodMaker get_set => [ '_cmd_obj', '_time', ];
    *CORE::GLOBAL::time =
      \&Class::Prevayler::ClockRecoveryCommand::_prevayler_time;
    *CORE::GLOBAL::localtime =
      \&Class::Prevayler::ClockRecoveryCommand::_prevayler_localtime;
    *CORE::GLOBAL::gmtime =
      \&Class::Prevayler::ClockRecoveryCommand::_prevayler_gmtime;
}

sub new {
    my ( $pkg, $cmd_obj ) = @_;
    my $self = bless( {}, $pkg );

    $self->_cmd_obj($cmd_obj);

    # store the time
    $self->_time(CORE::time);

    return $self;
}

sub execute {
    my ( $self, $system ) = @_;
    $self->_freeze_time;
    $self->_cmd_obj()->execute($system);
    $self->_thaw_time;
}

sub _freeze_time {
    my $self = shift;
    $Class::Prevayler::ClockRecoveryCommand::time_frozen = 1;
    $Class::Prevayler::ClockRecoveryCommand::time        = $self->_time;
}

sub _thaw_time {
    undef $Class::Prevayler::ClockRecoveryCommand::time;
    $Class::Prevayler::ClockRecoveryCommand::time_frozen = 0;
}

sub _prevayler_time {
    $Class::Prevayler::ClockRecoveryCommand::time_frozen
      ? $Class::Prevayler::ClockRecoveryCommand::time
      : CORE::time;
}

sub _prevayler_localtime {
    wantarray
      ? ( CORE::localtime( time() ) )
      : scalar CORE::localtime( time() );
}

sub _prevayler_gmtime {
    wantarray
      ? ( CORE::gmtime( time() ) )
      : scalar CORE::gmtime( time() );
}
1;
__END__
