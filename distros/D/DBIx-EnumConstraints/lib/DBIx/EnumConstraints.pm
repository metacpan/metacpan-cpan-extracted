use strict;
use warnings FATAL => 'all';

=head1 NAME

DBIx::EnumConstraints - generates enum-like SQL constraints.

=head1 SYNOPSIS

  use DBIx::EnumConstraints;

  my $ec = DBIx::EnumConstraints->new({
	  	table => 'the_table'
		, name => 'kind', fields => [ [ 'a', 'b' ]
					, [ 'b' ] ]
  });

=head1 DESCRIPTION

This module generates SQL statements for enforcing enum semantics on the
database columns.

Enum columns is the column which can get one of 1 .. k values. For each of
those values there are other columns which should or should not be null.

For example in the SYNOPSIS above, when C<kind> column is 1 the row should have
both of C<a> and C<b> columns not null. When C<kind> column is 2 the row should
have C<a> but no C<b> columns.

=cut

package DBIx::EnumConstraints;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(name fields optionals table));

our $VERSION = '0.05';

=head1 CONSTRUCTORS

=head2 $class->new($args)

C<$args> should be HASH reference containing the following parameters:

=over

=item table

The table for which to generate the constraints.

=item name

The name of the enum.

=item fields

Array of arrays describing columns dependent on the enum. Each row is index
is the possible value of enum minus 1 (e.g. row number 1 is for enum value 2).

The items are column names. There is a possibility to mark optional columns by
using trailing C<?> (e.g. C<b?> denotes an optional C<b> field.

=item column_groups

Hash of columns dependent on other columns. E.g. a => [ 'b', 'c' ] means that
when C<a> is present C<b>, C<c> columns should be present as well.

The key column should be given in C<fields> parameter above.

=back

=cut
sub new {
	my ($class, $args) = @_;
	my $self = $class->SUPER::new($args);
	my $cgs = $args->{column_groups} || {};
	$self->optionals({});
	my $i = 1;
	for my $f (@{ $self->fields || [] }) {
		my @cfs = map { @{ $cgs->{$_ } || [] } } @$f;
		push @$f, @cfs;
		for my $in (@$f) {
			$self->optionals->{$i}->{$in} = 1 if ($in =~ s/\?$//);
		}
		$i++;
	}
	return $self;
}

=head1 METHODS

=head2 $self->for_each_kind($callback)

Runs C<$callback> over registered enum states. For each state passes state
index, fields which are in the state and fields which are out of the state.

The fields are passed as ARRAY references.

=cut
sub for_each_kind {
	my ($self, $cb) = @_;
	my $fs = $self->fields;
	my %all;
	for my $f (@$fs) {
		$all{$_} = 1 for @$f;
	}
	my $i = 1;
	for my $f (@$fs) {
		my %not = %all;
		delete $not{$_} for @$f;
		$cb->($i, $f, [ sort keys %not ]);
		$i++;
	}
}

=head2 $self->make_constraints

Generates suitable PostgreSQL constraints using the fields.

Also generates drop plpgsql function to automate dropping of the constraints.

=cut
sub make_constraints {
	my $self = shift;
	my ($n, $t, $fc) = ($self->name, $self->table, @{ $self->fields } + 1);
	my (%fins, %fouts);
	$self->for_each_kind(sub {
		my ($i, $ins, $outs) = @_;
		push @{ $fins{$_} }, $i for @$ins;
		push @{ $fouts{$_} }, $i for @$outs;
		push @{ $fouts{$_} }, $i for grep {
			$self->optionals->{$i}->{$_} } @$ins;
	});
	my $inconstrs = join("\n", map { sprintf(<<ENDS
alter table $t add constraint $t\_$n\_$_\_out_chk check (
	$_ is null or $n in (%s));
ENDS
		, join(", ", @{ $fins{$_} })) } keys %fins);
	my $outconstrs = join("\n", map { sprintf(<<ENDS
alter table $t add constraint $t\_$n\_$_\_in_chk check (
	$_ is not null or $n in (%s));
ENDS
		, join(", ", @{ $fouts{$_} })) } keys %fouts);
	my $incodro = join("\n", map {
		"alter table $t drop constraint $t\_$n\_$_\_out_chk;"
	} keys %fins);
	my $outcodro = join("\n", map {
		"alter table $t drop constraint $t\_$n\_$_\_in_chk;"
	} keys %fouts);

	my $res = <<ENDS
create function drop_$t\_$n\_constraints() returns void as \$\$
begin
alter table $t drop constraint $t\_$n\_size_chk;
$incodro
$outcodro
drop function drop_$t\_$n\_constraints();
end;
\$\$ language plpgsql;
alter table $t add constraint $t\_$n\_size_chk check ($n > 0 and $n < $fc);
$inconstrs
$outconstrs
ENDS
}

=head2 $self->load_fields_from_db($dbh)

Loads fields configuration from the database using current constraints.

=cut
sub load_fields_from_db {
	my ($self, $dbh) = @_;
	my ($t, $n) = ($self->table, $self->name);
	my $arr = $dbh->selectcol_arrayref(<<ENDS);
select check_clause from information_schema.check_constraints
	where constraint_name = '$t\_$n\_size_chk'
ENDS
	my ($upto) = ($arr->[0] =~ /< (\d+)/);

	$arr = $dbh->selectall_arrayref(<<ENDS);
select constraint_name, check_clause from information_schema.check_constraints
	where constraint_name like '$t\_$n\_%_out_chk'
ENDS
	my @fields = map { [] } (1 .. ($upto - 1));
	for my $a (@$arr) {
		my ($c) = ($a->[0] =~ /$t\_$n\_(\w+)_out_chk$/);
		my @no = ($a->[1] =~ /$n = (\d+)/);
		if (!@no) {
			$a->[1] =~ /$n = .*\[([\d, ]+)/;
			@no = split(', ', $1);
		}
		push(@{ $fields[ $_ - 1 ] }, $c) for @no;
	}
	$self->fields(\@fields);
}

1;

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

