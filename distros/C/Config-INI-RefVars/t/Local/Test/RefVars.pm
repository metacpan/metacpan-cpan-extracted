package Local::Test::RefVars;

use strict;
use warnings;

use Exporter 'import';
use Test::Exception;

use Config::INI::RefVars;

our @EXPORT_OK = qw(
  throws_ini_like
  ini_exception
  write_file
);


sub throws_ini_like {
  my ($name, $ini, $re) = @_;

  throws_ok(
    sub {
      my $obj = Config::INI::RefVars->new();
      $obj->parse_ini(src => $ini);
    },
    $re,
    $name,
  );
}


sub ini_exception {
  my ($ini) = @_;

  my $ok = eval {
    my $obj = Config::INI::RefVars->new();
    $obj->parse_ini(src => $ini);
    1;
  };
  return "" if $ok;
  my $error = $@;
  $error =~ s/\s+at\s+\S+\s+line\s+\d+\.?\n?\z//;
  return $error;
}


sub write_file {
  my ($file, $text) = @_;

  open(my $fh, ">:encoding(UTF-8)", $file)
    or die "$file: $!";
  print {$fh} $text;
  close($fh);
}

1;


__END__

=head1 NAME

Local::Test::RefVars - Helper functions for Config::INI::RefVars test cases

=head1 SYNOPSIS

  use lib 't';

  use Local::Test::RefVars qw(
                              throws_ini_like
                              ini_exception
                             );

  throws_ini_like(
                  'unknown function',
                  $ini,
                  qr/unknown function/,
                 );

  my $err = ini_exception($ini);

=head1 DESCRIPTION

This module contains helper functions used by the test suite of
C<Config::INI::RefVars>.

It reduces duplicated test code for parsing INI data and checking
exceptions.

=head1 FUNCTIONS

=head2 throws_ini_like

   throws_ini_like($test_name, $ini, $regex);

Parses the supplied INI source and verifies that parsing dies with
an exception matching C<$regex>.

Internally this function uses C<throws_ok> from L<Test::Exception>.


=head2 ini_exception

  my $err = ini_exception($ini);

Parses the supplied INI source and returns the exception text.

Returns undef if no exception is thrown.

Internally this function uses C<(exception> from L<Test::Exception>.


=head1 AUTHOR

Abdul al Hazred

=head1 LICENSE

This file is part of the L<Config::INI::RefVars> test suite and is
distributed under the same terms as Perl itself.

