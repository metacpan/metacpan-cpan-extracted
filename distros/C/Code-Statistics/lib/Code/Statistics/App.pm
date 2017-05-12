use strict;
use warnings;

package Code::Statistics::App;
{
  $Code::Statistics::App::VERSION = '1.112980';
}

# ABSTRACT: handles global command configuration and cstat instantiation

use App::Cmd::Setup -app;

use Code::Statistics;

sub global_opt_spec {
    my @opts             = (
        [ 'global_conf_file|g=s' => 'path to the global config file' ],
        [ 'conf_file|c=s'        => 'path to the local config file' ],
        [ 'profile|p=s'          => 'a configuration profile' ],
    );
    return @opts;
}


sub cstat {
    my ( $self, %command_args ) = @_;

    my %args = ( %{ $self->global_options }, command => ( $self->get_command( @ARGV ) )[0], );

    return Code::Statistics->new( %args, args => \%command_args );
}

1;

__END__
=pod

=head1 NAME

Code::Statistics::App - handles global command configuration and cstat instantiation

=head1 VERSION

version 1.112980

=head2 cstat
    Creates a Code::Statistics object with the given commandline args.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

