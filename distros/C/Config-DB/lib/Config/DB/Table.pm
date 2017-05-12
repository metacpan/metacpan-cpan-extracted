package Config::DB::Table;

$Config::DB::Table::VERSION = '0.2';

use strict;
use warnings;

use Carp;

our $AUTOLOAD;

sub AUTOLOAD {
    my ( $self, @pars ) = @_;
    my $name = $AUTOLOAD;

    $name =~ s/.*://;

    croak "Can't locate object method \"$name\" via package \""
      . __PACKAGE__ . '"'
      unless $name =~ /^_/;

    $name =~ s/^_//;

    return $self->get( $name, @pars );
}

sub DESTROY {
}

sub get {
    my ( $self, $key, $field ) = @_;

    croak __PACKAGE__ . "::get: missing key parameter" unless defined $key;
    croak __PACKAGE__ . "::get: missing key '$key' in configuration table"
      unless exists $self->{$key};

    return $self->{$key} unless defined $field;

    croak __PACKAGE__ . "::get: unknown field '$field' for configuration table"
      unless exists $self->{$key}->{$field};

    return $self->{$key}->{$field};
}

1;

__END__

=head1 NAME

Config::DB::Table - DataBase Configuration Table module

=head1 SYNOPSIS

 use Config::DB;
 my $cfg   = Config::DB->new( connect => \@params, tables => \%tables );
 my $table = $cfg->get( 'table1' );

=head1 DESCRIPTION

This module is used by L<Config::DB> to rapresentate a table.

=head1 METHODS

=head2 get( $key_value [ , $field_name ] )

It returns a configuration value or a configuration record. Parameter $key_value identifies the
requested record; without $field_name parameter a L<Config::DB:Record> object is returned, if
provided the method returns the value of that field as a SCALAR. It dies on missing key value or
missing field.

=head2 AUTOLOAD

A quicker syntax is offered: following calls are identical...

 my $rec1 = $table->get( 1 );
 my $rec1 = $table->_1;

... following calls are identical as well.

 my $value2 = $table->get( 2 'field2' );
 my $value2 = $table->_2( 'field2' );

=head1 VERSION

0.2

=cut
