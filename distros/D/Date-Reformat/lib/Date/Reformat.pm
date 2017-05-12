package Date::Reformat;

=head1 NAME

Date::Reformat - Rearrange date strings

=head1 SYNOPSIS

    use Date::Reformat;

    my $reformat = Date::Reformat->new(
        parser => {
            regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/,
            params => [qw(year month day hour minute second)],
        },
        defaults => {
            time_zone => 'America/New_York',
        },
        transformations => [
            {
                from    => 'year',
                to      => 'century',
                coderef => sub { int($_[0] / 100) },
            },
        ],
        formatter => {
            sprintf => '%s-%02d-%02dT%02d:%02d:02d %s',
            params  => [qw(year month day hour minute second time_zone)],
        },
    );

    my $reformat = Date::Reformat->new(
        parser => {
            strptime => '%Y-%m-%dT%M:%H:%S',
            # or heuristic => 'ymd', # http://www.postgresql.org/docs/9.2/static/datetime-input-rules.html
        },
        defaults => {
            time_zone => 'America/New_York',
        },
        formatter => {
            strftime => '%Y-%m-%dT%M:%H:%S %Z',
            # or data_structure => 'hashref' || 'hash' || 'arrayref' || 'array'
            # or coderef => sub { my ($y, $m, $d) = @_; DateTime->new(year => $y, month => $m, day => $d) },
            # params => [qw(year month day)],
        },
    );

    my $reformatted_string = $reformat->reformat_date($date_string);

=head1 DESCRIPTION

This module aims to be a lightweight and flexible tool for rearranging
components of a date string, then returning the components in the order
and structure specified.

My motivation was a month of trying to compare data from spreadsheets from
several sources, and every single one used a different date format, which
made comparison difficult.

There are so many modules for doing date math, or parsing a specific date
format.  I needed something that could take in pretty much any format
and turn it into a single format that I could then use for comparison.

=cut

use 5.010000;
use strict;
use warnings;

use Types::Standard qw(ClassName Object Maybe Optional slurpy Dict HashRef ArrayRef RegexpRef CodeRef Enum Str Int);
use Type::Params qw();

our $VERSION = '0.04';

my $MONTH_LOOKUP = {
};
{
    # Lookups for month abbreviations.
    my $c = 0;
    foreach my $abbr (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)) {
        $MONTH_LOOKUP->{'abbr'}->{lc($abbr)} = ++$c;
        $MONTH_LOOKUP->{'number'}->{$c}->{'abbr'} = $abbr;
    }
}

