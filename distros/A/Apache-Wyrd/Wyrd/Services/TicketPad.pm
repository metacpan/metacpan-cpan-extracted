use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::TicketPad;
our $VERSION = '0.98';
use BerkeleyDB;
use BerkeleyDB::Btree;

=pod

=head1 NAME

Apache::Wyrd::Services::TicketPad - Key storage for LoginServer Service

=head1 SYNOPSIS

	use Apache::Wyrd::Services::TicketPad;
	my $pad = Apache::Wyrd::Services::TicketPad->new($ticketfile, 5);
	my $key = 'Swordfish';
	my $ticket = join ('', qw(
		5261306521af6ea42a9c19060e1dc1258791d4c1f6ac
		9be773c5e454b1679171f2ddf35967a5b4bad255e9c8
		e8c98444d3790c3793a826b6460087cbaaf32036a19b
		526236eb07931ea055808f047d81f6afae38ffabb720
	));
	$pad->add_ticket($ticket, $key);
	$key = $pad->find($ticket);

=head1 DESCRIPTION

NONE

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Services::TicketFile) C<new> (scalar, scalar)

Accepts a filename for the file which will hold the ticket pad and the number of
tickets the pad should keep (default 100).  Returns the TicketPad object.

=cut

sub new {
	my ($class, $file, $tickets) = @_;
	$file || die ('You need to define a file for the ticketpad.');
	$tickets ||= 100;
	my $self = {
		indexfile => $file,
		tickets => $tickets
	};
	bless $self, $class;
	my $cr = Apache::Wyrd::Services::CodeRing->new;
	tie (my %pad, 'BerkeleyDB::Btree',
		-Filename => $self->{'indexfile'},
		-Flags => DB_CREATE,
		-Env => $self->_berkeley_environment,
		-Mode => 0600) || die('Could not tie to index file ' . $self->{'indexfile'} . ' -- write operation');
	my $challenge_key = 'I am he against whom no lock may hold nor fastened portal bar';
	$challenge_key = ${$cr->encrypt(\$challenge_key)};
	unless ($pad{'key'} eq $challenge_key) {
		warn('key is stale.  Flushing key cache and clearing tickets.');
		for (my $i = $tickets; $i > 0; $i--) {
			$pad{$i} = undef;
		}
		$pad{'key'} = $challenge_key;
	}
	untie(%pad);
	$self->{'cr'} = $cr;
	return $self;
}

=item (void) C<add_ticket> (scalar, scalar)

Accepts a key and a value for an entry (ticket) in the ticket pad. 
Discards the oldest ticket if this would raise the size of the pad
beyond capacity.

=cut

sub add_ticket {
	#think key, value not ticket, key
	my ($self, $key, $value) = @_;
	tie (my %pad, 'BerkeleyDB::Btree',
		-Filename => $self->{'indexfile'},
		-Flags => DB_CREATE,
		-Env => $self->_berkeley_environment,
		-Mode => 0660) || die('Could not tie to index file -- write operation');
	for (my $i = ($self->{'tickets'} - 1); $i > 0; $i--) {
		$pad{$i} = $pad{$i - 1};
	}
	$value = ${$self->{'cr'}->encrypt(\$value)};
	$pad{'0'} = "$key:$value";
	untie(%pad);
}

=item (scalar) C<add_ticket> (scalar)

Accepts a key and returns the value of the ticket under that key. 
Returns the empty string if the ticket cannot be found.

=cut

sub find {
	my ($self, $key) = @_;
	my $return_value = undef;
	tie (my %pad, 'BerkeleyDB::Btree',
		-Filename => $self->{'indexfile'},
		-Flags => DB_RDONLY,
		-Env => $self->_berkeley_environment,
		-Mode => 0660) || die('Could not tie to index file -- read operation');
	for (my $i = 0; $i < 100; $i++) {
		if ($pad{$i} =~ /^$key/) {
			my (undef, $ticket) = split(':', $pad{$i});
			untie(%pad);
			$return_value = ${$self->{'cr'}->decrypt(\$ticket)};
		}
		last if ($return_value);
	}
	untie(%pad);
	return $return_value;
}

=pod

=back

=head1 BUGS/CAVEATS/RESERVED METHODS

Will fail if the Apache process cannot create a file unreadable by group
or other.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd::Services::Auth

Authorization handler

=item Apache::Wyrd::Services::LoginServer

Perl Handler for login services.

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub _berkeley_environment {
	my ($self) = @_;
	my $directory = $self->{'indexfile'};
	$directory =~ s#(.+/).*$#$1#;
	$directory = '/tmp' unless ($directory);
	return BerkeleyDB::Env->new(
		-Home			=> $directory,
		-Flags			=> DB_INIT_LOCK | DB_INIT_LOG | DB_INIT_MPOOL,
		-LockDetect		=> DB_LOCK_DEFAULT
	);
}

1;
