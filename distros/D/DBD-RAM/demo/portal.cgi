#!perl -Tw
use strict;
$|++;
use CGI qw(:all -nodebug);
use DBI;
my $dbh = DBI->connect('dbi:RAM:',,,{RaiseError => 1});
my $table_name = 'demo_table';
print header,
      start_html("DBD::RAM Portal Demo"),
      &get_sites(),
      end_html;

sub get_sites {
    my @sites = (
        {
          remote_source => 'http://www.slashdot.org/slashdot.xml',
          record_tag    => 'backslash story',
          col_names     => ['title','url','topic']
        },
        {
          remote_source => 'http://www.freshmeat.net/backend/fm.rdf',
          record_tag    => 'rss channel item',
          col_names     => ['title','link','description']
        }
    );
    for my $specs(@sites){ 
        $specs->{data_type}  = 'XML';
        $specs->{table_name} = $table_name;
        $dbh->func($specs,'import');
    } 
    my $sth = $dbh->prepare("SELECT * FROM $table_name ORDER BY title");
    $sth->execute;
    my @rows;
    while( my($title,$url,$topic) = $sth->fetchrow_array ) {
        my @row;
        push @row, qq{<a href ="$url">$title</a>\n};
        $url =~ s#.*//([^.]*)\..*#$1#;
        push @row, $topic;
        push @row, $url;     # source name
        push @rows, \@row;
    }
    my $columns = ['Article','Topic','Source'];
    return table({Border => 1, Cellspacing => 0, Cellpadding => 2},
              Tr(
                 {bgcolor=>'#cccccc'},
                 th($columns)
              ),
              map Tr(td($_)), @rows);
}
__END__


