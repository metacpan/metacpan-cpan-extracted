package ComXo::Call2;

use strict;
use warnings;
our $VERSION = '0.02';

use Carp;
use SOAP::Lite;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );

my %possible_err = (
    '*01' => 'Number Failed',
    '*02' => 'Alias Does Not Exist',
    '*03' => 'No Call Records',
    '*04' => 'Account details incorrect',
    '*05' => 'Not enough credit on account',
    '*06' => 'ID not recognised',
    '*07' => 'Possible Fraud Attempt',
);

use vars qw/$errstr/;
sub errstr { return $errstr }

sub new {    ## no critic (ArgUnpacking)
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    for (qw/account password/) {
        $args{$_} || croak "Param $_ is required.";
    }

    $args{soup} = SOAP::Lite->proxy("https://www.comxo.com/webservices/buttontel.cfc")->uri("http://webservices");
    $args{soup}->transport->ssl_opts(
        verify_hostname => 0,
        SSL_verify_mode => SSL_VERIFY_NONE
    );
    SOAP::Trace->import('all') if $args{debug};    # for debug

    return bless \%args, $class;
}

sub InitCall {                                     ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my $anumber = $args{anumber} or croak 'anumber is required.';
    my $bnumber = $args{bnumber} or croak 'bnumber is required.';
    $anumber =~ s/^[+]//;
    $bnumber =~ s/^[+]//;
    croak 'invalid anumber' unless $anumber =~ /^[0-9]+$/;
    croak 'invalid bnumber' unless $bnumber =~ /^[0-9]+$/;

    $args{amessage} = '0' unless exists $args{amessage};
    $args{bmessage} = '0' unless exists $args{bmessage};
    $args{delay}    = 0   unless exists $args{delay};

    my @args = ();
    foreach my $x (
        'account', 'password', 'amessage', 'bmessage', 'adigits',  'bdigits', 'anumber', 'bnumber',
        'delay',   'alias',    'name',     'company',  'postcode', 'email',   'product', 'url',
        'extra1',  'extra2',   'extra3',   'extra4',   'extra5'
        )
    {
        $args{$x} = '' unless exists $args{$x};
        my $v = $args{$x};
        $v = $self->{$x} if not $v and exists $self->{$x};    # self for account/password
        my $type = ($x eq 'delay') ? 'double' : 'string';
        push @args, SOAP::Data->type($type)->name($x)->value($v);
    }

    my $som = $self->{soup}->InitCall(@args);
    if ($som->fault) {
        $errstr = $som->faultstring;
        return;
    }
    if (exists $possible_err{$som->result}) {
        $errstr = $possible_err{$som->result};
        return;
    }
    return $som->result;
}

sub GetAllCalls {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    my @args;
    foreach my $x ('account', 'password', 'fromdate', 'todate') {
        $args{$x} = '' unless exists $args{$x};
        my $v = $args{$x};
        $v = $self->{$x} if not $v and exists $self->{$x};    # self for account/password
        my $type = 'string';
        push @args, SOAP::Data->type($type)->name($x)->value($v);
    }

    my $som = $self->{soup}->GetAllCalls(@args);
    if ($som->fault) {
        $errstr = $som->faultstring;
        return;
    }
    if (exists $possible_err{$som->result}) {
        $errstr = $possible_err{$som->result};
        return;
    }
    my $text = $som->result;
    my @calls = split(/[\r\n]+/, $text);
    @calls = map { [split(',')] } @calls;
    return wantarray ? @calls : \@calls;
}

sub GetCallStatus {
    my ($self, $callid) = @_;

    $callid or croak "callid is required.";

    my @args;
    foreach my $x ('account', 'password') {
        push @args, SOAP::Data->type('string')->name($x)->value($self->{$x});
    }
    push @args, SOAP::Data->type('double')->name('callid')->value($callid);

    my $som = $self->{soup}->GetCallStatus(@args);
    if ($som->fault) {
        $errstr = $som->faultstring;
        return;
    }
    if (exists $possible_err{$som->result}) {
        $errstr = $possible_err{$som->result};
        return;
    }
    my $text = $som->result;
    my @status = split(',', $text);
    return wantarray ? @status : \@status;
}

1;
__END__

=encoding utf-8

=head1 NAME

ComXo::Call2 - API for the ComXo Call2 service (www.call2.com)

=head1 SYNOPSIS

  use ComXo::Call2;

=head1 DESCRIPTION

ComXo::Call2 is a perl implementation for L<http://www.comxo.com/webservices/buttontel.cfm>

=head1 METHODS

=head2 new

=over 4

=item * account

required.

=item * password

required.

=item * debug

enable SOAP trace. default is off.

=back

=head2 InitCall

Initiate A Call

    my $call_id = $call2->InitCall(
        anumber  => $call_to,   # to number
        bnumber  => $call_from, # from number
        alias    => 'alias',    # optional
    ) or die $call2->errstr;

=over 4

=item * amessage

integer - ID of message to play to customer (0=no message, 15=standard message)

=item * bmessage

integer - ID of message to play to company (0=no message, 15=standard message)

=item * anumber

string, anumber - Customer Phone Number

=item * bnumber

string, bnumber - Company Phone Number

=item * delay

integer, delay - Delay in Seconds

=item * alias

string, alias - Button Alias (A preset alias or your own identifier)

=item * name

string, name - Customer's Name

=item * company

string, company - Customer's Company

=item * postcode

string, postcode - Customer's Post Code

=item * email

string, email - Customer's Email Address

=item * product

string, product - Product Interest

=item * url

string, url - URL of Button

=item * extra1

string, extra1 - Additional Information 1

=item * extra2

string, extra2 - Additional Information 2

=item * extra3

string, extra3 - Additional Information 3

=item * extra4

string, extra4 - Additional Information 4

=item * extra5

string, extra5 - Additional Information 5

=back

=head2 GetAllCalls

Get All Call Details

    my @calls = $call2->GetAllCalls(
        fromdate => $dt_from,
        todate   => $dt_to
    ) or die $call2->errstr;

Array of arrayref of

Call Reference,Start Time,A Number,B Number,A Clear Reason,B Clear Reason,A Status,B Status,Duration(seconds),
A Country,B Country,Cost,Name,Company,Post Code,Email,Product,URL,Extra1,Extra2,Extra3,Extra4,Extra5,AAnswered,BAnswered

=over 4

=item * fromdate

datetime, fromdate - Date (YYYY-MM-DD HH:MM)

=item * todate

datetime, todate - Date (YYYY-MM-DD HH:MM)

=back

=head2 GetCallStatus

Get Call Details

    my $call_status = $call2->GetCallStatus($call_id) or die $call2->errstr;

Arrayref of

Call Reference,Start Time,A Number,B Number,A Clear Reason,B Clear Reason,A Status,B Status,Duration(seconds),
A Country,B Country,Cost,Name,Company,Post Code,Email,Product,URL,Extra1,Extra2,Extra3,Extra4,Extra5,AAnswered,BAnswered

=head2 errstr

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
