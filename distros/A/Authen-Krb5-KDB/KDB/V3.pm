package Authen::Krb5::KDB::V3;

# $Id: V3.pm,v 1.13 2002/10/09 20:41:55 steiner Exp $

use Carp;
use POSIX qw(strftime);
use Authen::Krb5::KDB_H qw(:Attributes KRB5_KDB_V1_BASE_LENGTH);
use Authen::Krb5::KDB::TL;
use Authen::Krb5::KDB::Key;
use Authen::Krb5::KDB::Utils;
use strict;
use vars qw($VERSION);

$VERSION = do{my@r=q$Revision: 1.13 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# If value is 1, the value is read/write and we build the accessor function;
#  if 0, the value is read-only and an accessor function is built.
#  if -1, the accessor function is written by hand

my %Princ_Fields = (
    'type'            =>  0,
    'len'             =>  0,
    'name_len'        =>  0,
    'n_tl_data'       =>  0,
    'n_key_data'      =>  0,
    'e_length'        =>  0,
    'name'            => -1,
    'attributes'      =>  1,
    'max_life'        =>  1,
    'max_renew_life'  =>  1,
    'expiration'      =>  1,
    'pw_expiration'   =>  1,
    'last_success'    => -1,
    'last_failed'     => -1,
    'fail_auth_count' =>  1,
    'tl_data'         => -1,
    'key_data'        => -1,
    'e_data'          => -1,
 );

my %Princ_Ext_Fields = (
    'last_success_dt' => 0,
    'last_failed_dt'  => 0,
 );

### From krb5-1.2.4/src/kadmin/dbutil/dump.c
# * The dump format is as follows:
# *	len strlen(name) n_tl_data n_key_data e_length
# *	name
# *	attributes max_life max_renewable_life expiration
# *	pw_expiration last_success last_failed fail_auth_count
# *	n_tl_data*[type length <contents>]
# *	n_key_data*[ver kvno ver*(type length <contents>)]
# *	<e_data>
# * Fields which are not encapsulated by angle-brackets are to appear
# * verbatim.  Bracketed fields absence is indicated by a -1 in its
# * place

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # data => "string"

    $args{'raw_data'} = $args{'data'};

    my $p = $class->new_princ ( %args );
    return $p;
}

