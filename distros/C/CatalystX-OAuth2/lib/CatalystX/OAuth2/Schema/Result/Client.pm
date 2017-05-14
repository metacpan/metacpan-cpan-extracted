package CatalystX::OAuth2::Schema::Result::Client;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering clients

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('client');
__PACKAGE__->add_columns(
  id            => { data_type => 'int',  is_auto_increment => 1 },
  endpoint      => { data_type => 'text', is_nullable       => 0 },
  client_secret => { data_type => 'text', is_nullable       => 1 }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( codes => 'CatalystX::OAuth2::Schema::Result::Code' =>
    { 'foreign.client_id' => 'self.id' } );

sub find_refresh {
  shift->codes->search( { is_active => 1 } )
    ->related_resultset('refresh_tokens')->find(@_);
}

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::Result::Client - A table for registering clients

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
