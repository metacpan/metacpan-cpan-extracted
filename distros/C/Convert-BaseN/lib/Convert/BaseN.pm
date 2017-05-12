package Convert::BaseN;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;
use Carp;

sub _make_tr($$;$) {
    my ( $from, $to, $opt ) = @_;
    $opt ||= '';
    my $tr = eval qq{ sub{ \$_[0] =~ tr#$from#$to#$opt } };
    croak $@ if $@;
    $tr;
}

my %h2q = qw{ 0 00 1 01 2 02 3 03 4 10 5 11 6 12 7 13
	      8 20 9 21 a 22 b 23 c 30 d 31 e 32 f 33 };
my %q2h = reverse %h2q;

my %o2b = qw{ 0 000 1 001 2 010 3 011 4 100 5 101 6 110 7 111 };
my %b2o = reverse %o2b;

my %v2b = do {
    my $i = 0;
    map { $_ => sprintf( "%05b", $i++ ) } ( '0' .. '9', 'A' .. 'V' );
};
my %b2v = reverse %v2b;

my %gen_decoders = (
    2 => sub {
        my ( $chars ) = @_;
        my $tr = $chars ? _make_tr( $chars, '01' ) : undef;
        sub {
	    my $str = shift;
	    $tr->($str) if $tr;
	    $str =~ tr/01//cd;
	    scalar pack "B*", $str;
	}
    },
    4 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( $chars, '0123' ) : undef;
        sub {
            my $str = shift;
            $tr->($str) if $tr;
            $str =~ tr/0123//cd;
	    $str =~ s/(..)/$q2h{$1}/g;
            scalar pack "H*", $str;
          }
    },
    8 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( $chars, '0-7=' ) : undef;
        sub {
            my $str = shift;
            $tr->($str) if $tr;
            $str =~ tr/0-7//cd;
	    $str =~ s/(.)/$o2b{$1}/g;
	    my $padlen = (length $str) % 8;
	    $str =~ s/0{$padlen}\z//;
            scalar pack "B*", $str;
          }
    },
    16 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( $chars, '0-9a-f' ) : undef;
        sub {
            my $str = shift;
            $tr->($str) if $tr;
            $str =~ tr/0-9a-f//cd;
            scalar pack "H*", lc $str;
          }
    },
    32 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( $chars, '0-9A-V=' ) : undef;
        sub {
            my $str = shift;
            $tr->($str) if $tr;
            $str =~ tr/0-9A-V//cd;
	    $str =~ s/(.)/$v2b{$1}/g;
	    my $padlen = (length $str) % 8;
	    $str =~ s/0{$padlen}\z//;
            scalar pack "B*", $str;
          }
    },
    64 => sub {
	require MIME::Base64;
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( $chars, '0-9A-Za-z+/=' ) : undef;
        sub {
            my $str = shift;
            $tr->($str) if $tr;
	    MIME::Base64::decode($str);
          }
    }
);

sub _fold_line {
    my ( $str, $lf, $cpl ) = @_;
    $lf = "\n" unless defined $lf;
    # warn ord $lf;
    return $str unless $lf;
    $cpl ||= 76;
    $str =~ s/(.{$cpl})/$1$lf/gms;
    $str;
}

my %gen_encoders = (
    2 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( '01', $chars ) : undef;
        sub ($;$$) {
            my ( $str, $lf, $cpl ) = @_;
            my $ret = unpack "B*", $str;
            $tr->($ret) if $tr;
            _fold_line( $ret, $lf, $cpl );
          }
    },
    4 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( '0123', $chars ) : undef;
        sub ($;$) {
            my ( $str, $lf, $cpl ) = @_;
            my $ret = unpack "H*", $str;
            $ret =~ s/(.)/$h2q{$1}/g;
            $tr->($ret) if $tr;
            _fold_line( $ret, $lf, $cpl );
          }
    },
    8 => sub {
        my ( $chars, $nopad ) = @_;
        my $tr = $chars ? _make_tr( '0-7=', $chars ) : undef;
        sub ($;$$) {
            my ( $str, $lf, $cpl ) = @_;
            my $ret = unpack "B*", $str;
            $ret .= 0 while ( length $ret ) % 3;
            $ret =~ s/(...)/$b2o{$1}/g;
            $nopad or do{ $ret .= '=' while ( length $ret ) % 8 };
            $tr->($ret) if $tr;
            _fold_line( $ret, $lf, $cpl );
          }
    },
    16 => sub {
        my ($chars) = @_;
        my $tr = $chars ? _make_tr( '0-9a-f', $chars ) : undef;
        sub ($;$$) {
            my ( $str, $lf, $cpl ) = @_;
            my $ret = unpack "H*", $str;
            $tr->($ret) if $tr;
            _fold_line( $ret, $lf, $cpl );
          }
    },
    32 => sub {
        my ( $chars, $nopad ) = @_;
        my $tr = $chars ? _make_tr( '0-9A-V=', $chars ) : undef;
        sub ($;$$) {
            my ( $str, $lf, $cpl ) = @_;
            my $ret = unpack "B*", $str;
            $ret .= 0 while ( length $ret ) % 5;
            $ret =~ s/(.....)/$b2v{$1}/g;
            $nopad or do{ $ret .= '=' while ( length $ret ) % 8 };
            $tr->($ret) if $tr;
            _fold_line( $ret, $lf, $cpl );
          }
    },
    64 => sub {
        require MIME::Base64;
        my ( $chars, $nopad ) = @_;
        my $tr = $chars ? _make_tr( '0-9A-Za-z+/=', $chars ) : undef;
        sub ($;$$) {
            my ( $str, $lf, $cpl ) = @_;
            $str =
              defined $lf
              ? _fold_line( MIME::Base64::encode( $str, '' ), $lf, $cpl )
              : MIME::Base64::encode( $str, $lf );
	    $str =~ tr/=//d if $nopad;
            $tr->($str) if $tr;
            $str;
          }
    }
);

