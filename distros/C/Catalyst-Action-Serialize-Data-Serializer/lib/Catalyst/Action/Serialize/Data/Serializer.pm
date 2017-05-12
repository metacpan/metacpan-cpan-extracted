package Catalyst::Action::Serialize::Data::Serializer;

use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use Data::Serializer;

our $VERSION = '1.08';
$VERSION = eval $VERSION;

sub execute {
    my $self = shift;
    my ( $controller, $c, $serializer ) = @_;

    my $stash_key = (
            $controller->{'serialize'} ?
                $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'}
        ) || 'rest';
    my $sp = $serializer;
    $sp =~ s/::/\//g;
    $sp .= ".pm";
    eval {
        require $sp
    };
    if ($@) {
        $c->log->info("Could not load $serializer, refusing to serialize: $@");
        return;
    }
    my $dso = Data::Serializer->new( serializer => $serializer );
    my $data = $dso->raw_serialize($c->stash->{$stash_key});
    $c->response->output( $data );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Catalyst::Action::Serialize::Data::Serializer - Serialize with Data::Serializer

=head1 SYNOPSIS

   package MyApp::Controller::Foo;

   use Moose;
   use namespace::autoclean;

   BEGIN { extends 'Catalyst::Controller' }

   __PACKAGE__->config(
       'default'   => 'text/x-yaml',
       'stash_key' => 'rest',
       'map'       => {
           'text/x-yaml'        => 'YAML',
           'application/json'   => 'JSON',
           'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
       },
   );

=head1 DESCRIPTION

This module implements a serializer for use with C<Data::Dumper> and others.  It
was factored out of L<Catalyst::Action::REST> because it is unlikely to be
widely used and tends to break tests, be insecure, and is generally weird.  Use
at your own risk.

=head1 AUTHOR

Adam Jacob E<lt>adam@stalecoffee.orgE<gt>, with lots of help from mst and jrockway

Marchex, Inc. paid me while I developed this module. (L<http://www.marchex.com>)

=head1 CONTRIBUTORS

Tomas Doran (t0m) E<lt>bobtfish@bobtfish.netE<gt>

John Goulah

Christopher Laco

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

Hans Dieter Pearcey

Brian Phillips E<lt>bphillips@cpan.orgE<gt>

Dave Rolsky E<lt>autarch@urth.orgE<gt>

Luke Saunders

Arthur Axel "fREW" Schmidt E<lt>frioux@gmail.comE<gt>

J. Shirley E<lt>jshirley@gmail.comE<gt>

Gavin Henry E<lt>ghenry@surevoip.co.ukE<gt>

Gerv http://www.gerv.net/

Colin Newell <colin@opusvl.com>

Wallace Reis E<lt>wreis@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2013 the above named AUTHOR and CONTRIBUTORS

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
