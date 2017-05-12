use strict;
use warnings;
use Test::More;
use Test::LongString;
use File::Temp;
use HTTP::Request;
use LWP::UserAgent;

plan(tests => 47);

require_ok('CGI');
require_ok('CGI::Application::MailPage');
my $options = {
    page         => 'http://unused/test.html',
    rm           => 'send_mail',
    name         => 'Sammy Sender',
    from_email   => 'sam@tregar.com',
    subject      => 'Test Subject',
    to_emails    => 'sam@tregar.com',
    note         => '',
    format       => 'both_attachment',
};

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REMOTE_ADDR} = '123.45.67.89';
my $good_url = 'http://www.perl.com';


# 3-4
# test a the 'both_attachment' format
{
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    contains_string($mail, 'This is the test HTML page', 'Test page as both');
    contains_string($mail, 'X-Originating-Ip: 123.45.67.89');
}

# 5 
# test a the 'html' format
{
    $options->{format} = 'html';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /<H1>This is the test HTML page<\/H1>/, 'Test page as HTML');
}

# 6 
# test a the 'html_attachment' format
{
    $options->{format} = 'html_attachment';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /<H1>This is the test HTML page<\/H1>/, 'Test page as HTML attachment');
}

# 7 
# test a the 'text' format
{
    $options->{format} = 'text';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /This is the test HTML page/, 'Test page as text');
}

# 8 
# test a the 'text_attachment' format
{
    $options->{format} = 'text_attachment';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ /This is the test HTML page/, 'Test page as text_attachment');
}


# 9 
# test the 'url' format
{
    $options->{format} = 'url';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://unused/test.html!, 'Test page as url');
}

# 10
# test an acceptable domain in 'acceptable_domains' option
{
    $options->{format} = 'url';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            acceptable_domains => [qw(unused)],
        }
    );
    my $output = $mailpage->run();
    die if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://unused/test.html!, 'Acceptable Domain');
}

# 11
# test an unacceptable domain in 'acceptable_domains' option 
{
    $options->{format} = 'url';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            acceptable_domains => [qw(acceptable.com)],
        }
    );
    my $output = $mailpage->run();
    ok($output =~ m!not acceptable!, 'Domain Not Acceptable');
}

# 12
# test the 'extra_tmpl_params'
{
    $options->{format} = 'url';
    $options->{rm} = 'show_form';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            extra_tmpl_params => {
                note => 'This is my note.',
            },
        }
    );
    my $output = $mailpage->run();
    ok($output =~ m!This is my note.!, 'extra_tmpl_params overrides');
}

# 13
# test the 'remote_fetch' with a bad url
{
    $options->{rm} = 'send_mail';
    $options->{format} = 'both_attachment';
    $options->{page} = 'http://unused/test.html';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    ok($output =~ m!Unable to retrieve!i, 'remote_fetch invalid url');
}

# 14
# test the 'remote_fetch' with a good url with 'both_attachment'
# only if we can GET that url
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'both_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://google\.com!, 'remote_fetch valid url (both_attachment)');
}

# 15
# test the 'remote_fetch' with a good url with 'html'
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'html';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!<title>Google</title>!, 'remote_fetch valid url (html)');
}

# 16
# test the 'remote_fetch' with a good url with 'html_attachment'
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'html_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!<title>Google</title>!, 'remote_fetch valid url (html)');
}

# 17
# test the 'remote_fetch' with a good url with 'text'
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'text';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!Google!, 'remote_fetch valid url (html)');
}
                                                                                                                                           
# 18
# test the 'remote_fetch' with a good url with 'text_attachment'
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'text_attachment';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!Google!, 'remote_fetch valid url (html)');
}

# 19
# test the 'remote_fetch' with a good url with 'url'
SKIP: {
    skip("Can't GET $good_url", 1) unless
        can_get($good_url);
    $options->{rm} = 'send_mail';
    $options->{format} = 'url';
    $options->{page} = 'http://google.com';
    my $query = CGI->new($options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            remote_fetch => 1,
        }
    );
    my $output = $mailpage->run();
    die $output if($output !~ /Mail Dumped/);
    ok($mail =~ m!http://google.com!, 'remote_fetch valid url (url)');
}

