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
package Catalog::tools::cgi;
use vars qw(@ISA $random %char2quote);
use strict;

use CGI qw(:compile);
use Carp;
use Catalog::tools::tools;

@ISA = qw(CGI);

sub init {
    my($self) = shift;

    $self->CGI::init(@_);

    my($config) = config_load("cgi.conf");
    %$self = (%$self, %$config) if(defined($config));
}

sub protect_gen {
    my($self) = @_;

    my($file) = time() . $$ . $random++;
    my($path) = "$self->{'fct_dir'}/$file";
    open(FILE, ">$path") or error("cannot open $path for writing : $!");
    close(FILE);
    $self->param('cgi_protect', $file);
}

sub protect_check {
    my($self) = @_;

    my($file) = $self->param('cgi_protect');
    return undef if(!defined($file));
    my($path) = "$self->{'fct_dir'}/$file";
    return -f $path;
}

sub protect_clear {
    my($self) = @_;

    my($file) = $self->param('cgi_protect');
    return undef if(!defined($file));
    my($path) = "$self->{'fct_dir'}/$file";
    return undef if(!-f $path);
    unlink($path) or error("cannot unlink $path : $!");
    return 1;
}

#
# Function like cgi call
#
sub hash2params {
    my($hash) = @_;
    return join("&", map { "$_=" . CGI::escape($hash->{$_}) } keys(%$hash));
}

sub fct_call {
    my($self, $params, %args) = @_;

    error("recursive cgi depth > 1 is not allowed") if(defined($self->param('fct_name')));
    
    $params .= "&fct_args=" . CGI::escape(hash2params($args{'args'}));
    $params .= "&fct_returned=" . CGI::escape(hash2params($args{'returned'}));
    $params .= "&fct_name=$args{'name'}";

    my($filebase) = time() . $$ . $random++;	# see also fct_return
    my($file) = "$self->{'fct_dir'}/$filebase";
    open(FILE, ">$file") or error("cannot open $file for writing : $!");
    $self->save('FILE');
    close(FILE);

	# Save base name only to minimise security issues.
	# XXX still allows deletion of any file in /tmp if the
	# default fct_dir value in cgi.conf is used
    $params .= "&fct_stack=$filebase"; # see also fct_return

#
# Wait for the fileno() bug to be fixed
#
#    my($cgi) = Catalog::tools::cgi->new($params);
    my($cgi) = Catalog::tools::cgi->new();
    $cgi->delete_all();
    my(@pairs) = split(/[&]/, $params);
    my($param,$value);
    foreach (@pairs) {
	($param,$value) = split('=', $_, 2);
	$param = CGI::unescape($param);
	$value = CGI::unescape($value);
	$cgi->param($param => $value);
    }

    return $cgi;
}

sub reset_params {
    my($self, $params) = @_;

    $self->delete_all();
    my(@pairs) = split(/[&]/, $params);
    my($param,$value);
    foreach (@pairs) {
	($param,$value) = split('=', $_, 2);
	$param = CGI::unescape($param);
	$value = CGI::unescape($value);
	$self->param($param => $value);
    }
}

sub fct_args {
    my($self) = @_;

    return $self->fct_extract('fct_args');
}

sub fct_returned {
    my($self) = @_;

    return $self->fct_extract('fct_returned');
}

sub fct_name {
    my($self) = @_;

    return $self->param('fct_name');
}

sub fct_extract {
    my($self, $what) = @_;

    my(%args);
    my($args) = $self->param($what);
    if(defined($args)) {
	my($cgi) = CGI->new(CGI::unescape($args));
	my($key);
	foreach $key ($cgi->param()) {
	    $args{$key} = $cgi->param($key);
	}
    }
    return \%args;
}

sub fct_return {
    my($self, %args) = @_;

    my($filebase) = $self->param('fct_stack');
	$filebase = $1 if $filebase =~ m/^(\d+)$/; # untaint
	my($file) = "$self->{'fct_dir'}/$filebase";
    open(FILE, "<$file") or error("cannot open $file for reading : $!");
    my($cgi) = Catalog::tools::cgi->new('FILE');
    close(FILE);
    unlink($file);

    my($key, $value);
    while(($key, $value) = each(%args)) {
	$cgi->param($key, $value);
    }

    return $cgi;
}

#
#
# Parameters reconstitution for context passing
#
sub params {
    my($self, $keys, %pairs) = @_;

    return $self->params_1('params', $keys, %pairs);
}

sub hidden {
    my($self, $keys, %pairs) = @_;

    return $self->params_1('hidden', $keys, %pairs);
}

sub params_1 {
    my($self, $style, $keys, %pairs) = @_;

    my($html) = '';
    my($field);
    #
    # Build from values found in the current set of parameters
    #
    foreach $field (@$keys, 'cgi_protect', 'fct_name', 'fct_args', 'fct_stack', 'fct_returned') {
	next if(exists($pairs{$field}) || !defined($self->param($field)));
	$html .= params_format($style, $field, $self->param($field));
    }
    #
    # Override with %pairs arguments
    #
    my($value);
    while(($field, $value) = each(%pairs)) {
	$html .= params_format($style, $field, $value);
    }

    #
    # Remove leading &
    #
    $html =~ s/^\&// if($style eq 'params');

    return $html;
}

sub params_format {
    my($style, $key, $value) = @_;
    
    my($html) = '';

    if(defined($value)) {
	if($style eq 'params') {
	    $html = "&$key=" . CGI::escape($value);
	} else {
	    $value = CGI::escapeHTML($value);
	    $html = "<input type=hidden name=$key value=\"$value\">\n";
	}
    }

    return $html;
}

%char2quote = (
			       '>' => '&gt;',
			       '<' => '&lt;',
			       '&' => '&amp;',
			       "'" => '&#39;',
			       '"' => '&quot;',
			       );

sub myescapeHTML {
    my($toencode) = @_;

    return undef if(!defined($toencode));

    $toencode =~ s;([&\"<>\']);$char2quote{$1};ge;
    return $toencode;
}

sub myunescapeHTML {
    my($string) = @_;
    return undef if(!defined($string));
    # thanks to Randal Schwartz for the correct solution to this one
    $string =~ s[&(.*?);]{
	local $_ = $1;
	/^amp$/i	? "&" :
	/^quot$/i	? '"' :
        /^gt$/i		? ">" :
	/^lt$/i		? "<" :
	/^#(\d+)$/	? chr($1) :
	/^#x([0-9a-f]+)$/i ? chr(hex($1)) :
	$_
	}gex;
    return $string;
}
