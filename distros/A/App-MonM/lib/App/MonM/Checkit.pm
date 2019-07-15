package App::MonM::Checkit; # $Id: Checkit.pm 80 2019-07-08 10:41:47Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit - App::MonM checkit class

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

    use App::MonM::Checkit;

=head1 DESCRIPTION

App::MonM checkit class

=head2 new

    my $checker = new App::MonM::Checkit;

Returns checker object

=head2 check

    my $ostat = $checker->check({ ... });

Performs checking of checkit-sources by checkit rules (checkit config sections)

Returns status: 0 - PASS; 1 - FAIL

=head2 cleanup

    my $self = $checker->cleanup;

Flushes all working variables to defaults

=head2 code

    my $code = $checker->code;
    my $newcode = $checker->code(200);

Sets and returns response code (rc)

=head2 config

    my $conf = $checker->config;

Returns Checkit config structure

=head2 content

    my $content = $checker->content;
    my $newcontent = $checker->content("Foo Bar Baz");

Sets and returns the content value

=head2 error

    my $error = $checker->error;
    my $newerror = $checker->error("Blah-Blah-Blah");

Sets and returns the error value

=head2 message

    my $message = $checker->message;
    my $newmessage = $checker->message("Foo Bar Baz");

Sets and returns the message value

=head2 source

    my $source = $checker->source;
    my $newsource = $checker->source("http://foo.example.com");

Sets and returns the source value

=head2 status

    my $status = $checker->status;
    my $newstatus = $checker->status(1);

Sets and returns the status value

=head2 type

    my $type = $checker->type;
    my $newtype = $checker->type(1);

Sets and returns the type value

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.02';

use Class::C3::Adopt::NEXT;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use base qw/
        App::MonM::Checkit::HTTP
        App::MonM::Checkit::Command
        App::MonM::Checkit::DBI
    /;

use constant {
    TRUERX      => qr/^\s*(1|ok|pass|yes|true)/i, # True regexp
    FALSERX     => qr/^\s*(0|error|fail|no|false)/i, # False regext
    ORDERBY     => "true,false",
    TARGET      => "status",
    FAIL        => 0,
    PASS        => 1,
    QRTYPES => {
            ''  => sub { qr{$_[0]} },
            x   => sub { qr{$_[0]}x },
            i   => sub { qr{$_[0]}i },
            s   => sub { qr{$_[0]}s },
            m   => sub { qr{$_[0]}m },
            ix  => sub { qr{$_[0]}ix },
            sx  => sub { qr{$_[0]}sx },
            mx  => sub { qr{$_[0]}mx },
            si  => sub { qr{$_[0]}si },
            mi  => sub { qr{$_[0]}mi },
            ms  => sub { qr{$_[0]}sm },
            six => sub { qr{$_[0]}six },
            mix => sub { qr{$_[0]}mix },
            msx => sub { qr{$_[0]}msx },
            msi => sub { qr{$_[0]}msi },
            msix => sub { qr{$_[0]}msix },
    },
};

