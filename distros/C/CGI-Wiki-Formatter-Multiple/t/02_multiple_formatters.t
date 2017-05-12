use strict;
use CGI::Wiki;
use CGI::Wiki::Store::SQLite;
use CGI::Wiki::Formatter::Default;
use CGI::Wiki::Formatter::Multiple;
use vars qw( $num_sqlite_tests );
BEGIN {
   $num_sqlite_tests = 7;
}
use Test::More tests => 1 + $num_sqlite_tests;

my $default_fmtr = CGI::Wiki::Formatter::Default->new;
my $uc_fmtr = Local::Test::Formatter::UC->new;
my $append_fmtr = Local::Test::Formatter::Append->new;

my $formatter = CGI::Wiki::Formatter::Multiple->new(
    normal   => $default_fmtr,
    uc       => $uc_fmtr,
    _DEFAULT => $append_fmtr,
);
isa_ok( $formatter, "CGI::Wiki::Formatter::Multiple" );

eval { require DBD::SQLite };
my $run_tests = $@ ? 0 : 1;

SKIP: {
    skip "DBD::SQLite not installed - can't make test database",
      $num_sqlite_tests unless $run_tests;

    my $store = CGI::Wiki::Store::SQLite->new( dbname => "./t/wiki.db" );
    my $wiki = CGI::Wiki->new( store => $store, formatter => $formatter );
    isa_ok( $wiki, "CGI::Wiki" );

    $wiki->write_node( "Normal Node", "foo bar FooBar", undef,
                       { formatter => "normal" } ) or die "Can't write node";
    $wiki->write_node( "UC Node", "foo bar", undef,
                       { formatter => "uc" } ) or die "Can't write node";
    $wiki->write_node( "Other Node", "foo bar" ) or die "Can't write node";

    my %data1 = $wiki->retrieve_node( "Normal Node" );
    my $output1 = $wiki->format( $data1{content}, $data1{metadata} );
    like( $output1, qr|\Q<p>foo bar <a href="wiki.cgi?node=FooBar">FooBar</a></p>|,
          "'normal' node formatted as expected" );

    my %data2 = $wiki->retrieve_node( "UC Node" );
    my $output2 = $wiki->format( $data2{content}, $data2{metadata} );
    like( $output2, qr|FOO BAR|,
          "'uc' node formatted as expected" );

    my %data3 = $wiki->retrieve_node( "Other Node" );
    my $output3 = $wiki->format( $data3{content}, $data3{metadata} );
    like( $output3, qr|foo bar XXXX|,
          "default node formatted as expected" );

    # Now test we get a sensible default _DEFAULT.
    $formatter = CGI::Wiki::Formatter::Multiple->new( uc => $uc_fmtr );
    $wiki = CGI::Wiki->new( store => $store, formatter => $formatter );
    my %data4 = $wiki->retrieve_node( "Other Node" );
    my $output4 = $wiki->format( $data4{content}, $data4{metadata} );
    like( $output4, qr|<p>\s*foo bar\s*</p>|, "default _DEFAULT as expected" );

    ok( $formatter->can("find_internal_links"),
      "formatter can find_internal_links" );

    my @links = $formatter->find_internal_links( $data1{content}, $data1{metadata} );
    is_deeply(\@links, [ 'FooBar' ], "links are correct");

} # end of SKIP


package Local::Test::Formatter::UC;

sub new {
    return bless {}, shift;
}

sub format {
    return uc( $_[1] );
}

package Local::Test::Formatter::Append;

sub new {
    return bless {}, shift;
}

sub format {
    return $_[1] . " XXXX";
}
