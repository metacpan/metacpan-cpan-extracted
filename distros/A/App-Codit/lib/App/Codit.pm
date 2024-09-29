package App::Codit;

=head1 NAME

App::Codit - IDE for and in Perl

=head1 DESCRIPTION

Codit is a versatile text editor / integrated development environment aimed at the Perl programming language.

It is written in Perl/Tk and based on the L<Tk::AppWindow> application framework.

It uses the L<Tk::CodeText> text widget for editing.

Codit has been under development for about one year now. It has gone quite some miles on our systems 
and can be considered beta software as of version 0.10.

It features a multi document interface that can hold an unlimited number of documents,
navigable through the tab bar at the top and a document list in the left side panel. 

It has a plugin system designed to invite users to write their own plugins.

It is fully configurable through a configuration window, allowing you to set defaults
for editing, the graphical user interface, syntax highlighting and (un)loading plugins.

L<Tk::CodeText> offers syntax highlighting and code folding in plenty formats and languages.
It has and advanced word based undo/redo stack that keeps track of selections and save points.
It does auto indent, bookmarks, comment, uncomment, indent and unindent. Tab size and indent style are
fully user configurable.

=head1 RUNNING CODIT

You can launch Codit from the command line as follows:

 codit [options] [files]

The following command line options are available:

=over 4

=item I<-c> or I<-config>

Specifies the configfolder to use. If the path does not exist it will be created.

=item I<-h> or I<-help>

Displays a help message on the command line and exits.

=item I<-i> or I<-iconpath>

Point to the folders where your icon libraries are located.*

=item I<-t> or I<-icontheme>

Icon theme to load.

=item I<-P> or I<-noplugins>

Launch without any plugins loaded. This supersedes the -plugins option.

=item I<-p> or I<-plugins>

Launch with only these plugins .*

=item I<-s> or I<-session>

Loads a session at launch. The plugin Sessions must be loaded for this to work.

=item I<-y> or I<-syntax>

Specify the default syntax to use for syntax highlighting. Codit will determine the syntax 
of documents by their extension. This options comes in handy when the file you are 
loading does not have an extension.

=item I<-v> or I<-version>

Displays the version number on the command line and exits.

=back

* You can specify a list of items by separating them with a ':'.

=head1 TROUBLESHOOTING

Just hoping you never need this.

=head2 General troubleshooting

If you encounter problems and error messages using Codit here are some general troubleshooting steps:

=over 4

=item Use the -config command line option to point to a new, preferably fresh settingsfolder.

=item Use the -noplugins command line option to launch Codit without any plugins loaded.

=item Use the -plugins command line option to launch Codit with only the plugins loaded you specify here.

=back

=head2 No icons

If Codit launches without any icons do one or more of the following:

=over 4

=item Check if your icon theme is based on scalable vectors. Install Icons::LibRSVG if so. See also the Readme.md that comes with this distribution.

=item Locate where your icons are located on your system and use the -iconpath command line option to point there.

=item Select an icon library by using the -icontheme command line option.

=back

=head2 Session will not load

Sometimes it happens that a session file gets corrupted. You solve it like this:

=over 4

=item Launch the session manager. Menu->Session->Manage sessions.

=item Remove the affected session.

=item Rebuild it from scratch.

=back

Sorry, that is all we have to offer.

=head3 Report a bug

If all fails you are welcome to open a ticket here: L<https://github.com/haje61/App-Codit/issues>.

=head1 BASECLASSES

Codit comes with the base class L<App::Codit::BaseClasses::TextModPlugin>. It is used by several
plugins. You can use it to define your own plugin.

=head1 EXTENSIONS

Codit uses the following extensions from L<Tk::AppWindow>:

=over 4

=item B<Art> see L<Tk::AppWindow::Ext::Art>

=item B<ConfigFolder> see L<Tk::AppWindow::Ext::ConfigFolder>

=item B<Daemons> see L<Tk::AppWindow::Ext::Daemons>

=item B<Help> see L<Tk::AppWindow::Ext::Help>

=item B<Keyboard> see L<Tk::AppWindow::Ext::Keyboard>

