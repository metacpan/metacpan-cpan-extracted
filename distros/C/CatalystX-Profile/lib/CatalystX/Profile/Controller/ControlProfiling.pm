# ABSTRACT: Control profiling within your application
package CatalystX::Profile::Controller::ControlProfiling;
BEGIN {
  $CatalystX::Profile::Controller::ControlProfiling::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use Devel::NYTProf;

sub stop_profiling : Local {
    my ($self, $c) = @_;
    DB::finish_profile();
    $c->log->debug('Profiling has now been disabled');
    $c->body('Profiling finished');
}

1;


__END__
=pod

=head1 NAME

CatalystX::Profile::Controller::ControlProfiling - Control profiling within your application

=head1 VERSION

version 0.02

=head1 DESCRIPTIONS

Some actions you can use to control profiling

=head1 ACTIONS

=head2 stop_profiling

Stop and finish profiling, and write all the output. This can be a bit
slow while the profiling data is written, but that's normal.

=head1 AUTHOR

Oliver Charles <oliver.g.charles@googlemail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Oliver Charles.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

