package Database::Async::ORM;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

=head1 NAME

Database::Async::ORM - provides object-relational features for L<Database::Async>

=head1 SYNOPSIS

 use 5.020;
 use IO::Async::Loop;
 use Database::Async::ORM;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $orm = Database::Async::ORM->new
 );

 # Load schemata directly from the database
 $orm->load_from($db)
  ->then(sub ($orm) {
   say 'We have the following tables:';
   $orm->tables
       ->map('name')
       ->say
       ->completed
  })->get;

 # Load schemata from a hashref (e.g. pulled
 # from a YAML/JSON/XML file or API)
 $orm->load_from({ ... })
  ->then(sub ($orm) {
   $orm->apply_to($db)
  })->then(sub ($orm) {
   say 'We have the following tables:';
   $orm->tables
       ->map('name')
       ->say
       ->completed
  })->get;

=cut

use Database::Async::ORM::Table;
use Database::Async::ORM::Type;
use Database::Async::ORM::Field;
use Database::Async::ORM::Schema;

sub new {
    my $class = shift;
    bless { @_ }, $class
}

sub add_schema {
    my ($self, $schema) = @_;
    push @{$self->{schema}}, $schema;
}

sub schemata {
    shift->{schema}->@*
}

sub schema_by_name {
    my ($self, $name) = @_;
    my ($schema) = grep { $_->name eq $name } $self->schemata or die 'cannot find schema ' . $name . ', have these instead: ' . join(',', map $_->name, $self->schemata);
    return $schema;
}

1;

__END__

=head1 SEE ALSO

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2018. Licensed under the same terms as Perl itself.

