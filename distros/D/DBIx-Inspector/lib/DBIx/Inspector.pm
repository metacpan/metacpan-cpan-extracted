package DBIx::Inspector;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.12';
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw/dbh catalog schema driver/);
use Carp ();
use DBIx::Inspector::Table;
use DBIx::Inspector::Iterator;
use DBIx::Inspector::ForeignKey;
use Module::Load ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    my $dbh = $args{dbh};
    Carp::croak("missing mandatory parameter: dbh") unless $dbh;
    my $driver_name = $dbh->{Driver}->{Name};
    my $driver_class = "$class\::Driver::$driver_name";
    Module::Load::load($driver_class);
    return $driver_class->new(%args);
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Inspector - Get information from $dbh

=head1 SYNOPSIS

    use DBIx::Inspector;

    my $dbh = DBI->connect(...) or die;
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables = $inspector->tables;
    for my $table (@tables) {
        print "  pk:\n";
        for my $pk ($table->primary_key) {
            print "    ", $pk->name, "\n";
        }
        print "  columns:\n";
        for my $column ($table->columns) {
            print "    ", $column->name, "\n";
        }
    }

=head1 DESCRIPTION

DBIx::Inspector is a inspector for $dbh.

This is under development. B<Any API will change without notice.>

=head1 METHODS

=over 4

=item C<< my $inspector = DBIx::Inspector->new(dbh => $dbh); >>

Create new instance of DBIx::Inspector.

=item C<< my @tables = $inspector->tables(); >>

Retrieve table objects from $dbh. Every elements in @tables is instance of L<DBIx::Inspector::Table>.

=item C<< my $table = $inspector->table($table_name); >>

Retrieve table object from $dbh. Return value is instance of L<DBIx::Inspector::Table>.

=item C<< my @views = $inspector->views(); >>

Retrieve view objects from $dbh. Every elements in @views is instance of L<DBIx::Inspector::Table>.

=item C<< my $view = $inspector->view($view_name); >>

Retrieve view object from $dbh. Return value is instance of L<DBIx::Inspector::Table>.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<DBI>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
