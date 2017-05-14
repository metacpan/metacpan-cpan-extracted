package CatalystX::OAuth2::Schema::Result::AccessTokenToRefreshToken;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering refresh tokens

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('access_token_to_refresh_token');
__PACKAGE__->add_columns(
  access_token_id  => { data_type => 'int', is_nullable => 0 },
  code_id          => { data_type => 'int', is_nullable => 0 },
  refresh_token_id => { data_type => 'int', is_nullable => 0 },
);
__PACKAGE__->set_primary_key(qw(access_token_id code_id refresh_token_id));

__PACKAGE__->belongs_to( code => 'CatalystX::OAuth2::Schema::Result::Code' =>
    { 'foreign.id' => 'self.code_id' } );
__PACKAGE__->belongs_to(
  access_token => 'CatalystX::OAuth2::Schema::Result::Token' => {
    'foreign.id'      => 'self.access_token_id',
    'foreign.code_id' => 'self.code_id'
  }
);
__PACKAGE__->belongs_to(
  refresh_token => 'CatalystX::OAuth2::Schema::Result::RefreshToken' => {
    'foreign.id'      => 'self.refresh_token_id',
    'foreign.code_id' => 'self.code_id'
  }
);

__PACKAGE__->add_unique_constraint( [qw(access_token_id code_id)] );
__PACKAGE__->add_unique_constraint( [qw(refresh_token_id code_id)] );

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::Result::AccessTokenToRefreshToken - A table for registering refresh tokens

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
