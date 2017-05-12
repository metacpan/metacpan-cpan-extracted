package API::Intis;
use Modern::Perl;
use utf8;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.00';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

package API::Intis::APIGrab;
use YAML::Tiny;
use WWW::Mechanize;
use Crypt::SSLeay;
use Digest::Perl::MD5 'md5_hex';
use JSON;
use error_codes;


sub readConfig {
    my $conf = YAML::Tiny->read( 'config.yaml' );
    return (login => $conf->[0]->{APIconnector}->{login}, APIkey => $conf->[0]->{APIconnector}->{APIkey}, host => $conf->[0]->{APIconnector}->{host});
};

sub build_signature {
    my (%params) = @_;
    delete $params{host};
    my $APIkey = delete $params{APIkey};
    my @ssignature;
    foreach my $key(sort keys %params){
        say "$key => $params{$key}";
        push @ssignature, $params{$key};
    };
    return md5_hex join('', @ssignature).$APIkey;
};

sub connect {
    my ($method, $other_params) = @_;
    my $ua = WWW::Mechanize->new(ssl_opts => { verify_hostname => 0 } );
    $ua->cookie_jar(HTTP::Cookies->new());
    $ua->agent_alias('Linux Mozilla');
    my %config = &readConfig();
    my $timestamp = $ua->get('https://go.intistele.com/external/get/timestamp.php')->content( raw => 1 );
    my %timestamp = (timestamp => $timestamp);
    my $output_format;
    if ($other_params ne '') {
        my %other_params = %{$other_params};
        foreach my $key (keys %other_params) {
            if ($key eq 'return') {
                $output_format = delete $other_params{$key};
            };
        };
        %config = (%config, %timestamp, %other_params);
    } else {
        %config = (%config, %timestamp);
    };
    my @o_formats = ('xml', 'json');
    my $request_json; my $request_xml;
    foreach my $format (@o_formats) {
        $config{return} = $format;
        my $signature = &build_signature(%config);
        my $url = "$config{host}$method.php?login=$config{login}&signature=$signature";
        while((my $key, my $value) = each %config){
            say "$key => $value\n";
            next if $key eq 'host' || $key eq 'login' || $key eq 'APIkey';
            $url .= "&$key=$value";
        };
        my $request = $ua->get("$url&return=$format")->decoded_content(charset => 'utf-8', raw => 1);
        $request_json = $request if $format eq 'json';
        $request_xml = $request if $format eq 'xml';
    };
    my $r = from_json($request_json);
    my @error;
    if ($r->{error}) {
        @error = &error_codes::get_name_from_code($r->{error});
    } else {
        @error = &error_codes::get_name_from_code();
    };
    return (request_json => $request_json, error => \@error, request_xml => $request_xml, request_object => \%{$r}, out_format => !defined $output_format ? 'json' : $output_format );
};

package API::Intis::APIRequest;
use JSON;
sub new {
    my($class, $method, $other_params) = @_;
    my %request_params;
    if (defined $other_params) {
        %request_params = &API::Intis::APIGrab::connect($method, $other_params);
    } else {
        %request_params = &API::Intis::APIGrab::connect($method, '');
    };
    my $self = {
        name => 'API::Intis::APIRequest',
        version => '1.0',
        method => $method,
        request_json =>  $request_params{request_json},
        error => $request_params{error},
        request_xml => $request_params{request_xml},
        request_object => $request_params{request_object},
        out_format => $request_params{out_format},
    };
    bless $self, $class;
    return $self;
};

1;
# The preceding line will help the module return a true value

