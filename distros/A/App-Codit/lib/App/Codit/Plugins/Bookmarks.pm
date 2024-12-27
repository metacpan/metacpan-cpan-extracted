package App::Codit::Plugins::Bookmarks;

=head1 NAME

App::Codit::Plugins::Bookmarks - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = 0.14;

use Data::Compare;
require Tk::ITree;

use base qw( App::Codit::BaseClasses::TextModPlugin );

=head1 DESCRIPTION

Manage bookmarks for all files.

=head1 DETAILS

The bookmarks menu only covers bookmarks within the selected document. The bookmarks
plugin covers the bookmarks in all open files. I creates a bookmarks list in the
navigator panel and a previous and next button in the toolbar. Previous and next refer
to the previously and next selected bookmarks.

The sessions plugin restores all bookmarks in the Bookmarks plugin if it is loaded.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;

	my $page = $self->ToolNavigPageAdd('Bookmarks', 'bookmarks', undef, 'Manage your bookmarks');

	$self->cmdConfig(
		bm_plug_next => ['bmNext', $self],
		bm_plug_previous => ['bmPrevious', $self],
	);
	$self->cmdHookAfter('bookmark_add', 'RefreshSelected', $self);
	$self->cmdHookAfter('bookmark_remove', 'RefreshSelected', $self);

	$self->{CURRENT} = undef;
	$self->{NEXT} = [];
	$self->{PREVIOUS} = [];

	my $tree = $page->Scrolled('ITree',
		-height => 4,
		-browsecmd => ['Select', $self],
		-scrollbars => 'osoe',
		-separator => '@',
	)->pack(-padx => 2, -pady => 2, -expand => 1, -fill => 'both');
	$self->{TREE} = $tree;

	$self->after(100, ['Initialize', $self]);
	return $self;
}

sub _visible {
	my $self = shift;
	return $self->tree->ismapped;
}

sub bmAdd {
	my $self = shift;
	my $name = shift;
	my $t = $self->tree;
	
	#add parent unless already exists
	unless ($t->infoExists($name)) {

		#calculate position
		my @ch = $t->infoChildren('');
		my @op;
		for (@ch) {
			if ($_ gt $name) {
				push @op, -before => $_;
				last;
			}
		}

		#add parent
		$t->add($name, -text => $self->abbreviate($name, 30), @op);
	}

	#add bookmarks
	while (@_) {
		my $mark = shift;
		unless ($self->bmExists($name, $mark)) {
			#calculate position
			my @ch = $t->infoChildren($name);
			my $newmark = $name . '@' . $mark;
			my $line = $self->bmLineNumber($newmark);
			my @op;
			for (@ch) {
				my $peer = $self->bmLineNumber($_);
				if ($peer > $line) {
					push @op, -before => $_;
					last;
				}
			}
	
			#add bookmark
			$t->add($newmark, -text => $mark, @op);
		}
		$t->autosetmode(1);
	}
}

sub bmCompare {
	my ($self, $mark1, $mark2) = @_;
	if ($mark1 =~ /^(\d+)/) {
		$mark1 = $1
	}
	if ($mark2 =~ /^(\d+)/) {
		$mark2 = $1
	}
	return $mark1 eq $mark2
}

sub bmExists {
	my ($self, $name, $mark) = @_;
	my $t = $self->tree;
	return '' unless $t->infoExists($name);

	my @list = $t->infoChildren($name);
	for (@list) {
		my @targ = split/\@/, $_;
		return 1 if $self->bmCompare($mark, $targ[1]);
	}
	return ''
}

sub bmGo {
	my ($self, $mark) = @_;
	my ($doc, $bm) = split /\@/, $mark;
	$bm = '' unless defined $bm;
	my $mdi = $self->mdi;
	if ($bm =~ /^(\d+)/) {
		$self->cmdExecute('doc_select', $doc);
		my $w = $mdi->docGet($doc)->CWidg;
		$w->bookmarkGo($1);
	}
}

sub bmLineNumber {
	my ($self, $mark) = @_;
	my ($doc, $bm) = split /\@/, $mark;
	$bm = '' unless defined $bm;
	if ($bm =~ /^(\d+)/) {
		return $1
	}
}

sub bmNext {
	my $self = shift;
	my $nstack = $self->{NEXT};
	if (@$nstack) {
		my $pstack = $self->{PREVIOUS};
		unshift @$pstack, $self->{CURRENT};
		my $new = shift @$nstack;
		$self->{CURRENT} = $new;
		$self->bmGo($new);
	}
}

