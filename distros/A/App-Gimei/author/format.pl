use v5.40;
use feature 'class';
no warnings 'experimental::class';

class Formatter {
    use FindBin;
    use File::Spec;
    use Cwd 'abs_path';
    use Perl::Tidy;
    use List::Util qw(any);

    my @patterns = ( qr/.+\.pl$/, qr/.+\.pm$/, qr/.+\.t$/, qr/^cpanfile$/ );

    field $root_dir : param = undef;

    ADJUST {
        $root_dir = abs_path( File::Spec->catdir( $FindBin::Bin, '..' ) );
    }

    method run() {
        my @files = `git -C $root_dir ls-files `;
        chomp @files;
        foreach my $f (@files) {
            if ( any { $f =~ $_ } @patterns ) {
                print $f . "\n";
                $self->format($f);
            }
        }
    }

    method format($file) {
        my $perltidyrc = File::Spec->catfile( $root_dir, '.perltidyrc' );

        my $error = Perl::Tidy::perltidy(
            source      => $file,
            destination => $file,
            perltidyrc  => $perltidyrc,
        );
        if ($error) {
            die "perltidy failed on $file\n";
        }
    }
}

my $formatter = Formatter->new();
$formatter->run();
