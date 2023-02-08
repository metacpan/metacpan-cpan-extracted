package DBIx::Class::CryptColumn;
$DBIx::Class::CryptColumn::VERSION = '0.001';
use strict;
use warnings;

use Sub::Util 1.40 'set_subname';
use namespace::clean;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::Crypt::Passphrase));

__PACKAGE__->mk_classdata('_passphrase_columns');

sub new {
	my ($self, $attr, @rest) = @_;

	my $ppr_cols = $self->_passphrase_columns;
	for my $col (keys %{ $ppr_cols }) {
		next unless exists $attr->{$col} && !ref $attr->{$col};
		$attr->{$col} = $ppr_cols->{$col}->hash_password($attr->{$col});
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

		$self->_passphrase_columns({
			%{ $self->_passphrase_columns // {} },
			$column => $crypt_passphrase,
		});

		if (defined(my $name = $args->{verify_method})) {
			$self->_export_sub($name, sub {
				my ($row, $value) = @_;
				return $crypt_passphrase->verify_password($row->get_column($column), $value);
			});
		}

		if (defined(my $name = $args->{rehash_method})) {
			$self->_export_sub($name, sub {
				my $row = shift;
				return $crypt_passphrase->needs_rehash($row->get_column($column));
			});
		}

		my %new_info = (%{$info}, inflate_passphrase => $crypt_passphrase);
		$self->next::method($column, \%new_info, @rest);
	}
	else {
		$self->next::method($column, $info, @rest);
	}
}

sub set_column {
	my ($self, $col, $val, @rest) = @_;

	my $passphrase_columns = $self->_passphrase_columns;
	$val = $passphrase_columns->{$col}->hash_password($val) if exists $passphrase_columns->{$col};

	return $self->next::method($col, $val, @rest);
}

1;

# ABSTRACT: Automatically hash password/passphrase columns

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::CryptColumn - Automatically hash password/passphrase columns

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 __PACKAGE__->load_components(qw(CryptColumn));

 __PACKAGE__->add_columns(
     id => {
         data_type         => 'integer',
         is_auto_increment => 1,
     },
     passphrase => {
         data_type          => 'text',
         inflate_passphrase => {
             encoder        => 'Argon2',
             verify_method  => 'verify_passphrase',
             rehash_method  => 'passphrase_needs_rehash',
         },
     },
 );

 __PACKAGE__->set_primary_key('id');

In application code:

 # 'plain' will automatically be hashed using the specified passphrase_class
 # and passphrase_args. The result of the hashing will stored in the
 # specified encoding
 $rs->create({ passphrase => 'plain' });

 my $row = $rs->find({ id => $id });
 my $passphrase = $row->passphrase; # Crypt::Passphrase::PassphraseHash object

 if ($row->verify_passphrase($input)) {
   if ($row->passphrase_needs_rehash) {
     $row->update({ passphrase => $input });
   }
   ...
 }

 $row->passphrase('new passphrase');

=head1 DESCRIPTION

This component can be used to automatically hash password columns using any
scheme supported by L<Crypt::Passphrase> whenever the value of these columns is
changed.

If the C<verify_method> option is set it adds a method with that name to verify
if a password matches the known hash, and likewise C<rehash_method> will add
a method for checking if a password needs to be rehashed.

=head1 METHODS

=head2 register_column

Chains with the C<register_column> method in C<DBIx::Class::Row>, and sets up
passphrase columns according to the options documented above. This would not
normally be directly called by end users.

=head2 set_column

Hash a passphrase column whenever it is set.

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
