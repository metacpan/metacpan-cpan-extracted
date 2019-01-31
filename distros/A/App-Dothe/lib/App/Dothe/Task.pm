package App::Dothe::Task;
our $AUTHORITY = 'cpan:YANICK';
$App::Dothe::Task::VERSION = '0.0.1';
use 5.20.0;
use warnings;

use Moose;

use Log::Any qw($log);
use Types::Standard qw/ ArrayRef InstanceOf /;
use Type::Tiny;
use List::AllUtils qw/ min pairmap /;
use Ref::Util qw/ is_arrayref is_hashref /;
use PerlX::Maybe;
use Text::Template;
use Path::Tiny;
use File::Wildcard;


use experimental qw/
    signatures
    postderef
/;

has name => (
    is       => 'ro',
    required => 1,
);


has cmds => (
    is => 'ro',
    lazy => 1,
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        commands => 'elements',
    },
);

has raw_sources => (
    is => 'ro',
    init_arg => 'sources',
    default => sub { [] },
);

has raw_generates => (
    is => 'ro',
    init_arg => 'generates',
    default => sub { [] },
);

has sources => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub($self) {
        $self->vars->{sources} = $self->expand_files( $self->raw_sources )
    },
);

has generates => (
    is => 'ro',
    init_arg => undef,
    lazy => 1,
    default => sub ($self){
        $self->vars->{generates} = $self->expand_files( $self->raw_generates )
    },
);

sub expand_files($self, $list ) {
    $list = [ $list ] unless ref $list;

    [
    map { File::Wildcard->new( path=> $_ )->all }
    map { s!\*\*!/!gr }
    map { $self->render( $_, $self->vars ) }
    @$list ]
}


has tasks => (
    is	    => 'ro',
    required => 1,
);



sub latest_source_mod($self) {
    return min map { -M "".$_ } $self->sources->@*;
}

sub latest_generate_mod($self) {
    return min map { -M "".$_ } $self->generates->@*;
}

sub is_uptodate ($self) {
    return 0 if $self->tasks->force;

    my $source = $self->latest_source_mod;
    my $gen = $self->latest_generate_mod;

    return ( $gen and $source >= $gen );
};

has raw_vars => (
    is	    => 'ro',
    isa 	=> 'HashRef',
    init_arg => 'vars',
    default => sub {
        +{}
    },
);

has vars => (
    is => 'ro',
    lazy => 1,
    init_arg => undef,
    isa => 'HashRef',
    builder => '_build_vars',
);


sub render($self,$template,$vars) {
    if( is_arrayref $template ) {
        return [ map { $self->render($_,$vars) } @$template ];
    }

    if( is_hashref $template ) {
        return { pairmap { $a => $self->render($b,$vars) } %$template }
    }

    no warnings 'uninitialized';
    $self->template( $template )->fill_in( HASH => $vars,
        PACKAGE => 'App::Dothe::Sandbox',
    );
}

sub _build_vars($self) {
    my %vars = ( $self->tasks->vars->%*, $self->raw_vars->%* );

    %vars = (
        %vars,
        pairmap { $a => $self->render( $b, \%vars ) }
            $self->raw_vars->%*
    );

    return \%vars;
}

has foreach => (
    is	    => 'ro',
    isa 	=> 'Str',
);

sub foreach_vars($self) {
    my $foreach = $self->foreach or return;

    $self->sources;
    $self->generates;

    return map { +{ item => $_ } } $self->vars->{$foreach}->@*;
}

has deps => (
    is	    => 'ro',
    isa 	=> 'ArrayRef',
    default => sub {
        []
    },
);

sub dependency_tree($self, $graph = undef ) {
    require Graph::Directed;

    $graph ||= Graph::Directed->new;

    return $graph
        if $graph->get_vertex_attribute( $self->name, 'done' );

    $graph->set_vertex_attribute( $self->name, 'done', 1 );

    for my $dep ( $self->deps->@* ) {
        $graph->add_edge( $dep => $self->name );
        $self->tasks->task($dep)->dependency_tree($graph);
    }

    return $graph;
}

sub dependencies($self) {
    return grep { $_ ne $self->name } $self->dependency_tree->topological_sort;
}

sub run($self) {
    my @deps = $self->dependencies;

    $self->tasks->task($_)->run for @deps;

    $log->infof( "running task %s", $self->name );

    if ( $self->is_uptodate ) {
        $log->infof( '%s is up-to-date', $self->name );
        return;
    }

    my $vars = $self->vars;
    $self->sources;
    $self->generates;

    if( $self->foreach ) {
        for my $entry ( $self->foreach_vars ) {
            App::Dothe::Task->new(
                tasks => $self->tasks,
                name => ( join ' - ', $self->name, values %$entry ),
                sources => $self->sources,
                generates => $self->generates,
                vars => { %$vars, %$entry },
                cmds => $self->cmds,
            )->run;
        }
        return;
    }

    for my $command ( $self->commands ) {
            $self->run_command( $command, $vars );
    }

}

sub run_command($self,$command,$vars) {

    if( !ref $command ) {
        $command = { cmd => $command };
    }

    if( my $subtask = $command->{task} ) {
            my $t = $self->tasks->task($subtask);
            my $newt = App::Dothe::Task->new(
                name => $t->name,
                tasks => $t->tasks,
                maybe foreach => $t->foreach,
                sources => $t->raw_sources,
                generates => $t->raw_generates,
                vars => {
                    $self->vars->%*,
                    $t->vars->%*,
                    eval { $command->{vars}->%* }
                },
                cmds => $t->cmds,
            );
            $newt->run;
            return;
    }


    no warnings 'uninitialized';
    my $processed = $self->template( $command->{cmd} )->fill_in(
        HASH => $vars,
        PACKAGE => 'App::Dothe::Sandbox',
    );

    $log->debug( "vars", $vars );
    $log->infof( "> %s", $processed );
    system $processed and die "command failed, aborting\n";
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

App::Dothe::Task

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
