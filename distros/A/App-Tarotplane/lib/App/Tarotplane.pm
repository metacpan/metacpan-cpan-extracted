package App::Tarotplane;
our $VERSION = '1.00';
use 5.016;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(%CARD_SORT);

use Getopt::Long;

use App::Tarotplane::Cards;
use App::Tarotplane::UI;

my $PRGNAM = 'tarotplane';
my $PRGVER = $VERSION;

my $HELP_MSG = <<END;
$PRGNAM - $PRGVER
Usage: $0 [options] file ...

Options:
 -o <by>  --order=<by>   Order cards alphabetically by terms or definitions
 -r       --random       Randomize order cards appear in
 -t       --terms-first  Show terms first rather than definitions
 -h       --help         Print help message and exit
 -v       --version      Print version and copyright info, then exit
END

my $VER_MSG = <<END;
$PRGNAM - $PRGVER

Copyright 2024, Samuel Young

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
END

our %CARD_SORT = (
	None   => 0,
	Random => 1,
	Order  => 2,
);

sub init {

	my $class = shift;
	my $self = {
		Files   => [],
		Sort    => $CARD_SORT{None},
		OrderBy => '',
		First   => 'Definition',
	};

	my $order = undef;

	Getopt::Long::config('bundling');
	GetOptions(
		'order|o:s'     => \$order,
		'random|r'      => sub { $self->{Sort} = $CARD_SORT{Random} },
		'terms-first|t' => sub { $self->{First} = 'Term' },
		'help|h'        => sub { print $HELP_MSG; exit 0 },
		'version|v'     => sub { print $VER_MSG;  exit 0 },
	) or die "Error in command line arguments\n";

	die $HELP_MSG unless @ARGV;

	$self->{Files} = \@ARGV;

	foreach my $f (@{$self->{Files}}) {
		unless (-r $f) {
			die "$f does not exist or is not readable\n";
		}
	}

	if (defined $order) {

		$order = fc $order;

		if ($order eq fc 'term' or $order eq '') {
			$self->{OrderBy} = 'Term';
		} elsif ($order eq fc 'definition') {
			$self->{OrderBy} = 'Definition';
		} else {
			die "Cards must be sorted by either 'Term' or 'Definition'\n";
		}

		$self->{Sort} = $CARD_SORT{Order};

	}

	bless $self, $class;
	return $self;

}

sub run {

	my $self = shift;

	my $deck = App::Tarotplane::Cards->new(@{$self->{Files}});

	if ($self->{Sort} == $CARD_SORT{Random}) {
		$deck->shuffle_deck();
	} elsif ($self->{Sort} == $CARD_SORT{Order}) {
		$deck->order_deck($self->{OrderBy});
	}

	my $filestr = join(" ", @{$self->{Files}});

	my $card = 0;
	my $side = $self->{First};

	my $ui = App::Tarotplane::UI->init();

	$ui->wipe();

	$ui->draw_card(
		$deck->card_side($card, $side),
		$side eq 'Term' ? 1 : 0
	);
	$ui->draw_info(
		sprintf("[%d/%d] %s", $card + 1, $deck->get('CardNum'), $filestr)
	);

	$ui->update();

	while (1) {

		my $cmd = $ui->poll();

		# Do nothing if we can't recognize the command
		next unless defined $cmd;

		if ($cmd eq 'Next') {
			$card++ if $card < $deck->get('CardNum') - 1;
			$side = $self->{First};
		} elsif ($cmd eq 'Prev') {
			$card-- if $card > 0;
			$side = $self->{First};
		} elsif ($cmd eq 'Flip') {
			$side = $side eq 'Term' ? 'Definition' : 'Term';
		} elsif ($cmd eq 'First') {
			$card = 0;
			$side = $self->{First};
		} elsif ($cmd eq 'Last') {
			$card = $deck->get('CardNum') - 1;
			$side = $self->{First};
		} elsif ($cmd eq 'Quit') {
			last;
		} elsif ($cmd eq 'Help') {
			$ui->wipe();
			$ui->draw_help();
			$ui->update();
			$ui->poll();
		}

		$ui->wipe();
		$ui->draw_card(
			$deck->card_side($card, $side),
			$side eq 'Term' ? 1 : 0
		);
		$ui->draw_info(
			sprintf("[%d/%d] %s", $card + 1, $deck->get('CardNum'), $filestr)
		);
		$ui->update();

	}

	$ui->end();

}

sub get {

	my $self = shift;
	my $get  = shift;

	return $self->{$get};

}

1;



=head1 NAME

App::Tarotplane - Curses flashcard program

=head1 SYNOPSIS

  use App::Tarotplane;

  $tarotplane = App::Tarotplane->init();
  $tarotplane->run();

=head1 DESCRIPTION

App::Tarotplane is the module that does all of the work for L<tarotplane>.
If you're looking for L<tarotplane> documentation, you should consult its
manual page instead of this one.

=head1 Object Methods

=head2 App::Tarotplane->init()

Reads @ARGV and returns an initialized App::Tarotplane object. Read the
documentation for L<tarotplane> for a list of what options are available to
tarotplane.

=head2 $tarotplane->run()

Runs tarotplane.

=head1 Global Variables

=over 4

=item $App::Tarotplane::VERSION

tarotplane version.

=item %CARD_SORT

  use App::Tarotplane qw(%CARD_SORT);

Hash map of different ways tarotplane can sort cards.

=over 4

=item None

Cards are sorted as they appear in the given files.

=item Random

Cards are sorted in random order.

=item Order

Cards are sorted in alphabetical order.

=back

=back

=head1 AUTHOR

Written by Samuel Young E<lt>L<samyoung12788@gmail.com>E<gt>.

=head1 COPYRIGHT

Copyright 2024, Samuel Young

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<tarotplane>

=cut
