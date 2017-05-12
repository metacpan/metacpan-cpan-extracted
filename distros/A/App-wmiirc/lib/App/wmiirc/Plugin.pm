package App::wmiirc::Plugin;
{
  $App::wmiirc::Plugin::VERSION = '1.000';
}
# ABSTRACT: Imports modules a plugin needs.
use 5.014;
use Moo::Role;
require Moo;
require App::wmiirc::Util;

has core => (
  is => 'ro',
  required => 0, # TODO: something means this doesn't work
);

sub import {
  # This runs in the plugin itself.
  eval qq{
    package @{[scalar caller 0]};
    BEGIN { Moo->import }
    with 'App::wmiirc::Plugin';
    App::wmiirc::Util->import;
    1;
  } or die;
  feature->import(":5.14"); # TODO: does this work, seem to need use 5.014 too?
  strictures->import(1);
  warnings->unimport('illegalproto');
}

1;

__END__
=pod

=head1 NAME

App::wmiirc::Plugin - Imports modules a plugin needs.

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

