# -*- perl -*-

# t/007_get_lookup_table.t

use 5.010;
use CPAN::Mini::Visit::Simple;
use CPAN::Mini::Visit::Simple::Auxiliary qw(
    get_lookup_table
    create_minicpan_for_testing
);
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );

use Test::More;
require CPAN::Mini;
my $config_file = CPAN::Mini->config_file({});
if (! (defined $config_file and -e $config_file) ) {
    plan skip_all => 'No .minicpanrc located';
}
my %config = CPAN::Mini->read_config;
if (! $config{local}) {
    plan skip_all => "No 'local' setting in configuration file '$config_file'";
}
elsif (! (-d $config{local}) ) {
    plan skip_all => 'minicpan directory not located';
}
else {
    plan tests => 11;
}

{
    my ($tdir, $author_dir) = create_minicpan_for_testing();

    # Create object and get primary list
    my $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');

    ok( $self->identify_distros(),
        "identify_distros() returned true value" );

    my $list_ref = $self->get_list_ref();
    my %seen_in = map { $_ => 1 } ( @{$list_ref} );

    my $lookup = get_lookup_table( $list_ref );
    my %seen_out = map { $lookup->{$_}{distro} => 1 } ( keys %{$lookup} );

    is_deeply( \%seen_in, \%seen_out, "In and out matched up" );
}

{
    my ( $tdir, $id_dir, $author_dir );
    my ( @source_list );
    # Prepare the test by creating a minicpan in a temporary directory.
    $tdir = tempdir( CLEANUP => 1 );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    $author_dir = File::Spec->catdir($id_dir, qw( A AA AARDVARK ) );
    make_path($author_dir, { mode => 0711 });
    ok( -d $author_dir, "'author's directory created for testing" );

    @source_list = qw(
        Alpha-Beta-0.01.tar.gz
        Gamma-Delta-0.02.tar.gz
        Epsilon-Zeta-0.03.tar.txt
    );
    my @input = ();
    foreach my $distro (@source_list) {
        my $fulldistro = File::Spec->catfile($author_dir, $distro);
        push @input, $fulldistro;
    }
    my $lookup = get_lookup_table( \@input );
    my $seen = 0;
    foreach my $k ( keys %{$lookup} ) {
        $seen++ if $k =~ m/Epsilon-Zeta/;
    }
    is( $seen, 0, "key not added because it did not match regex" );
}
