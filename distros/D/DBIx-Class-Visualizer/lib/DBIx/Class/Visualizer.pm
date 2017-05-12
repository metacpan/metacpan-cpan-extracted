use 5.10.1;
use strict;
use warnings;

package DBIx::Class::Visualizer;

# ABSTRACT: Visualize a DBIx::Class schema
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

use Moo;
use GraphViz2;
use Log::Handler;
use List::Util qw/any none/;
use Types::Standard qw/ArrayRef RegexpRef Maybe HashRef InstanceOf Bool/;
use Syntax::Keyword::Gather;
use JSON::MaybeXS qw/encode_json/;
use PerlX::Maybe;
use DBIx::Class::Visualizer::ResultHandler;

has logger_conf => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    default => sub {
        [
            screen => {
                maxlevel => 'debug',
                minlevel => 'emerg',
                message_layout => '%m',
            },
        ];
    },
);
has logger => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Log::Handler->new(@{ shift->logger_conf })
    },
);
has graphviz_conf => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        return +{
            global => {
                directed => 1,
                smoothing => 'none',
                overlap => 'false',
                logger => $self->logger,
            },
            graph => {
                rankdir => 'LR',
                splines => 'true',
                fontname => 'helvetica',
                fontsize => 7,
                labeljust => 'l',
                nodesep => 0.38,
                ranksep => 0.46,
            },
            node => {
                fontname => 'helvetica',
                shape => 'none',
            },
        };
    },
);
has graph => (
    is => 'ro',
    lazy => 1,
    builder => '_build_graph',
    handles => [qw/run/],
);
sub _build_graph {
    return GraphViz2->new(shift->graphviz_conf);
}
has schema => (
    is => 'ro',
    required => 1,
);
has degrees_of_separation => (
    is => 'ro',
    default => 1,
);
has wanted_result_source_names => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);
has skip_result_source_names => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);
has only_keys => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

has result_handlers => (
    is => 'ro',
    isa => ArrayRef[Maybe[InstanceOf['DBIx::Class::Visualizer::ResultHandler']]],
    lazy => 1,
    builder => 1,
);
has has_warned_for_polylines => (
    is => 'rw',
    isa => Bool,
    lazy => 1,
);

sub _build_result_handlers {
    my $self = shift;

    return [
        gather {
            SOURCE:
            for my $source_name (sort $self->schema->sources) {
                my $show = !$self->has_skip_result_source_names && !$self->has_wanted_result_source_names ? 1
                         : (any { $source_name eq $_ } @{ $self->wanted_result_source_names })            ? 1
                         : $self->has_wanted_result_source_names                                          ? 0
                         : (any { $source_name eq $_ } @{ $self->skip_result_source_names })              ? 0
                         : $self->has_skip_result_source_names                                            ? 1
                         :                                                                                  0
                         ;

                take(DBIx::Class::Visualizer::ResultHandler->new(
                    name => $source_name,
                    show => $show,
                    wanted => (any { $source_name eq $_ } (@{ $self->wanted_result_source_names })) ? 1 : 0,
                    skip => (any { $source_name eq $_ } (@{ $self->skip_result_source_names }))     ? 1 : 0,
                    rs   => $self->schema->resultset($source_name)->result_source,
                    only_keys => $self->only_keys,
                ));
            }
        }
    ];
}
sub result_handler {
    my $self = shift;
    my $source_name = shift;
    return (grep { $_->name eq $source_name } @{ $self->result_handlers })[0];
}
sub showable_result_handlers {
    return sort {   $b->wanted <=> $a->wanted
                 || $a->degree_of_separation <=> $b->degree_of_separation
                 || $a->name cmp $b->name
            } grep { $_->show } @{ shift->result_handlers };
}

sub has_wanted_result_source_names { scalar @{ shift->wanted_result_source_names }; }
sub has_skip_result_source_names   { scalar @{ shift->skip_result_source_names }; }
sub any_result_handler_is_wanted {
    my $self = shift;
    my @result_handlers = @_;

    return scalar grep { $_->wanted } @result_handlers;
}

