package Class::Spiffy;
use strict;
use 5.006001;
use warnings;
use Carp;
require Exporter;
our $VERSION = '0.15';
our @EXPORT = ();
our @EXPORT_BASE = qw(field const stub super);
our @EXPORT_OK = (@EXPORT_BASE, qw(id WWW XXX YYY ZZZ));
our %EXPORT_TAGS = (XXX => [qw(WWW XXX YYY ZZZ)]);

my $stack_frame = 0; 
my $dump = 'yaml';
my $bases_map = {};

sub WWW; sub XXX; sub YYY; sub ZZZ;

# This line is here to convince "autouse" into believing we are autousable.
sub can {
    ($_[1] eq 'import' and caller()->isa('autouse'))
        ? \&Exporter::import        # pacify autouse's equality test
        : $_[0]->SUPER::can($_[1])  # normal case
}

# TODO
#
# Exported functions like field and super should be hidden so as not to
# be confused with methods that can be inherited.
#

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = bless {}, $class;
    while (@_) {
        my $method = shift;
        $self->$method(shift);
    }
    return $self;    
}

sub import {
    no strict 'refs'; 
    no warnings;
    my $self_package = shift;

    # XXX Using parse_arguments here might cause confusion, because the
    # subclass's boolean_arguments and paired_arguments can conflict, causing
    # difficult debugging. Consider using something truly local.
    my ($args, @export_list) = do {
        local *boolean_arguments = sub { 
            qw(
                -base -Base -mixin -selfless 
                -XXX -dumper -yaml 
            ) 
        };
        local *paired_arguments = sub { qw(-package) };
        $self_package->parse_arguments(@_);
    };
    return spiffy_mixin_import(scalar(caller(0)), $self_package, @export_list)
      if $args->{-mixin};

    croak <<'...' if $args->{-Base};
Use of '-Base' with Class::Spiffy is illegal.
Please use '-base' or 'use Spiffy -Base'
...

    $dump = 'yaml' if $args->{-yaml};
    $dump = 'dumper' if $args->{-dumper};

    local @EXPORT_BASE = @EXPORT_BASE;

    if ($args->{-XXX}) {
        push @EXPORT_BASE, @{$EXPORT_TAGS{XXX}}
          unless grep /^XXX$/, @EXPORT_BASE;
    }

    my $caller_package = $args->{-package} || caller($stack_frame);
    push @{"$caller_package\::ISA"}, $self_package
      if $args->{-base};

    for my $class (@{all_my_bases($self_package)}) {
        next unless $class->isa('Class::Spiffy');
        my @export = grep {
            not defined &{"$caller_package\::$_"};
        } ( @{"$class\::EXPORT"}, 
            $args->{-base} ? @{"$class\::EXPORT_BASE"} : (),
          );
        my @export_ok = grep {
            not defined &{"$caller_package\::$_"};
        } @{"$class\::EXPORT_OK"};

        # Avoid calling the expensive Exporter::export 
        # if there is nothing to do (optimization)
        my %exportable = map { ($_, 1) } @export, @export_ok;
        next unless keys %exportable;

        my @export_save = @{"$class\::EXPORT"};
        my @export_ok_save = @{"$class\::EXPORT_OK"};
        @{"$class\::EXPORT"} = @export;
        @{"$class\::EXPORT_OK"} = @export_ok;
        my @list = grep {
            (my $v = $_) =~ s/^[\!\:]//;
            $exportable{$v} or ${"$class\::EXPORT_TAGS"}{$v};
        } @export_list;
        Exporter::export($class, $caller_package, @list);
        @{"$class\::EXPORT"} = @export_save;
        @{"$class\::EXPORT_OK"} = @export_ok_save;
    }
}

sub base {
    push @_, -base;
    goto &import;
}

sub all_my_bases {
    my $class = shift;

    return $bases_map->{$class} 
      if defined $bases_map->{$class};

    my @bases = ($class);
    no strict 'refs';
    for my $base_class (@{"${class}::ISA"}) {
        push @bases, @{all_my_bases($base_class)};
    }
    my $used = {};
    $bases_map->{$class} = [grep {not $used->{$_}++} @bases];
}