# 20..39
# test default and custom validation_profile
{
    # some missing stuff
    my %local_options = (
        note        => "x a " x 100,
        rm          => 'send_mail',
        page        => 'http://unused/test.html',
    );
    my $query = CGI->new(\%local_options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    my $output = $mailpage->run();
    contains_string($output, "Your submission has errors");
    contains_string($output, "Please fill in your name in the form below");
    contains_string($output, "Please fill in your email address in the form below.");
    contains_string($output, "Please fill in your friends' email addresses in the form below.");
    contains_string($output, "Please enter a Subject for the email in the form below.");
    contains_string($output, "That is not an acceptable format!");

    # some invalid stuff
    %local_options = (
        name        => "This is\na hack!",
        subject     => "xx" x 50,
        from_email  => 'stuyfffff',
        to_emails   => "stuff me you and more stuff",
        note        => "x a " x 100,
        format      => "junk",
        page        => 'http://unused/test.html',
        rm          => 'send_mail',
    );
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
        }
    );
    $output = $mailpage->run();
    contains_string($output, "Your submission has errors");
    contains_string($output, "That name is too long or contains unnacceptable characters.");
    contains_string($output, "That is not a valid email address.");
    contains_string($output, "One of your friend's email addresses is not valid");
    contains_string($output, "That Subject is too long or contains unnacceptable characters.");
    contains_string($output, "That is not an acceptable format!");
    contains_string($output, "Sorry, that note is too long!");

    # override the subject to allow 100 characters and the format
    # to only allow the format 'url'
    %local_options = (
        %local_options,
        format  => 'html_attachment',
    );
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            validation_profile => {
                constraints => {
                    subject => qr/^[a-zA-Z0-9 ]{1,100}$/,
                    format  => sub { 
                        my $val = shift; 
                        return $val if( $val eq 'url' ); 
                        return; 
                    },
                },
            },
        },
    );
    $output = $mailpage->run();
    contains_string($output, "Your submission has errors");
    contains_string($output, "That name is too long or contains unnacceptable characters.");
    contains_string($output, "That is not a valid email address.");
    contains_string($output, "One of your friend's email addresses is not valid");
    lacks_string($output, "That Subject is too long or contains unnacceptable characters.");
    contains_string($output, "That is not an acceptable format!");
    contains_string($output, "Sorry, that note is too long!");

    # TODO - perhaps further stress the profile itself without having to worry about
    # the web interface
}

# 40..43
# test max_emails_per_request
{
    # send 5 but have a limit of 3
    my %local_options = (
        %$options,
        to_emails   => 'sam@tregar.com mpeters@plusthree.com, stupid@silly.com liar@untruth.com,  gone@nothere.com',  
    );
    my $query = CGI->new(\%local_options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_request => 3,
        }
    );
    my $output = $mailpage->run();
    contains_string($output, "Your submission has errors");
    contains_string($output, "exceeded the limit of emails to send.");

    # make the limit 5
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_request => 5,
        }
    );
    $output = $mailpage->run();
    lacks_string($output, "Your submission has errors");
    lacks_string($output, "exceeded the limit of emails to send.");
}

# 44..47
# test max_emails_per_hour
{
    # setup a temp file.
    my $tmp = File::Temp->new(
        UNLINK  => 0,
    ) or die "Could not open temp file! $!";
    my $file_name = $tmp->filename();
    close($tmp) or die "Could not close temp file! $!";

    # send 5 with an hourly limit of 9
    my %local_options = (
        %$options,
        to_emails   => 'sam@tregar.com mpeters@plusthree.com, stupid@silly.com liar@untruth.com,  gone@nothere.com',
    );
    my $query = CGI->new(\%local_options);
    my $mail;
    my $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_hour => 9,
            max_emails_per_hour_file => $file_name,
        }
    );
    my $output = $mailpage->run();
    lacks_string($output, "Your submission has errors");

    # send 5 again to exceed limit of 9
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_hour => 9,
            max_emails_per_hour_file => $file_name,
        }
    );
    $output = $mailpage->run();
    contains_string($output, "Hourly limit on emails exceeded!");

    # open the file, reset the time and try again
    open(my $FH, '>', $file_name) 
        or die "Could not open $file_name for reading! $!";
    my $time = time() - (61 * 61);  # a little more than an hour before
    my $new_count = 2;
    print $FH "$time:$new_count";
    close($FH)
        or die "Could not close $file_name! $!";
    
        
    # send 5 again to put new total at 7, still below 9
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_hour => 9,
            max_emails_per_hour_file => $file_name,
        }
    );
    $output = $mailpage->run();
    lacks_string($output, "Hourly limit on emails exceeded!");

    # send 5 again to push us over again
    $query = CGI->new(\%local_options);
    $mailpage = CGI::Application::MailPage->new(
        QUERY => $query,
        PARAMS => {
            document_root => './',
            smtp_server => 'unused',
            dump_mail => \$mail,
            use_page_param => 1,
            max_emails_per_hour => 9,
            max_emails_per_hour_file => $file_name,
        }
    );
    $output = $mailpage->run();
    contains_string($output, "Hourly limit on emails exceeded!");
    
    # now remove the temp file
    unlink($file_name) or die "Could not remove temp file $file_name! $!";
}


sub can_get {
    my $url = shift;
    my $agent = LWP::UserAgent->new();
    $agent->timeout(5);
    my $response = $agent->get($good_url);
    return $response->is_success;
}


