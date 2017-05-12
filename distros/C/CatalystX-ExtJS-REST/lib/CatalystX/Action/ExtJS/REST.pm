#
# This file is part of CatalystX-ExtJS-REST
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::REST;
$CatalystX::Action::ExtJS::REST::VERSION = '2.1.3';
# ABSTRACT: Mark an action as REST endpoint
use Moose;
extends 'Catalyst::Action';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Action::ExtJS::REST - Mark an action as REST endpoint

=head1 VERSION

version 2.1.3

=head1 DESCRIPTION

The purpose of this action class is to mark an action as REST endpoint. 
Actions with this action will become a L<CatalystX::Controller::ExtJS::Direct::Route::REST> route.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
