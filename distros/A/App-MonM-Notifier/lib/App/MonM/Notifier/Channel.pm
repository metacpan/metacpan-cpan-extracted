package App::MonM::Notifier::Channel; # $Id: Channel.pm 32 2017-11-22 16:05:22Z abalama $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier::Channel - monotifier channel base class

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Channel;

    my $channel = new App::MonM::Notifier::Channel(
            timeout => 300, # Default: 300
        );

    my $data = {
        id      => 1,
        to      => "recipient",
        from    => "sender",
        subject => "Test message",
        message => "Content of the message",
    };

    $channel->send( default => $data ) or warn($channel->error);
    # ...or...
    $channel->default( $data ) or warn($channel->error);

    # Run Email::MIME methods
    print $channel->{email}->body_str if $channel->status;

=head1 DESCRIPTION

This module provides channel base methods

=head2 METHODS

=over 8

=item B<new>

    my $channel = new App::MonM::Notifier::Channel(
            timeout => 300, # Default: 300
        );

Constructor

The "timeout" attribute is maximum time to run the channel process. Default: 300 secs

=item B<status>

    my $status = $channel->status;
    my $status = $channel->status( 1 ); # Sets the status value and returns it

Get/set BOOL status of the operation

=item B<error>

    my $error = $channel->error;

Gets error message

    my $status = $channel->error( "Error message", "Trace dump" );

Sets error message and trace dump if second argument is provided.
This method in "set" context returns status of the operation as status() method.
See L</trace> about tracing

=item B<trace>

    my $trace = $channel->trace;

Gets trace message

=item B<timeout>

    my $timeout = $channel->timeout;

    # Sets the timeout value and returns it
    my $timeout = $channel->timeout( 500 );

Get/set timeout of the operation

=item B<channels>

    my @available_channels = $channel->channels;
    my $available_channel = $channel->channels( "default" );

Returns list of available channels.
To check the availability of the channel, you must specify its name as an argument

=item B<check>

    my $status = $channel->check( file => $data, $opts )
        or warn($channel->error);

Runs validation of the data and options and returns status

=item B<send>

    my $status = $channel->send( default => $data, $opts )
        or warn($channel->error);
    my $status = $channel->default( $data, $opts )
        or warn($channel->error);

This method runs process of sending message to selected channel and returns
status this operation.

For selecting the channel you must be provided name it as the first argument
or call the method of the same name.

See L</DATA> and L</OPTIONS> for more details on data and options of method

=item B<handler>

Local default method that provides base process. See L</send> method

=back

=head2 DATA

It is a structure (hash), that can contain the following fields:

=over 8

=item B<id>

Contains internal ID of the message. This ID is converted to an X-Id header

=item B<to>

Recipient address or name

=item B<from>

Sender address or name

=item B<subject>

Subject of the message

=item B<message>

Body of the message

=item B<headers>

Optional field. Contains eXtra headers (extension headers). For example:

    headers => {
            "bcc" => "bcc\@example.com",
            "X-Mailer" => "My mailer",
        }

=back

=head2 OPTIONS

It is a structure (hash), that can contain the following fields:

=over 8

=item B<encoding>

Encoding: 'quoted-printable', base64' or '8bit'

Default: 8bit

See L<Email::MIME>

=item B<content_type>

The content type

Default: text/plain

See L<Email::MIME>

=item B<charset>

Part of common Content-Type attribute. Defines charset

Default: utf-8

See L<Email::MIME>

=item B<io>

This attribute defines method of the returned serialized data

    my $ret;
    $channel->default( $data, {io => \$ret} );

Returns serialized data as scalar variable $ret

    $channel->default( $data, {io => $fh} );

Returns serialized data to file by file handler (IO::File)

    $channel->default( $data, {io => \*STDERR} );

Returns serialized data to STDERR pipe

    $channel->default( $data, {io => IO::Pipe->new} );

Returns serialized data to custom pipe

    $channel->default( $data, {io => 'NONE'} );

Returns serialized data to STDOUT

    $channel->default( $data, {io => undef} );

No returns any serialized data! See email attrribute, get it
via $channel->{email} access

=item B<signature>

Set/unset add signature to the message's body

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<CTK>, L<Email::MIME>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::Notifier>, L<Email::MIME>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use CTK::Util;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Module::Load;
use IO::Handle;
use IO::String;
use App::MonM::Notifier::Util;
use Email::MIME;
use Sys::Hostname;

use constant {
    PREFIX      => 'monotifier',
    TIMEOUT     => 300, # 5 min timeout
    SUBCLASSES => [qw/
            App::MonM::Notifier::Channel::File
            App::MonM::Notifier::Channel::Email
            App::MonM::Notifier::Channel::Script
        /],
    CONTENT_TYPE=> "text/plain",
    CHARSET     => "utf-8",
    ENCODING    => "8bit", # "base64"
};

use vars qw/$VERSION $BANNER/;
$VERSION = '1.00';
$BANNER = sprintf("%s/%.2f", PREFIX, "$VERSION");

