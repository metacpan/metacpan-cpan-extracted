package MyTest::AJAXBase;
use base 'MyTest::Base';
use Test::More;
use Test::LongString;
use File::Spec::Functions qw(catfile);

my $SUGGEST_FILE = catfile('t', 'conf', 'index_words');

sub B_ajax_search: Test(9) {
    my $self = shift;

    # simple word 'please'
    # no higlighting
    my $cgi = CGI->new({
        rm          => 'perform_search',
        keywords    => 'please',
        ajax        => 1,
    });
    my $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            HIGHLIGHT => 0,
        },
    );
    $output = $app->run();
    lacks_string($output, '<h2>Search Results</h2>');
    lacks_string($output, 'No results');
    like($output, qr/Elapsed Time: \d\.\d{1,3}s/i);
    like($output, qr/>\w+ \d\d?, 20\d\d - \d+(K|M|G)?</i);
    contains_string($output, 'This is a Test');
    contains_string($output, 'Please Help Me');
    contains_string($output, 'This is a test. This is a only a test. And please do not panic.');
    contains_string($output, 'Would you please help me find this document');
    contains_string($output, 'Results: 1 to 2 of 2');
    
    # set back to empty
    %MyTest::Base::BASE_CGI_PARAMS = ();
}

sub L_suggestions: Test(12) {
    my $self = shift;
    my @p_words = qw(
        panic
        paragraph
        please
        porta
        praesent
        pretium
        proin
    );
    my $cgi = CGI->new({
        rm          => 'suggestions',
        keywords    => 'p',
        ajax        => 1,
    });

    # with no limit
    my $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST      => 1,
            AUTO_SUGGEST_FILE => $SUGGEST_FILE,
        },
    );
    $output = $app->run();
    my $full_regex = join('.*', map { quotemeta($_) } @p_words);
    like($output, qr/$full_regex/);

    # now set a limit
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_LIMIT => 2,
            AUTO_SUGGEST_FILE  => $SUGGEST_FILE,
        },
    );
    $output = $app->run();
    my $partial_regex = join('.*', map { quotemeta($_) } @p_words[0..1]);
    unlike($output, qr/$full_regex/);
    like($output, qr/$partial_regex/);

    # with no limit cached
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_CACHE => 1,
            AUTO_SUGGEST_FILE  => $SUGGEST_FILE,
        },
    );
    $output = $app->run();
    like($output, qr/$full_regex/);

    # now set a limit with cached
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_LIMIT => 2,
            AUTO_SUGGEST_CACHE => 1,
            AUTO_SUGGEST_FILE  => $SUGGEST_FILE,
        },
    );
    $output = $app->run();
    unlike($output, qr/$full_regex/);
    like($output, qr/$partial_regex/);

    # multiple words
    $cgi = CGI->new({
        rm          => 'suggestions',
        keywords    => 'stuff p',
        ajax        => 1,
    });
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_LIMIT => 2,
            AUTO_SUGGEST_CACHE => 1,
            AUTO_SUGGEST_FILE  => $SUGGEST_FILE,
        },
    );
    $output = $app->run();
    $partial_regex = join('.*', map { quotemeta("stuff $_") } @p_words[0..1]);
    like($output, qr/$partial_regex/);

    # without specifiying a file
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_LIMIT => 2,
        },
    );
    $self->_throw_away_stderr();
    $output = $app->run();
    $self->_restore_stderr();
    contains_string($output, '<ul></ul>');
    contains_string($self->_stderr_junk(), 'AUTO_SUGGEST_FILE was not specified!');

    # without a readable file
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
            AUTO_SUGGEST       => 1,
            AUTO_SUGGEST_LIMIT => 2,
            AUTO_SUGGEST_FILE  => 'foo.txt',
        },
    );
    $self->_throw_away_stderr();
    $output = $app->run();
    $self->_restore_stderr();
    contains_string($output, '<ul></ul>');
    contains_string($self->_stderr_junk(), 'AUTO_SUGGEST_FILE foo.txt is not readable!');

    # without AUTO_SUGGEST
    $app = CGI::Application::Search->new(
        QUERY   => $cgi,
        PARAMS  => {
            %MyTest::Base::BASE_OPTIONS,
            $self->options,
        },
    );
    $self->_throw_away_stderr();
    $output = $app->run();
    $self->_restore_stderr();
    contains_string($self->_stderr_junk(), 'without AUTO_SUGGEST turned on');
}

1;


