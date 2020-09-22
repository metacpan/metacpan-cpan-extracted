use strictures 2;
use autodie;
use File::Slurper qw(read_text);
use Test::More;
use Test::Exception;
use Capture::Tiny qw(capture_stdout);

use App::Reorder::TSV qw( reorder );

my @data = (
    [ 'test.tsv',       'template.tsv',      'output.tsv' ],
    [ 'test.tsv.gz',    'template.tsv',      'output.tsv' ],
    [ 'test-norow.tsv', 'template.tsv',      'output-norow.tsv' ],
    [ 'test-nocol.tsv', 'template.tsv',      'output-nocol.tsv' ],
    [ 'test-same.tsv',  'template-same.tsv', 'output-same.tsv' ],
);

plan tests => ( 2 * scalar @data ) + 5;

foreach my $datum (@data) {
    my ( $tsv_file, $template_file, $output_file ) = @{$datum};

    my $output_string = read_text( 't/data/' . $output_file );

    my $output;
    open my $fh, q{>}, \$output;
    reorder(
        {
            tsv      => 't/data/' . $tsv_file,
            template => 't/data/' . $template_file,
            fh       => $fh,
        }
    );
    is( $output, $output_string, "$tsv_file / $template_file -> filehandle" );
    close $fh;

    $output = capture_stdout {
        reorder(
            {
                tsv      => 't/data/' . $tsv_file,
                template => 't/data/' . $template_file,
            }
        )
    };
    is( $output, $output_string, "$tsv_file / $template_file -> STDOUT" );
}

throws_ok {
    reorder(
        {
            template => 't/data/template.tsv',
        }
    )
}
qr/TSV argument missing/ms, 'Missing TSV';

throws_ok {
    reorder(
        {
            tsv => 't/data/test.tsv',
        }
    )
}
qr/Template argument missing/ms, 'Missing template';

throws_ok {
    reorder(
        {
            tsv      => 't/data/notexist.tsv',
            template => 't/data/template.tsv',
        }
    )
}
qr/Input TSV file does not exist/ms, 'TSV not exist';

throws_ok {
    reorder(
        {
            tsv      => 't/data/test.tsv',
            template => 't/data/notexist.tsv',
        }
    )
}
qr/Template TSV does not exist/ms, 'Template not exist';

throws_ok {
    reorder(
        {
            tsv      => 't/data/notgz.tsv.gz',
            template => 't/data/template.tsv',
        }
    )
}
qr/gunzip failed/ms, 'Not gunzipped file';

