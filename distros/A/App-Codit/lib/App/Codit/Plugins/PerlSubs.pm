package App::Codit::Plugins::PerlSubs;

=head1 NAME

App::Codit::Plugins::PerlSubs - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.11;
use base qw( App::Codit::BaseClasses::TextModPlugin );

use Data::Compare;
use Tk;
require Tk::HList;
require Tk::FileBrowser::Header;

=head1 DESCRIPTION

Easily find the subs in your document.

=head1 DETAILS

PerlSubs scans the current selected document for lines that begin
with 'sub someName' and displays it in a list with the line number. 
The list is refreshed after an edit.

When you click on and item in the list, the insert cursor is moved to that
line and it is scrolled into visibility.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	my $page = $self->ToolNavigPageAdd('PerlSubs', 'code-context', undef, 'Find your Perl subs');

	$self->{CURRENT} = [];
	$self->{SORTON} = 'Line';
	$self->{SORTORDER} = 'ascending';
	
	my $hlist = $page->Scrolled('HList',
		-browsecmd => ['Select', $self],
		-columns => 2,
		-header => 1,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->{HLIST} = $hlist;
	my $count = 0;
	for ('Sub', 'Line') {
		my $header = $hlist->Header(
			-column => $count,
			-sortcall => ['Sortcall', $self],
			-text => $_,
		);
		$hlist->headerCreate($count,
			-headerbackground => $self->configGet('-background'),
			-itemtype => 'window', 
			-widget => $header
		);
		$count ++;
	}
	my $h2 = $hlist->headerCget(1, '-widget');
	$h2->configure(-sortorder => 'ascending');

	return $self;
}

sub Clear {
	my $self = shift;
	my $hlist = $self->{HLIST};
	$hlist->deleteAll;
}

sub Current {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub FillList {
	my ($self, $new, $select) = @_;
	$select = 1 unless defined $select;
	my $hlist = $self->{HLIST};
	my $cursel;
	( $cursel ) = $hlist->infoSelection;
	my $lastvisible = $hlist->nearest($hlist->height - 1);
	$self->Clear;

	for (@$new) {
		my ($name, $num) = @$_;
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

	#find and set selection
	if ($select) {
		$hlist->selectionSet($cursel) if (defined $cursel) and $hlist->infoExists($cursel);
		$hlist->see($lastvisible) if (defined $lastvisible) and $hlist->infoExists($lastvisible);
	}
	$self->Current($new);
}

sub Refresh {
	my ($self, $select) = @_;
	$self->SUPER::Refresh;
	$select = 1 unless defined $select;
	my $current = $self->Current;
	my @new = ();

	my $mdi = $self->extGet('CoditMDI');
	my $doc = $self->mdi->docWidget;
	return unless defined $doc;
	my $end = $doc->index('end - 1c');
	my $numlines = $end;
	$numlines =~ s/\.\d+$//;
	for (1 .. $numlines) {
		my $num = $_;
		my $line = $doc->get("$num.0", "$num.0 lineend");
		if ($line =~ /^\s*sub\s+([^\s|^\{]+)/) {
			my $name = $1;
			push @new, [$name, $num];
		}
		@new = $self->Sort(@new);
	}
	
	unless (Compare($current, \@new)) {
		$self->FillList(\@new, $select);
	}
}

sub Select {
	my ($self, $name) = @_;
	my $hlist = $self->{HLIST};
	my $doc = $self->mdi->docWidget;
	if (defined $doc) {
		my $line = $hlist->infoData($name);
		my $index = "$line.0";
		$doc->goTo($index);
		$doc->focus;
# 		$doc->see($index);
	}
}

sub Sort {
	my ($self, @list) = @_;
	my $on = $self->SortOn;
	my $order = $self->SortOrder;
	my @new;
	if ($on eq 'Sub') {
		if ($order eq 'ascending') {
			@new = sort {$a->[0] cmp $b->[0]} @list
		} elsif ($order eq 'descending') {
			@new = reverse sort {$a->[0] cmp $b->[0]} @list
		}
	} elsif ($on eq 'Line') {
		if ($order eq 'ascending') {
			@new = sort {$a->[1] <=> $b->[1]} @list
		} elsif ($order eq 'descending') {
			@new = reverse sort {$a->[1] <=> $b->[1]} @list
		}
	}
	return @new
}

sub Sortcall {
	my ($self, $on, $order) = @_;
	$self->SortOn($on);
	$self->SortOrder($order);
	my $hlist = $self->{HLIST};

	my $col;
	$col = 0 if $on eq 'Sub';
	$col = 1 if $on eq 'Line';
	my $h1 = $hlist->headerCget($col, '-widget');
	$h1->configure(-sortorder => $order);
	my $ncol = not $col;
	my $h2 = $hlist->headerCget($ncol, '-widget');
	$h2->configure(-sortorder => 'none');

	my $cur = $self->Current;
	my @new = $self->Sort(@$cur);
	$self->FillList(\@new);
	$self->Current(\@new);
}

sub SortOn {
	my $self = shift;
	$self->{SORTON} = shift if @_;
	return $self->{SORTON}
}

sub SortOrder {
	my $self = shift;
	$self->{SORTORDER} = shift if @_;
	return $self->{SORTORDER}
}

sub Unload {
	my $self = shift;
	$self->ToolNavigPageRemove('PerlSubs');
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

















