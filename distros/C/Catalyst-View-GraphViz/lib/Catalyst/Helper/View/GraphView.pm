package Catalyst::Helper::View::GraphView;

use strict;

=head1 NAME

Catalyst::Helper::View::GraphView - Helper for GraphView Views

=head1 SYNOPSIS

    script/create.pl view GraphView GraphView

=head1 DESCRIPTION

Helper for GraphView Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Johan Lindstrom, C<johanl@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View';

=head1 NAME

[% class %] - Catalyst GraphView View




=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst GraphView View.



=head1 METHODS

=head2 process

Render the object specified in
C<$c-E<gt>stash-E<gt>{graphview}-E<gt>{object}> and store the output
in C<$c-E<gt>response-E<gt>output>.

=cut
sub process {
    my ($self, $c) = @_;


    #This is an example. Adjust to your needs.


    #1. This is your model object containing the abstract graph you are about
    #   to render into a GraphViz object.
    my $graph = $c->stash->{graphview}->{object} or die('No object specified in $c->stash->{graphview}->{object} for rendering');


    #2. Render the model object. This is your View code where you adapt the
    #   look of the graph (node shape, color, etc.)
    my $graphViz = GraphViz->new(node => {
        fontname => "Verdana", fontsize => 7,
        name => "graph",
    });
    $graphViz->add_node("something from $graph", shape => "triangle", color => "black");


    #3. Forward to the GraphViz View
    $c->stash->{graphviz}->{graph} = $graphViz;
    $c->forward('[% app %]::V::GraphViz');


    if($c->res->content_type eq "text/plain") {   #imap
        #4. You may want to post-process imagemap output
        #   Transform it here using something more interesting
        #   than lc(). Useful e.g. for adding javascript events.
        $c->response->body( lc( $c->response->body ) ); 
    }

    return 1;
}





=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
