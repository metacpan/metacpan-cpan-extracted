package App::Codit::BaseClasses::TextModPlugin;

=head1 NAME

App::Codit::BaseClasses::TextModPlugin - baseclass for plugins that respond to text modifications

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.10;
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Plugin );
require Tk::HList;

=head1 DESCRIPTION

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	$self->{ACTIVEDELAY} = 600;
	$self->cmdHookBefore('quit', 'selectBlock', $self);
	$self->cmdHookBefore('deferred_open', 'selectBlock', $self);
	$self->cmdHookAfter('modified', 'activate', $self);
	$self->cmdHookAfter('doc_select', 'docSelect', $self);
	
#	$self->after(1000, sub {
#		my $sel = $self->extGet('CoditMDI')->docSelected;
#		$self->docSelect($sel) if defined $sel;
#	});

	return $self;
}

sub activate {
	my $self = shift;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	$self->{'active_id'} = $self->after($self->activeDelay, ['Refresh', $self]);
	return @_;
}

sub activeDelay {
	my $self = shift;
	$self->{ACTIVEDELAY} = shift if @_;
	return $self->{ACTIVEDELAY}
}

sub Clear {
}

sub docSelect {
	my $self = shift;

	if (exists $self->{'select_block'}) {
		$self->after(100, sub { delete $self->{'select_block'} });
		return @_;
	}

	my $mdi = $self->extGet('CoditMDI');
	return @_ if $mdi->selectDisabled;
	$self->after(10, sub {
		$self->Refresh(0);
	});
	return @_
}

sub docWidget {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $name = $mdi->docSelected;
	return undef unless defined $name;
	my $doc = $mdi->docGet($name);
	return undef unless defined $doc;
	return $doc->CWidg;
}
 
sub Refresh {
	my $self = shift;
	delete $self->{'active_id'};
}

sub selectBlock {
	my $self = shift;
	$self->{'select_block'} = 1;
	return @_;
}

sub Unload {
	my $self = shift;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	$self->cmdUnhookBefore('quit', 'selectBlock', $self);
	$self->cmdUnhookBefore('deferred_open', 'selectBlock', $self);
	$self->cmdUnhookAfter('modified', 'activate', $self);
	$self->cmdUnhookAfter('doc_select', 'docSelect', $self);
#	$self->cmdUnhookAfter('doc_close', 'docAfterClose', $self);
	return $self->SUPER::Unload
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut


1;
