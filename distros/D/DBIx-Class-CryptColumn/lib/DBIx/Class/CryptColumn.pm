package DBIx::Class::CryptColumn;
$DBIx::Class::CryptColumn::VERSION = '0.009';
use strict;
use warnings;

use Crypt::Passphrase 0.019;
use Sub::Util 1.40 'set_subname';
use namespace::clean;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::Crypt::Passphrase));

sub new {
	my ($self, $attr, @rest) = @_;

	for my $col (grep { !/^-/ } keys %{ $attr }) {
		next unless my $inflate = $self->column_info($col)->{inflate_passphrase};
		$attr->{$col} = $inflate->hash_password($attr->{$col});
	}

	return $self->next::method($attr, @rest);
}

sub _export_sub {
	my ($self, $name, $sub) = @_;
	my $full_name = $self->result_class . "::$name";
	no strict 'refs';
	*$full_name = set_subname $full_name => $sub;
}

sub register_column {
	my ($self, $column, $info, @rest) = @_;

	if (my $args = $info->{inflate_passphrase}) {
		$self->throw_exception(q['inflate_passphrase' must be a hash reference]) unless ref $args eq 'HASH';

		my $crypt_passphrase = Crypt::Passphrase->new(%{$args});

		if (defined(my $name = $args->{verify_method})) {
			$self->_export_sub($name, sub {
				my ($row, $password) = @_;
				return $crypt_passphrase->verify_password($password, $row->get_column($column));
			});
		}

		if (defined(my $name = $args->{rehash_method})) {
			$self->_export_sub($name, sub {
				my $row = shift;
				return $crypt_passphrase->needs_rehash($row->get_column($column));
			});
		}

		if (defined(my $name = $args->{verify_and_rehash_method})) {
			$self->_export_sub($name, sub {
				my ($row, $password) = @_;

				my $hash = $row->get_column($column);
				my $result = $crypt_passphrase->verify_password($password, $hash);
				if ($result && $crypt_passphrase->needs_rehash($hash)) {
					$row->update({ $column => $password })->discard_changes;
				}

				return $result;
			});
		}

		if (defined(my $name = $args->{recode_hash_method})) {
			$self->_export_sub($name, sub {
				my $row = shift;
				my $old_hash = $row->get_column($column);
				my $new_hash = $crypt_passphrase->recode_hash($old_hash);

				if ($new_hash ne $old_hash) {
					local $self->column_info($column)->{inflate_passphrase};
					$row->update({ $column => $new_hash })->discard_changes;
				}

				return $new_hash;
			});
		}

		$info->{inflate_passphrase} = $crypt_passphrase;
	}

	$self->next::method($column, $info, @rest);
}

sub set_column {
	my ($self, $col, $val, @rest) = @_;

	my $inflate = $self->column_info($col)->{inflate_passphrase};
	$val = $inflate->hash_password($val) if $inflate;

	return $self->next::method($col, $val, @rest);
}

sub set_inflated_column {
	my ($self, $col, $val, @rest) = @_;
	local $self->column_info($col)->{inflate_passphrase};
	$self->next::method($col, $val, @rest);
}

1;

# ABSTRACT: Automatically hash password/passphrase columns

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::CryptColumn - Automatically hash password/passphrase columns

=head1 VERSION

version 0.009

=head1 SYNOPSIS

 __PACKAGE__->load_components(qw(CryptColumn));

 __PACKAGE__->add_columns(
     id => {
         data_type         => 'integer',
         is_auto_increment => 1,
     },
     password => {
         data_type          => 'text',
         inflate_passphrase => {
             encoder        => 'Argon2',
             verify_and_rehash_method  => 'verify_and_rehash_password',
         },
     },
 );

 __PACKAGE__->set_primary_key('id');

In application code:

 # 'plain' will automatically be hashed using the specified
 # inflate_passphrase arguments
 $rs->create({ password => 'plain' });

 my $row = $rs->find({ id => $id });

 if ($row->verify_and_rehash_password($given_password)) {
   ...
 }

 # equivalent to

 if ($row->password->verify_password($given_password)) {
   if ($row->password->needs_rehash) {
     $row->update({ password => $input });
   }
   ...
 }

 # Change password
 $row->password('new password');

=head1 DESCRIPTION

This component can be used to automatically hash password columns using any
scheme supported by L<Crypt::Passphrase> whenever the value of these columns is
changed, as well as conveniently check if any given password matches the hash.

Its main advantage over other similar DBIx::Class extensions is that it provides
the cryptographic agility of Crypt::Passphrase; that means that it allows you to
define a single scheme that will be used for new passwords, but several schemes
to check passwords against. It will be able to tell you if you should rehash
your password, not only because the scheme is outdated, but also because the
desired parameters have changed.

=head1 ARGUMENTS

In addition to the usual C<Crypt::Passphrase> arguments, this module takes three
extra arguments that each set a method on the row.

=over 4

=item * verify_method

If this option is set it adds a method with that name to the row class to verify
if a password matches the known hash. This method takes a password as its single
argument.

=item * rehash_method

If this option is set it will add a method with the given name that checks if a
password needs to be rehashed. It takes no arguments.

=item * verify_and_rehash_method

If this option is set it will add a method with the given name that verifies if
a password matches the known hash. If it does and the hash needs a rehash it
will rehash the password and store the result to the database. In either case it
returns the result of the verification. This method takes a password as its
only argument. This option is recommended over the others for most deployments.

=item * recode_hash_method

If this option is set it will add a method with the given name that checks if
the hash recodes to a new value, and if so updates it in the database, otherwise
this is a no-op.

=back

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns according to the options documented above. This would not
normally be directly called by end users.

=head2 set_column

Hash a passphrase column whenever it is set.

=head2 set_inflated_column

Sets an inflated password column that does not need to be hashed again.

=head2 new

Hash all passphrase columns on C<new()> so that C<copy()>, C<create()>, and
others B<DWIM>.

=head1 SEE ALSO

L<DBIx::Class::PassphraseColumn>

L<DBIx::Class::EncodedColumn>

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