=item B<MenuBar> see L<Tk::AppWindow::Ext::MenuBar>

=item B<Navigator> see L<Tk::AppWindow::Ext::Navigator>

=item B<NavigatorPanel> see L<Tk::AppWindow::Ext::NavigatorPanel>

=item B<Panels> see L<Tk::AppWindow::Ext::Panels>

=item B<Plugins> see L<Tk::AppWindow::Ext::Plugins>

=item B<Settings> see L<Tk::AppWindow::Ext::Settings>

=item B<SideBars> see L<Tk::AppWindow::Ext::SideBars>

=item B<StatusBar> see L<Tk::AppWindow::Ext::StatusBar>

=item B<ToolBar> see L<Tk::AppWindow::Ext::ToolBar>

=back

Codit has its own extension as multiple document interface.

=over 4

=item B<CoditMDI> see L<App::Codit::Ext::CoditMDI>

=back

=head1 PLUGINS

Codit comes with these plugins:

=over 4

=item B<Backups> see L<App::Codit::Plugins::Backups>

=item B<Bookmarks> see L<App::Codit::Plugins::Bookmarks>

=item B<Colors> see L<App::Codit::Plugins::Colors>

=item B<Console> see L<App::Codit::Plugins::Console>

=item B<FileBrowser> see L<App::Codit::Plugins::FileBrowser>

=item B<Git> see L<App::Codit::Plugins::Git>

=item B<PerlSubs> see L<App::Codit::Plugins::PerlSubs>

=item B<PodViewer> see L<App::Codit::Plugins::PodViewer>

=item B<SearchReplace> see L<App::Codit::Plugins::SearchReplace>

=item B<Sessions> see L<App::Codit::Plugins::Sessions>

=item B<Snippets> see L<App::Codit::Plugins::Snippets>

=item B<WordCompletion> see L<App::Codit::Plugins::WordCompletion>

=back

=head1 CONFIG VARIABLES

Codit defines one config variable.

=over 4

=item Switch B<-uniqueinstance>

Boolean flag. Default value 0. If set only this instance is used
for opening files through the command line.

=back

=head1 METHODS

B<App::Codit> inherits L<Tk::AppWindow> and all of its methods.

=over 4

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.10";
use Tk;
use App::Codit::CodeTextManager;

use base qw(Tk::Derived Tk::AppWindow);
Construct Tk::Widget 'Codit';

