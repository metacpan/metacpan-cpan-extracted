package App::bmkpasswd;
$App::bmkpasswd::VERSION = '2.012002';
use strictures 2;
use Carp;
use Try::Tiny;

use Crypt::Eksblowfish::Bcrypt qw/
  bcrypt 
  en_base64
/;

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  mkpasswd
  passwdcmp 
/;
our @EXPORT_OK = qw/
  mkpasswd_available
  mkpasswd_forked
/;

{ local @INC = @INC;
  pop @INC if $INC[-1] eq '.';
  require Bytes::Random::Secure::Tiny;
}
my ($brs, $brsnb);
sub get_brs {
  my (%params) = @_;
  $params{strong} ?
    $brs ||= Bytes::Random::Secure::Tiny->new(Bits => 128, NonBlocking => 0)
    : $brsnb ||= Bytes::Random::Secure::Tiny->new(Bits => 128, NonBlocking => 1)
}

sub mkpasswd_forked {
  srand; # wrt random-length salts
  undef $brs;
  undef $brsnb;
}

# can be local'd or replaced, but you get to keep both pieces ->
our $SaltGenerator = sub {
  my ($type, $strong) = @_;

  my $rnd = get_brs(strong => $strong);
  if ($type eq 'bcrypt') {
    return en_base64( $rnd->bytes(16) );
  }

  if ($type eq 'sha') {
    my $max = en_base64( $rnd->bytes(16) );
    my $initial = substr $max, 0, 8, '';
    # Drepper recommends random-length salts:
    $initial .= substr $max, 0, 1, '' for  1 .. rand 8;
    return $initial
  }

  if ($type eq 'md5') {
    return en_base64( $rnd->bytes(6) );
  }

  confess "SaltGenerator fell through, unknown type $type"
};

my %_can_haz;
sub have_passwd_xs {
  unless (defined $_can_haz{passwdxs}) {
    local @INC = @INC;
    pop @INC if $INC[-1] eq '.';
    try { require Crypt::Passwd::XS;  $_can_haz{passwdxs} = 1 } 
      catch { $_can_haz{passwdxs} = 0 };
  }
  $_can_haz{passwdxs}
}

my %_shatests = (
  sha256 => sub {
    my $testc = try { crypt('a', '$5$abc$') } catch { warn $_; () };
    $testc && index($testc, '$5$abc$') == 0 ? 1 : ()
  },
  sha512 => sub {
    my $testc = try { crypt('b', '$6$abc$') } catch { warn $_; () };
    $testc && index($testc, '$6$abc$') == 0 ? 1 : ()
  },
);

sub have_sha {
  # if we have Crypt::Passwd::XS, just use that:
  return 1 if have_passwd_xs();
  # else determine (the slow way) if SHA256/512 are available via libc:
  my $rate = $_[0] || 512;
  my $type = "sha$rate";
  return $_can_haz{$type} if defined $_can_haz{$type};
  if (exists $_shatests{$type} && $_shatests{$type}->()) {
    return $_can_haz{$type} = 1
  }
  return $_can_haz{$type} = 0
}

sub have_md5 {
  return 1 if have_passwd_xs();
  return $_can_haz{md5} if defined $_can_haz{md5};
  my $testc = try { crypt('a', '$1$abcd$') } catch { warn $_; () };
  if ($testc && index($testc, '$1$abcd$') == 0) {
    return $_can_haz{md5} = 1
  }
  return $_can_haz{md5} = 0
}


sub mkpasswd_available {
  my ($type) = @_;

  unless ($type) {
    return (
      'bcrypt',
      ( have_sha(256) ? 'sha256' : () ),
      ( have_sha(512) ? 'sha512' : () ),
      ( have_md5()    ? 'md5'    : () ),
    );
  }

  $type = lc $type;
  return 1            if $type eq 'bcrypt';
  return have_sha($1) if $type =~ /^sha-?(\d{3})$/;
  return have_md5()   if $type eq 'md5';
  return
}



