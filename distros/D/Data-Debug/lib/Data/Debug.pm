package Data::Debug;

# ABSTRACT: allows for basic data dumping and introspection.

####----------------------------------------------------------------###
##  Copyright 2014 - Bluehost                                         #
##  Distributed under the Perl Artistic License without warranty      #
####----------------------------------------------------------------###

use strict;
use base qw(Exporter);
our @EXPORT    = qw(debug debug_warn);
our @EXPORT_OK = qw(debug_text debug_html debug_plain caller_trace);
our $QR_TRACE1 = qr{ \A (?: /[^/]+ | \.)* / (?: perl | lib | cgi(?:-bin)? ) / (.+) \Z }x;
our $QR_TRACE2 = qr{ \A .+ / ( [\w\.\-]+ / [\w\.\-]+ ) \Z }x;

our $VERSION = '0.04';

BEGIN {
    ### cache mod_perl version (light if or if not mod_perl)
    my $v = (! $ENV{'MOD_PERL'}) ? 0                                                                                                                                            
        # mod_perl/1.27 or mod_perl/1.99_16 or mod_perl/2.0.1
        # if MOD_PERL is set - don't die if regex fails - just assume 1.0
        : ($ENV{'MOD_PERL'} =~ m{ ^ mod_perl / (\d+\.[\d_]+) (?: \.\d+)? $ }x) ? $1
        : '1.0_0';
    sub _mod_perl_version () { $v }
    sub _is_mod_perl_1    () { $v <  1.98 && $v > 0 }
    sub _is_mod_perl_2    () { $v >= 1.98 }

    ### cache apache request getter (light if or if not mod_perl)
    my $sub;
    if (_is_mod_perl_1) { # old mod_perl
        require Apache;
        $sub = sub { Apache->request };
    } elsif (_is_mod_perl_2) {
        if (eval { require Apache2::RequestRec }) { # debian style
            require Apache2::RequestUtil;
            $sub = sub { Apache2::RequestUtil->request };
        } else { # fedora and mandrake style
            require Apache::RequestUtil;
            $sub = sub { Apache->request };
        }
    } else {
        $sub = sub {};
    }
    sub apache_request_sub () { $sub }
}

my %LINE_CACHE;
my $DEPARSE;

sub set_deparse { $DEPARSE = 1 }

sub _dump {
    local $Data::Dumper::Deparse   = $DEPARSE && eval {require B::Deparse};
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Useqq     = 1;
    local $Data::Dumper::Quotekeys = 0;

    my $ref;
    for (ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_) { last if UNIVERSAL::isa($_, 'HASH') && ($ref = $_->{'dbh_cache'}) }
    local @$ref{keys %$ref} = ('hidden')x(keys %$ref) if $ref;

    return Data::Dumper->Dumpperl(\@_);
}

###----------------------------------------------------------------###