sub Populate {
	my ($self,$args) = @_;

	$self->geometry('800x600+150+150');

	my $rawdir = Tk::findINC('App/Codit/Icons');
	my %opts = (
#		-appname => 'Codit',
		-logo => Tk::findINC('App/Codit/codit_logo.png'),
		-extensions => [qw[Art CoditMDI ToolBar StatusBar MenuBar Navigator Help Settings Plugins]],
		-preconfig => [
			-uniqueinstance => ['METHOD', undef, undef, 0],
		],
		-documentinterface => 'CoditMDI',
		-namespace => 'App::Codit',
		-rawiconpath => [ $rawdir ],
		-savegeometry => 1,
		-updatesmenuitem => 1,

		-panellayout => [
			CENTER => {
				-in => 'MAIN',
				-side => 'top',
				-fill => 'both',
				-expand => 1,
			},
			SUBCENTER => {
				-in => 'CENTER',
				-side => 'left',
				-fill => 'both',
				-expand => 1,
			},
			WORK => {
				-in => 'SUBCENTER',
				-side => 'top',
				-fill => 'both',
				-expand => 1,
			},
			TOOL => {
				-in => 'SUBCENTER',
				-after => 'WORK',
				-side => 'top',
				-fill => 'x',
#				-expand => 1,
				-canhide => 1,
				-paneloptions => [-height => 150],
				-adjuster => 'bottom',
			},
			TOP => {
				-in => 'MAIN',
				-side => 'top',
				-before => 'CENTER',
				-fill => 'x',
				-canhide => 1,
			},
			BOTTOM => {
				-in => 'MAIN',
				-after => 'CENTER',
				-side => 'top',
				-fill => 'x',
				-canhide => 1,
			},
			LEFT => {
				-in => 'CENTER',
				-before => 'SUBCENTER',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-paneloptions => [-width => 150],
				-adjuster => 'left',
			},
			RIGHT => {
				-in => 'CENTER',
				-after => 'SUBCENTER',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-paneloptions => [-width => 150],
				-adjuster => 'right',
			},
		
		],

		-aboutinfo => {
			author => 'Hans Jeuken',
			components => [
				'FreeDesktop::Icons',
				'Imager',
				'Syntax::Kamelon', 
				'Tk', 
				'Tk::AppWindow', 
				'Tk::CodeText',
				'Tk::ColorEntry',
				'Tk::DocumentTree',
				'Tk::FileBrowser',
				'Tk::PodViewer',
				'Tk::QuickForm',
				'Tk::Terminal',
				'Tk::YADialog',
				'Tk::YANoteBook',
			],
			http => 'https://github.com/haje61/App-Codit',
		},
		-helpfile => 'http://www.perlgui.org/wp-content/uploads/2024/09/manual-0.10.pdf',

		-contentmanagerclass => 'CodeTextManager',
		-contentmanageroptions => [
			'-contentautoindent', 
			'-contentbackground',
			'-contentbgdspace',
			'-contentbgdtab',
			'-contentbookmarkcolor',
			'-contentfont', 
			'-contentforeground', 
			'-contentindent', 
			'-contentinsertbg', 
			'-contentmatchbg', 
			'-contentmatchfg', 
			'-contentsyntax', 
			'-contenttabs', 
			'-contentwrap',
			'-showfolds',
			'-shownumbers',
			'-showstatus',
			'-highlight_themefile',
		],

		-contentautoindent => 1, 
		-contentindent => 'tab',
		-contenttabs => '8m',
		-contentwrap => 'none',
		-showfolds => 1,
		-shownumbers => 1,
		-showstatus => 1,

		-useroptions => [
			'*page' => 'Editing',
			'*section' => 'Editor settings',
			-contentfont => ['font', 'Font'],
			-contentautoindent => ['boolean', 'Auto indent'],
			-contentindent => ['text', 'Indent style', -regex => qr/^\d+|tab$/, -width => 4],
			-contenttabs => ['text', 'Tab size', -regex => qr/^\d+\.?\d*[c|i|m|p]$/, -width => 4],
			-contentwrap => ['radio', 'Wrap', -values => [qw[none char word]]],
			-doc_show_spaces => ['boolean', 'Show spaces'],
			'*end',
			'*section' => 'Show indicators',
			-showfolds => ['boolean', 'Fold indicators'],
			-shownumbers => ['boolean', 'Line numbers'],
			-showstatus => ['boolean', 'Doc status'],
			'*end',

			'*page' => 'Colors',
			'*section' => 'Editing',
			-contentforeground => ['color', 'Foreground', -width => 8],
			-contentbackground => ['color', 'Background', -width => 8],
			-contentinsertbg => ['color', 'Insert bg', -width => 8],
			'*end',
			'*section' => 'Spaces and tabs',
			-contentbgdspace => ['color', 'Space bg', -width => 8],
			-contentbgdtab => ['color', 'Tab bg', -width => 8],
			'*end',
			'*section' => 'Matching {}, [] and ()',
			-contentmatchfg => ['color', 'Foreground', -width => 8],
			-contentmatchbg => ['color', 'Background', -width => 8],
			'*end',
			'*section' => 'Bookmarks',
			-contentbookmarkcolor => ['color', 'Background', -width => 8],
			'*end',

			'*page' => 'GUI',
			'*section' => 'Icon sizes',
			-iconsize => ['spin', 'General', -width => 4],
			-sidebariconsize => ['spin', 'Side bars', -width => 4],
			'*column',
			-menuiconsize => ['spin', 'Menu bar', -width => 4],
			-tooliconsize => ['spin', 'Tool bar', -width => 4],
			'*end',
			'*section' => 'Visibility at lauch',
			'-tool barvisible' => ['boolean', 'Tool bar'],
			'-status barvisible' => ['boolean', 'Status bar'],
			'*column',
			'-navigator panelvisible' => ['boolean', 'Navigator panel'],
			'*end',
			'*section' => 'Geometry',
			-savegeometry => ['boolean', 'Save on exit',],
			'*end',
			'*section' => 'Unique instance',
			-uniqueinstance => ['boolean', 'Unique', -onvalue => 1, -offvalue => 0],
			'*end',
			'*section' => 'Tool bar',
			-tooltextposition => ['radio', 'Text position', -values => [qw[none left right top bottom]]],
			'*end',
		],
	);
	for (keys %opts) {
		$args->{$_} = $opts{$_}
	}
	$self->SUPER::Populate($args);
	
	$self->{UNIQUE} = 0;

	$self->extGet('Panels')->panelHide('TOOL');
	$self->extGet('Panels')->panelHide('RIGHT');

	$self->addPostConfig('DoPostConfig', $self);
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

=item B<abbreviate>I<($string, ?$size?, ?$firstsize?)>

Shortens $string to $size by leaving out a middle part. Then returns it.
$size is set to 30 unless you specify it. $firstsize is set to 25% of $size
unless you set it.

=cut

sub abbreviate {
	my ($self, $string, $size, $firstsize) = @_;
	$size = 30 unless defined $size;
	$firstsize = int($size / 4) unless defined $firstsize;
	my $length = length($string);
	if ($length > $size) {
		my $first = substr($string, 0, $firstsize) . ' ... ';
		my $lastsize = $size - $firstsize - 5;
		my $last = substr($string, $length - $lastsize, $lastsize);
		$string = $first . $last;
	} 
	return $string;
}

sub CanQuit {
	my $self = shift;
	my $file = $self->lockfile;
	unlink $file if defined $file;
	return $self->SUPER::CanQuit
}

sub DoPostConfig {
	my $self = shift;
	$self->SetThemeFile;
	$self->cmdExecute('doc_new');
#	$self->mdi->createContextMenu;
}

sub GetThemeFile {
	return $_[0]->extGet('ConfigFolder')->ConfigFolder .'/highlight_theme.ctt';
}

sub lockfile {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/lockfile';
	return $file if -e $file;
	return undef
}

sub lockModified {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/lockfile';
	if (-e $file) {
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
		my $lmod = $self->{LOCKMODIFIED};
		return $lmod ne $mtime if defined $lmod;
	}
	return ''
}

sub lockReset {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/lockfile';
	if (open(LOUT, '>', $file)) {
		print LOUT "\n";
		close LOUT
	}
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);
	$self->{LOCKMODIFIED} = $mtime;
}

