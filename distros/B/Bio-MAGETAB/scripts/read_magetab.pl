#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: read_magetab.pl 333 2010-06-02 16:41:31Z tfrayner $


# This is a very simplistic example script to illustrate how one might
# use the Reader modules to parse a MAGE-TAB document into
# Bio::MAGETAB objects in memory or in a database, and generate an
# output GraphViz visualization.

use strict;
use warnings;

use Getopt::Long;
use File::Path;

use Bio::MAGETAB::Util::Reader;
use Bio::MAGETAB::Util::Writer::GraphViz;

my ( $idf,
     $is_relaxed,
     $ignore_datafiles,
     $authority,
     $namespace,
     $want_help,
     $want_version,
     $graph_file,
     $dsn,
     $write );

GetOptions(
    "i|idf=s"       => \$idf,
    "a|authority=s" => \$authority,
    "n|namespace=s" => \$namespace,
    "r|relaxed"     => \$is_relaxed,
    "x|ignore-data" => \$ignore_datafiles,
    "g|graph=s"     => \$graph_file,
    "d|dsn=s"       => \$dsn,
    "w|write=s"     => \$write,
    "h|help"        => \$want_help,
    "v|version"     => \$want_version,
);

if ( $want_help || ! ($idf && -r $idf) ) {

    print (<<"USAGE");

 Usage: read_magetab.pl -i <IDF file>

 Options:

    -r :   Use "relaxed" parsing, where undeclared objects are created for you on the fly.
    -x :   Do not attempt to parse any data files listed in the SDRF (specifically, data matrices).
    -n :   Use the specified namespace string.
    -a :   Use the specified authority string.
    -g :   Filename to use for SDRF graph output using GraphViz.
    -d :   DSN, or SQLite database file to load the generated objects into.
    -w :   Attempt to round-trip the MAGE-TAB information by writing a new document
               to the specified directory.

    -v :   Print version information.
    -h :   Print this help.

USAGE

    exit 255;
}

if ( $want_version ) {
    print "This is Bio::MAGETAB::Util::Reader version $Bio::MAGETAB::Util::Reader::VERSION\n";
    exit 255;
}

$namespace ||= q{};
$authority ||= q{};

my $reader = Bio::MAGETAB::Util::Reader->new(
    idf              => $idf,
    relaxed_parser   => $is_relaxed,
    ignore_datafiles => $ignore_datafiles,
    namespace        => $namespace,
    authority        => $authority,
);

# If a database file was specified, dump the Investigation and all
# associated objects into a SQLite schema.
if ( $dsn ) {

    warn("Attempting to connect to database...\n");

    # We default to SQLite here for the sake of simplicity. In
    # principle, any database backend supported by Tangram should
    # work. NOTE that during testing, SQLite performance didn't scale
    # terribly well; MySQL worked better.
    require Bio::MAGETAB::Util::Persistence;
    require Bio::MAGETAB::Util::DBLoader;

    unless ( $dsn =~ /\A dbi:\w+:\w+ /ixms ) {
        $dsn = "dbi:SQLite:$dsn";
    }
    my $db = Bio::MAGETAB::Util::Persistence->new({
        dbparams => [ $dsn ],
    });

    # Connect to the database and dump the objects.
    $db->connect();

    my $builder = Bio::MAGETAB::Util::DBLoader->new({
        database  => $db,
        namespace => $namespace,
        authority => $authority,
    });

    $reader->set_builder( $builder );
}

# Parse the IDF and any associated SDRFs/ADFs.
warn("Parsing MAGE-TAB document...\n");
my ( $inv, $magetab ) = $reader->parse();

# If a graph file was specified, attempt to use GraphViz to draw the
# experimental design graph.
if ( $graph_file ) {

    warn("Attempting to generate a graph visualisation...\n");

    open ( my $fh, '>', $graph_file )
        or die("Error: Unable to open output file: $!");

    my $writer = Bio::MAGETAB::Util::Writer::GraphViz->new({
        sdrfs => [ $inv->get_sdrfs() ],
    });

    my $g = $writer->draw();

    print $fh $g->as_png();
}

if ( $write ) {

    warn("Attempting to write out a new set of MAGE-TAB documents...\n");

    require Bio::MAGETAB::Util::Writer;

    mkpath( $write );
    chdir( $write );

    my $writer = Bio::MAGETAB::Util::Writer->new({
        magetab => $magetab,
    });
 
    $writer->write();
}

warn("Done.\n");
