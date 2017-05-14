use Test::More ;

my $dir  = $ENV{PWD} =~ m#\/t$#  ? '../' : '';
##plan skip_all => "Spelling tests only for author" unless -d 'inc/.author';
my $filter = sub {
		my $_ = shift;
		! (/_ja.pod$/ || /_es.pad$/ )
};

use constant { NO_CHECK => 1 };

eval 'use Test::Spelling' ;

SKIP: {        
		done_testing(1)                        if $@ || NO_CHECK ;
        skip  'no Test::Spelling', scalar 1    if $@ || NO_CHECK ;
		add_stopwords(<DATA>);
		set_pod_file_filter($filter) ;
		my @files = all_pod_files ( "${dir}blib"  );
		pod_file_spelling_ok( $_, ) for @files;
		done_testing( scalar @files );
};

__END__
#     RecDecent
#     RecDescent
#     TCPDMATCH
#     TcpdmatchRD
#     TcpdmatchYapp
#     libwarp
#     tcpdmatch
#     yapp
not ok 3 - POD spelling for ../blib/lib/Authen/Tcpdmatch/TcpdmatchRD.pm
#   Failed test 'POD spelling for ../blib/lib/Authen/Tcpdmatch/TcpdmatchRD.pm'
#   at 01s_spelling.t line 20.
# Errors:
#     libwarp
#     tcpdmatch
