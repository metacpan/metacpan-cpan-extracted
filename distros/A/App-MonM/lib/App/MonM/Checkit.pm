package App::MonM::Checkit; # $Id: Checkit.pm 116 2022-08-27 08:57:12Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Checkit - App::MonM checkit class

=head1 VIRSION

Version 1.03

=head1 SYNOPSIS

    use App::MonM::Checkit;

=head1 DESCRIPTION

App::MonM checkit class

=head2 new

    my $checker = App::MonM::Checkit->new;

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

=head2 note

    my $note = $checker->note;
    $checker->note("Blah-Blah-Blah");

Sets and returns the note value

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

=head1 CONFIGURATION DIRECTIVES

General configuration options (directives) detailed describes in L<App::MonM/GENERAL DIRECTIVES>

The checkit configuration directives are specified in named
sections <checkit NAME> where NAME is the name of the checkit section.
The NAME is REQUIRED attribute. For example:

    <Checkit "foo">
        Enable      yes
        URL         https://www.example.com
        Target      code
        IsTrue      200
    </Checkit>

Each the checkit section can contain the following basic directives:

=over 4

=item B<Enable>

    Enable  yes

The main switcher of the checkit section

Default: no

=item B<Interval>

    Interval 20s

Defines the time interval between two checks

Format for time can be in any of the following forms:

    20   -- in 20 seconds
    180s -- in 180 seconds
    2m   -- in 2 minutes
    12h  -- in 12 hours
    1d   -- in 1 day
    3M   -- in 3 months
    2y   -- in 2 years
    3m   -- 3 minutes ago(!)

Default: 0

=item B<IsFalse>

    IsFalse  Error.

The definition of "What is bad?"

Default: !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))

Examples:

    IsFalse   !!perl/regexp (?i-xsm:^\s*(0|error|fail|no|false))
    IsFalse   0
    IsFalse   Error.

=item B<IsTrue>

    IsTrue  Ok.

The definition of "What is good?"

Default: !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))

Examples:

    IsTrue    !!perl/regexp (?i-xsm:^\s*(1|ok|pass|yes|true))
    IsTrue    1
    IsTrue    Ok.

=item B<OrderBy>

    OrderBy True,False

Controls the order in which True and False are evaluated.
The OrderBy directive, along with the IsTrue and IsFalse directives,
controls a two-pass resolve system. The first pass processes IsTrue
or IsFalse directive, as specified by the OrderBy directive.
The second pass parses the rest of the directive (IsFalse or IsTrue).

Ordering is one of:

    OrderBy True,False

First, IsTrue directive is evaluated. Next, IsFalse directive is evaluated.
If matches IsTrue, the check's result sets to true (PASSED), otherwise
result sets to false (FAILED)

    OrderBy False,True

First, IsFalse directive is evaluated. Next, IsTrue directive is evaluated.
If matches IsFalse, the check's result sets to false (FAILED), otherwise
result sets to true (PASSED)

Default: "True,False"

Examples:

    OrderBy   True,False
    OrderBy   ASC # Is same as: "True,False"
    OrderBy   False,True
    OrderBy   DESC # Is same as: "False,True"

=item B<SendTo>

    SendTo  Alice

Defines a List of Recipients for notifications.
There can be several such directives

Email addresses for sending notifications directly (See Channel SendMail):

    SendTo  foo@example.com
    SendTo  bar@example.com

...or SMS phone numbers (See Channel SMSGW):

    SendTo 11231230002
    SendTo +11231230001
    SendTo +1-123-123-0003

...or a notify users:

    SendTo Bob, Alice
    SendTo Fred

...or a notify groups:

    SendTo @Foo, @Bar
    SendTo @Baz

=item B<Target>

    Target    content

