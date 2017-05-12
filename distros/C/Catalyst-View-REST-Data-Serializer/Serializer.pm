package Catalyst::View::REST::Data::Serializer;

use warnings;
use strict;
use base qw/Catalyst::Base/;
use Data::Serializer;
use Data::Dumper;

our $VERSION = "0.02";

__PACKAGE__->mk_classdata('_serializer');

=head1 NAME

Catalyst::View::REST::Data::Serializer - Data::Serializer View Class

=head1 SYNOPSIS

    # lib/MyApp/View/REST.pm
    package MyApp::View::REST;

    use base 'Catalyst::View::REST::Data::Serializer';

    1;

    $c->forward('MyApp::View::REST');

=head1 DESCRIPTION

This is the C<Data::Serializer> view class.  It can be used to use any
number of Serialization methods (YAML, Storable, Data::Dumper) to implement
a REST view.  It also supports optional compression, encryption, and a host
of other useful goodies.  

=head2 CONFIGURATION OPTIONS

Any of the options you can pass to L<Data::Serializer> you can put into
$c->config->{'serializer'}, and have them passed on to it.  If you don't
pass any options, the following are used:

            serializer       => 'Data::Dumper',
            digester         => 'SHA1',
            cipher           => 'Blowfish',
            secret           => undef,
            portable         => '1',
            compress         => '0',
            serializer_token => '1',
            options          => {},

They are the same as the Data::Serializer defaults.  The two additional
options are:

=head3 astext

Setting this to a true value will allow you to pass the "astext=1" param to
any request processed by this View.  The results will be the contents of
$c->stash passed through to Data::Dumper, as opposed to your Serialized object.

This should be turned off in production environments concerned about security.
It's great for debugging, though!

=head3 raw

Setting this to a true value will cause Data::Serializer to call the "raw" version
of the regular serialize function (raw_serialize).  The effect is the same as just using
the underlying Serializer directly.

=head2 OVERLOADED METHODS

=head3 process

Serializes $c->stash to $c->response->output.  If you pass "astext=1" as a
param, and the $c->config->{'serializer'}->{'astext'} option is true, then
it will return the output of the stash via Data::Dumper.

=cut

sub process {
    my ($self, $c) = @_;
    my $serializer = $self->_serializer;    
    unless ($serializer) {
        my %defaults = (
            serializer       => 'Data::Dumper',
            digester         => 'SHA1',
            cipher           => 'Blowfish',
            secret           => undef,
            portable         => '1',
            compress         => '0',
            serializer_token => '1',
            options          => {},
        );
        while (my ($k, $v) = each %defaults) {
            if (!exists($c->config->{'serializer'}->{$k})) {
                $c->config->{'serializer'}->{$k} = $v;
            }
        }
        my $astext = 0;
        if (exists($c->config->{'serializer'}->{'astext'})) {
            $astext = $c->config->{'serializer'}->{'astext'};
            delete($c->config->{'serializer'}->{'astext'});
        }
        $serializer = Data::Serializer->new(%{ $c->config->{'serializer'} },);
        $self->_serializer($serializer);
        $c->config->{'serializer'}->{'astext'} = $astext;
    }
    $c->response->headers->content_type('text/plain');
    if ($c->req->param("astext") && $c->config->{'serializer'}->{'astext'}) {
        $c->response->output(Data::Dumper->Dump([ $c->stash ]));
    } else {
        if ($c->config->{'serializer'}->{'raw'}) {
            $c->response->output($serializer->raw_serialize($c->stash));
        } else {
            $c->response->output($serializer->serialize($c->stash));
        }
    }
    return 1;
}

=head1 SEE ALSO

L<Catalyst>, L<Data::Serializer>

=head1 AUTHOR

Adam Jacob, C<adam@stalecoffee.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
