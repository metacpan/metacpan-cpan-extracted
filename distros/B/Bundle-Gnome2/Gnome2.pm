# $Id: Gnome2.pm,v 1.20 2005/10/04 12:16:43 jodrell Exp $
package Bundle::Gnome2;

$VERSION = '0.12';

__END__

=pod

=head1 NAME

Bundle::Gnome2 - A bundle to install all the Gtk2 and Gnome2 modules.

=head1 SYNOPSIS

C<# perl -MCPAN -e 'install Bundle::Gnome2'>

=head1 CONTENTS

ExtUtils::Depends		- Easily build XS extensions that depend on XS extensions

ExtUtils::PkgConfig		- simplistic interface to pkg-config

IO::Scalar			- IO:: interface for reading/writing a scalar

Locale::gettext			- message handling functions

Glib				- Perl wrappers for the GLib utility and Object libraries

Gtk2				- Perl interface to the 2.x series of the Gimp Toolkit library

Gtk2::Phat			- Perl interface to the Phat widget collection

Gtk2::SourceView		- Perl wrappers for the GtkSourceView widget  

Gtk2::Spell			- Bindings for GtkSpell with Gtk2

Gtk2::TrayIcon			- Perl interface to the EggTrayIcon library

Gtk2::TrayManager		- Perl bindings for EggTrayManager

Gtk::CV				- a fast gtk+ image viewer modeled after xv

Gtk2::Ex::Carp			- GTK+ friendly die() and warn() functions.

Gtk2::Ex::ComboBox		- A simple ComboBox with multiple selection capabilities.

Gtk2::Ex::Datasheet::DBI	- A module that automates the process of setting up a treeview tied to a DBI connection.

Gtk2::Ex::DBI			- A module that automates the process of tying data from a DBI datasource to widgets on a Glade-generated form

Gtk2::Ex::DBITableFilter	- A high level widget to present large amounts of data fetched using DBI. Also provides data filtering capabilities.

Gtk2::Ex::Dialogs		- Useful tools for Gnome2/Gtk2 Perl GUI design.

Gtk2::Ex::FormFactory		- Makes building complex GUI's easy

Gtk2::Ex::Geo			- A Perl Gtk2 widget for spatial data and a glue class for using it

Gtk2::Ex::Graph::GD		- A thin wrapper around the GD::Graph module.

Gtk2::Ex::ICal::Recur		- A widget for scheduling a recurring set of events.

Gtk2::Ex::PrintDialog		- a simple, pure Perl dialog for printing PostScript data in GTK+ applications.

Gtk2::Ex::PodViewer		- a Gtk2 widget for displaying Plain old Documentation (POD)

Gtk2::Ex::RecordsFilter		- A high level widget to browse reasonably large amounts of relational data and select a subset of records.

Gtk2::Ex::Simple::List		- A simple interface to Gtk2's complex MVC list widget

Gtk2::Ex::Simple::Menu		- A simple interface to Gtk2's ItemFactory for creating application menus

Gtk2::Ex::Simple::Tree		- A simple interface to Gtk2's complex MVC tree widget

Gtk2::Ex::Threads::DBI		- Achieving *asynchronous DBI like* functionality for gtk2-perl applications using perl ithreads.

Gtk2::Ex::TreeMaker		- A high level widget to represent a set of relational records in a hierarchical spreadsheet kinda display.

Gtk2::Ex::TreeMap		- Implementation of TreeMap.

Gtk2::Ex::Utils			- Extra Gtk2 Utilities for working with Gnome2/Gtk2 in Perl.

Gtk2::Ex::VolumeButton		- widget to control volume and similar values

Gtk2Fu				- GTK2 Forked Ultimate, a powerful layer on top of Gtk2.

Gtk2::GladeXML			- Perl wrappers for the Gtk2::GladeXML utilities

Gtk2::GladeXML::Simple		- A clean object-oriented interface to Gtk2::GladeXML

Gtk2::MozEmbed			- Perl interface to the Mozilla embedding widget

Gnome2::Canvas			- Perl interface to the Gnome Canvas

Gnome2::Dia			- Perl interface to the DiaCanvas2 library

Gnome2::GConf			- Perl wrappers for the GConf configuration engine

Gnome2				- Perl interface to the 2.x series of the GNOME libraries

Gnome2::Print			- Perl wrappers for the Gnome Print utilities

Gnome2::Rsvg			- Perl interface to the RSVG library

Gnome2::VFS			- Perl interface to the 2.x series of the GNOME VFS library

Gnome2::Vte			- Perl interface to the VTE library

Gnome2::Wnck			- Perl interface to the Window Navigator Construction Kit

X11::FreeDesktop::DesktopEntry	- Interface to Freedesktop.org .desktop files

=head1 DESCRIPTION

This module bundles together all the Perl libraries available for
developing applications using the 2.x series of Gtk+ and Gnome. As well
as the core toolkit libraries there are also extra widgets (like
Gtk2::PodViewer) and bindings for libraries including gtkspell and
libwnck.

=head1 IMPORTANT NOTE

Almost all the modules in this bundle are wrappers around C libraries -
naturally, you will have to have those libraries (and their development
headers) installed I<before> you try to install this bundle.

=head1 AUTHOR

Gavin Brown E<lt>F<gavin.brown@uk.com>E<gt>

=cut
