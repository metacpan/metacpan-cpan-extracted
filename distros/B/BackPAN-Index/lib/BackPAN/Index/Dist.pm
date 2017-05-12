use utf8;
package BackPAN::Index::Dist;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("dists");
__PACKAGE__->add_columns(
  "name",
  { data_type => "text", is_nullable => 0 },
  "first_release",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "latest_release",
  { data_type => "text", is_foreign_key => 1, is_nullable => 0 },
  "first_date",
  { data_type => "integer", is_nullable => 0 },
  "latest_date",
  { data_type => "integer", is_nullable => 0 },
  "first_author",
  { data_type => "text", is_nullable => 0 },
  "latest_author",
  { data_type => "text", is_nullable => 0 },
  "num_releases",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("name");
__PACKAGE__->belongs_to(
  "first_release",
  "BackPAN::Index::Release",
  { path => "first_release" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "latest_release",
  "BackPAN::Index::Release",
  { path => "latest_release" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->has_many(
  "releases",
  "BackPAN::Index::Release",
  { "foreign.dist" => "self.name" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2012-12-27 01:39:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BuglboqFzRDZo6vlK4n0yw

use Mouse;
with 'BackPAN::Index::Role::AsHash';

use overload
  q[""]         => sub { $_[0]->name },
  fallback      => 1;

sub data_methods {
    return qw(
        name num_releases
        first_release  first_date  first_author
        latest_release latest_date latest_author
    );
}

sub authors {
    my $self = shift;

    return $self->releases->search(undef, { distinct => 1 })->get_column("cpanid")->all;
}

1;

__END__

=head1 NAME

BackPAN::Index::Dist - Representing a distribution on BackPAN

=head1 SYNOPSIS

Use through BackPAN::Index.

=head1 DESCRIPTION

An object representing a distribution on BackPAN.  A distribution is
made up of releases.

=head2 releases

    my $releases = $dist->releases;

A ResultSet of this distribution's releases.

=head2 name

    my $dist_name = $dist->name;

Name of the distribution.

=head2 authors

    my @authors = $dist->authors;

Return the CPANIDs which made releases of this $dist, in no particular order.

=head2 num_releases

    my $num_releases = $dist->num_releases;

Returns the number of releases this distribution has.

=head2 first_release

=head2 latest_release

    my $release = $dist->first_release;

Returns the first or latest release of this distribution as a BackPAN::Index::Release.

=head2 first_date

=head2 latest_date

    my $release = $dist->first_date;

Returns the date of the first or latest release of this distribution.

=head2 first_author

=head2 latest_author

    my $cpanid = $dist->first_author;

Returns the CPANID of the author of the first or latest release.

=head2 as_hash

    my $data = $dist->as_hash;

Returns a hash ref containing the data inside C<$dist>.


=head1 SEE ALSO

L<BackPAN::Index>

=cut