sub new {
    my $class = shift;
    my %args = @_;
    my $self = bless {%args}, $class;
    return $self->cleanup;
}
sub cleanup {
    my $self = shift;
    $self->{config}  = {}; # Config
    $self->{status}  = undef; # 1 - Ok; 0 - Error
    $self->{error}   = ''; # Error message
    $self->{code}    = undef; # 200
    $self->{type}    = undef; # http/dbi/command
    $self->{source}  = ''; # URL/DSN/Command
    $self->{message} = ''; # Message string or error
    $self->{content} = ''; # Content data or STDOUT data
    return $self;
}
sub config {
    my $self = shift;
    return $self->{config};
}
sub status {
    my $self = shift;
    my $v = shift;
    $self->{status} = $v if defined $v;
    return $self->{status};
}
sub error {
    my $self = shift;
    my $v = shift;
    $self->{error} = $v if defined $v;
    return $self->{error};
}
sub code {
    my $self = shift;
    my $v = shift;
    $self->{code} = $v if defined $v;
    return $self->{code};
}
sub type {
    my $self = shift;
    my $v = shift;
    $self->{type} = $v if defined $v;
    return $self->{type};
}
sub source {
    my $self = shift;
    my $v = shift;
    $self->{source} = $v if defined $v;
    return $self->{source};
}
sub message {
    my $self = shift;
    my $v = shift;
    $self->{message} = $v if defined $v;
    return $self->{message};
}
sub content {
    my $self = shift;
    my $v = shift;
    $self->{content} = $v if defined $v;
    return $self->{content};
}
sub check {
    my $self = shift;
    my $conf = shift;
    my $status = FAIL;
    $self->cleanup;
    $self->{config} = $conf if ref($conf) eq 'HASH';
    $self->type(lc(value($conf, 'type') || 'http'));
    $self->maybe::next::method();

    # Check response
    my $true_regexp = _qrreconstruct(value($conf, 'istrue'));
    my $false_regexp= _qrreconstruct(value($conf, 'isfalse'));
    my $orderby     = value($conf, 'orderby') || ORDERBY;
    my $target      = lc(value($conf, 'target') || TARGET);
    my $result;
    if ($target eq 'code') { $result = $self->code } # code
    elsif ($target eq 'message') { $result = $self->message } # message
    elsif ($target eq 'content') { $result = $self->content } # content
    else { $result = $self->status } # status
    $result //= '';

    # Check result
    my $rtt = (defined($true_regexp) && ref($true_regexp)) ? ref($true_regexp) : 'String';
    my $rtf = (defined($false_regexp) && ref($false_regexp)) ? ref($false_regexp) : 'String';
    if (($orderby =~ /false\s*\,\s*true/i) || ($orderby =~ /desc/i)) { # DESC
        if (defined $false_regexp) {
            $status = _cmp($result, $false_regexp, [FAIL, PASS]);
            $self->error("RESULT == FALSE (DEC ORDERED) [AS $rtf]") if !$status && !$self->error;
        } elsif (defined $true_regexp) {
            $status = _cmp($result, $true_regexp, [PASS, FAIL]);
            $self->error("RESULT != TRUE (DEC ORDERED) [AS $rtt]") if !$status && !$self->error;
        } else {
            $status = _cmp($result, FALSERX, [FAIL, PASS]);
            $self->error("RESULT == FALSE-DEFAULT (DEC ORDERED) [AS Regexp (DEFAULT)]") if !$status && !$self->error;
        }
    } else { # ASC
        if (defined $true_regexp) {
            $status = _cmp($result, $true_regexp, [PASS, FAIL]);
            $self->error("RESULT != TRUE (ASC ORDERED) [AS $rtt]") if !$status && !$self->error;
        } elsif (defined $false_regexp) {
            $status = _cmp($result, $false_regexp, [FAIL, PASS]);
            $self->error("RESULT == FALSE (ASC ORDERED) [AS $rtf]") if !$status && !$self->error;
        } else {
            $status = _cmp($result, TRUERX, [PASS, FAIL]);
            $self->error("RESULT != TRUE-DEFAULT (ASC ORDERED) [AS Regexp (DEFAULT)]") if !$status && !$self->error;
        }
    }
    return $status;
}

sub _qrreconstruct {
    # Returns regular expression (QR)
    # Gets from YAML::Type::regexp of YAML::Types
    # To input:
    #    !!perl/regexp (?i-xsm:^\s*(error|fault|no))
    # Translate to:
    #    qr/^\s*(error|fault|no)/i
    my $v = shift;
    return undef unless defined $v;
    return $v unless $v =~ /^\s*\!\!perl\/regexp\s*/i;
    $v =~ s/\s*\!\!perl\/regexp\s*//i;
    return qr{$v} unless $v =~ /^\(\?([\^\-xism]*):(.*)\)\z/s;
    my ($flags, $re) = ($1, $2);
    $flags =~ s/-.*//;
    $flags =~ s/^\^//;
    my $sub = QRTYPES->{$flags} || sub { qr{$_[0]} };
    return $sub->($re);
}
sub _cmp {
    my $s = shift || ''; # Text
    my $x = shift || ''; # Regext
    my $r = shift || [PASS, FAIL]; # Select [OK, ERROR]
    if (ref($x) eq 'Regexp') {
        return $r->[0] if $s =~ $x;
    } else {
        return $r->[0] if $s eq $x;
    }
    return $r->[1];
}

1;

__END__
