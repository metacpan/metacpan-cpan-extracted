use Test::More tests => 12;

SKIP: {

    eval { require Catalyst::Helper; };

    skip "Catalyst::Helper not installed", 12 if $@;

    my @files =
    qw[t/Generated.pm t/root/SomeTable/edit.tmpl t/root/SomeTable/add.tmpl t/root/SomeTable/list.tmpl t/root/SomeTable/view.tmpl];

    for my $file (@files) {
        ok( !-e $file, "$file should not be present" );
        diag("Testing $file is not present");
    }

    my $helper = Catalyst::Helper->new;

    ok( $helper, 'Helper creation' );
    diag("Helper created");

    ok(
        $helper->mk_component(
            'TestApp',   "controller",
            "SomeTable", "Scaffold::HTML::Template",
            "CDBI::SomeTable", { file => './t/Generated.pm', base => './t/' }
        ),
        'Files crestion'
    );

    for my $file (@files) {
        ok( -e $file, "$file  creation" );
        diag("Testing $file creation");
    }

    for my $file (@files) {
        unlink $file;
    }

}
	
