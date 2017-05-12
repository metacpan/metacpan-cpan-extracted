# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-31 16:04 (EDT)
# Function: store file data
#
# $Id$

package AC::Yenta::Store::File;
use AC::Yenta::Debug 'store_file';

use File::Path;
use strict;

sub new {
    my $class = shift;
    my $name  = shift;
    my $conf  = shift;

    return bless {
        name	=> $name,
        conf	=> $conf,
    }, $class;
}

sub get {
    my $me   = shift;
    my $name = shift;

    my $cf   = $me->{conf};
    my $base = $cf->{basedir};
    return unless $base;
    my $filename = "$base/$name";

    my $f;
    unless( open($f, $filename) ){
        problem("cannot open file '$filename': $!");
        return;
    }

    local $/ = undef;
    my $content = <$f>;
    return \$content;
}

sub put {
    my $me   = shift;
    my $name = shift;
    my $cont = shift;	# reference

    # validate filename
    return if $name =~ m%(^\.\./)|(/\.\./)%;

    my $cf   = $me->{conf};
    my $base = $cf->{basedir};
    return 1 unless $base;

    # split name into dir / file
    my($dir, $file) = $name =~ m|(.*)/([^/]+)$|;

    # create directory
    debug("mkpath: $base/$dir");
    my $mask = umask 0;
    eval { mkpath("$base/$dir", undef, 0777); };
    umask $mask;

    # save file
    my $f;
    unless( open($f, "> $base/$name.tmp") ){
        problem("cannot save file '$base/$name.tmp': $!");
        return;
    }

    debug("saving file '$base/$name'");
    print $f $$cont;
    close $f;
    rename "$base/$name.tmp", "$base/$name";

    return 1;
}


1;
