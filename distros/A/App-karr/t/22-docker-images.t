use strict;
use warnings;
use Test::More;

my $dockerfile = 'Dockerfile';
ok( -f $dockerfile, 'Dockerfile exists' ) or BAIL_OUT('Dockerfile missing');

open my $fh, '<', $dockerfile or BAIL_OUT("Could not open $dockerfile: $!");
my $content = do { local $/; <$fh> };
close $fh;

like( $content, qr/AS runtime-root\b/, 'Dockerfile defines a runtime-root target' );
like( $content, qr/AS runtime-user\b/, 'Dockerfile defines a runtime-user target' );
like(
    $content,
    qr/COPY docker\/karr-entrypoint\.sh \/usr\/local\/bin\/karr-entrypoint\.sh/,
    'runtime image copies the ownership-adjusting entrypoint',
);
like(
    $content,
    qr/ENTRYPOINT \["karr-entrypoint\.sh"\]/,
    'root runtime uses the dynamic karr entrypoint',
);
like(
    $content,
    qr/\bUSER karr\b/,
    'user runtime ends as the fixed non-root karr user',
);
like(
    $content,
    qr/\bARG KARR_UID="?1000"?/,
    'Dockerfile exposes a default build-time KARR_UID argument',
);
like(
    $content,
    qr/\bARG KARR_GID="?1000"?/,
    'Dockerfile exposes a default build-time KARR_GID argument',
);

done_testing;