my %code = (
    sub_start =>
      "sub {\n",
    set_default =>
      "  \$_[0]->{%s} = %s\n    unless exists \$_[0]->{%s};\n",
    init =>
      "  return \$_[0]->{%s} = do { my \$self = \$_[0]; %s }\n" .
      "    unless \$#_ > 0 or defined \$_[0]->{%s};\n",
    weak_init =>
      "  return do {\n" .
      "    \$_[0]->{%s} = do { my \$self = \$_[0]; %s };\n" .
      "    Scalar::Util::weaken(\$_[0]->{%s}) if ref \$_[0]->{%s};\n" .
      "    \$_[0]->{%s};\n" .
      "  } unless \$#_ > 0 or defined \$_[0]->{%s};\n",
    return_if_get =>
      "  return \$_[0]->{%s} unless \$#_ > 0;\n",
    set =>
      "  \$_[0]->{%s} = \$_[1];\n",
    weaken =>
      "  Scalar::Util::weaken(\$_[0]->{%s}) if ref \$_[0]->{%s};\n",
    sub_end =>
      "  return \$_[0]->{%s};\n}\n",
);

sub field {
    my $package = caller;
    my ($args, @values) = do {
        no warnings;
        local *boolean_arguments = sub { (qw(-weak)) };
        local *paired_arguments = sub { (qw(-package -init)) };
        Class::Spiffy->parse_arguments(@_);
    };
    my ($field, $default) = @values;
    $package = $args->{-package} if defined $args->{-package};
    die "Cannot have a default for a weakened field ($field)"
        if defined $default && $args->{-weak};
    return if defined &{"${package}::$field"};
    require Scalar::Util if $args->{-weak};
    my $default_string =
        ( ref($default) eq 'ARRAY' and not @$default )
        ? '[]'
        : (ref($default) eq 'HASH' and not keys %$default )
          ? '{}'
          : default_as_code($default);

    my $code = $code{sub_start};
    if ($args->{-init}) {
        my $fragment = $args->{-weak} ? $code{weak_init} : $code{init};
        $code .= sprintf $fragment, $field, $args->{-init}, ($field) x 4;
    }
    $code .= sprintf $code{set_default}, $field, $default_string, $field
      if defined $default;
    $code .= sprintf $code{return_if_get}, $field;
    $code .= sprintf $code{set}, $field;
    $code .= sprintf $code{weaken}, $field, $field 
      if $args->{-weak};
    $code .= sprintf $code{sub_end}, $field;

    my $sub = eval $code;
    die $@ if $@;
    no strict 'refs';
    *{"${package}::$field"} = $sub;
    return $code if defined wantarray;
}

sub default_as_code {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    my $code = Data::Dumper::Dumper(shift);
    $code =~ s/^\$VAR1 = //;
    $code =~ s/;$//;
    return $code;
}

sub const {
    my $package = caller;
    my ($args, @values) = do {
        no warnings;
        local *paired_arguments = sub { (qw(-package)) };
        Class::Spiffy->parse_arguments(@_);
    };
    my ($field, $default) = @values;
    $package = $args->{-package} if defined $args->{-package};
    no strict 'refs';
    return if defined &{"${package}::$field"};
    *{"${package}::$field"} = sub { $default }
}

sub stub {
    my $package = caller;
    my ($args, @values) = do {
        no warnings;
        local *paired_arguments = sub { (qw(-package)) };
        Class::Spiffy->parse_arguments(@_);
    };
    my ($field, $default) = @values;
    $package = $args->{-package} if defined $args->{-package};
    no strict 'refs';
    return if defined &{"${package}::$field"};
    *{"${package}::$field"} = 
    sub { 
        require Carp;
        Carp::confess 
          "Method $field in package $package must be subclassed";
    }
}

sub parse_arguments {
    my $class = shift;
    my ($args, @values) = ({}, ());
    my %booleans = map { ($_, 1) } $class->boolean_arguments;
    my %pairs = map { ($_, 1) } $class->paired_arguments;
    while (@_) {
        my $elem = shift;
        if (defined $elem and defined $booleans{$elem}) {
            $args->{$elem} = (@_ and $_[0] =~ /^[01]$/)
            ? shift
            : 1;
        }
        elsif (defined $elem and defined $pairs{$elem} and @_) {
            $args->{$elem} = shift;
        }
        else {
            push @values, $elem;
        }
    }
    return wantarray ? ($args, @values) : $args;        
}

