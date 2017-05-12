use strict;
use warnings;
package CPAN::Testers::Metabase::MongoDB;
# ABSTRACT: Metabase backend on MongoDB
our $VERSION = '0.001'; # VERSION

use Moose;
use Metabase::Archive::MongoDB 1.000;
use Metabase::Index::MongoDB 1.000;
use Metabase::Librarian 1.000;
use namespace::autoclean;

with 'Metabase::Gateway';

has 'db_prefix' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

has 'host' => (
  is        => 'ro',
  isa       => 'Str',
  required  => 1,
);

sub _build_fact_classes { return [qw/CPAN::Testers::Report/] }

sub _build_public_librarian { return $_[0]->__build_librarian("public") }

sub _build_private_librarian { return $_[0]->__build_librarian("private") }

sub __build_librarian {
  my ($self, $subspace) = @_;
  my $db_prefix = $self->db_prefix;

  return Metabase::Librarian->new(
    archive => Metabase::Archive::MongoDB->new(
      db_name => "${db_prefix}_${subspace}",
      host => $self->host,
    ),
    index => Metabase::Index::MongoDB->new(
      db_name => "${db_prefix}_${subspace}",
      host => $self->host,
    ),
  );
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

CPAN::Testers::Metabase::MongoDB - Metabase backend on MongoDB

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head2 Direct usage

   use CPAN::Testers::Metabase::MongoDB;
 
   my $mb = CPAN::Testers::Metabase::MongoDB->new(
     db_prefix => "my_metabase",
     host      => "mongodb://localhost:27017",
   );
 
   $mb->public_librarian->search( %search spec );
   ...

=head2 Metabase::Web config

   ---
   Model::Metabase:
     class: CPAN::Testers::Metabase::MongoDB
       args:
         db_prefix: my_metabase
         host: "mongodb://localhost:27017/"

=head1 DESCRIPTION

This class instantiates a Metabase backend that uses MongoDB for storage and
indexing.

=head1 USAGE

=head2 new

   my $mb = CPAN::Testers::Metabase::MongoDB->new(
     db_prefix => "my_metabase",
     host      => "mongodb://localhost:27017",
   );

Arguments for C<<< new >>>:

=over

=item *

C<<< db_prefix >>> -- required -- a unique namespace for the collections

=item *

C<<< host >>> -- required -- a MongoDB connection string

=back

=head2 Metabase::Gateway Role

This class does the L<Metabase::Gateway> role, including the following
methods:

=over

=item *

C<<< handle_submission >>>

=item *

C<<< handle_registration >>>

=item *

C<<< enqueue >>>

=back

see L<Metabase::Gateway> for more.

=head1 SEE ALSO

=over

=item *

L<CPAN::Testers::Metabase>

=item *

L<Metabase::Gateway>

=item *

L<Metabase::Web>

=item *

L<Net::Amazon::Config>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Metabase-MongoDB>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/cpan-testers-metabase-mongodb>

  git clone https://github.com/dagolden/cpan-testers-metabase-mongodb.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__

