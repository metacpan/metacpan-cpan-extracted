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

package BabelObjects::Runner::Initializer;

use Carp;
use strict;

use BabelObjects::Util::Dvlpt::Log;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use XML::DOM;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
$VERSION = '1.00';

my $doc;
my $aLog;

my %fields = (
    cfg => undef
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
    $aLog->log("\n-- BabelObjects::Runner::Initializer --");

    foreach (keys %parameters) {
        # the following lines are useful to verify argument values
        $aLog->log("Before : $_ = ".$parameters{$_});
        $self->$_($parameters{$_});
        $aLog->log("After  : $_ = ".$self->$_);
    }

    $self->loadParameters();

    return $self;
}
 
sub loadParameters {
    my $self = shift;

    $aLog->log("Start - loadParameters()");

    $aLog->log("new Parser()");
    my $parser = new XML::DOM::Parser(NoLWP => 1);

    $aLog->log("parsefile()");
    $doc = $parser->parsefile($self->cfg);

    $aLog->log("End - loadParameters()");
}

sub getParameters {
    my $self = shift;

    return $doc;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) or croak "$self is not an object";
 
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
 
    unless (exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in class $type";
    }
 
    # Gérer le cas des attributs multivalués
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

BabelObjects::Runner::Initializer - load initialization data in memory

=head1 SYNOPSIS

  use BabelObjects::Runner::Initializer;

  $parameters{"cfg"} = "/usr/local/babelobjects/conf/bo.xml";

  my $aInitializer = new BabelObjects::Runner::Initializer(\%parameters);
  $confParameters = $aInitializer->getParameters();


=head1 DESCRIPTION

This library can be used in a web or no web context. It loads data from xml
files and creates a DOM object in memory. It could be interesting to use a
xml database like dbXML for example.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
