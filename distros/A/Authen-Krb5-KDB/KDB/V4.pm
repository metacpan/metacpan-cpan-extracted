package Authen::Krb5::KDB::V4;

# $Id: V4.pm,v 1.10 2002/10/09 20:41:32 steiner Exp $

use Carp;
use Authen::Krb5::KDB::V3;
use strict;
use vars qw($VERSION @ISA);

@ISA = ( "Authen::Krb5::KDB::V3" );

$VERSION = do{my@r=q$Revision: 1.10 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

my %Policy_Fields = (
    'type'           => 0,
    'name'           => 1,
    'pw_min_life'    => 1,
    'pw_max_life'    => 1,
    'pw_min_length'  => 1,
    'pw_min_classes' => 1,
    'pw_history_num' => 1,
    'policy_refcnt'  => 1,
 );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # data => "string"
    my ($entry_type, $p);

    if ($args{'data'} =~ /^(\w+)\t(.*)$/) {
	$entry_type = $1;
	$args{'raw_data'} = $args{'data'};
	$args{'data'} = $2;
    }

    if ($entry_type eq 'princ') {
	$p = $class->new_princ ( %args );
    } elsif ($entry_type eq 'policy') {
	$p = $class->new_policy ( %args );
    } else {
	carp "Unknown entry type '$entry_type' at line $args{'lineno'}";
	return undef;
    }
    return $p;
}

sub new_policy {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # data => "string"
        # raw_data => "string"
    my $self = {};
    my @data;

    if (defined($args{'data'})) {
	@data = split(/\t/, $args{'data'});
	$self->{'raw_data'} = defined($args{'raw_data'}) ? $args{'raw_data'} : $args{'data'};
    } else {
	croak "data for new policy not defined at line $args{'lineno'}";
    }

    if (scalar @data != scalar(keys %Policy_Fields) - 1) {
	carp "wrong number of data fields for policy at line $args{'lineno'}";
    }

    $self->{'type'} = 'policy';

    $self->{'name'} = shift @data;
    $self->{'pw_min_life'} = shift @data;
    $self->{'pw_max_life'} = shift @data;
    $self->{'pw_min_length'} = shift @data;
    $self->{'pw_min_classes'} = shift @data;
    $self->{'pw_history_num'} = shift @data;
    $self->{'policy_refcnt'} = shift @data;

    if (@data) {
	carp "still data left from policy '$self->{'name'}' at line $args{'lineno'}: '@data'";
    }

    if ($args{'checks'} == 2) {
	_check_level2($self, $args{'lineno'});
    }

    bless($self, $class);
    return $self;
}

sub print_policy {
    my $self = shift;

    if ($self->type() ne 'policy') {
	croak "data is not a policy record but a '" . $self->type . "'";
    }
    print "Policy: ", $self->name(), "\n";
    print "Maximum password life: ", $self->pw_max_life(), "\n";
    print "Minimum password life: ", $self->pw_min_life(), "\n";
    print "Minimum password length: ", $self->pw_min_length(), "\n";
    print "Minimum number of password character classes: ",
            $self->pw_min_classes(), "\n";
    print "Number of old keys kept: ", $self->pw_history_num(), "\n";
    print "Reference count: ", $self->policy_refcnt(), "\n";
    print "\n";
}

sub _check_level2 ($$) {
    my $self = shift;
    my $lineno = shift;

    if ($self->{'name'} !~ /^[!-~]+$/) { # any ASCII printable char
	carp "name is not valid at line $lineno: $self->{'name'}";
    }
    if ($self->{'pw_min_life'} !~ /^\d+$/) {
	carp "pw_min_life is not valid at line $lineno: $self->{'pw_min_life'}";
    }
    if ($self->{'pw_max_life'} !~ /^\d+$/) {
	carp "pw_max_life is not valid at line $lineno: $self->{'pw_max_life'}";
    }
    if ($self->{'pw_min_length'} !~ /^\d+$/) {
	carp "pw_min_length is not valid at line $lineno: $self->{'pw_min_length'}";
    }
    if ($self->{'pw_min_classes'} !~ /^\d+$/) {
	carp "pw_min_classes is not valid at line $lineno: $self->{'pw_min_classes'}";
    }
    if ($self->{'pw_history_num'} !~ /^\d+$/) {
	carp "pw_history_num is not valid at line $lineno: $self->{'pw_history_num'}";
    }
    if ($self->{'policy_refcnt'} !~ /^\d+$/) {
	carp "policy_refcnt is not valid at line $lineno: $self->{'policy_refcnt'}";
    }
}

