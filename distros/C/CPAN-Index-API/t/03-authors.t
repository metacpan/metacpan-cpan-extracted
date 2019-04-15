use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempfile);
use Path::Tiny qw(path);
use CPAN::Index::API::File::MailRc;

my $mailrc = <<'EndOfMailRc';
alias FOOBAR "Foo Bar <foo@bar.com>"
alias LOCAL "Local <CENSORED>"
alias PSHANGOV "Peter Shangov <pshangov@example.com>"
EndOfMailRc

my @authors = (
    { authorid => 'FOOBAR',   name => 'Foo Bar',       email => 'foo@bar.com' },
    { authorid => 'PSHANGOV', name => 'Peter Shangov', email => 'pshangov@example.com' },
    { authorid => 'LOCAL',    name => 'Local' },
);

my $writer = CPAN::Index::API::File::MailRc->new(
    authors => \@authors,
);

eq_or_diff( $writer->content, $mailrc, 'mailrc' );

my ($fh, $filename) = tempfile;
$writer->write_to_file($filename);
my $content = path($filename)->slurp_utf8;
eq_or_diff( $content, $mailrc, 'write to file' );

my $reader = CPAN::Index::API::File::MailRc->read_from_string($mailrc);

my @three_authors = $reader->authors;

is ( scalar @three_authors, 3, "reader has 3 authors" );

(my $foobar) = grep { $_->{authorid} eq 'FOOBAR' } @three_authors;

is ( $foobar->{authorid}, 'FOOBAR',      'read author id' );
is ( $foobar->{name},     'Foo Bar',     'read author name'    );
is ( $foobar->{email},    'foo@bar.com', 'read author email'   );

(my $undef_email) = grep { ! defined $_->{email} } @three_authors;
is ( $undef_email->{email}, undef, 'read undefined email' );

is ( $foobar->{authorid}, 'FOOBAR',      'read author id' );
is ( $foobar->{name},     'Foo Bar',     'read author name'    );
is ( $foobar->{email},    'foo@bar.com', 'read author email'   );

done_testing;