sub BUILD {
    my $self = shift;

    if($self->has_wanted_result_source_names) {
        DEGREES:
        for my $degree_of_separation (1..$self->degrees_of_separation) {
            my @result_handlers = $self->showable_result_handlers;

            HANDLER:
            for my $result_handler (@result_handlers) {

                RELATION:
                for my $relation (@{ $result_handler->relations }) {
                    my $check_result_handler = $self->result_handler($relation->destination_table);
                    next RELATION if $check_result_handler->skip;
                    $check_result_handler->show(1);
                    $check_result_handler->degree_of_separation($degree_of_separation);
                }
            }
        }
    }

    $self->add_node($_)  for $self->showable_result_handlers;
    $self->add_edges($_) for $self->showable_result_handlers;

}

sub svg {
    my $self = shift;

    my $output;
    $self->graph->run(output_file => \$output, format => 'svg');
    return $output;
}
sub transformed_svg {
    my $self = shift;
    my $output = $self->svg;

    if(!eval { require Mojo::DOM; require Mojo::Util; 1; }) {
        $self->logger->info('Using DBIx::Class::Visualizer->transformed_svg requires Mojolicious');
        return $output;
    }

    my $dom = Mojo::DOM->new($output);

    $dom->find('text')->each(sub {
        my $text = shift;
        my $fillattr = $text->attr('fill');

        # remove elements used for padding
        if(defined $fillattr && $fillattr eq 'white') {
            $text->remove;
            return;
        }
        if(!length Mojo::Util::trim($text->text)) {
            $text->remove;
            return;
        }

        # Remove and set attributes on texts
        delete $text->attr->{'font-family'};
        delete $text->attr->{'font-size'};
        $text->attr('data-is-primary' => 1) if delete $text->attr->{'font-weight'};
        $text->attr('data-is-foreign' => 1) if delete $text->attr->{'text-decoration'};
    });

    # Remove attributes and set classes on node polygons
    $dom->find('.node > polygon')->reverse->each(sub {
        my $polygon = shift;
        my $fill = delete $polygon->attr->{'fill'};
        my $stroke = delete $polygon->attr->{'stroke'};

        $polygon->attr(class => $stroke eq '#f0f0f0' ? 'border'
                              : $fill eq '#fefefe'   ? 'column-name'
                              : $fill eq '#dddfdd'   ? 'table-name'
                              :                        'unknown'
        );
    });

    # The first <text> in a .node is the table name
    $dom->find('.node > text:first-of-type')->each(sub {
        my $el = shift;
        delete $el->attr->{'fill'};
        $el->attr->{'class'} = 'table-name';
    });
    # The other <text>s are column names
    $dom->find('.node > text:not(.table-name)')->each(sub {
        my $el = shift;
        delete $el->attr->{'fill'};
        $el->attr(class => 'column-name');
    });

    # Add data attributes to everything in nodes
    $dom->find('.node')->each(sub {
        my $node = shift;
        my $result_handler = $self->result_handler($node->at('text.table-name')->all_text);
        $node->attr('data-table-name', $result_handler->name);
        $node->attr(id => 'node-'.$result_handler->node_name);

        $node->find('text.column-name')->each(sub {
            my $el = shift;
            my $column_name = $el->all_text;
            $el->attr('data-column-name', $column_name);
            $el->attr(id => 'column-'.$result_handler->node_name . '-' . $column_name);
            my $polygon = $el->previous;

            # background polygon
            $polygon->attr('data-column-name', $column_name);
            $polygon->attr(id => 'bg-column-'.$result_handler->node_name . '-' . $column_name);

            $el->attr('data-column-info', encode_json($result_handler->get_column($column_name)->TO_JSON));
        });

        # There might be a tiny <polygon.table-name> on top of the real <polygon.table-name> (used for padding during graphviz creation)
        # We don't want it any more, we only want the last <polygon.table-name> in each .node (or the first since its reversed..)
        $node->find('polygon.table-name')->reverse->each(sub {
            $_[0]->remove if $_[1] > 1;
        });
    });

    # Turn attr points  '6.5,-591.22 6.5,-662.22 158.5,-662.22 158.5,-591.22 6.5,-591.22'
    # into              [{ x => 6.5, y => -591.22 }, ... ]
    my $point_to_hash = sub {
        +{ x => shift, y => shift };
    };

    # <polygon.table-name> leave a small gap to the .border that we don't want.
    # Since the arrows overlap the default .border[stroke-width] the .border x-points
    # are moved inwards a little bit, thereby fixing both problems at once.
    #   There is also a slightly larger gap between <.node polygon.table-name>
    # and the top border created by a padding element removed above. Hence
    # <polygon.table-name> gets their two top y-points set to the .border top y-point.
    #   And finally, there's a gap between <polygon.table-name>
    # and the first <polygon.column-name>, also due to padding during creation.
    # This is removed by setting <polygon.table-name>'s' lower y-points to those of
    # the first <polygon.column-name>.
    $dom->find('.node > polygon.border')->each(sub {
        my $border = shift;
        my $table_name_polygon = $border->parent->at('polygon.table-name');
        my $column_name_polygon = $border->parent->at('polygon.column-name');

        my $border_points      = [map { $point_to_hash->(split /,/) } split / /, $border->attr('points') ];
        my $table_name_points  = [map { $point_to_hash->(split /,/) } split / /, $table_name_polygon->attr('points')];
        my $column_name_points = [map { $point_to_hash->(split /,/) } split / /, $column_name_polygon->attr('points')];

        # 0: bottom left, 1: top left, 2: top right, 3: bottom right, 4: bottom left again
        for my $point (0..4) {
            $border_points->[$point]{'x'} += .75                               if any { $point == $_ } (0, 1, 4);
            $border_points->[$point]{'x'} -= .75                               if any { $point == $_ } (2, 3);

            $table_name_points->[$point]{'x'} = $border_points->[$point]{'x'};
            $table_name_points->[$point]{'y'} = $column_name_points->[1]{'y'}  if any { $point == $_ } (0, 3, 4);
            $table_name_points->[$point]{'y'} = $border_points->[$point]{'y'}  if any { $point == $_ } (1, 2);
        }
        $border->attr(points => join ' ', map { "$_->{'x'},$_->{'y'}" } @{ $border_points });
        $table_name_polygon->attr(points => join ' ', map { "$_->{'x'},$_->{'y'}" } @{ $table_name_points });
    });

    # cleanup edges
    $dom->find('.edge > path, .edge > polygon, .edge > polyline, .edge > ellipse')->each(sub {
        my $el = shift;
        delete $el->attr->{'stroke'};
        delete $el->attr->{'stroke-width'};
        delete $el->attr->{'fill'};
    });
    # Make edges aware of what they are connecting
    $dom->find('.edge')->each(sub {
        my $edge = shift;
        my $title = $edge->at('title');

        if($title->text =~ m{ ^ ([^:]+) : ([^-]+?) -> ([^:;]+) : (.+) $ }x) {
            my $origin_table = $1;
            my $origin_column = $2;
            my $destination_table = $3;
            my $destination_column = $4;

            # Restore table names. See also node_name()
            $origin_table =~ s{__}{::}g;
            $destination_table =~ s{__}{::}g;

            my $relation_type = $self->result_handler($origin_table)->get_relation_between($origin_column, $destination_table, $destination_column)->relation_type;
            my $reverse_relation_type = $self->result_handler($destination_table)->get_relation_between($destination_column, $origin_table, $origin_column)->relation_type;

            $edge->attr(id => sprintf '%s-%s--%s-%s', $origin_table, $origin_column, $destination_table, $destination_column);
            $edge->attr('data-origin-table', $origin_table);
            $edge->attr('data-origin-column', $origin_column);
            $edge->attr('data-destination-table', $destination_table);
            $edge->attr('data-destination-column', $destination_column);
            $title->content("$origin_table.$origin_column\n&#9660; $relation_type | $reverse_relation_type &#9650;\n$destination_table.$destination_column");
        }

        # * There are sometimes annoying gaps between <path> and certain <polyline>s. By nudging
        #   the <path> a little bit outwards (in both directions) they are reduced
        # * Two polylines are created at each arrow to connect the .node with the <path>. This causes
        #   a gap near arrows of type tee. Combine those polylines into one.
        my $path = $edge->at('path');
        (my $path_d = $path->attr('d')) =~ s{^M(?<M>[^,]+) (.*) \s (?<x>[^\s,]+), (?<y>[^\s]+)$}{$2}x;
        my $x = $+{'x'} + .5;
        my $m = $+{'M'} - .6;

        $path->attr(d => "M$m$path_d $x,$+{'y'}");

        # Compare the first two, and the last two, polylines.
        # For each of those pairs:
        #   If the second point of the first polyline is identical to the first point of the second polygon
        #   set the second point of the first polyline to the second point of the second polygon
        #   and then remove the second polygon.
        # (The crow arrow type has only one polyline.)
        my $polylines = [ gather {
            for my $polyline (@{ $edge->find('polyline')->to_array }) {
                take +{
                    element => $polyline,
                    points => [map { $point_to_hash->(split /,/) } split / /, $polyline->attr('points') ],
                };
            }
        } ];

        if(any { !defined $_ } ($polylines->[0]{'points'}[1]{'x'}, $polylines->[1]{'points'}[0]{'x'}, $polylines->[0]{'points'}[1]{'y'}, $polylines->[1]{'points'}[0]{'y'})) {
            if(!$self->has_warned_for_polylines) {
                $self->logger->info('There might be a problem with how at least some relationships are displayed. Feel free to follow up at https://github.com/Csson/p5-DBIx-Class-Visualizer/issues/1');
                $self->has_warned_for_polylines(1);
            }
            return;
        }

        if(    $polylines->[0]{'points'}[1]{'x'} == $polylines->[1]{'points'}[0]{'x'}
            && $polylines->[0]{'points'}[1]{'y'} == $polylines->[1]{'points'}[0]{'y'}) {

            %{ $polylines->[0]{'points'}[1] } = %{ $polylines->[1]{'points'}[1] };

            $polylines->[0]{'element'}->attr(points => join ' ', map { "$_->{'x'},$_->{'y'}" } @{ $polylines->[0]{'points'} });
            $polylines->[1]{'element'}->remove;
        }
        if(    $polylines->[-2]{'points'}[1]{'x'} == $polylines->[-1]{'points'}[0]{'x'}
            && $polylines->[-2]{'points'}[1]{'y'} == $polylines->[-1]{'points'}[0]{'y'}) {

            %{ $polylines->[-2]{'points'}[1] } = %{ $polylines->[-1]{'points'}[1] };

            $polylines->[-2]{'element'}->attr(points => join ' ', map { "$_->{'x'},$_->{'y'}" } @{ $polylines->[-2]{'points'} });
            $polylines->[-1]{'element'}->remove;
        }
    });


    # Fix the graph name
    my $schema_name = ref $self->schema;
    $dom->at('title')->content($schema_name);

    my $rendered = $dom->to_string;
    $rendered =~ s{\n+}{\n}g;

    return $rendered;

}

