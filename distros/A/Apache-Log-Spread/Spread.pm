package Logger::Spread;

require 5.005_62;

use strict;
use warnings;
use Apache::Constants qw(:common);
use Apache::ModuleConfig ();
use Apache::Util qw( ht_time );
use DynaLoader ();
use English;
use POSIX;
use Spread;


use vars qw( $VERSION $mailbox $private_group $iter);

$VERSION = '1.0.3';

if($ENV{MOD_PERL}) {
    no strict;
    @ISA = qw(DynaLoader);
    __PACKAGE__->bootstrap($VERSION);
}

sub spconnect($)
{
    my $daemon = shift; 
    my %args;
    $args{'spread_name'} = $daemon;
    $args{'private_name'} = "http-$PID";
    $args{'priority'} = 0;
    $args{'group_membership'} = 0;
    return ($mailbox, $private_group) = Spread::connect( \%args );
}

sub handler($$) 
{
    my $self = shift;
    $self = bless {}, $self;
    my $apache_req = shift;
    my %log_hash;
    my $cfg = Apache::ModuleConfig->get($apache_req, 'Logger::Spread');
    unless($mailbox) {
        ($mailbox, $private_group) = spconnect($cfg->{spreaddaemon});
    }
    standard_log_entries($apache_req, \%log_hash);
    # handle variable expansion
    foreach my $log (@{$cfg->{mls_logs}}) {
        if ($log->{mask} && !$log->{mask}->($apache_req)) {
            next;
        }
        my $log_string = $cfg->{logformat}->{$log->{format}};
        # expand 'standard' LogFormat strings and custom Taubman entries
        $log_string =~ s/%([\w<>]+)/$log_hash{$1}/g;
        # expand Environment variables
        $log_string =~ s/%\{([\w-]+)\}e\b/$ENV{$1}/g;
        # expand request headers
        $log_string =~ s/%\{([\w-]+)\}i\b/$apache_req->header_in($1)/eg;
        # expand response headers
        $log_string =~ s/%\{([\w-]+)\}o\b/$apache_req->header_out($1)/eg;
        # expand arbitrary variables
        $log_string =~ s/%\{([\w-]+)\}v\b/$$1/g;
        $log_string =~ s/%\{([^\}]+)\}perl\b/eval($1)/eg;
        # handle proprietary extensions
        _interpolate_log_string(\$log_string);
        Spread::multicast($mailbox, 
            AGREED_MESS, 
            $log->{name},
            1,
            $log_string);
    }
}

# used to extend basic operation
sub _interpolate_log_string { }

sub standard_log_entries 
{
    my $orig = shift;
    my $r = $orig->last;
    my $hashref = shift;

    $hashref->{a} = $r->connection->remote_ip;
    $hashref->{B} = $r->bytes_sent;
    $hashref->{b} = $r->bytes_sent?$r->bytes_sent:"-";
    $hashref->{c} = "-";  # unimplemeted
    $hashref->{f} = $r->filename;
    $hashref->{h} = $r->get_remote_host;
    $hashref->{H} = $r->protocol;
    $hashref->{l} = $r->get_remote_logname;
    $hashref->{m} = $r->method;
    $hashref->{p} = $r->server->port;
    $hashref->{P} = $PID;
    $hashref->{q} = '?'.$r->args;
    $hashref->{r} = $r->the_request;
    $hashref->{s} = $r->status;
    $hashref->{'>s'} = $orig->status; 
    # [06/May/2002:23:56:56 -0400]
    $hashref->{t} = POSIX::strftime('[%d/%b/%Y:%H:%M:%S %z]',localtime($orig->request_time));
    $hashref->{u} = $r->connection->user?$r->connection->user:"-";
    $hashref->{U} = $orig->uri;
    $hashref->{v} = $r->hostname;
    $hashref->{V} = $r->hostname;
}

sub MLS_LogFormat($$$$) 
{
    my ($cfg, $parms, $format, $name, $env) = @_;
   $cfg->{logformat}->{$name}= $format;
}

sub MLS_Log($$$$;$)
{
    my ($cfg, $parms, $fname, $format, $mask) = @_;
    my $env;
    eval "\$env = sub { my \$r = shift; $mask}"; 
    push @{$cfg->{mls_logs}}, { name => $fname, format => $format, mask => $env};
}

sub SpreadDaemon($$$)
{
    my ($cfg, $parms, $daemon) = @_;
    $cfg->{spreaddaemon} = $daemon;
}
	
1;
__END__

=head1 NAME

Apache::Log::Spread - Perl implementation of mod_log_spread for multicasting access logs.

=head1 SYNOPSIS

# In httpd.conf
PerlModule Apache::Log::Spread
PerlLogHandler 'Apache::Log::Spread->handler'
SpreadDaemon 4903
MLS_LogFormat "%h %{$cookie->isVisitor?'V':'U'}perl %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" custom
MLS_Log www custom

=head1 DESCRIPTION

Apache::Log::Spread provides logging handlers to allow for Apache access logs to
be multocast to a spread group.  The configuration interface is a super-set of
the Apache mod_log_config interface and allows for expansion of perl code.

=head1 Configuration Directives

=over 4

=item SpreadDaemon port[@host]

The location of the spread daemon to connect to.

=item MLS_LogFormat formatstring formatname

formatstring is a standard mod_log_config format line, the standard format options are all accepted (see the mod_log_config documentation for details), as well as the special tag %{...code...}perl, which evals the contained code and substitutes the results for the format specifier.

=item MLS_Log groupname formatname [should_print]

groupname is the name of the spread group to which logs should be multicast.  formatname is the name of the MLS_LogFormat to use.  should_print is an optional environment
string to toggle transmission of logs.  This can be used the way that mod_setenvif 
environment variables are used, or with a complete code block.  For example, to only
multicast requests for '.html' files we can use:

MLS_Log    www custom "return ($r->uri =~ /\.html/) || ($r->uri =~ /$\//));"

=back

=head1 EXTENDING

Apache::Log::Spread is deigned to be extended to provide custom format string expansions.  To extend it in ithis fashion, simply override the _interpolate_log_string function.

An example is

=over 4

package My::SpreadLogger;
use strict;

use Apache::Logger::Spread;
use My::Cookies;

use vars qw( @ISA);
@ISA = qw(Logger::Spread);

sub handler($$)
{
    my $self = shift;
    my $ar = shift;
    Apache::Log::Spread::handler($self, $ar);
}

sub _interpolate_log_string {
    my ($self, $logref) = @_;
    my $cookie = My::Cookie->new();
    $$logref =~ s/%\{([\w-]+)\}cookie/$cookie->{$1} || '-'/ego;
}

=back


=head1 AUTHOR

George Schlossnagle <george@omniti.com>

=cut