sub boolean_arguments { () }
sub paired_arguments { () }

# get a unique id for any node
sub id {
    if (not ref $_[0]) {
        return 'undef' if not defined $_[0];
        \$_[0] =~ /\((\w+)\)$/o or die;
        return "$1-S";
    }
    require overload;
    overload::StrVal($_[0]) =~ /\((\w+)\)$/o or die;
    return $1;
}

#===============================================================================
# It's super, man.
#===============================================================================
package DB;
{
    no warnings 'redefine';
    sub super_args { 
        my @dummy = caller(@_ ? $_[0] : 2); 
        return @DB::args;
    }
}

package Class::Spiffy;
sub super {
    my $method;
    my $frame = 1;
    while ($method = (caller($frame++))[3]) {
        $method =~ s/.*::// and last;
    }
    my @args = DB::super_args($frame);
    @_ = @_ ? ($args[0], @_) : @args;
    my $class = ref $_[0] ? ref $_[0] : $_[0];
    my $caller_class = caller;
    my $seen = 0;
    my @super_classes = reverse grep {
        ($seen or $seen = ($_ eq $caller_class)) ? 0 : 1;
    } reverse @{all_my_bases($class)};
    for my $super_class (@super_classes) {
        no strict 'refs';
        next if $super_class eq $class;
        if (defined &{"${super_class}::$method"}) {
            ${"$super_class\::AUTOLOAD"} = ${"$class\::AUTOLOAD"}
              if $method eq 'AUTOLOAD';
            return &{"${super_class}::$method"};
        }
    }
    return;
}

#===============================================================================
# This code deserves a spanking, because it is being very naughty.
# It is exchanging base.pm's import() for its own, so that people
# can use base.pm with Class::Spiffy modules, without being the wiser.
#===============================================================================
my $real_base_import;
my $real_mixin_import;

BEGIN {
    require base unless defined $INC{'base.pm'};
    $INC{'mixin.pm'} ||= 'Class/Spiffy/mixin.pm';
    $real_base_import = \&base::import;
    $real_mixin_import = \&mixin::import;
    no warnings;
    *base::import = \&spiffy_base_import;
    *mixin::import = \&spiffy_mixin_import;
}

# my $i = 0;
# while (my $caller = caller($i++)) {
#     next unless $caller eq 'base' or $caller eq 'mixin';
#     croak <<END;
# Class::Spiffy must be loaded before calling 'use base' or 'use mixin' with a
# Class::Spiffy module. See the documentation of Class::Spiffy for details.
# END
# }

sub spiffy_base_import {
    my @base_classes = @_;
    shift @base_classes;
    no strict 'refs';
    goto &$real_base_import
      unless grep {
          eval "require $_" unless %{"$_\::"};
          $_->isa('Class::Spiffy');
      } @base_classes;
    my $inheritor = caller(0);
    for my $base_class (@base_classes) {
        next if $inheritor->isa($base_class);
        croak "Can't mix Class::Spiffy and non-Class::Spiffy classes in 'use base'.\n", 
              "See the documentation of Class::Spiffy for details\n  "
          unless $base_class->isa('Class::Spiffy');
        $stack_frame = 1; # tell import to use different caller
        import($base_class, '-base');
        $stack_frame = 0;
    }
}

sub mixin {
    my $self = shift;
    my $target_class = ref($self);
    spiffy_mixin_import($target_class, @_)
}

sub spiffy_mixin_import {
    my $target_class = shift;
    $target_class = caller(0)
      if $target_class eq 'mixin';
    my $mixin_class = shift
      or die "Nothing to mixin";
    eval "require $mixin_class";
    my @roles = @_;
    my $pseudo_class = join '-', $target_class, $mixin_class, @roles;
    my %methods = spiffy_mixin_methods($mixin_class, @roles);
    no strict 'refs';
    no warnings;
    @{"$pseudo_class\::ISA"} = @{"$target_class\::ISA"};
    @{"$target_class\::ISA"} = ($pseudo_class);
    for (keys %methods) {
        *{"$pseudo_class\::$_"} = $methods{$_};
    }
}

sub spiffy_mixin_methods {
    my $mixin_class = shift;
    no strict 'refs';
    my %methods = spiffy_all_methods($mixin_class);
    map {
        $methods{$_}
          ? ($_, \ &{"$methods{$_}\::$_"})
          : ($_, \ &{"$mixin_class\::$_"})
    } @_ 
      ? (get_roles($mixin_class, @_))
      : (keys %methods);
}

