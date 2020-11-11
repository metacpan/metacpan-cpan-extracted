package Ansible::Util;
$Ansible::Util::VERSION = '0.001';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use Ansible::Util::Run;
use Ansible::Util::Vars;

=head1 NAME

Ansible::Util - Utilities for working with Ansible.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Ansible::Util;
  
  $vars = Ansible::Util::Vars->new;
  $run =  Ansible::Util::Run->new;
  
=head1 DESCRIPTION

This is a base class that simply loads the underlying modules in one shot.   

=head1 MODULES 

=over

=item *

L<Ansible::Util::Run>

=item *

L<Ansible::Util::Vars>

=back
 
=cut


##############################################################################
# CONSTANTS
##############################################################################

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

##############################################################################
# CONSTRUCTOR
##############################################################################

##############################################################################
# PUBLIC METHODS
##############################################################################

##############################################################################
# PRIVATE METHODS
##############################################################################


1;
