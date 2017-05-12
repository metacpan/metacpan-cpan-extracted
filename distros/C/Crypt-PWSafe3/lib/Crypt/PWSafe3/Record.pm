#
# Copyright (c) 2011-2015 T.v.Dein <tlinden |AT| cpan.org>.
#
# Licensed under the terms of the Artistic License 2.0
# see: http://www.perlfoundation.org/artistic_license_2_0
#
package Crypt::PWSafe3::Record;

use Carp::Heavy;
use Carp;
use Exporter ();
use vars qw(@ISA @EXPORT %map2name %map2type);

my %map2type = %Crypt::PWSafe3::Field::map2type;

my %map2name = %Crypt::PWSafe3::Field::map2name;

$Crypt::PWSafe3::Record::VERSION = '1.10';

foreach my $field (keys %map2type ) {
  eval  qq(
      *Crypt::PWSafe3::Record::$field = sub {
              my(\$this, \$arg) = \@_;
              if (\$arg) {
                return \$this->modifyfield("$field", \$arg);
              }
              else {
                return \$this->{field}->{$field}->{value};
              }
      }
    );
}

sub new {
  #
  # new record object
  my($this, %param) = @_;
  my $class = ref($this) || $this;
  my $self = \%param;
  bless($self, $class);
  $self->{field} = ();

  # just in case this is a record to be filled by the user,
  # initialize it properly
  my $newuuid = $self->genuuid();

  my $time = time;

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'uuid',
					     raw   => $newuuid,
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'ctime',
					     value => $time,
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'mtime',
					     value => $time
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'lastmod',
					     value => $time
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'passwd',
					     value => ''
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'user',
					     value => ''
					   ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'title',
					     value => ''
					   ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'notes',
					     value => ''
					    ));

  $self->addfield(Crypt::PWSafe3::Field->new(
					     name  => 'group',
					     value => ''
					    ));

  return $self;
}

sub modifyfield {
  #
  # add or modify a record field
  my($this, $name, $value) = @_;
  if (exists $map2type{$name}) {
    my $type = $map2type{$name};
    my $field = Crypt::PWSafe3::Field->new(
					   type => $type,
					   value => $value
					  );

    my $time = time;

    # we are in fact just overwriting an eventually
    # existing field with a new one, instead of modifying
    # it, so we are using the conversion automatism in
    # Field::new()
    $this->addfield($field);

    # mark the field as modified if it's passwd field
    $this->addfield(Crypt::PWSafe3::Field->new(
					       name => 'mtime',
					       value => $time
					      )) if $name eq 'passwd';

    $this->addfield(Crypt::PWSafe3::Field->new(
					       name  => "lastmod",
					       value => $time
					      ));

    my ($package, $filename, $line, $subroutine, @ignore) = caller(1);

    # this looks a little bit weird but it's a cool feat.
    # 'super' contains the vault object (of class Crypt::PWSafe3),
    # which initially called our new() method, so we know to which
    # vault we belong.
    # therefore, if the user just calls $record->passwd('newpw'),
    # then we can update the record directly on the vault object,
    # so that the user doesn't have to call modifyrecord. this is
    # especially usefull inside a loop.
    # also note, that the 'super' parameter to Crypt::PWSafe3::Record::new()
    # is not documented, so it's an internal parameter not to be used
    # by users. however, maybe in the future it would be useful to
    # have it populated so that if a user has a function which takes a
    # record as parameter, then in this function he could access the
    # vault as well. maybe.
    #
    # Thu May 21 10:04:15 CEST 2015 tlinden\@cpan.org
    if (exists $this->{super} &&
	"${package}::${subroutine}" !~ /Crypt::PWSafe3::modifyrecord$/ &&
       	"${package}::${subroutine}" !~ /Crypt::PWSafe3::newrecord$/ &&
 	"${package}::${subroutine}" !~ /Crypt::PWSafe3::Record::modifyfield$/
       ) {
      # we've been called from the outside (the user in fact) and
      # we're attached to a vault, so update ourselfes there as well
      $this->{super}->modifyrecord($this->uuid, $name, $value);
    }

    return $field;
  }
  else {
    croak "Unknown field $name";
  }
}

sub genuuid {
  #
  # generate a v4 uuid string
  my($this) = @_;
  my $ug    = Data::UUID->new();
  my $uuid  = $ug->create();
  return $uuid;
}

sub addfield {
  #
  # add a field to the record
  my ($this, $field) = @_;
  my $name = $map2name{$field->type};
  unless( defined($name) ) {
      $name = $field->type; # consistent with Field->new
  }
  $this->{field}->{ $name } = $field;
}

sub policy {
  #
  # return or set a password policy
  my ($this, $policy) = @_;

  if($policy) {
    $this->{policy} = $policy;
    $this->pwpol($policy->encode());
  }
  else {
    $this->{policy} = Crypt::PWSafe3::PasswordPolicy->new(raw => $this->pwpol);
  }

  return $this->{policy};
}

