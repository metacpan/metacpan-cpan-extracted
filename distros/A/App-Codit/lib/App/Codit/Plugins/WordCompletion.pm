package App::Codit::Plugins::WordCompletion;

=head1 NAME

App::Codit::Plugins::WordCompletion - plugin for App::Codit

=cut

use strict;
use warnings;
use Carp;
use vars qw( $VERSION );
$VERSION = 0.10;

require Tk::HList;
require Tk::LabFrame;
require Tk::Spinbox;
require Tk::Toplevel;
require Tk::YADialog;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

Make your life easy with word completion.

=head1 DETAILS

This plugin will scan open documents for words longer than five characters
and store them in a database. Whenever you start typing similar words it
will pop a list with suggestions. You can close this popup with the escape key. 
You can traverse the list with your keyboard and select and entry with the
mouse or the return key.

You can temporarily disable word completion through an option in the Tool menu.

In the toolmenu you will also find an option to pop a dialog for configuring word completion.
The I<Active delay> option specifies the wait time after the last key stroke.
The I<Pop size> option specifies how many characters you type before a pop up occurs.
The I<Scan size> option specifies the minimal word size for addition to the database.


Word completion only works on files opened after this plugin was loaded. You may want
to restart Codit after loading this plugin.

=cut

my @deliminators = (
	'.',	'(', ')',	':',	'!',	'+',	',',	'-',	'<',	'=',	'>',	'%',	'&',	'*', '"', '\'',
	'/',	';',	'?',	'[',	']',	'^',	'{',	'|',	'}',	'~',	'\\', '$', '@', '#', '`'
);
my %delimhash = ();
my $reg = '';
for (@deliminators) {
	$delimhash{$_} = 1;
	$reg = $reg . quotemeta($_) . '|';
}
$delimhash{' '} = 1;
$delimhash{"\t"} = 1;
$reg = $reg . '\s';
$reg = qr/$reg/;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_,);
	return undef unless defined $self;

	$self->interval(10);
	$self->{ACTIVEDELAY} = 300;
	$self->{DOCPOOL} = {};
	$self->{POPBLOCK} = 0;
	$self->{POPSIZE} = 4;
	$self->{SCANSIZE} = 6;
	$self->{TRIGGERWORD} = '';

	$self->cmdHookBefore('deferred_open', 'docOpen', $self);
	$self->cmdHookAfter('modified', 'activate', $self);
	$self->cmdHookAfter('doc_close', 'docClose', $self);

	$self->cmdConfig('wc_settings', ['ConfigureSettings', $self]);

	$self->configInit('-wordcompletion', ['wordcompletion', $self, 1]);

	my $choicepop = $self->Toplevel;
	$choicepop->overrideredirect(1);
	$choicepop->withdraw;
	$self->{POP} = $choicepop;
	my $bindsub = $self->bind('<Button-1>');
	if ($bindsub) {
		$self->{'bind_sub'} = $bindsub;
		$self->bind('<Button-1>', sub {
			$bindsub->Call;
			$self->popDown;
		});
	} else {
		$self->bind('<Button-1>',  [$self, 'popDown'] );
	}

	my $lb = $choicepop->HList(
		-borderwidth => 1,
		-highlightthickness => 0,
		-browsecmd => ['Select', $self],
		-relief => 'raised',
		-selectmode => 'single',
	)->pack(-expand => 1, -fill => 'both');
	$lb->bind('<Escape>', [$self, 'popDown']);
	$lb->bind('<Return>', [$self, 'Select']);
	$self->{LISTBOX} = $lb;

	$self->after(50, ['DoPostConfig', $self]);

	return $self;
}

sub _listbox { return $_[0]->{LISTBOX} }

sub _pool { return $_[0]->{DOCPOOL} }

sub _pop { return $_[0]->{POP} }

sub activeDelay {
	my $self = shift;
	$self->{ACTIVEDELAY} = shift if @_;
	return $self->{ACTIVEDELAY}
}