our $AUTOLOAD;

my %subclasses;
foreach my $sc (@{(SUBCLASSES)}) {
    next if exists $subclasses{$sc};
    load $sc;
    $subclasses{$sc} ||= {version => $sc->VERSION, inited => 0, type => undef, init => undef};
}

sub new {
    my $class = shift;
    my %opts = @_;

    my %props = (
            error       => '',
            status      => 1,
            trace       => '',
            #subclasses  => \%subclasses,
            channels     => {
                default => {
                        class => bless({},__PACKAGE__),
                    },
            },
            timeout     => $opts{timeout} || TIMEOUT,
            email       => undef,
        );

    # Init subclasses
    my @errs = ();
    foreach my $sc (keys %subclasses) {
        if ($subclasses{$sc}{inited}) {
            my $it = $subclasses{$sc}{init};
            my $tp = $subclasses{$sc}{type};
            $props{channels}{$tp} = $it;
            next;
        }
        $subclasses{$sc}{inited}++;
        my %initopts = ();
        if ($sc->can("init")) {
            %initopts = $sc->init(%opts);
            unless (%initopts) {
                push @errs, sprintf("Can't init module %s", $sc);
                next;
            }
        } else {
            next;
        }

        # Register class $sc with %initopts
        unless ($initopts{type}) {
            push @errs, sprintf("Can't init module %s: incorrect channel type", $sc);
            next;
        }
        my $type = lc($initopts{type});
        delete $initopts{type};

        my $it = {
                %initopts,
                class => bless({ }, $sc)
            };
        $props{channels}{$type} = $it;
        $subclasses{$sc}{type} = $type;
        $subclasses{$sc}{init} = $it;
    }
    if (@errs) {
        $props{status} = 0;
        $props{error} = join "; ", @errs;
    }

     #print Dumper(\%subclasses);
    #print Dumper(\%props);
    return bless { %props }, $class;
}
sub status {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{status}) unless defined($value);
    $self->{status} = $value ? 1 : 0;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $value = shift;
    my $trace = shift;
    return uv2null($self->{error}) unless defined($value);
    $self->{error} = $value;
    $self->{trace} = $trace;
    $self->status($value ne "" ? 0 : 1);
    return $self->status;
}
sub trace {
    my $self = shift;
    return uv2null($self->{trace});
}
sub timeout {
    my $self = shift;
    my $value = shift;
    return fv2zero($self->{timeout}) unless defined($value);
    $value = 0 unless is_int16($value);
    $value = 0 if $value < 0;
    $self->{timeout} = $value;
    return $self->{timeout};
}
sub channels {
    my $self = shift;
    my $req = shift;
    my $channels = $self->{channels};
    return () unless $channels && is_hash($channels);
    if (defined($req) && length($req)) {
        my ($ret) = grep {$_ eq lc($req)} keys %$channels;
        return $ret if defined $ret;
        return ();
    }
    return keys %$channels;
}
sub check {
    my $self = shift;
    my $type = lc(shift || 'default');
    my $data = shift;
    my $options = shift;
    my $channel = hash($self->{channels}, $type);
    unless ($channel && $channel->{class}) {
        return $self->error(sprintf("Can't find %s channel", $type));
    }
    unless ($data && is_hash($data) && keys %$data) {
        return $self->error("Message data incorrect");
    }
    unless (!$channel or (is_hash($channel) && keys %$channel)) {
        return $self->error("Channel options incorrect");
    }
    my $validation = hash($channel => "validation");
    return 1 unless (keys %$validation);

    my $val_data = hash($validation => "data");
    foreach my $k (keys %$val_data) {
        return 0 unless _chk($self, $k, $val_data->{$k}, $data->{$k});
    }
    my $val_opts = hash($validation => "options");
    foreach my $k (keys %$val_opts) {
        return 0 unless _chk($self, $k, $val_opts->{$k}, $options->{$k});
    }

    return 1;
}
sub _chk {
    my ($self, $k, $v, $t) = @_;
    return 1 unless $v && is_hash($v) && keys %$v;
    my $e = $v->{error} || sprintf("Incorrect \"%s\" field", $k);

    # Defined
    my $optional = $v->{optional} || 0;
    return $self->error(sprintf("%s: undefined value", $e)) if !defined($t) && !$optional;
    return 1 unless defined($t);

    # Length
    my $max = $v->{maxlength} || 0;
    my $min = $v->{minlength} || 0;
    return $self->error(sprintf("%s: value is too long", $e))
        if $max && is_int($max) && length($t) > $max;
    return $self->error(sprintf("%s: value is too short", $e))
        if $min && is_int($min) && length($t) < $min;

    # Type
    my $type = $v->{type} || '';
    if ($type) {
        if ($type =~ /^int$/i) {
            return $self->error(sprintf("%s: type of the value is not int", $e))
                unless is_int($t);
        } elsif ($type =~ /^str$/i) {
            return $self->error(sprintf("%s: type of the value is not string", $e))
                unless length($t);
        }
    }

    # Regexp
    my $regexp = $v->{regexp} || undef;
    if ($regexp && ref($regexp) eq 'Regexp') {
        return $self->error(sprintf("%s: not match by mask (regexp)", $e))
            unless $t =~ $regexp;
    }

    return 1;
}
sub send {
    my $self = shift;
    my $type = lc(shift || 'default');
    my $data = shift;
    my $options = shift;
    my $channel = hash($self->{channels}, $type);
    return 0 unless $self->check($type, $data, $options);

    my $class = $channel->{class};
    unless ($class && $class->can("handler")) {
        $class = $self->{channels}{default}{class};
    }
    my $code = $class->can("handler");

    # Run with timeout!
    my $timeout = $self->timeout;
    my $prev_alarm = alarm 0; # suspend outer alarm early
    my $sigcount = 0;
    my $res;

    eval {
        local $SIG{ALRM} = sub { $sigcount++; die "Got timeout\n"; };
        local $SIG{PIPE} = sub { $sigcount++; die "Broken pipe\n" };
        local $SIG{__DIE__};
        alarm($timeout);
        eval {
            $res = &$code($self, $data, $options);
        };
        alarm(0); # avoid race conditions
        die $@ if $@;
    };
    my $err = $@;
    alarm $prev_alarm;

    # this shouldn't happen anymore?
    return($self->error("Unknown error")) if $sigcount && !$err; # seems to happen sometimes
    return($self->error($err)) if $err;

    return $res // 0;
}
sub handler {
    my $self = shift;
    my $data = shift;
    my $options = shift;

    my $ioin = $options->{io};
    my $io;
    if (defined($ioin) && ref($ioin) eq 'SCALAR') { # Scalar ref
        $io = IO::String->new( $options->{io} )
    } elsif (defined($ioin) && ref($ioin) eq 'GLOB') { # Glob ref
        $io = IO::Handle->new();
        unless ($io->fdopen($ioin,"w")) {
            return $self->error("Can't use io handler as GLOB");
        }
        binmode($io);
    } elsif (defined($ioin) && ref($ioin) eq 'IO::File') { # IO::File object
        $io = IO::Handle->new();
        unless ($io->fdopen($ioin,"w")) {
            return $self->error("Can't use io handler as IO::File object");
        }
        binmode($io);
    } elsif (defined($ioin) && ref($ioin) =~ 'IO') { # IO::* object
        $io = $ioin;
        binmode($io);
    } elsif (defined($ioin)) {
        $io = IO::Handle->new();
        unless ($io->fdopen(fileno(STDOUT),"w")) {
            return $self->error("Can't use STDOUT handler");
        }
        binmode($io);
    }

    my $to = value($data => "to");
    return $self->error("Field \"to\" incorrect") unless(defined($to) && length($to));

    my $headers = hash($data => "headers");
    my %hset = (
            To      => $to,
            From    => value($data => "from"),
            Subject => value($data => "subject"),
        );
    if ($headers && is_hash($headers) && keys(%$headers)) {
        while (my ($k,$v) = each %$headers) {
            next unless defined $v;
            if (grep {lc($k) eq lc($_)} (qw/To From Subject/)) {
                $hset{ucfirst($k)} = $v;
            } else {
                $hset{$k} = $v;
            }
        }
    }
    my $email = Email::MIME->create(
        header_str => [%hset],
    );
    $email->content_type_set( value($options => "content_type") // CONTENT_TYPE );
    $email->charset_set( value($options => "charset") // CHARSET );
    $email->encoding_set( value($options => "encoding") // ENCODING );
    my $message = defined($data->{message}) ? value($data => "message") : '';
    my $signature = "";
    if (value($options => "signature")) {
        $signature = sprintf(join("\n",
                    "",
                    "---",
                    "Hostname     : %s",
                    "Mailer       : %s",
                    "Worker [pid] : %s [%d]",
                    "Generated    : %s"
                ),
                hostname(),
                $BANNER,
                PREFIX, $$,
                dtf("%w, %DD %MON %YYYY %hh:%mm:%ss ".tz_diff()),
            );
    }
    $email->body_str_set($message.$signature);

    if ($io && $io->can("print")) { # No output. Set obj.prop
        $io->print($email->as_string);
        $io->close;
    } else {
        $self->{email} = $email;
    }

    1;
}

sub DESTROY {}; # avoid problems with autoload
sub AUTOLOAD {
    my ($self) = @_;
    my $sub = $AUTOLOAD;
    (my $method = $sub) =~ s/.*:://;
    #print ">>> CATCHED <<<\n";
    my $channel = hash($self->{channels}, $method);
    unless ($channel && $channel->{class}) {
        return $self->error(sprintf("Can't find %s method", $method));
    }
    no strict 'refs';
    *{$sub} = sub {
        my $self = shift;
        return $self->send("$method", @_);
    };
    goto &$AUTOLOAD;
}

1;
