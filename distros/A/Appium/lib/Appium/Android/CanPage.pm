package Appium::Android::CanPage;
$Appium::Android::CanPage::VERSION = '0.0804';
# ABSTRACT: Display all interesting elements for Android, useful during authoring
use Moo::Role;
use XML::LibXML;

has _page_printer => (
    is => 'rw',
    default => sub { return sub { print shift . "\n"; } }
);

has _page_parser => (
    is => 'lazy',
    default => sub { return XML::LibXML->new; }
);


sub page {
    my ($self) = @_;

    my $source = $self->get_page_source;
    my $parser = $self->_page_parser;
    my $dom = $parser->load_xml( string => $source );
    my @nodes = $dom->childNodes;

    return $self->_inspect_nodes( @nodes );
}

sub _inspect_nodes {
    my ($self, @nodes) = @_;

    # A node is interesting if it has a text, id, or content-desc
    # attribute.
    my $interesting_attrs = [ qw/text resource-id content-desc/ ];

    foreach my $node (@nodes) {
        # The inspect output for a single node looks like:
        #
        # $class_of_node
        #    text: $node_text
        #    resource-id: $node_id
        #    content-desc: $node_desc
        #
        # We'll keep the lines in an array that we push on to whenever
        # we find interesting things about the node
        my @inspect_output = ( $node->getAttribute('class') );

        my $is_node_interesting = 0;
        foreach my $attr (@$interesting_attrs) {
            if ( $node->hasAttribute( $attr ) ) {
                my $value = $node->getAttribute( $attr );

                # We don't want to display attributes that are empty.
                if ( $value ) {
                    $is_node_interesting++;
                    push @inspect_output, _format_attribute( $attr, $value );
                }
            }
        }

        if ( $is_node_interesting ) {
            # Separate entire nodes with an extra new line
            push @inspect_output, '';
            $self->_page_printer->( join( "\n", @inspect_output ) );
        }

        $self->_inspect_nodes( $node->childNodes );
    }
}

sub _format_attribute {
    my ($name, $value) = @_;

    return "  $name: $value";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Appium::Android::CanPage - Display all interesting elements for Android, useful during authoring

=head1 VERSION

version 0.0804

=head1 METHODS

=head2 page

Display a list of the currently visible elements that have at least
one of the following attributes: C<text>, C<resource-id>, or
C<content-desc>. This is a shadow of
L<arc|https://github.com/appium/ruby_console>'s own page command,
mimicked here for its usefulness during test authoring.

Think of it like a lo-fi version of Chrome's C<Inspect element>.

    $appium->page;
    # android.view.View
    #   resource-id: android:id/action_bar_overlay_layout
    #
    # android.widget.FrameLayout
    #   resource-id: android:id/action_bar_container
    #
    # android.view.View
    #   resource-id: android:id/action_bar
    #
    # android.widget.ImageView
    #   resource-id: android:id/home
    #
    # android.widget.TextView
    #   text: API Demos
    #   resource-id: android:id/action_bar_title
    #
    # android.widget.FrameLayout
    #   resource-id: android:id/content
    #
    # android.widget.ListView
    #   resource-id: android:id/list
    #
    # android.widget.TextView
    #   text: Accessibility
    #   resource-id: android:id/text1
    #   content-desc: Accessibility
    # ...

This behavior is only prepared for native apps; we've no idea what'll
happen if you use this on a webview and/or with chromedriver.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Appium|Appium>

=item *

L<Appium|Appium>

=item *

L<Appium::Android::CanPage|Appium::Android::CanPage>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/appium/perl-client/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
