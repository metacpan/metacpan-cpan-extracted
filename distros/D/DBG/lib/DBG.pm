package DBG;
$DBG::VERSION = '0.004';
# ABSTRACT: A collection of debugging functions


use v5.10;
use strict;
use warnings;

use parent 'Exporter';
use FileHandle;
use Data::Dumper;
use Perl::Tidy;
use DateTime;
use File::Spec;
use Scalar::Util qw(refaddr reftype blessed);
use List::MoreUtils qw(natatime);
use B qw(svref_2object);
use B::Deparse;
use Devel::Size qw(total_size);
use Class::MOP;

our @EXPORT = qw(dmp png trc dbg ts rt cyc prp cnm pkg sz mtd inh dpr flt);

our $ON     = $ENV{DBG_ON}     // 1;
our $HEADER = $ENV{DBG_HEADER} // 1;

our ( $fh, $fn, $stamped );

BEGIN {
    $fn =
        defined $ENV{DBG_LOG}
      ? $ENV{DBG_LOG} eq '0'
          ? ''
          : $ENV{DBG_LOG} . ''
      : File::Spec->catfile( $ENV{HOME}, 'DBG.log' );
}

sub _tee($) {
    return unless $ON;
    my $data = shift;
    return unless defined $data;
    if ( $HEADER && !$stamped ) {
        my @msg = (
            '>> DEBUGGING SESSION START: ',
            DateTime->now, ' ; PID: ', $$, ' <<', "\n\n"
        );
        print $fh @msg if $fh;
        print STDERR @msg;
        $stamped = 1;
    }
    $data =~ s/\s++$//;
    $data .= "\n";
    print $fh $data if $fh;
    print STDERR $data;
}

BEGIN {
    if ( length $fn ) {
        $fh = FileHandle->new(">> $fn") or die $!;
        binmode $fh,     ':utf8';
        binmode *STDERR, ':utf8';
        $fh->autoflush(1);
    }
}

END {
    if ( $HEADER && $stamped ) {
        my $msg = join '', "\n", '** DEBUGGING SESSION END: ', DateTime->now,
          ' ; PID: ', $$, ' **';
        _tee($msg);
    }
    $fh->close if $fh;
}

{    # DateTime with optional label payload

    package DBG::ts;
$DBG::ts::VERSION = '0.004';
use parent 'DateTime';
    use Scalar::Util qw(refaddr);

    our %messages;

    sub text {
        my ( $self, $text ) = @_;
        my $addr = refaddr $self;
        my $old  = $messages{$addr};
        $messages{$addr} = $text if defined $text;
        return $old;
    }

    sub DESTROY {
        my $self = shift;
        delete $messages{ refaddr $self };
        $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
    }
}


sub ts(;$) {
    my $ts = DBG::ts->now;
    $ts->text(shift);
    return $ts;
}


sub rt($$) {
    return unless $ON;
    for (@_) {
        die 'DBG::ts expected'
          unless blessed($_) && $_->isa('DBG::ts');
    }
    my ( $t1, $t2 ) = @_;
    my $i = natatime 2, ( $t2 - $t1 )->deltas;
    my $reported;
    my $text   = $t1->text;
    my $prefix = '';
    if ( defined $text ) {
        _tee("timestamp $text");
        $prefix = "\t";
    }
    while ( my ( $unit, $amt ) = $i->() ) {
        next unless $amt;
        $reported = 1;
        $unit =~ s/s$// if $amt == 1;
        _tee("$prefix$amt $unit");
    }
    _tee("${prefix}negligible time elapsed") unless $reported;
    return $t2;
}


sub trc() {
    return unless $ON;
    _tee 'TRACE';
    my $i = 0;
    my @stack;
    while ( my @frame = caller($i) ) {
        push @stack, [ $i++, $frame[3], $frame[1], $frame[2] ];
    }
    my $fmt = '%' . length( $stack[-1][0] ) . 'd) %s (%s:%d)';
    for $i ( 1 .. $#stack ) {
        _tee sprintf $fmt, ( @{ $stack[$i] } )[ 0 .. 1 ],
          ( @{ $stack[ $i - 1 ] } )[ 2 .. 3 ];
    }
    _tee 'END TRACE';
}


sub dmp($) {
    return unless $ON;
    my $ref = shift;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Terse     = 1;
    my $code = Dumper $ref;
    _dmp($code);
}

