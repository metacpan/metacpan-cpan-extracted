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

package BabelObjects::Runner::Dispatcher;

use Carp;
use strict;

use BabelObjects::Util::Dvlpt::Log;

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

my $newfilename;
my $aLog;

my %fields = (
    runData => undef
);
 
sub new {
    my $proto = shift;
    my $args = shift;

    my $class = ref($proto) || $proto;

    my $self  = {
         _permitted => \%fields,
         %fields,
    };
 
    bless ($self, $class);

    my %parameters = %$args;

    $aLog = new BabelObjects::Util::Dvlpt::Log();
    #$aLog->log("\n-- BabelObjects::Runner::Dispatcher --");

    foreach (keys %parameters) {
        # the following lines are useful to verify argument values
        #$aLog->log("Before : $_ = ".$parameters{$_});
        $self->$_($parameters{$_});
        #$aLog->log("After  : $_ = ".$self->$_);
    }

    return $self;
}
 
sub executeBO {
    my $self = shift;
    (my $aClassName, my $aMethodName) = @_;
 
    # 3 steps
    #  1 - creates an instance of aClassName
    #  2 - tries :
    #       * aMethodName in uppercase : getXXXX()
    #       * aMethodName according bo info answer : getXxXx()
    #       * aMethodName as a parameter according bo info : getValue(XxXx)
    #  3 -
 
    #$aLog->log("executeBO");
    #$aLog->log("    ClassName = $aClassName");
    #$aLog->log("    MethodName = $aMethodName");
 
    eval("require $aClassName");
 
    # be careful : $runData is a reference on a hashtable
    # to access values, use $$runData{itemkey}

    my %parameters = ();
    $parameters{"runData"} = $self->runData;
    #$aLog->log("runData : ".$self->runData);
    my $aObject = $aClassName->new(\%parameters);
    #$aLog->log("    $aObject created");

    my %boAttributes = $aObject->getBoInfo();

    #foreach (keys %boAttributes) {
    #    $aLog->log("Attrib = ".$boAttributes{$_}."\n");
    #}

    my $realMethod = $boAttributes{lc($aMethodName)};
    my $realGetMethod = "get".$realMethod;

    my $result = $aObject->$realGetMethod ;

    #$aLog->log("Result = $result");

    if ( $result =~ /$realGetMethod/ ) {
    # if ( $result =~ /$aClassName::$realGetMethod/ ) {

        #print "getValue call : getValue(", $realMethod, ")\n";
        # the getXXXX() or getXxXx method doesn't exist,
        # so we try the get method with the $realMethod like
        # a parameter and we print it
        #$aLog->log("    Real Method = $realMethod");
        $result = $aObject->getValue($realMethod);
        # if ( $result =~ /$aClassName::getValue/ ) {
        if ( $result =~ /getValue/ ) {
          # there is really an error
          $aLog->log("There is really an error");
          exit();
        } else {
          $self->boprint($result);
        }
    } else { 
      # if $realMethod is in uppercase, the method prints the result
      # else the actual method (executeBO) prints the result
      if ( $realMethod ne uc($realMethod) ) {
        # the method isn't in upper case so we print the result
        $self->boprint($result);
      }
    }
}
 
# aClassName String long class name
sub executeTransition {
    my $self = shift;
    my ($aClassName, $aMethodName) = @_;
 
    #$aLog->log("executeTransition");
    #$aLog->log("    ClassName = $aClassName");
    #$aLog->log("    MethodName = $aMethodName");

    eval("require $aClassName");
 
    # be careful : $runData is a reference on a hashtable
    # to access values, use $$runData{itemkey}

    my %parameters = (runData => $self->runData);
    my $aObject = $aClassName->new(\%parameters);
    #$aLog->log("$aObject is created");

    my %boAttributes = $aObject->getBoInfo();

    #foreach (keys %boAttributes) {
    #    print STDERR "$_ => ", $boAttributes{$_}, "<br>\n";
    #}

    my $realMethod = $boAttributes{lc($aMethodName)};
    #$aLog->log("Real Method = $realMethod");
 
    my $result = $aObject->$realMethod;
    #$aLog->log("Result = $result");

    if ( ($result eq "") || ($result =~ /$realMethod/) ) {
    # if ( $result =~ /$aClassName::$realGetMethod/ ) {
        #print "realMethod call : ", $realMethod, " -> $result\n";
        # the realmethod doesn't exist => error
        return "PB";
    } else {
        if ($result eq "true") {
            return "OK"; 
        } elsif ($result eq "false") {
            return "NOK";
        } else {
            return $result;
        }
    }
}
 
