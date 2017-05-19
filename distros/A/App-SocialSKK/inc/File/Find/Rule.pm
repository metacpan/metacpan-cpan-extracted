#line 1
#       $Id: /mirror/lab/perl/File-Find-Rule/lib/File/Find/Rule.pm 2102 2006-06-01T15:39:03.942922Z richardc  $

package File::Find::Rule;
use strict;
use vars qw/$VERSION $AUTOLOAD/;
use File::Spec;
use Text::Glob 'glob_to_regex';
use Number::Compare;
use Carp qw/croak/;
use File::Find (); # we're only wrapping for now
use Cwd;           # 5.00503s File::Find goes screwy with max_depth == 0

$VERSION = '0.30';

# we'd just inherit from Exporter, but I want the colon
sub import {
    my $pkg = shift;
    my $to  = caller;
    for my $sym ( qw( find rule ) ) {
        no strict 'refs';
        *{"$to\::$sym"} = \&{$sym};
    }
    for (grep /^:/, @_) {
        my ($extension) = /^:(.*)/;
        eval "require File::Find::Rule::$extension";
        croak "couldn't bootstrap File::Find::Rule::$extension: $@" if $@;
    }
}

#line 56

# the procedural shim

*rule = \&find;
sub find {
    my $object = __PACKAGE__->new();
    my $not = 0;

    while (@_) {
        my $method = shift;
        my @args;

        if ($method =~ s/^\!//) {
            # jinkies, we're really negating this
            unshift @_, $method;
            $not = 1;
            next;
        }
        unless (defined prototype $method) {
            my $args = shift;
            @args = ref $args eq 'ARRAY' ? @$args : $args;
        }
        if ($not) {
            $not = 0;
            @args = $object->new->$method(@args);
            $method = "not";
        }

        my @return = $object->$method(@args);
        return @return if $method eq 'in';
    }
    $object;
}


#line 102

sub new {
    my $referent = shift;
    my $class = ref $referent || $referent;
    bless {
        rules    => [],  # [0]
        subs     => [],  # [1]
        iterator => [],
        extras   => {},
        maxdepth => undef,
        mindepth => undef,
    }, $class;
}

sub _force_object {
    my $object = shift;
    $object = $object->new()
      unless ref $object;
    $object;
}

#line 139

sub _flatten {
    my @flat;
    while (@_) {
        my $item = shift;
        ref $item eq 'ARRAY' ? push @_, @{ $item } : push @flat, $item;
    }
    return @flat;
}

sub name {
    my $self = _force_object shift;
    my @names = map { ref $_ eq "Regexp" ? $_ : glob_to_regex $_ } _flatten( @_ );

    push @{ $self->{rules} }, {
        rule => 'name',
        code => join( ' || ', map { "m($_)" } @names ),
        args => \@_,
    };

    $self;
}

#line 195

use vars qw( %X_tests );
%X_tests = (
    -r  =>  readable           =>  -R  =>  r_readable      =>
    -w  =>  writeable          =>  -W  =>  r_writeable     =>
    -w  =>  writable           =>  -W  =>  r_writable      =>
    -x  =>  executable         =>  -X  =>  r_executable    =>
    -o  =>  owned              =>  -O  =>  r_owned         =>

    -e  =>  exists             =>  -f  =>  file            =>
    -z  =>  empty              =>  -d  =>  directory       =>
    -s  =>  nonempty           =>  -l  =>  symlink         =>
                               =>  -p  =>  fifo            =>
    -u  =>  setuid             =>  -S  =>  socket          =>
    -g  =>  setgid             =>  -b  =>  block           =>
    -k  =>  sticky             =>  -c  =>  character       =>
                               =>  -t  =>  tty             =>
    -M  =>  modified                                       =>
    -A  =>  accessed           =>  -T  =>  ascii           =>
    -C  =>  changed            =>  -B  =>  binary          =>
   );

