use strict;
use warnings;

use Test::More 0.88;

use Test::Requires (
    'Path::Class' => '0',
);

use File::Slurp::Tiny qw( read_file );
use Path::Class qw( dir );

use Courriel;

my $dir = dir(qw( t data stress-test));

{
    my $email = _parse( $dir->file('mbox_bad_date_email.txt') );

    is(
        $email->datetime->date,
        '2000-06-07',
        'email with totally bogus Date header still produces correct date for ->datetime'
    );
}

{
    my $email = _parse( $dir->file('mbox_date_encoded.txt') );

    is(
        $email->datetime->date,
        '2001-12-24',
        'email with totally weirdly encoded Date header still produces correct date for ->datetime'
    );
}

{
    my $email = _parse( $dir->file('mbox_mime_missing-abuse.txt') );

    my $plain = $email->plain_body_part;

    like(
        $plain->content,
        qr/You need to read/,
        'found plain body content with broken mime boundary'
    );
}

{
    my $email = _parse( $dir->file('mbox_mime_virus-alert-headers.txt') );

    my $plain = $email->plain_body_part;

    like(
        $plain->content,
        qr/V I R U S  A L E R T/,
        'found plain body content with no content-type header'
    );
}

{
    my $email = _parse( $dir->file('mbox_unknown8bit.txt') );

    my $plain = $email->plain_body_part;

    like(
        $plain->content,
        qr/dip my toe/,
        'plain body part contains expected content'
    );
}

done_testing();

sub _parse {
    my $file = shift;

    my $text = read_file( $file->stringify );

    my $email = eval { Courriel->parse( text => \$text ) };
    BAIL_OUT("Failed to parse $file")
        if $@ || !$email;

    return $email;
}
