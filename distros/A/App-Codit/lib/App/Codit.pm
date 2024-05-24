package App::Codit;

=head1 NAME

App::Codit - IDE for and in Perl

=head1 DESCRIPTION

Codit is a versatile text editor / integrated development environment aimed at the Perl programming language.

It is written in Perl/Tk and based on the L<Tk::AppWindow> application framework.

It uses the L<Tk::CodeText> text widget for editing.

Codit has been under development for about one year now. And even though it is considered
alpha software, it already has gone quite some miles on our systems.

It features a multi document interface that can hold an unlimited number of documents,
navigable through the tab bar at the top and a document list in the left side panel. 

It has a plugin system designed to invite users to write their own plugins.

It is fully configurable through a configuration window, allowing you to set defaults
for editing, the graphical user interface, syntax highlighting and (un)loading plugins.

L<Tk::CodeText> offers syntax highlighting and code folding in plenty formats and languages.
It has and advanced word based undo/redo stack that keeps track of selections and save points.
It does auto indent, comment, uncomment, indent and unindent. Tab size and indent style are
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

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.04";
use Tk;
require App::Codit::CodeTextManager;

use base qw(Tk::Derived Tk::AppWindow);
Construct Tk::Widget 'Codit';

sub Populate {
	my ($self,$args) = @_;

	$self->geometry('800x600+150+150');

	my %opts = (
		-appname => 'Codit',
		-logo => Tk::findINC('App/Codit/codit_logo.png'),
		-extensions => [qw[Art Balloon CoditMDI ToolBar StatusBar MenuBar Navigator ToolPanel Help Settings Plugins]],
		-documentinterface => 'CoditMDI',
		-namespace => 'App::Codit',
		-savegeometry => 1,

		-aboutinfo => {
			version => $VERSION,
			author => 'Hans Jeuken',
			http => 'https://github.com/haje61/App-Codit',
			license => 'Same as Perl',
		},
		-helpfile => Tk::findINC('App/Codit/manual.pdf'),

		-contentmanagerclass => 'CodeTextManager',
		-contentmanageroptions => [
			'-contentautoindent', 
			'-contentbackground', 
			'-contentfont', 
			'-contentforeground', 
			'-contentindent', 
			'-contentsyntax', 
			'-contenttabs', 
			'-contentwrap',
#			'-contentxml',
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
			'*section' => 'Text',
			-contentforeground => ['color', 'Foreground'],
			-contentbackground => ['color', 'Background'],
			-contentfont => ['font', 'Font'],
			'*end',
			'*section' => 'Editor settings',
			-contentautoindent => ['boolean', 'Auto indent'],
			-contentindent => ['text', 'Indent style'],
			'*column',
			-contenttabs => ['text', 'Tab size'],
			-contentwrap => ['radio', 'Wrap', -values => [qw[none char word]]],
			'*end',
			'*section' => 'Show indicators',
			-showfolds => ['boolean', 'Fold indicators'],
			-shownumbers => ['boolean', 'Line numbers'],
			-showstatus => ['boolean', 'Doc status'],
			'*end',

			'*page' => 'GUI',
			'*section' => 'Icon sizes',
			-iconsize => ['spin', 'General'],
			-menuiconsize => ['spin', 'Menu bar'],
			-tooliconsize => ['spin', 'Tool bar'],
			'*column',
			-navigatorpaneliconsize => ['spin', 'Navigator panel'],
			-toolpaneliconsize => ['spin', 'Tool panel'],
			'*end',
			'*section' => 'Visibility at lauch',
			-toolbarvisible => ['boolean', 'Tool bar'],
			-statusbarvisible => ['boolean', 'Status bar'],
			'*column',
			-navigatorpanelvisible => ['boolean', 'Navigator panel'],
			-toolpanelvisible => ['boolean', 'Tool panel'],
			'*end',
			'*section' => 'Geometry',
			-savegeometry => ['boolean', 'Save on exit',],
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

	$self->addPostConfig('DoPostConfig', $self);
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub DoPostConfig {
	my $self = shift;
	$self->SetThemeFile;
	$self->cmdExecute('doc_new');
}

sub GetThemeFile {
	return $_[0]->extGet('ConfigFolder')->ConfigFolder .'/highlight_theme.ctt';
}

sub mdi {
	return $_[0]->extGet('CoditMDI');
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


















