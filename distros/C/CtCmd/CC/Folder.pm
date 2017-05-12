##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2004. All rights reserved.           #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# Matt Lennon - Creation and framework.                                  #
#                                                                        #
# William Spurlin - Maintenance and defect fixes                         #
#                                                                        #
##########################################################################

=head1 NAME

CC::Folder - XXX

=cut

##############################################################################
package CC::Folder;
##############################################################################

# Folder is a subclass of VobObject.

@ISA = qw(CC::UCMObject);

use CC::CC;
use CC::UCMObject;
use CC::VobObject;
use CC::Activity;
use strict;
# use Trace;


##############################################################################
sub new
##############################################################################
{
    # my $trace();
    my $class  = shift @_;
    my $objsel = CC::CC::make_objsel('folder', @_);

    my $this   = new CC::VobObject($objsel);
    my $cleartool = ClearCase::CtCmd->new;
    my $status;
    $this->{cleartool}=$cleartool;
    $this->{status}=0;
    return bless($this, $class);
}

##############################################################################
sub create
##############################################################################
{
    # my $trace();
    my %args   = @_;
    my $parent = $args{parent};
    my $name   = $args{name};
    my $title  = $args{title};
    
    CC::CC::assert($parent);
    CC::CC::assert($name) unless $title;
    CC::CC::assert($title) unless $name;
    
    my $objsel ;
    $objsel = CC::CC::make_objsel('folder', $name, $parent->vob()) if $name;

    $title or $title = $name;
    my @title_args ;
    @title_args = ('-title', qq("$title")) if $title;

    my @cmd = ('mkfolder', '-nc', @title_args, '-in', $parent->objsel(), $objsel);

    my @rv = ClearCase::CtCmd::exec(@cmd);
    chomp $rv[1];
    if ($objsel){}
    else{
	$rv[1] =~ /folder\s+\"(.+?)\"/;
	$objsel = CC::CC::make_objsel('folder', $1,$parent->vob());
    }
    return $rv[0]? new CC::Folder($objsel) : 0;
}

##############################################################################
# this name "projects"  is inconsistent with the CC::Component::list() method
# for a method that has the same purpose and returns the same type  wjs

sub projects

##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    my @objsels = split(' ', $this->describe('%[contains_projects]Xp'));

    return map { new CC::Project($_); } @objsels;
}

##############################################################################
sub folders
##############################################################################
{
    # my $trace();
    my $this  = shift @_;

    my @objsels = split(' ', $this->describe('%[contains_folders]Xp'));
    for (@objsels){s/\"//g}; #wjs
    return map { new CC::Folder($_); } @objsels;
}

##############################################################################
sub root_folder
##############################################################################
{
    # my $trace();
    my $vob   = shift @_;

    return new CC::Folder('RootFolder', $vob);
}

1;   # Make "use" and "require" happy