my $TOKENS = {
    'year' => {
        'regex'   => q/(?<year>\d{4})/,
        'sprintf' => '%04d',
    },
    'year_abbr' => {
        'regex'   => q/(?<year_abbr>\d{2})/,
        'sprintf' => '%02d',
    },
    'month' => {
        'regex'   => q/(?<month>\d\d?)/,
        'sprintf' => '%02d',
    },
    'month_no_padding' => {
        'regex'   => q/(?<month>\d\d?)/,
        'sprintf' => '%d',
        'storage' => 'month',
    },
    'month_name' => {
        'regex'   => q/(?<month_name>January|February|March|April|May|June|July|August|September|October|November|December)/,
        'sprintf' => '%s',
    },
    'month_abbr' => {
        'regex'   => q/(?<month_abbr>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/,
        'sprintf' => '%s',
    },
    'day' => {
        'regex'   => q/(?<day>\d\d?)/,
        'sprintf' => '%02d',
    },
    'day_name' => {
        'regex'   => q/(?<day_name>Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)/,
        'sprintf' => '%s',
    },
    'day_abbr' => {
        'regex'   => q/(?<day_abbr>Mon|Tues?|Wed|Thur?|Fri|Sat|Sun)/,
        'sprintf' => '%s',
    },
    'day_of_year' => {
        'regex'   => q/(?<day_of_year>\d\d?\d?)/,
        'sprintf' => '%03d',
    },
    'julian_day' => {
        'regex'      => q/J(?<julian_day>\d+)/,
        'sprintf'    => '%s',
        'constraint' => sub { $_[0] >= 0 },
    },
    'era_abbr' => {
        'regex'      => q/(?<era_abbr>BC|AD|BCE|CE)/,
        'sprintf'    => '%s',
    },
    'hour' => {
        'regex'      => q/(?<hour>\d\d?)/,
        'sprintf'    => '%02d',
        'constraint' => sub { $_[0] >= 0 && $_[0] < 24 },
    },
    'hour_12' => {
        'regex'   => q/(?<hour_12>\d\d?)/,
        'sprintf' => '%d',
    },
    'minute' => {
        'regex'      => q/(?<minute>\d\d)/,
        'sprintf'    => '%02d',
        'constraint' => sub { $_[0] >= 0 && $_[0] < 60 },
    },
    'second' => {
        'regex'   => q/(?<second>\d\d)/,
        'sprintf' => '%02d',
    },
    'am_or_pm' => {
        'regex'   => q/(?<am_or_pm>(?i)[ap]\.?m\.?)/,
        'sprintf' => '%s',
    },
    'time_zone' => {
        'regex'   => q/(?<time_zone>Z|UTC|[[:alpha:]]{3,}(?:\/[[:alpha:]]+)?)/,
        'sprintf' => '%s',
    },
    'time_zone_offset' => {
        'regex'   => q|(?<time_zone_offset>[-+]\d\d?(?:\d\d)?)|,
        'sprintf' => '%s',
    },
    'phrase' => {
        'regex'   => q/(?<phrase>(?i)today|tomorrow|yesterday|(?:next|last)\w+(?:week|month|year)|\d+\w+(?:seconds?|minutes?|hours?|days?|weeks?|months?|years?)\w+(?:ago|from\w+now))/,
        'sprintf' => '%s',
    },
};

my $STRPTIME_PREPROCESS = [
    {
        'token'       => '%c',
        'replacement' => '%c', # TODO: Perhaps use Scalar::Defer, and look up locale datetime format only if needed.
    },
    {
        'token'       => '%D',
        'replacement' => '%m/%d/%y',
    },
    {
        'token'       => '%F',
        'replacement' => '%Y-%m-%d',
    },
    {
        'token'       => '%R',
        'replacement' => '%H:%M',
    },
    {
        'token'       => '%r',
        'replacement' => '%I:%M:%S %p', # TODO: This may be affected by locale.
    },
    {
        'token'       => '%T',
        'replacement' => '%H:%M:%S',
    },
    {
        'token'       => '%X',
        'replacement' => '%X', # TODO: Perhaps use Scalar::Defer, and look up locale time format only if needed.
    },
    {
        'token'       => '%x',
        'replacement' => '%x', # TODO: Perhaps use Scalar::Defer, and look up locale date format only if needed.
    },
];

my $STRPTIME_POSTPROCESS = [
    {
        'token'       => '%n',
        'replacement' => '\s+',
    },
    {
        'token'       => '%t',
        'replacement' => '\s+',
    },
    {
        'token'       => '%%',
        'replacement' => quotemeta('%'),
    },
];

my $STRFTIME_POSTPROCESS = [
    {
        'token'       => '%n',
        'replacement' => "\n",
    },
    {
        'token'       => '%t',
        'replacement' => "\t",
    },
];

my $DEFAULT_STRPTIME_MAPPINGS = {
    '%A' => 'day_name', # TODO
    '%a' => 'day_abbr',
    '%B' => 'month_name', # TODO
    '%b' => 'month_abbr',
    '%C' => 'century', # TODO
    '%d' => 'day',
    '%e' => 'day', # TODO: This one is space-padded.
    '%G' => 'week_year', # TODO
    '%g' => 'week_year_abbr', # TODO
    '%H' => 'hour',
    '%h' => 'month_abbr',
    '%I' => 'hour_12',
    '%j' => 'day_of_year',
    '%k' => 'hour', # TODO: This one is space-padded.
    '%l' => 'hour_12', # TODO: This one is space-padded.
    '%M' => 'minute',
    '%m' => 'month',
    '%-m' => 'month_no_padding',
    '%N' => 'fractional_seconds', # TODO
    '%P' => 'am_or_pm',
    '%p' => 'am_or_pm', # TODO: This is uppercase.
    '%S' => 'second',
    '%s' => 'epoch', # TODO
    '%U' => 'week_number_0', # TODO
    '%u' => 'day_of_week', # TODO
    '%V' => 'week_number', # TODO
    '%W' => 'week_number_1', # TODO
    '%w' => 'day_of_week_0', # TODO
    '%Y' => 'year',
    '%y' => 'year_abbr',
    '%Z' => 'time_zone',
    '%z' => 'time_zone_offset',
};

my $DEFAULT_STRFTIME_MAPPINGS = {
};

my $DEFAULT_TRANSFORMATIONS = {
    # to => {
    #   from => \&transformation_coderef,
    # },
    'year' => {
        'year_abbr' => sub {
            my ($date) = @_;
            return $date->{'year'} if defined($date->{'year'});
            return $date->{'year_abbr'} < 70
                ? $date->{'year_abbr'} + 2000
                : $date->{'year_abbr'} + 1900;
        },
    },
    'year_abbr' => {
        'year' => sub {
            my ($date) = @_;
            return $date->{'year_abbr'} if defined($date->{'year_abbr'});
            return substr($date->{'year'}, -2, 2);
        },
    },
    'month' => {
        'month_abbr' => sub {
            my ($date) = @_;
            return $date->{'month'} if defined($date->{'month'});
            return $MONTH_LOOKUP->{'abbr'}->{ lc($date->{'month_abbr'}) } // undef;
        },
    },
    'month_abbr' => {
        'month' => sub {
            my ($date) = @_;
            return $date->{'month_abbr'} if defined($date->{'month_abbr'});
            return $MONTH_LOOKUP->{'number'}->{ $date->{'month'}+0 }->{'abbr'} // undef;
        },
    },
    'hour' => {
        'hour_12' => sub {
            my ($date) = @_;
            return $date->{'hour'} if defined($date->{'hour'});
            if (lc($date->{'am_or_pm'}) eq 'pm') {
                return $date->{'hour_12'} == 12
                    ? $date->{'hour_12'}
                    : $date->{'hour_12'} + 12;
            }
            return $date->{'hour_12'} == 12
                ? 0
                : $date->{'hour_12'};
        },
    },
    'hour_12' => {
        'hour' => sub {
            my ($date) = @_;
            return $date->{'hour_12'} if defined($date->{'hour_12'});
            if ($date->{'hour'} == 0) {
                return 12;
            }
            return $date->{'hour'} < 13
                ? $date->{'hour'}
                : $date->{'hour'} - 12;
        },
    },
    'am_or_pm' => {
        'hour' => sub {
            my ($date) = @_;
            return $date->{'am_or_pm'} if defined($date->{'am_or_pm'});
            if ($date->{'hour'} == 0) {
                return 'am';
            }
            return $date->{'hour'} >= 12
                ? 'pm'
                : 'am';
        },
    },
};

=head2 METHODS

=over 4

=item new()

Returns a new reformatter instance.

    my $reformat = Date::Reformat->new(
        'parser'          => $parsing_instructions,
        'transformations' => $transformation_instructions,
        'defaults'        => $default_values,
        'formatter'       => $formatting_instructions,
        'debug'           => 0,
    );

Parameters:

=over 4

=item parser

A hashref of instructions used to initialize a parser.

See L</"prepare_parser()"> for details.

=item transformations

An arrayref of hashrefs containing instructions on how to
convert values of one token into values for another token
(such as C<month_abbr> to C<month>).

See L</"prepare_transformations()"> for details.

=item defaults

A hashref specifying values to use if the date string does
not contain a specific token (such as a time_zone value).

See L</"prepare_defaults()"> for details.

=item formatter

A hashref of instructions used to initialize a formatter.

See L</"prepare_formatter()"> for details.

=item debug

Either a 1 or a 0, to turn debugging on or off, respectively.

=back

=cut

sub new {
    state $check = Type::Params::compile(
        ClassName,
        slurpy Dict[
            'debug'           => Optional[Int],
            'parser'          => Optional[HashRef],
            'formatter'       => Optional[HashRef],
            'transformations' => Optional[ArrayRef[HashRef]],
            'defaults'        => Optional[HashRef],
        ],
    );
    my ($class, $args) = $check->(@_);
    my $self = bless {}, $class;

    $self->debug($args->{'debug'});

    foreach my $parameter (
        'parser',
        'formatter',
        'transformations',
        'defaults',
    )
    {
        next if ! defined $args->{$parameter};

        my $initialize = 'prepare_' . $parameter;
        my @data = $self->$initialize($args->{$parameter});

        my $add = 'add_' . $parameter;
        $self->$add(@data);
    }
    return $self;
}

=item prepare_parser()

Builds a parser based on the given instructions.  To add it to
the currently active parsers, see L</"add_parser()">.

If several parsers are active, the first one to successfully parse
the current date string returns the results of the parse, and subsequent
parsers are not utilized.  See L</"parse_date()"> for more information.

The types of parsers that can be initialized via this method are:

=over 4

=item regex

The regex must specify what parts should be captured, and a list
of token names must be supplied to identify which token each captured
value will be assigned to.

    $reformat->prepare_parser(
        {
            regex  => qr/^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)$/,
            params => [qw(year month day hour minute second)],
        },
    );

=item regex with named capture

The regex must specify what parts should be captured, using named
capture syntax.

    $reformat->prepare_parser(
        {
            regex  => qr/^(?<year>\d{4})-(?<month>\d\d)-(?<day>\d\d) (?<hour>\d\d?):(?<minute>\d\d):(?<second>\d\d)$/,
        },
    );

=item strptime

The format string must be in strptime() format.

    $reformat->prepare_parser(
        {
            strptime => '%Y-%m-%dT%M:%H:%S',
        },
    );

=item heuristic

A hint must be provided that will help the parser determine the meaning
of numbers if the ordering is ambiguous.

Currently the heuristic parsing mimics the PostgreSQL date parser (though
I have not copied over all the test cases from the PostgreSQL regression
tests, so there are likely to be differences/flaws).

    $reformat->prepare_parser(
        {
            heuristic => 'ymd',  # or 'mdy' or 'dmy'
        },
    );

