package App::Unicode::Block;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Curses::UI;
use Encode qw(encode_utf8);
use Error::Pure qw(err);
use Getopt::Std;
use List::MoreUtils qw(none);
use Unicode::Block::Ascii;
use Unicode::Block::List;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'l' => 0,
	};
	if (! getopts('hl', $self->{'_opts'}) || $self->{'_opts'}->{'h'}) {
		print STDERR "Usage: $0 [-h] [-l] [--version] [unicode_block]\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t-l\t\tList of blocks.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tunicode_block\tUnicode block name for print.\n";
		exit 1;
	}
	$self->{'_unicode_block'} = $ARGV[0];

	# Get unicode block list.
	$self->{'_list'} = Unicode::Block::List->new;
	$self->{'_unicode_block_list'} = [$self->{'_list'}->list];

	# Check unicode block.
	if (defined $self->{'_unicode_block'}) {
		if (none { $self->{'_unicode_block'} eq $_ }
			@{$self->{'_unicode_block_list'}}) {

			err "Unicode block '$self->{'_unicode_block'}' doesn't exist.";
		}
	}

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Print unicode blocks.
	if ($self->{'_opts'}->{'l'}) {
		print join "\n", @{$self->{'_unicode_block_list'}};
		print "\n";
		return;
	}

	# Print block.
	if ($self->{'_unicode_block'}) {
		$self->_print_block($self->{'_unicode_block'});

	# GUI for selecting of block.
	} else {

		# Window.
		my $cui = Curses::UI->new;
		my $win = $cui->add('window_id', 'Window');
		$win->set_binding(\&exit, "\cQ", "\cC");

		# Popup menu.
		my $popupbox = $win->add(
			'mypopupbox', 'Popupmenu',
			'-labels' => {
				map { $_, $_ } @{$self->{'_unicode_block_list'}},
			},
			'-onchange' => sub {
				my $cui_self = shift;
				$cui->leave_curses;
				$self->_print_block($cui_self->get);
				exit 0;
			},
			'-values' => $self->{'_unicode_block_list'},
		);
		$popupbox->focus;

		# Loop.
		$cui->mainloop;
	}

	return;
}

sub _print_block {
	my ($self, $block) = @_;

	my $block_hr = $self->{'_list'}->block($block);
	my $block_ascii = Unicode::Block::Ascii->new(%{$block_hr});
	print encode_utf8($block_ascii->get)."\n";

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Unicode::Block - Base class for unicode-block script.

=head1 SYNOPSIS

 use App::Unicode::Block;

 my $app = App::Unicode::Block->new;
 $app->run;

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=item C<run()>

 Run method.
 Returns undef.

=back

=head1 ERRORS

 new():
         Unicode block '%s' doesn't exist.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Unicode::Block;

 # Arguments.
 @ARGV = (
         'Thai',
 );

 # Run.
 App::Unicode::Block->new->run;

 # Output:
 # ┌────────────────────────────────────────┐
 # │                  Thai                  │
 # ├────────┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┤
 # │        │0│1│2│3│4│5│6│7│8│9│A│B│C│D│E│F│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e0x │ │ก│ข│ฃ│ค│ฅ│ฆ│ง│จ│ฉ│ช│ซ│ฌ│ญ│ฎ│ฏ│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e1x │ฐ│ฑ│ฒ│ณ│ด│ต│ถ│ท│ธ│น│บ│ป│ผ│ฝ│พ│ฟ│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e2x │ภ│ม│ย│ร│ฤ│ล│ฦ│ว│ศ│ษ│ส│ห│ฬ│อ│ฮ│ฯ│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e3x │ะ│ ั│า│ำ│ ิ│ ี│ ึ│ ื│ ุ│ ู│ ฺ│ │ │ │ │฿│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e4x │เ│แ│โ│ใ│ไ│ๅ│ๆ│ ็│ ่│ ้│ ๊│ ๋│ ์│ ํ│ ๎│๏│
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e5x │๐│๑│๒│๓│๔│๕│๖│๗│๘│๙│๚│๛│ │ │ │ │
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e6x │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
 # ├────────┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤
 # │ U+0e7x │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
 # └────────┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘

=head1 DEPENDENCIES

L<Class::Utils>,
L<Curses::UI>,
L<Encode>,
L<Error::Pure>,
L<Getopt::Std>,
L<List::MoreUtils>,
L<Unicode::Block::Ascii>,
L<Unicode::Block::List>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Unicode-Block>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2020 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
