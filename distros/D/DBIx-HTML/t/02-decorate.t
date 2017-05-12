#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use DBIx::HTML;
use Test::More;
use Data::Dumper;

eval "use DBD::CSV 0.48";
plan skip_all => "DBD::CSV 0.48 required" if $@;

eval "use HTML::TableExtract";
plan skip_all => "HTML::TableExtract required" if $@;

plan tests => 5;

my $dbh = DBI->connect (
    "dbi:CSV:", undef, undef, {
        f_ext      => ".csv/r",
        f_dir      => "t/data/",
        RaiseError => 1,
    }
);
my $table = DBIx::HTML->connect( $dbh );

is output( 'select * from decorate', { table => { class => 'foo' } } ),
    '<table class="foo"><tr><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr><tr><td>7</td><td>8</td><td>9</td></tr></table>',
    "able to add attrs to <table>"
;

is output( 'select * from decorate', { tr => { class => 'foo' } } ),
    '<table><tr class="foo"><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr><tr class="foo"><td>1</td><td>2</td><td>3</td></tr><tr class="foo"><td>4</td><td>5</td><td>6</td></tr><tr class="foo"><td>7</td><td>8</td><td>9</td></tr></table>',
    "able to add attrs to <tr>"
;

is output( 'select * from decorate', { td => { class => 'foo' } } ),
    '<table><tr><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr><tr><td class="foo">1</td><td class="foo">2</td><td class="foo">3</td></tr><tr><td class="foo">4</td><td class="foo">5</td><td class="foo">6</td></tr><tr><td class="foo">7</td><td class="foo">8</td><td class="foo">9</td></tr></table>',
    "able to add attrs to <td>"
;

is output( 'select * from decorate', { th => { class => 'foo' } } ),
    '<table><tr><th class="foo">Col 1</th><th class="foo">Col 2</th><th class="foo">Col 3</th></tr><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr><tr><td>7</td><td>8</td><td>9</td></tr></table>',
    "able to add attrs to <th>"
;

is output( 'select * from decorate', { headings => undef } ),
    '<table><tr><th>col_1</th><th>col_2</th><th>col_3</th></tr><tr><td>1</td><td>2</td><td>3</td></tr><tr><td>4</td><td>5</td><td>6</td></tr><tr><td>7</td><td>8</td><td>9</td></tr></table>',
    "able to override headings"
;


sub output {
    my ($query, $table_attrs) = @_;
    my $output = DBIx::HTML
        ->connect($dbh)
        ->do( $query )
        ->generate( %$table_attrs )
    ;
    return $output;
}