sub get_roles {
    my $mixin_class = shift;
    my @roles = @_;
    while (grep /^!*:/, @roles) {
        @roles = map {
            s/!!//g;
            /^!:(.*)/ ? do { 
                my $m = "_role_$1"; 
                map("!$_", $mixin_class->$m);
            } :
            /^:(.*)/ ? do {
                my $m = "_role_$1"; 
                ($mixin_class->$m);
            } :
            ($_)
        } @roles;
    }
    if (@roles and $roles[0] =~ /^!/) {
        my %methods = spiffy_all_methods($mixin_class);
        unshift @roles, keys(%methods);
    }
    my %roles;
    for (@roles) {
        s/!!//g;
        delete $roles{$1}, next
          if /^!(.*)/;
        $roles{$_} = 1;
    }
    keys %roles;
}

sub spiffy_all_methods {
    no strict 'refs';
    my $class = shift;
    return if $class eq 'Class::Spiffy';
    my %methods = map {
        ($_, $class)
    } grep {
        defined &{"$class\::$_"} and not /^_/
    } keys %{"$class\::"};
    my %super_methods;
    %super_methods = spiffy_all_methods(${"$class\::ISA"}[0])
      if @{"$class\::ISA"};
    %{{%super_methods, %methods}};
}


# END of naughty code.
#===============================================================================
# Debugging support
#===============================================================================
sub spiffy_dump {
    no warnings;
    if ($dump eq 'dumper') {
        require Data::Dumper;
        $Data::Dumper::Sortkeys = 1;
        $Data::Dumper::Indent = 1;
        return Data::Dumper::Dumper(@_);
    }
    require YAML;
    $YAML::UseVersion = 0;
    return YAML::Dump(@_) . "...\n";
}

sub at_line_number {
    my ($file_path, $line_number) = (caller(1))[1,2];
    "  at $file_path line $line_number\n";
}

sub WWW {
    warn spiffy_dump(@_) . at_line_number;
    return wantarray ? @_ : $_[0];
}

sub XXX {
    die spiffy_dump(@_) . at_line_number;
}

sub YYY {
    print spiffy_dump(@_) . at_line_number;
    return wantarray ? @_ : $_[0];
}

sub ZZZ {
    require Carp;
    Carp::confess spiffy_dump(@_);
}

1;

__END__

=head1 NAME

Class::Spiffy - Spiffy Framework with No Source Filtering

=head1 SYNOPSIS

    package Keen;
    use strict;
    use warnings;
    use Class::Spiffy -base;
    field 'mirth';
    const mood => ':-)';
    
    sub happy {
        my $self = shift;
        if ($self->mood eq ':-(') {
            $self->mirth(-1);
            print "Cheer up!";
        }
        super;
    }

    1;

=head1 DESCRIPTION

"Class::Spiffy" is a framework and methodology for doing object oriented
(OO) programming in Perl. Class::Spiffy combines the best parts of
Exporter.pm, base.pm, mixin.pm and SUPER.pm into one magic foundation
class. It attempts to fix all the nits and warts of traditional Perl OO,
in a clean, straightforward and (perhaps someday) standard way.

Class::Spiffy borrows ideas from other OO languages like Python, Ruby,
Java and Perl 6. It also adds a few tricks of its own.

If you take a look on CPAN, there are a ton of OO related modules. When
starting a new project, you need to pick the set of modules that makes
most sense, and then you need to use those modules in each of your
classes. Class::Spiffy, on the other hand, has everything you'll
probably need in one module, and you only need to use it once in one of
your classes. If you make Class::Spiffy the base class of the basest class
in your project, Class::Spiffy will automatically pass all of its magic to all
of your subclasses. You may eventually forget that you're even using it!

The most striking difference between Class::Spiffy and other Perl object
oriented base classes, is that it has the ability to export things. If
you create a subclass of Class::Spiffy, all the things that
Class::Spiffy exports will automatically be exported by your subclass,
in addition to any more things that you want to export. And if someone
creates a subclass of your subclass, all of those things will be
exported automatically, and so on. Think of it as "Inherited
Exportation", and it uses the familiar Exporter.pm specification syntax.