Currently when the heuristic parser parses a date string, it creates a
named regex parser which it injects into the active parsers directly in
front of itself, so that subsequent date strings that are in the same
format will be parsed via the regex.

I plan to add a parameter that will control whether parsers are generated
by the heuristic parser (I also plan to refactor that method quite a bit,
because it kind of makes me cringe to look at it).

=back

=cut

sub prepare_parser {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'regex'     => Optional[RegexpRef],
            'params'    => Optional[ArrayRef],
            'strptime'  => Optional[Str],
            'heuristic' => Optional[Enum[qw(ymd dmy mdy)]],
        ],
    );
    my ($self, $definition) = $check->(@_);

    if (defined($definition->{'regex'})) {

        # Initialize the right kind of regex parser (simple capture or named capture).
        if (defined($definition->{'params'})) {
            return $self->prepare_parser_for_regex_with_params(
                {
                    'regex'  => $definition->{'regex'},
                    'params' => $definition->{'params'},
                }
            );
        }
        return $self->prepare_parser_for_regex_named_capture(
            {
                'regex' => $definition->{'regex'},
            },
        );

    }

    if (defined($definition->{'strptime'})) {
        return $self->prepare_parser_for_strptime(
            {
                'strptime' => $definition->{'strptime'},
            },
        );
    }

    if (defined($definition->{'heuristic'})) {
        return $self->prepare_parser_heuristic(
            {
                'heuristic' => $definition->{'heuristic'},
            },
        );
    }

    # Nothing initialized.
    return;
}

=item prepare_formatter()

Builds a formatter based on the given instructions.  To add it to the
currently active formatters, see L</"add_formatter">.

If several formatters are active, they are each called in turn, receiving
the output from the previous parser.

The types of parsers that can be initialized via this method are:

=over 4

=item sprintf

The format string must be in sprintf() format, and a list of token names
must be supplied to identify which token values to send to the formatter.

    $reformat->prepare_formatter(
        {
            sprintf => '%s-%02d-%02dT%02d:%02d:02d %s',
            params  => [qw(year month day hour minute second time_zone)],
        },
    );

=item strftime

The format string must be in strftime() format.

    $reformat->prepare_formatter(
        {
            strftime => '%Y-%m-%dT%M:%H:%S %Z',
        },
    );

=item data_structure

The type of the desired data structure must be specified, and a list of
token names to identify which token values to include in the data structure.

Valid data structure types are:

=over 4

=item hash

=item hashref

=item array

=item arrayref

=back

    $reformat->prepare_formatter(
        {
            data_structure => 'hashref',
            params         => [qw(year month day hour minute second time_zone)],
        },
    );

=item coderef

The supplied coderef will be passed the token values specified.  Whatever the
coderef returns will be passed to the next active formatter, or will be returned,
if this is the final formatter.

    $reformat->prepare_formatter(
        {
            coderef => sub { my ($y, $m, $d) = @_; DateTime->new(year => $y, month => $m, day => $d) },
            params  => [qw(year month day)],
        },
    );

=back

=cut

sub prepare_formatter {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'sprintf'        => Optional[Str],
            'params'         => Optional[ArrayRef],
            'strftime'       => Optional[Str],
            'data_structure' => Optional[Enum[qw(hash hashref array arrayref)]],
            'coderef'        => Optional[CodeRef],
        ],
    );
    my ($self, $definition) = $check->(@_);

    if (defined($definition->{'sprintf'})) {
        return $self->prepare_formatter_for_sprintf(
            {
                'sprintf' => $definition->{'sprintf'},
                'params'  => $definition->{'params'},
            },
        );
    }

    if (defined($definition->{'strftime'})) {
        return $self->prepare_formatter_for_strftime(
            {
                'strftime' => $definition->{'strftime'},
            },
        );
    }

    if (defined($definition->{'data_structure'})) {
        if ($definition->{'data_structure'} =~ /^hash(?:ref)?$/) {
            return $self->prepare_formatter_for_hashref(
                {
                    'structure' => $definition->{'data_structure'},
                    'params'    => $definition->{'params'},
                },
            );
        }

        if ($definition->{'data_structure'} =~ /^array(?:ref)?$/) {
            return $self->prepare_formatter_for_arrayref(
                {
                    'structure' => $definition->{'data_structure'},
                    'params'    => $definition->{'params'},
                },
            );
        }
    }

    if (defined($definition->{'coderef'})) {
        return $self->prepare_formatter_for_coderef(
            {
                'coderef' => $definition->{'coderef'},
                'params'  => $definition->{'params'},
            },
        );
    }

    # Nothing initialized.
    return;
}

=item prepare_transformations()

Accepts an arrayref of hashrefs that specify how to transform
token values from one token type to another.

Returns the same arrayref.  To add it to the currently active
transformers, see L</"add_transformations">.

=cut

sub prepare_transformations {
    my ($self, $transformations) = @_;
    return $transformations // [];
}

=item add_transformations()

Accepts an arrayref of hashrefs that specify how to transform
token values from one token type to another.  Adds each
transformation instruction to the list of active transformers.
A transformation instruction with the same C<to> and C<from>
values as a previous instruction will overwrite the previous
version.

    $reformat->add_transformations(
        [
            {
                'to'             => 'hour',
                'from'           => 'hour_12',
                'transformation' => sub {
                    my ($date) = @_;
                    # Use the value of $date->{'hour_12'} (and $date->{'am_or_pm'})
                    # to calculate what the value of $date->{'hour'} should be.
                    # ...
                    return $hour;
                },
            },
        ],
    );

The values in each hashref are:

=over 4

=item to

The name of the token type that is desired (for instance
'hour', meaning the 24-hour format).

=item from

The name of the token type that is available in the date
string (for instance 'hour_12', meaning the 12-hour format).

=item transformation

A coderef which accepts a hashref containing the information
which has been parsed out of the date string.  The coderef
is expected to examine the date information, transform the
token type specified via C<from> into the correct value for the
token type specified via C<to>, and return that value.

=back

Several transformations have been built into this module.
Search for C<$DEFAULT_TRANSFORMATIONS> in the source code.

Transformations added via this method will take precedence
over built-in transformations.

=cut

sub add_transformations {
    state $check = Type::Params::compile(
        Object,
        ArrayRef[
            Dict[
                'to'             => Str,
                'from'           => Str,
                'transformation' => CodeRef,
            ],
        ],
    );
    my ($self, $transformations) = $check->(@_);

    my $count = 0;
    foreach my $t (@$transformations) {
        $self->{'transformations'}->{$t->{'to'}}->{$t->{'from'}} = $t->{'transformation'};
        $count++;
    }
    return $count;
}

=item prepare_defaults()

Accepts a hashref of default values to use when transforming
or formatting a date which is missing tokens that are needed.

This method clears out any defaults which had been set
previously.

Returns the same hashref it was given, but does not set them.
To add defaults, see L</"add_defaults">.

=cut

sub prepare_defaults {
    my ($self, $args) = @_;
    $self->{'defaults'} = {};
    return $args;
}

=item add_defaults()

Accepts a hashref of default values to use when transforming
or formatting a date which is missing tokens that are needed.

