package Bio::Chado::Schema;
BEGIN {
  $Bio::Chado::Schema::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JJ2AbsZoAN4cnM4vrYOxKA

use Carp::Clan qr/^Bio::Chado::Schema/;
use Bio::Chado::Schema::Util;

=head1 NAME

Bio::Chado::Schema - A standard DBIx::Class layer for the Chado database schema.

=head1 SYNOPSIS

  use Bio::Chado::Schema;

  my $chado = Bio::Chado::Schema->connect( $dsn, $user, $password );

  print "number of rows in feature table: ",
        $chado->resultset('Sequence::Feature')->count,
        "\n";


=head1 DESCRIPTION

This is a standard object-relational mapping layer for use with the
GMOD Chado database schema.  This layer is implemented with
L<DBIx::Class>, generated with the help of the very fine
L<DBIx::Class::Schema::Loader> module.

Chado is an open-source modular database schema for biological data.
It is divided into several notional "modules", which are reflected in
the namespace organization of this package.  Note that modules in the
Chado context refers to sets of tables, they are not modules in the
Perl sense.

=head1 GETTING STARTED

To learn how to use this DBIx::Class ORM layer, a good starting
point is the L<DBIx::Class::Manual>.

=head1 CHADO MODULES COVERED BY THIS PACKAGE

L<Bio::Chado::Schema::CellLine>

L<Bio::Chado::Schema::Companalysis>

L<Bio::Chado::Schema::Composite>

L<Bio::Chado::Schema::Contact>

L<Bio::Chado::Schema::Cv>

L<Bio::Chado::Schema::Expression>

L<Bio::Chado::Schema::General>

L<Bio::Chado::Schema::Genetic>

L<Bio::Chado::Schema::Library>

L<Bio::Chado::Schema::Mage>

L<Bio::Chado::Schema::Map>

L<Bio::Chado::Schema::NaturalDiversity>

L<Bio::Chado::Schema::Organism>

L<Bio::Chado::Schema::Phenotype>

L<Bio::Chado::Schema::Phylogeny>

L<Bio::Chado::Schema::Project>

L<Bio::Chado::Schema::Pub>

L<Bio::Chado::Schema::Sequence>

L<Bio::Chado::Schema::Stock>


=head1 CHADO VERSIONS

Basically, BCS has always followed the SVN HEAD of Chado, since it's
on a much faster release cycle than Chado itself.

Most users will not experience incompatibilities using the most recent
versions of Bio::Chado::Schema with older Chado installations.
However, if you encounter problems using Bio::Chado::Schema with an
older Chado schema, you may want to try downgrading to an earlier
version of Bio::Chado::Schema.  The following rough equivalencies hold
between BCS and Chado versions:

  Chado 1.2   --  BCS 0.09000
  Chado 1.11  --  BCS 0.05801
  Chado 1.1   --  BCS 0.05801
  older       --  BCS 0.03100

=head1 SCHEMA OBJECT METHODS

=head2 get_cvterm( "$cv_name:$cvterm_name" ) OR get_cvterm( $cv_name, $cvterm_name )

Convenience method to for finding single cvterms based on the text
name of the CV and the term.  The cvterm objects found with this
method are cached in the schema object itself.  Thus, you only use
this function in the (relatively common) scenario in which you just
need convenient access to a handful of different cvterms.

=cut

sub get_cvterm {
    my ( $self, $cv_name, $term_name ) = @_;

    croak "must provide at least one argument!" unless @_ > 1;

    unless( $term_name ) {
        ($cv_name, $term_name) = split /:/, $cv_name, 2;
    }

    return $self->{_bio_chado_schema_cvterm_cache}{$cv_name}{$term_name} ||=
        $self->resultset('Cv::Cv')
             ->search({ 'me.name' => $cv_name })
             ->search_related('cvterms', { 'cvterms.name' => $term_name })
             ->single;
}

=head2 get_cvterm_or_die

Same as get_cvterm above, but dies with a "not found" message if the
cvterm is not found.  This is convenient when you don't want to be
bothered with checking the return value of C<get_cvterm>, which for me
is most of the time.

=cut

sub get_cvterm_or_die {
    shift->get_cvterm( @_ ) or croak "cvterm @_ not found";
}

=head1 CLASS METHODS

=head2 plugin_add_relationship( 'ChadoModule::SourceName', 'reltype', @args )

Sometimes application-specific plugins need to add relationships to
the core BCS classes.  It can't just be done normally from inside the
classes of the plugins, you need to use this method.

Example: Bio::Chado::Schema::Result::MyApp::SpecialThing belongs_to
the core BCS Organism::Organism, and you would like to be able to call
C<$organism-E<gt>myapp_specialthings> on organisms to get their
associated SpecialThings.

    package Bio::Chado::Schema::MyApp::Result::SpecialThing;

    # ( do table and column definitions and so forth here )

    Bio::Chado::Schema->plugin_add_relationship(
        'Organism::Organism', 'has_many', (
            "myapp_specialthings",
            "Bio::Chado::Schema::MyApp::Result::Foo",
            { "foreign.organism_id" => "self.organism_id" },
            { cascade_copy => 0, cascade_delete => 0 },
        );
    );

=cut

{
    my @after_load;
    $_->() for @after_load; #< note that this executes after load_classes above

    sub plugin_add_relationship {
        my ( $class, $target_moniker, $reltype, @args ) = @_;

        push @after_load, sub {
            no strict 'refs';
            my $target_class = $class->class( $target_moniker );
            $target_class->$reltype( @args );
            __PACKAGE__->register_class( $target_moniker => $target_class );
        };
    }
}

sub DESTROY {
    my $self = shift;

    # need to delete our cvterm cache to avoid memory leaks
    delete $self->{_bio_chado_schema_cvterm_cache};
    $self->SUPER::DESTROY( @_ ) if $self->can( 'SUPER::DESTROY' );
}

=head1 AUTHOR

Robert Buels, <rmb32@cornell.edu>

=head1 CONTRIBUTORS

Naama Menda, <nm249@cornell.edu>

Aureliano Bombarely, <ab782@cornell.edu>

Jonathan "Duke" Leto, <jonathan@leto.net>

=cut

1;
