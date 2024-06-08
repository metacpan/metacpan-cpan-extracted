use File::Spec::Functions qw(catfile);
use Net::EmptyPort;

sub start_server {
	my( $port ) = @_;

	my $child_pid = fork;

	return $child_pid unless $child_pid == 0;

	require HTTP::Daemon;
	require HTTP::Date;
	require HTTP::Status;

	my $d = HTTP::Daemon->new( LocalPort => $port ) or exit;
	CONNECTION: while (my $c = $d->accept) {
		REQUEST: while (my $r = $c->get_request) {
			my $file = (split m|/|, $r->uri->path)[-1] // 'index.html';
			my $path = catfile 't', 'html', $file;

			if ($r->method eq 'GET') {
				if( -e $path ) {
					$c->send_file_response( catfile 't', 'html', $file);
					}
				elsif( $path eq 'shutdown' ) {
					$c->close; undef $c;
					last CONNECTION;
					}
				else {
					$c->send_error(HTTP::Status::RC_NOT_FOUND())
					}
				}
			elsif ($r->method eq 'HEAD') { # update_mirror does this
				if( -e $path ) {
					my $last_modified = (stat $path)[9];
					$c->send_header(
						'Last-Modified'  => HTTP::Date::time2str($last_modified),
						'Content-Length' => (-s $path),
						);
					}
				else {
					$c->send_error(HTTP::Status::RC_NOT_FOUND())
					}
				}
			else {
				$c->send_error(HTTP::Status::RC_FORBIDDEN())
				}
			}
		$c->close;
		undef($c);
		}

	exit;
	}

sub can_fetch { require LWP::UserAgent; LWP::UserAgent->new->get( shift )->is_success }

1;
