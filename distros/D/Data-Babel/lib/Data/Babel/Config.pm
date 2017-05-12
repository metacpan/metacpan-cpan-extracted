package Data::Babel::Config;
#################################################################################
#
# Author:	Nat Goodman
# Created:	10-08-11
# $Id$
#
# Copyright 2010 Institute for Systems Biology
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either: the GNU General Public License as published
# by the Free Software Foundation; or the Artistic License.
#
# See http://dev.perl.org/licenses/ for more information.
#
# Wrapper for Config::IniFiles specialized for processing Babel files
# Note: Can't be subclass of Config::IniFiles, because AutoClass::new passes 
#   all args to base classes and Config::IniFiles::new chokes on unexpected args
#
#################################################################################
use strict;
use Carp;
use Template;
use Config::IniFiles;
use File::Basename;
use File::Spec;
use List::MoreUtils qw(uniq);
use Hash::AutoHash;
use Data::Babel::Base;

use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(filename tt stash config);
@OTHER_ATTRIBUTES=qw();
# NG 10-11-11: change tt default to 1. move maptable_header to ReadConfig 
# %DEFAULTS=(stash=>{maptable_header=>File::Spec->catfile(qw(conf maptable_header.tt))});
%DEFAULTS=(tt=>1);
%SYNONYMS=(file=>'filename');
Class::AutoClass::declare(__PACKAGE__);

# Args for new
#  filename              filename to be opened
#  tt                    preprocess via Template Template. default 1
#  autohash              convert to Hash::AutoHash. implied by 'objects'
#  objects               convert to objects. class can be value of arg, or set via 'class'
#  class                 class of objects produced if 'objects' set
sub _init_self {
  my ($self,$class,$args) = @_;
  return unless $class eq __PACKAGE__;
  if ($self->filename) {
    $self->ReadConfig;
  } else {	     # no filename usually means user wants empty object
    $self->config(new Config::IniFiles);
  }
  $self->autohash(1) if $args->autohash; # 'autohash(1)' forces recomputation
  $self->objects($args->class || $args->objects) if $args->objects;
}
sub ReadConfig {
  my $self=shift;
  my($filename,$tt)=$self->get(qw(filename tt));
  my $handle;
  # NG 13-06-10: use 3-argument form of open to handle in-memory files
  # open($handle,$filename) || confess "Cannot open file $filename: $!";
  open($handle,'<',$filename) || confess "Cannot open file $filename: $!";
  if ($tt) {
    my $template = new Template
      (RELATIVE => 1,
       ABSOLUTE => 1,
       INTERPOLATE=>1,		# allow 'naked' use of $ variables
       EVAL_PERL=>1,		# use of [% PERL %] blocks
      );
    # NG 10-08-24: implement Denise's solution for specifying maptable header location
    my $stash='HASH' eq ref $tt? $tt: $self->stash;
    # NG 10-11-11: stuff useful environment variables into stash. USER now. more later maybe
    my @envs=qw(USER); @$stash{@envs}=@ENV{@envs};
    # NG 10-11-11: assume maptable_header in conf unless set by caller
    unless ($stash->{maptable_header}) {
      $stash->{maptable_header}=File::Spec->catfile('conf','maptable_header.tt');
    }
    my $tt_out;
    $template->process($handle,$stash,\$tt_out) || 
      confess "Template::process failed: ".$template->error();
    open($handle,'<',\$tt_out) || confess "Cannot tie TT output string: $!";
  } 
  $self->config(new Config::IniFiles(-file=>$handle,-default=>'GLOBAL'));
}
sub autohash {
  my $self=shift;
  if (@_ || !$self->{autohash})	{ # make autohash
    my $config=$self->config;
			          # grab GLOBAL parameters to add to each section
    my @global_params=$config->Parameters('GLOBAL');
    my $autohash=$self->{autohash}=new Hash::AutoHash;  
    for my $section ($config->Sections) {
      next if $section eq 'GLOBAL';
      my @params=uniq(@global_params,$config->Parameters($section));
      $autohash->$section
	(new Hash::AutoHash map {$_=>scalar($config->val($section,$_))} @params);
  }}
  $self->{autohash};
}
sub objects {
  my($self,$class)=@_;
  if ($class) {			    # make objects
    $class="Data::Babel::$class" unless $class=~/^Data::Babel::/;
    my $autohash=$self->autohash;
    $self->{objects}=[map {new $class (name=>$_,%{$autohash->$_})} keys %$autohash];
  }
  $self->{objects};
}
sub WriteConfig {
  my($self,$filename)=@_;
  open(OUT,"> $filename") || confess "Cannot create file $filename: $!";
  my $old_fh=select(OUT);
  $self->config->OutputConfig;
  close OUT;
  select($old_fh);
}

# delegate unknown methods to config
use vars qw($AUTOLOAD);
sub AUTOLOAD {
  my $self=shift;
  $AUTOLOAD=~s/^.*:://;		    # strip class qualification
  return if $AUTOLOAD eq 'DESTROY'; # the books say you should do this
  $self->config->$AUTOLOAD(@_);
}

# NG 10-08-08. sigh.'verbose' in Class::AutoClass::Root conflicts with method in Base
#              because AutoDB splices itself onto front of @ISA.
sub verbose {Data::Babel::Base::verbose(@_)}
1;
