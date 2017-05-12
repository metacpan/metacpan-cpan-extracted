package # hide from PAUSE
  TestCSL::search;
use strict;
use warnings;
use CPAN::Search::Lite::Query;

my ($db, $user, $passwd) = ('test', 'test', '');
my $query;

sub search {
    my ($self, %args) = @_;
    my $mode = $args{mode};
    my $query_term = trim($args{query});
    return unless (defined $mode and defined $query_term);

    $query ||= CPAN::Search::Lite::Query->new(db => $db,
                                              user => $user,
                                              passwd => $passwd,
                                              max_results => 100);
    $query->query(mode => $mode, query => $query_term, want_array => 1);
    return $query->{results};
}

sub trim {
    my $string = shift;
    return '' unless defined $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\s+/ /g;
    $string =~ s/\"|\'|\\//g;
    return ($string =~ /\w/) ? $string : undef;
}
1;