=head1 NAME

Crypt::PWSafe3::Record - Represents a Passwordsafe v3 data record

=head1 SYNOPSIS

 use Crypt::PWSafe3;
 my $record = $vault->getrecord($uuid);
 $record->title('t2');
 $record->passwd('foobar');
 print $record->notes;

=head1 DESCRIPTION

B<Crypt::PWSafe3::Record> represents a Passwordsafe v3 data record.
Each record consists of a number of fields of type B<Crypt::PWSafe3::Field>.
The class provides get/set methods to access the values of those
fields.

It is also possible to access the raw unencoded values of the fields
by accessing them directly, refer to L<Crypt::PWSafe3::Field> for more
details on this.

If the record object has been created by L<Crypt::PWSafe3> (and fetched with
Crypt::PWSafe3::getrecord), then it's still associated with the L<Crypt::PWSafe3>
parent object. Changes to the record will therefore automatically populated
back into the parent object (the vault). This is not the case if you created
the record object yourself.

=head1 METHODS

=head2 B<uuid([string])>

Returns the UUID without argument. Sets the UUID if an argument
is given. Must be a hex representation of an L<Data::UUID> object.

This will be generated automatically for new records, so you
normally don't have to cope with.

=head2 B<user([string])>

Returns the username without argument. Sets the username
if an argument is given.

=head2 B<title([string])>

Returns the title without argument. Sets the title
if an argument is given.

=head2 B<passwd([string])>

Returns the password without argument. Sets the password
if an argument is given.

=head2 B<notes([string])>

Returns the notes without argument. Sets the notes
if an argument is given.

=head2 B<group([string])>

Returns the group without argument. Sets the group
if an argument is given.

Group hierarchy can be done by separating subgroups
by dot, eg:

 $record->group('accounts.banking');

=head2 B<ctime([time_t])>

Returns the creation time without argument. Sets the creation time
if an argument is given. Argument must be an integer timestamp
as returned by L<time()>.

This will be generated automatically for new records, so you
normally don't have to cope with.

=head2 B<atime([time_t])>

Returns the access time without argument. Sets the access time
if an argument is given. Argument must be an integer timestamp
as returned by L<time()>.

B<Crypt::PWSafe3> doesn't update the atime field currently. So if
you mind, do it yourself.

=head2 B<mtime([time_t])>

Returns the modification time of the passwd field without argument. Sets the modification time
if an argument is given. Argument must be an integer timestamp
as returned by L<time()>.

This will be generated automatically for modified records if the passwd field changed, so you
normally don't have to cope with.

=head2 B<lastmod([string])>

Returns the modification time without argument. Sets the modification time
if an argument is given. Argument must be an integer timestamp
as returned by L<time()>.

This will be generated automatically for modified records, so you
normally don't have to cope with.

=head2 B<url([string])>

Returns the url without argument. Sets the url
if an argument is given. The url must be in the well
known notation as:

 proto://host/path

=head2 B<pwhist([string])>

Returns the password history without argument. Sets the password history
if an argument is given.

B<Crypt::PWSafe3> doesn't update the pwhist field currently. So if
you mind, do it yourself. Refer to L<Crypt::PWSafe3::Databaseformat>
for more details.

=head2 B<pwpol([string])>

Returns the password policy without argument. Sets the password policy
if an argument is given.

This is the raw encoded policy string. If you want to access it, use the
B<policy()> method, see below.

=head2 B<policy([Crypt::PWSafe3::PasswordPolicy object])>

If called without arguments, returns a Crypt::PWSafe3::PasswordPolicy
object. See L<Crypt::PWSafe3::PasswordPolicy> for details, how to access
it.

To modify the password policy, create new Crypt::PWSafe3::PasswordPolicy
object or modify the existing one and pass it as argument to the
B<policy> method.

=head2 B<pwexp([string])>

Returns the password expire time without argument. Sets the password expire time
if an argument is given.

B<Crypt::PWSafe3> doesn't update the pwexp field currently. So if
you mind, do it yourself. Refer to L<Crypt::PWSafe3::Databaseformat>
for more details.

=head1 MANDATORY FIELDS

B<Crypt::PWSafe3::Record> creates the following fields automatically
on creation, because those fields are mandatory:

B<uuid> will be generated using L<Data::UUID>.

B<user, password, title> will be set to the empty string.

B<ctime, atime, mtime, lastmod> will be set to current
time of creation time.

=head1 SEE ALSO

L<Crypt::PWSafe3>

=head1 AUTHOR

T.v.Dein <tlinden@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2011-2015 by T.v.Dein <tlinden@cpan.org>.
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms of the Artistic
License 2.0, see: L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
