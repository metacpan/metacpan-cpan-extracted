use Coat::Persistent;
Coat::Persistent->map_to_dbi('csv', "f_dir=./t/fixtures;csv_eol=\n;csv_sep_char=,;csv_quote_char=\";csv_escape_char=");

$SIG{__WARN__} = sub
{
    my @loc = caller(1);
    die "Warning generated at line $loc[2] in $loc[1]:\n", @_;
};

