package inc::ModuleBuildXS;
use strict;
use warnings;
use feature 'state';

use Moose;
extends 'Dist::Zilla::Plugin::ModuleBuild';

around module_build_args => sub {
    my $orig = shift;
    my ($self, @args) = @_;
    my $mb_args = $orig->($self, @args);
    $mb_args->{c_source} = 'src';
    $mb_args->{config}{cxxflags} = '-std=c++11';
    $mb_args->{extra_linker_flags} = '-lstdc++';
    return $mb_args;
};

__PACKAGE__->meta->make_immutable;
1;

__END__
