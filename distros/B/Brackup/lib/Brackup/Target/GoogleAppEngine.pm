package Brackup::Target::GoogleAppEngine;

use strict;
use warnings;
use base 'Brackup::Target';
use Carp qw(croak);
use LWP::ConnCache;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;

# fields in object:
#   user_email
#   password
#   url

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);
    
    $self->{user_email} = $confsec->value("user_email")
        or die "No 'user_email'";
    $self->{password} = $confsec->value("password")
        or die "No 'password'";
    $self->{url} = $confsec->value("server_url")
        or die "No 'server_url'";

    return $self->_init;
}

sub _init {
    my $self = shift;
    $self->{url} =~ s!/$!!;
    my $conn_cache = LWP::ConnCache->new(total_capacity => 10);
    $self->{ua} = LWP::UserAgent->new(conn_cache => $conn_cache);

    $self->{upload_urls} = [];
    return $self;
}

sub _prompt {
    my ($q) = @_;
    print $q if $q;
    my $ans = <STDIN>;
    $ans =~ s/^\s+//;
    $ans =~ s/\s+$//;
    return $ans;
}

sub backup_header {
    my $self = shift;
    return {
        "UserEmail" => $self->{user_email},
        "URL" => $self->{url},
    };
}

sub new_from_backup_header {
    my ($class, $header) = @_;
    my $password = _prompt("App Engine Target Server Password for $header->{UserEmail}: ")
        or die "Password required.\n";
    my $self = bless {
        user_email => $header->{UserEmail},
        url => $header->{URL},
        password => $password,
    }, $class;
    return $self->_init;
}

sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;   # "sha1:sdfsdf" format scalar

    die "no impl";
    return 0;
}

sub load_chunk {
    my ($self, $dig) = @_;
    my $req = GET("$self->{url}/get_chunk?digest=$dig&" .
                  "password=" . _eurl($self->{password}) . "&" .
                  "user_email=" . $self->{user_email});
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        my $content_type = $res->header("Content-Type");
        die "Expected x-danga/brackup-chunk content type but got $content_type."
            unless $content_type eq "x-danga/brackup-chunk";
        my $content_ref = \ scalar $res->content;
        # TODO: verify digest out of paranoia?
        return $content_ref;
    } else {
        warn "Failed to get chunk $dig: " . $res->status_line . "\n"
            . $res->content;
    }
    return 0;
}

