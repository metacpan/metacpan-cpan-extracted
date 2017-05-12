package ApacheLog::Parser;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

ApacheLog::Parser - parse apache 'combined' log format

=head1 SYNOPSIS

  use ApacheLog::Parser qw(parse_line);
  # imports the field constants too

  my %visitors;
  while(my $line = <$fh>) {
    chomp($line);
    my $ref = parse_line($line);
    ($visitors{$ref->[client]} ||= 0)++;
  }
  no ApacheLog::Parser; # cleans-out the constants

  print join("\n  ", 'visitors:',
    map({$_ . ': ' . $visitors{$_}} keys(%visitors))), "\n";


=cut

my @fields;
BEGIN {
  @fields = qw(
    client
    login
    dtime
    request
    file
    params
    proto
    code
    bytes
    refer
    agent
  );
}
use constant ({map({$fields[$_] => $_} 0..$#fields)});

########################################################################
# I-hate-exporter overhead
my %exported;
my $do_export = sub {
  my $package = shift;
  my ($caller, $function) = @_;

  my $track = $exported{$package} ||= {};
  $track = $track->{$caller} ||= {};

  $track->{$function} = 1;
  no strict 'refs';
  *{$caller . '::' . $function} = $package->can($function) or
    croak("cannot $function");
};

sub import {
  my $package = shift;
  my $caller = caller;
  my %args = map({$_ => 1} @_);

  # DWIM bits
  if($args{parse_line}) {
    $args{':fields'} = 1;
  }

  # exports
  if(delete($args{':fields'})) {
    $package->$do_export($caller, $_) for(@fields);
  }

  foreach my $func (keys(%args)) {
    $package->$do_export($caller, $func);
  }
}

=head2 unimport

Allows 'no ApacheLog::Parser' to cleanup your namespace.

=cut

sub unimport {
  my $package = shift;
  my $caller = caller;

  my $track = $exported{$package} ||= {};
  $track = $track->{$caller} ||= {};
  foreach my $func (keys(%$track)) {
    no strict 'refs';
    delete(${$caller . '::'}{$func});
  }
}
########################################################################

# TODO document this as an interface?
our $regexp = qr/^
  ([^ ]+)\ +([^ ]+)\ +([^\[]+)\ +             # client, ruser, login
  \[([^\]]+)\]\ +                            # date
  "(.*)"\ +(\d+)\ +(\d+|-)\ +                # req, code, bytes
  "(.*)"\ +"(.*)"                            # refer, agent
$/x;

=head2 parse_line

Assumes an already chomp()'d $line.

  my $array_ref = parse_line($line);

=cut

sub parse_line {
  my ($line) = @_;

  my @v;
  my $req;

  $line =~ $regexp or die "failed to parse $line";
  (@v[client, login, dtime], $req, @v[code, bytes, refer, agent]) =
    ($1, $3, $4, $5, $6, $7, $8, $9);

  $v[code] or die "no code in $line (@v)";

  $req =~ s/^(?:([A-Z]+) +)?//;
  $v[request] = $1 || ''; # ouch, a non-request (telnet) hack
  # just tear this off the end
  $v[proto] = ($req =~ s# +(HTTP/\d+\.\d+)$##) ? $1 : '';

  @v[file, params] = split(/\?/, $req, 2);
  defined($v[$_]) or $v[$_] = '' for(file, params);
  $v[params] =~ s/\\"/"/g;

  ($v[$_] eq '-') and $v[$_] = ''
    for(login, request, code, refer, agent);
  $v[bytes] = 0 if($v[bytes] eq '-');

  return(\@v);
} # end subroutine parse_line definition
########################################################################

=head2 parse_line_to_hash

Is a little more elegant interface than the array-ref and constants used
in parse_line(), but you pay dearly for passing-around those hash keys.
Fun for one-off stuff, but not recommended for heavy lifting.

  my %hash = parse_line_to_hash($line);

=cut

sub parse_line_to_hash {
  my @keys = @fields;
  return(map({shift(@keys) => $_} @{parse_line($_[0])}));
} # end subroutine parse_line_to_hash definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
