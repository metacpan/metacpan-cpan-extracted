#!/usr/bin/env perl
# quick and easy test if email works
#
# (c) kevin Mulholland 2012, moodfarm@cpan.org
# this code is released under the Perl Artistic License

# v0.1 moodfarm@cpan.org, initial work

use 5.12.0;
use strict;
use warnings;
use Test::More tests => 6;
use File::Slurp qw(read_file);
use Text::Markdown qw(markdown);
use Try::Tiny;

BEGIN { use_ok('App::Basis::Email'); }

# -----------------------------------------------------------------------------
my $logo_img = "https://db.tt/9Ge7rmkt";
my $markdown = <<EOD ;
# Basic Markdown

![logo]($logo_img)

That was an inlined image

## level2 header

* bullet
    * sub-bullet

### level3 header

EOD
my $html = markdown($markdown);

# -----------------------------------------------------------------------------
# ready to build the message to send

# if we supply a host, then we must want SMTP, we set testing so we will not send the message
# so we do not care about valid email address or server name
my $email1 = App::Basis::Email->new( host => "email.server.fred", testing => 1 );
isa_ok( $email1, 'App::Basis::Email', 'Created class for smtp parameters' );
isa_ok( $email1->sender, 'Email::Sender::Transport::SMTP', 'Created correct SMTP sender class' );

my $email2 = App::Basis::Email->new( transport => 'sendmail', testing => 1, sendmail_path => '/usr/bin/sendmail' );
isa_ok( $email2, 'App::Basis::Email', 'Created correct class for sendmail' );
isa_ok( $email2->sender, 'Email::Sender::Transport::Sendmail', 'Created correct Sendmail sender class' );

my $email_data = $email1->send(
    from    => 'fred@fred.test.fred',
    to      => 'fred@fred.test.fred',
    subject => 'test HTML email, with inline images',
    html    => $html
);
# in testing mode we get the string that would be send to the email server
# in normal mode this would be '1' for a good send
ok( length($email_data) > length($html), 'Correctly returned a good sized string' );

# note diag $email_data ;

