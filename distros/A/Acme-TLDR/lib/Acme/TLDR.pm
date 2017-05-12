package Acme::TLDR;
# ABSTRACT: Abbreviate Perl namespaces for the Extreme Perl Golf


use strict;
use utf8;
use warnings qw(all);

use Digest::MD5 qw(md5_hex);
use ExtUtils::Installed;
use File::HomeDir;
use File::Spec::Functions;
use Filter::Simple;
use List::MoreUtils qw(uniq);
use Module::CoreList;
use Storable;

our $VERSION = '0.004'; # VERSION


# hack; only absolute paths
BEGIN { @main::INC = grep { substr($_, 0, 1) eq substr($^X, 0, 1) } @INC }

FILTER_ONLY
    code => sub {
        my $installed = _installed();
        my $shortened = _shorten($installed);

        while (my ($long, $short) = each %{$shortened}) {
            s{\b\Q$short\E\b}{$long}gsx;
        }
    };

sub _debug {
    my ($fmt, @args) = @_;
    printf STDERR qq($fmt\n) => @args
        if exists $ENV{DEBUG};
    return;
}

sub _installed {
    my $cache = catfile(
        File::HomeDir->my_data,
        q(.Acme-TLDR-) . md5_hex(join ':' => sort @INC) . q(.cache)
    );
    _debug(q(ExtUtils::Installed cache: %s), $cache);

    my $updated = -M $cache;

    my $modules;
    if (
        not defined $updated
            or
        grep { -e and -M _ < $updated }
        map { catfile($_, q(perllocal.pod)) }
        @INC
    ) {
        ## no critic (ProhibitPackageVars)
        _debug(q(no cache found; generating));
        $modules = [
            uniq
                keys %{$Module::CoreList::version{$]}},
                ExtUtils::Installed->new->modules,
        ];
        store $modules => $cache
            unless exists $ENV{NOCACHE};
    } else {
        _debug(q(reading from cache));
        $modules = retrieve $cache;
    }

    return $modules;
}

sub _shorten {
    my ($modules) = @_;
    my %collisions = map { $_ => 1 } @{$modules};
    my %modules;

    for my $long (sort @{$modules}) {
        my @parts = split /\b|(?=[A-Z0-9])/x, $long;
        next unless $#parts;

        my $short = join q() => map { /^(\w)\w{3,}$/x ? $1 : $_ } @parts;
        next if $short eq $long;

        unless (exists $collisions{$short}) {
            ++$collisions{$short};
            $modules{$long} = $short;
            _debug(q(%-64s => %s), $long, $short);
        } else {
            _debug(q(%-64s => *undef*), $long);
        }
    }

    return \%modules;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::TLDR - Abbreviate Perl namespaces for the Extreme Perl Golf

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;

    use Acme::TLDR;
    use D::D;       # Data::Dump
    use D::MD5;     # Digest::MD5
    use DT;         # DateTime
    use HTTP::T;    # HTTP::Tiny

    print DT->now, "\n";

    my $ua = HTTP::T->new;
    my $res = $ua->get('http://ifconfig.me/all');
    dd $res;

    my $md5 = D::MD5->new;
    $md5->add($res->{content});
    print $md5->hexdigest, "\n";

=head1 DESCRIPTION

This module is heavily inspired on the
L<shortener module proposal|http://mail.pm.org/pipermail/rio-pm/2012q2/009177.html>
by L<Fernando Correa de Oliveira|https://metacpan.org/author/FCO>,
albeit it operates in a completely distinct way.

=head1 ENVIRONMENT VARIABLES

=over 4

=item *

C<DEBUG> - when set, dump the internals status (most importantly, the long <=> short name mapping;

=item *

C<NOCACHE> - when set, no persistent cache is saved.

=back

=head1 CAVEAT

To reduce loading time (C<ExtUtils::Installed-E<gt>new-E<gt>modules> is too damn slow), an installed module cache
is initialized upon L<Acme::TLDR> start.
It is updated when the F<perllocal.pod> file of the used Perl version gets a modified time more recent than the cache file itself.

=head1 SEE ALSO

=over 4

=item *

L<App::p>

=item *

L<L>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTOR

Sergey Romanov <sromanov-dev@yandex.ru>

=cut
