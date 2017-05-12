package Catalyst::Plugin::DBIC::Schema::Profiler;

# $Id$

use strict;
use warnings;

use NEXT;
use Catalyst::Plugin::DBIC::Schema::Profiler::DebugObj;

our $VERSION = '0.06';

=head1 NAME

Catalyst::Plugin::DBIC::Schema::Profiler - Profile time query took with DBIC::Schema in your Catalyst application.

=head1 SYNOPSIS

  # MyApp.pm
  use Catalyst qw/
      ...
      DBIC::Schema::Profiler    # Load this plugin.
      ...
    /;

  
  # myapp.yml
  DBIC::Schema::Profiler:
      MODEL_NAME: DBIC


=head1 DESCRIPTION

  This plugin is only active in -Debug mode.

=cut

sub prepare {
    my $c = shift;
    $c = $c->NEXT::prepare(@_);

    my $model_name = $c->config->{'DBIC::Schema::Profiler'}->{MODEL_NAME}
      || return $c;

    if ( $c->debug ) {
        $c->model($model_name)->schema->storage->debug(1);
        $c->model($model_name)->schema->storage->debugobj(
            Catalyst::Plugin::DBIC::Schema::Profiler::DebugObj->new(
                log => $c->log
            )
        );
    }

    return $c;
}

=head1 AUTHOR

Ryuzo Yamamoto, E<lt>ryuzo.yamamoto@gmail.comE<gt>

=head1 SEE ALSO

L<Catalyst::Plugin::DBIC::Profiler>, L<Catalyst>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006-2010 by Yamamoto Ryuzo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
