use Module::Build;
my $build = Module::Build->new (
    module_name => 'CGI::Application::MailPage',
    license => 'perl',
    requires => {
        'perl'                => '5.6.1',
        'CGI::Application'    => '3.2',
        'File::Spec'          => '0',
        'HTML::Template'      => '0',
        'HTML::TreeBuilder'   => '0',
        'HTTP::Date'          => '0',
        'MIME::Entity'        => '0',
        'Mail::Header'        => '0',
        'Mail::Internet'      => '0',
        'Net::SMTP'           => '0',
        'Text::Format'        => '0',
        'URI'                 => '0',
        'HTTP::Request'       => '0',
        'LWP::UserAgent'      => '0',
        'Email::Valid'        => '0',
        'Data::FormValidator' => '3',
        'Fcntl'               => '0',
    },
    build_requires => {
        'Test::LongString'  => '0',
    },
    pm_files => {
        'lib/CGI/Application/MailPage.pm' => 'lib/CGI/Application/MailPage.pm', 
        'templates/email.tmpl' => 'lib/CGI/Application/MailPage/templates/email.tmpl',
        'templates/error.tmpl' => 'lib/CGI/Application/MailPage/templates/error.tmpl',
        'templates/form.tmpl' => 'lib/CGI/Application/MailPage/templates/form.tmpl',
        'templates/thanks.tmpl' => 'lib/CGI/Application/MailPage/templates/thanks.tmpl',
    },
);
$build->create_build_script;
