package DBIx::NoSQL::ClassScaffold;
our $AUTHORITY = 'cpan:YANICK';
# Scaffold
$DBIx::NoSQL::ClassScaffold::VERSION = '0.0021';
use strict;
use warnings;

my $__serial__ = -1;
our $serial = sub {
    return $__serial__ += 1;
};

use Moose;

has package => qw/ is ro lazy_build 1 /;
sub _build_package {
    return 'DBIx::NoSQL::__Anonymous__::Class' . $serial->();
}

has package_meta => qw/ is ro lazy_build 1 /;
sub _build_package_meta {
    my $self = shift;
		return Moose::Meta::Class->create($self->package);
}

sub push_ISA {
    my $self = shift;
    my $target = shift;

    my $package = $self->package;
    eval "push \@${package}::ISA, '$target'";
    return $self;
}

sub become_Schema {
    my $self = shift;

    require DBIx::Class::Schema;
    $self->package_meta->superclasses( 'DBIx::NoSQL::ClassScaffold::Schema' );
    return $self;
}

sub become_ResultClass {
    my $self = shift;

    require DBIx::Class::Core;
    $self->push_ISA( 'DBIx::NoSQL::ClassScaffold::ResultClass' );
    return $self;
}

sub become_ResultClass_Store {
    my $self = shift;

    $self->become_ResultClass;
    my $package = $self->package;

    $package->table( '__Store__' );
    $package->add_columns(
        __model__ => {
            data_type => 'text',
        },
        __key__ => {
            data_type => 'text',
        },
        __value__ => {
            data_type => 'text',
            default_value => '{}',
        },
    );
    $package->set_primary_key(qw/ __model__ __key__ /);
    return $self;
}

package DBIx::NoSQL::ClassScaffold::Schema;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::ClassScaffold::Schema::VERSION = '0.0021';
use Moose;

extends qw/ DBIx::Class::Schema /;

use JSON; our $json = JSON->new->pretty;
use Digest::SHA qw/ sha1_hex /;

has store => qw/ is rw weak_ref 1 /;

has deployment_statements => qw/ accessor _deployment_statements lazy_build 1 /;
sub _build_deployment_statements {
    return shift->build_deployment_statements;
}

sub build_deployment_statements {
    my $self = shift;
    my $sql = $self->deployment_statements( undef, undef, undef, { add_drop_table => 1 } );
    $sql =~ s/^--[^\n]*$//gsm;
    return $sql;
}

around deployment_statements => sub {
    my $inner = shift;
    my $self = shift;
    return $inner->( $self, @_ ) if @_;
    return $self->_deployment_statements;
};

has version => qw/ is ro lazy_build 1 /;
sub _build_version {
    my $self = shift;
    return sha1_hex( $self->sql );
}

sub deploy {
    my $self = shift;

    my $deployment_statements = $self->deployment_statements;
    s/^\s*//, s/\s*$// for $deployment_statements;
    my @deployment_statements = split m/;\n\s*/, $deployment_statements;

    $self->store->storage->do( $_ ) for @deployment_statements;
}

package DBIx::NoSQL::ClassScaffold::ResultClass;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::ClassScaffold::ResultClass::VERSION = '0.0021';
use strict;
use warnings;

use base qw/ DBIx::Class::Core /;

sub register {
    my $class = shift;
    my $schema_class = shift;
    my $moniker = shift;

    $schema_class->register_class( $moniker => $class );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL::ClassScaffold

=head1 VERSION

version 0.0021

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
