package Authen::Krb5::KDB::TL;

# $Id: TL.pm,v 1.3 2002/10/09 20:42:31 steiner Exp $

use Carp;
use Authen::Krb5::KDB_H qw(:TLTypes);
use Authen::Krb5::KDB::Utils;
use strict;
use vars qw($VERSION);

$VERSION = do{my@r=q$Revision: 1.3 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

# If value is 1, the value is read/write and we build the accessor function;
#  if 0, the value is read-only and an accessor function is built.
#  if -1, the accessor function is written by hand

my %TL_Fields = (
    'type'            =>  0,
    'length'          =>  0,
    'contents'        => -1,
 );


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;
        # checks => level
        # lineno => N
        # type => N
        # length => N
        # contents => "string"
    my $self = {};

    # check arguments
    if (not defined($args{'type'})) {
	croak "type for TL data not defined at line $args{'lineno'}";
    }
    if (not defined($args{'length'})) {
	croak "length for TL data not defined at line $args{'lineno'}";
    } else {
	# probably already checked but let's make sure
	if ($args{'checks'}) {
	    if (check_length($args{'length'}*2, $args{'contents'})) {
		carp "tl length field not ok at line $args{'lineno'}";
	    }
	}
    }
    if (not defined($args{'contents'})) {
	croak "contents for TL data not defined at line $args{'lineno'}";
    }

    $self->{'type'} = $args{'type'};
    $self->{'length'} = $args{'length'};
    $self->{'contents'} = $args{'contents'};

    if ($args{'checks'} == 2) {
	_check_level2($self, $args{'lineno'});
    }

    bless($self, $class);
    return $self;
}

sub _check_level2 ($$) {
    my $self = shift;
    my $lineno = shift;

    if ($self->{'type'} !~ /^\d+$/) {
	carp "tl type is not valid at line $lineno: $self->{'type'}";
    }
    if ($self->{'length'} !~ /^\d+$/) {
	carp "tl length is not valid at line $lineno: $self->{'length'}";
    }
    if ($self->{'contents'} ne '-1' and
	$self->{'contents'} !~ /^[\da-f]+$/) {
	carp "tl contents is not valid at line $lineno: $self->{'contents'}";
    }
}

sub parse_contents {
    my $self = shift;

    my $byte = 8;
    my $template = "A2" x $self->length();
    my (@date, $date, @modname);
    my $modname = '';
    my $octet = 0;

    @modname = map hex, unpack($template, $self->contents());
    @date = splice(@modname, 0, 4);
    if (@modname) {
	$modname = ": " . join '', map chr, @modname;
    }
    foreach (@date) {
	$date |= $_ << $octet;
	$octet += $byte;
    }
    $date = strdate($date);
    return "$date$modname";
}

sub contents {
    my $self = shift;
    if (@_) {
	$self->{'contents'} = shift;
	# number of hex pairs
	$self->{'length'} = CORE::length($self->{'contents'})/2;
    }
    return $self->{'contents'};
}

# generate rest of accessor methods
foreach my $field (keys %TL_Fields) {
    no strict "refs";
    if ($TL_Fields{$field} == 1) {
	*$field = sub {
	    my $self = shift;
	    $self->{$field} = shift  if @_;
	    return $self->{$field};
	};
    } elsif (not $TL_Fields{$field}) {
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

Authen::Krb5::KDB::TL - objects for Kerberos V5 database TL data


=head1 SYNOPSIS

    use Authen::Krb5::KDB::TL;

    Authen::Krb5::KDB::TL->new ( checks   => N,
				 lineno   => N,
				 type     => $type,
				 length   => $length,
				 contents => $contents );

    foreach my $tl (@{$principal->tl_data()}) {
	print "Type:     ", $tl->type(), "\n";
	print "Length:   ", $tl->length(), "\n";
	print "Contents: ", $tl->contents(), "\n";
	print "          ", $tl->parse_contents(), "\n";
    }


=head1 DESCRIPTION

Generally the constructor is only used internally within other KDB modules.

=over 4

=item  new()

=item  type (I<read only>)

=item  length (I<read only>)

=item  contents

=item  parse_contents

Parse hexadecimal contents and return as a string of the
form "Date: mod_name\@".

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