Defines a target for analysis of results

    status  - the status of the check operation is analyzed
    code    - the return code is analyzed (HTTP code, error code and etc.)
    content - the content is analyzed (data from HTTP response, data
              from command's STDOUT or data from DB)
    message - the message is analyzed (HTTP message, eg.)

Default: status

=item B<Trigger>

    Trigger "curl http://cam.com/[NAME]/[ID]?[MSISDN] >/tmp/photo.jpg"

Defines triggers (system commands) that runs before sending notifications
There can be several such directives
Each trigger can contents the variables for auto replacement, for example:

    Trigger  "mycommand1 "[MESSAGE]""

Replacement variables:

    [ID]        -- Internal ID of the message
    [MESSAGE], [MSG] -- The checker message content
    [MSISDN]    -- Phone number, recipient
    [NAME]      -- Checkit section name
    [NOTE]      -- The checker notes
    [RESULT]    -- The check result: PASSED/FAILED
    [SOURCE], [SRC]  -- Source string (URL, Command, etc.)
    [STATUS]    -- The checker status: OK/ERROR
    [SUBJECT], [SBJ] -- Subject of message (MIME)
    [TYPE]      -- Type of checkit: http/dbi/command

=item B<Type>

    Type      https

Defines checking type. As of today, three types are supported:
http(s), command and dbi(db)

Default: http

Examples:

    Type      http
    Type      dbi
    Type      command

=back

The HTTP checkit directives are describes in L<App::MonM::Checkit::HTTP/CONFIGURATION DIRECTIVES>,
the "Command" checkit directives are describes in L<App::MonM::Checkit::Command/CONFIGURATION DIRECTIVES>,
the DBI checkit directives are describes in L<App::MonM::Checkit::DBI/CONFIGURATION DIRECTIVES>

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.03';

use mro;

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use parent qw/
        App::MonM::Checkit::HTTP
        App::MonM::Checkit::Command
        App::MonM::Checkit::DBI
    /;

use constant {
    TRUERX      => qr/^\s*(1|ok|pass|yes|true)/i, # True regexp
    FALSERX     => qr/^\s*(0|error|fail|no|false)/i, # False regexp
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
    $self->{error}   = ''; # Error string
    $self->{code}    = undef; # 200
    $self->{type}    = undef; # http/dbi/command
    $self->{source}  = ''; # URL/DSN/Command
    $self->{message} = ''; # Message string or error
    $self->{content} = ''; # Content data or STDOUT data
    $self->{note} = ''; # Note
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
sub note {
    my $self = shift;
    my $v = shift;
    $self->{note} = $v if defined $v;
    return $self->{note};
}
sub check {
    my $self = shift;
    my $conf = shift;
    my $result = FAIL;
    $self->cleanup;
    $self->{config} = $conf if ref($conf) eq 'HASH';
    $self->type(lc(lvalue($conf, 'type') || 'http'));
    $self->maybe::next::method();

    # Check response
    my $true_regexp = _qrreconstruct(lvalue($conf, 'istrue'));
    my $false_regexp= _qrreconstruct(lvalue($conf, 'isfalse'));
    my $orderby     = lvalue($conf, 'orderby') || ORDERBY;
    my $target      = lc(lvalue($conf, 'target') || TARGET);
    my $test; # Value for testing
    if ($target eq 'code') { $test = $self->code } # code
    elsif ($target eq 'message') { $test = $self->message } # message
    elsif ($target eq 'content') { $test = $self->content } # content
    else { # status (default)
        $target = TARGET;
        $test = $self->status;
    }
    $test //= '';

    # Check test value
    my ($direct, $rule);
    if (($orderby =~ /false\s*\,\s*true/i) || ($orderby =~ /desc/i)) { # DESC
        $direct = "DESC";
        if (defined $false_regexp) {
            $result = _cmp($test, $false_regexp, [FAIL, PASS]);
            $rule = $result ? "!= FALSE" : "== FALSE";
        } elsif (defined $true_regexp) {
            $result = _cmp($test, $true_regexp, [PASS, FAIL]);
            $rule = $result ? "== TRUE" : "!= TRUE";
        } else {
            $result = _cmp($test, FALSERX, [FAIL, PASS]);
            $rule = $result ? "!= FALSE-DEFAULT" : "== FALSE-DEFAULT";
        }
    } else { # ASC
        $direct = "ASC";
        if (defined $true_regexp) {
            $result = _cmp($test, $true_regexp, [PASS, FAIL]);
            $rule = $result ? "== TRUE" : "!= TRUE";
        } elsif (defined $false_regexp) {
            $result = _cmp($test, $false_regexp, [FAIL, PASS]);
            $rule = $result ? "!= FALSE" : "== FALSE";
        } else {
            $result = _cmp($test, TRUERX, [PASS, FAIL]);
            $rule = $result ? "== TRUE-DEFAULT" : "!= TRUE-DEFAULT";
        }
    }

    # Set errors and note
    my $rtt = (defined($true_regexp) && ref($true_regexp)) ? ref($true_regexp) : 'String';
    my $rtf = (defined($false_regexp) && ref($false_regexp)) ? ref($false_regexp) : 'String';
    my $note = sprintf("Check [%s] %s: RESULT [%s] %s (%s) [%s]",
        $self->type,
        $result ? "PASSED" : "FAILED",
        $target, $rule, $direct,
        $rule =~ /DEF/ ? 'Regexp (DEFAULT)' : $rule =~ /TRUE/ ? $rtt : $rtf);
    $self->note($note);
    $self->error($note) if !$result && !$self->error; # Set error if NO erorrs from backends

    return $result;
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
