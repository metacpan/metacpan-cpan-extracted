package App::Codit::Plugins::PerlSubs;

=head1 NAME

App::Codit::Plugins::PerlSubs - plugin for App::Codit

=cut

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );
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
	$self->cmdHookAfter('doc_select', 'NewDocument', $self);
	$self->cmdHookAfter('doc_close', 'docAfter', $self);
	$self->interval(300);
	
	$self->{NAME} = undef;
	$self->{POSITIONS} = {};
	$self->{CURDOC} = 0;
	$self->{MODLEVEL} = 0;
	
	my @columns = ('Sub', 'Line');
	my $hlist = $page->Scrolled('HList',
		-browsecmd => ['Select', $self],
		-columns => 2,
		-header => 1,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->{HLIST} = $hlist;
	my $count = 0;
	for (@columns) {
		my $header = $hlist->Frame;
		$header->Label(-text => $_)->pack(-side => 'left');
		$hlist->headerCreate($count, -itemtype => 'window', -widget => $header);
#		$list->headerCreate($count, -text => $_);
		$count ++;
	}

	$self->jobStart('PerlSubs', 'RefreshCycle', $self);
	
	my $sel = $self->extGet('CoditMDI')->docSelected;
	$self->NewDocument($sel) if defined $sel;

	return $self;
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
		$self->{HLIST}->deleteAll;
		$self->{NAME} = $name;
		$self->{MODLEVEL} = '';
#		$self->after(100, ['RefreshList', $self]);
	}
	return @_
}

sub RefreshCycle {
	my $self = shift;
	my $doc = $self->GetDocument;
	if (defined $doc) {
		my $mod = $doc->editModified;
		if ($mod ne $self->{MODLEVEL}) {
			$self->RefreshList;
			$self->{MODLEVEL} = $mod;
		}
	}
}

sub RefreshList {
	my $self = shift;
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
	$hlist->selectionSet($current) if defined $current;
	$hlist->see($lastvisible) if defined $lastvisible;
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
	$self->SUPER::Unload;
	$self->extGet('NavigatorPanel')->deletePage('PerlSubs');
	$self->cmdUnhookAfter('doc_select', 'NewDocument', $self);
	$self->cmdUnhookAfter('doc_close', 'docAfter', $self);
	return 1
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

