sub _dmp {
    my $code = shift;
    my ( $ds, $stderr_string );
    local @ARGV;    # prevents Perl::Tidy craziness
    my $error = Perl::Tidy::perltidy(
        source      => \$code,
        destination => \$ds,
        stderr      => \$stderr_string
    );
    if ($error) {
        _tee "TIDY ERROR: $stderr_string";
        _tee $code;
    }
    else {
        _tee $ds;
    }
}


sub dbg($) {
    return unless $ON;
    my $data = shift;
    _tee $data;
}


sub png(;$) {
    return unless $ON;
    my $msg   = shift;
    my @frame = caller(1);
    my $data;
    if ( @frame && $msg ) {
        ( $data = $frame[3] ) =~ s/.*::(.*)/in code $1/;
    }
    else {
        $data = @frame ? sprintf( 'PING %4$s (%2$s:%3$d)', @frame ) : 'PING';
    }
    $data .= " -- $msg" if $msg && ( ref $msg || $msg ne '1' );
    _tee $data;
}


sub cyc($) {
    return unless $ON;
    _tee '===== OBJECT GRAPH =====';
    _cycles( shift, {}, 0, 'base' );
}

sub _cycles {
    my ( $ref, $hash, $indent, $parent ) = @_;
    my $type = reftype $ref;
    return unless $type;
## Please see file perltidy.ERR
    my $addr = refaddr $ref;
    my $name = blessed $ref // $type;
    my $left = ' ' x ( $indent * 3 );
    if ( $hash->{$addr}++ ) {
        _tee sprintf '%s%s (%s <- %s) -- ref count: %d', $left, $name, $addr,
          $parent,
          $hash->{$addr};
    }
    else {
        _tee sprintf '%s%s (%s <- %s)', $left, $name, $addr, $parent;
        if ( $type eq 'HASH' ) {
            _cycles( $_, $hash, $indent + 1, $addr ) for values %$ref;
        }
        elsif ( $type eq 'ARRAY' ) {
            _cycles( $_, $hash, $indent + 1, $addr ) for @$ref;
        }
    }
}


sub prp($$) {
    my ( $msg, $var ) = @_;
    $msg =~ s/\??\s*$/? /;
    _tee( $msg . ( $var ? 'yes' : 'no' ) );
}


sub cnm($;$) {
    my ( $code, $quiet ) = @_;
    return unless ref $code;
    my $gv   = _code_name($code);
    my $name = '';
    if ( my $st = $gv->STASH ) {
        $name = $st->NAME . '::';
    }
    my $n = $gv->NAME;
    if ($n) {
        $name .= $n;
        if ( $n eq '__ANON__' ) {
            $name .= ' defined at ' . $gv->FILE . ':' . $gv->LINE;
        }
    }
    _tee($name) unless $quiet;
    return $name;
}

sub _code_name {
    my $code = shift;
    return unless my $cv = svref_2object($code);
    return
      unless $cv->isa('B::CV')
      and my $gv = $cv->GV;
    return $gv;
}


sub pkg($$;$) {
    my ( $obj, $method, $file ) = @_;
    return _tee('first parameter must be an object') unless blessed $obj;
    return _tee('method not defined') unless defined $method;
    my $m = $obj->can($method);
    return _tee( "did not find method $method in " . ref $obj ) unless $m;
    my $gv = _code_name($m);
    return _tee("could not find $method") unless $gv;
    if ( !$file ) {
        _tee( sprintf 'package: %s; file: %s; line: %s',
            $gv->STASH->NAME, $gv->FILE, $gv->LINE );
    }
    else {
        _tee( $gv->STASH->NAME );
    }
}


sub sz($;$) {
    state $ts = eval { require Devel::Size };
    if ($ts) {
        my $msg = Devel::Size::total_size( pop @_ );
        $msg = pop(@_) . ' ' . $msg if @_;
        _tee($msg);
    }
    else {
        _tee('sz requires Devel::Size');
    }
}


