package App::Dothe;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: YAML-based task runner
$App::Dothe::VERSION = '0.0.1';
use 5.20.0;
use warnings;

use MooseX::App::Simple;

use YAML::XS qw/ LoadFile /;
use App::Dothe::Task;

use Log::Any::Adapter;
Log::Any::Adapter->set('Stdout', log_level => 'info' );

use List::AllUtils qw/ pairmap /;

use Text::Template;

use experimental qw/ signatures postderef /;

option debug => (
    is => 'ro',
    documentation => 'enable debugging logs',
    default => 0,
    isa => 'Bool',
    trigger => sub {
        Log::Any::Adapter->set('Stdout', log_level => 'debug' );
    },
);

option force => (
    is => 'ro',
    documentation => 'force the tasks to be run',
    default => 0,
    isa => 'Bool',
);

parameter target => (
    is => 'ro',
    required => 1,
);

has raw_vars => (
    is	    => 'ro',
    isa 	=> 'HashRef',
    init_arg => 'vars',
    default => sub($self) {
        $self->config->{vars} || {}
    },
);

has vars => (
    is => 'ro',
    lazy => 1,
    isa => 'HashRef',
    builder => '_build_vars',
    init_arg => undef,
);

use Ref::Util qw/ is_arrayref is_hashref /;

sub render($self,$template,$vars) {
    if( is_arrayref $template ) {
        return [ map { $self->render($_,$vars) } @$template ];
    }

    if( is_hashref $template ) {
        return { pairmap { $a => $self->render($b,$vars) } %$template }
    }

    return $self->template($template)->fill_in(HASH => $vars );
}

sub _build_vars($self) {
    my %vars;

    %vars = (
        %vars,
        pairmap { $a => $self->render( $b, \%vars ) } $self->raw_vars->%*
    );

    return \%vars;
}

has tasks => (
    is => 'ro',
    lazy => 1,
    traits => [ 'Hash' ],
    default => sub($self) { +{} },
);

sub task($self,$name) {
    return $self->{tasks}{$name} ||= App::Dothe::Task->new(
        name => $name, tasks => $self, $self->config->{tasks}{$name}->%* );
}

option file => (
    is => 'ro',
    documentation => 'configuration file',
    isa => 'Str',
    default => './Dothe.yml',
);

has config => (
    is => 'ro',
    lazy => 1,
    default => sub($self) { LoadFile( $self->file ) },
);

sub run( $self ) {

    if ( my $code = $self->config->{code} ) {
        eval join '', 'package App::Dothe::Sandbox;', @$code;
    }

    $self->task($self->target)->run;

}

sub template ($self,$source) {
    return Text::Template->new( TYPE => 'STRING', DELIMITERS => [ '{{', '}}' ],
        SOURCE => $source );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Dothe - YAML-based task runner

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

Task runner heavily inspired by Task (L<https://github.com/go-task/task>).
Basically, I wanted C<Task>, but with a C<foreach> construct.

See C<perldoc App::DoThe> for the syntax of the F<Dothe.yml> file.

=head1 DOTHE SYNTAX

The configuration file is in YAML. It follows, by and large, the
format used by Task.

By default, `dothe` looks for the file `Dothe.yml`.

Where entries can be templates, they are evaluated via L<Text::Template>.
Basically, that means that in a template all that is surrounded by double curley braces
is evaluated as Perl code. Those code snippets are evaluated within the
C<App::Dothe::Sandbox> namespace, and have all the C<vars> variables
accessible to them.

=head2 C<code> section

Takes an array. Each item will be eval'ed in the namespace
used by the template code.

For example, to have access to L<Path::Tiny>'s
C<path>:

    code:
        - use Path::Tiny;

    tasks:
        import-all:
            sources:
                - /home/yanick/work/blog_entries/**/entry
            foreach: sources
            cmds:
                - task: import
                  vars: { dir: '{{ path($item)->parent }}' }

=head2 C<vars> section

Takes a hash of variable names and values. Those are variables that will be accessible to all
tasks.

E.g.,

    vars:
        entries_file: ./content/_shared/entries.md
        blog_entries_root: /home/yanick/work/blog_entries

=head2 C<tasks> section

Takes a hash of task names and their definitions.

E.g.,

    tasks:

        something:
            sources: [ ./src/foo.source ]
            generates: [ ./dest/foo.dest ]
            foreach: sources
            cmds:
                - ./tools/process_entry.pl {{$item}}

=head3 C<task>

Defines a specific task.

=head4 C<vars>

Hash of variable names and values to be made accessible to the
task and its subtasks.

Variable values can be templates, which have visibility of
previously declared variables.

A locally defined variable will mask the definition of a global
variable.

=head4 C<deps>

Array of task dependencies. If present, Dothe will build the graph
of dependencies (via L<Graph::Directed>) and run them in their
topological order.

    deploy:
        deps: [ clean, build, test ]
        cmds:
            - dzil release

=head4 C<sources>

Array of files. Can take glob patterns that will be expanded using
L<Path::Tiny::Glob>. The result is accessible via the C<sources> variable.

    foo:
        sources: [ './lib/**/*.pm' ]
        foreach: sources
        cmds:
            - perl -c {{$item}}

=head4 C<generates>

Array of files. If C<sources> and C<generates> are both given, the task will
only be run if any of the sources (or the F<Dothe.yml> file itself) has been
modified after the C<generates> files.

Can take glob patterns that will be expanded using
L<Path::Tiny::Glob>. The result is accessible via the C<generates> variable.

=head4 C<foreach>

Takes the name of a variable that must hold an array. If presents,
the C<cmds> will be run for each value of that variable, which will
be accessible via C<$item>.

=head4 C<cmds>

List of shell commands to run. The entries can be templates.
As soon as one command fails, the task aborts.

    deploy:
        vars:
            important_test: ./xt/test.t
        cmds:
            - dzil build
            - perl {{ $important_test }}
            - dzil release

A command can also be a subtask, with potentially some associated variables:

    stuff:
        cmds:
            - task: other_stuff
              vars:
                foo: bar
                baz: quux

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