sub _what_is_this {
    my ($pkg, $file, $line_n, $called) = caller(1);
    $called =~ s/.+:://;

    my $line = '';
    if (defined $LINE_CACHE{"$file:$line_n"}) {
        # Just use global cache
        $line = $LINE_CACHE{"$file:$line_n"};
    }
    else {
        if (open my $fh, '<', $file) {
            my $n = 0;
            my $ignore_after = $line_n + 1000;
            while (defined(my $l = <$fh>)) {
                if (++$n == $line_n) {
                    $LINE_CACHE{"$file:$line_n"} = $line = $l;
                }
                elsif ($l =~ /debug/) {
                    $LINE_CACHE{"$file:$n"} = $l;
                }
                elsif ($n > $ignore_after) {
                    last;
                }
            }
            close $fh;
        }
        $line ||= "";
        $LINE_CACHE{"$file:$line_n"} = $line;
    }

    $file =~ s/$QR_TRACE1/$1/ || $file =~ s/$QR_TRACE2/$1/; # trim up extended filename

    require Data::Dumper;
    local $Data::Dumper::Indent = 1 if $called eq 'debug_warn';

    # dump it out
    my @dump = map {_dump($_)} @_;
    my @var  = ('$VAR') x @dump;
    my $hold;
    if ($line =~ s/^ .*\b \Q$called\E ( \s* \( \s* | \s+ )//x
        && ($hold = $1)
        && ($line =~ s/ \s* \b if \b .* \n? $ //x
            || $line =~ s/ \s* ; \s* $ //x
            || $line =~ s/ \s+ $ //x)) {
        $line =~ s/ \s*\) $ //x if $hold =~ /^\s*\(/;
        my @_var = map {/^[\"\']/ ? 'String' : $_} split (/\s*,\s*/, $line);
        @var = @_var if $#var == $#_var;
    }

    # spit it out
    if ($called eq 'debug_html'
        || ($called eq 'debug' && $ENV{'REQUEST_METHOD'})) {
        my $html = "<pre style=\"text-align:left\"><b>$called: $file line $line_n</b>\n";
        for (0 .. $#dump) {
            $dump[$_] =~ s/(?<!\\)\\n/\n/g;
            $dump[$_] = _html_quote($dump[$_]);
            $dump[$_] =~ s|\$VAR1|<span class=debugvar><b>$var[$_]</b></span>|g;
            $html .= $dump[$_];
        }
        $html .= "</pre>\n";
        return $html if $called eq 'debug_html';
        my $typed = content_typed();
        print_content_type();
        print $typed ? $html : "<!DOCTYPE html>$html";
    } else {
        my $txt = "$called: $file line $line_n\n";
        for (0 .. $#dump) {
            $dump[$_] =~ s|\$VAR1|$var[$_]|g;
            $txt .= $dump[$_];
        }
        $txt =~ s/\s*$/\n/;
        return $txt if $called eq 'debug_text';

        if ($called eq 'debug_warn') {
            warn $txt;
        }
        else {
            print $txt;
        }
    }
    return @_[0..$#_];
}

sub debug      { &_what_is_this }
sub debug_warn { &_what_is_this }
sub debug_text { &_what_is_this }
sub debug_html { &_what_is_this }

sub debug_plain {
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Terse = 1;
    my $dump = join "\n", map {_dump($_)} @_;
    print $dump if !defined wantarray;
    return $dump;
}


sub content_typed {
    if (my $r = apache_request_sub()->()) {
        return $r->bytes_sent;
    } else {
        return $ENV{'CONTENT_TYPED'} ? 1 : undef;
    }
}

sub print_content_type {
    my $type = "text/html";

    if (my $r = apache_request_sub()->()) {
        return if $r->bytes_sent;
        $r->content_type($type);
        $r->send_http_header if _is_mod_perl_1;
    } else {
        if (! $ENV{'CONTENT_TYPED'}) {
            print "Content-Type: $type\r\n\r\n";
            $ENV{'CONTENT_TYPED'} = '';
        }
        $ENV{'CONTENT_TYPED'} .= sprintf("%s, %d\n", (caller)[1,2]);
    }
}

sub _html_quote {
    my $value = shift;
    return '' if ! defined $value;
    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    return $value;
}

sub caller_trace {
    eval { require 5.8.0 } || return ['Caller trace requires perl 5.8'];
    require Carp::Heavy;
    local $Carp::MaxArgNums = 5;
    local $Carp::MaxArgLen  = 20;
    my $i    = shift || 0;
    my $skip = shift || {};
    my @i = ();
    my $max1 = 0;
    my $max2 = 0;
    my $max3 = 0;
    while (my %i = Carp::caller_info(++$i)) {
        next if $skip->{$i{file}};
        $i{sub_name} =~ s/\((.*)\)$//;
        $i{args} = $i{has_args} ? $1 : "";
        $i{sub_name} =~ s/^.*?([^:]+)$/$1/;
        $i{file} =~ s/$QR_TRACE1/$1/ || $i{file} =~ s/$QR_TRACE2/$1/;
        $max1 = length($i{sub_name}) if length($i{sub_name}) > $max1;
        $max2 = length($i{file})     if length($i{file})     > $max2;
        $max3 = length($i{line})     if length($i{line})     > $max3;
        push @i, \%i;
    }
    foreach my $ref (@i) {
        $ref = sprintf("%-${max1}s at %-${max2}s line %${max3}s", $ref->{sub_name}, $ref->{file}, $ref->{line})
            . ($ref->{args} ? " ($ref->{args})" : "");
    }
    return \@i;
}

###----------------------------------------------------------------###

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Debug - allows for basic data dumping and introspection.

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Data::Debug; # auto imports debug, debug_warn
  use Data::Debug qw(debug debug_text caller_trace);

  my $hash = {
      foo => ['a', 'b', 'Foo','a', 'b', 'Foo','a', 'b', 'Foo','a'],
  };

  debug $hash; # or debug_warn $hash;

  debug;

  debug "hi";

  debug $hash, "hi", $hash;

  debug \@INC; # print to STDOUT, or format for web if $ENV{REQUEST_METHOD}

  debug_warn \@INC;  # same as debug but to STDOUT

  print FOO debug_text \@INC; # same as debug but return dump

  # ALSO #

  use Data::Debug qw(debug);

  debug; # same as debug

=head1 DESCRIPTION

Uses the base Data::Dumper of the distribution and gives it nicer formatting - and
allows for calling just about anytime during execution.

Calling Data::Debug::set_deparse() will allow for dumped output of subroutines
if available.

   perl -e 'use Data::Debug;  debug "foo", [1..10];'

See also L<Data::Dumper>.

Setting any of the Data::Dumper globals will alter the output.

=head1 FUNCTIONS

=head2 debug()

Prints out pretty output to STDOUT.  Formatted for the web if on the web.

It also returns the items called for it so that it can be used inline.

   my $foo = debug [2,3]; # foo will contain [2,3]

=head2 debug_warn()

Prints to STDERR.

=head2 debug_text()

Return the text as a scalar.

=head2 debug_plain()

Return a plainer string as a scalar.  This basically just avoids the attempt to
get variable names and line numbers and such.

If passed multiple values, each value is joined by a newline.  This has the
effect of placing an empty line between each one since each dump ends in a
newline already.

If called in void context, it displays the result on the default filehandle
(usually STDOUT).

=head2 debug_html()

HTML-ized output

=head2 caller_trace()

Caller trace returned as an arrayref.  Suitable for use like "debug caller_trace".
This does require at least perl 5.8.0's Carp.

=head2 content_typed()

Return truth if a content-type was sent

=head2 set_deparse()

set $DEPARSE=1

=head2 print_content_type()

sends the 'text/html' header, properly formatted to whether or not one has been sent

=head2 apache_request_sub()

Looks to see if you are in a mod_perl environment, and then retrieve the appropriate apache request object

=head1 AUTHORS

=over 4

=item *

'Paul Seamons <paul@seamons.com>'

=item *

'Russel Fisher <geistberg@gmail.com>'

=back

=head1 CONTRIBUTORS

=for stopwords gbingham James Lance Jason Hall

=over 4

=item *

gbingham <gbingham@bluehost.com>

=item *

James Lance <james@thelances.net>

=item *

Jason Hall <jayce@lug-nut.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Seamons.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
