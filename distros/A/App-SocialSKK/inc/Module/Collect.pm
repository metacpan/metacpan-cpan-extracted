#line 1
package Module::Collect;
use strict;
use warnings;
our $VERSION = '0.05';

use Carp;
use File::Find::Rule;
use Module::Collect::Package;

sub new {
    my($class, %args) = @_;

    $args{modules}  = [];
    $args{pattern} = '*.pm' unless $args{pattern};

    my $self = bless { %args }, $class;
    $self->_find_modules;

    $self;
}

sub _find_modules {
    my $self = shift;

    my $path = $self->{path} || [];
       $path = [ $path ] unless ref($path) eq 'ARRAY';

    for my $dirpath (@{ $path }) {
        next unless -d $dirpath;

        my $rule = File::Find::Rule->new;
        $rule->file;
        $rule->name($self->{pattern});

        my @modules = $rule->in($dirpath);
        for my $modulefile (@modules) {
            $self->_add_module($modulefile);
        }
    }
}

sub _add_module {
    my($self, $modulefile) = @_;
    my @packages = $self->_extract_package($modulefile);
    return unless @packages;
    for (@packages) {
        push @{ $self->{modules} }, Module::Collect::Package->new(
            package => $_,
            path    => $modulefile,
        );
    }
}

sub _extract_package {
    my($self, $modulefile) = @_;

    open my $fh, '<', $modulefile or croak "$modulefile: $!";
    my $prefix = $self->{prefix};
    $prefix .= '::' if $prefix;
    $prefix = '' unless $prefix;

    return _extract_multiple_package($fh, $prefix) if $self->{multiple};
    my $in_pod = 0;
    while (<$fh>) {
        $in_pod = 1 if m/^=\w/;
        $in_pod = 0 if /^=cut/;
        next if ($in_pod || /^=cut/);  # skip pod text
        next if /^\s*\#/;

        /^\s*package\s+($prefix.*?)\s*;/ and return $1;
    }
    return;
}

sub _extract_multiple_package {
    my($fh, $prefix) = @_;

    my $in_pod = 0;
    my @packages;
    while (<$fh>) {
        $in_pod = 1 if m/^=\w/;
        $in_pod = 0 if /^=cut/;
        next if ($in_pod || /^=cut/);  # skip pod text
        next if /^\s*\#/;

        /^\s*package\s+($prefix.*?)\s*;/ and push @packages, $1;
    }
    return @packages;
}

sub modules {
    my $self = shift;
    $self->{modules};
}

1;
__END__

=encoding utf8

#line 178
