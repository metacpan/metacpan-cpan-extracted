package App::DBI::Loader;

use strict;
use warnings;

# ABSTRACT: A tiny script to load CSV/TSV contents into a database table via DBI
our $VERSION = 'v0.0.2'; # VERSION

use Getopt::Std;
use Getopt::Config::FromPod;
use Pod::Usage;

use DBI;
use String::Unescape;

sub run
{
    shift if @_ && eval { $_[0]->isa(__PACKAGE__) };
    local (@ARGV) = @_;

    my %opts;
    getopts(Getopt::Config::FromPod->string, \%opts);
    pod2usage(-verbose => 2) if exists $opts{h};
    pod2usage(-msg => 'At least 2 arguments MUST be specified', -verbose => 0, -exitval => 1) if @ARGV < 2;
    push @ARGV, '-' if @ARGV == 2;

    $opts{t} ||= '';
    my $sep = String::Unescape->unescape($opts{t}) || ',';

    my $dbstr = shift @ARGV;
    my $table = shift @ARGV;

    my $dbh = DBI->connect($dbstr, $opts{u} || '', $opts{p} || '') or die;
    my $has_transaction = 1;
    eval { $dbh->{AutoCommit} = 0 };
    $has_transaction = 0 if $@;
    if($ARGV[0] =~ /\(.*\)/) {
        my $schema = shift @ARGV;
        $dbh->do("DROP TABLE IF EXISTS $table");
        $dbh->do("CREATE TABLE $table $schema");
    }
    if(exists $opts{c}) {
        $dbh->do("DELETE FROM $table");
    }
    my $sth;

    while(my $file = shift @ARGV) {
        my $fh;
        if($file eq '-') {
            $fh = \*STDIN;
        } else {
            open $fh, '<', $file or die;
        }
        while(<$fh>) {
            s/[\r\n]+$//;
            my (@t) = $sep ? split /$sep/ : $_;
            $sth ||= $dbh->prepare('INSERT INTO '.$table.' VALUES ('.join(',', ('?')x @t).')');
            $sth->execute(@t);
        }
        close $fh;
    }
    $dbh->commit if $has_transaction;
}

1;

__END__

=pod

=head1 NAME

App::DBI::Loader - A tiny script to load CSV/TSV contents into a database table via DBI

=head1 VERSION

version v0.0.2

=head1 SYNOPSIS

  App::DBI::Loader->run(@ARGV);

=head1 DESCRIPTION

This is an implementation module for a tiny script to load CSV/TSV contents into a database table via DBI.

=head1 METHODS

=head2 C<run(@arg)>

Process arguments. Typically, C<@ARGV> is passed. For details, see L<dbiloader>.

=over 4

=item *

L<dbiloader>

=back

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
