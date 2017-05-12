
package Class::Prevayler::CommandLogger;
use strict;
use warnings;
use Carp;
use File::Spec;

use constant INSTANCE_DEFAULTS => (
    max_file_size => 680000000,    #cd-rom
    _file_length  => 0,
);

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
        'serializer',  'directory',     'number',      'file_counter',
        '_filehandle', 'max_file_size', '_file_length',
      ];
}

########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Class::Prevayler::CommandLogger - Prevayler implementation - www.prevayler.org

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
    my $self = shift;
    my %values = ( INSTANCE_DEFAULTS, @_ );
    $self->hash_init(%values);
    ( $self->directory && $self->serializer )
      or croak "need a directory and a serializer!";
    return;
}

sub write_command {
    my ( $self, $cmd_obj ) = @_;
    my $serialized = $self->serializer->($cmd_obj);
    my $length     = length($serialized);
    if ( $self->_file_length + $length > $self->max_file_size
        or not defined( $self->_filehandle ) )
    {
        close $self->_filehandle
          if defined $self->_filehandle;
        $self->_file_length(0);
        my $filehandle;
        open $filehandle, '>>'
          . File::Spec->catfile( $self->directory,
            sprintf( '%016d', $self->file_counter->reserve_number_for_command )
              . '.commandLog' )
          or croak "couldn't open file: $!";
        $self->_filehandle($filehandle);
    }
    $self->_file_length( $self->_file_length + $length + length($length) + 2 );
    my $filehandle = $self->_filehandle;
    print $filehandle $length . "\n" . $serialized . "\n";
}

1;    #this line is important and will help the module return a true value
__END__