sub lockScan {
	my $self = shift;
	return unless $self->lockModified;
	$self->deiconify unless $self->ismapped;
	$self->raise;
	$self->focus;
	if (my $file = $self->lockfile) {
		if (open(LIN, '<', $file)) {
			while (<LIN>) {
				my $line = $_;
				chomp $line;
				$self->cmdExecute('doc_open', $line) if -e $line
			}
#			close LIN;
			$self->lockReset;
		}
	}
}

=item B<mdi>

Returns a reference to the CoditMDI extension.

=cut

sub mdi {
	return $_[0]->extGet('CoditMDI');
}

=item B<panels>

Returns a reference to the Panels extension.

=cut

sub panels {
	return $_[0]->extGet('Panels');
}

sub SetThemeFile {
	my $self = shift;
	my $themefile = $self->GetThemeFile;
	$self->SetDefaultTheme unless -e $themefile;
	$self->configPut(-highlight_themefile => $themefile);
}

sub SetDefaultTheme {
	my $self = shift;
	my $themefile = $self->GetThemeFile;
	my $default = Tk::findINC('App/Codit/highlight_theme.ctt');
	my $theme = Tk::CodeText::Theme->new;
	$theme->load($default);
	$theme->save($themefile);
}

=item B<sidebars>

Returns a reference to the SideBars extension.

=cut

sub sidebars {
	return $_[0]->extGet('SideBars');
}

sub ToolBottomBookAdd {
	my $self = shift;
	return if $self->ToolBottomBookExists;
	my $sb = $self->sidebars;
	$sb->nbAdd('tool panel bottom', 'TOOL', 'bottom');
	$sb->nbTextSide('tool panel bottom', 'right');
	$self->panels->panelShow('TOOL')
}

