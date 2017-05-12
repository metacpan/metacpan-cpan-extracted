#!/usr/bin/perl
#----------------------------------------------------------------------------
#   App::Modular - perl program modularization framewok
#   App::Modular/module.pm: base class for all modules
#
#   Copyright (c) 2003-2004 Baltasar Cevc
#
#   This code is released under the L<perlartistic> Perl Artistic
#   License, which can should be accessible via the C<perldoc
#   perlartistic> command and the file COPYING provided with this
#
#   DISCLAIMER: THIS SOFTWARE AND DOCUMENTATION IS PROVIDED "AS IS," AND
#   COPYRIGHT HOLDERS MAKE NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO, WARRANTIES OF MERCHANTABILITY
#   OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE SOFTWARE
#   OR DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
#   TRADEMARKS OR OTHER RIGHTS.
#   IF YOU USE THIS SOFTWARE, YOU DO SO AT YOUR OWN RISK.
#
#   See this internet site for more details: http://technik.juz-kirchheim.de/
#
#   Creation:       02.12.03    bc
#   Last Update:    06.04.08    bc
#   Version:         0. 1. 3  
# ----------------------------------------------------------------------------

###################
###             ###
###  "PREFIX"   ###
###             ###
###################
###################
#     Pragma      #
###################
use strict;
use warnings;
use 5.006_001;

###################
#     Module      #
###################
package App::Modular::Module;

use vars qw($VERSION);
$VERSION=0.001_003;

###################
###             ###
###  MENTHODS   ###
###             ###
###################
sub module_init {
   my $self = {};
   my $type = shift;
   $self->{'module_name'} = $type;
   substr $self->{'module_name'}, 0, 
      length ("App::Modular::module::"), ''
      if ( (index $self->{'module_name'}, "App::Modular::Module::") == 0); 
   $self->{'modularizer'} = App::Modular->instance();
   $self->{'modularizer'}->mlog (99, "module $self->{'module_name'}:".
                                      " blessed myself!");
   return bless $self, $type;
};

sub module_name {
   my ($self) = @_;
   
   return $self->{'module_name'};
};

sub modularizer {
   my $self = shift;
   return $self->{'modularizer'};
};

sub DESTROY {
   my ($self) = @_;
#   foreach (keys %$self) { print "+++ $_:{".$self->{$_}."}\n"; }
   $self->modularizer()->mlog (99, "module $self->{'module_name'}:".
                                      " going to be destroyed")
      if ($self->modularizer());
};

sub module_depends {
   return;
};

###################
###             ###
###DOCUMENTATION###
###             ###
###################
=pod

=head1 NAME

App::Modular::Module - App::Modular module base class.

=head1 SYNOPSIS

	#!/usr/bin/perl -w
	use strict;

	package App::Modular::Module::Dummy;

	use modularizer;
	use base qw(App::Modular::Module);

	# a complete do-noting module :-)

	1;
	
=head1 USAGE

See L<App::Modular> (secction 'usage') for an example.

=head1 DESCRIPTION

This class should be used as a base class for every modularizer
module. It provides some base methods to cleanly initialize and
destroy the module.
Every

=head1 Creating a new module

See the examples in the documentation of L<App::Modular> for details.

=head1 REFERENCE

In this section I will describe the standard methods that every single module
inheritfs from the master module. The standard aparameters are described, too.

=head2 Internal data

Every module that @IS-A App::Modular::Module will be a blessed hash reference.
In this hash, you will find some default data, too.

=over 4

=item $self->{'module_name'} -> name of Module (= package name without 
App::Modular::Module::)

=item $self->{'modularizer'} -> instance of App::Modular

=back

=head2 Methods

=over 4

=item module_init

Initialize a module (and create a blessed object for it).

Return value: (ref) reference to the module object

=item module_name

Returns the internal module name.

Return value: (string) name of the current module

=item modularizer

Returns the reference to the modularizer object.

Return value: (ref) instance of App::Module

=item DESTROY

The standard destructor for modules (log the destruction, no
other action taken).

=item module_depends

Returns the module dependencies (none by default).

Return value: (array of strings) names of the modules I depend on

=back

=head1 AUTHOR and COPYRIGHT

(c) 2004 Baltasar Cevc

This code is released under the L<perlartistic> Perl Artistic
License, which can should be accessible via the C<perldoc
perlartistic> command and the file COPYING provided with this
package.

=head1 SEE ALSO

L<App::Modular.pm(3pm)>

=cut
1;
