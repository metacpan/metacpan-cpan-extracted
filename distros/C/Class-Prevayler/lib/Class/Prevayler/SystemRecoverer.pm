
package Class::Prevayler::SystemRecoverer;
use Class::Prevayler::CommandRecoverer;
use strict;
use warnings;
use Carp;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = 0.02;
    @ISA     = qw (Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();

    use Class::MethodMaker
      new_with_init => 'new',
      new_hash_init => 'hash_init',
      get_set       => [ 'deserializer', 'directory', 'next_logfile_number', ];
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Class::Prevayler::SystemRecoverer - Prevayler implementation - www.prevayler.org

=head1 DESCRIPTION

this class is an internal part of the Class::Prevayler module.

=head1 AUTHOR

	Nathanael Obermayer
	CPAN ID: nathanael
	natom-pause@smi2le.net
	http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

Class::Prevayler

=cut

sub init {
    my $self   = shift;
    my %values = (@_);
    $self->hash_init(%values);
    ( $self->directory && $self->deserializer )
      or croak "need a directory and a deserializer!";
    return;
}

sub _read_system {
    my ( $self, $filename ) = @_;
    my $filehandle;
    open $filehandle, $filename
      or croak "couldn't open $filename : $!";
    my $file;
    while (<$filehandle>) {
        $file .= $_;
    }
    close $filehandle
      or croak "couldn't close $filename : $!";

    return $self->deserializer()->($file);
}

sub _find_last_snapshot_file {
    my $self = shift;

    local (*DIRHANDLE);
    opendir DIRHANDLE, $self->directory()
      or croak "couldn't open directory " . $self->directory . ": $!";
    my @snapshots = grep /\.snapshot$/, readdir DIRHANDLE;
    return undef unless scalar @snapshots;
    my @sorted_snapshots = sort @snapshots;

    return File::Spec->catfile( $self->directory, $sorted_snapshots[-1] );
}

sub _recover_snapshot {
    my ( $self, $virgin_system ) = @_;
    my $snapshot_file = $self->_find_last_snapshot_file();
    my $system;
    if ($snapshot_file) {
        $system = $self->_read_system($snapshot_file);
        $self->next_logfile_number( $self->_number($snapshot_file) + 1 );
    }
    else {
        $system = $virgin_system;
        $self->next_logfile_number(1);
    }
    return $system;
}

sub recover {
    my ( $self, $virgin_system ) = @_;
    my $system = $self->_recover_snapshot($virgin_system);
    return $self->_recover_commands($system);
}

sub _number {
    my ( $self, $filename ) = @_;

    my ($number) = $filename =~ /(\d*)\.snapshot/;
    return $number;
}

sub _recover_commands {
    my ( $self, $system ) = @_;

    my $cmd_recoverer = Class::Prevayler::CommandRecoverer->new(
        directory           => $self->directory,
        deserializer        => $self->deserializer,
        next_logfile_number => $self->next_logfile_number,
    );
    my $updated_system = $cmd_recoverer->recover($system);
    $self->next_logfile_number( $cmd_recoverer->next_logfile_number() );
    return $updated_system;
}

1;    #this line is important and will help the module return a true value
__END__

