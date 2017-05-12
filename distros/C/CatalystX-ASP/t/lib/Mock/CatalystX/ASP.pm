package Mock::CatalystX::ASP;

use Moose;
use Path::Tiny qw(path);
use FindBin qw($Bin);
use File::Temp;
use File::Slurp qw(write_file);
use HTTP::Headers;
use Catalyst::Exception::Detach;

use parent 'Exporter';
our @EXPORT = qw(
    mock_c
    mock_asp
    mock_global_asa
);

require CatalystX::ASP;

my $mock_c;
my $mock_c_response;
my $mock_c_request;
my $mock_asp;
my $mock_logger;
my $mock_global_asa;

my $upload_fh = File::Temp->new( TEMPLATE => 'upload-XXXXXX', DIR => '/tmp', UNLINK => 1 );
$upload_fh->print( 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' );
$upload_fh->seek( 0, SEEK_SET );
my %mock_uploads = (
    foofile => Moose::Meta::Class->create_anon_class(
        methods => {
            size     => sub {62},
            type     => sub {'plain/text'},
            fh       => sub {$upload_fh},
            tempname => sub { $upload_fh->filename },
            filename => sub {'foo.txt'},
            }
        )->new_object(),
);

my %response_data = (
    cookies  => {},
    headers  => HTTP::Headers->new,
    location => '',
    status   => 200,
);
my %log_data     = ();
my %session_data = ();

*file_id = *CatalystX::ASP::file_id;

sub mock_logger {
    $mock_logger //= Moose::Meta::Class->create_anon_class(
        methods => {
            warn  => sub { push @{ $log_data{warn} },  $_[1] },
            error => sub { push @{ $log_data{error} }, $_[1] },
            debug => sub { push @{ $log_data{debug} }, $_[1] },
            _get_logs => sub {
                my ( $self, $level ) = @_;
                return $log_data{$level};
            },
        },
    )->new_object();
}

sub mock_c_response {
    $mock_c_response //= Moose::Meta::Class->create_anon_class(
        methods => {
            cookies => sub { $response_data{cookies} },
            header  => sub { shift->headers->header( @_ ) },
            headers => sub { $response_data{headers} },
            redirect => sub {
                my ( $self, $location ) = @_;
                $response_data{location} = $location;
                $response_data{status}   = 302;
            },
            location => sub { $response_data{location} },
            status   => sub { $response_data{status} },
        },
    )->new_object();
}

sub mock_c_request {
    $mock_c_request //= Moose::Meta::Class->create_anon_class(
        methods => {
            cookies => sub {
                return {
                    foo => { value => ['bar'] },
                    foofoo => { value => [ 'baz=bar', 'bar=baz' ] },
                };
            },
            upload  => sub { $mock_uploads{foofile} },
            uploads => sub { \%mock_uploads },
            query_parameters => sub {
                return {
                    foobar => 'baz',
                };
            },
            body_parameters => sub {
                return {
                    foo => 'bar',
                    bar => 'foo',
                    baz => 'foobar',
                };
            },
            parameters => sub {
                return {
                    foo    => 'bar',
                    bar    => 'foo',
                    baz    => 'foobar',
                    foobar => 'baz',
                };
            },
            env => sub { return \%ENV },
            body => sub {
                my $body_fh = File::Temp->new( 'body-XXXXXX', DIR => '/tmp', UNLINK => 1 );
                $body_fh->print( 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' );
                $body_fh->seek( 0, SEEK_SET );
                return $body_fh;
            },
            content_length => sub {0},
            content_type   => sub {'application/x-www-form-urlencoded'},
            method         => sub {'GET'},
            path           => sub {'welcome.asp'},
        },
    )->new_object();
}

sub mock_c {
    $mock_c //= Moose::Meta::Class->create_anon_class(
        methods => {
            log      => \&mock_logger,
            response => \&mock_c_response,
            request  => \&mock_c_request,
            config   => sub { { name => 'TestApp', home => path( __FILE__, '../../../TestApp' )->realpath } },
            error            => sub { print STDERR "$_[1]\n"; },
            detach           => sub { Catalyst::Exception::Detach->throw },
            path_to          => sub { path( __FILE__, '../../../TestApp/root/welcome.asp' )->realpath },
            session          => sub { \%session_data },
            sessionid        => sub {'1234567890abcdef0987654321fedcba'},
            session_is_valid => sub { shift->sessionid eq shift },
        },
    )->new_object();
}

sub mock_asp {
    $mock_asp //= Moose::Meta::Class->create_anon_class(
        roles => [ 'CatalystX::ASP::Parser', 'CatalystX::ASP::Compiler' ],
        methods => {
            c                   => \&mock_c,
            search_includes_dir => sub { path( $_[0]->IncludesDir, $_[1] ) },
            file_id             => \&Mock::CatalystX::ASP::file_id,
            IncludesDir         => sub { path( __FILE__, '../../../TestApp/root' )->realpath },
            GlobalPackage => sub {'TestApp::ASP'},
            GlobalASA     => \&mock_global_asa,
            XMLSubsMatch  => sub {qr/parser:[\w\-]+/},
            Debug         => sub {1},
        },
    )->new_object();
}

sub mock_global_asa {
    $mock_global_asa //= Moose::Meta::Class->create_anon_class(
        methods => {
            exists         => sub {1},
            execute_event  => sub {'does nothing!'},
            package        => sub { mock_asp->GlobalPackage },
            Script_OnParse => sub {'Script_OnParse event!'},
        },
    )->new_object();
}

1;
