use strict;
use Test::More;

plan skip_all => "Only useful to the author" unless -d "releases";
plan skip_all => "Test::Deep required for this test" unless eval "use Test::Deep; 1";
eval "use File::Temp qw(:POSIX)";
eval "use YAML qw(LoadFile)";
eval "use CPAN::Dependency";


# known dependencies
my @mods = qw(
    WWW::Mechanize  Maypole  Template  CPAN::Search::Lite  Net::Pcap  SVK  Test::Class
);
my %dists = (
    'WWW::Mechanize' => 'WWW-Mechanize', 
    'Maypole' => 'Maypole', 
    'Template' => 'Template-Toolkit', 
    'CPAN::Search::Lite' => 'CPAN-Search-Lite', 
    'Net::Pcap' => 'Net-Pcap', 
    'SVK' => 'SVK', 
    'Test::Class' => 'Test-Class', 
);
my %prereqs = (
    'CPAN-Search-Lite' => {
        author => 'Randy Kobes', 
        cpanid => 'RKOBES', 
        prereqs => {
            'AI-Categorizer' => 1, 
            'Apache2-SOAP' => 0, 
            #'Archive-Tar' => 1,    # core since 5.9.3
            'Archive-Zip' => 1, 
            'CPAN-DistnameInfo' => 1, 
            'Config-IniFiles' => 1, 
            'DBD-mysql' => 1, 
            #'File-Temp' => 1,      # core since 5.6.1
            #'IO-Zlib' => 1,        # core since 5.9.3
            'Lingua-Stem' => 1, 
            'Lingua-StopWords' => 1, 
            #'PathTools' => 1, 
            'Perl-Tidy' => 1, 
            #'Pod-Parser' => 1, 
            'Pod-Xhtml' => 1, 
            'SOAP-Lite' => 1, 
            'XML-SAX-ExpatXS' => 1, 
            'YAML' => 1, 
            'libwww-perl' => 1, 
            'txt2html' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    Maypole => {
        author => 'Aaron James Trevena', 
        cpanid => 'TEEJAY', 
        prereqs => {
            'CGI-Simple' => 1, 
            'CGI-Untaint' => 1, 
            'CGI-Untaint-date' => 1, 
            'CGI-Untaint-email' => 1, 
            'Class-DBI' => 1, 
            'Class-DBI-AbstractSearch' => 1, 
            'Class-DBI-Loader' => 1, 
            'Class-DBI-Loader-Relationship' => 1, 
            'Class-DBI-Pager' => 1, 
            'Class-DBI-Plugin-RetrieveAll' => 1, 
            'Class-DBI-Plugin-Type' => 1, 
            'Class-DBI-SQLite' => 1, 
            'Class-DBI-SQLite' => 1, 
            'File-MMagic-XS' => 1, 
            #'Digest-MD5' => 1,         # core since 5.7.3
            'HTML-Tree' => 1, 
            'HTTP-Body' => 1, 
            'Template-Plugin-Class' => 1, 
            'Template-Toolkit' => 1, 
            'Test-MockModule' => 1, 
            'UNIVERSAL-moniker' => 1, 
            'UNIVERSAL-require' => 1, 
            'URI' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Net-Pcap' => {
        author => 'Sebastien Aperghis-Tramoni', 
        cpanid => 'SAPER', 
        prereqs => {}, 
        used_by => ignore(), 
        score => 0, 
    }, 
    SVK => {
        author => 'Chia-liang Kao', 
        cpanid => 'CLKAO', 
        prereqs => {
            'Algorithm-Annotate' => 0, 
            'Algorithm-Diff' => 1, 
            'App-CLI' => 0, 
            'Class-Autouse' => 1, 
            'Class-Accessor' => 1, 
            'Class-Data-Inheritable' => 1, 
            'Data-Hierarchy' => 0, 
            #'Encode' => 1,             # core since 5.7.3
            #'File-Temp' => 1,          # core since 5.6.1
            'IO-Digest' => 0, 
            #'Getopt-Long' => 1,        # core since 5.000
            'List-MoreUtils' => 1, 
            'Path-Class' => 1, 
            'PerlIO-eol' => 1, 
            'PerlIO-via-dynamic' => 0, 
            'PerlIO-via-symlink' => 0, 
            #'Pod-Escapes' => 1,        # core since 5.9.3
            #'Pod-Simple' => 1,         # core since 5.9.3
            'SVN-Mirror' => 0,          # third-party module
            'SVN-Simple' => 0, 
            'TermReadKey' => 1, 
            #'Time-HiRes' => 1,         # core since 5.7.3
            'UNIVERSAL-require' => 1, 
            'URI' => 1, 
            'YAML-Syck' => 1, 
            #'version' => 1,            # core since 5.9
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Test-Class' => {
        author => 'Adrian Howard', 
        cpanid => 'ADIE', 
        prereqs => {
            'Devel-Symdump' => 1, 
            'Test-Exception' => 0, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'Template-Toolkit' => {
        author => 'Andy Wardley', 
        cpanid => 'ABW', 
        prereqs => {
            'AppConfig' => 0, 
            'File-HomeDir' => 1, 
            #'PathTools' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
    'WWW-Mechanize' => {
        author => 'Andy Lester', 
        cpanid => 'PETDANCE', 
        prereqs => {
            'libwww-perl' => 1, 
            #'File-Temp' => 1, 
            'HTML-Parser' => 1, 
            #'Pod-Parser' => 1, 
            #'Test-Simple' => 1, 
            'URI' => 1, 
        }, 
        used_by => ignore(), 
        score => 0, 
    }, 
);

# test plan
my @all = ( values(%dists), map { keys %{ $prereqs{$_}{prereqs} } } keys %prereqs );
@all = do { my %uniq; @uniq{@all} = (); keys %uniq };

plan tests => 
        4               # object creation
        + 2 * @mods     # dependencies checking
        + 4 + @all      # score checking
        + 3             # saving data on disk
        + 7             # loading save data from disk
;


# create an object
my $cpandep = undef;
eval { $cpandep = new CPAN::Dependency };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

# checking that the whole thing works as expected: we'll ask the dependencies 
# of several distributions then check that the information are what we expect
$cpandep->verbose(0);
$cpandep->debug(0);

for my $mod (@mods) {
    my $dist = $dists{$mod};
    $cpandep->process($mod);
    eval { $cpandep->run };
    is( $@, '', "processing $mod" );
    cmp_deeply( $cpandep->deps_by_dists->{$dist}, $prereqs{$dist}, "checking information for $mod" )
}

# calculate the score of each distribution
eval { $cpandep->calculate_score };
is( $@, '', "calculate_score()" );

#is( $cpandep->deps_by_dists->{'Test-Simple'}{score}, '1', "score of Test-Simple" );
is( $cpandep->deps_by_dists->{'URI'        }{score}, '3', "score of URI" );
is( $cpandep->deps_by_dists->{'libwww-perl'}{score}, '2', "score of libwww-perl" );

my %score = ();
eval { %score = $cpandep->score_by_dists };
is( $@, '', "score_by_dists()" );

for my $dist (keys %score) {
    is( $score{$dist}, $cpandep->deps_by_dists->{$dist}{score}, "checking score of $dist" );
}

# saving the dependencies tree to the disk
my $file = tmpnam();
eval { $cpandep->save_deps_tree(file => $file) };
is( $@, '', "save_deps_tree()" );
ok( -f $file, "file exists" );

my $deps = LoadFile($file);
cmp_deeply( $deps, $cpandep->deps_by_dists, "saved file has the same data as object" );

# loading the previously saved tree in a new object
my $cpandep2 = undef;
eval { $cpandep2 = $cpandep->new };
is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

eval { $cpandep2->load_deps_tree(file => $file) };
is( $@, '', "load_deps_tree()" );
cmp_deeply( $cpandep2->deps_by_dists, $deps, "new object has the same data as saved file" );
cmp_deeply( $cpandep2->deps_by_dists, $cpandep->deps_by_dists, "new object has the same data as previous object" );