sub ToolBottomBookExists {
	my $self = shift;
	return $self->sidebars->nbExists('tool panel bottom');
}

sub ToolBottomBookRemove {
	my $self = shift;
	return unless $self->ToolBottomBookExists;
	$self->sidebars->nbDelete('tool panel bottom');
	$self->panels->panelHide('TOOL');
}

=item B<ToolBottomPageAdd>I<($name, $image, $text, $statustext, $initialsize)>

See also the B<pageAdd> method in L<Tk::AppWindow::Ext::SideBars>.
Adds a new page to the tool panel at the bottom of the CENTER window.
Creates the notebook widget if it does not exists.

=cut

sub ToolBottomPageAdd {
	my $self = shift;
	$self->ToolBottomBookAdd;
	return $self->sidebars->pageAdd('tool panel bottom', @_);
}

=item B<ToolBottomPageRemove>I<($name)>

See also the B<pageDelete> method in L<Tk::AppWindow::Ext::SideBars>.
Removes page $name from the tool panel at the bottom of the CENTER window.
Removes the notebook widget if it holds no more entries.

=cut

sub ToolBottomPageRemove {
	my ($self, $page) = @_;
	my $sb = $self->sidebars;
	$self->sidebars->pageDelete('tool panel bottom', $page);
	$self->ToolBottomBookRemove unless $sb->pageCount('tool panel bottom');
}

sub ToolRightBookAdd {
	my $self = shift;
	return if $self->ToolRightBookExists;
	my $sb = $self->sidebars;
	$sb->nbAdd('tool panel right', 'RIGHT', 'right');
#	$sb->nbTextSide('tool panel bottom', 'right');
	$self->panels->panelShow('RIGHT')
}

sub ToolRightBookExists {
	my $self = shift;
	return $self->sidebars->nbExists('tool panel right');
}

sub ToolRightBookRemove {
	my $self = shift;
	return unless $self->ToolRightBookExists;
	$self->sidebars->nbDelete('tool panel right');
	$self->panels->panelHide('RIGHT');
}

=item B<ToolRightPageAdd>I<($notebook, $name, $image, $text, $statustext, $initialsize)>

See also the B<pageAdd> method in L<Tk::AppWindow::Ext::SideBars>.
Adds a new page to the tool panel at the right of the application window.
Creates the notebook widget if it does not exists.

=cut

sub ToolRightPageAdd {
	my $self = shift;
	$self->ToolRightBookAdd;
	return $self->sidebars->pageAdd('tool panel right', @_);
}

=item B<ToolRightPageRemove>I<($page)>

See also the B<pageDelete> method in L<Tk::AppWindow::Ext::SideBars>.
Removes page $name from the tool panel at the right of the application window.
Removes the notebook widget if it holds no more entries.

=cut

sub ToolRightPageRemove {
	my ($self, $page) = @_;
	my $sb = $self->sidebars;
	$self->sidebars->pageDelete('tool panel right', $page);
	$self->ToolRightBookRemove unless $sb->pageCount('tool panel right');
}

sub uniqueinstance {
	my $self = shift;
	if (@_) {
		my $val = shift;
		my $file = $self->configGet('-configfolder') . '/lockfile';
		my $daem = $self->extGet('Daemons');
		my $job = 'codit_lock_scan';
		if ($val) {
			$self->after(100, sub { 
				$self->lockReset;
				$daem->jobAdd($job, 100, 'lockScan', $self) unless $daem->jobExists($job) 
			});
		} else {
			unlink $file;
			$daem->jobRemove($job) if $daem->jobExists($job);
		}
		$self->{UNIQUE} = $val;
	}
	return $self->{UNIQUE}
}

=back

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)
=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::OverView>

=item L<Tk::AppWindow::CookBook>

=item L<Tk::AppWindow::Ext::MDI>

=item L<Tk::AppWindow::Ext::Plugins>

=item L<App::Codit::Ext::CoditMDI>

=back

=cut

1;


















