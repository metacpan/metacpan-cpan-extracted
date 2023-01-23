package Config::Inetd;

use strict;
use warnings;
use boolean qw(true false);

use Carp qw(croak);
use Fcntl qw(O_RDWR LOCK_EX);
use Params::Validate ':all';
use Tie::File ();

our ($VERSION, $INETD_CONF);

$VERSION = '0.32';
$INETD_CONF = '/etc/inetd.conf';

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

sub new
{
    my $class = shift;

    my $self = bless {}, ref($class) || $class;

    $self->_tie_conf(@_);
    $self->_parse_enabled;

    return $self;
}

sub _tie_conf
{
    my $self = shift;
    my ($conf_file) = @_;
    $conf_file ||= $INETD_CONF;

    my $conf_tied = tie(
        @{$self->{CONF}}, 'Tie::File', $conf_file,
        mode => O_RDWR, autochomp => false
    ) or croak "Cannot tie `$conf_file': $!";
    $conf_tied->flock(LOCK_EX)
      or croak "Cannot lock `$conf_file': $!";
}

sub _parse_enabled
{
    my $self = shift;

    $self->_filter_conf($self->{CONF});

    foreach my $entry (@{$self->{CONF}}) {
        my ($serv, $prot) = $self->_extract_serv_prot($entry);
        $self->{ENABLED}{$serv}{$prot} = $entry !~ /^\#/
          ? true : false;
    }
}

sub is_enabled
{
    my $self = shift;
    $self->_validate(@_);
    my ($serv, $prot) = @_;

    return exists $self->{ENABLED}{$serv}{$prot}
      ? $self->{ENABLED}{$serv}{$prot}
      : undef;
}

sub enable
{
    my $self = shift;
    $self->_validate(@_);
    my ($serv, $prot) = @_;

    foreach my $entry (@{$self->{CONF}}) {
        if ($entry =~ /^ \# .*? $serv .+? $prot \b/x) {
            $self->{ENABLED}{$serv}{$prot} = true;
            $entry = substr($entry, 1);
            return true;
        }
    }

    return false;
}

sub disable
{
    my $self = shift;
    $self->_validate(@_);
    my ($serv, $prot) = @_;

    foreach my $entry (@{$self->{CONF}}) {
        if ($entry =~ /^ (?!\#) .*? $serv .+? $prot \b/x) {
            $self->{ENABLED}{$serv}{$prot} = false;
            $entry = "#$entry";
            return true;
        }
    }

    return false;
}

sub dump_enabled
{
    my $self = shift;

    my @conf = @{$self->{CONF}};
    $self->_filter_conf(\@conf, qr/^[^\#]/);

    return @conf;
}

sub dump_disabled
{
    my $self = shift;

    my @conf = @{$self->{CONF}};
    $self->_filter_conf(\@conf, qr/^\#/);

    return @conf;
}

sub config
{
    my $self = shift;
    validate_pos(@_);

    return $self->{CONF};
}

sub _filter_conf
{
    my $self = shift;
    my ($conf, @regexps) = @_;

    unshift @regexps, qr/(?:stream|dgram|raw|rdm|seqpacket)/;

    for (my $i = $#$conf; $i >= 0; $i--) {
        foreach my $regexp (@regexps) {
            splice(@$conf, $i, 1) and last
              unless $conf->[$i] =~ $regexp;
        }
    }
}

sub _extract_serv_prot
{
    my $self = shift;
    my ($entry) = @_;

    my ($serv, $prot) = (split /\s+/, $entry)[0,2];

    $serv =~ s/.*:(.*)/$1/;
    $serv = substr($serv, 1) if $serv =~ /^\#/;

    return ($serv, $prot);
}

sub _validate
{
    my $self = shift;
    validate_pos(@_, { type => SCALAR }, { type => SCALAR });
}

DESTROY
{
    my $self = shift;
    untie @{$self->{CONF}};
}

1;
__END__

=head1 NAME

Config::Inetd - Interface inetd's configuration file

=head1 SYNOPSIS

 use Config::Inetd;

 $inetd = Config::Inetd->new;

 if ($inetd->is_enabled(telnet => 'tcp')) {
     $inetd->disable(telnet => 'tcp');
 }

 print $inetd->dump_enabled;
 print $inetd->dump_disabled;

 print $inetd->config->[6];

=head1 DESCRIPTION

C<Config::Inetd> provides an interface to inetd's configuration file
(usually named F<inetd.conf>); it basically simplifies checking and
setting the enabled/disabled status of services and also allows for
dumping them by a given status.

=head1 CONSTRUCTOR

=head2 new

 $inetd = Config::Inetd->new('/path/to/inetd.conf');

Omitting the path to inetd.conf will cause the default F</etc/inetd.conf>
to be used.

=head1 METHODS

=head2 is_enabled

Checks whether a service is enlisted as enabled.

 $inetd->is_enabled($service => $protocol);

Returns true if the service is enlisted as enabled, false if enlisted
as disabled and undef if the service does not exist.

=head2 enable

Enables a service.

 $inetd->enable($service => $protocol);

Returns true if the service has been enabled, false if no action has
been taken.

It is recommended to precedingly call C<is_enabled()> with according
arguments supplied to determine whether a service is disabled.

=head2 disable

Disables a service.

 $inetd->disable($service => $protocol);

Returns true if the service has been disabled, false if no action has
been taken.

It is recommended to precedingly call C<is_enabled()> with according
arguments supplied to determine whether a service is enabled.

=head2 dump_enabled

Dumps the enabled services.

 @dump = $inetd->dump_enabled;

Returns a flat list that consists of the enabled entries as seen in the
configuration file.

=head2 dump_disabled

Dumps the disabled services.

 @dump = $inetd->dump_disabled;

Returns a flat list that consists of the disabled entries as seen in the
configuration file.

=head2 config

Access the tied configuration file.

 @config = @{$inetd->config};

Returns an array reference.

=head1 INSTANCE DATA

The inetd configuration file is tied as instance data with newlines
preserved; it may be accessed via C<< $inetd->config >>.

=head1 BUGS & CAVEATS

It is strongly advised that the configuration file is B<backuped> first
if one is intending to work with the default (i.e., system-wide)
configuration file and not a customized one.

Accessing C<< @{$inetd->{CONF}} >> is deprecated and superseded by
C<< $inetd->config >>.

=head1 SEE ALSO

L<Tie::File>, inetd.conf(5)

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
