#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok('AnyEvent::Net::Curl::Queued');
}

diag("AnyEvent::Net::Curl::Queued v$AnyEvent::Net::Curl::Queued::VERSION");
diag("Net::Curl v$Net::Curl::VERSION");
diag("AnyEvent v$AnyEvent::VERSION (" .  AnyEvent::detect . ')');
diag("Perl $] ($^X)");

# shamelessly borrowed from Net::Curl t/00-info.t
diag "Net::Curl::version():\n\t" . Net::Curl::version() . "\n";
my $vi = Net::Curl::version_info();

diag "Net::Curl::version_info():\n";
foreach my $key (sort keys %$vi) {
    my $value = $vi->{$key};
    if ($key eq 'features') {
        print_features($value);
        next;
    } elsif (ref $value and ref $value eq 'ARRAY') {
        $value = join ', ', sort @$value;
    } elsif ($value =~ m/^\d+$/x) {
        $value = sprintf "0x%06x", $value
            if $value > 255;
    } else {
        $value = "'$value'";
    }
    diag "\t{$key} = $value;\n";
}

sub print_features {
    my $features = shift;
    my @found = ('');
    my @missing = ('');
    foreach my $f (
        sort { Net::Curl->$a() <=> Net::Curl->$b() }
        grep { /^CURL_VERSION_/x } keys %{Net::Curl::}
      )
    {
        my $val = Net::Curl->$f();
        my $bit = log($val) / log 2;
        if ($features & $val) {
            push @found, "$f (1<<$bit)";
        } else {
            push @missing, "$f (1<<$bit)";
        }
    }

    local $" = "\n\t\t| ";
    diag "\t{features} = @found;\n";
    diag "\tmissing features = @missing;\n";

    return;
}
