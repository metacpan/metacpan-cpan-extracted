use strict; use warnings;

use CPAN::Meta;
use Software::LicenseUtils;
use Pod::Readme::Brief;

sub slurp { open my $fh, '<', $_[0] or die "Couldn't open $_[0] to read: $!\n"; readline $fh }
sub trimnl { s/\A\s*\n//, s/\s*\z/\n/ for @_; @_[ 0 .. $#_ ] }

chdir $ARGV[0] or die "Cannot chdir to $ARGV[0]: $!\n";

my %file;

my $meta = CPAN::Meta->load_file( 'META.json' );

my $license = do {
	my @key = ( $meta->license, $meta->meta_spec_version );
	my ( $class, @ambiguous ) = Software::LicenseUtils->guess_license_from_meta_key( @key );
	die if @ambiguous;
	$class->new( $meta->custom( 'x_copyright' ) );
};

$file{'LICENSE'} = trimnl $license->fulltext;

( my $src = 'lib/' . $meta->name . '.pm' ) =~ s!-!/!g;
my @source = slurp $src;
splice @source, -2, 0, "\n=head1 AUTHOR\n\n", join "\n", trimnl $meta->authors;
splice @source, -2, 0, "\n=head1 COPYRIGHT AND LICENSE\n\n", trimnl $license->notice;
$file{ $src } = join '', @source;

die unless -e 'Makefile.PL';
$file{'README'} = Pod::Readme::Brief->new( @source )->render( installer => 'eumm' );

my @manifest = slurp 'MANIFEST';
my %manifest = map /\A([^\s#]+)()/, @manifest;
$file{'MANIFEST'} = join '', @manifest, sort map "$_\n", grep !exists $manifest{ $_ }, keys %file;

for my $fn ( sort keys %file ) {
	unlink $fn if -e $fn;
	open my $fh, '>', $fn or die "Couldn't open $fn to write: $!\n";
	print $fh $file{ $fn };
	close $fh or die "Couldn't close $fn after writing: $!\n";
}