To use Class::Spiffy or any subclass of Class::Spiffy as a base class of
your class, you specify the C<-base> argument to the C<use> command.

    use MySpiffyBaseModule -base;

You can also use the traditional C<use base 'MySpiffyBaseModule';>
syntax and everything will work exactly the same. The only caveat is
that Class::Spiffy must already be loaded. That's because Class::Spiffy
rewires base.pm on the fly to do all the Spiffy magics.

Class::Spiffy has support for Ruby-like mixins with Perl6-like roles.
Just like C<base> you can use either of the following invocations:

    use mixin 'MySpiffyBaseModule';
    use MySpiffyBaseModule -mixin;

The second version will only work if the class being mixed in is a
subclass of Class::Spiffy. The first version will work in all cases, as
long as Class::Spiffy has already been loaded.

To limit the methods that get mixed in, use roles. (Hint: they work just like
an Exporter list):

    use MySpiffyBaseModule -mixin => qw(:basics x y !foo);

A useful feature of Class::Spiffy is that it exports two functions:
C<field> and C<const> that can be used to declare the attributes of your
class, and automatically generate accessor methods for them. The only
difference between the two functions is that C<const> attributes can not
be modified; thus the accessor is much faster.

One interesting aspect of OO programming is when a method calls the same
method from a parent class. This is generally known as calling a super
method. Perl's facility for doing this is butt ugly:

    sub cleanup {
        my $self = shift;
        $self->scrub;
        $self->SUPER::cleanup(@_);
    }

Class::Spiffy makes it, er, super easy to call super methods. You just
use the C<super> function. You don't need to pass it any arguments
because it automatically passes them on for you. Here's the same
function with Class::Spiffy:

    sub cleanup {
        my $self = shift;
        $self->scrub;
        super;
    }

Class::Spiffy has a special method for parsing arguments called
C<parse_arguments>, that it also uses for parsing its own arguments. You
declare which arguments are boolean (singletons) and which ones are
paired, with two special methods called C<boolean_arguments> and
C<paired_arguments>. Parse arguments pulls out the booleans and pairs
and returns them in an anonymous hash, followed by a list of the
unmatched arguments.

Finally, Class::Spiffy can export a few debugging functions C<WWW>,
C<XXX>, C<YYY> and C<ZZZ>. Each of them produces a YAML dump of its
arguments. WWW warns the output, XXX dies with the output, YYY prints
the output, and ZZZ confesses the output. If YAML doesn't suit your
needs, you can switch all the dumps to Data::Dumper format with the C<-
dumper> option.

That's Spiffy! Pretty Classy, eh?

=head1 A Spiffy NOTE

Class::Spiffy started off as the Spiffy.pm module. Class::Spiffy does
everything Spiffy does except clever source filtering. So you can be
sure that any module that uses Class::Spiffy, (like YAML.pm) doesn't use
source filtering. If you don't like source filtering, this may help you
sleep better at night.

=head1 Spiffy EXPORTING

Class::Spiffy implements a completely new idea in Perl. Modules that act
both as object oriented classes and that also export functions. But it
takes the concept of Exporter.pm one step further; it walks the entire
C<@ISA> path of a class and honors the export specifications of each
module. Since Class::Spiffy calls on the Exporter module to do this, you
can use all the fancy interface features that Exporter has, including
tags and negation.

Class::Spiffy considers all the arguments that don't begin with a dash to
comprise the export specification.

    package Vehicle;
    use Spiffy -base;
    our $SERIAL_NUMBER = 0;
    our @EXPORT = qw($SERIAL_NUMBER);
    our @EXPORT_BASE = qw(tire horn);

    package Bicycle;
    use Vehicle -base, '!field';

In this case, C<Bicycle->isa('Vehicle')> and also all the things
that C<Vehicle> and C<Class::Spiffy> export, will go into C<Bicycle>,
except C<field>.

Exporting can be very helpful when you've designed a system with
hundreds of classes, and you want them all to have access to some
functions or constants or variables. Just export them in your main base
class and every subclass will get the functions they need.

You can do almost everything that Exporter does because Class::Spiffy
delegates the job to Exporter (after adding some Spiffy magic).
Class::Spiffy offers a C<@EXPORT_BASE> variable which is like
C<@EXPORT>, but only for usages that use C<-base>.

