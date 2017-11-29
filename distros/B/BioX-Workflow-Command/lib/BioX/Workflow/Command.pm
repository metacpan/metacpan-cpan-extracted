package BioX::Workflow::Command;

use v5.10;
our $VERSION = '2.3.0';

use MooseX::App qw(Color);

app_strict 0;

with 'BioX::Workflow::Command::Utils::Log';
with 'BioSAILs::Utils::Plugin';
with 'BioSAILs::Utils::LoadConfigs';

option '+config_base' => (
    is      => 'rw',
    default => '.bioxworkflow',
);

sub BUILD {}

after 'BUILD' => sub {
    my $self = shift;

    return unless $self->plugins;

    $self->app_load_plugins( $self->plugins );
    $self->parse_plugin_opts( $self->plugins_opts );

    ##Must reload the configs to get any options from the plugins
    if ( $self->has_config_files ) {
        $self->load_configs;
    }
};


#This class is not compatible with namespace::autoclean...
no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf-8

=head1 NAME

BioX::Workflow::Command - Opinionated Bioinformatics Genomics Workflow Creator

=head1 SYNOPSIS

  biox run -w workflow.yml
  biox -h

=head1 documentation

Full documentation is available at gitbooks. L<Documentation |
https://biosails.gitbooks.io/biox-workflow-command-docs/content/>

=head1 Quick Start

=head2 Get Help

  #Global Help
  biox --help
  biox-workflow.pl --help
  #Help Per Command
  biox run --help

=head2 Run a Workflow

  #Previously biox-workflow.pl --workflow workflow.yaml
  biox run -w workflow.yml #or --workflow
  biox-workflow.pl run --workflow workflow.yml

=head2 Run a Workflow with make like utilities


Using the option --auto_deps will create #HPC deps based on your INPUT/OUTPUTs -
use this with caution. It will only work correctly if INPUT/OUTPUT is complete
and accurate.

  biox run --workflow workflow.yml --auto_deps


=head2 Create a new workflow

This creates a new workflow with rules rule1, rule2, rule3, with a few variables
to help get you started.

  biox new -w workflow.yml --rules rule1,rule2,rule3

=head2 Add a new rule to a workflow

Add new rules to an existing workflow.

  biox add -w workflow.yml --rules rule4

=head2 Check the status of files in your workflow

You must have defined INPUT/OUTPUTs to make use of this rule. If you do, biox
will output a table with information about your files.

  biox stats -w workflow.yml

=head1 DESCRIPTION

BioX::Workflow::Command is a templating system for creating Bioinformatics Workflows.

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 Acknowledgements

As of version 0.03:

This modules continuing development is supported
by NYU Abu Dhabi in the Center for Genomics and
Systems Biology. With approval from NYUAD, this
information was generalized and put on github,
for which the authors would like to express their
gratitude.

Before version 0.03

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.


=head1 SEE ALSO

=cut