foreach my $field (keys %Policy_Fields) {
    no strict "refs";
    if ($Policy_Fields{$field}) {
	*$field = sub {
	    my $self = shift;
	    $self->{$field} = shift  if @_;
	    return $self->{$field};
	};
    } else {
	*$field = sub {
	    my $self = shift;
	    carp "Can't change value via $field method"  if @_;
	    return $self->{$field};
	};
    }
}

1;
__END__

=head1 NAME

Authen::Krb5::KDB::V4 - objects for Kerberos V5 database V4 principals and policies


=head1 SYNOPSIS

Generally you won't load this library or call it's C<new> methods directly.
See L<Authen::Krb5::KDB> for more information.

    use Authen::Krb5::KDB::V4;

    $p = Authen::Krb5::KDB::V4->new( data => "..." );

    if ($p->type eq 'princ') {
	print $p->name, ": ", $p->fail_auth_count"\n";
    } elsif ($p->type eq 'policy') {
	print $p->name, ": ", $p->policy_refcnt, "\n";
    }


=head1 DESCRIPTION

=over 4

=item  new( data => "..." )

Parses version 4 principal and policy entries and returns the data via
an object.  Calls either C<new_princ> or C<new_policy> depending on the data.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


=head2 Principals

=over 4

=item  new_princ( data => "..." )

Parses version 4 principal entries and returns the data via an object.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


Methods to retrieve and set data fields are:

=over 4

=item  type (I<read only>)

=item  len (I<read only>)

=item  name_len (I<read only>)

=item  n_tl_data (I<read only>)

=item  n_key_data (I<read only>)

=item  e_length (I<read only>)

=item  name

=item  attributes

=item  max_life

=item  max_renew_life

=item  expiration

=item  pw_expiration

=item  last_success

=item  last_success_dt (I<read only>)

=item  last_failed

=item  last_failed_dt (I<read only>)

=item  fail_auth_count

=item  tl_data

See the L<Authen::Krb5::KDB::TL> for methods to deal with TL objects.

=item  key_data

See the L<Authen::Krb5::KDB::Key> for methods to deal with Key
objects.

=item  e_data

=back

Other methods include:

=over 4

=item  print_principal

Print out the data on a principal, similar to the B<get_principal>
command in B<kadmin>, but more verbose.

=item  get_attributes

Return a string of all the attributes set for this principal.

=back


=head2 Policies

=over 4

=item  new_policy( data => "..." )

Parses version 4 policy entries and returns the data via an object.

Arguments are:

data => E<lt>stringE<gt>

Data to be parsed.  This argument is required.

checks => E<lt>levelE<gt>

Data checking level.  Level 0 means no checks; level 1 (the default)
does basic checks like checking that the lengths in the records are
correct; level 2 does much further consistency checks on the data.

lineno => E<lt>NE<gt>

Line number of the data file where this data came from (for error messages).

=back


Methods to retrieve and set policy data fields are:

=over 4

=item  type (I<read only>)

=item  name

=item  pw_max_life

=item  pw_min_life

=item  pw_min_length

=item  pw_min_classes

=item  pw_history_num

=item  policy_refcnt

=back

Other methods include:

=over 4

=item  print_policy

Print out the policy data, similar to the B<get_policy> command in
B<kadmin>.

=back


=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB, Authen::Krb5::KDB_H,
Authen::Krb5::KDB::TL, Authen::Krb5::KDB::Key.

=cut
