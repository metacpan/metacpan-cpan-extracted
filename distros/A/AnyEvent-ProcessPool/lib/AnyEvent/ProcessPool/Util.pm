package AnyEvent::ProcessPool::Util;
# ABSTRACT: A multi-process pool for Perl
$AnyEvent::ProcessPool::Util::VERSION = '0.06';
use strict;
use warnings;
use v5.10;
use parent 'Exporter';

use Data::UUID::MT;

our @EXPORT_OK = qw(
  next_id
  cpu_count
);

sub next_id {
  state $ug = Data::UUID::MT->new(version => 4);
  $ug->create_hex;
}

#-------------------------------------------------------------------------------
# "Borrowed" from Test::Smoke::Util::get_ncpus.
#
# Modifications:
#   * Use $^O in place of an input argument
#   * Return number instead of string
#-------------------------------------------------------------------------------
sub cpu_count {
  # Only *nixy osses need this, so use ':'
  local $ENV{PATH} = "$ENV{PATH}:/usr/sbin:/sbin";

  my $cpus = "?";
  OS_CHECK: {
    local $_ = $^O;

    /aix/i && do {
      my @output = `lsdev -C -c processor -S Available`;
      $cpus = scalar @output;
      last OS_CHECK;
    };

    /(?:darwin|.*bsd)/i && do {
      chomp( my @output = `sysctl -n hw.ncpu` );
      $cpus = $output[0];
      last OS_CHECK;
    };

    /hp-?ux/i && do {
      my @output = grep /^processor/ => `ioscan -fnkC processor`;
      $cpus = scalar @output;
      last OS_CHECK;
    };

    /irix/i && do {
      my @output = grep /\s+processors?$/i => `hinv -c processor`;
      $cpus = (split " ", $output[0])[0];
      last OS_CHECK;
    };

    /linux/i && do {
      my @output; local *PROC;
      if ( open PROC, "< /proc/cpuinfo" ) { ## no critic
        @output = grep /^processor/ => <PROC>;
        close PROC;
      }
      $cpus = @output ? scalar @output : '';
      last OS_CHECK;
    };

    /solaris|sunos|osf/i && do {
      my @output = grep /on-line/ => `psrinfo`;
      $cpus =  scalar @output;
      last OS_CHECK;
    };

    /mswin32|cygwin/i && do {
      $cpus = exists $ENV{NUMBER_OF_PROCESSORS}
        ? $ENV{NUMBER_OF_PROCESSORS} : '';
      last OS_CHECK;
    };

    /vms/i && do {
      my @output = grep /CPU \d+ is in RUN state/ => `show cpu/active`;
      $cpus = @output ? scalar @output : '';
      last OS_CHECK;
    };

    $cpus = "";
    require Carp;
    Carp::carp( "get_ncpu: unknown operationg system" );
  }

  return sprintf '%d', ($cpus || 1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::ProcessPool::Util - A multi-process pool for Perl

=head1 VERSION

version 0.06

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
