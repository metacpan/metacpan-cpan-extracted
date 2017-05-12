use 5.008;
use strict;
use warnings;

package Data::Storage::DBIC;
BEGIN {
  $Data::Storage::DBIC::VERSION = '1.102720';
}
# ABSTRACT: Base class for DBIx::Class-based storages
use Error::Hierarchy::Util qw(assert_defined load_class);
use Error ':try';
use parent 'Data::Storage::DBI';
__PACKAGE__
    ->mk_scalar_accessors(qw(schema))
    ->mk_abstract_accessors(qw(SCHEMA_CLASS));

sub is_connected {
    my $self         = shift;
    my $is_connected = ref($self->schema)
      && $self->schema->storage->connected;
    $self->log->debug('storage [%s] is %s',
        $self->dbname, $is_connected ? 'connected' : 'not connected');
    $is_connected;
}

sub connect {
    my $self = shift;
    return if $self->is_connected;
    assert_defined $self->$_, sprintf "called without %s argument.", $_
      for qw/dbname dbuser dbpass/;
    $self->log->debug('connecting to storage [%s] as [%s/%s]',
        $self->dbname, $self->dbuser, $self->dbpass);
    try {
        load_class $self->SCHEMA_CLASS, 0;
        my $class = $self->SCHEMA_CLASS;
        $self->schema(
            $class->connect(
                $self->dbname, $self->dbuser,
                $self->dbpass, $self->get_connect_options
            )
        );

        # XXX no global commit and rollback in DBIx::Class, so we have to
        # create a transaction?
        $self->schema->txn_begin;
    }
    catch Error with {
        my $E = shift;
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => sprintf
              "couldn't connect to storage [%s (%s/%s)]: %s",
            $self->dbname,
            $self->dbuser,
            $self->dbpass,
            $E
        );
    };
}

sub disconnect {
    my $self = shift;
    return unless $self->is_connected;
    $self->rollback_mode ? $self->rollback : $self->commit;
    $self->log->debug('disconnecting from storage [%s]', $self->dbname);
    $self->schema->storage->disconnect;
}

sub rollback {
    my $self = shift;

    # avoid "rollback ineffective with AutoCommit enabled" error
    # return if $self->AutoCommit;
    $self->schema->txn_rollback;
    $self->log->debug('did rollback');
}

sub commit {
    my $self = shift;
    return if $self->rollback_mode;

    # avoid "commit ineffective with AutoCommit enabled" error
    return if $self->AutoCommit;
    $self->schema->txn_commit;
    $self->log->debug('did commit');
}

sub lazy_connect {
    my $self = shift;

    # not supported in DBIx::Class?
    $self->connect(@_);
}
1;


__END__
=pod

=head1 NAME

Data::Storage::DBIC - Base class for DBIx::Class-based storages

=head1 VERSION

version 1.102720

=head1 METHODS

=head2 commit

FIXME

=head2 connect

FIXME

=head2 disconnect

FIXME

=head2 is_connected

FIXME

=head2 lazy_connect

FIXME

=head2 rollback

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

