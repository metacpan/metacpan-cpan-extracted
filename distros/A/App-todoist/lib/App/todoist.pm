package App::todoist;
$App::todoist::VERSION = '0.04';
use 5.006;
use strict;
use warnings;
use Net::Todoist;
use Carp qw/ croak /;
use AppConfig::Std;
use File::Slurper qw/ read_lines /;

sub new
{
    my $class = shift;
    my $obj   = bless({}, $class)
                || croak "Can't instantiate App::todoist\n";

    return $obj;
}

sub process_options
{
    my ($self, $opts) = @_;

    my $config        = AppConfig::Std->new()
                        || croak "Can't instantiate AppConfig::Std\n";

    $config->define('token',        { ARGCOUNT => 1 });
    $config->define('project',      { ARGCOUNT => 1 });
    $config->define('importfile',   { ARGCOUNT => 1, ALIAS => 'i' });
    $config->define('priority',     { ARGCOUNT => 1, ALIAS => 'p', DEFAULT => 4 });
    $config->define('add-project',  { ARGCOUNT => 1, ALIAS => 'ap' });

    if (defined($ENV{HOME}) && -f "$ENV{HOME}/.todoist") {
        my $filename = "$ENV{HOME}/.todoist";
        if (((stat($filename))[2] & 36) != 0) {
            croak "your config file ($filename) is readable by others!\n";
        }
        $config->file($filename) || exit 1;
    }

    if ($opts->{argv}) {
        $config->args($opts->{argv})
        || die "run \"$0 -help\" to see valid options\n";
    }

    croak "you must provide a token\n"   unless $config->token;
    if (!$config->project && !$config->get('add-project')) {
        croak "you must either project a project, or add a project\n";
    }

    $self->{config} = $config;

    my $todoist = Net::Todoist->new(token => $config->token)
                  || croak "failed to connect to todoist\n";

    $self->{todoist} = $todoist;

    if ($config->project) {
        my @projects = $todoist->getProjects;
        my ($project) = grep { $_->{name} eq $config->project } @projects;
        if (not defined $project) {
            croak "couldn't find project '", $config->project, "' in todoist\n"
        }
        $self->{project_id} = $project->{id};
    }
}

sub config
{
    my $self = shift;
    return $self->{config};
}

sub todoist
{
    my $self = shift;
    return $self->{todoist};
}

sub run
{
    my ($self, $opts) = @_;

    $self->process_options($opts);

    if ($self->config->importfile) {
        my @tasks = read_lines($self->config->importfile);
        foreach my $task (@tasks) {
            $self->todoist->addItem(
                project_id => $self->{project_id},
                content    => $task,
                priority   => $self->config->priority,
            );
        }
        printf STDERR "%d tasks added from %s\n", int(@tasks),
                      $self->config->importfile;
    }

    if ($self->config->get('add-project')) {
        $self->todoist->addProject(name => $self->config->get('add-project'));
        my @projects = $self->todoist->getProjects;
        my ($project) = grep { $_->{name} eq $self->config->get('add-project') } @projects;
        if (defined($project)) {
            print STDERR "Project added - id = ", $project->{id}, "\n";
        }
        else {
            die "Failed to add project\n";
        }
    }
}

1;

=head1 NAME

App::todoist - command-line for manipulating your todoist.com todo list

=head1 SYNOPSIS

 Add something here

=head1 DESCRIPTION

This module implements the functionality behind the C<todoist> script.
You should look at the documentation for that.

=head1 REPOSITORY

L<https://github.com/neilbowers/App-todoist>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

