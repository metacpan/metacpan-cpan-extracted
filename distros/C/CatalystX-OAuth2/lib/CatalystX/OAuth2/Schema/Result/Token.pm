package CatalystX::OAuth2::Schema::Result::Token;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering bearer tokens

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('token');
__PACKAGE__->add_columns(
  id       => { data_type => 'int', is_auto_increment => 1 },
  code_id  => { data_type => 'int', is_nullable       => 0 },
);
__PACKAGE__->set_primary_key(qw(id));
__PACKAGE__->belongs_to( code => 'CatalystX::OAuth2::Schema::Result::Code' =>
    { 'foreign.id' => 'self.code_id' } );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  from_refresh_token_map =>
    'CatalystX::OAuth2::Schema::Result::RefreshTokenToAccessToken' => {
    'foreign.access_token_id' => 'self.id',
    'foreign.code_id'         => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  from_refresh_token_map_m2m => from_refresh_token_map => 'refresh_token' );

# this is a has many but will only ever return a single record
# because of the constraint on the relationship table
__PACKAGE__->has_many(
  to_refresh_token_map =>
    'CatalystX::OAuth2::Schema::Result::AccessTokenToRefreshToken' => {
    'foreign.access_token_id' => 'self.id',
    'foreign.code_id'         => 'self.code_id'
    }
);
__PACKAGE__->many_to_many(
  to_refresh_token_map_m2m => to_refresh_token_map => 'refresh_token' );

sub from_refresh_token { shift->from_refresh_token_map_m2m->first }
sub to_refresh_token   { shift->to_refresh_token_map_m2m->first }

sub as_string  { shift->id }
sub type       {'bearer'}
sub expires_in {3600}
sub owner { shift->code->owner }

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::Result::Token - A table for registering bearer tokens

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
