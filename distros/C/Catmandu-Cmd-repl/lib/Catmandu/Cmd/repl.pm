package Catmandu::Cmd::repl;

use Catmandu::Sane;
use parent 'Catmandu::Cmd';
use Devel::REPL;

=head1 NAME

Catmandu::Cmd::repl - interactive shell for Catmandu

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    catmandu repl

=cut

sub command_opt_spec {
    ();
}

sub command {
    my ($self, $opts, $args) = @_;

    my @plugins = qw(LexEnv DDC Packages Commands MultiLine::PPI Colors);

    my $init = <<PERL;
use Catmandu::Sane;
use Catmandu qw(:all);
PERL

    my $repl = Devel::REPL->new;
    $repl->load_plugin($_) for @plugins;
    $repl->current_package('main');
    $repl->eval($init);
    $repl->run;
}

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Ghent University Library

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
