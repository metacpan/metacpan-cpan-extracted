use strict;
use warnings;

package Code::Statistics::App::Command::report;
{
  $Code::Statistics::App::Command::report::VERSION = '1.112980';
}

# ABSTRACT: the shell command handler for stat reporting

use Code::Statistics::App -command;

sub abstract { return 'create reports on statistics and output them' }

sub opt_spec {
    my @opts = (
        [ 'quiet' => 'prevents writing of report to screen' ],
        [ 'file_ignore=s' => 'list of regexes matching files that should be ignored in reporting ' ],
    );
    return @opts;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    return $self->cstat( %{$opt} )->report;
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::App::Command::report - the shell command handler for stat reporting

=head1 VERSION

version 1.112980

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

