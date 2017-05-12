package Cache::KyotoTycoon;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.16';
use Cache::KyotoTycoon::Cursor;
use TSVRPC::Client;
use Carp ();

sub _errmsg {
    my ($code, $msg) = @_;
    return "Cache::KyotoTycoon unexpected response code: $code $msg";
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    my $host = $args{host} || '127.0.0.1';
    my $port = $args{port} || 1978;
    my $db   = $args{db}   || 0;
    my $base = "http://${host}:${port}/rpc/";
    my $client = TSVRPC::Client->new(
        timeout    => exists( $args{timeout} ) ? $args{timeout} : 1,
        base       => $base,
    );
    my $self = bless {
        db        => $db,
        client    => $client,
    }, $class;
    return $self;
}

sub db {
    my $self = shift;
    $self->{db} = shift if @_;
    $self->{db};
}

sub make_cursor {
    my ($self, $cursor_id) = @_;
    return Cache::KyotoTycoon::Cursor->new($cursor_id, $self->{db}, $self->{client});
}

sub echo {
    my ($self, $args) = @_;
    my ($code, $body, $msg) = $self->{client}->call('echo', $args);
    Carp::croak _errmsg($code, $msg) if $code ne 200;
    return $body;
}

sub report {
    my ($self, ) = @_;
    my ($code, $body, $msg) = $self->{client}->call('report');
    Carp::croak _errmsg($code, $msg) if $code ne 200;
    return $body;
}

sub play_script {
    my ($self, $name, $input) = @_;
    my %args = (name => $name);
    while (my ($k, $v) = each %$input) {
        $args{"_$k"} = $v;
    }
    my ($code, $body, $msg) = $self->{client}->call('play_script', \%args);
    Carp::croak _errmsg($code, $msg) if $code ne 200;
    my %res;
    while (my ($k, $v) = each %$body) {
        $k =~ s!^_!!;
        $res{$k} = $v;
    }
    return \%res;
}

sub status {
    my ($self, ) = @_;
    my ($code, $body, $msg) = $self->{client}->call('status', {DB => $self->db});
    Carp::croak _errmsg($code, $msg) unless $code eq 200;
    return $body;
}

