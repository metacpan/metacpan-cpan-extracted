package CHI::Driver::MemcachedFast::Util;
use Data::Dumper;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(
  dp
  require_dynamic
);

sub _dump_value_with_caller {
    my ($value) = @_;

    my $dump =
      Data::Dumper->new( [$value] )->Indent(1)->Sortkeys(1)->Quotekeys(0)
      ->Terse(1)->Dump();
    my @caller = caller(1);
    return sprintf( "[dp at %s line %d.] [%d] %s\n",
        $caller[1], $caller[2], $$, $dump );
}

sub dp {
    print STDERR _dump_value_with_caller(@_);
}

sub require_dynamic {
    my ($class) = @_;

    eval "require $class";    ## no critic (ProhibitStringyEval)
    croak $@ if $@;
}

1;
