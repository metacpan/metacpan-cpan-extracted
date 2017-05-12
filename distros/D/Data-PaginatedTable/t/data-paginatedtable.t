use Modern::Perl;
use Test::More;
use Data::PaginatedTable;

my @series = 1 .. 12;
my $dt = Data::PaginatedTable->new( { data => \@series } );

ok $dt->page_count == 1, '1 page';

$dt->rows(2);
$dt->columns(3);

ok $dt->page_count == 2, '2 pages';
ok $dt->current == 1,    'First page';
ok "$dt" eq "123456", 'Stringifies raw horiztonal';

$dt->fill_direction('vertical');
ok "$dt" eq "135246", 'Stringifies raw vertical';

$dt->string_mode('preformatted');
ok "$dt" eq "1 3 5\n2 4 6\n", 'Stringifies preformatted';

$dt->string_mode('html');
ok "$dt" eq "<table>
  <tr>
    <td>1</td>
    <td>3</td>
    <td>5</td>
  </tr>
  <tr>
    <td>2</td>
    <td>4</td>
    <td>6</td>
  </tr>
</table>\n", 'Stringifies html';

my $pages = $dt->pages;
is_deeply $pages,
  [ [ [ 1, 3, 5 ], [ 2, 4, 6 ] ], [ [ 7, 9, 11 ], [ 8, 10, 12 ] ] ],
  'Pages returns proper data';

my ( $page1, $page2 ) = @{$dt};
is_deeply $page1, [ [ 1, 3, 5 ],  [ 2, 4,  6 ] ],  'Page1 has proper data';
is_deeply $page2, [ [ 7, 9, 11 ], [ 8, 10, 12 ] ], 'Page2 has proper data';

ok $dt->current == 2, 'Current is 2';

$dt->previous;
ok $dt->current == 1, 'Current is 1';

$dt->next;
ok $dt->current == 2, 'Current is 2';

$dt->first;
ok $dt->current == 1, 'Current is 1';

is_deeply $dt->page(2), [ [ 7, 9, 11 ], [ 8, 10, 12 ] ],
  'Can go to explicit page';
is_deeply $dt->page, [ [ 7, 9, 11 ], [ 8, 10, 12 ] ], 'Can access current page';

done_testing;
