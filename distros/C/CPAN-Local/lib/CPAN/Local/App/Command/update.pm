package CPAN::Local::App::Command::update;
{
  $CPAN::Local::App::Command::update::VERSION = '0.010';
}

# ABSTRACT: Update repository

use Moose;
extends 'MooseX::App::Cmd::Command';

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $cpan_local = $self->app->cpan_local;

    my @distros;

    ### COLLECT DISTRIBUTIONS TO INJECT ###
    foreach my $plugin ( $cpan_local->plugins_with('-Gather') )
    {
        push @distros, $plugin->gather(@distros);
    }

    ### REMOVE DUPLICATES, ETC. ###
    foreach my $plugin ( $cpan_local->plugins_with('-Prune') )
    {
        @distros = $plugin->prune(@distros);
    }

    ### INJECT ###
    foreach my $plugin ( $cpan_local->plugins_with('-Inject') )
    {
        @distros = $plugin->inject(@distros);
    }

    ### WRITE RELEVANT INDECES ###
    foreach my $plugin ( $cpan_local->plugins_with('-Index') )
    {
        $plugin->index(@distros);
    }

    ### EXECUTE POST-UPDATE ACTIONS ###
    foreach my $plugin ( $cpan_local->plugins_with('-Finalise') )
    {
        $plugin->finalise(@distros);
    }
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::App::Command::update - Update repository

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  % lpan update

=head1 DESCRIPTION

Update the repository in the current directory.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

