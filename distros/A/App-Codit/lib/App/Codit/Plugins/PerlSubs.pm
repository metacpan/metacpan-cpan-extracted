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
		$hlist->headerCreate($count,
			-headerbackground => $self->configGet('-background'),
			-itemtype => 'window', 
			-widget => $header);
#		$list->headerCreate($count, -text => $_);
		$count ++;
	}

	return $self;
}

sub Clear {
	my $self = shift;
	my $hlist = $self->{HLIST};
	$hlist->deleteAll;
}

sub Refresh {
	my ($self, $select) = @_;
	$self->SUPER::Refresh;
	$select = 1 unless defined $select;
	my $current = $self->{CURRENT};
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
	}
	
	unless (Compare($current, \@new)) {

		my $hlist = $self->{HLIST};
		my $cursel;
		( $cursel ) = $hlist->infoSelection if $hlist->infoSelection;
	
		my $lastvisible = $hlist->nearest($hlist->height - 1);
		$self->Clear;

		for (@new) {
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
			$hlist->selectionSet($current) if (defined $current) and $hlist->infoExists($current);
			$hlist->see($lastvisible) if (defined $lastvisible) and $hlist->infoExists($lastvisible);
		}
		$self->{CURRENT} = \@new
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

















