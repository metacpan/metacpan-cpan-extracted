package Biblio::RFID::Reader;

use warnings;
use strict;

use Data::Dump qw(dump);
use Time::HiRes;
use lib 'lib';
use Biblio::RFID;
use Carp qw(confess);

=head1 NAME

Biblio::RFID::Reader - simple way to write RFID applications in perl

=head1 DESCRIPTION

This module will probe all available readers and use calls from
L<Biblio::RFID::Reader::API> to invoke correct reader.

=head1 FUNCTIONS

=head2 new

  my $rfid = Biblio::RFID::Reader->new( 'optional reader filter' );

=cut

sub new {
	my ( $class, $filter ) = @_;
	my $self = {};
	bless $self, $class;
	$self->{_readers} = [ $self->_available( $filter ) ];
	return $self;
}

=head2 tags

  my @visible = $rfid->tags(
		enter => sub { my $tag = shift; },
		leave => sub { my $tag = shift; },
  );

=cut

sub tags {
	my $self = shift;
	my $triggers = {@_};

	$self->{_tags} ||= {};
	$self->{_tags}->{$_}->{time} = 0 foreach keys %{$self->{_tags}};
	my $t = time;

	foreach my $rfid ( @{ $self->{_readers} } ) {
		warn "# inventory on $rfid";
		my @tags = $rfid->inventory;

		foreach my $tag ( @tags ) {

			if ( ! exists $self->{_tags}->{$tag} ) {
				eval {
					my $blocks = $rfid->read_blocks($tag);
					$self->{_tags}->{$tag}->{blocks} = $blocks->{$tag} || die "no $tag in ",dump($blocks);
					my $afi = $rfid->read_afi($tag);
					$self->{_tags}->{$tag}->{afi} = $afi;

				};
				if ( $@ ) {
					warn "ERROR reading $tag: $@\n";
					$self->_invalidate_tag( $tag );
					next;
				}

				$triggers->{enter}->( $tag ) if $triggers->{enter};
			}

			$self->{_tags}->{$tag}->{time} = $t;

		}
	
		foreach my $tag ( grep { $self->{_tags}->{$_}->{time} == 0 } keys %{ $self->{_tags} } ) {
			$triggers->{leave}->( $tag ) if $triggers->{leave};
			$self->_invalidate_tag( $tag );
		}

	}

	warn "## _tags ",dump( $self->{_tags} );

	return grep { $self->{_tags}->{$_}->{time} } keys %{ $self->{_tags} };
}

=head2 blocks

  my $blocks_arrayref = $rfid->blocks( $tag );

=head2 afi

  my $afi = $rfid->afi( $tag );

=cut

sub blocks { $_[0]->{_tags}->{$_[1]}->{ 'blocks' } || confess "no blocks for $_[1]"; };
sub afi    { $_[0]->{_tags}->{$_[1]}->{ 'afi'    } || confess "no afi for $_[1]"; };

=head1 PRIVATE

=head2 _invalidate_tag

  $rfid->_invalidate_tag( $tag );

=cut

sub _invalidate_tag {
	my ( $self, $tag ) = @_;
	my @caller = caller(0);
	warn "## _invalidate_tag caller $caller[0] $caller[1] +$caller[2]\n";
	my $old = delete $self->{_tags}->{$tag};
	warn "# _invalidate_tag $tag ", dump($old);
}

=head2 _available

Probe each RFID reader supported and returns succefull ones

  my $rfid_readers = Biblio::RFID::Reader->_available( $regex_filter );

=cut

my @readers = ( '3M810', 'CPRM02', 'librfid' );

sub _available {
	my ( $self, $filter ) = @_;

	$filter = '' unless defined $filter;

	warn "# filter: $filter";

	my @rfid;

	foreach my $reader ( @readers ) {
		next if $filter && $reader !~ /$filter/i;
		my $module = "Biblio::RFID::Reader::$reader";
		eval "use $module";
		die $@ if $@;
		if ( my $rfid = $module->new ) {
			push @rfid, $rfid;
			warn "# added $module\n";
		} else {
			warn "# ignored $module\n";
		}
	}

	die "no readers found" unless @rfid;

	return @rfid;
}

=head1 AUTOLOAD

On any other function calls, we just marshall to all readers

=cut

# we don't want DESTROY to fallback into AUTOLOAD
sub DESTROY {}

our $AUTOLOAD;
sub AUTOLOAD {
	my $self = shift;
	my $command = $AUTOLOAD;
	$command =~ s/.*://;

	my @out;

	foreach my $r ( @{ $self->{_readers} } ) {
		push @out, $r->$command(@_);
	}

	$self->_invalidate_tag( $_[0] ) if $command =~ m/write/;

	return @out;
}

1
__END__

=head1 SEE ALSO

=head2 RFID reader implementations

L<Biblio::RFID::Reader::3M810>

L<Biblio::RFID::Reader::CPRM02>

L<Biblio::RFID::Reader::librfid>

