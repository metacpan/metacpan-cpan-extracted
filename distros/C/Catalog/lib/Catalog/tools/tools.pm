#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
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
# $Header: /cvsroot/Catalog/Catalog/lib/Catalog/tools/tools.pm,v 1.21 2000/01/27 18:08:37 loic Exp $
#
# 
package Catalog::tools::tools;
use strict;
use vars qw(@ISA @EXPORT);

use Carp qw(cluck carp croak confess);
use Cwd;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(readfile writefile dbg error shell
	     config_load
	     istring locate_file
	     template_load template_build template_parse template_set
	     template_fill template_clean
	     ostring owrite oread
	     pager sortu
	     absolute_path cd cdp
	     unaccent_8859
	     );

sub dbg {
    my($message, $info) = @_;

    if(defined($::opt_verbose)) {
	if(defined($info)) {
	    if($info =~ /$::opt_verbose/o) {
		if(defined($::opt_error_stack)) {
		    cluck($message);
		} else {
		    warn($message);
		}
	    }
	} else {
	    if(defined($::opt_error_stack)) {
		cluck($message);
	    } else {
		warn($message);
	    }
	}
    }
}

sub error {
    my($message) = @_;

    if(defined($::opt_error_stack)) {
	confess($message);
    } else {
	croak($message);
    }
}

sub messages_load {
    my($base) = @_;

    if(!defined($Catalog::tools::tools::messages{$base})) {
	my($file) = locate_file($base, $ENV{'CONFIG_DIR'});
	if(!defined($file)) {
	    dbg("no messages file found in path " . ($ENV{'CONFIG_DIR'} || '') . " for $base", "message");
	} else {
	    my(%messages);
	    open(FILE, "<$file") or croak("cannot open $file for reading : $!");
	    messages_load_parse(\%messages);
	    close(FILE);
	    $Catalog::tools::tools::messages{$base} = \%messages;
	}
    }

    dbg("$base " . ostring($Catalog::tools::tools::messages{$base}), "messages");
    return $Catalog::tools::tools::messages{$base};
}

