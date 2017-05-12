package Combinator;

use 5.010;
use strict;
use warnings;

=head1 NAME

Combinator - Intuitively write async program serially, parallel, or circularly

=head1 VERSION

Version 0.4.2

=cut

use version;
our $VERSION = qv 'v0.4.2';

=head1 SYNOPSIS

The following is the basic form for serializing a sequence of async code blocks:

    use Combinator;
    use AE;

    my $cv = AE::cv;
    {{com
        print "sleep 1 second\n";
        my $t = AE::timer 1, 0, {{next}};
      --ser
        undef $t;
        my $t = AE::timer 0.5, 0, {{next}};
        print "sleep 0.5 second\n"; # this line will be executed before the next block
      --ser
        undef $t;
        print "wait for 3 timers at the same time\n";
        my $t1 = AE::timer 1, 0, {{next}};
        my $t2 = AE::timer 2, 0, {{next}};
        my $t3 = AE::timer 1.5, 0, {{next}};
      --ser
        undef $t1; undef $t2; undef $t3;
        # after the max time interval of them (2 seconds)
        print "the next block will start immediately\n";
      --ser
        print "done\n";
        $cv->send;
    }}com
    $cv->recv;

The following block will wait for previous block's end and all the {{next}}s in the
previous block been called.

And also, it could be nested {{com..}}com blocks in the code block.
the following block will also wait for completion of these {{com..}}com blocks.
Thus, you can distribute independent code blocks into each one,
and optionally use 'return' to stop the {{com..}}com block.

    use Combinator;
    use AE;

    my $cv = AE::cv;
    {{com
        print "all start\n";
        {{com
            print "A begin\n";
            my $t = AE::timer 1, 0, {{next}};
          --ser
            undef $t;
            print "A second\n";
            my $t = AE::timer 1, 0, {{next}};
          --ser
            undef $t;
            print "A done\n";
            return; # this will stop the later part of this {{com..}}com block
          --ser
            print "never be here\n";
          --ser
            print "never be here either\n";
        }}com

        {{com
            print "B begin\n";
            my $t = AE::timer .7, 0, {{next}};
          --ser
            print "B second\n";
            my $t = AE::timer .7, 0, {{next}};
          --ser
            print "B done\n";
        --com # this is a short cut for }}com {{com
            print "C begin\n";
            my $t = AE::timer .4, 0, {{next}};
          --ser
            print "C second\n";
            my $t = AE::timer .4, 0, {{next}};
          --ser
            print "C done\n";
        }}com
      --ser
        print "all done\n";
        $cv->send;
    }}com
    $cv->recv;

And also, the following block will get all the arguments when {{next}} is called.
This is useful when integrating with other callback based module.

    use Combinator;
    use AE;
    use AnyEvent::HTTP;

    my $cv = AE::cv;
    {{com
        print "start\n";
        http_get "http://search.cpan.org/", {{next}};
      --ser
        my($data, $headers) = @_; # the cb args of http_get

        if( !defined($data) ) {
            print "Fetch cpan fail\n";
            return;
        }
        print "Fetch cpan success\n";

        http_get "http://www.perl.org/", {{next}};
      --ser
        my($data, $headers) = @_; # the cb args of http_get

        if( !defined($data) ) {
            print "Fetch perl fail\n";
            return;
        }
        print "Fetch perl success\n";

        print "done\n";
        $cv->send;
    }}com
    $cv->recv;

If there are multiple {{next}}s been called,
You'll get all the args concatenated together.

    use Combinator;
    use AE;

    my $cv = AE::cv;
    {{com
        {{next}}->(0);
        {{com
            my $t = AE::timer 1, 0, {{next}};
          --ser
            undef $t;
            {{next}}->(1);
        --com
            my $t = AE::timer .6, 0, {{next}};
          --ser
            undef $t;
            {{next}}->(2);
        --com
            my $t = AE::timer .3, 0, {{next}};
          --ser
            undef $t;
            {{next}}->(3);
        }}com
        {{next}}->(4);
      --ser
        print "@_\n"; # 0 4 3 2 1
        $cv->send;
    }}com

