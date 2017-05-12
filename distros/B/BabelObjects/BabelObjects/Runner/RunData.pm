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

package BabelObjects::Runner::RunData;

use Carp;
use strict;

use BabelObjects::Util::Dvlpt::Log;
use BabelObjects::Util::Facility::XMLFacility;

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

my %fields = (
    req => undef,
    confParameters => undef
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
    #$aLog->log("\n-- BabelObjects::Runner::RunData --");

    foreach (keys %parameters) {
        # the following lines are useful to verify argument values
        #$aLog->log("Before : $_ = ".$parameters{$_});
        $self->$_($parameters{$_});
        #$aLog->log("After  : $_ = ".$self->$_);
    }

    return $self;
}

sub getParameter {
    my $self = shift;
    my $parameterName = shift;

    #$aLog->log("Parameter Name = ".$parameterName);

    if ($self->req =~ /CGI/ ) {
        #$aLog->log("Web request = ".$self->req);
        return $self->req->param($parameterName);
    } else {
        #$aLog->log("No web request = ".$self->req);
        # we aren't in a web context because $self->req isn't a CGI object
        my $req = $self->req;
        return $$req{$parameterName};
    }
}

sub getConfParameter {
    my $self = shift;
    my $path = shift;

    #$aLog->log("getConfParameter");
    #$aLog->log("    Path = $path");

    my $doc = $self->confParameters;
    #$aLog->log("    Doc = $doc");

    my $xmlHelper = new BabelObjects::Util::Facility::XMLFacility();
    my @results = $xmlHelper->getElementsByPath($doc, $path);
    #my @results = $doc->getElementsByTagName("web");

    #$aLog->log(@results." results.");
    #$aLog->log("    $path = ".$results[0]->getFirstChild()->getData());

    return $results[0]->getFirstChild->getData();
}

sub getConfParameters {
    my $self = shift;

    return $self->confParameters;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
 
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
 
    unless (exists $self->{_permitted}->{$name} ) {
        if ($name =~ /param/) {
            # we aren't in a web context because req-param doesn't exist
            my $parameterName = shift;
            my %vars = $self->req;
            return $vars{$parameterName};
        } else {
            croak "Can't access `$name' field in class $type";
        }
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

BabelObjects::Runner::RunData - stores all the data available for your program

=head1 SYNOPSIS

  use BabelObjects::Runner::RunData;

  $parameters{"req"} = $req;
  $parameters{"confParameters"} = $confParameters;
  my $aRunData = new BabelObjects::Runner::RunData(\%parameters);

  print $aRunData->getParameter("module");

  print $aRunData->getConfParameter(
                       $aRunData->getParameter("module"),
                       $aRunData->getParameter("parameter"));

=head1 DESCRIPTION

RunData stores all the information available :
 * initialization data available through getConfParameter("path") where path
   is the XML path to the element you want
 * http request information available through getParameter("parameterName")

You can add the information you want in the RunData object without risk
to break anything. For example, in the java version, you have the
HttpServletResponse too.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
