package CPAN::Releases::Latest::Source::MetaCPAN;
$CPAN::Releases::Latest::Source::MetaCPAN::VERSION = '0.08';
use 5.006;
use Moo;
use MetaCPAN::Client 2.006000;
use CPAN::DistnameInfo;
use Carp;

has client => (
                is      => 'ro',
                default => sub { MetaCPAN::Client->new },
              );

sub get_release_info
{
    my $self       = shift;
    my $client     = MetaCPAN::Client->new();
    my $query      = {
                        either => [
                                      { all => [
                                          { status   => 'latest'    },
                                          { maturity => 'released'  },
                                      ]},

                                      { all => [
                                          { status   => 'cpan'      },
                                          { maturity => 'developer' },
                                      ]},
                                   ]
                     };
    my $params     = {
                         _source => [qw(name version date status maturity stat download_url)]
                     };
    my $result_set = $client->release($query, $params);
    my $distdata   = {
                         released  => {},
                         developer => {},
                     };

    while (my $release = $result_set->next) {
        my $maturity = $release->maturity;
        my $slice    = $distdata->{$maturity};
        my $path     = $release->download_url;
        next unless defined $path;
           $path     =~ s!^.*/authors/id/!!;
        my $distinfo = CPAN::DistnameInfo->new($path);
        my $distname = defined($distinfo) && defined($distinfo->dist)
                       ? $distinfo->dist
                       : $release->name;

        next unless !exists($slice->{ $distname })
                 || $release->stat->{mtime} > $slice->{$distname}->{time};
        $slice->{ $distname } = {
                                    path => $path,
                                    time => $release->stat->{mtime},
                                    size => $release->stat->{size},
                                };
    }

    return $distdata;
}


1;

=head1 NAME

CPAN::Releases::Latest::Source::MetaCPAN - get latest release info from MetaCPAN

=head1 SYNOPSIS

 use CPAN::Releases::Latest::Source::MetaCPAN;
 
 my $source       = CPAN::Releases::Latest::Source::MetaCPAN->new();
 my $release_info = $source->get_release_info();
 
=head1 DESCRIPTION

This is the default plugin used by L<CPAN::Releases::Latest> to
build up information about the latest release of dists currently
on CPAN.

See the documentation for L<CPAN::Releases::Latest> on the details
of the interface, and the source of this module for what it does.

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-Releases-Latest>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

