package Load::Trace;

# Tracy loads for modules.
# usage: use Load::Trace { port => \@loaded_module_accumulator,
#                          filter => [qw/Modules To::Ignore] };

use strict;

sub import {
    (undef, my $spec) = @_;
    die "Load::Trace requires an output port" unless $spec->{port};
    my %filter = map { $_ => 1 } @{ $spec->{filter} || [] };
    use Carp;
    unshift @INC, sub {
        (undef, my $file) = @_;
        normalize($file);

        push @{ $spec->{port} }, $file
            unless $filter{$file};
        return;
    };
}

# Foo/Bar.pm -> Foo::Bar
sub normalize {
    $_[0] =~ s/\.pm$// or die "not a relative filename: $_[0]";
    $_[0] =~ s,[/\\:],::,g;
}

"fnord";