sub activate {
	my $self = shift;
	return @_ if $self->{POPBLOCK};
	return @_ unless $self->configGet('-wordcompletion');

	my $word = $self->getWord;
	unless (defined $word) {
		$self->TriggerWord('');
		return @_;
	}

	my $tword = $self->TriggerWord;
	$tword = quotemeta($tword);
	return @_ if ($tword ne '') and ($word =~ /^$tword/);
	$self->TriggerWord($word);

	my ($name) = @_;
	$name = $self->extGet('CoditMDI')->docSelected unless defined $name;
	my $id = $self->{'active_id'};
	$self->afterCancel($id) if defined $id;
	return @_ unless (defined $name) and ($name ne '');
	$self->{'active_id'} = $self->after($self->activeDelay, ['postChoices', $self, $name]);
	return @_;
}

sub CanQuit {
	my $self = shift;
	my $cff = $self->extGet('ConfigFolder');
	my %settings = (
		delay => $self->activeDelay,
		popsize => $self->PopSize,
		scansize => $self->ScanSize,
	);
	$cff->saveHash('wc_settings', 'cdt wc_settings', %settings);
	return 1
}

sub ConfigureSettings {
	my $self = shift;

	my $delay = $self->activeDelay;
	my $popsize = $self->PopSize;
	my $scansize = $self->ScanSize;

	my @padding = (
		-padx => 2, 
		-pady => 2
	);
	my @l1opt = (		
		-width => 12,
		-anchor => 'e',
	);
	my @l2opt = (		
		-width => 3,
		-anchor => 'w',
	);
	my @spbopt = (
		-from => 0,
		-to => 5000,
		-width => 8,
	);
	my $q = $self->YADialog(
		-title => 'Word Completion',
		-buttons => ['Ok', 'Cancel'],
		-defaultbutton => 'Ok',
	);
	my $f = $q->LabFrame(
		-label => 'Settings',
		-labelside => 'acrosstop',
	)->pack(@padding, -expand => 1, -fill => 'both');

	my $row = 0;
	for (
		[\$delay, 'Active delay', 'ms'],
		[\$popsize, 'Pop size', 'ch'],
		[\$scansize, 'Scan size', 'ch'],
	) {
		my ($variable, $label, $unit) = @$_;
		$f->Label(@l1opt,
			-text => $label,
		)->grid(@padding, -row => $row, -column => 0);
		$f->Spinbox(@spbopt,
			-textvariable => $variable,
		)->grid(@padding, -row => $row, -column => 1);
		$f->Label(@l2opt,
			-text => $unit,
		)->grid(-row => $row, -column => 2);
		$row ++;
	}

	my $answer = $q->Show(-popover => $self->GetAppWindow);
	if ($answer eq 'Ok') {
		if ($delay =~ /^\d+$/) {
			$self->activeDelay($delay);
		} else {
			$self->popMessage("Invalid value '$delay' for Active delay", 'dialog-warning');
		}
		if ($popsize =~ /^\d+$/) {
			$self->PopSize($popsize);
		} else {
			$self->popMessage("Invalid value '$popsize' for Pop size", 'dialog-warning');
		}
		if ($scansize =~ /^\d+$/) {
			$self->ScanSize($scansize);
		} else {
			$self->popMessage("Invalid value '$scansize' for Scan size", 'dialog-warning');
		}
	}
	$q->destroy;
}

sub docClose {
	my $self = shift;
	my ($name) = @_;
	$self->ScanEnd($name);
	delete $self->_pool->{$name};
	return @_;
}

sub docExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return exists $self->_pool->{$name}
}

sub docList {
	my $self = shift;
	my $p = $self->_pool;
	return keys %$p
}

sub docOpen {
	my $self = shift;
	my ($name) = @_;
	return @_ unless defined $name;
	$self->_pool->{$name} = {
		line => 1,
		data => {},
	};
	$self->ScanStart($name, 'scan', $self, $name) unless $self->jobExists($name);
	return @_;
}

