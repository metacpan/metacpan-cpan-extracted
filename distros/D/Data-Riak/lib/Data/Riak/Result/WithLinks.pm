package Data::Riak::Result::WithLinks;
{
  $Data::Riak::Result::WithLinks::VERSION = '2.0';
}
# ABSTRACT: Results with links

use Moose::Role;
use Data::Riak::Link;
use namespace::autoclean;

with 'MooseX::Clone';


has links => (
    is  => 'ro',
    isa => 'ArrayRef[Data::Riak::Link]',
);


sub create_link {
    my ($self, %opts) = @_;
    return Data::Riak::Link->new({
        bucket => $self->bucket_name,
        key => $self->key,
        riaktag => $opts{riaktag},
        (exists $opts{params} ? (params => $opts{params}) : ())
    });
}


sub add_link {
    my ($self, $link) = @_;
    confess 'No link to add provided'
        unless blessed $link && $link->isa('Data::Riak::Link');
    return $self->clone(links => [@{ $self->links }, $link]);
}


sub remove_link {
    my ($self, $args) = @_;
    my $key = $args->{key};
    my $riaktag = $args->{riaktag};
    my $bucket = $args->{bucket};
    my $links = $self->links;
    my $new_links;
    foreach my $link (@{$links}) {
        next if($bucket && ($bucket eq $link->bucket));
        next if($key && $link->has_key && ($key eq $link->key));
        next if($riaktag && $link->has_riaktag && ($riaktag eq $link->riaktag));
        push @{$new_links}, $link;
    }
    return $self->clone(links => $new_links);
}

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::WithLinks - Results with links

=head1 VERSION

version 2.0

=head1 ATTRIBUTES

=head2 links

This object's list of L<Data::Riak::Link>s.

=head1 METHODS

=head2 create_link

  my $link = $obj->create_link(
      riaktag => 'buddy',
  );

Create a new L<Data::Riak::Link> for this object's key within its bucket.

This only instanciates a new link. It won't automatically be added to the
object's list of links. Use L</add_link> for that.

=head2 add_link

  my $obj_with_links = $obj->add_link(
      $obj->create_link(riaktag => 'buddy'),
  );

Returns a clone of the instance, with the new link added to its list of links.

=head2 remove_link

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
