use 5.008;
use strict;
use warnings;

package Data::Storage::DBI::Pg;
BEGIN {
  $Data::Storage::DBI::Pg::VERSION = '1.102720';
}

# ABSTRACT: Base class for Pg DBI storages
use Error::Hierarchy::Util 'assert_defined';
use parent qw(Data::Storage::DBI Class::Accessor::Complex);
use constant connect_string_dbi_id => 'Pg';

sub connect {
    my $self = shift;
    $self->SUPER::connect(@_);

  # FIXME: is this the right place and the right way for setting utf-8 encoding?
    $self->dbh->{pg_enable_utf8} = 1;
}

sub test_setup {
    my $self = shift;
    $self->connect;
    $self->disconnect;
}

sub last_id {
    my ($self, $sequence_name) = @_;
    $self->dbh->last_insert_id(undef, undef, undef, undef,
        { sequence => $sequence_name });
}

sub next_id {
    my ($self, $sequence_name) = @_;
    unless ($sequence_name) {
        throw Error::Hierarchy::Internal::ValueUndefined;
    }
    my $sth = $self->prepare("
    SELECT NEXTVAL('$sequence_name')");
    $sth->execute;
    my ($next_id) = $sth->fetchrow_array;
    $sth->finish;
    $next_id;
}

sub trace {
    my $self = shift;
    $self->dbh->trace(@_);
}

# Database type-specifc rewrites
sub rewrite_query_for_dbd {
    my ($self, $query) = @_;
    $query =~ s/<USER>/CURRENT_USER/g;
    $query =~ s/<NOW>/NOW()/g;
    $query =~ s/<NEXTVAL>\((.*?)\)/NEXTVAL('$1')/g;
    $query =~ s/<BOOL>\((.*?)\)/sprintf "CASE %s WHEN '%s' THEN 1 WHEN '%s' THEN 0 END", $1,
        $self->delegate->YES, $self->delegate->NO
    /eg;
    $query;
}
1;


__END__
=pod

=for stopwords Pg

=head1 NAME

Data::Storage::DBI::Pg - Base class for Pg DBI storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 connect

FIXME

=head2 last_id

FIXME

=head2 next_id

FIXME

=head2 rewrite_query_for_dbd

FIXME

=head2 test_setup

FIXME

=head2 trace

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Storage>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Storage/>.

The development version lives at L<http://github.com/hanekomu/Data-Storage>
and may be cloned from L<git://github.com/hanekomu/Data-Storage>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