If you want to process each {{next}}'s args seperately,
you might use seperate {{com..}}com, and then gather the final result.

    use Combinator;
    use AnyEvent::HTTP;
    use Data::Dumper;

    my $cv = AE::cv;
    {{com
        my @health;
        for my $url (qw(http://www.perl.org/ http://search.cpan.org/)) {{com
            my $url = $url; # we need to copy-out the $url here,
                    # or the later part of the {{com..}}com will
                    # not get the correct one.
            http_get $url, {{next}};
          --ser
            push @health, [$url, defined($_[0])];
        }}com
      --ser
        print Dumper(\@health);
        $cv->send;
    }}com

If you wish to run a {{com..}}com repeatly. Use {{cir instead of {{com,
or use --cir instead of --com if it's not the first block.

    use Combinator;
    use AE;
    use AnyEvent::Socket;
    use AnyEvent::Handle;

    tcp_server 0, 8888, sub {
        my($fh, $host, $port) = @_;

        my $hd; $hd = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                print "socket $host:$port end.\n";
                undef $hd;
            },
        );

        {{cir
            $hd->push_read( line => {{next}} );
          --ser
            my($hd, $line) = @_;
            $hd->push_write($line.$/);
        }}com
    };

    AE::cv->recv;

If you need finer controlled {{next}}, use {{nex .. }}nex block to
replace {{next}}.

    use Combinator;
    use AE;
    use AnyEvent::HTTP;

    {{com
        my($a_res, $b_res);
        http_get 'http://site.a/', {{nex $a_res = $_[1] }}nex;
        http_get 'http://site.b/', {{nex $b_res = $_[1] }}nex;
      --ser
        print "Completed!\n";
        print "SiteA = $a_res\n";
        print "SiteB = $b_res\n";
    }}com

    AE::cv->recv;

Though without {{nex .. }}nex block, you can still write:

    use Combinator;
    use AE;
    use AnyEvent::HTTP;

    {{com
        my($a_res, $b_res);
        {{com
            http_get 'http://site.a/', {{next}};
          --ser
            $a_res = $_[1];
        --com
            http_get 'http://site.b/', {{next}};
          --ser
            $b_res = $_[1];
        }}com
      --ser
        print "Completed!\n";
        print "SiteA = $a_res\n";
        print "SiteB = $b_res\n";
    }}com

    AE::cv->recv;

It's up to you to choose which one to use.

=head1 WHEN YOU SHOULD USE THIS MODULE

=head2 When you are tired of writing layered closures

    use AnyEvent::DBI;

    ...

    $dbh->exec("select ...", sub {
        ...
        $dbh->exec("select ...", sub {
            ...
            $dbh->exec("select ...", sub {
                ...
                $dbh->exec("select ...", sub {
                    ...
                });
            });
        });
    });

You can achieve that like this:

    use Combinator;
    use AnyEvent::DBI;

    ...

    {{com
        $dbh->exec("select ...", {{next}});
        ...
      --ser
        $dbh->exec("select ...", {{next}});
        ...
      --ser
        $dbh->exec("select ...", {{next}});
        ...
      --ser
        $dbh->exec("select ...", {{next}});
        ...
    }}com

=head2 When you are tired of manually using condition variable to
achieve asynchronous concurrent program.

    use AE;

    ...

    AE::io $fh, 0, sub {
        my($file_a, $file_b);
        my $cv = AE::cv {
            my $cv2 = AE::cv {
                sock_send($admin, "done", sub{});
            };
            $cv2->begin;
            for(@user) {
                sock_send($_, $file_a.$file_b, sub { $cv2->end });
            }
            $cv2->end;
        };

        $cv->begin;

        $cv->begin;
        read_a_file(..., sub { $file_a = ...; $cv->end });
        $cv->begin;
        read_a_file(..., sub { $file_b = ...; $cv->end });

        $cv->end;
    };

You can achieve that like this:

    use Combinator;
    use AE;

    ...

    AE::io $fh, 0, sub {{com
        my($file_a, $file_b);
        {{com
            read_a_file(..., {{next}});
          --ser
            $file_a = ...;
        --com
            read_a_file(..., {{next}});
          --ser
            $file_b = ...;
        }}com
      --ser
        for(@user) {
            sock_send($_, $file_a.$file_b, {{next}});
        }
      --ser
        sock_send($admin, "done", {{next}});
    }}com

=head2 When you are afraid of using recursion to achieve LOOP
in an event-driven program.

    use AE;

    ...

    sub sooner {
        my $int = shift;
        print "$int\n";
        return if $int <= 0;
        my $t = AE::timer $int, 0, sub {
            undef $t;
            sooner($int-1);
        };
    }
    sooner(3);

You can achieve that like this:

    use AE;

    ...

    sub sooner {{com
        my $int = shift;
        my $t;
        {{cir
            print "$int\n";
            if( $int <= 0 ) {
                undef $t;
                return;
            }
            $t = AE::timer $int, 0, {{next}};
            --$int;
        }}com
    }}com
    sooner(3);

=head1 OPTIONS

You can set some options like this:

    use Combinator verbose => 1, begin => qr/\{\{COM\b/;

Possible options are:

=head2 verbose => 0

Set to 1 if you want to see the generated code.

=head2 begin => qr/\{\{com\b/

=head2 cir_begin => qr/\{\{cir\b/

=head2 nex_begin => qr/\{\{nex\b/

=head2 ser => qr/--ser\b/

=head2 par => qr/--com\b/

=head2 cir_par => qr/--cir\b/

=head2 end => qr/\}\}(?:com|cir|nex)\b/

=head2 next => qr/\{\{next\}\}/

You can change these patterns to what you want

=head1 CAVEATS

=head2 PATTERNS IN COMMENTS OR STRINGS

This module is implemented by filter your code directly.
So it will still take effect if the pattern ({{com, {{next}, ... etc)
show up in comments or strings. So avoid it!

You may use options listed above to change the default patterns.

=head2 INFINITE RECURSION

The {{cir or --cir is implemented by recursion.
That is, if you using that without going through any event loop,
it may result in infinite recursion.

You can avoid that by a zero time timer. For example:

    {{cir
        print "Go\n";
    }}com

This will crash immediately due to the deep recursion.
You can replace it by:

    {{cir
        print "Go\n";
        my $t; $t = AE::timer 0, 0, {{next}};
      --ser
        undef $t;
    }}com

=head2 LATE STARTED NEXT

Each serial block will start to run once the previous block
is finished and all the started {{next}}s have been called.
That is, the un-started {{next}} is not counted.

Here's an example:

    {{com
        my $t; $t = AE::timer 1, 0, sub {
            undef $t;
            print "A\n";
            {{next}}->();
        };
      --ser
        print "B\n";
    }}com

It'll print "B" before "A", cause when the later block
is checking if the previous one is finished, the {{next}}
in the timer callback hasn't started.

You can fix it by:

    {{com
        my $next = {{next}};
        my $t; $t = AE::timer 1, 0, sub {
            undef $t;
            print "A\n";
            $next->();
        };
      --ser
        print "B\n";
    }}com

Then "B" will come after "A";

=head1 DEMO

Look up the file eg/demo_all.pl

=cut


=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to github L<http://github.com/CindyLinz/Perl-Combinator>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Combinator


You can also look for information at:

=over 4

=item * github: 

L<http://github.com/CindyLinz/Perl-Combinator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Combinator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Combinator>

=item * Search CPAN

L<http://search.cpan.org/dist/Combinator/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

use Filter::Simple;
use Guard;
use Devel::Caller;

my %opt;
my $begin_pat;
my $end_pat;
my $cir_begin_pat;
my $ser_pat;
my $par_pat;
my $cir_par_pat;
my $com_pat;
my $token_pat;
my $nex_begin_pat;
my $line_shift;

our $cv1 = [];

sub import {
    my $self = shift;
    %opt = (
        verbose => 0,
        begin => qr/\{\{com\b/,
        cir_begin => qr/\{\{cir\b/,
        nex_begin => qr/\{\{nex\b/,
        ser => qr/--ser\b/,
        par => qr/--com\b/,
        cir_par => qr/--cir\b/,
        end => qr/\}\}(?:com|cir|nex)\b/,
        next => qr/\{\{next\}\}/,
        @_
    );
    $begin_pat = qr/$opt{begin}|$opt{cir_begin}|(?:$opt{nex_begin})/;
    $end_pat = $opt{end};
    $ser_pat = $opt{ser};
    $par_pat = $opt{par};
    $cir_begin_pat = $opt{cir_begin};
    $nex_begin_pat = $opt{nex_begin};
    $cir_par_pat = $opt{cir_par};
    $com_pat = qr/($begin_pat((?:(?-2)|(?!$begin_pat).)*?)$end_pat)/s;
    $token_pat = qr/$com_pat|(?!$begin_pat)./s;
    $line_shift = (caller)[2];
}

sub att_sub {
    my($att1, $att2, $cb) = @_;
    sub {
        unshift @_, $att1, $att2;
        &$cb;
    }
}

# $cv = [wait_count, cb, args]
sub cv_end { # (cv, args)
    --$_[0][0];
    push @{$_[0][2]//=[]}, @{$_[1]} if $_[1];
    if( !$_[0][0] ) {
        if( $_[0][1] ) {
            delete($_[0][1])->(@{$_[0][2]});
        }
        undef $_[0][2];
    }
}
sub cv_cb { # (cv, cb)
    if( $_[0][0] ) {
        $_[0][1] = $_[1];
    }
    else {
        $_[1](@{$_[0][2]});
        undef $_[0][2];
    }
}

sub ser {
    my $depth = shift;
    if( @_ <= 1 ) { # next only
        return $_[0];
    }
    my $code = shift;
    unshift @_, $depth;
    my $next = &ser;
    replace_code($depth, $code);
    $code =~ s/$opt{next}/(do{my\$t=\$Combinator::cv1;++\$t->[0];sub{if(\$t){Combinator::cv_end(\$t,\\\@_);undef\$t}else{my(undef,\$f,\$l)=caller;warn"next should be invoked only once at \$f line \$l.\\n"}}})/g;
    my $out = "local\$Combinator::guard=Guard::guard{Combinator::cv_end(\$Combinator::cv0,\\\@_)};local\$Combinator::cv1=[1];$code;--\$Combinator::cv1->[0];Combinator::cv_cb(\$Combinator::cv1,Combinator::att_sub(\$Combinator::head,\$Combinator::cv0,sub{local\$Combinator::head=shift;local\$Combinator::cv0=shift;$next}));\$Combinator::guard->cancel";
    return $out;
}

sub com { # depth, code, head
    my($depth, $code, $head) = @_;
    my @ser;
    $code .= "\n" if( substr($code, -1) eq "\n" );
    push @ser, $1 while( $code =~ m/(?:^|$ser_pat)($token_pat*?)(?=$ser_pat|$)/gs );

    my $delayed = $head =~ $nex_begin_pat;

    my $out = (
            $delayed ?
                "(do{++\$Combinator::cv1->[0];Combinator::att_sub(do{\\(my\$t=1)},\$Combinator::cv1,sub{if(!\${\$_[0]}){my(undef,\$f,\$l)=caller;warn\"nex should be invoked only once at \$f line \$l.\\n\";return}--\${\$_[0]};shift;local\$Combinator::cv0=shift;" :
                "{&{sub{local\$Combinator::cv0=\$Combinator::cv1;++\$Combinator::cv0->[0];"
        )."local\$Combinator::head=[1,Devel::Caller::caller_cv(0)];" .
        ser($depth+1, @ser, $head =~ /^(?:$cir_par_pat|$cir_begin_pat)$/ ? "--\$Combinator::cv0->[0];\$Combinator::cv1=\$Combinator::cv0;Combinator::cv_end(\$Combinator::head,\\\@_)" : "Combinator::cv_end(\$Combinator::cv0,\\\@_)") .
        (
            $delayed ?
                "})})" :
                "}}}"
        );
    return $out;
}

sub replace_code {
    my $depth = shift;
    $_[0] =~ s[$com_pat]{
        my $code = $1;
        my $out = '';
        while( $code =~ /($begin_pat|$par_pat|$cir_par_pat)($token_pat*?)(?=($par_pat|$cir_par_pat|$end_pat))/g ) {
            my $fragment = $2;
            $out .= com($depth, $fragment, $1);
        }
        $out;
    }ge;
}

FILTER {
    replace_code(0, $_);
    if( $opt{verbose} ) {
        my $verbose_code = $_;
        my $n = $line_shift;
        $verbose_code =~ s/^/sprintf"%6d: ", ++$n/gem;
        print "Code after filtering:\n$verbose_code\nEnd Of Code\n";
    }
};

1; # End of Combinator