sub add_node {
    my $self = shift;
    my $result_handler = shift;

    $self->graph->add_node(
        name => $result_handler->node_name,
        label => $self->create_label_html($result_handler),
        margin => 0.01,
    );
}

sub add_edges {
    my $self = shift;
    my $result_handler = shift;

    my $rs = $result_handler->rs;

    COLUMN:
    for my $column (@{ $result_handler->columns }) {

        RELATION:
        for my $relation (@{ $column->relations }) {
            next RELATION if $relation->added_to_graph;

            my $reverse_result_handler = $self->result_handler($relation->destination_table);
            next RELATION if !$reverse_result_handler->show;

            my $reverse_relation = $reverse_result_handler->get_relation_between($relation->destination_column, $result_handler->name, $column->name);

            # If the reverse relation is complicated (as in not a hashref with one key (and one key only))
            # or if it is just missing
            next RELATION if !defined $reverse_relation;

            next RELATION if $reverse_relation->added_to_graph;
            $self->add_edge($result_handler, $relation, $reverse_result_handler, $reverse_relation);

            $relation->added_to_graph(1);
            $reverse_relation->added_to_graph(1);
        }
    }
}
sub add_edge {
    my $self = shift;
    my $result_handler = shift;
    my $relation = shift;
    my $reverse_result_handler = shift;
    my $reverse_relation = shift;

    # We need the arrow setting before possibly
    # inverting the relationships. The arrows
    # should be the same regardless of the direction
    # of the relationship.
    my $arrowtail = $reverse_relation->arrow_type;
    my $arrowhead = $relation->arrow_type;

    # If we have any 'wanted' result sources
    # *and* any of the two involved result_handlers are wanted
    # *and* the origin relation belongs_to the other
    # -> invert the edge direction.
    # (this places nodes that has_many to the current node on the left
    # and nodes that belongs_to to the current node on the right.)
    my $switched = $self->has_wanted_result_source_names
                   && $self->any_result_handler_is_wanted($result_handler, $reverse_result_handler)
                   && $relation->is_belongs_to;

    my %edge = (
        from      => ($switched ? $reverse_result_handler : $result_handler)->node_name,
        to        => ($switched ? $result_handler : $reverse_result_handler)->node_name,
        tailport  => ($switched ? $reverse_relation : $relation)->origin_column,
        headport  => ($switched ? $reverse_relation : $relation)->destination_column,
        arrowtail => ($switched ? $relation : $reverse_relation)->arrow_type,
        arrowhead => ($switched ? $reverse_relation : $relation)->arrow_type,
        dir       => 'both',
        minlen    => 2,
        penwidth  => 2,
    );

    $self->graph->add_edge(%edge);
}

