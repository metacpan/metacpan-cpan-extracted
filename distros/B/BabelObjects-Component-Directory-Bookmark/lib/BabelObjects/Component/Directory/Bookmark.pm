#/*====================================================================
# * Babel Objects, Version 1.0
# * ====================================================================
# *
# * Copyright (c) 2000 The Babel Objects Network. All rights reserved.
# *
# * This source file is subject to version 1.1 of The Babel Objects
# * License, that is bundled with this package in the file LICENSE,
# * and is available through the world wide web at :
# *
# *          http://www.BabelObjects.Org/law/license/1.1.txt
# *
# * If you did not receive a copy of the Babel Objects license and are
# * unable to obtain it through the world wide web, please send a note
# * to license@BabelObjects.Org so we can mail you a copy immediately.
# *
# * --------------------------------------------------------------------
# *
# * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
# * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# * DISCLAIMED.  IN NO EVENT SHALL THE BABEL OBJECTS NETWORK OR
# * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# * SUCH DAMAGE.
# *
# * ====================================================================
# *
# * This software consists of voluntary contributions made by many
# * individuals on behalf of The Babel Objects Network.  For more
# * information on The Babel Objects Network, please see
# * <http://www.BabelObjects.org/>.
# *
# */

package BabelObjects::Component::Directory::Bookmark;

use Carp;
use strict;

use BabelObjects::Util::Dvlpt::Log;
use URI::Bookmarks;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '1.00';

my $ROAMING_DIR = "/opt/www/www.babelobjects.org/roaming";

my $aLog;
my $bookmark;
my $file;

my %fields = (
        runData => undef
);
 
sub new {
    my $proto = shift;
    my $args = shift;
 
    my $class = ref($proto) || $proto;
 
    my $self  = {
        _permitted => \%fields,
        %fields
    };
 
    bless ($self, $class);
 
    my %parameters = %$args;

    $aLog = new BabelObjects::Util::Dvlpt::Log();
    $aLog->log("\n-- BabelObjects::Component::Directory::Bookmark --");

    foreach (keys %parameters) {
        # the following lines are useful to verify argument values
        #$aLog->log("Before : $_ = ".$parameters{$_});
        $self->$_($parameters{$_});
        #$aLog->log("After  : $_ = ".$self->$_);
    }

    my $user = $self->runData->getParameter("user");
    if (! $user) {
        $user = "default";
    }

    $file = $self->verifyAndCorrectBookmark($user);
    $bookmark = new URI::Bookmarks(file => $file);

    return $self;                                                               
}
 
sub verifyAndCorrectBookmark {
    my $self = shift;
    my $user = shift;

    my $file = "$ROAMING_DIR/$user/bookmarks";

    open(FILE, "$file");
    open(NEWFILE, ">$file.html");
    while(<FILE>) {
        s/\cM//g;
        print NEWFILE $_;
    }
    close(NEWFILE);
    close(FILE);

    return "$ROAMING_DIR/$user/bookmarks.html";
}

sub t_go {
    my $self = shift;

    return "OK";
}

sub getBoInfo {
    my $self = shift;

    # this method is a little silly because the information
    # is redundant between here and xml file

    my %attributes = ();

    # BO Tags that can be called in bo page

    $attributes{"folders"} = "FOLDERS";
    $attributes{"title"} = "Title";
    $attributes{"urls"} = "URLS";

    # BO Transitions that are called with T input field
    # Please note that "t_" is automatically added
    # do not put "t_" in your T var

    $attributes{"t_go"} = "t_go";
 
    return %attributes;
}

sub getFolders {
    my $self = shift;
    my $root = shift;

    my @folders;

    my @daughters = $root->daughters;

    foreach (@daughters) {
        if ($_->type eq "folder") {
            push(@folders, $_);
        }
    }

    return @folders;
}

sub getUrls {
    my $self = shift;
    my $root = shift;

    my @urls;

    my @daughters = $root->daughters;

    foreach (@daughters) {
        if ($_->type eq "bookmark") {
            push(@urls, $_);
        }
    }

    return @urls;
}

sub getFOLDERS {
    my $self = shift;

    my @folders;
    my $aFolder = $self->runData->getParameter("folder");
    my $user = $self->runData->getParameter("user");

    if ($aFolder eq "") {
        @folders = $self->getFolders($bookmark->tree_root());
    } else {
        @folders = $self->getFolders(($bookmark->name_to_nodes($aFolder))[0]);
        #$aLog->log(@folders." folders");
    }

    print "<table><tr><td>";
    print "<dl>\n";
    my $middle = @folders / 2;
    my $i = 0;
    foreach (@folders) {
        $i = $i + 1;
        # According to the visualization mode,
        # we create one or more columns
        print "<dt><a href=\"javascript:submitForFolder('".$user."','".$_->name."')\">"
              .$_->name
              ."</a>\n";
        if ($i == $middle) {
            print "</dl></td><td><dl>";
        }
    }
    print "</dl>\n";
    print "</td></tr></table>";
}

sub getURLS {
    my $self = shift;

    my @urls;
    my $aFolder = $self->runData->getParameter("folder");

    if ($aFolder eq "") {
        @urls = $self->getUrls($bookmark->tree_root());
    } else {
        #@urls = $self->lookup($aFolder);
        @urls = $self->getUrls($bookmark->name_to_nodes($aFolder));
    }

    print "<dl>\n";
    foreach (@urls) {
        # According to the visualization mode,
        # we create one or more columns
        print "<dt><a target=\"out\" "
            ."href=\"".$_->attributes->{HREF}."\">"
            .$_->name
            ."</a>";
        print "<dt>", $_->attributes->{description}, "\n";
        print "<dt><font size=-1>", $_->attributes->{HREF}, "</font>\n";
    }
    print "</dl>";
}

sub getTitle {
    my $self = shift;

    return $bookmark->title();
}

sub getValue {
    my $self = shift;
    my $key = shift;
    my $x;
 
    my $doc = $self->parameters;
    my $context = $self->context;
 
    foreach  $x ($doc->$context->parameter) {
      my $name = $x->name->getString;
      if (lc($name) eq $key) {
        return $x->value->getString;
      }
    }
 
    return "PB";                                                                
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
 
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
 
    unless (exists $self->{_permitted}->{$name} ) {
        # croak "Can't access `$name' field in class $type";
        # On intercepte ici les erreurs liées aux tentatives d'appel
        # des méthodes inexistantes
        #$aLog->log("AUTOLOAD : $self = $AUTOLOAD -->");
        $aLog->log("Can't access `$name' field in class $type");
        return $AUTOLOAD;
    }
 
    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}                                                                               

1;

__END__

=head1 NAME

BabelObjects::Component::Directory::Bookmark - loads user bookmark and puts it on the web

=head1 SYNOPSIS

  use BabelObjects::Component::Directory::Bookmark

  getFolders() - outputs folders in a 2 column way
  getUrls()    - outputs urls in a one column
  getTitle()   - outputs title

=head1 WEB SERVICE USAGE

  http://yourserver/test_bookmark.bo?user=toto&folder=Introduction

=head1 DESCRIPTION

This component enables you to create a open directory from several bookmarks
you can link together.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org, http://www.BabelObjects.Org

=head1 SEE ALSO

perl(1).

=cut
