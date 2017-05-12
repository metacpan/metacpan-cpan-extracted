package Dancer::Plugin::Test::Jasmine;
BEGIN {
  $Dancer::Plugin::Test::Jasmine::AUTHORITY = 'cpan:YANICK';
}
# ABSTRACT: Inject and run Jasmine tests in your web pages
$Dancer::Plugin::Test::Jasmine::VERSION = '0.2.0';

use strict;
use warnings;

use File::ShareDir::Tarball;

use Dancer ':syntax';
use Dancer::Plugin;
use Path::Tiny;

use Moo;
with 'MooX::Singleton';

has library_dir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        path(
            plugin_setting->{lib_dir} 
                || File::ShareDir::Tarball::dist_dir('Dancer-Plugin-Test-Jasmine') 
        );
    },
);

has specs_dir => (
    is => 'ro',
    lazy => 1,
    default => sub {
        path( config->{appdir}, plugin_setting->{specs_dir} || 't/specs' );
    },
);

has url_prefix => (
    is => 'ro',
    lazy => 1,
    default => sub {
        plugin_setting->{prefix} || '/test';
    },
);

for my $thing ( map { 'additional_' . $_ } qw/ scripts css / ) {
    has $thing => (
        is => 'ro',
        lazy => 1,
        default => sub {
            plugin_setting->{$thing} || [];
        },
    );
}

my $plugin = __PACKAGE__->instance;

hook before => sub {
    var jasmine_tests => param('test') ? [ param_array('test') ] : undef;
};

hook after => sub {
    my $resp = shift;

    my $tests = var 'jasmine_tests' or return;

    my $body = $resp->content;

    $body =~ s#(?=</head>)# _jasmine_includes() #ie;
    $body =~ s#(?=</body>)# _jasmine_tests()    #ie;

    $resp->content($body);

};

sub _jasmine_includes { 
    return '' unless var 'jasmine_tests';

    my $prefix = $plugin->url_prefix;

    return <<"END";
        <link rel="stylesheet" href="$prefix/lib/jasmine.css">
        @{[ map { sprintf "<link rel='stylesheet' href='$_'>" } @{ $plugin->additional_css } ]}
        <style>
            div.jasmine_html-reporter {
                position:  absolute;
                top: 0px;
                left: 0px;
                width: 400px;
                border: 1px solid black;
                background-color: white;
                padding: 3em;
            }
        </style>

        <script src="$prefix/lib/jasmine.js"></script>e
        <script src="$prefix/lib/jasmine-html.js"></script>
        <script src="$prefix/lib/boot.js"></script>
        <script src="$prefix/lib/jasmine-jsreporter.js"></script>
        <script src="$prefix/lib/jasmine-jquery.js"></script>
        @{[ map { sprintf "<script src='$_'></script>" } @{ $plugin->additional_scripts } ]}
END
};

sub _jasmine_tests { 
    my $tests =  var 'jasmine_tests' or return '';

    my $prefix = $plugin->url_prefix;

    my $js = <<'END';
        <script>
        jasmine.getEnv().addReporter(new jasmine.JSReporter2());
        </script>
END

    $js .= $_ for map { qq{<script src="$prefix/specs/$_"></script>} } 
                  map { $_ . '.js' } @$tests;

    return $js;
};

prefix $plugin->url_prefix => sub {

    get '/lib/:file' => sub {
        my $file = $plugin->library_dir->child(param 'file');
        
        send_error "file not found", 404 unless -f $file;

        send_file $file, system_path => 1;
    };

    get '/specs/**' =>  sub {
        my $file = $plugin->specs_dir->child( @{ (splat())[0] } );

        send_error "file not found", 404 unless -f $file;

        send_file $file, system_path => 1;
    };
};


register_plugin;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Test::Jasmine - Inject and run Jasmine tests in your web pages

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

In F<config.yml>:

    plugins:
        'Test::Jasmine':
            specs_dir: t/specs
            prefix: /test
            lib_dir: /path/to/jasmine/dir
            additional_scripts:
                - /uri/to/script.js
            additional_css:
                - /usr/to/other.css

In application:

    package MyApp;

    use Dancer;

    use if $ENV{DANCER_ENVIRONMENT} eq 'development', 
        'Dancer::Plugin::Test::Jasmine';

    ...;

=head1 DESCRIPTION

This plugin helps running L<Jasmine|http://jasmine.github.io> tests for your Dancer application.

If the plugin is enabled, a request with queries having one or more C<test> fields will
make the application inject the Jasmine library and the tests in the response (if no C<test>
parameter is present, the response is left untouched). The library is injected
at the end of the head section of the page, and the tests at the end of its body.

To incorporate those tests to your Perl test suites, see
L<Dancer::Plugin::Test::Jasmine::Results>.

In addition to Jasmine itself, this plugin also load
L<jasmine-jquery|https://github.com/velesin/jasmine-jquery>.

=head1 CONFIGURATION PARAMETERS

=over

=item specs_dir 

The directory where the Jasmine tests are to be found.  Defauls to C<t/specs>.

=item prefix

The uri prefix under which the Jasmine library and the Jasmine
specs files will be available . Defaults to C</test>.

=item lib_dir

By default the plugin uses a version of Jasmine and its JSON reporter bundled
in its share folder. If you prefer to use your own version of 
Jasmine, you can specify its directory via this parameter.

=item additional_scripts

=item additional_css

If specified, the plugin will include those scripts
and css files in addition of (and after) the Jasmine stuff. The paths 
are just the straight uris where to find those files.

For example, to test an Angular application one can add:

    plugins:
        Test::Jasmine:
            additional_scripts:
                - /js/angular-mocks.js

=back

=head1 RUNNING TESTS AS PART OF PERL TEST SUITES

Obviously, the tests need to be run from within 
a browser with a JavaScript engine. But if you desire to have the
tests included in your regular test suites, there are
several test modules allowing interactions (L<Test::WWW::Selenium>,
L<WWW::Mechanize::PhantomJS>) with browsers. 

In addition of the regular HTML report, the Jasmine test results are also
accessible via the JavaScipt function C<jasmine.getJSReportAsString()>,
thanks to the 
L<Jasmine-jsreporter|https://github.com/detro/jasmine-jsreporter> plugin. The module L<Dancer::Plugin::Test::Jasmine::Results> 
provides a helper function C<jasmine_results> that takes in the Jasmine results, and
produce equivalent TAP output.

=head2 WWW::Mechanize::PhantomJS

For example, if we wanted to run the test 't/specs/verify_title.js' via 
PhantomJS, we could use:

    use strict;
    use warnings;

    use Test::More;

    use JSON qw/ from_json /;

    use Test::TCP;
    use WWW::Mechanize::PhantomJS;

    use Dancer::Plugin::Test::Jasmine::Results;

    Test::TCP::test_tcp(
        client => sub {
            my $port = shift;

            my $mech = WWW::Mechanize::PhantomJS->new;

            $mech->get("http://localhost:$port?test=verify_title");

            jasmine_results from_json
                $mech->eval_in_page('jasmine.getJSReportAsString()'; 
        },
        server => sub {
            my $port = shift;

            use Dancer;
            use MyApp;
            Dancer::Config->load;

            set( startup_info => 0,  port => $port );
            Dancer->dance;
        },
    );

    done_testing;

=head1 SEE ALSO

=over

=item L<The original blog entry|http://techblog.babyl.ca/entry/dancer-jasmine>

=item L<Jasmine|http://jasmine.github.io/> - the JavaScript testing framework

=item L<jasmine-jsreporter|https://github.com/detro/jasmine-jsreporter> - Jasmine plugin used to get the results via JSON

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
