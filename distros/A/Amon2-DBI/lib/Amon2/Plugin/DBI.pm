use strict;
use warnings;
use utf8;

package Amon2::Plugin::DBI;
use Amon2::DBI;

sub init {
    my ($class, $context_class, $config) = @_;

    no strict 'refs';
    *{"$context_class\::dbh"} = \&_dbh;
}

sub _dbh {
    my ($self) = @_;

    if ( !defined $self->{dbh} ) {
        my $conf = $self->config->{'DBI'}
            or die "missing configuration for 'DBI'";
        $self->{dbh} = Amon2::DBI->connect(@$conf);
    }
    return $self->{dbh};
}

1;

