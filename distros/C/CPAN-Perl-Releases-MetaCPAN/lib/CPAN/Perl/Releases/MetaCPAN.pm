package CPAN::Perl::Releases::MetaCPAN;
use strict;
use warnings;

our $VERSION = '0.006';
use JSON::PP ();
use HTTP::Tinyish;

use Exporter 'import';
our @EXPORT_OK = qw(perl_tarballs perl_versions perl_pumpkins);

sub new {
    my ($class, %option) = @_;
    my $uri = $option{uri} || "https://fastapi.metacpan.org/v1/release";
    $uri =~ s{/$}{};
    my $cache = exists $option{cache} ? $option{cache} : 1;
    my $http = HTTP::Tinyish->new(verify_SSL => 1, agent => __PACKAGE__ . "/$VERSION");
    my $json = JSON::PP->new->canonical(1);
    bless { uri => $uri, http => $http, cache => $cache, json => $json }, $class;
}

sub get {
    my $self = shift;
    return $self->{_releases} if $self->{cache} and $self->{_releases};

    my @release;
    my $from = 0;
    my $total;
    my $uri = "$self->{uri}/_search";
    for (1..5) {
        # https://github.com/metacpan/metacpan-web/blob/master/lib/MetaCPAN/Web/Model/API/Release.pm
        # https://github.com/metacpan/metacpan-api/blob/master/lib/MetaCPAN/Document/Release/Set.pm
        my $query = {
            query => {
                bool => {
                    must => [
                        { term => { distribution => "perl" } },
                        { term => { authorized => JSON::PP::true } },
                    ],
                },
            },
            size => 1000,
            from => $from,
            sort => [ { date => 'desc' } ],
            fields => [qw( name date author version status maturity download_url )],
        };
        my $res = $self->{http}->post($uri, {
            content => $self->{json}->encode($query),
            headers => { 'content-type' => 'application/json' },
        });
        if (!$res->{success}) {
            my $message = $res->{status} == 599 ? ", $res->{content}" : "";
            chomp $message;
            $message =~ s/\n/ /g;
            die "$res->{status} $res->{reason}, $uri$message\n";
        }
        my $hash = $self->{json}->decode($res->{content});
        $total = $hash->{hits}{total} unless defined $total;
        push @release, map { $_->{fields} } @{$hash->{hits}{hits}};
        last if $total <= @release;
        $from = @release;
    }
    if ($total != @release) {
        die sprintf "metacpan returns %d perl releases, but expected %d\n",
            (scalar @release), $total;
    }
    $self->{_releases} = \@release if $self->{cache};
    \@release;
}

sub _self {
    my $self = eval { $_[0]->isa(__PACKAGE__) } ? shift : __PACKAGE__->new;
    wantarray ? ($self, @_) : $self;
}

sub perl_tarballs {
    my ($self, $arg) = _self @_;
    my $releases = $self->get;
    my %tarballs =
        map {
            my $url = $_->{download_url};
            $url =~ s{.*authors/id/}{};
            if ($url =~ /\.(tar\.\S+)$/) {
                ($1, $url);
            } else {
                ();
            }
        }
        grep { my $name = $_->{name}; $name =~ s/^perl-?//; $name eq $arg }
        grep { $_->{status} =~ /^(?:cpan|latest)$/ }
        @$releases;
    \%tarballs;
}

sub perl_versions {
    my $self = _self @_;
    my $releases = $self->get;
    my @versions =
        map { my $name = $_->{name}; $name =~ s/^perl-?//; $name }
        grep { $_->{status} =~ /^(?:cpan|latest)$/ }
        @$releases;
    @versions;
}

sub perl_pumpkins {
    my $self = _self @_;
    my $releases = $self->get;
    my %author =
        map { $_->{author} => 1 }
        grep { $_->{status} =~ /^(?:cpan|latest)$/ }
        @$releases;
    sort keys %author;
}

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Perl::Releases::MetaCPAN - Mapping Perl releases on CPAN to the location of the tarballs via MetaCPAN API

=head1 SYNOPSIS

  use CPAN::Perl::Releases::MetaCPAN;

  # OO
  my $cpan = CPAN::Perl::Releases::MetaCPAN->new;
  my $releases = $cpan->get;

  # Functions
  use CPAN::Perl::Releases::MetaCPAN qw/perl_tarballs/;

  my $hash = perl_tarballs('5.14.0');
  # {
  #   'tar.bz2' => 'J/JE/JESSE/perl-5.14.0.tar.bz2'
  # }

=head1 DESCRIPTION

CPAN::Perl::Releases::MetaCPAN is just like L<CPAN::Perl::Releases>,
but it gets the release information via MetaCPAN API C<https://fastapi.metacpan.org/v1/release>.

=head1 SEE ALSO

L<CPAN::Perl::Releases>

L<metacpan-api|https://github.com/metacpan/metacpan-api>

L<metacpan-web|https://github.com/metacpan/metacpan-web>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
