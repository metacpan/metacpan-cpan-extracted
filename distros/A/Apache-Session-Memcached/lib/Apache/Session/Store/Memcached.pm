package Apache::Session::Store::Memcached;

use Cache::Memcached;
use strict;
use vars qw($VERSION);
$VERSION = '0.03';

sub new {
	my($class,$session) = @_;
	my $self;

	my %opts = (
		servers => ( ref $session->{args}->{Servers} eq 'ARRAY' ) 
			? $session->{args}->{Servers} : [ split(/\s+/,$session->{args}->{Servers}) ],
		no_rehash => $session->{args}->{NoRehash},
		readonly => $session->{args}->{ReadOnly},
		debug => $session->{args}->{Debug},
		compress_threshold => $session->{args}->{CompressThreshold} || 10_000,
	);

	#use Data::Dumper;
	#print STDERR Dumper $session->{args};

	my $memd = new Cache::Memcached \%opts;
	$self->{cache} = $memd;
	bless $self,$class;
}

sub insert {
	my($self,$session) = @_;
	if ( $self->{cache}->get($session->{data}->{_session_id}) ) {
		die "Object already exists in the data store.";
	}
	$self->{cache}->set($session->{data}->{_session_id},$session->{serialized});
}

sub update {
	my($self,$session) = @_;
	$self->{cache}->replace($session->{data}->{_session_id},$session->{serialized});
}

sub materialize {
	my($self, $session) = @_;
	$session->{serialized} = $self->{cache}->get($session->{data}->{_session_id}) or die 'Object does not exist in data store.';
}

sub remove {
    my($self, $session) = @_;
    $self->{cache}->delete($session->{data}->{_session_id});
}

1;
__END__

=head1 NAME

Apache::Session::Store::Memcached - Stores persistent data using memcached
(memory cache daemon) for Apache::Session storage

=head1 SYNOPSIS

   tie %session, 'Apache::Session::Memcached', $sid, {
      Servers => '10.0.0.1:20000 10.0.0.2:20000',
      NoRehash => 1,
      Readonly => 0,
      Debug => 1,
      CompressThreshold => 10_000
   };

   # use with another locking/generation/serializaion scheme

   use Apache::Session::Flex;

   tie %session, 'Apache::Session::Flex', $id, {
      Store     => 'Memcached',
      Lock      => 'Null',
      Generate  => 'MD5',
      Serialize => 'Storable',
      Servers => '10.0.0.1:20000 10.0.0.2:20000',
   };

=head1 DESCRIPTION

Apache::Session::Store::Memcached implements the storage interface for
Apache::Session using Cache::Memcached frontend to memcached.

=head1 CONFIGURATIONS

This module wants to know standard options for Cache::Memcached. You can
specify these options as Apache::Session's tie options like this:

   tie %session, 'Apache::Session::Memcached', $sid, {
      Servers => '10.0.0.1:20000 10.0.0.2:20000',
      Debug => 1
   };

Note that spelling of options are slightly different from those for
Cache::Memcached.

'Servers', 'NoRehash', 'Readonly', 'Debug' and 'CompressThreshold' are the
corrispondant to 'servers', 'no_rehash', 'readonly', 'debug' and
'compress_threshold' Cache::Memcached parameters.

In addition 'Server' can be either a scalar of the form 'IP:port IP:port ...',
either an arrayref of hosts (as required by Cache::Memcached).

See L<Cache::Memcached> for details.

=head1 SEE ALSO

L<Apache::Session|Apache::Session>,
L<Apache::Session::Flex|Apache::Session::Flex>,
L<Cache::Memcached|Cache::Memcached>, L<memcached>.

=head1 AUTHOR

Enrico Sorcinelli E<lt>enrico at sorcinelliE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
