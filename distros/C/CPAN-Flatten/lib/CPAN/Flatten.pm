package CPAN::Flatten;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use CPAN::Flatten::Distribution::Factory;
use CPAN::Flatten::Distribution;
use Module::CoreList;
use version;

sub new {
    my ($class, %opt) = @_;
    my $target_perl = delete $opt{target_perl} || $];
    $target_perl = "v$target_perl" if $target_perl =~ /^5\.[1-9]\d*$/;
    $target_perl = version->parse($target_perl)->numify;
    bless {target_perl => $target_perl, %opt}, $class;
}
sub target_perl { shift->{target_perl} }

sub is_core {
    my ($self, $package, $version) = @_;
    $version ||= 0;
    if ($package eq "perl") {
        if ($version > $self->target_perl) {
            my $err = "target perl version is only @{[$self->target_perl]}";
            return (undef, $err);
        } else {
            return (1, undef);
        }
    }
    if (exists $Module::CoreList::version{$self->target_perl}{$package}) {
        return (1, undef);
    } else {
        return (0, undef);
    }
}

sub info_progress {
    my ($self, $depth) = (shift, shift);
    return if $self->{quiet};
    print STDERR "  " x $depth, "@_";
}
sub info_done {
    my $self = shift;
    return if $self->{quiet};
    print STDERR " -> @_\n";
}

sub flatten {
    my ($self, $package, $version) = @_;
    my $distribution = CPAN::Flatten::Distribution->new;
    my $miss = +{};
    $self->_flatten($distribution, $miss, $package, $version);
    my @miss = sort keys %$miss;
    return ($distribution, @miss ? \@miss : undef);
}

sub _flatten {
    my ($self, $distribution, $miss, $package, $version) = @_;
    return 0 if $miss->{$package};
    $version ||= 0;
    my $already = $distribution->root->providing($package, $version);
    if ($already) {
        return 0 if $distribution->is_child($already);
        $distribution->add_child( $already->dummy );
        return 1;
    }

    my ($is_core, $err) = $self->is_core($package, $version);
    if (!defined $is_core) {
        $miss->{$package}++;
        $self->info_progress($distribution->depth, "$package ($version)");
        $self->info_done("\e[31m$err\e[m");
        return 0;
    } elsif ($is_core) {
        if ($self->{verbose}) {
            $self->info_progress($distribution->depth, "$package ($version)");
            $self->info_done("core");
        }
        return 0;
    }

    $self->info_progress($distribution->depth, "$package ($version)");
    my ($found, $reason) = CPAN::Flatten::Distribution::Factory->from_pacakge($package, $version);
    if (!$found) {
        $miss->{$package}++;
        $self->info_done("\e[31m$reason\e[m");
        return 0;
    }
    $self->info_done("@{[$found->name]}");
    $distribution->add_child($found);
    my $count = 0;
    for my $requirement (@{$found->requirements}) {
        $count += $self->_flatten($found, $miss, $requirement->{package}, $requirement->{version});
    }
    return $count; # count == 0 means leaf
}

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Flatten - flatten cpan module requirements without install

=head1 SYNOPSIS

  $ flatten --target-perl 5.10.1 --verbose Mojolicious
  Mojolicious (0) -> SRI/Mojolicious-6.66
    ExtUtils::MakeMaker (0) -> core
    ExtUtils::MakeMaker (0) -> core
    IO::Socket::IP (0.37) -> PEVANS/IO-Socket-IP-0.37
      Test::More (0.88) -> core
      IO::Socket (0) -> core
      Socket (1.97) -> core
    JSON::PP (2.27103) -> MAKAMAKA/JSON-PP-2.27400
      ExtUtils::MakeMaker (0) -> core
      ExtUtils::MakeMaker (0) -> core
      Test::More (0) -> core
    Pod::Simple (3.09) -> core
    Time::Local (1.2) -> core
    perl (5.010001) -> core

  S/SR/SRI/Mojolicious-6.66.tar.gz
    P/PE/PEVANS/IO-Socket-IP-0.37.tar.gz
    M/MA/MAKAMAKA/JSON-PP-2.27400.tar.gz
  P/PE/PEVANS/IO-Socket-IP-0.37.tar.gz
  M/MA/MAKAMAKA/JSON-PP-2.27400.tar.gz

=head1 DESCRIPTION

This is experimental.

CPAN::Flatten flattens cpan module requirements without install.

As you know, the cpan world allows cpan modules to configure themselves dynamically.
So the actual requirements can not be determined
unless you install them to your local machines.

But, I think dynamic configuration is generally harmful,
and we should avoid that.

So what happens if we flattens cpan module requirements without install?

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
