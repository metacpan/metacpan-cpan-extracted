package App::PrereqGrapher;
$App::PrereqGrapher::VERSION = '0.14';
#
# ABSTRACT: generate dependency graph using Perl::PrereqScanner
#

use 5.006;
use strict;
use warnings;

use Carp;
use Moo;
use Perl::PrereqScanner;
use Getopt::Long qw/:config no_ignore_case/;
use Graph::Easy;
use Module::Path qw(module_path);
use Module::CoreList;

my %formats =
(
    'dot'  => sub { $_[0]->as_graphviz; },
    'svg'  => sub { $_[0]->as_svg; },
    'gml'  => sub { $_[0]->as_graphml; },
    'vcg'  => sub { $_[0]->as_vcg; },
    'html' => sub { $_[0]->as_html_file; },
);

has format => (
    is      => 'ro',
    isa     => sub { croak "valid formats: ", join(", ", keys %formats), "\n"  unless exists $formats{$_[0]}; },
    default => sub { return 'dot'; },
);

has output_file => (
    is  => 'ro',
);

has no_core => (
    is => 'ro',
);

has no_recurse_core => (
    is => 'ro',
);

has verbose => (
    is => 'ro',
);

has depth => (
    is => 'ro',
    isa => sub { croak "depth must be an integer\n" unless $_[0] =~ /^\d+$/; },
);

has timeout => (
    is => 'ro',
    isa => sub { croak "timeout must be an integer\n" unless $_[0] =~ /^\d+$/; },
);

sub new_with_options
{
    my $class    = shift;
    my %options  = $class->parse_options();
    my $instance = $class->new(%options, @_);

    return $instance;
}

sub parse_options
{
    my $class = shift;
    my %options;
    my %format;

    GetOptions(
        'h|help'              => \$options{'help'},
        'd|depth=i'           => \$options{'depth'},
        't|timeout=i'         => \$options{'timeout'},
        'o|output-file=s'     => \$options{'output_file'},
        'nc|no-core'          => \$options{'no_core'},
        'nrc|no-recurse-core' => \$options{'no_recurse_core'},
        'v|verbose'           => \$options{'verbose'},
        'dot'                 => \$format{'dot'},
        'svg'                 => \$format{'svg'},
        'gml'                 => \$format{'gml'},
        'vcg'                 => \$format{'vcg'},
        'html'                => \$format{'html'},
    ) || croak "Can't get options.";
    usage() if $options{'help'};

    foreach my $format (keys %formats) {
        delete $format{$format} unless $format{$format};
    }
    if (keys %format > 1) {
        print "FORMAT: ", join(', ', keys %format), "\n";
        croak "you can only specify at most ONE output format (default is 'dot')";
    }
    if ($format{svg}) {
        eval {
            require Graph::Easy::As_svg;
        };
        if ($@) {
            croak "You don't have Graph::Easy::As_svg installed, ",
                  "so I can't generate SVG";
        }
    }
    $format{dot} = 1 unless keys %format == 1;

    if ($options{no_core} && $options{no_recurse_core}) {
        croak "doesn't make sense to specify no-core and no-recurse-core together";
    }

    for (keys %options) {
        delete $options{$_} unless defined $options{$_};
    }
    $options{format} = (keys %format)[0];

    return %options;
}

sub generate_graph
{
    my ($self, @inputs) = @_;
    my (@queue, %seen, $scanner, $graph, $module);
    my ($prereqs, $depsref);
    my ($path, $filename, $fh);
    my $module_count = 0;
    my %depth;

    $scanner = Perl::PrereqScanner->new;
    $graph   = Graph::Easy->new();
    $graph->timeout($self->timeout);

    @depth{@inputs} = map { 0 } @inputs;

    push(@queue, @inputs);
    while (@queue > 0) {
        $module = shift @queue;
        next if $seen{$module};
        $seen{$module} = 1;

        if (defined($path = module_path($module))) {
        } elsif (-f $module) {
            $path = $module;
        } else {
            carp "can't find $module - keeping calm and carrying on.\n" if $self->verbose;
            next;
        }

        # Huge files (eg currently Perl::Tidy) will cause PPI to barf
        # So we need to catch those, keep calm, and carry on
        eval { $prereqs = $scanner->scan_file($path); };
        next if $@;
        ++$module_count;
        $depsref = $prereqs->as_string_hash();
        foreach my $dep (keys %{ $depsref }) {
            if (!exists($depth{$dep}) || $depth{$dep} > $depth{$module} + 1) {
                $depth{$dep} = $depth{$module} + 1;
            }
            if ($self->no_core && is_core($dep)) {
                # don't include core modules
            } elsif ($dep eq 'perl') {
                $graph->add_edge($module, "perl $depsref->{perl}");
            } else {
                $graph->add_edge($module, $dep);
                next if $self->depth && $depth{$dep} >= $self->depth;
                push(@queue, $dep) unless $self->no_recurse_core && is_core($dep);
            }
        }
    }

    $filename = $self->output_file || 'dependencies.'.$self->format;
    open($fh, '>', $filename) ||
        croak "Failed to write $filename: $!\n";
    print $fh $formats{$self->format}->($graph);
    close($fh);
    print STDERR "$module_count modules processed. Graph written to $filename\n" if $self->verbose;
}

