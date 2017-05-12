
package Class::Prevayler::CommandRecoverer;
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
      get_set       => [
        'deserializer',        'directory',
        'next_logfile_number', 'pending_commands',
        '_filehandle',
      ];

}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Class::Prevayler::CommandRecoverer - Prevayler implementation - www.prevayler.org


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

Class::Prevayler.

=cut

sub init {
    my $self   = shift;
    my %values = (@_);
    $self->hash_init(%values);
    ( $self->directory && $self->deserializer )
      or croak "need a directory and a deserializer!";
    return;
}

sub recover {
    my ( $self, $system ) = @_;

    while ( $self->_execute_next_command($system) ) { }
    return $system;
}

sub _execute_next_command {
    my ( $self, $system ) = @_;
    while (1) {
        unless ( $self->_filehandle ) {
            my $filename = $self->_find_next_command_file
              or return undef;
            my $filehandle;
            open( $filehandle, $filename )
              or croak "couldn't open file $filename " . ": $!";
            $self->_filehandle($filehandle);
        }
        my $cmd_obj = $self->_read_command( $self->_filehandle );
        unless ($cmd_obj) {
            close $self->_filehandle;
            $self->_filehandle(undef);
            $self->next_logfile_number( $self->next_logfile_number + 1 );
            next;
        }
        $self->_execute_cmd( $cmd_obj, $system );
        return 1;
    }
}

sub _execute_cmd {
    my ( $self, $cmd_obj, $system ) = @_;
    eval { $cmd_obj->execute($system); };
}

sub _read_command {
    my ( $self, $filehandle ) = @_;

    my $length = <$filehandle>;
    return undef unless $length;
    chomp($length);
    my $file = '';
    while ( length($file) < $length ) {
        $file .= <$filehandle>;
    }
    chomp($file);
    return $self->deserializer->($file);
}

sub _find_next_command_file {
    my ($self) = @_;

    unless ( $self->pending_commands ) {
        local (*DIRHANDLE);
        opendir DIRHANDLE, $self->directory()
          or croak "couldn't open directory " . $self->directory . ": $!";
        my @commands =
          grep {
            my ($number) = /(\d*)\.commandLog$/;
            defined $number && $number >= $self->next_logfile_number ? 1 : 0;
          } readdir DIRHANDLE;
        return undef unless scalar @commands;
        $self->pending_commands( [ sort @commands ] );
    }
    my $filename = shift @{ $self->pending_commands } or return undef;
    return File::Spec->catfile( $self->directory, $filename );
}

1;    #this line is important and will help the module return a true value
__END__