sub mkpasswd {
  # mkpasswd $passwd => $type, $cost, $strongsalt;
  # mkpasswd $passwd => +{
  #   type => $type,
  #   cost => $cost,
  #   saltgen => $coderef,
  #   strong => $strongsalt,
  # }
  my $pwd = shift;
  croak "mkpasswd passed an undef password"
    unless defined $pwd;

  my %opts =
    ref $_[0] eq 'HASH' ? %{ $_[0] }
    : map {; $_ => shift } qw/type cost strong/;
  my $type = defined $opts{type} ? $opts{type} : 'bcrypt';
  my $saltgen = $opts{saltgen} || $SaltGenerator;

  my $salt;

  TYPE: {
    if ($type =~ /^bcrypt$/i) {
      my $cost = $opts{cost} || '08';

      croak 'Work cost factor must be numeric'
        unless $cost =~ /^[0-9]+$/;
      $cost = "0$cost" if length $cost == 1;

      $salt = $saltgen->(bcrypt => $opts{strong});
      my $bsettings = join '', '$2a$', $cost, '$', $salt;

      # bcrypt returns from here; everything else depends on have_passwd_xs
      return bcrypt($pwd, $bsettings)
    }

    if ($type =~ /^sha-?512$/i) {
      croak 'SHA hash requested but no SHA support available' 
        unless have_sha(512);
      $salt = join '', '$6$', $saltgen->(sha => $opts{strong}), '$';
      last TYPE
    }

    if ($type =~ /^sha(-?256)?$/i) {
      croak 'SHA hash requested but no SHA support available' 
        unless have_sha(256);
      $salt = join '', '$5$', $saltgen->(sha => $opts{strong}), '$';
      last TYPE
    }

    if ($type =~ /^md5$/i) {
      croak 'MD5 hash requested but no MD5 support available'
        unless have_md5;
      $salt = join '', '$1$', $saltgen->(md5 => $opts{strong}), '$';
      last TYPE
    }

    croak "Unknown type specified: $type"
  }

  have_passwd_xs() ?
    Crypt::Passwd::XS::crypt($pwd, $salt) : crypt($pwd, $salt)
}

sub _eq {
  my ($orig, $created) = @_;
  my $unequal = ! (length $orig == length $created);
  my $n = 0;
  no warnings 'substr';
  while ($n < length $orig) {
    my $schr = substr $created, $n, 1;
    $unequal = 1
      if substr($orig, $n, 1) ne (defined $schr ? $schr : '');
    ++$n;
  }
  ! $unequal
}

sub passwdcmp {
  my ($pwd, $crypt) = @_;
  croak 'Expected a password string and hash'
    unless defined $pwd and $crypt;

  my $pos_a = index $crypt, '$';
  my $pos_b = index $crypt, '$', 2;
  carp 'Possibly passed an invalid hash' 
    unless $pos_a == 0
    and    $pos_b == 2
    or     $pos_b == 3;

  if ($crypt =~ /^\$2a\$\d{2}\$/) {
    # Looks like bcrypt.
    return $crypt if _eq( $crypt, bcrypt($pwd, $crypt) )
  } else {
    if (have_passwd_xs) {
      return $crypt
        if _eq( $crypt, Crypt::Passwd::XS::crypt($pwd, $crypt) )
    } else {
      return $crypt
        if _eq( $crypt, crypt($pwd, $crypt) )
    }
  }

  undef
}

1;
__END__

=pod

=head1 NAME

App::bmkpasswd - bcrypt-capable mkpasswd(1) and exported bcrypt interface

=head1 SYNOPSIS

  ## From Perl:

  use App::bmkpasswd -all;
  my $bcrypted = mkpasswd($passwd);
  say 'matched' if passwdcmp($passwd, $bcrypted);

  my $stronger = mkpasswd($passwd, 'bcrypt', 12);

  ## From a shell:

  bmkpasswd --help
  
  # Generate bcrypted passwords:
  bmkpasswd

  # Defaults to work cost factor '08':
  bmkpasswd --workcost='06'

  # SHA requires Crypt::Passwd::XS or a recent libc:
  bmkpasswd --method='sha512'
  
  # Compare a hash:
  bmkpasswd --check=HASH

  # Check hash generation times:
  bmkpasswd --benchmark

=head1 DESCRIPTION

B<App::bmkpasswd> is a bcrypt-enabled C<mkpasswd> implementation.

Helper functions are also exported for use in other applications; see
L</EXPORTED> -- however L<Crypt::Bcrypt::Easy> (from this distribution)
provides an easier bcrypt-specific programmatic interface for Perl
programmers.

See C<bmkpasswd --help> for command-line usage information.

Bcrypt leverages a work-cost factor allowing hash generation
to become configurably slower as computers get faster, thereby
impeding brute-force hash generation attempts.
See L<http://codahale.com/how-to-safely-store-a-password/> for more
on why you ought to be using bcrypt or similar "adaptive" techniques.

