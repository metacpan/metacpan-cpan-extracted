package DFVCDT::Test::FlexYear;
use DateTime::Format::Strptime;

use DateTime::Format::Builder (
  parsers => {
    parse_datetime => [
      sub { eval { DateTime::Format::Strptime->new(pattern => '%m/%d/%Y')->parse_datetime($_[1]) } },
      sub { eval { DateTime::Format::Strptime->new(pattern => '%m/%d/%y')->parse_datetime($_[1]) } },
    ]
  }
);

1;