sub messages_load_parse {
    my($messages) = @_;

    my($current);
    while(<FILE>) {
	next if(/^\s*\#/o || /^\s*$/o);
	if(/^(\S.*?)\s*$/) {
	    $current = $1;
	    croak("duplicate message for $current") if(exists($messages->{$current}));
	    $messages->{$current} = '';
	}
	if(/^\s+(.*?)\s*$/) {
	    $messages->{$current} .= " " . $1;
	}
    }
}

sub istring {
    my($format, @params) = @_;

    my($messages) = messages_load("messages.conf");

    if(defined($messages) && exists($messages->{$format})) {
	$format = $messages->{$format};
    }

    return sprintf($format, @params);
}

#
# Utilities
#
sub readfile {
    my($file) = @_;

    open(FILE, "<$file") or croak("cannot open $file for reading : $!");
    local($/);
    undef($/);
    my($content);
    $content = <FILE>;
    close(FILE);
    return $content;
}

sub writefile {
    my($file, $content) = @_;

    open(FILE, ">$file") or croak("cannot open $file for writing : $!");
    print FILE $content;
    close(FILE);
}

#
# Given a path, relative or absolute, always return an absolute path
#
sub absolute_path {
    my($path) = @_;

    if($path =~ m;^/;) {
	return $path;
    } else {
	return getcwd() . "/$path";
    }
}

sub locate_file {
    my($file, $path) = @_;

    return $file if($file =~ m|^/|);

    my($found);

    my($dirs) = join(":", '.', ($path || ()), ($ENV{'DOCUMENT_ROOT'} || ()));
    my($dir);
#    warn("locate_file dirs = $dirs");
    foreach $dir (split(':', $dirs)) {
	my($try) = "$dir/$file";
	if(-f $try) {
	    $found = $try;
	    last;
	}
    }

    return $found;
}

sub config_load {
    my($base) = @_;

    my($file) = locate_file($base, $ENV{'CONFIG_DIR'});
    $file = getcwd() . "/$file" if(defined($file) && $file !~ /^\//);
    if(!defined($file)) {
	dbg("no config file found in path " . ($ENV{'CONFIG_DIR'} || '') . " for $base", "config");
    } elsif(!defined($Catalog::tools::tools::config{$file})) {
	my(%config);
	open(FILE, "<$file") or croak("cannot open $file for reading : $!");
	config_load_parse(\%config);
	close(FILE);
	$Catalog::tools::tools::config{$file} = \%config;
    }
    return defined($file) ? $Catalog::tools::tools::config{$file} : undef;
}

sub config_load_parse {
    my($config) = @_;

    while(<FILE>) {
	next if(/^\s*\#/o || /^\s*$/o);
	return if(/^\s*end\s*/io);
	if(/^\s*([\w_-]+)\s*$/) {
	    my($name) = $1;
	    $config->{$name} = {};
	    config_load_parse($config->{$name});
	} elsif(/^\s*([\S*]+?)\s*=\s*(.*?)\s*$/o) {
	    $config->{$1} = $2;
	}
    }
}

sub template_load {
    my($base, $defaults, $context) = @_;

    #
    # Change the base according to context, if any
    #
    if(defined($context)) {
	my($config) = config_load("templates.conf");
#	warn(ostring($config));
	my($style) = $config->{'style'};
	if(defined($style)) {
	    my($spec) = $style->{$context};
	    if(defined($spec) && exists($spec->{$base})) {
		$base = $spec->{$base};
	    }
	}
    }

    my($file) = template_file($base);

    if(!defined($file)) {
	return defined($defaults) ? $defaults->{$base} : undef;
    }

    #
    # Read in the whole file
    #
    my($content) = readfile($file);

    return template_parse($file, $content);
}

sub template_set {
    my($assoc, $key, $value) = @_;

    $assoc->{$key} = $value if(exists($assoc->{$key}));
}

sub template_parse {
    my($file, $content, $name) = @_;

    #
    # Extract subtemplates if any
    #
    my(%children);
    my @depth;
    while($content =~ /(<\!--\s*(start|end)\s+(\w+)\s*-->)/iog) {
	my($se,$subname) = ($2,$3);
	my $end = pos($content);
	my $len = length($1);
	if($se eq 'start') {
	    push(@depth,[$subname,$end,$len]);
	    next;
	}
	elsif(@depth) {
	    croak("template $file: missing end for $subname")
		unless ($subname eq $depth[-1]->[0]);
	    if(@depth > 1) {
	        pop @depth;
		next;
	    }
	}
	else {
	    croak("template $file: unexpected end for $subname");
	}
	my $start = $depth[0]->[1];
	my $sublen = $end - $len - $start;
	$children{$subname} = template_parse($file,
	            substr($content,$start,$sublen), $subname);
	my($tag) = '_SUBTEMPLATE' . $subname . '_';
	$start -=  $depth[0]->[2];
	substr($content,$start,$end-$start) = $tag;
	pos($content) = $start + length($tag);
	@depth = ();
    }

    #
    # Extract parameters if any
    #
    my(%params);
    my($params_re) = '<\!--\s*params\s+(.*?)\s*-->';
    if($content =~ /$params_re/io) {
	eval "package; \%params = ( $1 )";
	croak $@ if $@;	# or just warn? what's the policy?
    }
    
    #
    # Extract tag list
    #
    my(%assoc);
    while($content =~ /(_[0-9A-Z-]+_)/g) {
	my($tag) = $1;
	next if($tag =~ /^_SUBTEMPLATE/);
	$assoc{$tag} = undef;
    }
    
    return {
	'content' => $content,
	'assoc' => \%assoc,
	'children' => \%children,
	'params' => \%params,
	'filename' => $file,
	'name' => $name || 'whole',
    };
}

#
# The caller is expected to alter the structure returned
# by template_load in the following way:
#
# . put values in the tags specified in {'assoc'}
# . set the {'skip'} field if nothing is to be done
# . set the {'html'} field to replace the {'content'} before
#   tags replacement
#
# When template_build returns the structure has been restored to
# its old state, except for the skipped entries.
#
sub template_build {
    my($template) = @_;

    my($content) = template_fill(@_);
    template_clean(@_);

    my($include_root) = $ENV{'DOCUMENT_ROOT'} || '/etc/httpd/htdocs';
    
    #
    # Handle server includes directives recursively
    #
    while($content =~ /(<\!--\#include\s+virtual\s*=\s*\"[^\"]*\"-->)/i) {
	my($include) = $1;
	my($matched) = quotemeta($include);
	my($file) = $include =~ /virtual\s*=\s*\"([^\"]*)/;
	my($path) = "$include_root$file";
	my($included) = readfile($path);
	$content =~ s/$matched/$included/;
    }

    return $content;
}

sub template_fill {
    my($template, $parents) = @_;

    return "" if($template->{'skip'});

    if ($template->{params}->{pre_fill}) {
	my $sub = $template->{params}->{pre_fill};
	$template = eval { package ; &$sub($template, $parents||[]) };
	croak $@ if $@;	# or just warn? what's the policy?
	return "" if $template->{skip};
    }

    my($children) = $template->{'children'};
    my($assoc)    = $template->{'assoc'};
    my($html)     = defined($template->{'html'})
			? $template->{'html'}
			: $template->{'content'};

    while (my ($name,$value) = each %$children) {
	my($tag) = '_SUBTEMPLATE' . $name . '_';
	push @{ $parents ||= [] }, $template;
	my($sub_html) = template_fill($value, $parents);
	$html =~ s/$tag/$sub_html/g;
    }

    while (my ($key,$value) = each %$assoc) {
	$value = '' unless defined $value;
	$html =~ s/$key/$value/g;
    }

    if ($template->{params}->{post_fill}) {
	my $sub = $template->{params}->{post_fill};
	$html = eval { &$sub($template, $parents||[], $html) };
	croak $@ if $@;	# or just warn? what's the policy?
    }

    return $html;
}

sub template_clean {
    my($template) = @_;

    return if(exists($template->{'noclean'}));

    delete($template->{'skip'});
    delete($template->{'html'});

    my($children) = $template->{'children'};
    foreach my $child (values %$children) {
	template_clean($child);
    }

    my($assoc) = $template->{'assoc'};
    foreach my $key (keys %$assoc) {
	$assoc->{$key} = undef;
    }
}

sub template_file {
    my($file) = @_;

    return locate_file($file, $ENV{'TEMPLATESDIR'});
}

sub template_exists {
    my($file) = @_;

    return -r template_file($file);
}

sub oread {
    my($file) = @_;

    my($ref);

    my($content) = readfile($file);
    eval "\$ref = $content";
    if($@) {
	croak("eval from $file, got error $@");
    }
    return $ref;
}

sub owrite {
    my($file, $ref) = @_;

    open(OBJECT, ">$file") or croak("cannot open $file for writing $!\n");
    owrite_1($ref, 0, {});
    close(OBJECT);
}

sub owrite_1 {
    my($ref, $depth, $seen) = @_;

    my($margin) = "\t" x $depth;
    $depth++;
    if(!ref($ref)) {
	$ref =~ s/\'/\\\'/g;
	print OBJECT "${margin}'$ref'\n";
    } elsif(ref($ref) eq 'HASH' || scalar($ref) =~ /=HASH/) {
	if(scalar($ref) =~ /(.*)=HASH\((.*)\)/ || ( $::perltools::owrite_compact && scalar($ref) =~ /^(HASH)\((.*)\)/)) {
	    my($type, $object) = ($1, $2);
	    if($object) {
		if(!$seen->{$object}) {
		    $seen->{$object}++;
		    print OBJECT "${margin}object $type($object) follows\n";
		} else {
		    print OBJECT "${margin}(see object $type($object))\n";
		    return;
		}
	    }
	}
	if(!keys(%$ref)) {
	    print OBJECT "${margin}\{}\n";
	} else {
	    my($key, $value);
	    print OBJECT "\n${margin}\{\n";
	    while(($key, $value) = each(%$ref)) {
		owrite_1($key, $depth);
		print OBJECT "${margin}=>\n";
		owrite_1($value, $depth);
		print OBJECT "${margin},\n";
	    }
	    print OBJECT "${margin}\}\n";
	}
    } elsif(ref($ref) eq 'ARRAY') {
	my($value);
	print OBJECT "\n${margin}\[\n";
	foreach $value (@$ref) {
	    owrite_1($value, $depth);
	    print OBJECT "${margin},\n";
	}
	print OBJECT "${margin}\]\n";
    }
}

#
# Same semantic as the owrite function but return the string produced
# instead of writing it in a file.
#
sub ostring {
    my($ref) = @_;

    my($string);
    return ostring_1(\$string, $ref, 0);
}

sub ostring_1 {
    my($string, $ref, $depth) = @_;

    my($margin) = "\t" x $depth;
    $depth++;
    if(!ref($ref)) {
	if(defined($ref)) {
	    $ref =~ s/\'/\\\'/g;
	} else {
	    $ref = '';
	}
	$$string .= "${margin}'$ref'\n";
    } elsif(ref($ref) eq 'HASH') {
	if(!keys(%$ref)) {
	    $$string .= "${margin}\{}\n";
	} else {
	    my($key, $value);
	    $$string .= "\n${margin}\{\n";
	    while(($key, $value) = each(%$ref)) {
		ostring_1($string, $key, $depth);
		$$string .= "${margin}=>\n";
		ostring_1($string, $value, $depth);
		$$string .= "${margin},\n";
	    }
	    $$string .= "${margin}\}\n";
	}
    } elsif(ref($ref) eq 'ARRAY') {
	my($value);
	$$string .= "\n${margin}\[\n";
	foreach $value (@$ref) {
	    ostring_1($string, $value, $depth);
	    $$string .= "${margin},\n";
	}
	$$string .= "${margin}\]\n";
    }
}

sub pager {
    use integer;
    my($page, $page_length, $callback, $url, $assoc) = @_;
    my($page_shown) = 20;
    $page_length = 10 if(!$page_length);

    $page = 1 if(!$page);

#    warn("page = $page, page_length = $page_length");
    my($index) = ($page - 1) * $page_length;
    my($max) = &$callback($index, $page_length);

    my($maxpage) = $max / $page_length;
    if($max % $page_length) {
	$maxpage++;
    }

    my($curpage) = $index / $page_length;
    my($firstpage) = ($index / ($page_length * $page_shown)) * $page_shown;
    my($lastpage) = $firstpage + $page_shown;
    if($lastpage > $maxpage) {
	$lastpage = $maxpage;
    }

    my($pages);
    if($firstpage > 0) {
	my($before_first) = $firstpage - 1;
	my($page_number) = $before_first + 1;
	$pages .= "<a href=\"${url}page=$page_number\">&lt;</a>";
    }
    my($i);
    for($i = $firstpage; $i < $lastpage; $i++) {
	my($page_number) = $i + 1;
	if($i != $curpage) {
	   $pages .= " <a href=\"${url}page=$page_number\">$page_number</a> ";
       } else {
	   $pages .= " $page_number ";
       }
    }
    if($maxpage > $lastpage) {
	my($page_number) = $lastpage + 1;
	$pages .= "<a href=\"${url}page=$page_number\">&gt;</a>";
    }

    $assoc->{'_PAGES_'} = $pages;
    $assoc->{'_CURPAGE_'} = $curpage;
    $assoc->{'_MAXPAGES_'} = $maxpage;

    return $max;
}

#
# Replace literal iso8859-1 accented letters
#
$tools::acc_from = pack("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC", 
	     198, 193, 194, 192, 197, 195, 196, 199, 208, 201,
	     202, 200, 203, 205, 206, 204, 207, 209, 211, 212, 
	     210, 216, 213, 214, 222, 218, 219, 217, 220, 221, 
	     225, 226, 230, 224, 229, 227, 228, 231, 233, 234, 
	     232, 240, 235, 237, 238, 236, 239, 241, 243, 244, 
	     242, 248, 245, 246, 223, 254, 250, 251, 249, 252, 253, 255);

$tools::acc_to = "aaaaaaacteeeeiiiinooooootuuuuyaaaaaaaceeeteiiiinoooooostuuuuyy";

sub unaccent_8859 {
    my($string) = @_;

    eval "\$string =~ tr/$tools::acc_from/$tools::acc_to/";

    return $string;
}

#
# Like system but bombs if return code is not 0
#
sub shell {
    my($cmd, $silent) = @_;
    dbg("$cmd\n", "normal") if(!$silent);
    my($pid);
    unless ($pid = fork) {
	exec('sh', '-c', $cmd) or error("no exec : $!");
    }
    waitpid($pid,0);
    if($? != 0) {
	error("$cmd: high = " . (($? >> 8) & 0xff) . " low = " . ($? & 0xff) . "\n");
    }
}

#
# A perl functional equivalent to shell sort -u
#
sub sortu {
    my(%h);
    my($tmp);
    my(@result);
    foreach $tmp (@_) {
	if(!defined($h{$tmp})) {
	    $h{$tmp} = 1;
	    push(@result, $tmp);
	}
    }
    return sort(@result);
}

#
# cd and make directories if they do not exist.
#
sub cdp {
    my($dir) = @_;

    mkdirp($dir);
    cd($dir);
}

#
# cd alias that bombs if an error occurs
#
sub cd {
    my($dir) = @_;
    
    chdir($dir) || error("cannot chdir($dir): $!\n");
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
