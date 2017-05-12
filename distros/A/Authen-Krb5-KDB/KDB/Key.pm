package Authen::Krb5::KDB::Key;

# $Id: Key.pm,v 1.3 2002/10/09 20:42:42 steiner Exp $

use Carp;
use Authen::Krb5::KDB::Utils;
use strict;
use vars qw($VERSION);

$VERSION = do{my@r=q$Revision: 1.3 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# If value is 1, the value is read/write and we build the accessor function;
#  if 0, the value is read-only and an accessor function is built.
#  if -1, the accessor function is written by hand

my %Key_Fields = (
    'version'         =>  1, # XXX writable?
    'kvno'            =>  1, # XXX writable?
    'type'            => -1,
    'length'          => -1,
    'contents'        => -1,
 );


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # version => N
        # kvno => N
        # data => array of type,len,contents tuples
    my $self = {};
    $self->{'_data_cntr'} = -1;

    # check arguments
    if (not defined($args{'version'})) {
	croak "version for Key data not defined at line $args{'lineno'}";
    }
    if (not defined($args{'kvno'})) {
	croak "kvno for Key data not defined at line $args{'lineno'}";
    }
    if (not defined($args{'data'}) or @{$args{'data'}} < 1) {
	croak "data for Key data not defined at line $args{'lineno'}";
    }

    $self->{'version'} = $args{'version'};
    $self->{'kvno'} = $args{'kvno'};
    $self->{'data'} = [];

    foreach my $tuple (@{$args{'data'}}) {
	my $p = {};
	$p->{'type'}     = $tuple->[0];
	$p->{'length'}   = $tuple->[1];
	$p->{'contents'} = $tuple->[2];

	# probably already checked but let's make sure
	if ($args{'checks'}) {
	    if (check_length($p->{'length'}*2, $p->{'contents'})) {
		carp "key contents length field not ok at line $args{'lineno'}";
	    }
	}

	push @{$self->{'data'}}, $p;
    }

    if ($args{'checks'} == 2) {
	_check_level2($self, $args{'lineno'});
    }

    bless($self, $class);
    return $self;
}

sub _check_level2 ($$) {
    my $self = shift;
    my $lineno = shift;

    if ($self->{'version'} !~ /^\d+$/) {
	carp "key version is not valid at line $lineno: $self->{'version'}";
    }
    if ($self->{'kvno'} !~ /^\d+$/) {
	carp "key kvno is not valid at line $lineno: $self->{'kvno'}";
    }
    foreach my $data (@{$self->{'data'}}) {
	if ($data->{'type'} !~ /^\d+$/) {
	    carp "key type is not valid at line $lineno: $data->{'type'}";
	}
	if ($data->{'length'} !~ /^\d+$/) {
	    carp "key length is not valid at line $lineno: $data->{'length'}";
	}
	if ($data->{'contents'} ne '-1' and
	    $data->{'contents'} !~ /^[\da-f]+$/) {
	    carp "key contents is not valid at line $lineno: $data->{'contents'}";
	}
    }
}

#XXX what is format???
sub parse_contents {
    my $self = shift;

    my $byte = 8;
    my $template = "A2" x $self->length();
    my @modname;
    my $modname = '';
    my $octet = 0;

    @modname = map hex, unpack($template, $self->contents());
    $modname = join '', map chr, @modname;
    return $modname;
}

sub next_data {
    my $self = shift;
    if (defined($self->{'data'}[$self->{'_data_cntr'}+1])) {
	$self->{'_data_cntr'}++;
	return 1;
    } else {
	$self->{'_data_cntr'} = -1;
	return 0;
    }
}

sub type {
    my $self = shift;
    carp "Can't change value via type method"  if @_;
    carp "Need to call the next_data method before calling type method"
	if ($self->{'_data_cntr'} == -1);
    return $self->{'data'}[$self->{'_data_cntr'}]->{'type'};
}

sub length {
    my $self = shift;
    carp "Can't change value via length method"  if @_;
    carp "Need to call the next_data method before calling length method"
	if ($self->{'_data_cntr'} == -1);
    return $self->{'data'}[$self->{'_data_cntr'}]->{'length'};
}

sub contents {
    my $self = shift;
    carp "Need to call the next_data method before calling contents method"
	if ($self->{'_data_cntr'} == -1);
    if (@_) {
	$self->{'data'}[$self->{'_data_cntr'}]->{'contents'} = shift;
	# length is the number of hex pairs
	$self->{'data'}[$self->{'_data_cntr'}]->{'length'} =
	  CORE::length($self->{'data'}[$self->{'_data_cntr'}]->{'contents'})/2;
    }
    return $self->{'data'}[$self->{'_data_cntr'}]->{'contents'};
}

# generate rest of accessor methods
foreach my $field (keys %Key_Fields) {
    no strict "refs";
    if ($Key_Fields{$field} == 1) {
	*$field = sub {
	    my $self = shift;
	    $self->{$field} = shift  if @_;
	    return $self->{$field};
	};
    } elsif (not $Key_Fields{$field}) {
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

Authen::Krb5::KDB::Key - objects for Kerberos V5 database Key data


=head1 SYNOPSIS

    use Authen::Krb5::KDB::Key;

    Authen::Krb5::KDB::Key->new ( checks  => N,
				  lineno  => N,
				  version => $version,
				  kvno    => $kvno,
				  data    => $data );

    foreach my $key (@{$principal->key_data()}) {
	print " Ver: ", $key->version(), "\n";
	print "Kvno: ", $key->kvno(), "\n";
	while ($key->next_data()) {
	    print " Type:     ", $key->type(), "\n";
	    print " Length:   ", $key->length(), "\n";
	    print " Contents: ", $key->contents(), "\n";
	}
    }


=head1 DESCRIPTION

Generally this functions are only used internally within other KDB modules.

=over 4

=item  new()

=item  version

=item  kvno

=item  next_data()

=item  type (I<read only>)

=item  length (I<read only>)

=item  contents

=item  parse_contents

Parse hexadecimal contents and return as a string.

=back


=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>


=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner.  All rights reserved.  

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB, Authen::Krb5::KDB_H,
Authen::Krb5::KDB::V5, Authen::Krb5::KDB::V4, Authen::Krb5::KDB::V3.

=cut
