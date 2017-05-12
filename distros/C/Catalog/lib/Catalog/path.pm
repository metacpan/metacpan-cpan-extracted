#
#   Copyright (C) 1999 Loic Dachary
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
# 
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/path.pm,v 1.4 1999/09/07 14:48:04 loic Exp $
#
# 
package Catalog::path;
use strict;
use vars qw(@EXPORT_OK @ISA);

require Exporter;

use MD5;
use Carp;

use Catalog::tools::tools;

@ISA = qw(Exporter);
@EXPORT_OK = qw(&path_simplify_component &path_simplify_path);

#
# Mandatory
# name : name of the catalog
# root : id of the catalog root
# url : base location of catalog
# db : DBI database pointer
# either pathname or id or path
#
# Optional
# path : comma separated list of id
# pathname : readable path name
# id : id of category
#
sub new {
    my($type, %args) = @_;

    my($self) = \%args;
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    error("missing url") if(!defined($self->{'url'}));
    error("missing name") if(!defined($self->{'name'}));
    error("missing db") if(!defined($self->{'db'}));
    error("missing root") if(!defined($self->{'root'}));

    my($key);
    foreach $key (qw(pathname path id)) {
	$self->{$key} = undef if(!$self->{$key});
    }
}

sub fill {
    my($self) = @_;
    my($db) = $self->{'db'};

    return if($self->{'filled'});

    my($row);
    if(defined($self->{'id'})) {
	$row = $db->exec_select_one("select * from catalog_path_$self->{'name'} where id = $self->{'id'}");
    } elsif(defined($self->{'pathname'})) {
	my($md5) = MD5->hexhash($self->{'pathname'});
	$row = $db->exec_select_one("select * from catalog_path_$self->{'name'} where md5 = '$md5'");
	
    } elsif(defined($self->{'path'})) {
	my($id) = $self->{'path'} =~ /(\d+)$/;
	$row = $db->exec_select_one("select * from catalog_path_$self->{'name'} where id = $id");
    } else {
	my($id) = $self->{'root'};
	$row = $db->exec_select_one("select * from catalog_path_$self->{'name'} where id = $id");
    }
    error("no row found") if(!defined($row));

    my($key);
    foreach $key (qw(pathname path id)) {
	$self->{$key} = $row->{$key};
    }

    $self->{'path'} =~ s/^,(.*),$/$1/;

    $self->{'filled'} = 1;
}

sub fashion {
    my($self) = @_;
    return $self->{'fashion'};
}

sub name {
    my($self) = @_;
    return $self->{'name'};
}

sub root {
    my($self) = @_;
    return $self->{'root'};
}

sub db {
    my($self) = @_;
    return $self->{'db'};
}

sub path {
    my($self) = @_;
    $self->fill() if(!defined($self->{'path'}));
    return $self->{'path'};
}

sub path_array {
    my($self) = @_;
    return split(',', $self->path());
}

sub pathname {
    my($self) = @_;
    $self->fill() if(!defined($self->{'pathname'}));
    return $self->{'pathname'};
}

sub pathname_array {
    my($self) = @_;

    return split('/', substr($self->pathname(), 1, -1));
}

sub id {
    my($self) = @_;
    $self->fill() if(!defined($self->{'id'}));
    return $self->{'id'};
}

sub pathname_file {
    my($self) = @_;

    return path_simplify_pathname($self->pathname());
}

sub pathname_file_array {
    my($self) = @_;

    return map { path_simplify_component($_) } $self->pathname_array();
}

