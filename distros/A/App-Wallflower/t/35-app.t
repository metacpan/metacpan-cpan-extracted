use strict;
use warnings;
use Test::More;
use Test::Output;
use File::Temp qw( tempdir );
use File::Spec;

my $dir = tempdir( CLEANUP => 1 );

# pod2usage calls exit
BEGIN {
    no strict 'refs';
    *{"CORE::GLOBAL::exit"} = sub { die "exit(@_)" };
}

use App::Wallflower;

plan tests => 4;

my $content = << "HTML";
<h1>Same</h1>

HTML
my $app = sub {
    my $env = shift;
    [
        200,
        [ 'Content-Type' => 'text/html', 'Content-Length' => length $content ],
        [$content]
    ];
};

# quick test of new_with_options
my $awf;
stderr_like(
    sub {
        $awf = eval { App::Wallflower->new_with_options(); };
    },
    qr/^Missing required option: application/,
    "expected error message for empty \@ARGV"
);
is( $awf, undef, "new_with_options() failed" );

# test App::Wallflower
$awf = App::Wallflower->new(
    option => {
        application => $app,
        destination => $dir,
        quiet       => 1,
    },
    callbacks => [ sub { pass('callback after running the app') } ],
);
$awf->run;

my $result = do {
    local $/;
    my $file = File::Spec->catfile( $dir, 'index.html' );
    open my $fh, '< :raw', $file or die "Can't open $file: $!";
    <$fh>;
};
is( $result, $content, "read content from file" );
