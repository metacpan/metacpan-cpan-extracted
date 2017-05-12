use Test::More tests => 14;
BEGIN {
   use lib '/projects/cgipager/perl_lib';
   use_ok('CGI::Pager')
};


sub get_test_pager {
   return CGI::Pager->new(
      url              => "test.html?offset=$_[0]",
      page_len         => $_[1],
      total_count      => $_[2],
   );
}


my $pager = get_test_pager(0, 10, 35);
ok($pager->is_at_start);
ok(!$pager->is_at_end);
ok(!$pager->prev_offset);
is($pager->next_offset, 10);
is(@{ $pager->pages }, 4);

$pager = get_test_pager(20, 10, 35);
ok(!$pager->is_at_start);
ok(!$pager->is_at_end);
is($pager->prev_offset, 10);
is($pager->next_offset, 30);

$pager = get_test_pager(30, 10, 35);
ok(!$pager->is_at_start);
ok($pager->is_at_end);
is($pager->prev_offset, 20);
is($pager->next_offset, undef);
