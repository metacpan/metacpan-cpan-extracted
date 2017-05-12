#!/usr/bin/perl -MDevel::Cover
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

my $CFG_DIR = "/usr/local/babelobjects/conf";
my $CFG = "$CFG_DIR/bo.xml";

use Carp;
use strict;

use BabelObjects::Util::Dvlpt::Log;
use BabelObjects::Runner::Initializer;
use BabelObjects::Runner::RunData;
use BabelObjects::Runner::Dispatcher;

use CGI::Fast;
use XML::DOM;
 
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

my $aLog;
my $doc;
my %parameters;
my $confParameters;
my $count = 0;
 
#
$aLog = new BabelObjects::Util::Dvlpt::Log;
init();
 
my $q = new CGI;
#while (my $q = new CGI::Fast) {
    service($q); 
#}

##
 
sub init {
    initParameters(); 
} 
 
sub initParameters {
    my %parameters;
 
    $parameters{"cfg"} = $CFG;
    my $aInitializer = new BabelObjects::Runner::Initializer(\%parameters);
    $confParameters = $aInitializer->getParameters();
} 

sub service {
    my $req = shift;
 
    if ($req->param('init') eq "parameters") {
    }
 
    %parameters = ();

    $parameters{"req"} = $req;
    $parameters{"confParameters"} = $confParameters;
    my $aRunData = new BabelObjects::Runner::RunData(\%parameters);

    %parameters = ();

    $parameters{"runData"} = $aRunData;

    #print "CONF Parameter = ", $aRunData->getConfParameter(
    #                                         $aRunData->getParameter("module"),
    #                                         $aRunData->getParameter("parameter")); 

    my $aDispatcher = new BabelObjects::Runner::Dispatcher(\%parameters);
#    if () {
# 
#    } else {
        my $target = $aDispatcher->parseAndExecuteTransition();
        $aLog->log("Target = $target");
        if ($target =~ m!^\w*://!) {
            # We consider it's an URL. We should do better
            print $req->redirect($target);
        } else {
            print("Content-type: text/html\r\n\r\n");
            $aDispatcher->parseFile($target);
        }
#    }
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
        #print "Dispatcher AUTOLOAD = $AUTOLOAD\n";
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

BabelObjects::Runner::Controller - Perl extension for blah blah blah

=head1 SYNOPSIS

  use BabelObjects::Runner::Controller;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for BabelObjects::Runner::Controller was created by h2xs. It looks like the author of the extension was negligent enough to leave the stub unedited.

Blah blah blah.

=head1 AUTHOR

Jean-Christophe Kermagoret jck@babelo.org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