sub pathname_html_array {
    my($self) = @_;

    my($fashion) = $self->{'fashion'};

    my(%params) = (
		   'root_label' => 'root',
		   'separator' => ':',
		   'last_link' => undef,
		   'root_constant' => undef,
		   );
    my($key);
    foreach $key (qw(root_label separator last_link root_constant)) {
	my($param);
	if(defined($self->{"path_$key"})) {
	    if(ref($self->{"path_$key"})) {
		$param = $self->{"path_$key"}->{$self->{'name'}};
	    } else {
		$param = $self->{"path_$key"};
	    }
	}
	$params{$key} = $param if(defined($param));
    }

    my(@html);
    my($url) = $self->{'url'};
    if($fashion eq 'intuitive') {
	push(@html, "<a href=$url/>$params{'root_label'}</a>$params{'separator'}") if(!defined($params{'root_constant'}));

	my($new_path) = '/';
	my(@names) = $self->pathname_array();
	my($count) = scalar(@names);
	my($i) = 1;
	my($name);
	foreach $name (@names) {
	    my($printed_name) = $name;
	    $printed_name =~ s/_/ /go;
	    $new_path .= "$name/";
	    if($i >= $count && !defined($params{'last_link'})) {
		push(@html, "$printed_name");
	    } else {
		push(@html, "<a href=$url$new_path>$printed_name</a>$params{'separator'}");
	    }
	    $i++;
	}
    } else {
	push(@html, "<a href=$url&id=$self->{'root'}>$params{'root_label'}</a>$params{'separator'}") if(!defined($params{'root_constant'}));;

	my($path) = $self->path();
	#
	# Root has no path at all, do nothing
	#
	if($path) {
	    my($rows) = $self->{'db'}->exec_select("select rowid,name from catalog_category_$self->{'name'} where rowid in ( $path )");
	    $rows = { map { $_->{'rowid'} => $_ } @$rows };

	    my($new_path) = '';
	    my($rowid);
	    my(@path) = split(',', $path);
	    my($last) = $path[$#path];
	    foreach $rowid (@path) {
		my($row) = $rows->{$rowid};
		$new_path .= "$rowid";
		if($rowid eq $last  && !defined($params{'last_link'})) {
		    push(@html, "$row->{'name'}");
		} else {
		    push(@html, "<a href=$url&id=$row->{'rowid'}&path=$new_path>$row->{'name'}</a>$params{'separator'}");
		}
		$new_path .= ",";
	    }
	}
    }

    return @html;
}

sub path_text_array {
    my($self) = @_;

    my(%params) = (
		   'root_label' => 'root',
		   );

    my($key);
    foreach $key (qw(root_label)) {
	my($param);
	if(defined($self->{"path_$key"})) {
	    if(ref($self->{"path_$key"})) {
		$param = $self->{"path_$key"}->{$self->{'name'}};
	    } else {
		$param = $self->{"path_$key"};
	    }
	}
	$params{$key} = $param if(defined($param));
    }

    my(@text) = $params{'root_label'};
    
    my($path) = $self->path();
    #
    # Root has no path at all, do nothing
    #
    if($path) {
	my($rows) = $self->{'db'}->exec_select("select rowid,name from catalog_category_$self->{'name'} where rowid in ( $path )");
	my(%rowid2name) = map { $_->{'rowid'} => $_->{'name'} } @$rows;
	push(@text, map { $rowid2name{$_} } split(',', $path));
    }

    return @text;
}

sub pathname_html {
    my($self) = @_;

    return join('', $self->pathname_html_array());
}

sub ptemplate_set {
    my($self, $template) = @_;

    my($assoc) = $template->{'assoc'};

    my($skip) = 1;
    my(%todo);
    my($tag);
    foreach $tag (keys(%$assoc)) {
	if($tag =~ /^_PATH(.*)_$/o) {
	    my($spec) = $1;
	    if($spec eq '' || $spec =~ /^\d+$/o) {
		$todo{'path'} = 1;
		$skip = 0;
	    } elsif($spec =~ /^FILE/o) {
		$todo{'pathfile'} = 1;
		$skip = 0;
	    } elsif($spec =~ /^TEXT/o) {
		$todo{'pathtext'} = 1;
		$skip = 0;
	    }
	}
    }

    #
    # Stop there if nothing to be done
    #
    return if($skip);

    my(@path);
    @path = $self->pathname_html_array() if($todo{'path'});
    my(@pathfile);
    @pathfile = $self->pathname_array() if($todo{'pathfile'});
    my(@pathtext);
    @pathtext = $self->path_text_array() if($todo{'pathtext'});

    foreach $tag (keys(%$assoc)) {
	if($tag =~ /^_PATH(.*)_$/) {
	    my($spec) = $1;
	    if($spec eq '') {
		template_set($assoc, $tag, join('', @path));
	    } elsif($spec =~ /^(\d+)$/) {
		my($index) = $1;
		template_set($assoc, $tag, $path[$index]) if(defined($path[$index]));
	    } elsif($spec =~ /^FILE$/) {
		template_set($assoc, $tag, join('_', @pathfile));
	    } elsif($spec =~ /^FILE(.*)$/) {
		my($index) = $1;
		if($index !~ /^\d+$/) {
		    $index =~ s/MINUS/-/g;
		    $index =~ s/DOTDOT/../g;
		    my(@list);
		    eval "\@list = \@pathfile[$index]";
		    croak("syntacticaly invalid range in $spec") if($@);
		    template_set($assoc, $tag, join('/', @list));
		} else {
		    template_set($assoc, $tag, $pathfile[$index]) if(defined($pathfile[$index]));
		}
	    } elsif($spec =~ /^TEXT$/) {
		template_set($assoc, $tag, join('/', @pathtext));
	    } elsif($spec =~ /^TEXT(.*)$/) {
		my($index) = $1;
		if($index !~ /^\d+$/) {
		    $index =~ s/MINUS/-/g;
		    $index =~ s/DOTDOT/../g;
		    my(@list);
		    eval "\@list = \@pathtext[$index]";
		    croak("syntacticaly invalid range in $spec") if($@);
		    template_set($assoc, $tag, join('/', @list));
		} else {
		    template_set($assoc, $tag, $pathtext[$index]) if(defined($pathtext[$index]));
		}
	    }
	}
    }
}

sub path_simplify_component {
    my($string) = @_;

    $string =~ s/[ \'\"]/_/og;
    return $string;
}

sub path_simplify_pathname {
    my($string) = @_;

    $string =~ s|[ \'\"/]|_|og;
    return $string;
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