sub _base64_decode_any {
    require MIME::Base64;
    my $str = shift;
    $str =~ tr{\-\_\+\,\[\]}{+/+/+/};
    local $^W = 0; # in case the string is not padded
    MIME::Base64::decode($str);
}


our %named_decoder = (
    base2       => $gen_decoders{2}->(),
    base4       => $gen_decoders{4}->(),
    DNA         => $gen_decoders{4}->('ACGT'),
    RNA         => $gen_decoders{4}->('UGCA'),
    base8       => $gen_decoders{8}->(),
    base16      => $gen_decoders{16}->('0-9A-F'),
    base32      => $gen_decoders{32}->('A-Z2-7='),
    base32hex   => $gen_decoders{32}->(),
    base64      => \&_base64_decode_any,
    base64_url  => \&_base64_decode_any,
    base64_imap => \&_base64_decode_any,
    base64_ircu => \&_base64_decode_any,
);

our %named_encoder = (
    base2       => $gen_encoders{2}->(),
    base4       => $gen_encoders{4}->(),
    DNA         => $gen_encoders{4}->('ACGT'),
    RNA         => $gen_encoders{4}->('UGCA'),
    base8       => $gen_encoders{8}->(),
    base16      => $gen_encoders{16}->('0-9A-F'),
    base32      => $gen_encoders{32}->('A-Z2-7='),
    base32hex   => $gen_encoders{32}->(),
    base64      => $gen_encoders{64}->(),
    base64_url  => $gen_encoders{64}->( '0-9A-Za-z\-\_=', 1 ),
    base64_imap => $gen_encoders{64}->('0-9A-Za-z\+\,='),
    base64_ircu => $gen_encoders{64}->('0-9A-Za-z\[\]='),
);

sub new {
    my $pkg = shift;
    my %opt = @_ == 1 ? ( name => shift ) : @_;
    my ( $encoder, $decoder );
    if ( $opt{name} ) {
        $decoder = $named_decoder{ $opt{name} };
        $encoder = $named_encoder{ $opt{name} };
        croak "$opt{name} unknown" unless $decoder and $encoder;
    }
    else {
        eval {
            my $nopad = exists $opt{padding} ? !$opt{padding}
		                             : $opt{nopadding};
            $decoder = $gen_decoders{ $opt{base} }->( $opt{chars} );
            $encoder = $gen_encoders{ $opt{base} }->( $opt{chars}, $nopad );
        };
        croak "base $opt{base} unknown" if $@;
    }
    bless {
        decoder => $decoder,
        encoder => $encoder,
    }, $pkg;
}

sub decode { my $self = shift; $self->{decoder}->(@_) }
sub encode { my $self = shift; $self->{encoder}->(@_) }

if (__FILE__ eq $0){
    my ($bn, $encoded);

    $bn = __PACKAGE__->new(base => 2, chars => '<>');
    $encoded = $bn->encode("dankogai", " ");
    warn $encoded;
    warn $bn->decode($encoded);

    $bn = __PACKAGE__->new(base => 4, chars => 'ACGT');
    $encoded = $bn->encode("dankogai", " ");
    warn $encoded;
    warn $bn->decode($encoded);
    $bn = __PACKAGE__->new(base => 8, chars => 'abcdefgh=');
    $encoded = $bn->encode("dankogai");
    warn $encoded;
    warn $bn->decode($encoded);
    warn length $bn->decode($encoded);

    $bn = __PACKAGE__->new(base => 16, chars => '0-9A-F');
    $encoded = $bn->encode("dankogai", " ");
    warn $encoded;

    $bn = __PACKAGE__->new(base => 32);
    $encoded = $bn->encode("dankogai");
    warn $encoded;
    warn $bn->decode($encoded);
    warn length $bn->decode($encoded);

    $bn = __PACKAGE__->new(base => 32, chars => 'A-Z2-7=');
    $encoded = $bn->encode("dankogai");
    warn $encoded;
    warn $bn->decode($encoded);
    warn length $bn->decode($encoded);

    $bn = __PACKAGE__->new(base => 64);
    $encoded = $bn->encode("dankogai");
    warn $encoded;
    warn $bn->decode($encoded);

    $bn = __PACKAGE__->new(base => 64,chars => '0-9A-Za-z\-_=');
    $encoded = $bn->encode(join("", map {chr} 0x21 .. 0x7e), "\n", 40);
    warn $encoded;
    warn $bn->decode($encoded);
    warn scalar unpack "H*", $bn->decode('-__-');

    $bn = __PACKAGE__->new('base69');
    #warn $bn->encode("dankogai");
    #$bn = __PACKAGE__->new(name => 'base4');
    #$bn = __PACKAGE__->new(name => 'basex');
    #$bn = __PACKAGE__->new(base => 17);
}

