use strict;
use warnings;

use Test::More
    skip_all => "Unimplemented";

=head1
eval { require Test::Output };
if ($@)
{
    plan skip_all => 'These tests require Test::Output.';
}

plan tests => 1;
{
    package DateTimeX::Lite::Locale::fake;

    use strict;
    use warnings;

    use DateTimeX::Lite::Locale;

    use base 'DateTimeX::Lite::Locale::root';

    sub cldr_version { '0.1' }

    sub _default_date_format_length { 'medium' }

    sub _default_time_format_length { 'medium' }

    DateTimeX::Lite::Locale->register( id          => 'fake',
                                en_language => 'Fake',
                              );
}

{
    Test::Output::stderr_like
        ( sub { DateTimeX::Lite::Locale->load('fake') },
          qr/\Qfrom an older version (0.1)/,
          'loading timezone where olson version is older than current'
        );
}
=cut
