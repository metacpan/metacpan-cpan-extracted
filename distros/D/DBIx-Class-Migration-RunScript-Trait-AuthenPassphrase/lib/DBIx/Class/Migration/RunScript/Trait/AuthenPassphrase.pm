package DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

our $VERSION = "0.002";

use Moose::Role;
use Authen::Passphrase;
use Class::Load 'load_class';

sub authen_passphrase {
  my ($self, $args, $plaintext) = @_;
  my ($passphrase_args, $encoding, $class_part) = (
    ($args->{passphrase_args} || {}),
    ($args->{passphrase} || die "passphrase is required"),
    ($args->{passphrase_class} || die "passphrase_class is required"));

  load_class(my $class = "Authen::Passphrase::$class_part");

  return $class
    ->new( %$passphrase_args, passphrase => $plaintext)
    ->${\"as_${encoding}"};
}

1;

__END__

=head1 NAME

DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase - encode values

=head1 SYNOPSIS

    use DBIx::Class::Migration::RunScript;

    builder {
      'AuthenPassphrase',
      sub {
        my $self = shift;
        my $password = 'plaintext';
        my $encoded = $self->authen_passphrase(\%args, $password)
        $self->schema->resultset('User')->create({name=>"Mr Echo",password=>$encoded});
      };
    };

=head1 DESCRIPTION

This trait is only useful if you are using L<DBIx::Class::Migration>.  We've
supplied this as an external CPAN module since L<Authen::Passphrase> has a
dependency weight we didn't want to impose on core L<DBIx::Class::Migration>.

Sometimes when you are adding data to your schema, you need to encode the value
for security purposes. For example, if you are adding rows to a C<User> table
you could be including a C<password> .  Best security practice requires
that you don't store passwords in plain text.  Typically you will either encrypt
the password (allows you to retrieve it if required, but vulnerable to theft) or
use some sort of hashing algorithm (you can check but never retrieve the
password, probably best option under current practices).

Typically when using L<DBIx::Class> you will use a C<component> such as one of
the following: L<DBIx::Class::PassphraseColumn>, L<DBIx::Class::DigestColumns>
or L<DBIx::Class::EncodedColumn> to assist in doing this correctly.  Support
for this approach is baked into many authentication systems for popular web
frameworks, such as L<Catalyst::Authentication::Store::DBIx::Class>.

This makes the process of doing the right thing for the security of your user's
passwords easy.  However when using L<DBIx::Class::Migration> and perl run
scripts, this introduces an issue, since the C<$schema> that is passed to the
run script is reverse engineered from the current deployed database and will
not contain any of your custom added components.  Thus if you try to insert
passwords with a run script they will appear in plain text in the database.

In order to help with this problem, this trait can be applied to your run script
builder and will expose an L<Authen::Password> object.  This will be
compatible with L<DBIx::Class::PassphraseColumn> which is the system I favor
for hashing user passwords.  So if for example you have a result class
C<MyApp::Schema::User> defined like:

    __PACKAGE__->load_components(qw(PassphraseColumn));

    __PACKAGE__->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        passphrase => {
            data_type        => 'text',
            passphrase       => 'rfc2307',
            passphrase_class => 'SaltedDigest',
            passphrase_args  => {
                algorithm   => 'SHA-1',
                salt_random => 20,
            },
            passphrase_check_method => 'check_passphrase',
        },
    );

__PACKAGE__->set_primary_key('id');

(Example copied from L<DBIx::Class::PassphraseColumn>DBIx::Class::PassphraseColumn>)

You can supply correctly hashed passwords using the following:

    builder {
      'AuthenPassphrase',
      sub {
        my $self = shift;
        my $password = 'plaintext';
        my $args = {
           passphrase       => 'rfc2307',
            passphrase_class => 'SaltedDigest',
            passphrase_args  => {
                algorithm   => 'SHA-1',
                salt_random => 20,
            },

        };

        my $encoded = $self->authen_passphrase($args, $password);
        $self->schema->resultset('User')->create({passphrase=>$encoded});
      };
    };

We have matched the arguments to how L<DBIx::Class::PassphraseColumn> works
so that it is easier for you to synchronize the configuration between both
systems.

If you wish to use this trait with the C<migrate> helper (which applies some
useful traits by default), you should do the following:

    use DBIx::Class::Migration::RunScript;
    use DBIx::Class::Migration::RunScript::Trait::AuthenPassphrase;

    migrate {
      my $runscript = shift;
      ## $runscript->can('authen_passphrase') now.
    }

Although this is not as ideal a solution as finding a way to make sure the
generated migration schema matches your custom schema, it does allow you to
get this working as expected.

=head1 methods

This class defines the follow methods.

=head2 authen_passphrase

Requires a HashRef and a Scalar argument.

Returns an L<Authen::Passphrase> encoded string, based on the provided \%args
and $string to encode.  See L</SYNOPSIS> and L</DESCRIPTION> for more.

=head1 SEE ALSO

L<DBIx::Class::Migration>, L<DBIx::Class::Migration::RunScript>,
L<Authen::Passphrase>.

=head1 AUTHOR

John Napiorkowski L<email:jjnapiork@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright 2013, John Napiorkowski L<email:jjnapiork@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