sub clear {
    my ($self, ) = @_;
    my %args = (DB => $self->db);
    my ($code, $body, $msg) = $self->{client}->call('clear', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq 200;
    return;
}

sub synchronize {
    my ($self, $hard, $command) = @_;
    my %args = (DB => $self->db);
    $args{hard} = $hard if $hard;
    $args{command} = $command if defined $command;
    my ($code, $body, $msg) = $self->{client}->call('synchronize', \%args);
    return 1 if $code eq 200;
    return 0 if $code eq 450;
    Carp::croak _errmsg($code, $msg);
}

sub set {
    my ($self, $key, $value, $xt) = @_;
    my %args = (DB => $self->db, key => $key, value => $value);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('set', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq 200;
    return;
}

sub add {
    my ($self, $key, $value, $xt) = @_;
    my %args = (DB => $self->db, key => $key, value => $value);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('add', \%args);
    return 1 if $code eq '200';
    return 0 if $code eq '450';
    Carp::croak _errmsg($code, $msg);
}

sub replace {
    my ($self, $key, $value, $xt) = @_;
    my %args = (DB => $self->db, key => $key, value => $value);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('replace', \%args);
    return 1 if $code eq '200';
    return 0 if $code eq '450';
    Carp::croak _errmsg($code, $msg);
}

sub append {
    my ($self, $key, $value, $xt) = @_;
    my %args = (DB => $self->db, key => $key, value => $value);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('append', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return;
}

sub increment {
    my ($self, $key, $num, $xt) = @_;
    my %args = (DB => $self->db, key => $key, num => $num);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('increment', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return $body->{num};
}

sub increment_double {
    my ($self, $key, $num, $xt) = @_;
    my %args = (DB => $self->db, key => $key, num => $num);
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('increment_double', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return $body->{num};
}

sub cas {
    my ($self, $key, $oval, $nval, $xt) = @_;
    my %args = (DB => $self->db, key => $key);
    $args{oval} = $oval if defined $oval;
    $args{nval} = $nval if defined $nval;
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('cas', \%args);
    return 1 if $code eq '200';
    return 0 if $code eq '450';
    Carp::croak _errmsg($code, $msg);
}

sub remove {
    my ($self, $key) = @_;
    my %args = (DB => $self->db, key => $key);
    my ($code, $body, $msg) = $self->{client}->call('remove', \%args);
    return 1 if $code eq '200';
    return 0 if $code eq '450';
    Carp::croak _errmsg($code, $msg);
}

sub get {
    my ($self, $key) = @_;
    my %args = (DB => $self->db, key => $key);
    my ($code, $body, $msg) = $self->{client}->call('get', \%args);
    if ($code eq 450) {
        return; # no value for key
    } elsif ($code eq 200) {
        return wantarray ? ($body->{value}, $body->{xt}) : $body->{value};
    } else {
        Carp::croak _errmsg($code, $msg);
    }
}

sub set_bulk {
    my ($self, $vals, $xt) = @_;
    my %args = (DB => $self->db);
    while (my ($k, $v) = each %$vals) {
        $args{"_$k"} = $v;
    }
    $args{xt} = $xt if defined $xt;
    my ($code, $body, $msg) = $self->{client}->call('set_bulk', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return $body->{num};
}

sub remove_bulk {
    my ($self, $keys) = @_;
    my %args = (DB => $self->db);
    for my $k (@$keys) {
        $args{"_$k"} = '';
    }
    my ($code, $body, $msg) = $self->{client}->call('remove_bulk', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return $body->{num};
}

sub get_bulk {
    my ($self, $keys) = @_;
    my %args = (DB => $self->db);
    for my $k (@$keys) {
        $args{"_$k"} = '';
    }
    my ($code, $body, $msg) = $self->{client}->call('get_bulk', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    my %ret;
    while (my ($k, $v) = each %$body) {
        if ($k =~ /^_(.+)$/) {
            $ret{$1} = $v;
        }
    }
    die "fatal error" unless keys(%ret) == $body->{num};
    return wantarray ? %ret : \%ret;
}

sub vacuum {
    my ($self, $step) = @_;
    my %args = (DB => $self->db);
    if (defined $step) {
        $args{step} = $step;
    }
    my ($code, $body, $msg) = $self->{client}->call('vacuum', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    return;
}

sub match_prefix {
    my ($self, $prefix, $max) = @_;
    my %args = (DB => $self->db, prefix => $prefix);
    $args{max} = $max if defined $max;
    my ($code, $body, $msg) = $self->{client}->call('match_prefix', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    my %ret;
    while (my ($k, $v) = each %$body) {
        if ($k =~ /^_(.+)$/) {
            $ret{$1} = $v;
        }
    }
    die "fatal error" unless keys(%ret) == $body->{num};
    return wantarray ? %ret : \%ret;
}

sub match_regex {
    my ($self, $regex, $max) = @_;
    my %args = (DB => $self->db, regex => $regex);
    $args{max} = $max if defined $max;
    my ($code, $body, $msg) = $self->{client}->call('match_regex', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    my %ret;
    while (my ($k, $v) = each %$body) {
        if ($k =~ /^_(.+)$/) {
            $ret{$1} = $v;
        }
    }
    die "fatal error" unless keys(%ret) == $body->{num};
    return wantarray ? %ret : \%ret;
}

sub match_similar {
    my ($self, $origin, $range, $utf8, $max) = @_;
    my %args = (DB => $self->db, origin => $origin);
    $args{range} = $max if defined $range;
    $args{utf}   = 1    if $utf8;
    $args{max}   = $max if defined $max;
    my ($code, $body, $msg) = $self->{client}->call('match_similar', \%args);
    Carp::croak _errmsg($code, $msg) unless $code eq '200';
    my %ret;

    while (my ($k, $v) = each %$body) {
        if ($k =~ /^_(.+)$/) {
            $ret{$1} = $v;
        }
    }
    die "fatal error" unless keys(%ret) == $body->{num};
    return wantarray ? %ret : \%ret;
}

1;
__END__

=encoding utf8

=head1 NAME

Cache::KyotoTycoon - KyotoTycoon client library

=head1 SYNOPSIS

    use Cache::KyotoTycoon;

    my $kt = Cache::KyotoTycoon->new(host => '127.0.0.1', port => 1978);
    $kt->set('foo' => bar');
    $kt->get('foo'); # => 'bar'

=head1 DESCRIPTION

KyotoTycoon.pm is L<KyotoTycoon|http://fallabs.com/kyototycoon/> client library for Perl5.

B<THIS MODULE IS IN ITS BETA QUALITY. THE API MAY CHANGE IN THE FUTURE>.

=head1 ERROR HANDLING POLICY

This module throws exception if got B<Server Error>.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item C<< timeout >>

Timeout value for each request in seconds.

I<Default>: 1 second

=item C<< host >>

Host name of server machine.

I<Default>: '127.0.0.1'

=item C<< port >>

Port number of server process. 

I<Default>: 1978 

=item C<< db >>

DB name or id.

I<Default>: 0

=back

=head1 METHODS

=over 4

=item C<< $kt->db() >>

Getter/Setter of DB name/id.

=item C<< my $cursor: Cache::KyotoTycoon::Cursor = $kt->make_cursor($cursor_number: Int); >>

Create new cursor object. This method returns instance of L<Cache::KyotoTycoon::Cursor>.

=item C<< my $res = $kt->echo($args) >>

The server returns $args. This method is useful for testing server.

$args is hashref.

I<Return>: the copy of $args.

=item C<< $kt->report() >>

Get server report.

I<Return>: server status information in hashref.

=item C<< my $output = $kt->play_script($name[, \%input]); >>

Call a procedure of the script language extension.

I<$name>: the name of the procedure to call.
I<\%input>: (optional): arbitrary records.

I<Return>: response of the script in hashref.

=item C<< my $info = $kt->status() >>

Get database status information.

I<Return>: database status information in hashref.

=item C<< $kt->clear() >>

Remove all elements for the storage.

I<Return>: Not a useful value.

=item C<< $kt->synchronize($hard:Bool, $command); >>

Synchronize database with file system.

I<$hard>: call fsync() or not.

I<$command>: call $command in synchronization state.

I<Return>: 1 if succeeded, 0 if $command returns false.

=item C<< $kt->set($key, $value, $xt); >>

Store I<$value> to I<$key>.

I<$xt>: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

I<Return>: not a useful value.

=item C<< my $ret = $kt->add($key, $value, $xt); >>

Store record. This method is not store if the I<$key> is already in the database.

I<$xt>: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

I<Return>: 1 if succeeded. 0 if $key is already in the db.

=item C<< my $ret = $kt->replace($key, $value, $xt); >>

Store the record, ignore if the record is not exists in the database.

I<$xt>: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

I<Return>: 1 if succeeded. 0 if $key is not exists in the database.

=item C<< my $ret = $kt->append($key, $value, $xt); >>

Store the record, append the $value to existent record if already exists entry.

I<$xt>: expiration time. If $xt>0, expiration time in seconds from now. If $xt<0, the epoch time. It is never remove if missing $xt.

I<Return>: not useful value. 

=item C<< my $ret = $kt->increment($key, $num, $xt); >>

I<$num>: incremental

I<Return>: value after increment. 

=item C<< my $ret = $kt->increment_double($key, $num, $xt); >>

I<$num>: incremental

I<Return>: value after increment. 

=item C<< my $ret = $kt->cas($key, $oval, $nval, $xt); >>

compare and swap.

I<$oval>: old value
I<$nval>: new value

I<Return>: 1 if succeeded, 0 if failed.

=item C<< $kt->remove($key); >>

Remove I<$key> from database.

I<Return> 1 if removed, 0 if record does not exists.

=item C<< my $val = $kt->get($key); >>

Get I<$key> from database.

I<Return>: the value from database in scalar context. ($value, $xt) in list context. I<undef> or empty list  if not exists in database.

=item C<< $kt->set_bulk(\%values); >>

Store multiple values in one time.

I<Return>: not useful value.

=item C<< $kt->remove_bulk(\@keys); >>

Remove multiple keys in one time.

I<Return>: not useful value.

=item C<< my $hashref = $kt->get_bulk(\@keys); >>

Get multiple values in one time.

I<Return>: records in hashref.

=item C<< $kt->vacuum([$step]); >>

Scan the database and eliminate regions of expired records.

I<input>: step: (optional): the number of steps. If it is omitted or not more than 0, the whole region is scanned.

I<Return>: not useful.

=item C<< my $hashref = $kt->match_prefix($prefix, $max); >>

Get list of matching keys.

I<Return>: records in hashref.

=item C<< my $hashref = $kt->match_regex($regex, $max); >>

Get list of matching keys.

I<Return>: records in hashref.

=item C<< my $hashref = $kt->match_similar($origin, $range, $utf8, $max); >>

Get list of matching keys.

I<Return>: records in hashref.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

=over 4

=item C<< L<KyotoTycoon|http://fallabs.com/kyototycoon/> >>

=item C<< http://fallabs.com/mikio/tech/promenade.cgi?id=99 >>

=back

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