sub DoPostConfig {
	my $self = shift;
	my $font = $self->configGet('-contentfont');
	if ((defined $font) and ($font ne '')) {
		$self->_listbox->configure('-font', $font);
	}
	my $folder = $self->configGet('-configfolder');
	if (-e "$folder/wc_settings") {
		my $cff = $self->extGet('ConfigFolder');
		my %settings = $cff->loadHash('wc_settings', 'cdt wc_settings');
		$self->activeDelay($settings{'delay'}) if exists $settings{'delay'};
		$self->PopSize($settings{'popsize'}) if exists $settings{'popsize'};
		$self->ScanSize($settings{'scansize'}) if exists $settings{'scansize'};	
	}
	my @docs = $self->mdi->docList;
	for (@docs) { $self->docOpen($_) }
}

sub getChoices {
	my ($self, $name, $word) = @_;
	my $data = $self->_pool->{$name}->{'data'};
	my @choices = ();
	for (keys %$data) {
		my $test = $_;
		next if length($test) < length($word);
		if ($test ne $word) {
			push @choices, $test if lc(substr($test, 0, length($word))) eq lc($word);
		}
	}
	@choices = sort {uc($a) cmp uc($b)} @choices;
	return @choices
}

sub getIndexes {
	my $self = shift;
	my $mdi = $self->mdi;
	my $w = $mdi->docGet($mdi->docSelected)->CWidg;

	#find starting point
	my $ins = $w->index('insert');
	my $start = $ins;
	while ((not exists $delimhash{$w->get("$start - 1c", $start)}) and (not $start =~ /\.0$/)) {
		$start = $w->index("$start - 1c");
	}
	
	#find end point
	my $end = $ins;
	my $lineend = $w->index("$end lineend");
	while ((not exists $delimhash{$w->get($end, "$end + 1c")}) and ($end ne $lineend)) {
		$end = $w->index("$end + 1c");
	}

	return ($start, $end);
}

sub getWidget {
	my $self = shift;
	my $mdi = $self->mdi;
	my $sel = $mdi->docSelected;
	return unless defined $sel;
	my $doc = $mdi->docGet($sel);
	return $doc->CWidg if defined $doc
}

sub getWord {
	my $self = shift;
	my $w = $self->getWidget;
	return undef unless defined $w;
	my $ins = $w->index('insert');
	my $line = $w->get("$ins linestart", $ins);
	if (($line =~ /([a-z0-9_]+)$/i) and (length($1) >= $self->PopSize)) {
		return $1;
	}
	return undef
}

sub MenuItems {
	my $self = shift;
	return (
      [ 'menu_check',  'Tools::Wrap',  'W~ord completion',    undef,   '-wordcompletion', undef, 0, 1],
      [ 'menu_normal', 'Tools::Wrap',  '~Configure word completion',   'wc_settings'],
	)
}

sub popDown {
	my $self = shift;
	my $pop = $self->_pop;
	return unless $pop->ismapped;
	$pop->withdraw;
	$pop->parent->grabRelease;
	$self->getWidget->focus();
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
}

sub PopSize {
	my $self = shift;
	$self->{POPSIZE} = shift if @_;
	return $self->{POPSIZE}
}

sub postChoices {
	my ($self, $name) = @_;
	return if $self->{POPBLOCK};
	$self->ScanStart($name);

	my $word = $self->getWord;
	my $doc = $self->getWidget;
	return unless defined $doc;
	return unless defined $word;
#	my $ins = $doc->index('insert');
	my @choices = $self->getChoices($name, $word);
	if (@choices) {
		my $lb = $self->_listbox;
		$lb->deleteAll;
		for (@choices) {
			$lb->add($_, -text => $_);
		}
		my @coord = $doc->bbox($doc->index('insert'));
		if (@coord) {
			#calculate position of the popup
			my $x = $coord[0] + $doc->rootx;
			my $y = $coord[1] + $coord[3] + $doc->rooty + 2;
		
			#calculate size of the popup
			my $longest = '';
			for (@choices) {
				$longest = $_ if length($_) > length($longest);
			}
			my $font = $lb->cget('-font');
			my $width = $lb->fontMeasure($font, $longest) + 10;

			my $size = $lb->fontActual($font, '-size');
			my $lineheight = int(abs($size) * 1.60);

			my $items = @choices;
			my $height = ($items * $lineheight) + 2;
			
			#pop this thing
			my $pop = $self->_pop;
			unless ($pop->ismapped) {
				$pop->geometry($width . "x$height+$x+$y");
				$pop->deiconify;
				$pop->raise;
				$self->{'_BE_grabinfo'} = $self->grabSave;
				$pop->parent->grabGlobal;
#				$lb->selectionSet($choices[0]);
				$lb->focus;
				$self->after(50, sub { $lb->eventGenerate('<Down>') });
			}
		}
	}
}

