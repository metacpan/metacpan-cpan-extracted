use Dwarf::Pragma;
use Benchmark ':all';
use Dwarf;
use Dwarf::Validator;
use FormValidator::Lite qw/Email Date/; 
use Plack::Request;

say "Perl: $]";
say "Dwarf: $Dwarf::VERSION";
say "FVL: $FormValidator::Lite::VERSION";

my $C = 5000;

my $q = Plack::Request->new(
    {
        QUERY_STRING   => 'param1=ABCD&param2=12345&mail1=lyo.kato@gmail.com&mail2=lyo.kato@gmail.com&year=2005&month=11&day=27',
        REQUEST_METHOD => 'POST',
        'psgi.input'   => *STDIN,
    },
);

cmpthese(
    $C => {
        'FormValidator::Lite' => sub {
            my $result = FormValidator::Lite->new($q)->check(
                param1 => [ 'NOT_BLANK', 'ASCII', [ 'LENGTH', 2, 5 ] ],
                param2 => [ 'NOT_BLANK', 'INT' ],
                mail1  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                mail2  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                { mails => [ 'mail1', 'mail2' ] } => ['DUPLICATION'],
                { date => [ 'year', 'month', 'day' ] } => ['DATE'],
            );
        },
        'Dwarf::Validator' => sub {
            my $result = Dwarf::Validator->new($q)->check(
                param1 => [ 'NOT_BLANK', 'ASCII', [ 'LENGTH', 2, 5 ] ],
                param2 => [ 'NOT_BLANK', 'INT' ],
                mail1  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                mail2  => [ 'NOT_BLANK', 'EMAIL_LOOSE' ],
                { mails => [ 'mail1', 'mail2' ] } => ['DUPLICATION'],
                { date => [ 'year', 'month', 'day' ] } => ['DATE'],
            );
        },
    },
);

