package App::RL;

our $VERSION = '0.2.33';

use App::Cmd::Setup -app;

1;

__END__

=head1 NAME

App::RL - operating chromosome runlist files

=head1 SYNOPSIS

    runlist <command> [-?h] [long options...]
    	-? -h --help    show help

    Available commands:

    commands: list the application's commands
        help: display a command's help screen
  
     combine: combine multiple sets of runlists
     compare: compare 2 chromosome runlists
       cover: output covers of positions on chromosomes
      genome: convert chr.size to runlists
       merge: merge runlist yaml files
    position: compare runlists against positions
        some: extract some records
        span: operate spans in a YAML file
       split: split runlist yaml files
        stat: coverage on chromosomes for runlists
       stat2: coverage on another runlist for runlists

See C<runlist commands> for usage information.

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