sub new_princ {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # data => "string"
        # raw_data => "string"
    my $self = {};
    my (@data, $n_data_fields, $n_fields);
    my $n_key_data_fields = 0;

    if (defined($args{'data'})) {
	if ($args{'data'} =~ /;$/) { 
	    chop($args{'data'});
	} else {
	    croak "princ record missing final ';' at line $args{'lineno'}";
	}
	@data = split(/\t/, $args{'data'});
	$self->{'raw_data'} = defined($args{'raw_data'}) ? $args{'raw_data'} : $args{'data'};
    } else {
	croak "data for new principal not defined at line $args{'lineno'}";
    }

    $n_data_fields = scalar @data;

    $self->{'type'} = 'princ';

    $self->{'tl_data'} = [];
    $self->{'key_data'} = [];

    $self->{'len'} = shift @data;
    if ($args{'checks'}) {
	if ($self->{'len'} != KRB5_KDB_V1_BASE_LENGTH) {
	    croak "princ len field not ok at line $args{'lineno'}";
	}
    }
    $self->{'name_len'} = shift @data;
    $self->{'n_tl_data'} = shift @data;
    $self->{'n_key_data'} = shift @data;
    $self->{'e_length'} = shift @data;
    $self->{'name'} = shift @data;
    $self->{'attributes'} = shift @data;
    $self->{'max_life'} = shift @data;
    $self->{'max_renew_life'} = shift @data;
    $self->{'expiration'} = shift @data;
    $self->{'pw_expiration'} = shift @data;
    $self->{'last_success'} = shift @data;
    $self->{'last_success_dt'} = strdate($self->{'last_success'});
    $self->{'last_failed'} = shift @data;
    $self->{'last_failed_dt'} = strdate($self->{'last_failed'});
    $self->{'fail_auth_count'} = shift @data;

    if ($args{'checks'}) {
	if ($self->{'name_len'}  != length($self->{'name'})) {
	    carp "princ name length field not ok at line $args{'lineno'}";
	}
    }

    for my $i (1..$self->{'n_tl_data'}) {
	my $type = shift @data;
	my $len = shift @data;
	my $contents = shift @data;
	if ($args{'checks'}) {
	    if (check_length($len*2, $contents)) {
		carp "princ tl length field not ok at line $args{'lineno'}";
	    }
	}
	push @{$self->{'tl_data'}},
             Authen::Krb5::KDB::TL->new ( checks   => $args{'checks'},
					  lineno   => $args{'lineno'},
					  type     => $type,
					  'length' => $len,
					  contents => $contents );
    }

    for my $i (1..$self->{'n_key_data'}) {
	my $ver = shift @data;
	my $kvno = shift @data;
	$n_key_data_fields += 2;
	my $vers = [];
	for my $j (1..$ver) {
	    my $type = shift @data;
	    my $len = shift @data;
	    my $contents = shift @data;
	    $n_key_data_fields += 3;
	    if ($args{'checks'}) {
		if (check_length($len*2, $contents)) {
		    carp "princ key length field not ok at line $args{'lineno'}";
		}
	    }
	    push @$vers, [ $type, $len, $contents ];
	}
	push @{$self->{'key_data'}},
             Authen::Krb5::KDB::Key->new ( checks  => $args{'checks'},
					   lineno  => $args{'lineno'},
					   version => $ver,
					   kvno    => $kvno,
					   data    => $vers );
    }

    $self->{'e_data'} = shift @data;
    if ($args{'checks'}) {
	if (check_length($self->{'e_length'}, $self->{'e_data'})) {
	    carp "princ e_data length field not ok at line $args{'lineno'}";
	}
    }

    # Note: do tl and key data separately and don't count 'type' field
    $n_fields = scalar(keys %Princ_Fields) - 3;
    $n_fields += 3 * $self->{'n_tl_data'};
    $n_fields += $n_key_data_fields;

    if ($n_data_fields != $n_fields) {
	carp "wrong number of data fields for princ at line $args{'lineno'}";
    }

    if (@data) {
	carp "Still data left from principal at line $args{'lineno'}: @data";
    }

    if ($args{'checks'} == 2) {
	_check_level2($self, $args{'lineno'});
    }

    bless($self, $class);
    return $self;
}

sub print_principal {
    my $self = shift;

    if ($self->type() ne 'princ') {
	croak "data is not a princ record but a '" . $self->type() . "'";
    }

    print "Length:        ", $self->len(), "\n";
    print "strlen(Name):  ", $self->name_len(), "\n";
    print "No. tl Data:   ", $self->n_tl_data(), "\n";
    print "No. Key Data:  ", $self->n_key_data(), "\n";
    print "E Length:      ", $self->e_length(), "\n";
    print "Name:          ", $self->name(), "\n";
    print "Attributes:    ", $self->attributes(), "\n";
    if ($self->attributes()) {
	print "               ", $self->get_attributes(), "\n";
    }
    print "MaxLife:       ", $self->max_life(), "\n";
    print "MaxRenewLife:  ", $self->max_renew_life(), "\n";
    print "Expiration:    ", $self->expiration(), "\n";
    print "PW Expiration: ", $self->pw_expiration(), "\n";
    print "Last Success:  ", $self->last_success_dt(),
		       " (", $self->last_success(), ")\n";
    print "Last Failed:   ", $self->last_failed_dt(),
		       " (", $self->last_failed(), ")\n";
    print "Fail Count:    ", $self->fail_auth_count(), "\n";

    my $i = 1;
    print "TL Data:\n";
    foreach my $tl (@{$self->tl_data()}) {
	print " $i: Type:     ", $tl->type(), "\n";
	print "    Length:   ",  $tl->length(), "\n";
	print "    Contents: ",  $tl->contents(), "\n";
	print "      ", $tl->parse_contents(), "\n";
	$i++;
    }
    
    $i = 1;
    print "Key Data:\n";
    foreach my $key (@{$self->key_data()}) {
	print " $i: Ver: ", $key->version(), "\n";
	print "    Kvno: ", $key->kvno(), "\n";
	while ($key->next_data()) {
	    print "      Type:     ", $key->type(), "\n";
	    print "      Length:   ", $key->length(), "\n";
	    print "      Contents: ", $key->contents(), "\n";
	}
	$i++;
    }

    print "E Data: ", $self->e_data(), "\n";
    print "\n";
}

