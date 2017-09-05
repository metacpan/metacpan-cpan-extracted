use strict;
use warnings;

use Module::Metadata;

sub MY::dist_basics {
    my ($self) = shift;

    my $manifest_frag = '$(PERLRUN) ./maint/mkmanifest';

    my $rval = ExtUtils::MM_Unix::dist_basics($self);
    $rval =~ s{^.*mkmanifest.*$}{\t$manifest_frag}m;

    return $rval;
}

$main::MM_Args{test}{TESTS} .= " xt/*.t";
$main::MM_Args{META_ADD}{provides} =
  Module::Metadata->provides( dir => 'lib', version => 2 );

1;