sub scan {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	
	unless ($self->configGet('-wordcompletion')) {
		$self->ScanEnd($name);
		return
	}
	
	my $doc_h = $self->mdi->docGet($name);
	return unless defined $doc_h;
	my $doc = $doc_h->CWidg;
	my $end = $doc->linenumber('end - 1c');
	my $count = 0;
	my $line = $self->_pool->{$name}->{'line'};
	$line = 1 unless defined $line;
	my $data = $self->_pool->{$name}->{'data'};
	while ($count < 100) {
		#end job if done
		if ($line > $end) {
			$self->_pool->{$name}->{'line'} = 1;
			$self->ScanEnd($name);
			return
		}

		#skip line if it holds the insert cursor;
		my $insline = $doc->linenumber($doc->index('insert'));
		if ($insline eq $line) {
			$line ++;
			$count ++;
			next
		}

		#scan line
		my $content = $doc->get("$line.0", "$line.0 lineend");
		while ($content ne '') {
			if ($content =~ s/^([a-z0-9_]+)//i) {
				my $word = $1;
				if (length($word) >= $self->ScanSize) {
					$data->{$word} = 1;
				}
			} else {
				$content =~ s/^.//;
			}
		}

		$line++;
		$count ++;
	}
	$self->_pool->{$name}->{'line'} = $line;
}

sub ScanEnd {
	my ($self, $name) = @_;
	if ($self->jobExists($name)) {
		$self->jobEnd($name);
		my $data = $self->_pool->{$name}->{'data'};
		if (defined $data) {
			for (keys %$data) {
				delete $data->{$_} if $data->{$_} eq 0;
			}
		}
	}
}

sub ScanSize {
	my $self = shift;
	$self->{SCANSIZE} = shift if @_;
	return $self->{SCANSIZE}
}

sub ScanStart {
	my ($self, $name) = @_;
	unless ($self->jobExists($name)) {
		$self->jobStart($name, 'scan', $self, $name);
		my $data = $self->_pool->{$name}->{'data'};
		if (defined $data) {
			for (keys %$data) {
				$data->{$_} = 0;
			}
		}
	}	
}

sub Select {
	my $self = shift;
	$self->popDown;
	my $w = $self->getWidget;
	my ( $select ) = $self->_listbox->infoSelection;
	return unless defined $select;
	my ($start, $end) = $self->getIndexes;
	
	#replace with select
	$self->{POPBLOCK} = 1;
	$w->delete($start, $end);
	$w->insert($start, $select);
	$self->{POPBLOCK} = 0;
}

sub TriggerWord {
	my $self = shift;
	$self->{TRIGGERWORD} = shift if @_;
	return $self->{TRIGGERWORD}
}

sub Unload {
	my $self = shift;
	$self->cmdUnhookBefore('deferred_open', 'docOpen', $self);
	$self->cmdUnhookAfter('modified', 'activate', $self);
	$self->cmdUnhookAfter('doc_close', 'docClose', $self);
	$self->configRemove('-wordcompletion');
	$self->cmdRemove('wc_settings');

	my $bindsub = $self->{'bind_sub'};
	if (defined $bindsub) { #not ideal but should be unproblematic
		$self->bind('<Button-1>', sub { $bindsub->Call })
	} else {
		$self->bind('<Button-1>', sub { })
	}

	$self->_pop->destroy;

	return $self->SUPER::Unload;
}

sub wordcompletion {
	my $self = shift;
	$self->{WORDCOMPLETION} = shift if @_;
	return $self->{WORDCOMPLETION}
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


