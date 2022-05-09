package DBIx::Class::BcryptColumn;

our $VERSION = '0.001003';

use strict;
use warnings;
use Crypt::Bcrypt ();
use Crypt::URandom ();
use Sub::Name ();

use parent 'DBIx::Class';

__PACKAGE__->mk_classdata('_bcrypt_columns_info');

our $DEFAULT_COST = 12;
our $SALT_SIZE = 16;  # You really can't change this

sub default_cost { return $DEFAULT_COST }

sub generate_salt {
  my ($self, $size) = @_;
  $size ||= $SALT_SIZE;
  return Crypt::URandom::urandom($size);
}
 
sub _default_check_method_format {
  my ($self, $column, $info) = @_;
  return "check_${column}";
}

sub _default_check_generator {
    my ($self, $column, %info) = @_;
    return sub {
      my ($self, $value_to_check) = @_;
      my $col_value = $self->get_column($column);
      return Crypt::Bcrypt::bcrypt_check($value_to_check, $col_value);
    };
}

sub _get_normalized_bcrypt_args {
  my ($self, $column, $info) = @_;
  return unless exists $info->{bcrypt};

  my %info = $info->{bcrypt} eq '1' ? () : %{$info->{bcrypt}};
  $info{cost} = $self->default_cost unless exists $info{cost};
  return %info;
}

sub _inject_check_method {
  my ($self, $check_name, $check_subref) = @_;

  no strict 'refs';
  *$check_name = Sub::Name::subname $check_name => $check_subref;
}

sub bcrypt  {
  my ($self, $password, $cost) = @_;
  return Crypt::Bcrypt::bcrypt($password, '2b', $cost, $self->generate_salt);
}

sub register_column {
    my ($self, $column, $info, @rest) = @_;
    $self->next::method($column, $info, @rest);
     
    return unless my %info = $self->_get_normalized_bcrypt_args($column, $info);

    $self->_bcrypt_columns_info({
      %{ $self->_bcrypt_columns_info || {} },
      $column => \%info,
    });
 
    my $method_name = $info{'check_method'} || $self->_default_check_method_format($column, $info);
    my $check_subref = $self->_default_check_generator($column, %info);
    my $check_name = join q[::] => $self->result_class, $method_name;

    $self->_inject_check_method($check_name, $check_subref);
}

sub bcrypt_columns {
  my $self = shift;
  return my @columns = keys %{ $self->_bcrypt_columns_info||+{} };
}

sub _bcrypt_set_columns {
  my $self = shift;
  my @columns = $self->bcrypt_columns;
  foreach my $column (@columns) {
    next unless $self->is_column_changed($column) || !$self->in_storage; # Don't hash unless changed (TODO: Is this premature optimization?)
    my $value = $self->get_column($column);
    my %info = %{$self->_bcrypt_columns_info->{$column}};
    $self->set_column($column, $self->bcrypt($value, $info{cost}));
  }
}

sub insert {
  my $self = shift;
  $self->_bcrypt_set_columns;
  $self->next::method(@_);
}
 
sub update {
  my ($self, $upd, @rest) = @_;
  if (ref $upd) {
    my @columns = $self->bcrypt_columns;
    foreach my $column (@columns) {
      next unless exists $upd->{$column};
      $self->set_column($column => delete $upd->{$column})
    }
  }
  $self->_bcrypt_set_columns;
  $self->next::method($upd, @rest);
}

1;

=head1 NAME

DBIx::Class::BcryptColumn - Set a column to securely hash on insert/update using bcrypt

=head1 SYNOPSIS

    __PACKAGE__->load_components('BcryptColumn');
     
    __PACKAGE__->add_columns(
        password => {
          data_type => 'text',
          bcrypt => 1, # Or a hashref of option overrides, see below
        },
    );

=head1 DESCRIPTION

It's considered best practice to store credential data about your system users (such as passwords)
using a one way hashing algorithm.  That way if your system gets hack and your database becomes
compromised then at least the hackers won't know everyone's password.  It also is useful as a
protective measure against in-house bad actors who have access to your production system as part
of their regular job duties.

