######################################################################
# $Id: YAMLBackend.pm,v 1.3 2005/10/27 19:00:20 nachbaur Exp $
# Copyright (C) 2005 Michael Nachbaur  All Rights Reserved
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either expressed or
# implied. See the License for the specific language governing
# rights and limitations under the License.
######################################################################

package Cache::YAMLBackend;

use strict;
use vars qw( @ISA );
use Cache::CacheUtils qw( Assert_Defined Build_Path );
use YAML;

@ISA = qw( Cache::FileBackend );

sub _read_data {
    my $self = shift;
    my ($p_path) = @_;

    Assert_Defined($p_path);

    my $frozen_data_ref = Cache::FileBackend::_Read_File_Without_Time_Modification($p_path) or
        return [ undef, undef ];

    my $data_ref = eval { 
        $self->_yaml->load($$frozen_data_ref);
    };
  
    if ($@ || (ref($data_ref) ne 'ARRAY')) {
        unlink Cache::FileBackend::_Untaint_Path($p_path);
        return [undef, undef];
    } else {
        return $data_ref;
    }
}

sub store {
    my $self = shift;
    return $self->SUPER::store(@_);
}

sub _write_data {
    my $self = shift;
    my ($self, $p_path, $p_data) = @_;

    Assert_Defined($p_path);
    Assert_Defined($p_data);

    Cache::FileBackend::_Make_Path($p_path, $self->get_directory_umask());

    my $frozen_file = $self->_yaml->dump($p_data);

    Cache::FileBackend::_Write_File($p_path, \$frozen_file);
}

sub _yaml {
    my $self = shift;
    my $y = YAML->new;
    return $y;
}

1;

__END__

=pod

=head1 NAME

Cache::YAMLBackend -- a filesystem based YAML persistance mechanism

=head1 DESCRIPTION

The YAMLBackend class is used to persist data to the filesystem as YAML,
based on Cache::FileBackend.

=head1 SYNOPSIS

  my $backend = new Cache::YAMLBackend( '/tmp/FileCache', 3, 000 );

  See Cache::FileBackend for the usage synopsis.

  $backend->store( 'namespace', 'foo', 'bar' );

  my $bar = $backend->restore( 'namespace', 'foo' );

  my $size_of_bar = $backend->get_size( 'namespace', 'foo' );

  foreach my $key ( $backend->get_keys( 'namespace' ) )
  {
    $backend->delete_key( 'namespace', $key );
  }

  foreach my $namespace ( $backend->get_namespaces( ) )
  {
    $backend->delete_namespace( $namespace );
  }

See Cache::FileBackend for the API documentation.

=head1 SEE ALSO

Cache::Backend, Cache::FileBackend

=head1 AUTHOR

Original author: Michael Nachbaur <mike@nachbaur.com>

Last author:     $Author: nachbaur $

Copyright (C) 2005 Michael Nachbaur

=cut