sub parseAndExecuteTransition {
    my $self = shift;

    my $target;
    my $result;

    my $transition = $self->runData->getParameter("T");
    my $prefix = $self->runData->getConfParameter("global/parameter/webDir");
    #my $transitionPath = $self->runData->req->url(-absolute=>1);
    my $transitionPath = $self->runData->req->url(-path_info=>1);

    #$aLog->log("parseAndExecuteTransition");
    #$aLog->log("    T = $transition");
    #$aLog->log("    Path info = $transitionPath");
    #$aLog->log("    Prefix info = $prefix");

    if ($transition ne "") {
        $_ = $transition;
        (my $shortClass, my $shortMethod) = /(.*)\.(.*)/;

        #$aLog->log("    ShortClass = $shortClass");
        #$aLog->log("    ShortMethod = $shortMethod");

        my $aClassName = $self->runData->getConfParameter("classes/parameter/$shortClass");
        my $aMethodName = "t_".$shortMethod;

        $result = $self->executeTransition($aClassName, $aMethodName);
        #$aLog->log("Transition's result = $result");

        my $path = $self->runData->getParameter($result);
        $_ = $path;
        #$aLog->log("    OK's Url  = ".$_);
        if (m!.*://!) {
            # It's an Url
            $target = $path;
        } elsif (m!\.\.!) {
            # we block potential intruders
            $target = "";
        } elsif (m!^/!) {
            # absolute path
            $target = $prefix.$path;
        } else {
            $_ = $transitionPath;
            #$aLog->log("    Transition path  = ".$_);
            if (! /\.\./) {
                # path relative to the action path
                (my $dir) = $transitionPath =~ /http:\/\/[^\/]*\/cgi-bin\/Controller[^\/]*(\/.*)\/[^\/]*$/;
                #$aLog->log("    T - Relative path  = ".$dir);
                $target = $prefix.$dir."/".$path;
            } else {
                # back relative path are prohibited
                $target = $prefix.$path;
            }
        }
    } else {
        $_ = $self->runData->req->url(-path_info=>1);
        #$aLog->log("    Path info = ".$_);
        (my $relativePath) = /\/cgi-bin\/Controller[^\/]*(\/.*)/;
        #(my $relativePath) = /http:\/\/[^\/]*(\/.*)$/;
        #(my $relativePath) = /([^\/]*)$/;
        #$aLog->log("    RelativePath = ".$relativePath);
        $target = $prefix.$relativePath;
    }

    return $target;
}
 
sub parseAndSubstituteBO {
    my $self = shift;
    my $aLine = shift;
    
    $_ = $aLine;
    #s/\$/\\\$/g;
    $aLine = $_;
 
    #my $regExp = "/\$\([A-Z_0-9\.]*\)/";
    #my @results = split($regExp, $aLine, 1);
    my @results = split(/(\$\([A-Za-z_0-9\.]*\))/, $aLine);
 
    # html parts and bo tags are together so we test if $result starts with...
    my $result;
    foreach (@results) {
        if (/^\$\([A-Za-z_0-9\.]*\)/) {
            # it's a bo tag
            (my $aClassName, my $aMethodName) = /\$\(([A-Z_a-z]*)\.([A-Z_a-z]*)\)/;

            #$aLog->log("parseAndSubstituteBO");
            #$aLog->log("    ClassName = $aClassName");
            #$aLog->log("    MethodName = $aMethodName");
            #$aLog->log("    RunData = ".$self->runData);

            my $longClassName = $self->runData->getConfParameter("classes/parameter/".lc($aClassName));
            $self->executeBO($longClassName, $aMethodName);
        } else {
            $self->boprint($_);
        }
    }
}

sub parseFile {
    my $self = shift;
    my $filename = shift;
 
    $newfilename = shift;
 
    if ($newfilename eq $filename) {
        #$aLog->log("ERROR : source and target filename are the same\n");
        exit();
    }
 
    if ($newfilename ne "") {
      open(NEWFILE, ">$newfilename");
    }
 
    #$aLog->log("INFO : filename = $filename");
    open(FILE, "$filename") || die $aLog->log("The $filename can't be opened");
    while (<FILE>) {
        # $_ contains line feed : no need to add it
        $self->parseAndSubstituteBO($_);
    }
    close(FILE);
 
    if ($newfilename ne "") {
      close(NEWFILE);
    }
}
 
sub boprint {
    my $self = shift;
    my $aString = shift;
 
    if ($newfilename ne "") {
      print NEWFILE $aString;
    } else {
      print $aString;
    }
}                                                                               

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
 
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
 
    unless (exists $self->{_permitted}->{$name} ) {
        #croak "Can't access `$name' field in class $type";
        # On intercepte ici les erreurs liées aux tentatives d'appel
        # des méthodes inexistantes
        #$aLog->log("AUTOLOAD : $self = $AUTOLOAD");
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
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BabelObjects::Runner::Dispatcher - parses the file and substitutes BO tags.

=head1 SYNOPSIS

  use BabelObjects::Runner::Dispatcher;



=head1 DESCRIPTION

Dispatcher parses the file and substitutes all Babel Objects tags by their
value. Tags are of the form : $(aClass.aMethod).

The file is parsed within a web or no web context. When a BO tag is
encountered, the dispatcher looks in the classes.xml file for an element
called aClass. If it finds one, it takes the real class name, loads it and
calls the aMethod on it :

   <classes>
      <parameter>
         <bookmark>BabelObjects::Component::Directory::Bookmark</bookmark>
      </parameter>
      <parameter>
         <test>BabelObjects::Component::Test::BabelObjects::Test</test>
      </parameter>
  <classes>

Then the result is written on the http output in a web context, or the standart
output in a no web context.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
