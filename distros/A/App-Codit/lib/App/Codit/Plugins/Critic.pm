package App::Codit::Plugins::Critic;

=head1 NAME

App::Codit::Plugins::Critic - plugin for App::Codit

=cut

use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '0.21';

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Perl::Critic;
require Tk::ROText;
use Tk;

=head1 DESCRIPTION

Check your code for best practices.

=head1 DETAILS

This plugin uses L<Perl::Critic> to check your document for best practices.
You can select your favorite severity level.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;

	my $page = $self->ToolRightPageAdd('Critic', 'code-class', undef, 'Check your code for best practices');


	my @padding = (-padx => 2, -pady => 2);

	my $sm = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-padx => 2, -fill => 'x');
	my $mf = $sm->Frame->pack(-expand => 1, -fill =>'x');
	$mf->Label(
		-anchor =>'e',
		-width => 10,
		-text => 'Severity:',
	)->pack(-side => 'left');
	my $sev = 'harsh';
	$self->{SEVERITY} = \$sev;
	my $mb = $mf->Menubutton(
		-anchor => 'w',
		-textvariable => \$sev,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');
	my @menu = ();
	for ('gentle', 'stern', 'harsh', 'cruel', 'brutal') {
		my $operation = $_;
		push @menu, [command => $operation,
			-command => sub { $sev = $operation },
		];
	}
	$mb->configure(-menu => $mb->Menu(
		-menuitems => \@menu,
	));

	my $sa = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(@padding, -expand => 1, -fill => 'both');
	$sa->Button(
		-text => 'Critique',
		-command => ['Critique', $self],
	)->pack(@padding, -fill => 'x');
	$sa->Button(
		-text => 'Clear',
		-command => ['Clear', $self],
	)->pack(@padding, -fill => 'x');

	my $fam = $self->configGet('-contentfontfamily');
	$fam = 'Courier' unless defined $fam;
	my $siz = $self->configGet('-contentfontsize');
	$siz = 10 unless defined $siz;
	my $txt = $sa->Scrolled('ROText',
		-font => "{$fam} $siz",
		-scrollbars => 'oe',
		-width => 40,
		-wrap => 'word',
	)->pack(@padding, -expand => 1, -fill => 'both');
	$self->{TXT} = $txt;

	$txt->tagConfigure('link', -foreground => $self->configGet('-linkcolor'));
	$txt->tagBind('link', '<Enter>', sub { $txt->configure('-cursor', 'hand1')});
	$txt->tagBind('link', '<Leave>', sub { $txt->configure('-cursor', 'xterm')});
	$txt->tagBind('link', '<ButtonRelease-1>', [$self, 'linkClick', Ev('x'), Ev('y')]);

	return $self;
}

sub Clear {
	my $self = shift;
	my $txt = $self->{TXT};
	$txt->delete('0.0', 'end');
}

sub Critique {
	my $self = shift;
	my $txt = $self->{TXT};
	$txt->delete('0.0', 'end');
	my $widg = $self->mdi->docWidget;
	my $source = $widg->get('0.0', 'end - 1 char');
	my $sev = $self->{SEVERITY};
	my $cr = new Perl::Critic(-severity => $$sev);
	my @violations = $cr->critique(\$source);
	for (@violations) {
		my $line = $_;
		while ($line ne '') {
			if ($line =~ s/^(line\s\d+,\scolumn\s\d+)//) {
				$txt->insert('end', $1, 'link');
			} else {
				my $char = substr($line, 0, 1);
				$line = substr($line, 1, length($line) - 1);
				if ($char eq "\n") {
					$txt->insert('end', "\n\n");
				} else {
					$txt->insert('end', $char);
				}
			}
		}
	}
}

sub linkClick {
	my ($self, $x, $y) = @_;
	my $link;
	my $txt = $self->{TXT};

	#find the link
	my $pos = $txt->index('@' ."$x,$y");
	my @ranges = $txt->tagRanges('link');
	while (@ranges) {
		my $begin = shift @ranges;
		my $end = shift @ranges;
		if (($txt->compare($begin, '<=', $pos)) and ($txt->compare($end, '>=', $pos))) {
			$link = $txt->get($begin, $end);
			last
		}
	}
	if ($link =~ /^line\s(\d+),\scolumn\s(\d+)/) {
		my $widg = $self->mdi->docWidget;
		my $goto = "$1.$2";
		$widg->goTo($goto);
		$widg->focus;
	}

}

sub Unload {
	my $self = shift;
	$self->ToolRightPageRemove('Critic');
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

If you find any bugs, please report them here L<https://github.com/haje61/App-Codit/issues>.

=head1 SEE ALSO

=over 4

=item L<Perl::Critic>

=back

=cut


1;









