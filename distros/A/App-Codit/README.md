# App-Codit

Codit is a versatile text editor / integrated development environment aimed 
at the Perl programming language.

It is written in Perl/Tk and based on the Tk::AppWindow application framework.

It uses the Tk::CodeText text widget for editing.

Codit has been under development for about one year now. And even though it is considered
alpha software, it already has gone quite some miles on our systems.

It features a multi document interface that can hold an unlimited number of documents,
navigable through the tab bar at the top and a document list in the left side panel. 

It has a plugin system designed to invite users to write their own plugins.

It is fully configurable through a configuration window, allowing you to set defaults for
editing, the graphical user interface, syntax highlighting and (un)loading plugins.

Tk::CodeText offers syntax highlighting and code folding in plenty formats and languages.
It has and advanced word based undo/redo stack that keeps track of selections and save points.
It does auto indent, comment, uncomment, indent and unindent. Tab size and indent style are
fully user configurable.

Enjoy playing!

# Requirements

The following Perl modules must be installed:

    * File::Path
    * Test::Tk
    * Tk
    * Tk::AppWindow
    * Tk::CodeText
    * Tk::FileBrowser
    * Tk::Terminal

# Installation

	perl Makefile.PL
	make
	make test
	sudo make install

After make you can do the following for visual inspection:

	perl -Mblib t/060-App-Codit-CoditTagsEditor.t show
	perl -Mblib t/100-App-Codit.t show
	perl -Mblib bin/codit

Unless you are running Windows, we strongly recommend you also install the Perl modules:

__Tk::GtkSettings__

Run the following commands each time you login;

	tkgtk
	xrdb .Xdefaults

This will make the look and feel of all your Tk applications conform to your desktop settings and helps Codit locate the correct icon library. The screenshots in this manual are taken from a KDE/Plasma desktop with the Golden Honey Oak color profile.

__Image::LibRSVG__

This will allow you to load vector graphics based themes like Breeze. We did not include it as a prerequisite since it does not respond well to unattended install. It requires the gnome library librsvg-2 and its development files to be installed.

# Running Codit

You can launch Codit from the command line as follows:
	codit [options] [files]
The following command line options are available:
    -c or -config
Specifies the configfolder to use. If the path does not exist it will be created.  
    -h or -help
Displays a help message on the command line and exits.

    -i or -iconpath
Point to the folders where your icon libraries are located. (1)

    -t or -icontheme
Icon theme to load.

    -P or -noplugins
Launch without any plugins loaded. This supersedes the -plugins option.

    -p or -plugins
Launch with only these plugins. (1)

    -s or -session
Loads a session at launch. The plugin Sessions must be loaded for this to work.

    -y or -syntax
Specify the default syntax to use for syntax highlighting. Codit will determine the syntax of documents by their extension. This options comes in handy when the file you are loading does not have an extension.

(1) You can specify a list of items by separating them with a ':'.

# Troubleshooting

Just hoping you never need this 

## General troubleshooting

If you encounter problems and error message using Codit, here are some general troubleshooting steps:
    • Use the -config command line option to point to a new, preferably fresh location.
    • Use the -noplugins command line option to launch Codit without any plugins loaded.
    • Use the -plugins command line option to launch Codit with only the plugins loaded you specify here.

## No icons

If Codit launches without any icons do one or more of the following:

Install __Icons::LibRSVG__. If your icon theme is a scalable vectors graphics theme, Codit is not able to load icons if you do not install this.

Locate where your icons are located on your system and use the __-iconpath__ command line option to point there.

Select a different icon library by using the __-icontheme__ option.

## Session will not load

Sometimes it happens that a session file gets corrupted. You solve it like this:

Launch the session manager. Main menu -> Session -> Manage sessions.

Remove the affected session.

Rebuild it from scratch.

Sorry, that is all we have to offer.

## Report a bug

If all fails you are welcome to open a ticket here: https://github.com/haje61/App-Codit/issues

