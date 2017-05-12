#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use Test::Differences;
use App::perlfind;
my %expect = (

    # The first element of the value is what the query gets rewritten as.
    'xor'                    => [ 'xor'                     => qw(perlop) ],
    'foreach'                => [ 'foreach'                 => qw(perlsyn) ],
    'isa'                    => [ 'isa'                     => qw(perlobj) ],
    'TIEARRAY'               => [ 'TIEARRAY'                => qw(perltie) ],
    'AUTOLOAD'               => [ 'AUTOLOAD'                => qw(perlsub) ],
    'INPUT_RECORD_SEPARATOR' => [ '$INPUT_RECORD_SEPARATOR' => qw(perlvar) ],
    '$RS'                    => [ '$RS'                     => qw(perlvar) ],
    '$/'                     => [ '$/'                      => qw(perlvar) ],
    '$^F'                    => [ '$^F'                     => qw(perlvar) ],
    'PERL5OPT'               => [ 'PERL5OPT'                => qw(perlrun) ],
    ':mmap'                  => [ ':mmap'                   => qw(PerlIO) ],
    '__WARN__'               => [ '%SIG'                    => qw(perlvar) ],
    '__PACKAGE__'                 => [ '__PACKAGE__'   => qw(perlfunc perlop) ],
    'head4'                       => [ 'head4'         => qw(perlpod) ],
    '=head4'                      => [ '=head4'        => qw(perlpod) ],
    'App::perlfind'               => [ 'App::perlfind' => qw(App::perlfind) ],
    'App::perlfind::find_matches' => [ 'App::perlfind' => qw(App::perlfind) ],
    'App::perlfind::Plugin' =>
      [ 'App::perlfind::Plugin' => qw(App::perlfind::Plugin) ],
    'splice' => [ 'splice' => qw(perlfunc perlop) ],
    'y'      => [ 'y'      => qw(perlfunc perlop) ],
    '-X'     => [ '-X'     => qw(perlfunc perlop) ],
    '-w'     => [ '-X'     => qw(perlfunc perlop) ],
    '_'      => [ '$_'     => qw(perlvar) ],
    'lib/App/perlfind.pm' => [ 'lib/App/perlfind.pm' ],
);
# Version-specific mapping hack
$expect{'__PACKAGE__'} = [ '__PACKAGE__', qw(perldata) ]
  if $] =~ /^5\.0(08|10|12|14)/;

for my $query (sort keys %expect) {
    test_find_matches($query, $expect{$query});
}
done_testing;

sub test_find_matches {
    my ($query,          $expect)         = @_;
    my ($word,           @pages)          = App::perlfind::find_matches($query);
    my ($expected_query, @expected_pages) = @$expect;
    is($word, $expected_query, "find_matches($query) searches for [$word]...");
    my $test_name = @expected_pages ? "in @expected_pages" : 'without finding pages';
    eq_or_diff(\@pages, \@expected_pages, "... $test_name");
}