B<SHA-256> and B<SHA-512> are supported if available. SHA support requires
either L<Crypt::Passwd::XS> or a system crypt() that can handle SHA (such as
glibc-2.7+ or modern FreeBSD builds).

This module uses L<Crypt::Eksblowfish::Bcrypt> as a back-end.

Uses L<Bytes::Random::Secure::Tiny> to generate random salts. Strongly-random salts
can also be enabled; see L</mkpasswd>.

=head1 EXPORTED

L<Crypt::Bcrypt::Easy> provides an easier programmatic interface, but only
generates bcrypt (although it can validate any supported type).  If you would
like to create crypted passwords using other methods, you can use the exported
B<mkpasswd> and B<passwdcmp> functions:

  # Import selectively:
  use App::bmkpasswd 'mkpasswd', 'passwdcmp';
  # Or import all functions:
  use App::bmkpasswd -all;

This module uses L<Exporter::Tiny> to export functions. This provides for
flexible import options. See the L<Exporter::Tiny> docs for details.

=head2 passwdcmp

Compare a password against a hash.

  if ( passwdcmp($plaintext => $crypted) ) {
    ## Successful match
  } else {
    ## Failed match
  }

B<passwdcmp> will return the hash if it is a match; otherwise, C<undef>
is returned. (This is an API change in C<v2.7.1>; prior versions return
an empty list on failure.)

As of C<v2.10>, a constant time comparison function is used to compare hashes.

=head2 mkpasswd

  my $crypted = mkpasswd($passwd);
  my $crypted = mkpasswd($passwd, $type);
  my $crypted = mkpasswd($passwd, 'bcrypt', $cost);
  my $crypted = mkpasswd($passwd, $type, $cost, $strongsalt);

  my $crypted = mkpasswd( $passwd => 
    +{
      type    => $type,
      cost    => $cost,
      strong  => $strongsalt,
      saltgen => $saltgenerator,
    }
  );

Generate hashed passwords.

By default, generates a bcrypted passwd with work-cost 08:

  $bcrypted = mkpasswd($passwd);

A different work-cost can be specified for bcrypt passwds:

  $bcrypted = mkpasswd($passwd, 'bcrypt', '10');

SHA-256 and SHA-512 are supported, in which case the work-cost value is ignored:

  $crypted = mkpasswd($passwd, 'sha256');
  $crypted = mkpasswd($passwd, 'sha512');

If a fourth boolean-true argument is specified, a strongly-random salt is
generated. This requires spare entropy, and will block if entropy-starved:

  $crypted = mkpasswd($passwd, 'bcrypt', '08', 'strong');
  $crypted = mkpasswd($passwd, 'sha512', 0, 'strong');

Options can be passed as a HASH, instead. This also lets you pass in a salt
generator coderef:

  $crypted = mkpasswd( $passwd => +{
      type => 'bcrypt',
      cost => '10',
      strong  => 0,
      saltgen => $saltgenerator,
    }
  );

The salt generator is passed the type (one of: C<bcrypt>, C<sha>, C<md5>) and
the value of the B<strong> option (default false).

  my $saltgenerator = sub {
    my ($type, $strongsalt) = @_;
    if ($type eq 'bcrypt') {
      # ...
    } elsif ($type eq 'sha') {
      # ...
    } else {
      die "Don't know how to create a salt for type '$type'!"
    }
  };

Most people want random salts, in which case the default salt generator
should be fine.

See L</mkpasswd_forked> if your application loads this module before forking
or creating threads that generate passwords.

=head2 mkpasswd_available

  my @available = mkpasswd_available;

  if ( mkpasswd_available('sha512') ) { ... }

Given no arguments, returns the list of available hash types.

Given a type (see L</mkpasswd>), returns boolean true if the method is available. ('bcrypt' is
always available.)

=head2 mkpasswd_forked

  # After a fork / new thread is created:
  mkpasswd_forked;

To retain secure salts after forking the process or creating a new thread, 
it's advisable to either only load this module after creating the new process
or call B<mkpasswd_forked> in the new process to reset the random seeds used
by salt generators.

Added in C<v2.6.1>.

=head1 AUTHOR

Jon Portnoy <jon@portnoy.me>

=for Pod::Coverage have_\w+ get_\w+

=cut
