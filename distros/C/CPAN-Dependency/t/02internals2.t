use strict;
use Test::More;
use CPAN::Dependency;


my @options = qw(clean_build_dir color debug prefer_bin verbose);

plan tests => 4 + @options;

my $cpandep = eval { CPAN::Dependency->new(
    verbose => 0, color => 0, debug => 0, prefer_bin => 0, clean_build_dir => 0
) };

is( $@, ''                                  , "object created (with boolean options set to 0)" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

for my $option (@options) {
    is( $cpandep->{options}{$option}, 0     , "  checking true value"        );
}
