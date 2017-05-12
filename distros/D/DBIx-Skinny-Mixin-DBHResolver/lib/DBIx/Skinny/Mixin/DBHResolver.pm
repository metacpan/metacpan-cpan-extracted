package DBIx::Skinny::Mixin::DBHResolver;
use strict;
use warnings;
our $VERSION = '0.04';

sub register_method {
    +{
        'dbh_resolver' => sub {
            my $class = shift;
            DBIx::Skinny::Mixin::DBHResolver::Base->new({skinny => $class});
        },
    },
}

package DBIx::Skinny::Mixin::DBHResolver::Base;
use DBIx::DBHResolver;

sub new {
    my ($class, $args) = @_;
    bless $args, $class;
}

sub conf {
    my ($self, $conf) = @_;
    DBIx::DBHResolver->config($conf);
}

sub cluster      { shift; DBIx::DBHResolver->cluster(@_)      }
sub connect_info { shift; DBIx::DBHResolver->connect_info(@_) }
sub load         { shift; DBIx::DBHResolver->load(@_)         }

sub connect {
    my $self = shift;
    $self->{skinny}->set_dbh(DBIx::DBHResolver->connect(@_));
}

sub connect_cached {
    my $self = shift;
    $self->{skinny}->set_dbh(DBIx::DBHResolver->connect_cached(@_));
}

1;
__END__

=head1 NAME

DBIx::Skinny::Mixin::DBHResolver - DBIx::DBHResolver mixin for DBIx::Skinny.

=head1 SYNOPSIS

  package Proj::DB;
  use DBIx::Skinny;
  use DBIx::Skinny::Mixin modules => ['DBHResolver'];

  package main;
  use Proj::DB;

  # call first
  Proj::DB->dbh_resolver->conf($conf);
  Proj::DB->dbh_resolver->connect(....);

=head1 DESCRIPTION

DBIx::Skinny::Mixin::DBHResolver is

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

L<DBIx::Skinny>

L<DBIx::DBHResolver>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
