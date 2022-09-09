package CTK::Plugin::Log;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

CTK::Plugin::Log - Logger plugin

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use CTK;
    use CTK::Log qw/:constants/;

    my $ctk = CTK->new(
            plugins     => "log",
            ident       => "myapp",
            logfile     => "test.log",
            logger_init => 1,
        );
    print $ctk->log_debug("Logger say: %s", "foo");

=head1 DESCRIPTION

Logger plugin

=over 8

=item B<ident>

Specifies ident string for each log-record

See L<CTK::Log/"ident">

=item B<logfile>

Specifies log file

See L<CTK::Log/"file">

=item B<logdir>

Really not used

=item B<logger_init>

Flag enabling the logger autoloading

If flag is enabled, then the data from the configuration will be used
for logger initialization

=back

=head1 METHODS

=over 8

=item B<logger>

    die $ctk->logger->error unless $ctk->logger->status;

Returns logger-object

=item B<logger_init>

    $ctk->logger_init( ... );

Init logger. See L<CTK::Log/"new">


=item B<log_debug>

    $ctk->log_debug( "format %s", "value", ... );

Sends debug message in sprintf fromat to log. See L<CTK::Log>

=item B<log_info>

    $ctk->log_info( "format %s", "value", ... );

Sends informational message in sprintf fromat to log. See L<CTK::Log>

=item B<log_notice>

    $ctk->log_notice( "format %s", "value", ... );

Sends notice message in sprintf fromat to log. See L<CTK::Log>

=item B<log_warning>, B<log_warn>

    $ctk->log_warning( "format %s", "value", ... );

Sends warning message in sprintf fromat to log. See L<CTK::Log>

=item B<log_error>

    $ctk->log_error( "format %s", "value", ... );

Sends error message in sprintf fromat to log. See L<CTK::Log>

=item B<log_crit>

    $ctk->log_crit( "format %s", "value", ... );

Sends critical message in sprintf fromat to log. See L<CTK::Log>

=item B<log_alert>

    $ctk->log_alert( "format %s", "value", ... );

Sends alert message in sprintf fromat to log. See L<CTK::Log>

=item B<log_emerg>

    $ctk->log_emerg( "format %s", "value", ... );

Sends emergency message in sprintf fromat to log. See L<CTK::Log>

=item B<log_fatal>

    $ctk->log_fatal( "format %s", "value", ... );

Sends fatal message in sprintf fromat to log. See L<CTK::Log>

=item B<log_except>, B<log_exception>

    $ctk->log_except( "format %s", "value", ... );

Sends exception message in sprintf fromat to log. See L<CTK::Log>

=back

=head2 init

Initializer method. Internal use only

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<CTK::Plugin>, L<CTK::Log>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<CTK::Plugin>, L<CTK::Log>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use base qw/CTK::Plugin/;

use CTK::Log;

sub init {
    my $self = shift; # It is CTK object!
    $self->{logger} = undef;
    return 1;
}

__PACKAGE__->register_method(
    method    => "logger",
    callback  => sub { shift->{logger} });

__PACKAGE__->register_method(
    method    => "logger_init",
    callback  => sub {
        my $self = shift;
        my %args = @_;
        $args{ident} //= $self->{ident} // $self->project; # From args or object or is project
        return $self->{logger} = CTK::Log->new(%args);
});

__PACKAGE__->register_method(
    method    => "log_debug",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_debug(@_);
});
__PACKAGE__->register_method(
    method    => "log_info",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_info(@_);
});
__PACKAGE__->register_method(
    method    => "log_notice",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_notice(@_);
});
__PACKAGE__->register_method(
    method    => "log_warning",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_warning(@_);
});
__PACKAGE__->register_method(
    method    => "log_warn",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_warn(@_);
});
__PACKAGE__->register_method(
    method    => "log_error",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_error(@_);
});
__PACKAGE__->register_method(
    method    => "log_crit",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_crit(@_);
});
__PACKAGE__->register_method(
    method    => "log_alert",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_alert(@_);
});
__PACKAGE__->register_method(
    method    => "log_emerg",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_emerg(@_);
});
__PACKAGE__->register_method(
    method    => "log_fatal",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_fatal(@_);
});
__PACKAGE__->register_method(
    method    => "log_except",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_except(@_);
});
__PACKAGE__->register_method(
    method    => "log_exception",
    callback  => sub {
        my $self = shift;
        my $logger = $self->{logger} || return 0;
        return $logger->log_exception(@_);
});

1;

__END__
