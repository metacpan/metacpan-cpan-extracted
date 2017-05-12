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

package BabelObjects::Util::Facility::XMLFacility;

use BabelObjects::Util::Dvlpt::Log;
use XML::DOM;

use strict;
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

sub new {
    my $proto = shift;
    my $args = shift;

    my $class = ref($proto) || $proto;

    my $self  = {
    };

    bless ($self, $class);

    $aLog = new BabelObjects::Util::Dvlpt::Log();
    #$aLog->log("\n-- BabelObjects::Util::Facility::XMLFacility --");

    return $self;
}

sub getValueByPath {
    my $self = shift;
    my $node = shift;
    my $path = shift;

    $_ = $path;

    my (@tags) = /(.*)\/(.*)/;

    foreach (@tags) {
        #$aLog->log("Tag name to search : $_");
        $node = $self->getElementByTagName($node, $_);
    }

    return $node->getFirstChild->getData;
}

# return the first node under $node with the parameter named $name provided 
sub getElementByTagName {
    my $self = shift;
    my $node = shift;
    my $name = shift;

    #$aLog->log("getElementByTagName");
    #$aLog->log("    Node = $node");
    #$aLog->log("    Name = $name");

    my $nodes = $node->getElementsByTagName ("*", 0);
    my $n = $nodes->getLength;

    for (my $i = 0; $i < $n; $i++) {
        my $aNode = $nodes->item($i);
        #$aLog->log("    Type = ".$aNode->getNodeType);
        if ($aNode->getNodeType == ELEMENT_NODE) {
            #$aLog->log("    Current Name = ".$aNode->getNodeName);
            if ($aNode->getNodeName eq $name) {
                #$aLog->log("    Name result = ".$aNode->getNodeName);
                return $aNode;
            } else {
                my $nodeResult = $self->getElementByTagName($aNode, $name);
                if ($nodeResult) {
                    return $nodeResult;
                }
            }
        }
    }
}

# returns all the child nodes in the same level under 'node' and named 'name'
sub getElementsByTagName {
    my $self = shift;
    my $node = shift;
    my $name = shift;

    my @nodes;

    #$aLog->log("getElementsByTagName");
    #$aLog->log("    Node = $node");
    #$aLog->log("    Name = $name");

    my $childs = $node->getChildNodes();
    my $n = $childs->getLength;

    for (my $i = 0; $i < $n; $i++) {
        my $aNode = $childs->item($i);
        #$aLog->log("Node $i = ".$aNode);
        if ($aNode->getNodeType == ELEMENT_NODE) {
            #$aLog->log("Current Name = ".$aNode->getNodeName);
            if ($aNode->getNodeName eq $name) {
                #$aLog->log("    Name result = ".$aNode->getNodeName);
                push(@nodes, $aNode);
            }
        }
    }

    return @nodes
}

# returns all the nodes named 'name' under the branch
sub getElementsByPath {
    my $self = shift;
    my $node = shift;
    my $path = shift;
    my $regExp = shift || "([^\/]+)\/[^\/]+\/([^\/]+)";

    #my (@tags) = $path =~ /([^\/]+)/g;
    my (@tags) = $path =~ /$regExp/g;
    my $name = pop(@tags);

    foreach (@tags) {
        #$aLog->log("Tag name to search : $_");
        $node = $self->getElementByTagName($node, $_);
    }

    #$aLog->log("    Tag name to search : $name");
    #return $self->getElementByTagName($node, $name);
    return $node->getElementsByTagName($name);
}

# prints the xml tree
sub dump {
    my $self = shift;
    my $node = shift;
    my $spaces = shift;

    my $nodes = $node->getElementsByTagName ("*", 0);
    my $n = $nodes->getLength;

    for (my $i = 0; $i < $n; $i++) {
        my $aNode = $nodes->item($i);
        #$aLog->log("    Node = $aNode");
        #$aLog->log("      Type = ".$aNode->getNodeType);
        #$aLog->log("      Name = ".$aNode->getNodeName);
        if ($aNode->getNodeType == ELEMENT_NODE) {
            print $spaces."<".$aNode->getNodeName.">\n";
            if ( ($aNode->getFirstChild)
                    && ($aNode->getFirstChild->getNodeType == TEXT_NODE)
                    && ($aNode->getFirstChild->getData ne "") ) {
                $_ = $aNode->getFirstChild->getData;
                s/\t*|\s*|\n//g;
                if ($_ ne "") {
                    print $spaces."    ".$_."\n";
                }
            }
            $self->dump($aNode, $spaces."    ");
            print $spaces."</".$aNode->getNodeName.">\n";
        }
    }
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

BabelObjects::Util::Facility::XMLFacility - manipulates XML data in an easy way

=head1 SYNOPSIS

  use BabelObjects::Util::Facility::XMLFacility;

  XML routines to help XML data manipulation. DON'T USE THIS PACKAGE ANYMORE.
  Use Xpath instead.

=head1 DESCRIPTION

  XML routines to help XML data manipulation. DON'T USE THIS PACKAGE ANYMORE.
  Use Xpath instead.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