There's a few distributions on CPAN to make it easier to do this with L<DBIx::Class>.  The two most
commonly cited are L<DBIx::Class::PassphraseColumn> and L<DBIx::Class::EncodedColumn>.  Those are
both good choices for this problem and all things equal you might want to review those before making
a final choice.  The main reason I wrote this was to solve two issues for me.  First, both of those
perform hashing on C<new> or C<set_column> instead of on insert / update as this module does.  That
approach is considered more secure by the DBIC community since it means that there is never a time
where unhashed passwords are in DBIC code and if you have a core dump or similar error those plain
text passwords have no chance of ending up in a file readable by an unauthorized person.  However if
you are using L<Valiant> and its DBIC glue L<DBIx::Class::Valiant> this means you can't apply any
validation rules at the DBIC level such as minimal password complexity, or do things like use the
confirmation validator, since hashing on C<new> / C<set_column> would happen before validation occurs
(In L<DBIx::Class::Valiant> validation doesn't happen until you try to update / insert the data, or if
you manually invoke C<validate>).  So For L<Valiant> users I wrote this as an option to allow you
to do those things if you are willing to accept the additional risk of plain text passwords in live
memory.  Personal I find this to be a minimal additional risk since it's likely those password will reside
in other parts of the code memory space anyway (such as in L<Catalyst::Request>).  If this risk
bothers you and you still want to use L<DBIx::Class::Valiant> then you can do password validation work 
prior to sending the data to L<DBIx::Class>.  For example if you are using L<Catalyst> you can invoke
some validation work from the controller before sending parameters to DBIC.

As a second difference, this distribution only does hashing using the bcrypt algorithm (via
L<Crypt::Eksblowfish::Bcrypt>).  As of late 2021 this is my goto hashing algorithm and the defaults
I have set should be sufficient to protect you against all but nation state level hackers.  You can 
tweak the defaults a bit to make it a harder algorithm at a higher performance cost.  The other popular
modules mentioned above support a lot of different hashing approaches and if you are not schooled
in security its very easy to accidentally choose a configuration that is not secure. With this
module its very easy to get a setup that is considered secure today (just follow the L</SYNOPSIS>).
If for some reason bcrypt becomes no longer considered secure I will mark this distribution as deprecated.

B<NOTE>: When using this with L<DBIx::Class::Valiant> you should add it AFTER adding the L<DBIx::Class::Valiant::Result>
component.  Otherwise you will still get passwords hashed prior to running validations, which will
negate the entire point.

B<NOTE>: Bcrypt has one downside in that it will truncate values at 72 bytes.  This might be an issue
if you are using this in a country with 2 or 4 byte wide characters (such as Chinese or Japanese
characters).  There are ways around this (the most common approach is to pre hash the password using
a cheaper algorithm like SHA-1) but for now those options are not available in this code.  You'd need
to override or wrap the L</bcrypt> method.  If this becomes a common issue I will consider adding an
option for this (open issues on the issue tracker and hassle the author :) ).

=head1 CONFIGURATION

This component permits the following configuration.  Example usage:

    __PACKAGE__->load_components('BcryptColumn');
     
    __PACKAGE__->add_columns(
      password => {
        data_type => 'text',
        bcrypt => {
          cost => $alt_cost,
          check_method => $alternative_check_method,
        }
      },
    );

=over 4

=item cost

Defaults to 12.  You can use this to change the cost used to generate the hash.  I don't recommend using
a smaller value; using a higher one might cause performance issues on equipment commonly available in
late 2021 when this module was written.

=item check_method

By default we create a method called C<check_${column}> which is useful when you want to see if a
proposed value is the same as the stored but hashed value.  Useful for things like logging into a
website.  If you prefer or need a different method name you can override it here.

=back

=head1 METHODS
 
This component contains the following public methods.

=head2 bcrypt_columns

Returns an array of columns marked to be hashed.

=head2 bcrypt

Arguments: ($value, $cost)

Returns a hashed version of C<$value> using L<Crypt::Eksblowfish::Bcrypt>.  This is used internally
by the component to hash columns but I've exposed it as a public method since you might find it
useful to have in your code.

=head2 default_cost

Returns the default cost we use for C<bcrypt>.  This is 12 unless you override. If you want a bigger cost
its best to set this via column level configuration.

=head2 generate_salt

Arguments ($size).

Returns a salt suitable for using with C<bcrypt>.  You might like to have access to this for things like
creating tokens.  The default $size is 16, which should not be changed for salts that are used with bcrypt
but we offer an argument here in cast you want to make larger results. Just remember that this also runs
the random value thru base64 so you always get a longer strong than the size specified (although its always
the same length in the end).

=head1 AUTHOR

  John Napiorkowski <jnapiork@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (c) 2021 the above named AUTHOR
 
=head1 LICENSE
 
You may distribute this code under the same terms as Perl itself.
 
=cut
