package App::Codit::Plugins::PerlSubs;

=head1 NAME

App::Codit::Plugins::PerlSubs - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.03;
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Plugin );
require Tk::HList;

=head1 DESCRIPTION

Easily find the subs in your document.

=head1 DETAILS

PerlSubs scans the current selected document for lines that begin
with ‘sub someName‘ and displays it in a list with the line number. 
The list is refreshed after an edit.

When you click on and item in the list, the insert cursor is moved to that
line and it is scrolled into visibility.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'NavigatorPanel');
	return undef unless defined $self;
	
	my $tp = $self->extGet('NavigatorPanel');
	my $page = $tp->addPage('PerlSubs', 'code-context', undef, 'Find your Perl subs');
	$self->{ACTIVEDELAY} = 300;
	$self->cmdHookAfter('modified', 'activate', $self);
	$self->cmdHookAfter('doc_select', 'NewDocument', $self);
	$self->cmdHookAfter('doc_close', 'docAfter', $self);
	
	$self->{NAME} = undef;
	$self->{POSITIONS} = {};
	$self->{CURDOC} = 0;
	$self->{MODLEVEL} = 0;
	
	my $hlist = $page->Scrolled('HList',
		-browsecmd => ['Select', $self],
		-columns => 2,
		-header => 1,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->{HLIST} = $hlist;
	my $count = 0;
	for ('Sub', 'Line') {
		my $header = $hlist->Frame;
		$header->Label(-text => $_)->pack(-side => 'left');
		$hlist->headerCreate($count, -itemtype => 'window', -widget => $header);
#		$list->headerCreate($count, -text => $_);
		$count ++;
	}

	my $sel = $self->extGet('CoditMDI')->docSelected;
	$self->NewDocument($sel) if defined $sel;

	return $self;
}

sub activate {
	my $self = shift;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	$self->{'active_id'} = $self->after($self->activeDelay, ['RefreshList', $self]);
	return @_;
}

sub activeDelay {
	my $self = shift;
	$self->{ACTIVEDELAY} = shift if @_;
	return $self->{ACTIVEDELAY}
}


sub docAfter {
	my $self = shift;
	my ($name) = @_;
	if ((defined $name) and $name) {
		$self->{NAME} = undef;
		$self->RefreshList;
	}
	return @_
}

sub GetDocument {
	my $self = shift;
	my $name = $self->{NAME};
	my $mdi = $self->extGet('CoditMDI');
	return undef unless defined $name;
	my $doc = $mdi->docGet($name);
	return undef unless defined $doc;
	return $name, $doc->CWidg;
}

sub NewDocument {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	return @_ if $mdi->selectDisabled;
	my $name = $mdi->docSelected;
	return @_ unless defined $name;
	if (defined $name) {
		$self->{NAME} = $name;
		$self->after(50, sub { $self->RefreshList(0)});
	}
	return @_
}

sub RefreshList {
	my ($self, $select) = @_;
	delete $self->{'active_id'};
	$select = 1 unless defined $select;
	my $name = $self->{NAME};

	my $hlist = $self->{HLIST};
	my $current;
	( $current ) = $hlist->infoSelection if $hlist->infoSelection;

	my $lastvisible = $hlist->nearest($hlist->height - 1);
	$hlist->deleteAll;
	return unless defined $name;
	my $mdi = $self->extGet('CoditMDI');
	my $doc = $mdi->docGet($name)->CWidg;
	my $end = $doc->index('end - 1c');
	my $numlines = $end;
	$numlines =~ s/\.\d+$//;
	for (1 .. $numlines) {
		my $num = $_;
		my $line = $doc->get("$num.0", "$num.0 lineend");
		if ($line =~ /^\s*sub\s+([^\s|^\{]+)/) {
			my $name = $1;
			my $item = $name;
			my $count = 2;
			while ($hlist->infoExists($item)) {
				$item = "$name$count";
				$count ++
			}
			$hlist->add($item, -data => $num);
			$hlist->itemCreate($item, 0, -text => $name);
			$hlist->itemCreate($item, 1, -text => $num);
		}
	}

	#find and set selection
	if ($select) {
		$hlist->selectionSet($current) if defined $current;
		$hlist->see($lastvisible) if defined $lastvisible;
	}
}

sub Select {
	my ($self, $name) = @_;
	my $hlist = $self->{HLIST};
	my $doc = $self->GetDocument;
	if (defined $doc) {
		my $line = $hlist->infoData($name);
		my $index = "$line.0";
		$doc->goTo($index);
		$doc->focus;
# 		$doc->see($index);
	}
}

sub Unload {
	my $self = shift;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	$self->extGet('NavigatorPanel')->deletePage('PerlSubs');
	$self->cmdUnhookAfter('modified', 'activate', $self);
	$self->cmdUnhookAfter('doc_select', 'NewDocument', $self);
	$self->cmdUnhookAfter('doc_close', 'docAfter', $self);
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

















