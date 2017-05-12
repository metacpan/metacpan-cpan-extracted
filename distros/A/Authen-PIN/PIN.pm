package Authen::PIN;

use Digest::MD5 qw(md5);
use Business::CreditCard;
use Number::Encode qw(uniform);

use Carp;
use strict;
use vars qw($VERSION);

our $VERSION = '1.10';

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Authen::PIN";

    my $template = uc shift;
    my $start = shift;
    
    $start = 0 unless $start;

    croak "Template contains unrecognized characters or is invalid"
	unless $template =~ /^[0-9PCHV]+$/;

    my $self = {
	template => [ split(//, $template) ],
	start => $start,
	inc => 1,
	count => $start,
	p => 0,
	c => 0,
	h => 0,
	v => 0,
    };

    for my $d (@{$self->{template}}) {
	if ($d eq 'P') { $self->{p} ++; }
	elsif ($d eq 'C') {$self->{c} ++; }
	elsif ($d eq 'H') {$self->{h} ++; }
	elsif ($d eq 'V') {$self->{v} ++; }
    }

    bless $self, $class;
}

sub set {
    my $self = shift;
    my $start = shift;
    
    $self->{start} = $start;
}

sub inc {
    my $self = shift;
    my $inc = shift;
    
    $self->{inc} = $inc;
}

sub pin {
    my $self = shift;

    my $pas = undef;
    my $ser = undef;
    my $cnt = undef;
    my $hsh = undef;
    my $ret = undef;

    my $pas_c = 0;
    my $cnt_c = 0;
    my $hsh_c = 0;

    if (@_ == 1) {
	$ser = shift;
    }
    else {
	$pas = shift;
	$ser = join('', @_);
    }
    
    carp("Pass-through not defined in template")
	 if ($pas and not $self->{p});

    if ($self->{c} > 0) {
	$cnt = $self->{count};
	$self->{count} += $self->{inc};
    }

    $hsh = uniform(md5($pas . $ser));

    if (defined $pas and length($pas) < $self->{p}) {
	$pas = (0 x ($self->{p} - length($pas))) . $pas;
    }

    if (defined $cnt and length($cnt) < $self->{c}) {
	$cnt = (0 x ($self->{c} - length($cnt))) . $cnt;
    }
    
    if (defined $hsh and length($hsh) < $self->{h}) {
	$hsh = (0 x ($self->{h} - length($hsh))) . $hsh;
    }

    for my $t (@{$self->{template}}) {
	if ($t =~ /[0-9]/) {
	    $ret .= $t;
	}
	elsif ($t eq 'P') {
	    $ret .= substr($pas, $pas_c ++, 1);
	}
	elsif ($t eq 'C') {
	    $ret .= substr($cnt, $cnt_c ++, 1);
	}
	elsif ($t eq 'H') {
	    $ret .= substr($hsh, $hsh_c ++, 1);
	}
	elsif ($t eq 'V') {
	    $ret .= generate_last_digit($ret);
	}
    }

    return $ret;
}


1;
__END__

=head1 NAME

Authen::PIN - Create and verify strong PIN numbers

=head1 SYNOPSIS

  use Authen::PIN;

  my $pinset = new Authen::PIN ('PPPCCP123HHHHHHHV',
				$start 		# Optional
				);

  $pinset->set($start);		# Preferred
  $pinset->inc($inc);
  $pinset->pin($pass_through, $serial);

# OR

  $pinset->pin($serial);	# undef $pass_through
    

=head1 DESCRIPTION

This module provides an interface to create crypto-strong PIN numbers
for applications such as calling cards that require a number that is
difficult to guess and that might convey hidden information.

It is based on templates, that define how the resulting PIN number
will be constructed by combining the following components:

=over

=item B<Pass through values>

This is represented in the template with the letter 'P'. It is copied
as is to the resulting PIN. Digits are passed to the template from
left to right. If the supplied value in the call to C<-E<gt>pin> is
too short, it will be left-padded with zeros.

=item B<Counters>

Represented in the template with the letter 'C'. This is a regular
counter that starts at the value passed to C<-E<gt>set> or C<$start>
(if specified) and is incremented for each call to C<-E<gt>pin> by
whatever value was passed to C<-E<gt>inc> (or 1 by default).

=item B<Hashes>

These are represented by the letter 'H'. When calling
C<-E<gt>pin($pass, $serial)>, the concatenation of C<$pass> and
C<$serial> are passed through the MD5 function and the result
converted to a string of digits. This string is replaced, from left to
right, into the supplied template. There is a limit in the number of
digits that a hash can generate. Using more than 20 or so digits is
discouraged as this might result in PIN numbers that are not strong
enough. In practice, a PIN number with such a large number of digits
is probably of little use.

=item B<Verification digit>

It is represented with the 'V' character in the template. When found,
a checksum of the PIN constructed so far will be calculated and placed
at the current position. This is usually used as the last digit in the
PIN template, to allow for a digit that allows for the simple discard
of bogus PIN number, avoiding more expensive database operations in a
complete application. The algorythm used for this checksum, is the
same used by credit cards, as implemented by Business::Creditcard.

=item B<Literal digits>

Digits in the range 0-9 are copied to the resulting PIN.

=back

=head1 AUTHOR

Luis E. Munoz <lem@cantv.net>

=head1 CHANGES

=over

=item 1.00  Fri Jan 12 15:51:03 2001
    original version; created by h2xs 1.19

=item 1.10  Thu Mar 01 18:15:00 2001
    modified to use Number::Encode to achieve a more robust PIN digit
    distribution


=back

=head1 WARRANTY

This code has the same warranty that Perl itself.

=head1 SEE ALSO

perl(1), Digest::MD5.

=cut