sub create_label_html {
    my $self = shift;
    my $result_handler = shift;

    my $source_name = $result_handler->name;
    my $node_name = $result_handler->node_name;

    my @column_html = gather {
        for my $column (@{ $result_handler->columns }) {

            my $column_name_tag = $column->column_name_label_tag;

            take qq{
            <tr><td align="left" port="@{[ $column->name ]}" bgcolor="#fefefe"> <font point-size="10" color="#222222">$column_name_tag</font><font color="white">_@{[ $self->padding($column->name) ]}</font></td></tr>};
        }
    };

    # Don't change colors here without fixing svg(). Magic numbers..
    my $html = qq{
        <<table cellborder="0" cellpadding="0.8" cellspacing="0" border="1" color="#f0f0f0" width="150">
            <tr><td bgcolor="#DDDFDD" width="150"><font point-size="2"> </font></td></tr>
            <tr><td align="left" bgcolor="#DDDFDD"> <font color="#333333"><b>$source_name</b></font><font color="white">_@{[ $self->padding($source_name) ]}</font></td></tr>
            <tr><td><font point-size="3"> </font></td></tr>
            } . join ('', @column_html) . qq{
        </table>>
    };
    return $html;
}

# graphviz (at least sometimes) draws too small boxes. We pad them a little (and remove the padding in svg())
sub padding {
    my $self = shift;
    my $text = shift;

    return '_' x int (length ($text) / 10);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Visualizer - Visualize a DBIx::Class schema



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10.1+-blue.svg" alt="Requires Perl 5.10.1+" />
<a href="https://travis-ci.org/Csson/p5-DBIx-Class-Visualizer"><img src="https://api.travis-ci.org/Csson/p5-DBIx-Class-Visualizer.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/DBIx-Class-Visualizer-0.0200"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/DBIx-Class-Visualizer/0.0200" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=DBIx-Class-Visualizer%200.0200"><img src="http://badgedepot.code301.com/badge/cpantesters/DBIx-Class-Visualizer/0.0200" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-89.2%-orange.svg" alt="coverage 89.2%" />
</p>

=end html

=head1 VERSION

Version 0.0200, released 2016-09-19.

=head1 SYNOPSIS

    use DBIx::Class::Visualizer;
    use The::DBIxClassSchema;

    my $schema = The::DBIxClassSchema->connect;
    my $svg = DBIx::Class::Visualizer->new(schema => $schema)->svg;

=head1 DESCRIPTION

DBIx::Class::Visualizer is a L<GraphViz2> renderer for L<DBIx::Class> schemas. It is designed to be used as a backend to web applications that
can display the rendered graph in a more user friendly way. See L<Mojolicious::Plugin::DbicSchemaViewer>.

=head1 STATUS

Backwards compatability between even minor releases is currently not a goal. That said, the public interface is small and most
breaking changes are likely to be in L</transformed_svg>.

=head1 ATTRIBUTES

=head2 schema

Required. An instance of a L<DBIx::Class::Schema> class.

=head2 logger_conf

Optional array reference. L<GraphViz2> uses L<Log::Handler>, so this distribution does that too. By default it noisily prints to screen. Not used if C<logger> is set.

=head2 logger

Optional. An instance of L<Log::Handler>.

=head2 wanted_result_source_names

Optional. An array reference consisting of result source names (without the .*::Result:: prefix) you wish to include in the output. This can
be useful to focus on a small part of large schemas.

If it is not set all result sources will be rendered (minus L</skip_result_source_names>).

=head2 skip_result_source_names

Optional. An array reference consisting of result source names (without the .*::Result:: prefix) you wish to not include in the output.

=head2 degrees_of_separation

Optional. A non-negative integer that is used together with L</wanted_result_source_names>. In addition to the wanted result sources, this attribute
defines how many relationship steps should be followed to other result sources that also should be included in the output.

Default is C<1>.

=head2 only_keys

Boolean, defaults to C<0>. If true, only primary and foreign key columns will be rendered.

=head2 graphviz_conf

Optional hashref. This hashref is passed to the L<GraphViz2> constructor. The output from L</transformed_svg> is adapted to the default settings, so
using these two together might cause a less usable svg document.

Won't be used if you pass C<graph> to the constructor.

=head2 graph

Optional. A L<GraphViz2> object. Pass this if you need to use an already constructed graph.

After L</new> has run it can be useful if you, for example, wishes to see the arguments to the dot renderer:

    my $visualizer = DBIx::Class::Visualizer->new(schema => $schema);
    my $svg = $visualizer->svg;

    my $dotfile = $visualizer->graph->dot_input;

=head1 METHODS

=head2 new

The constructor.

=head2 svg

Takes no arguments, and returns the graph as an svg string.

=head2 run

A shortcut for L<GraphViz2/run>:

    DBIx::Class::Visualizer->new(schema => $schema)->run(output_file => 'myschema.png', format => 'png');

=head2 transformed_svg

Takes no arguments. Returns an svg string that is more useful than that from L</svg> Using this method requires L<Mojolicious>.

This method improves the svg generated by L<graphviz|http://graphviz.org/> in several ways:

=over 4

=item *

All layout attributes (eg. C<fill>, C<stroke>, C<font-family>) are removed so that styling can be done using css.

=item *

There are occasional minor gaps between the various elements in edges, these are removed (or at least reduced).

=item *

This distribution adds some padding between texts and borders to avoid overlapping. These are removed so that no unnecessary elements remain.

=item *

All edges, nodes and column name elements get relevant values for their id attributes.

=item *

Several C<data-> attributes are added to edges, nodes and column attributes containing a lot of information about the schema.

=back

As an example, this is a column element as rendered by C<graphviz> (whitespace added for readability:

    <text text-anchor="start"
           x="700.391"
           y="-17.9"
           font-family="Helvetica,sans-Serif"
           font-weight="bold"
           font-size="10.00"
           fill="#222222">a_column_id</text>

After passing through C<transformed_svg> the same column looks like this:

    <text id="column-TableName-a_column_id"
          class="column-name"
          y="-17.9"
          x="700.391"
          text-anchor="start"
          data-is-primary="1"
          data-column-name="a_column_id"
          data-column-info="{
            "name": "a_column_id",
            "data_type": "integer",
            "is_primary_key": 1
            "is_auto_increment": 1,
            "is_nullable": 0,
            "is_foreign_key": 0,
            "is_numeric": 1,
            "extra": {},
            "relations":[
                {
                    "origin_table": "TableName",
                    "origin_column": "a_column_id",
                    "destination_table": "AnotherTableName"
                    "destination_column": "a_column_id",
                    "relation_type": "has_many",
                    "cascade_delete": 1,
                },
                ...
            ],
          }">a_column_id</text>

The C<data-column-info> attribute is a json object that is directly usable by something like jQuery:

    # has_many
    $('#column-TableName-a_column_id').data('column-info').relations[0].relation_type;

=head1 SEE ALSO

=over 4

=item *

L<Mojolicious::Plugin::DbicSchemaViewer> - A L<Mojolicious> plugin that uses this class

=item *

L<GraphViz2::DBI> - Visualizes a schema by inspecting the database.

=back

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Visualizer>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Visualizer>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
