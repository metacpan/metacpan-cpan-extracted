package Crypt::Cracklib;

use strict;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD $DEFAULT_DICT);

require Exporter;
require DynaLoader;

$VERSION = '1.7';
@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(fascist_check check bad_pass);

$DEFAULT_DICT = "";

{
  for my $path (qw(
    /usr/share/pw_dict
    /var/cache/cracklib/cracklib_dict
    /usr/lib/cracklib_dict
    /usr/lib64/cracklib_dict
    /usr/share/dict/cracklib_words)) {

    if (-f "$path.pwd") {

      $DEFAULT_DICT = $path;
      last;
    }
  }
}

# Wrapper.
sub fascist_check {
  my ($password, $dict) = @_;

  if ($password =~ /^\s*$/) {
    return "Nothing to do: \$password is all whitespace!";
  }

  my $ret = _FascistCheck($password, ($dict || $DEFAULT_DICT));

  if (!defined $ret or $ret =~ /^\s*$/) {

    $ret = 'ok';
  }

  return $ret;
}

sub bad_pass {
  my ($password, $dict) = @_;
  return 'Password is all whitespace' if $password =~ /^\s*$/;
  return _FascistCheck($password, ($dict || $DEFAULT_DICT)) || '';
}

# Wrapper wrapper.
sub check {
  my $ret = fascist_check(@_);

  return 1 if $ret eq 'ok';
  return 0;
}

bootstrap Crypt::Cracklib $VERSION;

1;

__END__

=head1 NAME

Crypt::Cracklib - Perl interface to Alec Muffett's Cracklib.

=head1 SYNOPSIS

  use Crypt::Cracklib;

  my $reason = fascist_check($password, $dictionary);

  print "Ok"  if  check($password, $dictionary);
  print "Bad" if !check($password, $dictionary);

=head1 DESCRIPTION

This is a simple interface to the cracklib library.

=head1 FUNCTIONS

=over 4

=item * fascist_check( $password, [ $dictionary ] )

Returns a string value. Either an error, or "ok".

=item * bad_pass( $password, [ $dictionary ] )

Returns a non-empty string on success or an empty string on failure.

=item * check( $password, [ $dictionary ] )

Returns a true or false value if the password is acceptable or not.

=back

=head1 AUTHOR

Dan Sully <daniel@cpan.org>

=head1 BUGS

Please file bugs at https://github.com/dsully/perl-crypt-cracklib/issues

=head1 SEE ALSO

perl(1).

=cut