sub bmPrevious {
	my $self = shift;
	my $pstack = $self->{PREVIOUS};
	if (@$pstack) {
		my $nstack = $self->{NEXT};
		unshift @$nstack, $self->{CURRENT};
		my $new = shift @$pstack;
		$self->{CURRENT} = $new;
		$self->bmGo($new);
	}
}

sub Collect {
	my ($self, $name) = @_;
#	print "collecting $name\n";
	my @out = ();
	my $mdi = $self->mdi;
	if ($mdi->deferredExists($name)) {
		my $o = $mdi->deferredOptions($name);
		if (defined $o) {
			if (my $b = $o->{'bookmarks'}) {
				my @marks = ();
				while ($b =~ s/^(\d+)\s//) {
					push @marks, $1;
				}
				my $num = 1;
				if (open IF, '<', $name) {
					while (my $line = <IF>) {
						chomp $line;
						if ($num eq $marks[0]) {
							shift @marks;
							$line =~ s/^\s+//;
							my $o = $line;
							$o = substr($line, 0, 20) if length $line > 20;
							push @out, "$num - $o";
						}
						$num ++;
						last unless @marks;
					}
					close IF;
				}
			}
		}
	} else {
		my $w = $mdi->docGet($name)->CWidg;
		my @list = $w->bookmarkList;
		for (@list) {
			push @out, "$_ - " . $w->bookmarkText($_);
		}
	}
	return @out
}

sub docRefresh {
	my ($self, $name) = @_;
	my $t = $self->tree;

	my $cursel;
	( $cursel ) = $t->infoSelection;

	if ($t->infoExists($name)) {
		for ($t->infoChildren($name)) {
			$t->deleteEntry($_);
		}
	}
	my @new = $self->Collect($name);
	if ($t->infoExists($name)) {
		$t->deleteEntry($name) unless @new;
	}
	$self->bmAdd($name, @new) if @new;

	$t->selectionSet($cursel) if (defined $cursel);
}

sub histClearNext {
	my $self = shift;
	$self->{NEXT} = [];
}

sub Initialize {
	my $self = shift;
	my $t = $self->tree;
	$t->deleteAll;
	my $mdi = $self->mdi;
	for ($mdi->deferredList, $mdi->docList) {
		my @marks = $self->Collect($_);
		$self->bmAdd($_, @marks) if @marks;
	}
}

sub Refresh {
	my $self = shift;
	$self->SUPER::Refresh;
	$self->RefreshSelected;
}

sub RefreshAll {
	my $self = shift;
	my $t = $self->tree;
	my @list = $t->infoChildren('');
	for (@list) {
		$self->docRefresh($_);
	}
}

sub RefreshSelected {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $doc = $mdi->docSelected;
	return unless defined $doc;
	$self->docRefresh($doc);
}

sub Select {
	my ($self, $mark) = @_;

	#check if the mark is valid
	my @targ = split /\@/, $mark;
	return unless @targ eq 2;

	#handle history
	my $cur = $self->{CURRENT};
	if ((defined $cur) and ($cur ne $mark)) {
		my $prev = $self->{PREVIOUS};
		push @$prev, $cur;
		$self->histClearNext;
	}

	#jump to bookmark
	$self->{CURRENT} = $mark;
	$self->bmGo($mark);
}

sub tree { return $_[0]->{TREE} }

sub ToolItems {
	my $self = shift;
	my @items = $self->SUPER::ToolItems;
	return (@items,
	#	type					label			      cmd					             icon					            help
	[	'tool_separator' ],
	[	'tool_button',		'Previous',	'bm_plug_previous', 	'bookmark_previous',	'Jump to previous bookmark'],
	[	'tool_button',		'Next',	    'bm_plug_next',		    'bookmark_next',		   'Jump to next bookmark'],
	);
}

sub Unload {
	my $self = shift;
	for (qw/
		bm_plug_next
		bm_plug_previous
	/) {
		$self->cmdRemove($_);
	}
	$self->cmdUnhookAfter('bookmark_add', 'RefreshSelected', $self);
	$self->cmdUnhookAfter('bookmark_remove', 'RefreshSelected', $self);
	$self->ToolNavigPageRemove('Bookmarks');
	return $self->SUPER::Unload;
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

