use strict;
use Test::More;
use CPAN::Dependency;


my @options = qw(clean_build_dir color debug prefer_bin verbose);

plan tests => 4 + @options;

my $cpandep = eval { CPAN::Dependency->new(
    verbose => 1, color => 1, debug => 1, prefer_bin => 1, clean_build_dir => 1
) };

is( $@, ''                                  , "object created (with boolean options set to 1)" );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

for my $option (@options) {
    is( $cpandep->{options}{$option}, 1     , "  checking true value"        );
}