sub is_core
{
    my $module   = shift;
    my $version  = @_ > 0 ? shift : $^V;

    return 0 unless defined(my $first_release = Module::CoreList::first_release($module));
    return 0 unless $version >= $first_release;
    return 1 if !defined(my $final_release = Module::CoreList::removed_from($module));
    return $version <= $final_release;
}

sub usage
{
    require Pod::Usage;
    Pod::Usage::pod2usage();
    exit;
}

1;

=head1 NAME

App::PrereqGrapher - generate dependency graph using Perl::PrereqScanner

=head1 SYNOPSIS

  use App::PrereqGrapher;

  my %options = (
                          format => 'dot',
                         no_core => 0,
                 no_recurse_core => 1,
                     output_file => 'prereqs.dot',
                         verbose => 0,
                );
  my $grapher = App::PrereqGrapher->new( %options );

  $grapher->generate_graph('Module::Path');

=head1 DESCRIPTION

App::PrereqGrapher builds a directed graph of the prereqs or dependencies for
a file or module. It uses Perl::PrereqScanner to find the dependencies for the seed,
and then repeatedly calls Perl::PrereqScanner on those dependencies, and so on,
until all dependencies have been found.

It then saves the resulting graph to a file, using one of the five supported formats.
The default format is 'dot', the format used by the GraphViz graph drawing toolkit.

If your code contains lines like:

 require 5.006;
 use 5.006;

Then you'll end up with a dependency labelled B<perl 5.006>;
this way you can see where you're dependent on modules which
require different minimum versions of perl.

=head1 METHODS

=head2 new

The constructor understands the following options:

=over 4

=item format

Select the output format, which must be one of: dot, svg, vcg, gml, or html.
See L</"OUTPUT FORMATS"> for more about the supported output formats.
If not specified, the default format is 'dot'.

=item output_file

Specifies the name of the file to write the dependency graph into,
including the extension. If not specified, the filename will be C<dependencies>,
with the extension set according to the format.

=item depth

Only generate the graph to the specified depth.
If the complete dependency graph is very large, this option may help you get
an overview.

=item no_core

Don't include any modules which are core (included with perl) for the version
of perl being used.

=item no_recurse_core

When a core module is used, include it in the dependency graph,
but don't show any of I<its> dependencies.

=item timeout

Specifies the timeout for Graph::Easy when its laying out the graph.
This is mainly relevant for formats like SVG and HTML, where the graph
layout is done in Perl. Defaults to 5 seconds.

=item verbose

Display verbose logging as the grapher runs.
Currently this will just tell you if a module was use'd or require'd,
but couldn't be found locally.

=back

=head2 generate_graph

Takes one or more seed items. Each item may be a module or the path to a perl file.

  $grapher->generate_graph('Module::Path', 'Module::Version');

It will first try and interpret each item as a module, but if it can't find a module
with the given name, it will try and interpret it as a file path.
This means that if you have a file called C<strict> for example, then you won't be
able to run:

  $grapher->generate_graph('strict');

as it will be interpreted as the module of that name. Put an explicit path to stop this:

  $grapher->generate_graph('./strict');

=head1 OUTPUT FORMATS

=over 4

=item dot

The format used by GraphViz and related tools.

=item svg

Scalable Vector Graphics (SVG) a W3C standard.
You have to install L<Graph::Easy::As_svg> if you want to use this format.

=item vcg

The VCG or GDL format.

=item gml

Graph Markup Language, aka GraphML.

=item html

Generate an HTML format with embedded CSS. I haven't been able to get this to work,
but it's one of the formats supported by L<Graph::Easy>.

=back

=head1 KNOWN BUGS

L<Perl::PrereqScanner> uses L<PPI> to parse each item.
PPI has a hard-coded limit for the size of file it's prepared to parse
(currently just over 1M).
This means that very large files will be ignored;
for example Perl::Tidy cannot be graphed,
and if you try and graph a file that use's Perl::Tidy,
then it just won't appear in the graph.

If a class isn't defined in its own file,
then App::PrereqGrapher won't find it;
for example Tie::StdHash is defined inside Tie::Hash.
By default these are silently ignored,
but if you use the B<-verbose> option you'll get the following warning:

  can't find Tie::StdHash - keeping calm and carrying on.

Perl::PrereqScanner parses code and makes no attempt to
determine whether any of it would actually run on your platform.
For example, one module might decide at run-time whether to C<require>
Foo::Bar or Foo::Baz, and might never use Foo::Baz on your OS.
But Perl::PrereqScanner will see both of Foo::Bar and Foo::Baz
as pre-reqs.

=head1 TODO

=over 4

=item *

Have an option to control what depth we should recurse to?
You might only be interested in the dependencies of your code,
and their first level of dependencies.

=item *

Show some indication that we're running. It can take a long time to run
if your ultimate dependency graph is very large.

=back

=head1 SEE ALSO

The distribution for this module contains a command-line script,
L<prereq-grapher>. It has its own documentation.

This module uses L<Perl::PrereqScanner> to parse the source code,
and L<Graph::Easy> to generate and save the dependency graph.

If you want to generate SVG graphs, you need to have L<Graph::Easy::As_svg> installed.

L<http://neilb.org/reviews/dependencies.html>: a review of CPAN modules that can be used
to get dependency information.

=head1 REPOSITORY

L<https://github.com/neilb/App-PrereqGrapher>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

