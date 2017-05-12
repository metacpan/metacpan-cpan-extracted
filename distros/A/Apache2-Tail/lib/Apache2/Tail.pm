package Apache2::Tail;

our $VERSION = 0.03;

use strict;
use warnings;

use Apache2::RequestIO  ();
use Apache2::RequestRec ();
use Apache2::ServerUtil ();
use Apache2::ServerRec  ();
use File::Tail          ();
use CGI;

use Apache2::Const -compile => qw(OK);

use constant TAIL_CNT => 25;

sub handler : method {
    my $class     = shift;
    my $r         = shift;
    my $s         = $r->server;
    my $name      = $s->server_hostname;
    my $error_log = $class->error_log($r);
    
    my $q = new CGI($r);

    my $tail_cnt = $q->param('n') || $class->tail_cnt($r);

    $r->content_type('text/html');

    my $tail = File::Tail->new(
                               name   => $error_log,
                               tail   => $tail_cnt,
                               nowait => 1,
                              );

    $class->print_header($r);

    while (my $line = $tail->read) {

        my ($date, $level, $client, $msg);
        if ($line =~
            m{\[(.*?)\]\s*\[(.*?)\]\s*(\[client\s*(.*?)\]\s*)?(.*)})
        {
            $level  = $2;
            $date   = $1;
            $client = $4;
            $msg    = $5;
            $msg =~ s/\\t/&nbsp;&nbsp;&nbsp;&nbsp;/g;
        }

        next unless $date;

        $r->print(<<"EOF");
<tr class="$level"><td class="timestamp">$date</td><td class="vhost">$name</td><td class="loglevel">$level</td><td class="client">$client</td><td class="message">$msg</td></tr>
EOF
        last if --$tail_cnt <= 0;
    }

    $class->print_footer($r);

    return Apache2::Const::OK;
}

sub style {
    my ($class, $r) = @_;
    
    if (my $user_style = $r->dir_config($class . '::CSS')) {
        return qq(<link rel="stylesheet" type="text/css" href="$user_style">);
    }
    else {
        return <<'EOF';
<style type="text/css">

body {
    font-family:    'Courier New', courier, monospace;
    font-size:      8pt;
    line-height:    10pt;
    color:          #333333;
}

td {
    padding:            .25em;
    align:              top;
    background-color:   #eee;
}

td.timestamp {
    font-size:      8pt;
    text-align:     center;
    width:          130px;
}

tr.warn td {
    background-color: #FFE79F;
}

tr.error td {
    background-color: #FFCCCC;
}

tr.notice td {
    background-color: #DFE7FF;
}

.vhost {
    font-style:     italic;
}

.loglevel {
    text-align:     center;
}

tr.info td.loglevel {

}

tr.notice td.loglevel {
    color:          #00C;
    font-weight:    bold;
} 

tr.debug td.loglevel{

}

tr.warn td.loglevel {
    font-weight:    bold;
    color:          #FF803E;
}

tr.error td.loglevel {
    color:          #F00;
    font-weight:    bold;
}

.client {
    color:          #333333;
}

.message {
    padding-left:   .5em;
}

tr.error td.message, tr.warn td.message, tr.notice td.message {
    font-weight:    bold;
}

</style>
EOF
    }
}

sub print_footer {
    my ($class, $r) = @_;
    $r->print(<<'EOF');
</table></body></html>
EOF
}

sub print_header {
    my ($class, $r) = @_;
    
    my $style = $class->style($r);

    $r->print(<<"EOF");
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Apache2::Tail $VERSION</title>
$style
</head>
<body>
<table border=0>
EOF
}

sub tail_cnt {
    my ($class, $r) = @_;
    return $r->dir_config($class . '::Count') || TAIL_CNT();
}

sub error_log {
    my ($class, $r) = @_;
    my $s = $r->server;
    return $r->dir_config($class . '::ErrorLog')
      || Apache2::ServerUtil::server_root_relative($r->pool,
                                                   $s->error_fname);

}

42;

__END__

=head1 NAME

Apache2::Tail - mod_perl handler to display the error_log

=head1 SYNOPSIS

  PerlModule Apache2::Tail
  <Location /tail>
    SetHandler  modperl
    PerlHandler Apache2::Tail

    [PerlSetVar Apache2::Tail::ErrorLog /some/other/log/file]
    [PerlSetVar Apache2::Tail::CSS /css/mystyle.css]
    [PerlSetVar Apache2::Tail::Count 100]

    Order deny,allow
    allow from 127.0.0.0/8
    deny from all
  </Location>


=head1 DESCRIPTION

Simple mod_perl handler that displays a pretty html version of the error_log.

=head2 OPTIONS

These options can be configured with PerlSetVar

=over 2

=item * Apache2::Tail::ErrorLog

The file to display, defaults to the current VirtualHost's I<error_log>

=item * Apache2::Tail::Count

The default maximum number of lines to display. Defaults to I<50>, but can
also be overriden at request time with the ?n= query parameter

=item * Apache2::Tail::CSS

The URL to an alternate sylesheet, defaults to some built-in defaults

=back

=head1 INTERNAL DOCUMENTATION

Quick summary of the internal APIs for anybody interested in subclassing
Apache2::Tail.

=head2 handler($class, $r)

The main handler, responsible for processing the request

=head2 error_log($class, $r)

Must return the full path to the file that needs tailing

=head2 print_header($class, $r)

prints the HTML header up to and including the E<lt>bodyE<gt>
tag

=head2 print_footer($class, $r)

prints the HTML footer closing the E<lt>bodyE<gt>
tag

=head2 tail_cnt($class, $r)

returns the maximum number of lines to tail for this
request.

=head2 style($class, $r)

returns the CSS content for the page

=head1 AUTHOR

Philippe M. Chiasson E<lt>gozer@cpan.orgE<gt>

=head1 ARTWORK

Tara Gibbs E<lt>tarag@activestate.comE<gt>

=head1 REPOSITORY

http://svn.ectoplasm.org/projects/perl/Apache2-Tail/trunk/

=head1 COPYRIGHT

Copyright 2007 by Philippe M. Chiasson E<lt>gozer@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>


=cut
