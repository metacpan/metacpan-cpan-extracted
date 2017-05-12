package DBIx::Class::InflateColumn::Boolean;

use warnings;
use strict;

use base qw/DBIx::Class/;

=head1 NAME

DBIx::Class::InflateColumn::Boolean - Auto-create boolean objects from columns.

=head1 VERSION

Version 0.003000

=cut

our $VERSION = '0.003000';

=head1 SYNOPSIS

Load this component and declare columns as boolean values.

  package Table;
  __PACKAGE__->load_components(qw/InflateColumn::Boolean Core/);
  __PACKAGE__->table('table');
  __PACKAGE__->true_is('Y');
  __PACKAGE__->add_columns(
      foo => {
          data_type => 'varchar',
          is_boolean  => 1,
      },
      bar => {
          data_type => 'varchar',
          is_boolean  => 1,
          true_is     => qr/^(?:yes|ja|oui|si)$/i,
      },
      baz => {
          data_type => 'int',
          is_boolean  => 1,
          false_is    => ['0', '-1'],
      },
  );

Then you can treat the specified column as a boolean:

  print 'table.foo is ', $table->foo ? 'true' : 'false', "\n";
  print 'table.bar is ', $table->bar ? 'true' : 'false', "\n";

The boolean object still stringifies to the actual field value:

  print $table->foo;  # prints "Y" if it is true

=head1 DESCRIPTION

Perl does not have a native boolean data type by itself, it takes
certain several scalar values as C<false> (like '', 0, 0.0) as well as
empty lists and C<undef>, and everything else is C<true>. It is also
possible to set the boolean value of an object instance.

As in most program code you have boolean data in nearly every database.
But for a database it is up to the designer to decide what is C<true>
and what is C<false>.

This module maps such "database booleans" into "Perl booleans" and back
by inflating designated columns into objects that store the original value,
but also evaluate as true or false in boolean context.  Therefore - if
"Yes" in the database means C<true> and "No" means C<false> in the
application the following two lines can virtually mean the same:

  if ($table->field eq "No") { ... }
  if (not $table->field) { ... }

That means that C<< $table->field >> has the scalar value "No", but
is taken as C<false> in a boolean context, whereas Perl would normally
regard the string "No" as C<true>.

When writing to the database, of course C<< $table->field >> would be
deflated to the original value "No" and not some Perlish form of a
boolean.

=head2 Important Notice

It is strongly encouraged to assign normal database values to a boolean
field when creating a fresh row, because:

=over 4

=item KISS (http://en.wikipedia.org/wiki/KISS_principle)

Just say "No" when you mean it.

=item Don't rely on the current boolean class

Take the underlying boolean class as a black box. It might be replaced by
something other in future versions of this module.

=back

Simply assign the appropriate scalars to boolean fields ("Yes" or "No"
for the above example).

=head2 Another Important Notice

A database C<NULL> value is mapped to Perl's C<undef> and is never
inflated. Therefore C<NULL> is C<false> and this can not be altered.

=head1 METHODS

=head2 true_is

  __PACKAGE__->true_is('Y');
  __PACKAGE__->true_is(['Y', 'y']);
  __PACKAGE__->true_is(qr/^(y|yes|true|1)$/i);

Gets/sets the possible values for C<true> data in this table.
Can be either a scalar, a reference to an array of scalars or a
regular expression (C<qr/.../>).

The last line in the above example shows this package's default
for what is C<true> when neither C<true_is> nor L</false_is> are set.

=head2 false_is

  __PACKAGE__->false_is('N');
  __PACKAGE__->false_is(['N', 'n']);
  __PACKAGE__->false_is(qr/^(n|no|false|0)$/i);

Gets/sets the possible values for C<false> data in this table.
Can be either a scalar, a reference to an array of scalars or a
regular expression (C<qr/.../>).

=cut

__PACKAGE__->mk_group_accessors(inherited => qw/true_is false_is/);

=head2 register_column

Chains with L<DBIx::Class::Row/register_column>, and sets up boolean
columns appropriately. This would not normally be called directly by end
users.

=cut

sub register_column {
    my ($self, $column, $info, @rest) = @_;

    $self->next::method($column, $info, @rest);

    return unless defined $info->{'is_boolean'};

    my ($true_is, $false_is);

    defined($true_is = $info->{true_is})
        or defined($false_is = $info->{false_is})
        or defined($true_is = $self->true_is)
        or defined($false_is = $self->false_is)
        or $true_is = qr/^(y|yes|true|1)$/i;

    my $ref;
    if (defined $false_is) {	# column is false-specific
        $ref = ref $false_is;
        $self->inflate_column(
            $column => {
                inflate =>
                    $ref eq '' ?
                        sub {
                            my $x = shift;
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, $x ne $false_is);
                        } :
                    $ref eq 'ARRAY' ?
                        sub {
                            my $x = shift;
                            for (@$false_is) {
                                return DBIx::Class::InflateColumn::Boolean::Value->new($x, 0)
                                if $x eq $_;
                            }
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, 1)
                        } :
                        # $ref eq 'Regexp'
                        sub {
                            my $x = shift;
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, $x !~ $false_is);
                        },
                deflate => sub { shift },
            }
        );
    }
    else {			# column is true-specific
        $ref = ref $true_is;
        $self->inflate_column(
            $column => {
                inflate =>
                    $ref eq '' ?
                        sub {
                            my $x = shift;
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, $x eq $true_is);
                        } :
                    $ref eq 'ARRAY' ?
                        sub {
                            my $x = shift;
                            for (@$true_is) {
                                return DBIx::Class::InflateColumn::Boolean::Value->new($x, 1)
                                if $x eq $_;
                            }
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, 0)
                        } :
                        # $ref eq 'Regexp'
                        sub {
                            my $x = shift;
                            DBIx::Class::InflateColumn::Boolean::Value->new($x, $x =~ $true_is)
                        },
                deflate => sub { shift },
            }
        );
    }
}

{
    package #hide
        DBIx::Class::InflateColumn::Boolean::Value;

    use overload
        '""' => sub { $_[0][0] },
        'bool' => sub { $_[0][1] },
        fallback => 1,
    ;

    sub new {
        my ($class, $value, $bool) = @_;
        my $self = bless [$value, !!$bool], $class;
    }
}

1;

__END__

=head1 SEE ALSO

L<DBIx::Class>,
L<DBIx::Class::InflateColumn>

=head1 AUTHOR

Bernhard Graf

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/augensalat/DBIx-Class-InflateColumn-Boolean/issues>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Bernhard Graf, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