for my $test (keys %X_tests) {
    my $sub = eval 'sub () {
        my $self = _force_object shift;
        push @{ $self->{rules} }, {
            code => "' . $test . ' \$_",
            rule => "'.$X_tests{$test}.'",
        };
        $self;
    } ';
    no strict 'refs';
    *{ $X_tests{$test} } = $sub;
}


#line 248

use vars qw( @stat_tests );
@stat_tests = qw( dev ino mode nlink uid gid rdev
                  size atime mtime ctime blksize blocks );
{
    my $i = 0;
    for my $test (@stat_tests) {
        my $index = $i++; # to close over
        my $sub = sub {
            my $self = _force_object shift;

            my @tests = map { Number::Compare->parse_to_perl($_) } @_;

            push @{ $self->{rules} }, {
                rule => $test,
                args => \@_,
                code => 'do { my $val = (stat $_)['.$index.'] || 0;'.
                  join ('||', map { "(\$val $_)" } @tests ).' }',
            };
            $self;
        };
        no strict 'refs';
        *$test = $sub;
    }
}

#line 289

sub any {
    my $self = _force_object shift;
    my @rulesets = @_;

    push @{ $self->{rules} }, {
        rule => 'any',
        code => '(' . join( ' || ', map {
            "( " . $_->_compile( $self->{subs} ) . " )"
        } @_ ) . ")",
        args => \@_,
    };
    $self;
}

*or = \&any;

#line 318

sub not {
    my $self = _force_object shift;
    my @rulesets = @_;

    push @{ $self->{rules} }, {
        rule => 'not',
        args => \@rulesets,
        code => '(' . join ( ' && ', map {
            "!(". $_->_compile( $self->{subs} ) . ")"
        } @_ ) . ")",
    };
    $self;
}

*none = \&not;

#line 340

sub prune () {
    my $self = _force_object shift;

    push @{ $self->{rules} },
      {
       rule => 'prune',
       code => '$File::Find::prune = 1'
      };
    $self;
}

#line 357

sub discard () {
    my $self = _force_object shift;

    push @{ $self->{rules} }, {
        rule => 'discard',
        code => '$discarded = 1',
    };
    $self;
}

#line 380

sub exec {
    my $self = _force_object shift;
    my $code = shift;

    push @{ $self->{rules} }, {
        rule => 'exec',
        code => $code,
    };
    $self;
}

#line 411

sub grep {
    my $self = _force_object shift;
    my @pattern = map {
        ref $_
          ? ref $_ eq 'ARRAY'
            ? map { [ ( ref $_ ? $_ : qr/$_/ ) => 0 ] } @$_
            : [ $_ => 1 ]
          : [ qr/$_/ => 1 ]
      } @_;

    $self->exec( sub {
        local *FILE;
        open FILE, $_ or return;
        local ($_, $.);
        while (<FILE>) {
            for my $p (@pattern) {
                my ($rule, $ret) = @$p;
                return $ret
                  if ref $rule eq 'Regexp'
                    ? /$rule/
                      : $rule->(@_);
            }
        }
        return;
    } );
}

#line 465

for my $setter (qw( maxdepth mindepth extras )) {
    my $sub = sub {
        my $self = _force_object shift;
        $self->{$setter} = shift;
        $self;
    };
    no strict 'refs';
    *$setter = $sub;
}


#line 482

sub relative () {
    my $self = _force_object shift;
    $self->{relative} = 1;
    $self;
}

#line 499

sub DESTROY {}
sub AUTOLOAD {
    $AUTOLOAD =~ /::not_([^:]*)$/
      or croak "Can't locate method $AUTOLOAD";
    my $method = $1;

    my $sub = sub {
        my $self = _force_object shift;
        $self->not( $self->new->$method(@_) );
    };
    {
        no strict 'refs';
        *$AUTOLOAD = $sub;
    }
    &$sub;
}

#line 529

