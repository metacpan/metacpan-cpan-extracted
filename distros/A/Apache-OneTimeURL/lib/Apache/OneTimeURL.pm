package Apache::OneTimeURL;

use 5.006;
use strict;
use warnings;
use MLDBM qw(DB_File);
use Digest::MD5 qw(md5_hex);
use Mail::Send;
use Apache;
use Apache::Constants;

our $VERSION = "1.34";

sub handler {
    my ($class,$r) = @_;
    # This allows us to use inheritance in situations where we're called
    # as "Apache::OneTimeURL->handler" but not otherwise.
    if (!$r and $class) { $r = $class; $class = __PACKAGE__ }

    $r->path_info() =~ /([a-f0-9]{32})/ or return DECLINED;
    my $key = $1;
    my %o;
    my $db = $r->dir_config("OneTimeDb")
        or die "Database not specified in OneTimeDb!";
    tie %o, "MLDBM", $db
        or die "Couldn't open database $db: $!";
    return DECLINED if !exists $o{$key};
    my $stuff = $o{$key};
    if ($stuff->{count}++) {
        $o{$key} = $stuff;
        untie %o;
        return $class->intruder($r, $stuff);
    }
    $o{$key} = $stuff;
    untie %o;
    return $class->deliver($r);
}

sub deliver {
    my ($class, $r) = @_;
    die "No OneTimeDoc specified!" unless my $file = $r->dir_config("OneTimeDoc");
    my $subr = $r->lookup_file($file);
    return $subr->run;
}

sub authorize {
    my ($class, $db, $comments) = @_;
    my $key = md5_hex(time().{}.rand().$$);
    my %o;
    tie %o, "MLDBM", $db or die "Couldn't open database: $!";
    $o{$key} = {
       comments => $comments,
       count => 0,
       created => time
    };
    untie %o;
    return $key;
}

sub intruder {
    my ($class, $r, $hash) = @_;
    my $sendcount = $r->dir_config("OneTimeMailCount") || 5;
    if ($hash->{count} < $sendcount) {
        $class->send_mail($r, $hash);
    }
    $r->send_http_header("text/html");
    print "<HTML><HEAD><title>Unauthorized access</title></HEAD>
<BODY>
You are not authorized to access this resource. This attempt has been
recorded.
</BODY>
<HTML>";
    return OK; # Can't return forbidden, since that calls other handlers.
}

sub send_mail {
    my ($class, $r, $hash) = @_;
    my $email = $r->dir_config("OneTimeEmail") || $r->server_admin();
    my $referrer = $r->header_in( 'Referer' );
    my $msg = new Mail::Send To => $email,
                             Subject => 'One-time URL reused';
    my $fh = $msg->open;
    print $fh <<EOF;

Key issued at @{[ scalar localtime $hash->{created} ]}
with comments @{[ $hash->{comments} ]}

Reused at @{[ scalar localtime ]}
by @{[ $r->get_remote_host ]} ( @{[ $r->get_remote_logname ]} )

EOF

    if ($referrer) { print $fh "Accessed via $referrer\n\n" }
    $fh->close;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::OneTimeURL - One-time use URLs for sensitive data

=head1 SYNOPSIS

    PerlModule Apache::OneTimeURL
    <Location /secret>
        PerlHandle Apache:OneTimeURL
        SetHandler perl-script
        PerlSetVar OneTimeDb  /opt/secret/access.db
        PerlSetVar OneTimeDoc /opt/secret/realfile.html
        PerlSetVar OneTimeEmail intruder@simon-cozens.org
    </Location>

F<authorize.pl>:

    #!/usr/bin/perl
    use Apache::OneTimeURL;
    my $comments = join " ", @ARGV;
    my $db = "/opt/secret/access.db";
    print "http://www.my.server.int/secret/",
           Apache::OneTimeURL->authorize($db, $comments),
           "\n";

Now:

    % authorize.pl Given to Simon C on IRC
    http://www.my.server.int/secret/2c61de78edd612cf79c0d73a3c7c94fb

This URL will only be viewable once, and will then return an error. For
the first five times that the URL is accessed in error, a mail will be sent
to the email address given in the config. The number of times can be
configured with the C<OneTimeMailCount> variable; if you don't want any
mail, set this to minus one.

=head1 DESCRIPTION

The synopsis pretty much wraps it up. I'm paranoid about giving out
certain information, and although I can't really control what people do
with the HTML when they download it, I can damned well ensure that URLs
in mail I send don't end up on the web and being a liability. Hence the
desire for a URL that's only valid once. You may have your own
interesting uses for such a set-up.

I've hopefully designed the module so that if there's some aspect of its
behaviour you don't like, you can switch to the "method handler" style
(ie. C<PerlHandler Apache::OneTime::URL-E<gt>handler> and subclass to
override the bits you're unhappy about. This may be easier than convincing
me to make changes to the module.

=head1 THANKS

Peter Sergeant offered several useful ideas which contributed to the 1.1
and 1.2. releases of this module.

=head1 REPOSITORY

L<https://github.com/neilb/Apache-OneTimeURL>

=head1 AUTHOR

Simon Cozens, C<simon@kasei.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
