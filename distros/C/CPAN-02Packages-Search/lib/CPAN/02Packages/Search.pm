package CPAN::02Packages::Search;
use strict;
use warnings;

use IO::Handle;
use Search::Dict ();
use Tie::Handle::SkipHeader;

our $VERSION = '0.001';

sub new {
    my ($class, %argv) = @_;
    my $file = $argv{file};
    my $skip_header = exists $argv{skip_header} ? $argv{skip_header} : 1;
    my $self = bless { file => $file, skip_header => $skip_header }, $class;
    $self->_fh;
    $self;
}

sub _fh {
    my $self = shift;
    return $self->{fh} if defined $self->{pid} && $self->{pid} == $$;
    my $file = $self->{file};
    if ($self->{skip_header}) {
        my $fh = IO::Handle->new;
        tie *$fh, 'Tie::Handle::SkipHeader', '<', $file or die "$!: $file\n";
        $self->{fh} = $fh;
    } else {
        open my $fh, "<", $file or die "$!: $file\n";
        $self->{fh} = $fh;
    }
    $self->{pid} = $$;
    $self->{fh};
}

sub search {
    my ($self, $package) = @_;
    my $fh = $self->_fh;
    seek $fh, 0, 0;
    my $pos = Search::Dict::look $fh, $package, { xfrm => \&_xform_package, fold => 1 };
    return if $pos == -1 || eof $fh;
    while (my $line = <$fh>) {
        last if $line !~ /\A\Q$package\E\s+/i;
        chomp $line;
        my ($_package, $version, $path) = split /\s+/, $line, 4;
        if ($package eq $_package) {
            $version = undef if $version eq 'undef';
            return { version => $version, path => $path };
        }
    }
    return;
}

sub _xform_package { (split " ", $_[0], 2)[0] }

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::02Packages::Search - Search packages in 02packages.details.txt

=head1 SYNOPSIS

  use CPAN::02Packages::Search;

  my $index = CPAN::02Packages::Search->new(file => '/path/to/02packages.details.txt');

  my $result1 = $index->search('Plack'); # { version => "1.0048", path => "M/MI/MIYAGAWA/Plack-1.0048.tar.gz" }
  my $result2 = $index->search('Does_Not_Exist'); # undef

=head1 DESCRIPTION

CPAN::02Packages::Search allows you to search packages in the de facto standard CPAN index file C<02packages.details.txt>.

=head1 MOTIVATION

We can already search packages in C<02packages.details.txt> by the excellent module L<CPAN::Common::Index::Mirror>.
Its functionality is not only searching packages, but also searching authors and even fetching/caching index files.

As an author of CPAN clients, I just want to search packages in C<02packages.details.txt>.
So I ended up extracting functionality of searching packages from CPAN::Common::Index::Mirror as CPAN::02Packages::Search.

=head1 PERFORMANCE

CPAN::Common::Index::Mirror and CPAN::02Packages::Search use L<Search::Dict>, which implements binary search.
A simple benchmark shows that CPAN::02Packages::Search is 422 times faster than I<naive> search.

  ❯ perl bench/bench.pl
                 Rate naive_search   our_search
  naive_search 4.13/s           --        -100%
  our_search   1752/s       42291%           --

See L<bench/bench.pl|https://github.com/skaji/CPAN-02Packages-Search/blob/main/bench/bench.pl> for details.

=head1 SEE ALSO

L<CPAN::Common::Index::Mirror>

L<Search::Dict>

L<https://www.cpan.org/modules/04pause.html>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