sub get_attributes {
    my $self = shift;
    my @attrs;

    if ($self->type() ne 'princ') {
	croak "data is not a princ record but a '" . $self->type() . "'";
    }

    if ($self->attributes & KRB5_KDB_DISALLOW_POSTDATED) {
	push @attrs, 'DISALLOW_POSTDATED';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_FORWARDABLE) {
	push @attrs, 'DISALLOW_FORWARDABLE';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_TGT_BASED) {
	push @attrs, 'DISALLOW_TGT_BASED';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_RENEWABLE) {
	push @attrs, 'DISALLOW_RENEWABLE';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_PROXIABLE) {
	push @attrs, 'DISALLOW_PROXIABLE';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_DUP_SKEY) {
	push @attrs, 'DISALLOW_DUP_SKEY';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_ALL_TIX) {
	push @attrs, 'DISALLOW_ALL_TIX';
    }
    if ($self->attributes & KRB5_KDB_REQUIRES_PRE_AUTH) {
	push @attrs, 'REQUIRES_PRE_AUTH';
    }
    if ($self->attributes & KRB5_KDB_REQUIRES_HW_AUTH) {
	push @attrs, 'REQUIRES_HW_AUTH';
    }
    if ($self->attributes & KRB5_KDB_REQUIRES_PWCHANGE) {
	push @attrs, 'REQUIRES_PWCHANGE';
    }
    if ($self->attributes & KRB5_KDB_DISALLOW_SVR) {
	push @attrs, 'DISALLOW_SVR';
    }
    if ($self->attributes & KRB5_KDB_PWCHANGE_SERVICE) {
	push @attrs, 'PWCHANGE_SERVICE';
    }
    if ($self->attributes & KRB5_KDB_SUPPORT_DESMD5) {
	push @attrs, 'SUPPORT_DESMD5';
    }
    if ($self->attributes & KRB5_KDB_NEW_PRINC) {
	push @attrs, 'NEW_PRINC';
    }
    return join(' ', @attrs);
}

sub _check_level2 ($$) {
    my $self = shift;
    my $lineno = shift;

    # check TL and Key data elsewhere

    if ($self->{'name_len'} !~ /^\d+$/) {
	carp "name_len is not valid at line $lineno: $self->{'name_len'}";
    }
    if ($self->{'n_tl_data'} !~ /^\d+$/) {
	carp "n_tl_data is not valid at line $lineno: $self->{'n_tl_data'}";
    }
    if ($self->{'n_key_data'} !~ /^\d+$/) {
	carp "n_key_data is not valid at line $lineno: $self->{'n_key_data'}";
    }
    if ($self->{'e_length'} !~ /^\d+$/) {
	carp "e_length is not valid at line $lineno: $self->{'e_length'}";
    }
    if ($self->{'name'} !~ /^[!-~]+$/) { # any ASCII printable char
	carp "name is not valid at line $lineno: $self->{'name'}";
    }
    if ($self->{'attributes'} !~ /^\d+$/) {
	carp "attributes is not valid at line $lineno: $self->{'attributes'}";
    }
    if ($self->{'max_life'} !~ /^\d+$/) {
	carp "max_life is not valid at line $lineno: $self->{'max_life'}";
    }
    if ($self->{'max_renew_life'} !~ /^\d+$/) {
	carp "max_renew_life is not valid at line $lineno: $self->{'max_renew_life'}";
    }
    if ($self->{'expiration'} !~ /^\d+$/) {
	carp "expiration is not valid at line $lineno: $self->{'expiration'}";
    }
    if ($self->{'pw_expiration'} !~ /^\d+$/) {
	carp "pw_expiration is not valid at line $lineno: $self->{'pw_expiration'}";
    }
    if ($self->{'last_success'} !~ /^\d+$/) {
	carp "last_success is not valid at line $lineno: $self->{'last_success'}";
    }
    if ($self->{'last_failed'} !~ /^\d+$/) {
	carp "last_failed is not valid at line $lineno: $self->{'last_failed'}";
    }
    if ($self->{'fail_auth_count'} !~ /^\d+$/) {
	carp "fail_auth_count is not valid at line $lineno: $self->{'fail_auth_count'}";
    }
    if ($self->{'e_data'} ne '-1' and
	$self->{'e_data'} !~ /^[\da-f]+$/) {
	carp "e_data is not valid at line $lineno: $self->{'e_data'}";
    }
}

