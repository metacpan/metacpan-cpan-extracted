package DBIx::Class::InflateColumn::Crypt::Passphrase;
$DBIx::Class::InflateColumn::Crypt::Passphrase::VERSION = '0.001';
use strict;
use warnings;

use parent 'DBIx::Class';

use Crypt::Passphrase 0.006;
use Crypt::Passphrase::PassphraseHash;
use Scalar::Util 'blessed';

use namespace::clean;

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	$self->next::method($column, $info, @rest);
	return unless my $encoding = $info->{inflate_passphrase};

	my $crypt_passphrase = blessed($encoding) ? $encoding : Crypt::Passphrase->new(%{ $encoding });

	$self->inflate_column(
		$column => {
			inflate => sub { Crypt::Passphrase::PassphraseHash->new($crypt_passphrase, shift) },
			deflate => sub { shift->raw_hash },
		},
	);
}

1;

# ABSTRACT: Inflate/deflate columns to passphrase objects

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::InflateColumn::Crypt::Passphrase - Inflate/deflate columns to passphrase objects

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 __PACKAGE__->load_components(qw(InflateColumn::Crypt::Passphrase));

 __PACKAGE__->add_columns(
     id => {
         data_type         => 'integer',
         is_auto_increment => 1,
     },
     passphrase => {
         data_type          => 'text',
         inflate_passphrase => {
             encoders   => {
                 module      => 'Argon2',
                 memory_cost => '64M',
                 time_cost   => 5,
                 parallelism => 4,
             },
             validators => [
                 'BCrypt',
             ],
         },
     },
 );

 __PACKAGE__->set_primary_key('id');


 # in application code
 $rs->create({ passphrase => 'password1' });

 my $row = $rs->find({ id => $id });
 if ($row->passphrase->verify_password($input)) { ...

=head1 DESCRIPTION

Provides inflation and deflation for Crypt::Passphrase instances from and to
crypt encoding.

To enable both inflating and deflating, C<inflate_passphrase> must be set to a
L<Crypt::Passphrase|Crypt::Passphrase> construction hash.

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns appropriately. This would not normally be directly called by
end users.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
