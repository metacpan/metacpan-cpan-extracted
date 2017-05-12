use strict;
use warnings;

use Test::Most;
use Test::XML;
use CPAN::Index::API::File::Whois;

my $whois = <<'EndOfWhois';
<?xml version="1.0" encoding="UTF-8"?>
<cpan-whois xmlns='http://www.cpan.org/xmlns/whois'
            last-generated='Tue Sep 18 04:19:04 2012 GMT'
            generated-by='Id'>
 <cpanid>
  <id>AFOXSON</id>
  <type>author</type>
  <fullname></fullname>
 </cpanid>
 <cpanid>
  <id>YOHAMED</id>
  <type>author</type>
  <fullname></fullname>
  <email>moe334578-pause@yahoo.com</email>
 </cpanid>
</cpan-whois>
EndOfWhois

my $index = CPAN::Index::API::File::Whois->read_from_string($whois);

my $generated_by   = 'Id';
my $last_generated = "Tue Sep 18 04:19:04 2012 GMT";

my @authordata = (
    {
        cpanid    => 'AFOXSON',
        type      => 'author',
        full_name => undef,
    },
    {
        cpanid    => 'YOHAMED',
        type      => 'author',
        full_name => undef,
        email     => 'moe334578-pause@yahoo.com',
    },
);

is $index->generated_by, $generated_by, 'read generated-by';
is $index->last_generated, $last_generated, 'read last-generated';

is $index->author_count, scalar @authordata, 'correct number of entries';

my $i = 0;

foreach my $author ($index->authors) {
    foreach my $property ( keys %{$authordata[$i]} ) {
        is $author->{$property}, $authordata[$i]{$property}, "read author $property";
    }
    $i++;
}

my $new_index = CPAN::Index::API::File::Whois->new(
    generated_by   => $generated_by,
    last_generated => $last_generated,
    authors        => \@authordata,
);

is_xml $new_index->content, $whois, "generate xml";

done_testing;