=head1 Spiffy MIXINs & ROLEs

If you've done much OO programming in Perl you've probably used Multiple
Inheritance (MI), and if you've done much MI you've probably run into
weird problems and headaches. Some languages like Ruby, attempt to
resolve MI issues using a technique called mixins. Basically, all Ruby
classes use only Single Inheritance (SI), and then I<mixin>
functionality from other modules if they need to.

Mixins can be thought of at a simplistic level as I<importing> the
methods of another class into your subclass. But from an implementation
standpoint that's not the best way to do it. Class::Spiffy does what Ruby
does. It creates an empty anonymous class, imports everything into that
class, and then chains the new class into your SI ISA path. In other
words, if you say:

    package A;
    use B -base;
    use C -mixin;
    use D -mixin;

You end up with a single inheritance chain of classes like this:

    A << A-D << A-C << B;

C<A-D> and C<A-C> are the actual package names of the generated
classes. The nice thing about this style is that mixing in C doesn't
clobber any methods in A, and D doesn't conflict with A or C either. If
you mixed in a method in C that was also in A, you can still get to it
by using C<super>.

When Class::Spiffy mixes in C, it pulls in all the methods in C that do
not begin with an underscore. Actually it goes farther than that. If C
is a subclass it will pull in every method that C C<can> do through
inheritance. This is very powerful, maybe too powerful.

To limit what you mixin, Class::Spiffy borrows the concept of Roles from
Perl6. The term role is used more loosely in Class::Spiffy though. It's
much like an import list that the Exporter module uses, and you can use
groups (tags) and negation. If the first element of your list uses
negation, Class::Spiffy will start with all the methods that your mixin
class can do.

    use E -mixin => qw(:tools walk !run !:sharp_tools);

In this example, C<walk> and C<run> are methods that E can do, and
C<tools> and C<sharp_tools> are roles of class E. How does class E
define these roles? It very simply defines methods called C<_role_tools>
and C<_role_sharp_tools> which return lists of more methods. (And
possibly other roles!) The neat thing here is that since roles are just
methods, they too can be inherited. Take B<that> Perl6!

=head1 Spiffy DEBUGGING

The XXX function is very handy for debugging because you can insert it
almost anywhere, and it will dump your data in nice clean YAML. Take the
following statement:

    my @stuff = grep { /keen/ } $self->find($a, $b);

If you have a problem with this statement, you can debug it in any of the
following ways:

    XXX my @stuff = grep { /keen/ } $self->find($a, $b);
    my @stuff = XXX grep { /keen/ } $self->find($a, $b);
    my @stuff = grep { /keen/ } XXX $self->find($a, $b);
    my @stuff = grep { /keen/ } $self->find(XXX $a, $b);

XXX is easy to insert and remove. It is also a tradition to mark
uncertain areas of code with XXX. This will make the debugging dumpers
easy to spot if you forget to take them out.

WWW and YYY are nice because they dump their arguments and then return the
arguments. This way you can insert them into many places and still have the
code run as before. Use ZZZ when you need to die with both a YAML dump and a
full stack trace.

The debugging functions are exported by default if you use the C<-base>
option, but only if you have previously used the C<-XXX> option. To
export all 4 functions use the export tag:

    use SomeSpiffyModule ':XXX';

To force the debugging functions to use Data::Dumper instead of YAML:

    use SomeSpiffyModule -dumper;

=head1 Spiffy FUNCTIONS

This section describes the functions the Class::Spiffy exports. The
C<field>, C<const>, C<stub> and C<super> functions are only exported
when you use the C<-base> option.

=over 4

=item * field

Defines accessor methods for a field of your class:

    package Example;
    use Classs::Spiffy -base;
    
    field 'foo';
    field bar => [];

    sub lalala {
        my $self == shift;
        $self->foo(42);
        push @{$self->{bar}}, $self->foo;
    }

The first parameter passed to C<field> is the name of the attribute
being defined. Accessors can be given an optional default value.
This value will be returned if no value for the field has been set
in the object.

=item * const

    const bar => 42;

The C<const> function is similar to <field> except that it is immutable.
It also does not store data in the object. You probably always want to
give a C<const> a default value, otherwise the generated method will be
somewhat useless.

=item * stub

    stub 'cigar';