sub _eurl {
    my $a = defined $_[0] ? $_[0] : "";
    $a =~ s/([^a-zA-Z0-9_\,\-.\/\\\: ])/uc sprintf("%%%02x",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}

sub _get_upload_url {
    my $self = shift;
    my $for_backup = shift || 0;

    if (!$for_backup && @{$self->{upload_urls}}) {
        my $url = shift @{$self->{upload_urls}};
        die "Bogus URL: $url" unless $url =~ /^http/;
        return $url;
    }

    my $count = $for_backup ? 1 : 10;

    my $req = HTTP::Request->new("GET",
                                 "$self->{url}/get_upload_urls?" .
                                 "for_backup=$for_backup&" .
                                 "count=$count&" .
                                 "password=" . _eurl($self->{password}) . "&" .
                                 "user_email=" . $self->{user_email});
    my $res = $self->{ua}->request($req);
    if ($res->is_success) {
        $self->{upload_urls} = [ split(/\s*\n\s*/, $res->content) ];
    } else {
        die "Failed to get upload URLs: " . $res->status_line . "\n" . $res->content;
    }

    my $url = shift @{$self->{upload_urls}};
    die "Bogus URL: $url" unless $url =~ /^http/;
    return $url;
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $blen = $chunk->backup_length;
    my $chunkref = $chunk->chunkref;

    my $upload_url = $self->_get_upload_url
        or die;

    my $filename = $dig;
    $filename =~ s/:/_/;
    $filename .= ".chunk";

    print "Storing chunk: $dig\n";

    my $content = do { local $/; <$chunkref> };

    my $req = HTTP::Request::Common::POST($upload_url,
                                          Content_Type => 'form-data',
                                          Content => [
                                                      "password" => $self->{password},
                                                      "user_email" => $self->{user_email},
                                                      "algo_digest" => $dig,
                                                      "size" => $blen,
                                                      "file" => [ undef, $filename,
                                                                  "Content-Type" => "x-danga/brackup-chunk",
                                                                  Content => $content ]
                                                      ]);

    my $location = 0;
    my $n_errors = 0;
    while ($n_errors < 10) {
        my $res = $self->{ua}->simple_request($req);
        if ($res->status_line =~ /^500/) {
            # AppEngine's datastore decided to time out on its
            # un-contended transactions?  Bleh.
            $n_errors++;
            warn "500 error from AppEngine (errors=$n_errors).  Retrying after some sleep.\n";
            sleep(5);
            next;
        }

        unless ($res->status_line =~ /^302/) {
            # TODO: retries on 5xx?
            die "Expected 302 redirect from AppEngine, got: " . $res->status_line;
        }

        my $location = $res->header("Location");
        return 1 if $location =~ m!/success$!;

        warn "Got error message from AppEngine: $location\n";
        return 0;
    }

    warn "Too many failures.";
    return 0;
}

sub delete_chunk {
    my ($self, $dig) = @_;
    die "no impl";
    return 0;
}

sub chunks {
    my $self = shift;

}

sub store_backup_meta {
    my ($self, $name, $fh, $meta) = @_;
    $meta ||= {};

    print "Storing backup: $name\n";

    my $upload_url = $self->_get_upload_url(1)  # for backup
        or die;

    my $content = do { local $/; <$fh> };

    my $req = HTTP::Request::Common::POST($upload_url,
                                          Content_Type => 'form-data',
                                          Content => [
                                                      "password" => $self->{password},
                                                      "user_email" => $self->{user_email},
                                                      "encrypted" => $meta->{is_encrypted} ? 1 : 0,
                                                      "title" => $name,
                                                      "file" => [ undef, $name,
                                                                  "Content-Type" => "x-danga/brackup-backup",
                                                                  Content => $content ]
                                                     ]);

    my $res = $self->{ua}->simple_request($req);
    unless ($res->status_line =~ /^302/) {
        # TODO: retries on 5xx?
        die "Expected 302 redirect from AppEngine, got: " . $res->status_line;
    }

    my $location = $res->header("Location");
    return 1 if $location =~ m!/success$!;

    warn "Got error message from AppEngine: $location\n";
    return 0;
}

sub backups {
    my $self = shift;
    die "no impl";
    return ();
}

sub get_backup {
    my $self = shift;
    my ($name, $output_file) = @_;
    die "no impl"
}

sub delete_backup {
    my $self = shift;
    my $name = shift;
    die "no impl"
}

#############################################################
# These functions are for the brackup-verify-inventory script
#############################################################

sub chunkpath {
    my $self = shift;
    my $dig = shift;
    die "no impl";
        #return $dig;
}

sub size {
    my $self = shift;
    my $dig = shift;

    die "no impl";
    #return $size;
}

1;

=head1 NAME

Brackup::Target::GoogleAppEngine - backup to the App Engine target server

=head1 WARNING WARNING WARNING

This isn't totally done yet.  B<Don't trust it quite yet>.  Restore should
work now, but storing and re-retrieving metafiles isn't done yet, for instance.

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:google]
  type = GoogleAppEngine
  user_email = ....
  password = ....
  server_url = ....

=head1 CONFIG OPTIONS

=over

=item B<type>

Must be "B<GoogleAppEngine>".

=item B<user_email>

Email address that you've logged into your brackup-gae-server instance
with and configured uploading.

=item B<password>

Your brackup-gae-server password.  B<NOT> your Google account's password.

You should make a separate password just for this.

=item B<server_url>

URL to your brackup-gae-server instance.

Source code to run your own instance is at: L<http://github.com/bradfitz/brackup-gae-server>

=back

=head1 WARRANTY AND SUPPORT

None.  Use this at your own risk.  I'm a Google employee, but I'm not
writing this as a Google employee, and this is not a Google product.

This comes with no warranty, neither expressed nor implied.

Also, it doesn't even work yet.  It's still in development.  See the
WARNING WARNING WARNING section at top.

=head1 SEE ALSO

L<Brackup::Target>

=head1 AUTHOR

Brad Fitzpatrick E<lt>brad@danga.comE<gt>


