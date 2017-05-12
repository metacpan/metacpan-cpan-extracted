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

package BabelObjects::Component::Test::BabelObjects::Test;

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

my $aLog;

my %fields = (
        runData => undef
);
 
sub new {
    my $proto = shift;
    my $args = shift;
 
    print STDERR "TEST ARGS = $args\n";

    my $class = ref($proto) || $proto;
 
    my $self  = {
                  _permitted => \%fields,
                  %fields,
    };
 
    bless ($self, $class);
 
    my %parameters = %$args;

    $aLog = new BabelObjects::Util::Dvlpt::Log();
    $aLog->log("\n--BabelObjects::Component::Test::BabelObjects::Test--");

    foreach (keys %parameters) {
        # the following lines are useful to verify argument values
        $aLog->log("$_ = ".$parameters{$_});
        $aLog->log("$_ = ".$self->$_);
        $self->$_($parameters{$_});
    }

    return $self;                                                               
}
 
sub t_test {
    my $self = shift;

    return "OK";
}

sub getBoInfo {
    my $self = shift;

    # this method is a little silly because the information
    # is redundant between here and xml file

    my %attributes = ();

    # BO Tags that can be called in bo page

    $attributes{"hello"} = "Hello";
    $attributes{"world"} = "World";

    # BO Transitions that are called with T input field
    # Please note that "t_" is automatically added
    # do not put "t_" in your T var

    $attributes{"t_test"} = "t_test";
 
    return %attributes;
}
 
sub getHello {
    return "Hello";
}

sub getWorld {
    print "World";
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
        $aLog->log("AUTOLOAD : $self = $AUTOLOAD");
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

BabelObjects::Component::Test::BabelObjects::Test - Perl extension for blah blah blah

=head1 SYNOPSIS

  use BabelObjects::Component::BabelObjects::Test;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for BabelObjects::Component::Test::BabelObjects::Test was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 AUTHOR

Jean-Christophe Kermagoret, jck@BabelObjects.Org (http://www.BabelObjects.Org)

=head1 SEE ALSO

perl(1).

=cut