The C<stub> function generates a method that will die with an
appropriate message. The idea is that subclasses must implement these
methods so that the stub methods don't get called.

=item * super

If this function is called without any arguments, it will call the same
method that it is in, higher up in the ISA tree, passing it all the
same arguments. If it is called with arguments, it will use those
arguments with C<$self> in the front. In other words, it just works
like you'd expect.

    sub foo {
        my $self = shift;
        super;             # Same as $self->SUPER::foo(@_);
        super('hello');    # Same as $self->SUPER::foo('hello');
        $self->bar(42);
    }

    sub new {
        my $self = super;
        $self->init;
        return $self;
    }

C<super> will simply do nothing if there is no super method. Finally,
C<super> does the right thing in AUTOLOAD subroutines.

=back

=head1 Spiffy METHODS

This section lists all of the methods that any subclass of Class::Spiffy
automatically inherits.

=over 4

=item * mixin

A method to mixin a class at runtime. Takes the same arguments as C<use
mixin ...>. Makes the target class a mixin of the caller.

    $self->mixin('SomeClass');
    $object->mixin('SomeOtherClass' => 'some_method');

=item * parse_arguments

This method takes a list of arguments and groups them into pairs. It
allows for boolean arguments which may or may not have a value
(defaulting to 1). The method returns a hash reference of all the pairs
as keys and values in the hash. Any arguments that cannot be paired, are
returned as a list. Here is an example:

    sub boolean_arguments { qw(-has_spots -is_yummy) }
    sub paired_arguments { qw(-name -size) }
    my ($pairs, @others) = $self->parse_arguments(
        'red', 'white',
        -name => 'Ingy',
        -has_spots =>
        -size => 'large',
        'black',
        -is_yummy => 0,
    );

After this call, C<$pairs> will contain:

    {
        -name => 'Ingy',
        -has_spots => 1,
        -size => 'large',
        -is_yummy => 0,
    }

and C<@others> will contain 'red', 'white', and 'black'.

=item * boolean_arguments

Returns the list of arguments that are recognized as being boolean. Override
this method to define your own list.

=item * paired_arguments

Returns the list of arguments that are recognized as being paired. Override
this method to define your own list.

=back

=head1 Spiffy ARGUMENTS

When you C<use> the Class::Spiffy module or a subclass of it, you can
pass it a list of arguments. These arguments are parsed using the
C<parse_arguments> method described above. The special argument C<-
base>, is used to make the current package a subclass of the
Class::Spiffy module being used.

Any non-paired parameters act like a normal import list; just like those
used with the Exporter module.

=head1 USING Class::Spiffy WITH base.pm

The proper way to use a Class::Spiffy module as a base class is with the
C<-base> parameter to the C<use> statement. This differs from typical
modules where you would want to C<use base>.

    package Something;
    use Spiffy::Module -base;
    use base 'NonSpiffy::Module';

Now it may be hard to keep track of what's Spiffy and what is not.
Therefore Class::Spiffy has actually been made to work with base.pm. You can
say:

    package Something;
    use base 'Spiffy::Module';
    use base 'NonSpiffy::Module';

C<use base> is also very useful when your class is not an actual module (a
separate file) but just a package in some file that has already been loaded.
C<base> will work whether the class is a module or not, while the C<-base>
syntax cannot work that way, since C<use> always tries to load a module.

=head2 base.pm Caveats

To make Class::Spiffy work with base.pm, a dirty trick was played.
Class::Spiffy swaps C<base::import> with its own version. If the base
modules are not Spiffy, Class::Spiffy calls the original base::import.
If the base modules are Spiffy, then Class::Spiffy does its own thing.

There are two caveats.

=over 4

=item * Class::Spiffy must be loaded first.

If Class::Spiffy is not loaded and C<use base> is invoked on a
Class::Spiffy module, Class::Spiffy will die with a useful message
telling the author to read this documentation. That's because
Class::Spiffy needed to do the import swap beforehand.

If you get this error, simply put a statement like this up front in
your code:

    use Class::Spiffy ();

=item * No Mixing

C<base.pm> can take multiple arguments. And this works with
Class::Spiffy as long as all the base classes are Spiffy, or they are
all non-Spiffy. If they are mixed, Class::Spiffy will die. In this case
just use separate C<use
base> statements.

=back

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
