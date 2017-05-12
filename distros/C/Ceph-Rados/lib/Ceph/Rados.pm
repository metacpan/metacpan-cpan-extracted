package Ceph::Rados;

use 5.014002;
use strict;
use warnings;
use Carp;

use Ceph::Rados::IO;

our @ISA = qw();

our $VERSION = '0.06';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Ceph::Rados::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Ceph::Rados', $VERSION);

# Preloaded methods go here.

sub new {
    my ($class, $id, %args) = @_;
    my $obj = create($id);
    bless $obj, $class;

    while( my ($key, $value) = each %args ) {
        my $method = "set_${key}";
        if( $obj->can($method) ) {
            $obj->$method($value);
        } else {
            Carp::carp "Invalid setting '$key'";
        }
    }
    return $obj;
}

sub io {
    my ($self, $pool_name) = @_;
    croak "usage: ->io(pool_name)" unless defined $pool_name;
    Ceph::Rados::IO->new($self, $pool_name);
}

sub DESTROY {
    my $self = shift;
    $self->shutdown;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ceph::Rados - Perl wrapper to librados.

=head1 SYNOPSIS

  use Ceph::Rados;

  my $cluster = Ceph::Rados->new('admin');
  $cluster->set_config_file;
  $cluster->set_config_option( keyring => '/etc/ceph/ceph.client.admin.keyring');
  $cluster->connect;

  my $io = $cluster->io('testing_pool');
  $io->write('greeting', 'hello');
  my $stored_data = $io->read('greeting',10);
  my ($len, $mtime) = $io->stat('greeting');
  $io->delete('greeting');

  my $list = $io->list;
  while (my $entry = $list->next) {
      print "Found $entry\n";
  }

=head1 DESCRIPTION

This module provides a very limited subset of the librados API,
currently just read/write/stat and lists.

If no length is passed to the read() call, the object is first stat'd
to determine the correct read length.

=head1 SEE ALSO

librados documentation - L<http://ceph.com/docs/master/rados/api/librados/>

=head1 AUTHOR

Alex Bowley, E<lt>alex@openimp.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Alex Bowley.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
