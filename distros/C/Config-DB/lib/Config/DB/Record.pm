package Config::DB::Record;

$Config::DB::Record::VERSION = '0.2';

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
    my ( $self, $field ) = @_;

    croak __PACKAGE__ . "::get: missing field parameter" unless defined $field;
    croak __PACKAGE__ . "::get: unknown field '$field' for configuration table"
      unless exists $self->{$field};

    return $self->{$field};
}

1;

__END__

=head1 NAME

Config::DB::Record - DataBase Configuration Record module

=head1 SYNOPSIS

 use Config::DB;
 my $cfg    = Config::DB->new( connect => \@params, tables => \%tables );
 my $rec    = $cfg->get( 'table1', 1 );

=head1 DESCRIPTION

This module is used by L<Config::DB> to rapresentate a record.

=head1 METHODS

=head2 get( $field_name )

It returns a configuration value. Parameter $field_name is the name of the requested field. It dies
on missing key value or missing field.

=head2 AUTOLOAD

A quicker syntax is offered: following calls are identical...

 my $value1 = $rec->get( 'field1' );
 my $value1 = $rec->_field1;

=head1 VERSION

0.2

=cut
