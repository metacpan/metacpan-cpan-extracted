package DTL::Fast::Filters;
use strict; use utf8; use warnings FATAL => 'all'; 

use DTL::Fast qw(register_filter);
# not in Django

# experimental
register_filter(qw(
    numberformat        DTL::Fast::Filter::Numberformat
    reverse             DTL::Fast::Filter::Reverse
    strftime            DTL::Fast::Filter::Strftime
    split               DTL::Fast::Filter::Split
));

# built in filters
register_filter(qw(
    add                 DTL::Fast::Filter::Add
    addslashes          DTL::Fast::Filter::Addslashes
    capfirst            DTL::Fast::Filter::Capfirst
    center              DTL::Fast::Filter::Center
    cut                 DTL::Fast::Filter::Cut
    date                DTL::Fast::Filter::Date
    default             DTL::Fast::Filter::Default
    default_if_none     DTL::Fast::Filter::DefaultIfNone
    dictsort            DTL::Fast::Filter::Dictsort
    dictsortreversed    DTL::Fast::Filter::Dictsortreversed
    divisibleby         DTL::Fast::Filter::Divisibleby
    escape              DTL::Fast::Filter::Escape
    escapejs            DTL::Fast::Filter::Escapejs
    filesizeformat      DTL::Fast::Filter::Filesizeformat
    first               DTL::Fast::Filter::First
    floatformat         DTL::Fast::Filter::Floatformat
    force_escape        DTL::Fast::Filter::Escape
    get_digit           DTL::Fast::Filter::Getdigit
    iriencode           DTL::Fast::Filter::Iriencode
    join                DTL::Fast::Filter::Join
    last                DTL::Fast::Filter::Last
    length              DTL::Fast::Filter::Length
    length_is           DTL::Fast::Filter::Lengthis
    linebreaks          DTL::Fast::Filter::Linebreaks
    linebreaksbr        DTL::Fast::Filter::Linebreaksbr
    linenumbers         DTL::Fast::Filter::Linenumbers
    ljust               DTL::Fast::Filter::Ljust
    lower               DTL::Fast::Filter::Lower
    make_list           DTL::Fast::Filter::MakeList
    phone2numeric       DTL::Fast::Filter::PhoneToNumeric
    pluralize           DTL::Fast::Filter::Pluralize
    random              DTL::Fast::Filter::Random
    removetags          DTL::Fast::Filter::Removetags
    rjust               DTL::Fast::Filter::Rjust
    safe                DTL::Fast::Filter::Safe
    safeseq             DTL::Fast::Filter::SafeSeq
    slice               DTL::Fast::Filter::Slice
    slugify             DTL::Fast::Filter::Slugify
    stringformat        DTL::Fast::Filter::Stringformat
    striptags           DTL::Fast::Filter::Striptags
    time                DTL::Fast::Filter::Time
    timesince           DTL::Fast::Filter::Timesince
    timeuntil           DTL::Fast::Filter::Timeuntil
    title               DTL::Fast::Filter::Title
    truncatechars       DTL::Fast::Filter::Truncatechars
    truncatechars_html  DTL::Fast::Filter::Truncatecharshtml
    truncatewords       DTL::Fast::Filter::Truncatewords
    truncatewords_html  DTL::Fast::Filter::Truncatewordshtml
    unordered_list      DTL::Fast::Filter::Unorderedlist
    upper               DTL::Fast::Filter::Upper
    urlencode           DTL::Fast::Filter::Urlencode
    urlize              DTL::Fast::Filter::Urlize
    urlizetrunc         DTL::Fast::Filter::Urlizetrunc
    wordcount           DTL::Fast::Filter::Wordcount
    wordwrap            DTL::Fast::Filter::Wordwrap
    yesno               DTL::Fast::Filter::Yesno
));

1;
