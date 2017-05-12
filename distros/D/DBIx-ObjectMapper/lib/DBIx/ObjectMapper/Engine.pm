package DBIx::ObjectMapper::Engine;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Log::Any qw($log);
use DBIx::ObjectMapper::Log;

sub new {
    my $class = shift;
#    if( $class eq __PACKAGE__ ) {
#        confess __PACKAGE__ . " can't direct use.";
#    }

    my $self = bless {}, $class;
    $self->_init(@_);
    return $self;
}

sub log { $log }

sub _init {}

sub transaction              { }
sub namesep                  { }
sub quote                    { }
sub driver                   { }
sub datetime_parser          { }
sub get_primary_key          { }
sub get_column_info          { }
sub get_unique_key           { }
sub get_tables               { }
sub select                   { }
sub select_single            { }
sub update                   { }
sub insert                   { }
sub create                   { }
sub delete                   { }
sub iterator                 { }

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Engine - the engine interface

=head1 DESCRIPTION

=head1 METHODS

=head2 _init

=head2 transaction

=head2 namesep

=head2 quote

=head2 driver

=head2 datetime_parser

=head2 get_primary_key

=head2 get_column_info

=head2 get_unique_key

=head2 get_tables

=head2 select

=head2 select_single

=head2 update

=head2 insert

=head2 create

=head2 delete

=head2 iterator


=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

