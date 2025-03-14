package CatalystX::OAuth2::Schema::Result::Owner;
use parent 'DBIx::Class';

# ABSTRACT: A table for registering resource owners

__PACKAGE__->load_components(qw(Core));
__PACKAGE__->table('owner');
__PACKAGE__->add_columns(
  id => { data_type => 'int', is_auto_increment => 1 }, );
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( codes => 'CatalystX::OAuth2::Schema::Result::Code' =>
    { 'foreign.owner_id' => 'self.id' } );

1;

__END__

=pod

=head1 NAME

CatalystX::OAuth2::Schema::Result::Owner - A table for registering resource owners

=head1 VERSION

version 0.001009

=head1 AUTHOR

Eden Cardim <edencardim@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
