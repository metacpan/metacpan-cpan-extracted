#
# This file is part of CatalystX-Controller-ExtJS-REST-SimpleExcel
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::REST::SimpleExcel::ApplicationToClass;
BEGIN {
  $CatalystX::Controller::ExtJS::REST::SimpleExcel::ApplicationToClass::VERSION = '0.1.1';
}
use Moose;
use strict;
use warnings;
extends 'Moose::Meta::Role::Application::ToClass';

after apply => sub {
    my ($self, $role, $class) = @_;
    $class->name->config->{map}{'application/vnd.ms-excel'} = 'SimpleExcel';
};

package CatalystX::Controller::ExtJS::REST::SimpleExcel::Trait;
BEGIN {
  $CatalystX::Controller::ExtJS::REST::SimpleExcel::Trait::VERSION = '0.1.1';
}
use Moose::Role;

sub application_to_class_class {
    'CatalystX::Controller::ExtJS::REST::SimpleExcel::ApplicationToClass';
}

1;
__END__
=pod

=head1 NAME

CatalystX::Controller::ExtJS::REST::SimpleExcel::ApplicationToClass

=head1 VERSION

version 0.1.1

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

