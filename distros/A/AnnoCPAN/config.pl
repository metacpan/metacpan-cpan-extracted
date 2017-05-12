# This is a sample AnnoCPAN configuration file. It is Perl code and
# should return a hashref
{
    # database configuration options
    dsn         =>'dbi:mysql:annocpan2;mysql_socket=/var/lib/mysql/mysql.sock',
    db_user     => '',
    db_passwd   => '',

    annopod_dsn => 'dbi:SQLite:dbname=annopod.db',

    # local CPAN mirror
    cpan_root   => '/home/ivan/CPAN',

    # site options
    recent_notes   => 25,
    min_similarity => 0.5,
    cache_html     => 0,
    pre_line_wrap  => 72,
    template_path  => '../tt',
    cookie_duration => 3000,
    secret          => 'life is like a box of chocolates',

    # default user preferences
    js          => 1,
    tol         => 60.0,
    style       => 'side',
    prefs       => [qw(js tol style)],

    # webspace parameters
    root_uri_abs => 'http://annocpan.org',
    root_uri_rel => '',
    img_root     => '/img',

}
