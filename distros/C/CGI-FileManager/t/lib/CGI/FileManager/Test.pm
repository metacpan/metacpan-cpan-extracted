package CGI::FileManager::Test;
use strict;
use warnings;

#use base 'Exporter';
#use Test::Builder;
#use Test::More;
use CGI;
use Carp qw(croak);
use FindBin qw($Bin);
#our @EXPORT = qw(&cgiapp &extract_cookie);

#my $T = Test::Builder->new;

=head1 Synopsis

This module, if developed correctly can become a generic testing module for
systems based on CGI::Application. For now its name remains specific to 
CGI::FileManager.

=head2 new

my $t = CGI::FileManager::Test->new({
	module    => MODULE_NAME,
	cookie    => COOKIE_NAME,
    http_host => "test-host",
});

=cut
sub new {
	my $class = shift;
	my $args  = shift;
	croak "Invalid arguments" if ref $args ne "HASH";
	croak "Module name not provided" if not defined $args->{module};

	$args->{http_host} = "test-host" if not $args->{http_host};

	# Later we might check that the provided arguments are exactly what we need.

	bless $args, $class;
}

=head2 cgiapp

my $result = $t->cgiapp(PATH_INFO, HTTP_COOKIE, CGI_PARAMS);

CGI_PARAMS is a hash reference such as {a => 23, b => 19}

=cut
sub cgiapp {
	my ($self, $path_info, $cookie, $params) = @_;
	croak "PATH_INFO not defined" if not defined $path_info;


	local $ENV{CGI_APP_RETURN_ONLY} = 1; # to eliminate screen output

	local $ENV{HTTP_HOST}   = $self->{http_host};
	local $ENV{PATH_INFO}   = $path_info;
	local $ENV{SCRIPT_NAME} = $path_info;
    local $ENV{HTTP_COOKIE} = '';
    if (defined $cookie) {
	    $ENV{HTTP_COOKIE} = "$self->{cookie}=$cookie";
    }
	
	my $q = CGI->new($params);
	my $pwfile = "$Bin/../authpasswd";
	my $webapp = $self->{module}->new(
		    QUERY => $q,
			PARAMS => {
				AUTH => {
					PASSWD_FILE => $pwfile,
				},
				TMPL_PATH => "$Bin/../templates",
#				ROOT => $self->{root},
			},
	    );
	return $webapp->run();
}

sub upload_file {
	my ($self, $path_info, $cookie, $params, $original_file, $long_filename_on_client) = @_;
	$long_filename_on_client ||= $original_file;

    my $binmode = $^O =~ /OS2|VMS|Win|DOS|Cygwin/i;

	#### Prepare environment that looks like a CGI environment
	my $boundary = "----------9GN0yM260jGW3Pq48BILfC";

	open my $fh, "<", "$original_file" or die "Cannot open $original_file\n";
	binmode $fh if $binmode;
	my $original_content = join "", <$fh>;
	close $fh;

	my $original ="";
	$original .= qq(--$boundary\r\n); 
	$original .= qq(Content-Disposition: form-data; name="filename"; filename="$long_filename_on_client"\r\n);
	$original .= qq(Content-Type: text/plain\r\n\r\n);
	$original .= qq($original_content\r\n);
	$original .= qq(--$boundary--\r\n);

	local $ENV{REQUEST_METHOD} = "POST";
	local $ENV{CONTENT_LENGTH} = length $original;
	local $ENV{CONTENT_TYPE}   = qq(multipart/form-data; boundary=$boundary);
	local $ENV{HTTP_USER_AGENT} = "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.3) Gecko/20030312";

	my $u;
    ## no critic (ProhibitBarewordFileHandles)
	local *STDIN;
	open STDIN, "<", \$original;
	return $self->cgiapp($path_info, $cookie, $params);
}

=head2 extract_cookie

my $cookie_value = $t->extract_cookie($result);

=cut
sub extract_cookie {
	my ($self, $result) = @_;
	if ($result =~ /^Set-Cookie: $self->{cookie}=([^;]*);/m) {
		return $1;
	} else {
		return "";
	}
}

=pod

sub cookie_set {
	my ($result, $cookie) = @_;
	$T->like($result, qr{^Set-Cookie: $COOKIE=$cookie; domain=$ENV{HTTP_HOST}; path=/}m, 'cookie set');
}


sub setup_sessions {
	my $n = shift;
	my @sids;
	foreach my $i (1 .. $n) {
		my $s = PTI::DB::Session->create;
		push @sids, $s->sid;
	}
	return @sids;
}

=cut

1;