sub in {
    my $self = _force_object shift;

    my @found;
    my $fragment = $self->_compile( $self->{subs} );
    my @subs = @{ $self->{subs} };

    warn "relative mode handed multiple paths - that's a bit silly\n"
      if $self->{relative} && @_ > 1;

    my $topdir;
    my $code = 'sub {
        (my $path = $File::Find::name)  =~ s#^(?:\./+)+##;
        my @args = ($_, $File::Find::dir, $path);
        my $maxdepth = $self->{maxdepth};
        my $mindepth = $self->{mindepth};
        my $relative = $self->{relative};

        # figure out the relative path and depth
        my $relpath = $File::Find::name;
        $relpath =~ s{^\Q$topdir\E/?}{};
        my $depth = scalar File::Spec->splitdir($relpath);
        #print "name: \'$File::Find::name\' ";
        #print "relpath: \'$relpath\' depth: $depth relative: $relative\n";

        defined $maxdepth && $depth >= $maxdepth
           and $File::Find::prune = 1;

        defined $mindepth && $depth < $mindepth
           and return;

        #print "Testing \'$_\'\n";

        my $discarded;
        return unless ' . $fragment . ';
        return if $discarded;
        if ($relative) {
            push @found, $relpath if $relpath ne "";
        }
        else {
            push @found, $path;
        }
    }';

    #use Data::Dumper;
    #print Dumper \@subs;
    #warn "Compiled sub: '$code'\n";

    my $sub = eval "$code" or die "compile error '$code' $@";
    my $cwd = getcwd;
    for my $path (@_) {
        # $topdir is used for relative and maxdepth
        $topdir = $path;
        # slice off the trailing slash if there is one (the
        # maxdepth/mindepth code is fussy)
        $topdir =~ s{/?$}{}
          unless $topdir eq '/';
        $self->_call_find( { %{ $self->{extras} }, wanted => $sub }, $path );
    }
    chdir $cwd;

    return @found;
}

sub _call_find {
    my $self = shift;
    File::Find::find( @_ );
}

sub _compile {
    my $self = shift;
    my $subs = shift; # [1]

    return '1' unless @{ $self->{rules} };
    my $code = join " && ", map {
        if (ref $_->{code}) {
            push @$subs, $_->{code};
            "\$subs[$#{$subs}]->(\@args) # $_->{rule}\n";
        }
        else {
            "( $_->{code} ) # $_->{rule}\n";
        }
    } @{ $self->{rules} };

    return $code;
}

#line 629

sub start {
    my $self = _force_object shift;

    $self->{iterator} = [ $self->in( @_ ) ];
    $self;
}

#line 642

sub match {
    my $self = _force_object shift;

    return shift @{ $self->{iterator} };
}

1;

__END__

#line 752

Implementation notes:

[0] Currently we use an array of anonymous subs, and call those
repeatedly from match.  It'll probably be way more effecient to
instead eval-string compile a dedicated matching sub, and call that to
avoid the repeated sub dispatch.

[1] Though [0] isn't as true as it once was, I'm not sure that the
subs stack is exposed in quite the right way.  Maybe it'd be better as
a private global hash.  Something like $subs{$self} = []; and in
C<DESTROY>, delete $subs{$self}.

That'd make compiling subrules really much easier (no need to pass
@subs in for context), and things that work via a mix of callbacks and
code fragments are possible (you'd probably want this for the stat
tests).

Need to check this currently working version in before I play with
that though.

[*] There's probably a win to be made with the current model in making
stat calls use C<_>.  For

  find( file => size => "> 20M" => size => "< 400M" );

up to 3 stats will happen for each candidate.  Adding a priming _
would be a bit blind if the first operation was C< name => 'foo' >,
since that can be tested by a single regex.  Simply checking what the
next type of operation doesn't work since any arbritary exec sub may
or may not stat.  Potentially worse, they could stat something else
like so:

  # extract from the worlds stupidest make(1)
  find( exec => sub { my $f = $_; $f =~ s/\.c$/.o/ && !-e $f } );

Maybe the best way is to treat C<_> as invalid after calling an exec,
and doc that C<_> will only be meaningful after stat and -X tests if
they're wanted in exec blocks.
