# $Id: XML.pm 1072 2006-01-04 05:01:11Z btrott $

package Catalyst::View::Atom::XML;
use strict;
use base qw( Catalyst::Base );

sub process {
    my($self, $c) = @_;

    my $obj = $c->stash->{xml_atom_object};
    unless ($obj) {
        $c->log->debug("No Atom object specified for rendering")
            if $c->debug;
        return 0;
    }

    unless ($c->response->content_type) {
        $c->response->content_type('application/atom+xml');
    }

    $c->response->body($obj->as_xml);

    1;
}

1;
__END__

=head1 NAME

Catalyst::View::Atom::XML - XML serialization for Atom objects

=head1 SYNOPSIS

    package My::App::View::XML;
    use strict;
    use base qw( Catalyst::View::Atom::XML );
    1;

=head1 DESCRIPTION

I<Catalyst::View::Atom::XML> provides automatic serialization of
I<XML::Atom> objects for a Catalyst application. Your application needs only
set C<$c-E<gt>stash-E<gt>{xml_atom_object}>, then I<forward> to your view,
to serialize an I<XML::Atom> object.

For example:

    sub foo {
        my($self, $c) = @_;
        my $entry = XML::Atom::Entry->new;
        $entry->title('Foo');
        $c->stash->{xml_atom_object} = $entry;
    }

    sub end : Private {
        my($self, $c) = @_;
        $c->forward('My::App::View::XML');
    }

=cut
