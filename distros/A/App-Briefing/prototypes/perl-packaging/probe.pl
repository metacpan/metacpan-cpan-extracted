#!/usr/bin/env perl
# THROWAWAY packaging prototype. Not a real harness hook, module, or distribution.
use strict;
use warnings;
use Config ();
use JSON::PP ();
use Path::Tiny qw( path );

binmode STDIN, ':raw';
binmode STDOUT, ':raw';

sub _emit {
  my ( $value ) = @_;
  print JSON::PP->new->utf8->canonical->convert_blessed->encode($value)."\n";
  exit 0;
}

sub _error {
  my ( $code, $name ) = @_;
  _emit({
    ok    => JSON::PP->false,
    error => { code => $code, defined $name ? ( name => $name ) : () },
  });
}

if (@ARGV) {
  _error('invalid_request') unless @ARGV == 1 && $ARGV[0] eq '--version';
  _emit({
    prototype_only => JSON::PP->true,
    protocol       => 'perl-packaging-probe-v1',
    perl_version   => ''.$^V,
    perl_arch      => $Config::Config{archname},
    os             => $^O,
  });
}

my $raw = do { local $/; <STDIN> };
my $request = eval { JSON::PP->new->utf8->decode($raw) };
_error('invalid_json') if $@;
_error('invalid_request') unless ref $request eq 'HASH' && ref $request->{skills} eq 'ARRAY';

my @skills;
for my $skill (@{$request->{skills}}) {
  _error('invalid_request') unless ref $skill eq 'HASH'
    && defined $skill->{name} && !ref $skill->{name}
    && defined $skill->{path} && !ref $skill->{path}
    && length $skill->{path} && index($skill->{path}, "\0") == -1;
  _error('missing_skill', $skill->{name}) unless -f $skill->{path};
  my $body = eval { path($skill->{path})->slurp_utf8 };
  _error('unreadable_skill', $skill->{name}) if $@;
  push @skills, { name => $skill->{name}, body => $body };
}

# Emit only after ALL successful reads; errors contain no skill content.
_emit({ ok => JSON::PP->true, skills => \@skills });
