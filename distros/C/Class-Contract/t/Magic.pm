package Magic;
#use strict;
use Exporter;
use vars qw( @ISA @EXPORT );
@ISA    = qw( Exporter );
@EXPORT = qw( ok );

sub debug { $::D || 0 }

sub import {
  printf("1..%d\n", count($_[0]));
  Magic->export_to_level(1,@_);
}

sub count {
  my $package = shift;
  local $/ = undef;
  open(SCRIPT, $0);
  my $code = <SCRIPT>;
  $code =~ s/\n__(DATA|END)__\n.*//s;
  $code =~ s/\n\n=pod\n\n.*?(\n\n=cut\n\n|$)//gs;
  my (@count) = $code =~ /::ok/gs;
  return (1 + scalar @count);
}

my $count = 2;
my %history;

sub ok(%) {
  my %p = (@_); # code, expect, desc, version, need
  my $ok = 0;
  exists $p{'code'} or die "->ok(code => \\&) required!";
  $p{'desc'} ||= '';

  return printf("# skip %-2s %s (\$VERSION < %s)\n",
		$count++, $p{'desc'}, $p{'version'})
    if (exists $p{'version'} and $Class::Contract::VERSION < $p{'version'});

  return printf("# skip %-2s %s\n          (duplicate test description)\n",
		$count++, $p{'desc'})
    if exists $history{$p{'desc'}};

  if (exists $p{'need'}) {
    $p{'need'} = [$p{'need'}]  unless (ref($p{'need'}) eq 'ARRAY');
    foreach my $test (@{$p{'need'}}) {
      return printf("# skip %-2s (test requires: '%s')\n", $count++, $test)
        unless $history{$test};
    }
  }

  undef $@;
  my $val = eval qq{$p{'code'}};
  $@ and $val = $@;

  if (exists $p{'expect'}) {
    if (ref($p{'expect'}) eq 'Regexp') {
      $ok = $val =~ /$p{'expect'}/;
      print "\t$count regex match on [$val]\n"  if debug;
    } elsif ($@) {
      $ok = 0;
      print STDERR "\tunexpected exception:\n$@\n";#  if debug;
    } else { # Is it a number or a string
      $ok = ($p{'expect'} =~ /^([+-]?)(?=\d|\.d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/)
          ? ($val == $p{'expect'})
          : ($val eq $p{'expect'});
      print "\texpected=[$p{'expect'}]\n\tvalue=[$val]\n"  if debug;
    }
  } else {
    $ok = $val ? 1 : 0
  }

  $history{$p{'desc'}} = $ok;

  print 'not '  unless $ok;
  printf("ok %-6s %s\n", $count, $p{'desc'});
  $count++;
  return $ok
}

1;
__END__
