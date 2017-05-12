package DBomb::Test::Util;

=head1 NAME

DBomb::Test::Util - THIS PACKAGE SHOULD NOT BE INSTALLED.

=head1 DESCRIPTION

This is a helper package for the "make test" part of the DBomb::* distribution.
It should not be installed. If it is installed, then report it as a bug, please.

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.3 $';

use base qw(Exporter);

our %EXPORT_TAGS = ( all => [qw{same_results same_list count_table truncate_table drop_table}] );
Exporter::export_ok_tags('all');

## Be sure to set the DBH from outside this package.
our $dbh;

## Compares two sql statemtns, or two query objects or a query object and sql statement
sub same_results {
    my $dbh = shift;
    my @sql     = map { UNIVERSAL::isa($_,'DBomb::Query')? scalar($_->sql) : $_->[0] } @_;
    my $msg = "SQL: " . $sql[0]
            . "\nSAME: " . $sql[1];

    eval {
        my @results;
        for (@_){
            if (UNIVERSAL::isa($_,'DBomb::Query')){
                push @results, $_->selectall_arrayref;
            }
            else{
                my($sql,@bind_values) = @$_;
                my $sth = $dbh->prepare($sql) or die $DBI::errstr;
                $sth->execute(@bind_values) or die $DBI::errstr;
                push @results, $sth->fetchall_arrayref;
            }
        }
        die "Results are not the same."  unless same_list(@results);
    };
    if ($@){
        print STDERR "$msg\n$@" if $@;
        return 0;
    }

    return 1;
}

## compares two lists for identical values.
sub same_list {
    my($a,$b) = @_;
    return 0 unless defined($a) && defined($b);
    return 0 unless ref($a) eq 'ARRAY';
    return 0 unless ref($b) eq 'ARRAY';
    return 0 unless @$a == @$b;

    for my $i (0..$#$a){
        my($x,$y) = ($a->[$i], $b->[$i]);
        next if ((not defined $x) && (not defined $y));
        if(ref($x) eq 'ARRAY' && ref($y) eq 'ARRAY'){
            return 0 unless same_list($x,$y);
            next;
        }
        return 0 unless $a->[$i] eq $b->[$i];
    }
    return 1;
}

sub count_table
{
    $dbh->selectcol_arrayref("SELECT COUNT(*) FROM $_[0]")->[0]
}


sub truncate_table
{
    $dbh->do("DELETE FROM $_[0]");
}

sub drop_table
{
    local $dbh->{RaiseError};
    local $dbh->{PrintError};
    $dbh->do("DROP TABLE $_[0]")
}

1;
__END__