sub mtd($;$) {
    my ( $obj, $verbose ) = @_;
    if ( my $class = ref $obj ) {
        my $meta = Class::MOP::Class->initialize($class);
        _tee("Class: $class");
        if ($verbose) {
            my $longest = 0;
            for ( $meta->get_all_methods ) {
                my $l = length $_->name;
                $longest = $l if $l > $longest;
            }
            my $format = '%-' . $longest . 's : %s  %s';
            for my $method ( sort { $a->name cmp $b->name }
                $meta->get_all_methods )
            {
                my $code = $obj->can( $method->name );
                my $gv   = _code_name($code);
                if ( $gv->LINE ) {
                    _tee( sprintf $format, $method->name, $gv->FILE,
                        $gv->LINE );
                }
                else {
                    _tee( $method->fully_qualified_name );
                }
            }
        }
        else {
            dmp(
                [
                    sort map { $_->fully_qualified_name }
                      $meta->get_all_methods
                ]
            );
        }
    }
    else {
        _tee "NOT AN OBJECT: $obj";
    }
}


sub inh($) {
    my $class = shift;
    _tee('inh needs a class') && return unless length( $class // '' );
    $class = ref($class) || $class;
    my $hash = { $class => 1 };
    _fetch_classes( $class, $hash );
    my @classes = sort keys %$hash;
    _tee("Classes in the inheritance hierarchy of $class:");
    _tee("  $_") for @classes;
}

sub _fetch_classes {
    my ( $class, $hash ) = @_;
    my @ar = eval '@' . $class . '::ISA';
    my @new = grep { !$hash->{$_} } @ar;
    $hash->{$_} = 1 for @ar;
    _fetch_classes( $_, $hash ) for @new;
}


sub dpr {
    my $ref = shift;
    die 'code reference expected' unless ref $ref eq 'CODE';
    my $d = B::Deparse->new(@_);
    _dmp( $d->coderef2text($ref) );
}


sub flt($;$) {
    my $v = _flt(shift);
    dmp($v) unless shift;
    return $v;
}

sub _flt {
    my $i = shift;
    return "$i" if blessed $i;
    for ( ref $i ) {
        when ('HASH') {
            my %h = %$i;
            $_ = _flt($_) for values %h;
            return \%h;
        }
        when ('ARRAY') {
            return [ map { _flt($_) } @$i ];
        }
    }
    return $i;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBG - A collection of debugging functions

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  package Foo::Bar::Baz;
  use DBG;

  ...
  dbg "log this $message";
  ...
  png;                  # do I ever get here?
  ...
  trc;                  # how did I get here?
  ...
  dmp $obj;             # what is this?
  ...
  cyc $obj;             # does this have reference cycles?
  ...
  my $ts = ts;          # get me the current time
  ...
  rt $ts, ts;           # how long did that take?
  ...
  prp "is it so", $val; # prints message plus "yes" or "no"
  ...
  pkg $obj, 'doit';     # prints package providing obj's doit method
  ...

=head1 DESCRIPTION

This is just a collection of functions useful for debugging. Instead of adding

  use Data::Dumper;
  use B::Deparse;
  use Devel::Size qw(total_size);

and so forth you can just type

  use DBG;

at the top of the script. If you're using git, or another version control system
with similar functionality, you can write a simple pre-commit hook to prevent
yourself from committing debugging lines to the repository. Once you've deleted
the C<use DBG;> line you can find all the other stuff you may have left in by
trying to compile the code and looking at the errors.

All functions have short names to make debugging quick(er).

All debugging messages are printed both to the screen and to a log. The log will
be C<~/DBG.log> unless otherwise specified. See C<$ENV{DBG_LOG}>. This facilitates
examining debugging output at one's leisure without having to visually cull away
any other output produced by the program.

All debugging functions are exported by default.

A timestamp will be printed before any debugging output to facilitate
distinguising one debugging session from another.

=head1 FUNCTIONS

=head2 ts(;$) -- "get timestamp"

Returns a L<DateTime>-based timestamp. The optional argument is a label for the
timestamp. The label will be accessible via the timestamp's C<text> method.

  my $t = ts 'foo';
  say $t->text;  # foo
  say $t;        # 2014-05-31T22:31:52

=head2 rt($$) -- "report timestamp"

Report time difference. This function expects two objects generated by the
C<ts> function, the earlier first. It returns the second timestamp to facilitate
the

   my $ts = ts;
   # some code
   $ts = rt $ts, ts

pattern.

The report will vary according to whether the first timestamp holds a label.

  my $t1 = ts 'foo';
  my $t2 = rt $t1, ts 'bar';
  sleep 1;
  my $t3 = rt $t2, ts;
  sleep 61;
  rt $t3, ts;

  # timestamp foo
  # 	negligible time elapsed
  # timestamp bar
  # 	1 second
  # 1 minute
  # 1 second

=head2 trc() -- "trace"

Prints a stack trace, skipping its own frame. Each line of the trace is
formatted as

  frame number) code name (file:line)

This involves munging the frames as returned by C<caller> so instead of saying
"you got here when called from here" it says simply "you are here". The next
line says how you got here. That is, the code name is the name of the code
you're in, not the code that just called you. I simply find this easier to
follow.

  sub foo   { bar() }
  sub bar   { baz() }
  sub baz   { plugh() }
  sub plugh { trc }
  foo();

  # TRACE
  # 1) main::plugh (test.pl:11)
  # 2) main::baz (test.pl:10)
  # 3) main::bar (test.pl:9)
  # 4) main::foo (test.pl:8)
  # END TRACE

=head2 dmp($) -- "dump"

Prints a pretty data dump. This uses a combination of L<Perl::Tidy> and
L<Data::Dumper>.

  my $r = { a => [qw(1 2 3)], c => { d => undef, egg => [ {}, {} ] } };
  dmp $r;

  # {
  #     a => [ '1', '2', '3' ],
  #     c => {
  #         d   => undef,
  #         egg => [ {}, {} ]
  #     }
  # }

=head2 dbg($) -- "debug"

Prints a message to the debugging log.

  dbg 'foo';  # foo

=head2 png(;$) -- "ping"

Prints a ping message to the debugging log. If optional argument is true, just
prints "in code <code name> -- <optional arg>", where C<code name> is the name
of the function or method minus the package. If the optional argument is just
"1", it is not suffixed to the ping message.

  sub foo { png }
  sub bar { png 1 }
  sub baz { png 'la la la la la' }
  foo();
  bar();
  baz();

  # PING main::foo (test.pl:11)
  # in code bar
  # in code baz -- la la la la la

=head2 cyc($) -- "cycles"

Checks for cycles in a reference, teeing out the entire object graph.
This is like a condensed dump concerning itself only with references.

  my $a = {};
  my $b = { b => $a };
  my $c = { c => $b };
  $a->{a} = $c;
  cyc $a;

  # HASH (140416464744656 <- base)
  #    HASH (140416464745304 <- 140416464744656)
  #       HASH (140416464744992 <- 140416464745304)
  #          HASH (140416464744656 <- 140416464744992) -- ref count: 2

=head2 prp($$) -- "property"

Takes a message and a scalar to be evaluated as a boolean and submits this to
C<dbg> as C<"$message? yes/no">.

  prp 'true', 1;
  prp 'true', 0;

  # true? yes
  # true? no

=head2 cnm($;$) -- "code name"

  cnm $ua->can('request');  # LWP::UserAgent::request

Converts a code reference to the place in the source code it comes from. This
uses B::svref_2object to do its magic. Sometimes it will provide the file and
line number, sometimes not.

If the optional second parameter is provided, the information is only returned,
not teed out.

=head2 pkg($$;$) -- "package"

Determines the package providing a method to an object. The first parameter is
the object and the second the method name. Unless the optional third parameter
is true, the file and line are also provided.

  my $d = DateTime->now;
  pkg $d, 'ymd';

  # package: DateTime; file: /Users/houghton/perl5/lib/perl5/darwin-thread-multi-2level/DateTime.pm; line: 820

  pkg $d, 'ymd', 1;

  # DateTime

=head2 sz($;$) -- "size"

Tees out the size of a scalar. If two arguments are given, the first is taken
as a label and the second the scalar.

  sz {};         # 128
  sz 'foo', {};  # foo 128

This delegates to the C<total_size> function in L<Devel::Size>. If you do not
have L<Devel::Size>, the C<sz> will only emit a warning that it requires
L<Devel::Size>.

=head2 mtd($;$) -- "method"

Dumps out a sorted list of the object's method names, fully qualified. If the
optional parameter is provided, it also lists where the code for each method
can be found.

  my $d = DateTime->now;
  mtd $d;

  # Class: DateTime
  # [
  #     'DateTime::DefaultLanguage',
  #     'DateTime::DefaultLocale',
  #     'DateTime::INFINITY',
  #     'DateTime::MAX_NANOSECONDS',
  #     ...                           # many lines omitted
  # ]

  mtd $d, 1;

  # Class: DateTime
  # UNIVERSAL::DOES
  # DefaultLanguage                 : /Users/houghton/perl5/lib/perl5/darwin-thread-multi-2level/DateTime.pm  106
  # DefaultLocale                   : /Users/houghton/perl5/lib/perl5/darwin-thread-multi-2level/DateTime.pm  106
  # INFINITY                        : /Users/houghton/perl5/lib/perl5/constant.pm  30
  # MAX_NANOSECONDS                 : /Users/houghton/perl5/lib/perl5/darwin-thread-multi-2level/Class/MOP/Mixin/HasMethods.pm  131
  # ...

=head2 inh($) -- "inheritance"

Takes an object or class and prints out a sorted list of all the classes in
that object or class's inheritance tree.

  package Plugh;
  package Foo;
  our @ISA = qw(Plugh);
  package Bar;
  package Baz;
  our @ISA = qw(Foo Bar);
  package main;

  inh 'Baz';

  # Classes in the inheritance hierarchy of Baz:
  #   Bar
  #   Baz
  #   Foo
  #   Plugh

=head2 dpr -- "deparse"

Takes a code reference and any optional parameters to pass to L<B::Deparse>.
Tees out the result of deparsing this reference.

  my $foo = sub { print "foo\n" };
  ...
  dpr $foo;    # what is this mystery code ref?

  # {
  #     use warnings;
  #     use strict 'refs';
  #     print "foo\n";
  # }

=head2 flt($;$) -- "flatten"

Takes a parameter and flattens it. For an ordinary scalar this just
means it returns it. For containers -- hash or array references -- it returns
copies with flattened values. Anything blessed it stringifies.

  flt { bar => 1, baz => DateTime->now };

  # {
  #     'bar' => 1,
  #     'baz' => '2014-05-31T21:04:07'
  # };

This is useful for dumping hashes containing huge objects whose innards you
don't need to see.

If the optional second parameter is provided, the information is only returned,
not also dumped out via C<dmp>.

=head1 VARIABLES

=head3 $ENV{DBG_LOG}

If the C<DBG_LOG> environment variable is set and is not equal to 0, this will
be understood as the file into which debugging output should be dumped. If it
is set to 0, the debugging output will only be sent to STDERR. If it is
undefined, the log will be C<~/DBG.log>.

=head3 $ENV{DBG_ON}

If the C<DBG_ON> environment variable is set, its boolean value will be used to
determine the value of C<$DBG::ON>.

=head3 $ENV{DBG_HEADER}

If the C<DBG_HEADER> environment variable is set, its boolean value will be used to
determine the value of C<$DBG::HEADER>.

=head3 $DBG::ON

If C<$DBG::ON> is true, which it is by default, all debugging code is executed.
If it is false, debugging code is ignored (aside from the initial timestamp).
The state of C<$ON> can be manipulated programmatically or set by the
C<$ENV{DBG_ON}> environment variable. This can be used to constrain debugging
output to a particular section of a program. For instance, one may set debugging
to off and then locally set it to one within a particular method.

  sub foo {
      local $DBG::ON = 1;
      my self = shift;
      ...
  }

=head3 $DBG::HEADER

Unless C<$DBG::HEADER> is false, a timestamp and process ID will be logged for
a debugging process. The header is not printed until the first debugging line
is logged, so this need not be set in a BEGIN block.

=head1 PRE-COMMIT HOOK

You probably don't want debugging code, at least not that associated with
DBG, getting into your repository. Here's a sample git pre-commit hook script
for screening it out:

  my $rx = qr/
    ( (?&line){0,3} (?&dbg) (?&line){0,3} )
    (?(DEFINE)
      (?<line> ^.*?(?:\R|\z) )
      (?<dbg>  ^\+\s*use\s+DBG\b.*?(?:\R|\z) )
    )
  /mx;
  my $text = `git diff --staged`;
  if ( my @matches = $text =~ /$rx/g ) {
      @matches = grep defined, @matches;
      exit 0 unless @matches;
      print STDERR "DBG lines: \n\n" . join "\n", @matches;
      print STDERR "\nRun with --no-verify if you want to skip the DBG check.\n";
      print STDERR "Aborting commit.\n";
      exit 1;
  }
  exit 0;

=head1 AUTHORS

=over 4

=item *

Grant Street Group <developers@grantstreet.com>

=item *

David F. Houghton <dfhoughton@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Grant Street Group.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