Each key should be the name of a token, and the corresponding
value is the default value that will be used when a date is
missing that token.

    $reformat->add_defaults(
        {
            'time_zone' => 'America/New_York',
        },
    );

=cut

sub add_defaults {
    state $check = Type::Params::compile(
        Object,
        HashRef,
    );
    my ($self, $args) = $check->(@_);

    foreach my $token (keys %$args) {
        $self->{'defaults'}->{$token} = $args->{$token};
    }
    return $self->{'defaults'};
}

=item debug()

Turns debugging statements on or off, or returns the
current debug setting.

Expects a true value to turn debugging on, and a false value
to turn debugging off.

    $reformat->debug(1);  # 1 or 0

=cut

sub debug {
    state $check = Type::Params::compile(
        Object,
        Maybe[Int],
    );
    my ($self, $value) = $check->(@_);
    $self->{'debug'} = $value if (defined $value);
    return $self->{'debug'} //= 0;
}

=item prepare_parser_for_regex_with_params()

Internal method called by L</"prepare_parser()">.

=cut

sub prepare_parser_for_regex_with_params {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'regex'  => RegexpRef,
            'params' => ArrayRef,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $regex = $definition->{'regex'};
    my $params = $definition->{'params'};

    state $sub_check = Type::Params::compile(
        Str,
    );

    return (
        sub {
            my ($date_string) = $sub_check->(@_);
            my (@components) = $date_string =~ $regex;
            return if ! @components;
            my %date = ();
            @date{@$params} = @components;
            # TODO: Add named capture values to %date.
            return \%date;
        },
    );
}

=item prepare_parser_for_regex_named_capture()

Internal method called by L</"prepare_parser()">.

=cut

sub prepare_parser_for_regex_named_capture {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'regex' => RegexpRef,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $regex = $definition->{'regex'};

    state $sub_check = Type::Params::compile(
        Str,
    );

    return (
        sub {
            my ($date_string) = $sub_check->(@_);
            my $success = $date_string =~ $regex;
            return if ! $success;
            my %date = %+;

            # Move 'hour_12' if the wrong value.
            if (
                defined($date{'hour_12'})
                &&
                (
                    $date{'hour_12'} > 12
                    ||
                    $date{'hour_12'} == 0
                )
            ) {
                $date{'hour'} = delete $date{'hour_12'};
            }

            return \%date;
        },
    );
}

=item prepare_parser_for_strptime()

Internal method called by L</"prepare_parser()">.

=cut

sub prepare_parser_for_strptime {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'strptime' => Str,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $strptime = $definition->{'strptime'};
    my $format = $strptime;

    # Preprocess some tokens that expand into other tokens.
    foreach my $preprocess (@$STRPTIME_PREPROCESS) {
        $format =~ s/$preprocess->{'token'}/$preprocess->{'replacement'}/g;
    }

    # Escape everything in the strptime string so we can turn it into a regex.
    $format = quotemeta($format);

    # Unescape the parts that we will replace as tokens.
    # regex from DateTime::Format::Strptime
    $format =~ s/(?<!\\)\\%/%/g;
    $format =~ s/%\\\{([^\}]+)\\\}/%{$1}/g;

    # Replace expanded tokens: %{year}
    $format =~
        s/
            %\{(\w+)\}
        /
            $TOKENS->{$1} ? $TOKENS->{$1}->{'regex'} : "\%{$1}"
        /sgex;

    # Replace single character tokens: %Y
    $format =~
        s/
            (%[%a-zA-Z])
        /
            $self->strptime_token_to_regex($1)
        /sgex;

    # Postprocess some tokens that expand into special characters.
    foreach my $postprocess (@$STRPTIME_POSTPROCESS) {
        $format =~ s/$postprocess->{'token'}/$postprocess->{'replacement'}/g;
    }

    say "Crafted regex: $strptime -> $format" if $self->{'debug'};
    return $self->prepare_parser_for_regex_named_capture(
        {
            'regex' => qr/$format/,
        },
    );
}

=item prepare_parser_heuristic()

Internal method called by L</"prepare_parser()">.

=cut

