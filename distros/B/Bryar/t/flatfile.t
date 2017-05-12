use Test::More 'no_plan';
use_ok("Bryar::DataSource::FlatFile");

# Test the all_documents method exists
ok(Bryar::DataSource::FlatFile->can("all_documents"), "We can call all_documents");
# Test the search method exists
ok(Bryar::DataSource::FlatFile->can("search"), "We can call search");

use Bryar;

my $bryar = new Bryar(datadir=>"./t/");

my @documents = reverse $bryar->{config}->source->all_documents($bryar->config);
is(@documents, 2, "We got two documents");
is($documents[0]->title, "First entry", "First title correct");
like($documents[0]->content, qr/flatfile format/, "First content correct");

is($bryar->{config}->source->id_to_file('1'), '1.txt', "id_to_file()");
is($bryar->{config}->source->file_to_id('1.txt'), '1', "file_to_id()");

ok( my @search_results = $bryar->{config}->source->search($bryar->{config}, content => "second" ));
is( scalar @search_results, 1, "Proper number of documents found." );

# add a comment
#         $config,
#        document => $doc,
#        author => $params{author},
#        url => $params{url},
#        content => $params{content},
#        epoch => tim
ok ( $bryar->{config}->source->add_comment( $bryar->{config}, document => $search_results[0], author => 'david cantrell', url => '', email => 'david@cantrell.org.uk', content => 'this is a test comment.  it is cool, innit?' ) );

ok ( my @comment_entries = $bryar->{config}->source->search($bryar->{config}, id => 2 ));

ok( my @subblog_results = $bryar->{config}->source->search($bryar->{config}, subblog => "subcat" ));
# is( scalar @subblog_results, 1, "Proper number of documents found." );
