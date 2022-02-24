# -*- perl -*-

use warnings;
use strict;
use Test::More 'no_plan';

use Config;
use File::Spec;
use lib qw( ../lib lib );
use B::Keywords ':all';

BEGIN {
  if (defined &Test::More::note) {
    *diag = *Test::More::note;
  }
}

# Translate control characters into ^A format
# Leave others alone.
my @control_map = (undef, "A".."Z");
sub _map_control_char {
    my $char = shift;
    my $ord = ord $char;

    return "^".$control_map[$ord] if $ord <= 26;
    return $char;
}

sub kopen {
    my @files = ();

    # this is the default location for 'kewords.h', unless we're on macOS
    push @files, File::Spec->catfile( $Config{archlibexp}, 'CORE', 'keywords.h' );

    # Apple has restructured it's file system, if we're on macOS and the above
    # doesn't exist, we're probably using system perl. try an alternate location
    # via Apple's tools
    if ($^O eq "darwin" && $Config{archlibexp} =~ m!^/System/Library/Perl!) {
	my $p = '';
	$p = qx/xcrun --show-sdk-path/;
	chomp $p;
	push @files, File::Spec->catdir($p, $files[0]);
    }

    # return the first FH we can open from the list above. 99.44% of
    # the time it's going to be the first (and correct) one
    for my $file (@files) {
	if (open my $fh, "<", $file) {
	    return $fh;
	}
    }

    # if we're here something else happend or apple is up to new tricks
    die "Can't open any of @files";
}

# Test everything in keywords.h is covered.
{
    # get a filehandle to 'keywords.h'
    my $fh = kopen();
    local $/;
    chomp( my @keywords = <$fh> =~ /^\#define \s+ KEY_(\S+) /xmsg );
    close $fh;
    my $usedevel = $Config{usedevel};

    my %covered = map { $_ => 1 } @Symbols, @Barewords;
    diag "check if all keywords.h have \@Symbols or \@Barewords";
  TODO: {
      for my $keyword (@keywords) {
          local $TODO = "old blead version, wait for the release" if $Config{usedevel} && !$covered{$keyword};
          ok $covered{$keyword}, "keyword: $keyword";
      }
    }

    diag "reverse: check if all \@Symbols and \@Barewords are in keywords.h";
    my %keyword = map { $_ => 1 } @keywords;
  TODO: {
      for my $key (@Barewords, @Functions) {
        if ($key =~ /^-/ or $key eq 'err') { # skip file test ops, err fails my tests
            diag "not in keywords.h: $key. skipped";
        } else {
            local $TODO = "old blead version, wait for the release" if $Config{usedevel} && !$keyword{$key};
            ok $keyword{$key}, "keywords.h: $key";
        }
      }
    }
}

# Test all the single character globals in main
{
    my @globals = map  { _map_control_char($_) }
                  grep { length $_ == 1 and /\W/ }
                       keys %main::;

    my %symbols = map { s/^.//; $_ => 1 } (@Scalars, @Arrays, @Hashes);
    diag "check if all single-character \@Scalars, \@Arrays, \@Hashes are as globals in \%main::";
    for my $global (@globals) {
        ok $symbols{$global}, "global: $global";
    }

    #my %globals = map { $_ => 1 } @globals;
    diag "the reverse is not true as most globals are auto-created";
    #for my $sym (grep { length $_ == 1 } keys %symbols) {
    #   ok $globals{$sym}, "\%main:: $sym";
    #}
}

# Cannot test all the other globals in main. They are mostly created on-the-fly.
if (0) {
    my %globals = map  { _map_control_char($_) => 1 }
                  grep { length $_ > 1 && $_ !~ /^_</ && $_ !~ /::$/ }
                       keys %main::;

    require English;
    English->import;
    diag "check if all multi-character \@Scalars, \@Arrays, \@Hashes are as globals in \%main::";
    my %symbols = map { s/^[\$\%\@]//; $_ => 1 } (@Scalars, @Arrays, @Hashes);
    for my $sym (grep { length $_ > 1 } keys %symbols) {
        ok $globals{$sym}, "\%main:: $sym";
    }
    # and the reverse is troubled by namespace pollution. %main:: contains B, Test, ...
}