sub prepare_parser_heuristic {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'heuristic' => Enum[qw(ymd dmy mdy)],
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $hint = $definition->{'heuristic'};
    my $known_parsers = {}; # Populated when we add a parser to the stack in front of this one.
    my $regex_for_date = qr{ \w+ [-/\.] \w+ (?:[-/\.] \w+) }x;
    my $regex_for_time = qr/ \d\d? : \d\d (?::\d\d) /x;
    my $regex_for_time_zone_offset = qr/ [-+] \d\d? (?:\d\d) /x;
    my $regex_for_time_zone_long_name = qr{ [[:alpha:]]+ / [[:alpha:]]+ (?:_ [[:alpha:]]+) }x;
    my $regex_for_julian_day = qr/ J\d+ /x;
    my $regex_for_number = qr/ \d+ /x;
    my $regex_for_string = qr/ [[:alpha:]]+ /x;
    my $regex_for_whitespace = qr/ \s+ /x;
    my $token_regex = qr{
        # time zone offset
        ( $regex_for_time_zone_offset )
        # time
        | ( $regex_for_time )
        # time zone long name
        | ( $regex_for_time_zone_long_name )
        # date
        | ( $regex_for_date )
        # Julian day
        | ( $regex_for_julian_day )
        # number
        | ( $regex_for_number )
        # string
        | ( $regex_for_string )
        # whitespace
        | ( $regex_for_whitespace )
        # anything else
        | ( . )
    }x;

    state $sub_check = Type::Params::compile(
        Str,
    );

    return (
        sub {
            my ($date_string) = $sub_check->(@_);
            my $order_string; # Will be set with ymd|dmy|mdy when we have enough information.

            # Split string into parts that can be identified later.
            say "Parsing date string into parts: $date_string" if $self->{'debug'};
            my @parts = $date_string =~ /$token_regex/g;
            return if ! @parts;

            # Try to identify what each part is, based on what it looks like, and what order it is in.
            my @parser_parts = ();
            my $date = {};
            foreach my $part (grep { defined($_) } @parts) {
                say "Trying to identify part: '$part'" if $self->{'debug'};
                if ($part =~ /^$regex_for_time_zone_offset$/) {
                    say "  time_zone_offset ($part)" if $self->{'debug'};
                    push @parser_parts, $TOKENS->{'time_zone_offset'}->{'regex'};
                    $date->{'time_zone_offset'} = $part;
                }
                elsif ($part =~ /^$regex_for_time$/) {
                    my @time = split(/:/, $part);

                    say "  hour ($time[0])" if $self->{'debug'};
                    push @parser_parts, $TOKENS->{'hour'}->{'regex'};
                    $date->{'hour'} = $time[0];

                    say "  minute ($time[1])" if $self->{'debug'};
                    push @parser_parts, quotemeta(':'), $TOKENS->{'minute'}->{'regex'};
                    $date->{'minute'} = $time[1];

                    if (@time > 2) {
                        say "  second ($time[2])" if $self->{'debug'};
                        push @parser_parts, quotemeta(':'), $TOKENS->{'second'}->{'regex'};
                        $date->{'second'} = $time[2];
                    }
                }
                elsif ($part =~ /^$regex_for_time_zone_long_name$/) {
                    say "  time_zone ($part)";
                    push @parser_parts, $TOKENS->{'time_zone'}->{'regex'};
                    $date->{'time_zone'} = $part;
                }
                elsif ($part =~ /^$regex_for_date$/) {
                    my @date_parts = split(m|[-/\.]|, $part);
                    my @order = ();
                    # PostgreSQL forces reliance on the hint.
                    #foreach my $index (0..2) {
                    #    if ($date_parts[$index] =~ /^\d+$/) {
                    #        if ($date_parts[$index] > 31) {
                    #            $order[$index] = 'y';
                    #        }
                    #        elsif ($date_parts[$index] > 12) {
                    #            $order[$index] = 'd';
                    #        }
                    #        else {
                    #            $order[$index] = 'm';
                    #        }
                    #    }
                    #    elsif ($date_parts[$index] =~ $TOKENS->{'month_abbr'}->{'regex'}) {
                    #        $order[$index] = 'm';
                    #    }
                    #}
                    $order_string = join('', @order);
                    if (
                        $date_parts[0] =~ /^$TOKENS->{'year'}->{'regex'}$/
                        &&
                        scalar(keys %$date) == 0
                    ) {
                        $order_string = 'ymd';
                    }
                    elsif (
                        $hint eq 'dmy'
                        &&
                        (
                            $date_parts[0] =~ /^$TOKENS->{'month_abbr'}->{'regex'}$/
                            ||
                            $date_parts[0] =~ /^$TOKENS->{'month_name'}->{'regex'}$/
                        )
                    ) {
                        $order_string = 'mdy';
                    }
                    elsif (
                        $hint eq 'mdy'
                        &&
                        (
                            $date_parts[1] =~ /^$TOKENS->{'month_abbr'}->{'regex'}$/
                            ||
                            $date_parts[1] =~ /^$TOKENS->{'month_name'}->{'regex'}$/
                        )
                    ) {
                        $order_string = 'dmy';
                    }
                    if ($order_string !~ /^ymd|dmy|mdy$/) {
                        say "Using date token order hint: $hint" if $self->{'debug'};
                        $order_string = $hint;
                    }
                    @order = split(//, $order_string);
                    foreach my $index (0..2) {
                        if ($order[$index] eq 'y') {
                            if ($date_parts[$index] =~ /^$TOKENS->{'year'}->{'regex'}$/) {
                                say "  year ($date_parts[$index])" if $self->{'debug'};
                                push @parser_parts, $TOKENS->{'year'}->{'regex'};
                                $date->{'year'} = $date_parts[$index];
                            }
                            elsif ($date_parts[$index] =~ /^$TOKENS->{'year_abbr'}->{'regex'}$/) {
                                say "  year_abbr ($date_parts[$index])" if $self->{'debug'};
                                push @parser_parts, $TOKENS->{'year_abbr'}->{'regex'};
                                $date->{'year_abbr'} = $date_parts[$index];
                            }
                            else {
                                warn "Error parsing year: "
                                    . "value '$date_parts[$index]' out of range ($part); "
                                    . "Perhaps you need a different heuristic hint than '$hint'\n";
                                return;
                            }
                        }
                        elsif ($order[$index] eq 'm') {
                            if (
                                $date_parts[$index] =~ /^$TOKENS->{'month'}->{'regex'}$/
                                && 
                                $date_parts[$index] <= 12
                            ) {
                                say "  month ($date_parts[$index])" if $self->{'debug'};
                                push @parser_parts, $TOKENS->{'month'}->{'regex'};
                                $date->{'month'} = $date_parts[$index];
                            }
                            elsif ($date_parts[$index] =~ /^$TOKENS->{'month_abbr'}->{'regex'}$/) {
                                say "  month_abbr ($date_parts[$index])" if $self->{'debug'};
                                push @parser_parts, $TOKENS->{'month_abbr'}->{'regex'};
                                $date->{'month_abbr'} = $date_parts[$index];
                            }
                            else {
                                warn "Error parsing month: "
                                    . "value '$date_parts[$index]' out of range ($part); "
                                    . "Perhaps you need a different heuristic hint than '$hint'\n";
                                return;
                            }
                        }
                        elsif ($order[$index] eq 'd') {
                            if (
                                $date_parts[$index] !~ /^$TOKENS->{'day'}->{'regex'}$/
                                ||
                                $date_parts[$index] > 31
                            ) {
                                warn "Error parsing day: "
                                    . "value '$date_parts[$index]' out of range ($part); "
                                    . "Perhaps you need a different heuristic hint than '$hint'\n";
                                return;
                            }
                            say "  day ($date_parts[$index])" if $self->{'debug'};
                            push @parser_parts, $TOKENS->{'day'}->{'regex'};
                            $date->{'day'} = $date_parts[$index];
                        }
                        push @parser_parts, qr|[-/\.]| if $index < 2;
                    }
                }
                elsif ($part =~ /^$regex_for_julian_day$/) {
                    my $success = $part =~ $TOKENS->{'julian_day'}->{'regex'};
                    say "  julian_day ($part)\n";
                    push @parser_parts, $TOKENS->{'julian_day'}->{'regex'};
                    $date->{'julian_day'} = $+{'julian_day'};
                }
                elsif ($part =~ /^$regex_for_number$/) {
                    if (length($part) == 8) {
                        my $regex_date =
                            qr/
                                $TOKENS->{'year'}->{'regex'}
                                $TOKENS->{'month'}->{'regex'}
                                $TOKENS->{'day'}->{'regex'}
                            /x;
                        my $success = $part =~ $regex_date;
                        my %ymd = %+;
                        foreach my $token ('year', 'month', 'day') {
                            say "  $token ($ymd{$token})";
                            push @parser_parts, $TOKENS->{$token}->{'regex'};
                            $date->{$token} = $ymd{$token};
                        }
                    }
                    elsif (length($part) == 6) {
                        if (defined($date->{'year'})) {
                            # This is a concatenated time: HHMM
                            my $regex_time =
                                qr/
                                    $TOKENS->{'hour'}->{'regex'}
                                    $TOKENS->{'minute'}->{'regex'}
                                    $TOKENS->{'second'}->{'regex'}
                                /x;
                            my $success = $part =~ $regex_time;
                            my %hms = %+;
                            foreach my $token ('hour', 'minute', 'second') {
                                say "  $token ($hms{$token})";
                                push @parser_parts, $TOKENS->{$token}->{'regex'};
                                $date->{$token} = $hms{$token};
                            }
                        }
                        else {
                            # This is a concatenated date: YYMMDD
                            my $regex_date =
                                qr/
                                    $TOKENS->{'year_abbr'}->{'regex'}
                                    $TOKENS->{'month'}->{'regex'}
                                    $TOKENS->{'day'}->{'regex'}
                                /x;
                            my $success = $part =~ $regex_date;
                            my %ymd = %+;
                            foreach my $token ('year_abbr', 'month', 'day') {
                                say "  $token ($ymd{$token})";
                                push @parser_parts, $TOKENS->{$token}->{'regex'};
                                $date->{$token} = $ymd{$token};
                            }
                        }
                    }
                    elsif (length($part) == 3 && defined($date->{'year'})) {
                        # day_of_year
                        say "  day_of_year ($part)" if $self->{'debug'};
                        push @parser_parts, $TOKENS->{'day_of_year'}->{'regex'};
                        $date->{'day_of_year'} = $part;
                    }
                    elsif (length($part) == 4) {
                        if (defined($date->{'year'}) || defined($date->{'year_abbr'})) {
                            # This is a concatenated time without seconds: HHMM
                            my $regex_time =
                                qr/
                                    $TOKENS->{'hour'}->{'regex'}
                                    $TOKENS->{'minute'}->{'regex'}
                                /x;
                            my $success = $part =~ $regex_time;
                            my %hm = %+;
                            foreach my $token ('hour', 'minute') {
                                if (! $TOKENS->{$token}->{'constraint'}->($hm{$token})) {
                                    warn "Error parsing $token: "
                                        . "value '$hm{$token}' out of range ($date_string)\n";
                                    return;
                                }
                                say "  $token ($hm{$token})";
                                push @parser_parts, $TOKENS->{$token}->{'regex'};
                                $date->{$token} = $hm{$token};
                            }
                        }
                        else {
                            # year (if month and day have not been set, order is now ymd).
                            my $token = $self->most_likely_token(
                                'possible_tokens' => ['year'],
                                'already_claimed' => $date,
                                'heuristic'       => ($order_string // $hint),
                                'date_string'     => $date_string,
                                'value'           => $part,
                            );
                            return if ! defined $token;
                            say "  $token ($part)" if $self->{'debug'};
                            push @parser_parts, $TOKENS->{$token}->{'regex'};
                            $date->{$token} = $part;
                            if (
                                ! defined($date->{'day'})
                                &&
                                ! defined($date->{'month'})
                                &&
                                ! defined($date->{'month_abbr'})
                                &&
                                ! defined($date->{'month_name'})
                            ) {
                                $order_string ||= 'ymd';
                            }
                        }
                    }
                    else {
                        # Either month, or day, or year (based on $order_string or $hint or what has been set already).
                        if (($order_string // $hint) eq 'dmy') {
                            my $token = $self->most_likely_token(
                                'possible_tokens' => ['day', 'month', 'year', 'year_abbr'],
                                'already_claimed' => $date,
                                'heuristic'       => ($order_string // $hint),
                                'date_string'     => $date_string,
                                'value'           => $part,
                            );
                            return if ! defined $token;
                            say "  $token ($part) based on " . ($order_string // $hint) if $self->{'debug'};
                            push @parser_parts, $TOKENS->{$token}->{'regex'};
                            $date->{$token} = $part;
                        }
                        elsif (($order_string // $hint) eq 'mdy') {
                            my $token = $self->most_likely_token(
                                'possible_tokens' => ['month', 'day', 'year', 'year_abbr'],
                                'already_claimed' => $date,
                                'heuristic'       => ($order_string // $hint),
                                'date_string'     => $date_string,
                                'value'           => $part,
                            );
                            return if ! defined $token;
                            say "  $token ($part) based on " . ($order_string // $hint) if $self->{'debug'};
                            push @parser_parts, $TOKENS->{$token}->{'regex'};
                            $date->{$token} = $part;
                        }
                        elsif (($order_string // $hint) eq 'ymd') {
                            my $token = $self->most_likely_token(
                                'possible_tokens' => ['year', 'year_abbr', 'month', 'day'],
                                'already_claimed' => $date,
                                'heuristic'       => ($order_string // $hint),
                                'date_string'     => $date_string,
                                'value'           => $part,
                            );
                            return if ! defined $token;
                            say "  $token ($part) based on " . ($order_string // $hint) if $self->{'debug'};
                            push @parser_parts, $TOKENS->{$token}->{'regex'};
                            $date->{$token} = $part;
                        }
                        else {
                            say "  number ($part)" if $self->{'debug'};
                            push @parser_parts, $regex_for_number;
                        }
                    }
                }
                elsif ($part =~ /^$regex_for_string$/) {
                    # TODO: Look for time zone abbreviation.
                    my $token = $self->most_likely_token(
                        'possible_tokens' => ['am_or_pm', 'era_abbr', 'month_name', 'month_abbr', 'day_name', 'day_abbr', 'phrase', 'time_zone'],
                        'already_claimed' => $date,
                        'date_string'     => $date_string,
                        'value'           => $part,
                    );
                    if ($token) {
                        if ($token eq 'month_name' || $token eq 'month_abbr') {
                            if (defined($date->{'month'})) {
                                say "  $token will need to take the place of month";
                                if (($order_string // $hint) =~ /md/) {
                                    say "  day ($date->{'month'}) moved from month" if $self->{'debug'};
                                    foreach my $parser_part (@parser_parts) {
                                        if ($parser_part =~ /\?<month>/) {
                                            $parser_part = $TOKENS->{'day'}->{'regex'};
                                        }
                                    }
                                    $date->{'day'} = delete $date->{'month'};
                                }
                            }
                        }
                        say "  $token ($part)" if $self->{'debug'};
                        push @parser_parts, $TOKENS->{$token}->{'regex'};
                        $date->{$token} = $part;
                    }
                    else {
                        say "  literal ($part)" if $self->{'debug'};
                        push @parser_parts, quotemeta($part);
                    }
                }
                elsif ($part =~ /^$regex_for_whitespace$/) {
                    say "  whitespace ($part)" if $self->{'debug'};
                    push @parser_parts, $regex_for_whitespace;
                }
                else {
                    say "  literal ($part)" if $self->{'debug'};
                    push @parser_parts, quotemeta($part);
                }
            }

            # If am_or_pm is pm, and hour is < 12, change from hour to hour_12 (and the parser).
            if (defined($date->{'am_or_pm'}) && lc($date->{'am_or_pm'}) eq 'pm' ) {
                if (defined($date->{'hour'}) && $date->{'hour'} < 12) {
                    $date->{'hour_12'} = delete $date->{'hour'};
                    foreach my $parser_part (@parser_parts) {
                        if ($parser_part =~ /\?<hour>/) {
                            $parser_part =~ s/\?<hour>/?<hour_12>/;
                        }
                    }
                }
            }
            my $parser_regex = join('', @parser_parts);
            say "Crafted regex: $date_string -> $parser_regex" if $self->{'debug'};

            # Add a new parser that will match this date format.
            if (! defined($known_parsers->{$parser_regex}) ) {
                $known_parsers->{$parser_regex} = 1;
                $self->add_parser(
                    $self->prepare_parser_for_regex_named_capture(
                        {
                            'regex' => qr/$parser_regex/,
                        },
                    ),
                );
                # Move the heuristic parser to the last slot again.
                push(
                    @{ $self->{'active_parsers'} },
                    splice(
                        @{ $self->{'active_parsers'} }, -2, 1
                    ),
                );
            }

            return $date;
        },
    );
}

=item prepare_formatter_for_arrayref()

Internal method called by L</"prepare_formatter()">.

=cut

sub prepare_formatter_for_arrayref {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'params'    => ArrayRef[Str],
            'structure' => Optional[Enum[qw(array arrayref)]],
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $structure = $definition->{'structure'} // 'arrayref';
    my $params = $definition->{'params'};

    state $sub_check = Type::Params::compile(
        HashRef,
    );

    return (
        sub {
            my ($date) = $sub_check->(@_);
            my @formatted = (
                map
                {
                    # Use the value, if available.
                    $date->{$_}
                    //
                    # Or see if we can determine the value by transforming another field.
                    $self->transform_token_value(
                        'target_token' => $_,
                        'date'         => $date,
                    )
                    //
                    # Or see if there is a default value for the field.
                    $self->{'defaults'}->{$_}
                    //
                    # Or just use a value of empty string.
                    ''
                }
                @$params,
            );
            return \@formatted if $structure eq 'arrayref';
            return @formatted;
        },
    );
}

=item prepare_formatter_for_hashref()

Internal method called by L</"prepare_formatter()">.

=cut

sub prepare_formatter_for_hashref {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'params'    => ArrayRef[Str],
            'structure' => Optional[Enum[qw(hash hashref)]],
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $structure = $definition->{'structure'} // 'hashref';
    my $params = $definition->{'params'};

    my @formatters = $self->prepare_formatter_for_arrayref(
        {
            'structure' => 'arrayref',
            'params'    => $params,
        },
    );

    state $sub_check = Type::Params::compile(
        ArrayRef,
    );

    push @formatters, (
        sub {
            my ($date) = $sub_check->(@_);
            my %formatted = ();
            @formatted{@$params} = @$date;
            return \%formatted if $structure eq 'hashref';
            return %formatted;
        },
    );
    return @formatters;
}

=item prepare_formatter_for_coderef()

Internal method called by L</"prepare_formatter()">.

=cut

sub prepare_formatter_for_coderef {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'params'  => ArrayRef[Str],
            'coderef' => CodeRef,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $coderef = $definition->{'coderef'};
    my $params = $definition->{'params'};

    my @formatters = $self->prepare_formatter_for_arrayref(
        {
            'structure' => 'array',
            'params'    => $params,
        },
    );

    push @formatters, (
        $coderef,
    );
    return @formatters;
}

=item prepare_formatter_for_sprintf()

Internal method called by L</"prepare_formatter()">.

=cut

sub prepare_formatter_for_sprintf {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'params'  => ArrayRef[Str],
            'sprintf' => Str,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $sprintf = $definition->{'sprintf'};
    my $params = $definition->{'params'};

    state $sub_check = Type::Params::compile(
        HashRef,
    );

    return (
        sub {
            my ($date) = $sub_check->(@_);
            my $formatted = sprintf(
                $sprintf,
                map
                {
                    # Use the value, if available.
                    $date->{$_}
                    //
                    # Or see if we can determine the value by transforming another field.
                    $self->transform_token_value(
                        'target_token' => $_,
                        'date'         => $date,
                    )
                    //
                    # Or see if there is a default value for the field.
                    $self->{'defaults'}->{$_}
                    //
                    # Or just use a value of empty string.
                    ''
                }
                @$params,
            );
            return $formatted;
        },
    );
}

=item prepare_formatter_for_strftime()

Internal method called by L</"prepare_formatter()">.

=cut

sub prepare_formatter_for_strftime {
    state $check = Type::Params::compile(
        Object,
        Dict[
            'strftime' => Str,
        ],
    );
    my ($self, $definition) = $check->(@_);

    my $strftime = $definition->{'strftime'};
    my $format = $strftime;
    my $params = [];

    # Preprocess some tokens that expand into other tokens.
    foreach my $preprocess (@$STRPTIME_PREPROCESS) {
        $format =~ s/$preprocess->{'token'}/$preprocess->{'replacement'}/g;
    }

    # Replace single character tokens with expanded tokens: %Y -> %{year}
    $format =~
        s/
            (%[-_^]?[%a-zA-Z])
        /
            $self->strftime_token_to_internal($1)
        /sgex;

    # Find all tokens.
    my @tokens = $format =~ m/(%\{\w+\})/g;

    # Replace tokens in order, and build $params list.
    foreach my $token (@tokens) {
        # Replace expanded tokens: %{year}
        if ($token =~ m/%\{(\w+)\}/) {
            my $internal = $1;
            my $sprintf = $TOKENS->{$internal}->{'sprintf'} //
                die "Unable to find sprintf definition for token '$internal'";

            say "Internal token $internal maps to sprintf token '$sprintf'." if $self->{'debug'};
            $format =~ s/\Q$token\E/$sprintf/;
            my $alias;
            if (defined($TOKENS->{$internal}->{'storage'})) {
                $alias = $TOKENS->{$internal}->{'storage'};
            }
            push @$params, ($alias // $internal);
        }
    }

    # Postprocess some tokens that expand into special characters.
    foreach my $postprocess (@$STRFTIME_POSTPROCESS) {
        $format =~ s/$postprocess->{'token'}/$postprocess->{'replacement'}/g;
    }

    say "Crafted sprintf: $strftime -> $format [" . join(', ', @$params) . "]" if $self->{'debug'};
    return $self->prepare_formatter_for_sprintf(
        {
            'sprintf' => $format,
            'params'  => $params,
        },
    );
}

=item strptime_token_to_regex()

Internal method called by L</"prepare_parser()">.

=cut

sub strptime_token_to_regex {
    state $check = Type::Params::compile(
        Object,
        Str,
    );
    my ($self, $token) = $check->(@_);

    my $internal;
    say "Attempting to convert strptime token $token into a regex." if $self->{'debug'};
    if (defined($self->{'strptime_mappings'}->{$token})) {
        $internal = $self->{'strptime_mappings'}->{$token};
    }
    elsif (defined($DEFAULT_STRPTIME_MAPPINGS->{$token})) {
        $internal = $DEFAULT_STRPTIME_MAPPINGS->{$token};
    }

    if (! defined($internal)) {
        say "No mapping found" if $self->{'debug'};
        return $token;  # Perform no substitution.
    }

    if (! defined($TOKENS->{$internal}->{'regex'})) {
        die "Unable to find regex definition for token '$internal'";
    }
    say "Strptime token $token maps to internal token '$internal'." if $self->{'debug'};

    return $TOKENS->{$internal}->{'regex'};
}

=item strftime_token_to_internal

Internal method called by L</"prepare_formatter()">.

=cut

sub strftime_token_to_internal {
    state $check = Type::Params::compile(
        Object,
        Str,
    );
    my ($self, $token) = $check->(@_);

    my $internal;
    say "Attempting to convert strftime token $token into an internal token." if $self->{'debug'};
    if (defined($self->{'strftime_mappings'}->{$token})) {
        $internal = $self->{'strftime_mappings'}->{$token};
    }
    if (defined($self->{'strptime_mappings'}->{$token})) {
        $internal = $self->{'strptime_mappings'}->{$token};
    }
    elsif (defined($DEFAULT_STRFTIME_MAPPINGS->{$token})) {
        $internal = $DEFAULT_STRFTIME_MAPPINGS->{$token};
    }
    elsif (defined($DEFAULT_STRPTIME_MAPPINGS->{$token})) {
        $internal = $DEFAULT_STRPTIME_MAPPINGS->{$token};
    }

    if (! defined($internal)) {
        say "No mapping found" if $self->{'debug'};
        return '%' . $token;  # Perform no substitution, but escape token for sprintf.
    }

    if (! defined($TOKENS->{$internal}->{'sprintf'})) {
        die "Unable to find sprintf definition for token '$internal'";
    }
    say "Strftime token $token maps to internal token '$internal'." if $self->{'debug'};

    return '%{' . $internal . '}';
}

=item transform_token_value()

Internal method called by L</"prepare_formatter()">.

=cut

sub transform_token_value {
    state $check = Type::Params::compile(
        Object,
        slurpy Dict[
            'target_token' => Str,
            'date'         => HashRef,
        ],
    );
    my ($self, $args) = $check->(@_);

    my $target_token = $args->{'target_token'};
    my $date = $args->{'date'};

    # Return the value, if it is already set.
    return $date->{$target_token} if defined($date->{$target_token});

    foreach my $transformations ($self->{'transformations'}, $DEFAULT_TRANSFORMATIONS) {
        # Look up transformations to $target_token from a field that is defined in $date.
        if (defined($transformations->{$target_token})) {
            foreach my $source_token (keys %{$transformations->{$target_token}}) {
                if (defined($date->{$source_token}) && defined($transformations->{$target_token}->{$source_token})) {
                    # Run the transformation and return the value.
                    return $transformations->{$target_token}->{$source_token}->($date);
                }
            }
        }
    }

    return;
}

=item most_likely_token()

Internal method called by L</"prepare_parser()">.

=cut

sub most_likely_token {
    state $check = Type::Params::compile(
        Object,
        slurpy Dict[
            'already_claimed' => Optional[HashRef],
            'possible_tokens' => ArrayRef,
            'heuristic'       => Optional[Str],
            'value'           => Str,
            'date_string'     => Optional[Str],
        ],
    );
    my ($self, $args) = $check->(@_);

    my $already_claimed = $args->{'already_claimed'} // {};
    my $possible_tokens = $args->{'possible_tokens'};
    my $hint = $args->{'heuristic'} // '';
    my $date_part = $args->{'value'};
    my $date_string = $args->{'date_string'} // $date_part;

    foreach my $token (@$possible_tokens) {
        if ($token eq 'day') {
            next if defined($already_claimed->{'day'});
            next if ($date_part !~ /^$TOKENS->{$token}->{'regex'}$/);
            if ($date_part > 31) {
                warn "Error parsing day: "
                    . "value '$date_part' out of range ($date_string); "
                    . "Perhaps you need a different heuristic hint than '$hint'\n";
                return;
            }
            return $token;
        }
        if ($token eq 'month') {
            next if defined($already_claimed->{'month'});
            next if defined($already_claimed->{'month_abbr'});
            next if defined($already_claimed->{'month_name'});
            next if ($date_part !~ /^$TOKENS->{$token}->{'regex'}$/);
            if ($date_part > 12) {
                warn "Error parsing month: "
                    . "value '$date_part' out of range ($date_string); "
                    . "Perhaps you need a different heuristic hint than '$hint'\n";
                return;
            }
            return $token;
        }
        if ($token eq 'year' || $token eq 'year_abbr') {
            next if defined($already_claimed->{'year'});
            next if defined($already_claimed->{'year_abbr'});
            next if ($date_part !~ /^$TOKENS->{$token}->{'regex'}$/);
            return $token;
        }

        # Any other type of token does not need special handling.
        next if defined($already_claimed->{$token});
        next if ($date_part !~ /^$TOKENS->{$token}->{'regex'}$/);
        return $token;
    }

    if ($hint) {
        warn "Error parsing $possible_tokens->[0]: "
            . "elements out of order ($date_string); "
            . "Perhaps you need a different heuristic hint than '$hint'\n";
    }

    return;
}


=item add_parser()

Adds a parser to the active parsers.  When parsing a date string,
the parser will be called if each preceeding parser has failed to
parse the date.

See L</"prepare_parser()"> for generating a parser in the correct
format.

    $reformat->add_parser(
        $reformat->prepare_parser( ... ),
    );

=cut

sub add_parser {
    state $check = Type::Params::compile(
        Object,
        slurpy ArrayRef[CodeRef],
    );
    my ($self, $parsers) = $check->(@_);

    my $count = push @{ $self->{'active_parsers'} }, @$parsers;
    return $count ? 1 : 0;
}

=item add_formatter()

Adds a formatter to the active formatters.  When formatting a date,
the formatter will be called after each preceeding formatter, receiving
as input the output from the previous formatter.

See L</"prepare_formatter()"> for generating a formatter in the correct
format.

    $reformat->add_formatter(
        $reformat->prepare_formatter( ... ),
    );

=cut

sub add_formatter {
    state $check = Type::Params::compile(
        Object,
        slurpy ArrayRef[CodeRef],
    );
    my ($self, $formatters) = $check->(@_);

    my $count = push @{ $self->{'active_formatters'} }, @$formatters;
    return $count ? 1 : 0;
}

=item parse_date()

Given a date string, attempts to parse it via the active parsers.
Returns a hashref containing the tokens that were extracted
from the date string.

    my $date_hashref = $reformat->parse_date($date_string);

=cut

sub parse_date {
    state $check = Type::Params::compile(
        Object,
        Str,
    );
    my ($self, $date_string) = $check->(@_);

    state $has_parser = ArrayRef[CodeRef];
    if (! $has_parser->($self->{'active_parsers'}) ) {
        die "No parsers defined. Have you called add_parser()?";
    }

    foreach my $parser (@{ $self->{'active_parsers'} }) {
        my $date = $parser->($date_string);
        return $date if defined($date);
    }
    # None of the parsers were able to extract the date components.
    return;
}

=item format_date()

Given a hashref containing the tokens that were extracted from a
date string, formats the date using each of the active parsers,
passing the output from the previous formatter to the next formatter.

    my $date_string = $reformat->format_date($date_hashref);

=cut

sub format_date {
    state $check = Type::Params::compile(
        Object,
        Maybe[HashRef],
    );
    my ($self, $date) = $check->(@_);

    return if ! defined($date);

    state $has_formatter = ArrayRef[CodeRef];
    if (! $has_formatter->($self->{'active_formatters'}) ) {
        die "No formatters defined. Have you called add_formatter()?";
    }

    my @formatted = ($date);
    foreach my $formatter (@{ $self->{'active_formatters'} }) {
        @formatted = $formatter->(@formatted);
    }
    return $formatted[0] if (scalar(@formatted) == 1);
    return @formatted;
}

=item reformat_date()

Given a date string, attempts to parse it and format it using the
active parsers and formaters.

    my $date_string = $reformat->reformat_date($date_string);

=cut

sub reformat_date {
    state $check = Type::Params::compile(
        Object,
        Str,
    );
    my ($self, $date_string) = $check->(@_);

    my $date = $self->parse_date($date_string);
    my @formatted = $self->format_date($date);
    return $formatted[0] if (scalar(@formatted) == 1);
    return @formatted;
};

=back

=cut

1;
__END__
=head1 SEE ALSO

=over 4

=item Date::Transform

=item Date::Parse

=item Date::Format

=item DateTime::Format::Flexible

=item DateTime::Format::Builder

=back

=head1 AUTHOR

Nathan Gray E<lt>kolibrie@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Nathan Gray

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