1;    # End of Convert::BaseN

=head1 NAME

Convert::BaseN - encoding and decoding of base{2,4,8,16,32,64} strings

=head1 VERSION

$Id: BaseN.pm,v 0.1 2008/06/16 17:34:27 dankogai Exp dankogai $

=cut

=head1 SYNOPSIS

  use Convert::BaseN;
  # by name
  my $cb = Convert::BaseN->new('base64');
  my $cb = Convert::BaseN->new( name => 'base64' );
  # or base
  my $cb = Convert::BaseN->new( base => 64 );
  my $cb_url = Convert::BaseN->new(
    base  => 64,
    chars => '0-9A-Za-z\-_=' 
  );
  # encode and decode
  $encoded = $cb->encode($data);
  $decoded = $cb->decode($encoded);

=head1 EXPORT

Nothing.  Instead of that, this module builds I<transcoder object> for
you and you use its C<decode> and C<encode> methods to get the job
done.

=head1 FUNCTIONS

=head2 new

Create the transcoder object.

  # by name
  my $cb = Convert::BaseN->new('base64');
  my $cb = Convert::BaseN->new( name => 'base64' );
  # or base
  my $cb = Convert::BaseN->new( base => 64 );
  my $cb_url = Convert::BaseN->new(
    base  => 64,
    chars => '0-9A-Za-z\-_=' 
  );

You can pick the decoder by name or create your own by specifying base
and character map.

=over 2

=item base

Must be 2, 4, 16, 32 or 64.

=item chars

Specifiles the character map.  The format is the same as C<tr>.

  # DNA is coded that way.
  my $dna = Convert::BaseN->new( base => 4, chars => 'ACGT' );

=item padding

=item nopadding

Specifies if padding (adding '=' or other chars) is required when
encoding.  default is yes.

  # url-safe Base64
  my $b64url = Convert::BaseN->new( 
    base => 64, chars => '0-9A-Za-z\-_=', padding => 0;
  );

=item name

When specified, the following pre-defined encodings will be used.

=over 2

=item base2

base 2 encoding. C<perl> is C<01110000011001010111001001101100>.

=item base4

=item DNA

=item RNA

base 4 encodings. C<perl> is:

  base4: 1300121113021230
  DNA:   CTAACGCCCTAGCGTA
  RNA:   GAUUGCGGGAUCGCAU

base 16 encoding. C<perl> is C<7065726c>.

=item base32

=item base32hex

base 32 encoding mentioned in RFC4648.  C<perl> is:

  base32:    OBSXE3A==
  base32hex: E1IN4R0==

=item base64

=item base64_url

=item base64_imap

=item base64_ircu

base 64 encoding, as in L<MIME::Base64>.  They differ only in
characters to represent number 62 and 63 as follows.

  base64:        +/
  base64_url:    -_
  base64_imap:   +,
  base64_ircu:   []

for all predefined base 64 variants, C<decode> accept ANY form of those.

=back

=back

=head2 decode

Does decode

  my $decoded = $cb->decode($data)

=head2 encode

Does encode.

  # line folds every 76 octets, like MIME::Base64::encode
  my $encoded = $cb->encode($data);
  # no line folding (compatibile w/ MIME::Base64)
  my $encoded = $cb->encode($data, "");
  # line folding by CRLF, every 40 octets
  my $encoded = $cb->encode($data, "\r\n", 40);

=head1 SEE ALSO

RFC4648 L<http://tools.ietf.org/html/rfc4648>

Wikipedia L<http://en.wikipedia.org/wiki/Base64>

L<http://www.centricorp.com/papers/base64.htm>

L<MIME::Base64>

L<MIME::Base32>

L<MIME::Base64::URLSafe>

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-convert-basen at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Convert-BaseN>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Convert::BaseN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Convert-BaseN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Convert-BaseN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Convert-BaseN>

=item * Search CPAN

L<http://search.cpan.org/dist/Convert-BaseN>

=back

=head1 ACKNOWLEDGEMENTS

N/A

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