### Accessor methods

sub name {
    my $self = shift;
    if (@_) {
	$self->{'name'} = shift;
	$self->{'name_len'} = length($self->{'name'});
    }
    return $self->{'name'};
}

sub last_success {
    my $self = shift;
    if (@_) {
	$self->{'last_success'} = shift;
	$self->{'last_success_dt'} = strdate($self->{'last_success'});
    }
    return $self->{'last_success'};
}

sub last_failed {
    my $self = shift;
    if (@_) {
	$self->{'last_failed'} = shift;
	$self->{'last_failed_dt'} = strdate($self->{'last_failed'});
    }
    return $self->{'last_failed'};
}

sub tl_data {
    my $self = shift;
    if (@_) {
	carp "Argument must be a reference to an array"
	    if (ref($_[0]) ne 'ARRAY');
	$self->{'tl_data'} = shift;
	$self->{'n_tl_data'} = scalar @{$self->{'tl_data'}};
    }
    return $self->{'tl_data'};
}

sub key_data {
    my $self = shift;
    if (@_) {
	carp "Argument must be a reference to an array"
	    if (ref($_[0]) ne 'ARRAY');
	$self->{'key_data'} = shift;
	$self->{'n_key_data'} = scalar @{$self->{'key_data'}};
    }
    return $self->{'key_data'};
}

sub e_data {
    my $self = shift;
    if (@_) {
	$self->{'e_data'} = shift;
	if ($self->{'e_data'} == -1) {
	    $self->{'e_length'} = 0;
	} else {
	    $self->{'e_length'} = length($self->{'e_data'});
	}
    }
    return $self->{'e_data'};
}

# generate rest of accessor methods
foreach my $field (keys %Princ_Fields) {
    no strict "refs";
    if ($Princ_Fields{$field} == 1) {
	*$field = sub {
	    my $self = shift;
	    $self->{$field} = shift  if @_;
	    return $self->{$field};
	};
    } elsif (not $Princ_Fields{$field}) {
	*$field = sub {
	    my $self = shift;
	    carp "Can't change value via $field method"  if @_;
	    return $self->{$field};
	};
    }
}

# all these methods are read-only
foreach my $field (keys %Princ_Ext_Fields) {
    no strict "refs";
    *$field = sub {
	my $self = shift;
	carp "Can't change value via $field method"  if @_;
	return $self->{$field};
    };
}

1;
__END__

=head1 NAME

Authen::Krb5::KDB::V3 - objects for Kerberos V5 database V3 principals


=head1 SYNOPSIS

Generally you won't load this library or call it's C<new> methods directly.
See L<Authen::Krb5::KDB> for more information.

    use Authen::Krb5::KDB::V3;

    $p = Authen::Krb5::KDB::V3->new( data => "..." );

    if ($p->type eq 'princ') {
	print $p->name, ": ", $p->fail_auth_count"\n";
    }


=head1 DESCRIPTION

=over 4

=item  new( data => "..." )

Parses version 3 principal entries and returns the data via an object.
Calls C<new_princ> to do the work.

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

Parses version 3 principal entries and returns the data via an object.

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
