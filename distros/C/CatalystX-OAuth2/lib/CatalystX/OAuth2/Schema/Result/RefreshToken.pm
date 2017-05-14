package CatalystX::OAuth2::Schema::Result::RefreshToken;
use warnings;
use strict;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering refresh tokens

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('refresh_token');
__PACKAGE__->add_columns(
  id      => { data_type => 'int', is_auto_increment => 1 },
  code_id => { data_type => 'int', is_nullable       => 0 },
);
__PACKAGE__->set_primary_key(qw(id));

__PACKAGE__->add_unique_constraint( [qw(id code_id)] );

__PACKAGE__->belongs_to( code => 'CatalystX::OAuth2::Schema::Result::Code' =>
    { 'foreign.id' => 'self.code_id' } );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  from_access_token_map =>
    'CatalystX::OAuth2::Schema::Result::AccessTokenToRefreshToken' => {
    'foreign.refresh_token_id' => 'self.id',
    'foreign.code_id'          => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  from_access_token_map_m2m => from_access_token_map => 'access_token' );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  to_access_token_map =>
    'CatalystX::OAuth2::Schema::Result::RefreshTokenToAccessToken' => {
    'foreign.refresh_token_id' => 'self.id',
    'foreign.code_id'          => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  to_access_token_map_m2m => to_access_token_map => 'access_token' );

sub from_access_token { shift->from_access_token_map_m2m->first }
sub to_access_token   { shift->to_access_token_map_m2m->first }

sub create_access_token {
  my ($self) = @_;
  my $code = $self->code;
  my $token;
  $self->result_source->storage->txn_do(
    sub {
      # create a new token from this refresh token
      $token = $code->tokens->create(
        { from_refresh_token_map => [ { refresh_token => $self } ] } );

      # create a new refresh token and add it to the new token
      my $refresh = $code->refresh_tokens->create( {} );
      $token->to_refresh_token_map->create(
        { code => $code, refresh_token => $refresh } );
    }
  );
  return $token;
}

# if we have already created a token from this refresh, de-activate it
sub is_active { !shift->to_access_token_map->count }

sub as_string { shift->id }

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::Result::RefreshToken - A table for registering refresh tokens

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
