package Class::Sniff;

use 5.006;
use warnings;
use strict;

use B::Concise;
use Carp ();
use Devel::Symdump;
use Digest::MD5;
use Graph::Easy;
use List::MoreUtils ();
use Sub::Identify   ();
use Text::SimpleTable;

use constant PSEUDO_PACKAGES => qr/::(?:SUPER|ISA::CACHE)$/;

=head1 NAME

Class::Sniff - Look for class composition code smells

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

 use Class::Sniff;
 my $sniff = Class::Sniff->new({class => 'Some::class'});

 my $num_methods = $sniff->methods;
 my $num_classes = $sniff->classes;
 my @methods     = $sniff->methods;
 my @classes     = $sniff->classes;

 my $graph    = $sniff->graph;   # Graph::Easy
 my $graphviz = $graph->as_graphviz();
 open my $DOT, '|dot -Tpng -o graph.png' or die("Cannot open pipe to dot: $!");
 print $DOT $graphviz;

 print $sniff->to_string;
 my @unreachable = $sniff->unreachable;
 foreach my $method (@unreachable) {
     print "$method\n";
 }

=head1 DESCRIPTION

B<ALPHA> code.  You've been warned.

The interface is rather ad-hoc at the moment and is likely to change.  After
creating a new instance, calling the C<report> method is your best option.
You can then visually examine it to look for potential problems:

 my $sniff = Class::Sniff->new({class => 'Some::Class'});
 print $sniff->report;

This module attempts to help programmers find 'code smells' in the
object-oriented code.  If it reports something, it does not mean that your
code is wrong.  It just means that you might want to look at your code a
little bit more closely to see if you have any problems.

At the present time, we assume Perl's default left-most, depth-first search
order.  We may alter this in the future (and there's a work-around with the
C<paths> method.  More on this later).

=head1 CLASS METHODS

=head2 C<new>

 my $sniff = Class::Sniff->new({
    class  => 'My::Class',
    ignore => qr/^DBIx::Class/,
 });

The constructor accepts a hashref with the following parameters:

=over 4

=item * C<class> (mandatory)

The name of the class to sniff.  If the class is not loaded into memory, the
constructor will still work, but nothing will get reported.  You must ensure
that your class is already loaded!

If you pass it an instance of a class instead, it will call 'ref' on the class
to determine what class to use.

=item * C<ignore> (optional)

This should be a regexp telling C<Class::Sniff> what to ignore in class names.
This is useful if you're inheriting from a large framework and don't want to
report on it.  Be careful with this, though.  If you have a complicated
inheritance hierarchy and you try to ignore something other than the root, you
will likely get bad information returned.

=item * C<universal> (optional)

If present and true, will attempt to include the C<UNIVERSAL> base class.  If
a class hierarchy is pruned with C<ignore>, C<UNIVERSAL> may not show up.

=item * C<clean> (optional)

If present, will automatically ignore "pseudo-packages" such as those ending
in C<::SUPER> and C<::ISA::CACHE>.  If you have legitimate packages with these
names, oops.

=item * C<method_length> (optional)

If present, will set the "maximum length" of a method (lines of code)
before it's reported as a code smell.
This feature is I<highly> experimental.
See C<long_methods> for details.

=back

=cut

sub new {
    my ( $class, $arg_for ) = @_;
    my $proto = $arg_for->{class}
      or Carp::croak("'class' argument not supplied to 'new'");
    my $target_class = ref $proto || $proto;
    if ( exists $arg_for->{ignore} && 'Regexp' ne ref $arg_for->{ignore} ) {
        Carp::croak("'ignore' requires a regex");
    }
    my $self = bless {
        classes       => {},
        clean         => $arg_for->{clean},
        duplicates    => {},
        exported      => {},
        graph         => undef,
        ignore        => $arg_for->{ignore},
        list_classes  => [$target_class],
        long_methods  => {},
        method_length => ( $arg_for->{method_length} || 50 ),
        methods       => {},
        paths         => [ [$target_class] ],
        target        => $target_class,
        universal     => $arg_for->{universal},
    } => $class;
    $self->_initialize;
    return $self;
}

=head2 C<new_from_namespace>

B<Warning>:  This can be a very slow method as it needs to exhaustively walk
and analyze the symbol table.

 my @sniffs = Class::Sniff->new_from_namespace({
     namespace => $some_root_namespace,
     universal => 1,
 });

 # Print reports for each class
 foreach my $sniff (@sniffs) {
     print $sniff->report;
 }

 # Print out the full inheritance heirarchy.
 my $sniff = pop @sniffs;
 my $graph = $sniff->combine_graphs(@sniffs);

 my $graphviz = $graph->as_graphviz();
 open my $DOT, '|dot -Tpng -o graph.png' or die("Cannot open pipe to dot: $!");
 print $DOT $graphviz;

Given a namespace, returns a list of C<Class::Sniff> objects namespaces which
start with the C<$namespace> string.  Requires a C<namespace> argument.

If you prefer, you can pass C<namespace> a regexp and it will simply return a
list of all namespaces matching that regexp:

 my @sniffs = Class::Sniff->new_from_namespace({
     namespace => qr/Result(?:Set|Source)/,
 });

You can also use this to slurp "everything":

 my @sniffs = Class::Sniff->new_from_namespace({
     namespace => qr/./,
     universal => 1,
 });

Note that because we still pull parents, it's possible that a parent class
will have a namespace not matching what you are expecting.

 use Class::Sniff;
 use HTML::TokeParser::Simple;
 my @sniffs = Class::Sniff->new_from_namespace({
     namespace => qr/(?i:tag)/,
 });
 my $graph    = $sniffs[0]->combine_graphs( @sniffs[ 1 .. $#sniffs ] );
 print $graph->as_ascii;
 __END__
 +-------------------------------------------+
 |      HTML::TokeParser::Simple::Token      |
 +-------------------------------------------+
   ^
   |
   |
 +-------------------------------------------+     +---------------------------------------------+
 |   HTML::TokeParser::Simple::Token::Tag    | <-- | HTML::TokeParser::Simple::Token::Tag::Start |
 +-------------------------------------------+     +---------------------------------------------+
   ^
   |
   |
 +-------------------------------------------+
 | HTML::TokeParser::Simple::Token::Tag::End |
 +-------------------------------------------+

All other arguments are passed to the C<Class::Sniff> constructor.

=cut

sub new_from_namespace {
    my ( $class, $arg_for ) = @_;
    my $namespace = delete $arg_for->{namespace}
      or Carp::croak("new_from_namespace requires a 'namespace' argument");
    my $ignore = delete $arg_for->{ignore};

    $namespace = ('Regexp' eq ref $namespace) 
        ? $namespace
        : qr/^$namespace/;

    if (defined $ignore) {
        $ignore = ('Regexp' eq ref $ignore) 
            ? $ignore
            : qr/^$ignore/;
    }

    my @sniffs;
    my %seen;
    my $find_classes = sub {
        my $symbol_name = shift;
        no warnings 'numeric';
        return if $seen{$symbol_name}++;    # prevent infinite loops
        if ( $symbol_name =~ $namespace ) {
            return if defined $ignore && $symbol_name =~ $ignore;
            $symbol_name =~ s/::$//;
            $arg_for->{class} = $symbol_name;
            if ( not $class->_is_real_package($symbol_name) ) {
                # we don't want to create a sniff, but we need to be able to
                # descend into the namespace.
                return 1;
            }
            push @sniffs => Class::Sniff->new($arg_for);
        }
        return 1;
    };
    B::walksymtable( \%::, 'NAME', $find_classes );
    return @sniffs;
}

=head2 C<graph_from_namespace>

    my $graph = Class::Sniff->graph_from_namespace({
        namespace => qr/^My::Namespace/,
    });
    print $graph->as_ascii;
    my $graphviz = $graph->as_graphviz();
    open my $DOT, '|dot -Tpng -o graph.png' or die("Cannot open pipe to dot: $!");
    print $DOT $graphviz;

Like C<new_from_namespace>, but returns a single C<Graph::Easy> object.

=cut

sub graph_from_namespace {
    my ( $class, $arg_for ) = @_;
    my @sniffs = $class->new_from_namespace($arg_for);
    my $sniff  = pop @sniffs;
    return @sniffs
      ? $sniff->combine_graphs(@sniffs)
      : $sniff->graph;
}

sub _initialize {
    my $self         = shift;
    my $target_class = $self->target_class;
    $self->width(72);
    $self->_register_class($target_class);
    $self->{classes}{$target_class}{count} = 1;
    $self->{graph} = Graph::Easy->new;
    $self->{graph}->set_attribute( 'graph', 'flow', 'up' );
    $self->_build_hierarchy($target_class);

    $self->_finalize;
}

sub _finalize {
    my $self    = shift;
    my @classes = $self->classes;
    my $index   = 0;
    my %classes = map { $_ => $index++ } @classes;

    # sort in inheritance order
    while ( my ( $method, $classes ) = each %{ $self->{methods} } ) {
        @$classes = sort { $classes{$a} <=> $classes{$b} } @$classes;
    }
}

sub _register_class {
    my ( $self, $class ) = @_;
    return if exists $self->{classes}{$class};

    # Do I really want to throw this away?
    my $symdump = Devel::Symdump->new($class);
    my @methods = map { s/^$class\:://; $_ } $symdump->functions;

    foreach my $method (@methods) {
        my $coderef = $class->can($method)
          or Carp::croak("Panic: $class->can($method) returned false!");
        my $package =  Sub::Identify::stash_name($coderef);
        if ( $package ne $class ) {
            $self->{exported}{$class}{$method} = $package;
        }
        else {

            # It's OK to throw away the exception.  The B:: modules can be
            # tricky and this is documented as experimental.
            local $@;
            eval {
                my $line   = B::svref_2object($coderef)->START->line;
                my $length = B::svref_2object($coderef)->GV->LINE - $line;
                if ( $length > $self->method_length ) {
                    $self->{long_methods}{"$class\::$method"} = $length;
                }
            };
        }

        my $walker = B::Concise::compile( '-terse', $coderef );    # 1
        B::Concise::walk_output( \my $buffer );
        $walker->();    # 1 renders -terse
        $buffer =~ s/^.*//;                          # strip method name
        $buffer =~ s/\(0x[^)]+\)/(0xHEXNUMBER)/g;    # normalize addresses
        my $digest = Digest::MD5::md5_hex($buffer);
        $self->{duplicates}{$digest} ||= [];
        push @{ $self->{duplicates}{$digest} } => [ $class, $method ];
    }

    for my $method (@methods) {
        $self->{methods}{$method} ||= [];
        push @{ $self->{methods}{$method} } => $class;
    }

    $self->{classes}{$class} = {
        parents  => [],
        children => [],
        methods  => \@methods,
        count    => 0,
    };
    return $self;
}

=head1 INSTANCE METHODS - CODE SMELLS

=head2 C<overridden>

 my $overridden = $sniff->overridden;

This method returns a hash of arrays.
Each key is the name of a method in the hierarchy
that has been overridden, and the arrays are lists of all classes the method
is defined in (not just which one's it's overridden in).  The order of the
classes is in Perl's default inheritance search order.

=head3 Code Smell:  overridden methods

Overridden methods are not necessarily a code smell, but you should check them
to find out if you've overridden something you didn't expect to override.
Accidental overriding of a method can be very hard to debug.

This can also be a sign of bad responsibilities.  If you have a long
inheritance chain and you override a method in five different levels with five
different behaviors, perhaps this behavior should be in its own class.

=cut

sub overridden {
    my $self = shift;
    my %methods;
    while ( my ( $method, $classes ) = each %{ $self->{methods} } ) {
        $methods{$method} = $classes if @$classes > 1;
    }
    return \%methods;
}

=head2 C<exported>

    my $exported = $sniff->exported;

Returns a hashref of all classes which have subroutines exported into them.
The structure is:

 {
     $class1 => {
         $sub1 => $exported_from1,
         $sub2 => $exported_from2,
     },
     $class2 => { ... }
 }

Returns an empty hashref if no exported subs are found.

=head3 Code Smell:  exported subroutines

Generally speaking, you should not be exporting subroutines into OO code.
Quite often this happens when using modules like C<Carp::croak>,
which exports subroutines into the use'ing module.
These functions may not behave like you
expect them to since they're generally not intended to be called as methods.

=cut

sub exported { $_[0]->{exported} }

=head2 C<unreachable>

 my @unreachable = $sniff->unreachable;
 for my $method (@unreachable) {
     print "Cannot reach '$method'\n";
 }

Returns a list of fully qualified method names (e.g.,
'My::Customer::_short_change') that are unreachable by Perl's normal search
inheritance search order.  It does this by searching the "paths" returned by
the C<paths> method.

=head3 Code Smell:  unreachable methods

Pretty straight-forward here.  If a method is unreachable, it's likely to be
dead code.  However, you might have a reason for this and maybe you're calling
it directly.

=cut

sub unreachable {
    my $self       = shift;
    my $overridden = $self->overridden;
    my @paths      = $self->paths;

    # If we only have one path through our code, we don't have any unreachable
    # methods.
    return if @paths == 1;

    # Algorithm:  If we have overridden methods, then if we have multiple
    # paths through the code, a method is unreachable if a *previous* path
    # contains the method because Perl's default search order won't get to
    # successive paths.
    my @unreachable;
    while ( my ( $method, $classes ) = each %$overridden ) {
        my @classes;

      CLASS:
        for my $class (@$classes) {
            my $method_found = 0;
            for my $path (@paths) {

                # method was found in a *previous* path.
                if ($method_found) {
                    push @unreachable => "$class\::$method";
                    next CLASS;
                }
                for my $curr_class (@$path) {
                    next CLASS if $curr_class eq $class;
                    if ( not $method_found && $curr_class->can($method) ) {
                        $method_found = 1;
                    }
                }
            }
        }
    }
    return @unreachable;
}

=head2 C<paths>

 my @paths = $sniff->paths;

 for my $i (0 .. $#paths) {
     my $path = join ' -> ' => @{ $paths[$i] };
     printf "Path #%d is ($path)\n" => $i + 1;
 }

Returns a list of array references.  Each array reference is a list of
classnames representing the path Perl will take to search for a method.  For
example, if we have an abstract C<Animal> class and we use diamond inheritance
to create an C<Animal::Platypus> class, we might have the following hierarchy:

               Animal
              /      \
    Animal::Duck   Animal::SpareParts
              \      /
          Animal::Platypus

With Perl's normal left-most, depth-first search order, C<paths> will return:

 (
     ['Animal::Platypus', 'Animal::Duck',       'Animal'],
     ['Animal::Platypus', 'Animal::SpareParts', 'Animal'],
 )

If you are using a different MRO (Method Resolution Order) and you know your
search order is different, you can pass in a list of "correct" paths,
structured as above:

 # Look ma, one hand (er, path)!
 $sniff->paths( 
     ['Animal::Platypus', 'Animal::Duck', 'Animal::SpareParts', 'Animal'],
 );

At the present time, we do I<no> validation of what's passed in.
It's just an experimental (and untested) hack.

=head3 Code Smell:  paths

Multiple inheritance paths are tricky to get right, make it easy to have
'unreachable' methods and have a greater cognitive load on the programmer.
For example, if C<Animal::Duck> and C<Animal::SpareParts> both define the same
method, C<Animal::SpareParts>' method is likely unreachable.  But what if
makes a required state change?  You now have broken code.

See L<http://use.perl.org/~Ovid/journal/38373> for a more in-depth
explanation.

=cut

sub paths {
    my $self = shift;
    return @{ $self->{paths} } unless @_;
    $self->{paths} = [@_];
    return $self;
}

=head2 C<multiple_inheritance>

 my $num_classes = $sniff->multiple_inheritance;
 my @classes     = $sniff->multiple_inheritance;

Returns a list of all classes that inherit from more than one class.

=head3 Code Smell:  multiple inheritance

See the C<Code Smell> section for C<paths>

=cut

sub multiple_inheritance {
    my $self = shift;
    return grep { $self->parents($_) > 1 } $self->classes;
}

=head2 C<duplicate_methods>

B<Note>:  This method is very experimental and requires the L<B::Concise>
module.

 my $num_duplicates = $self->duplicate_methods;
 my @duplicates     = $self->duplicate_methods;

Returns either the number of duplicate methods found, or a list of array refs.
Each arrayref contains a list of array references, each having a class name
and method name.

B<Note>:  We report duplicates based on identical op-trees.  If the method
names are different or the variable names are different, that's OK.  Any
change to the op-tree, however, will break this.  The following two methods
are identical, even if they are in different packages.:

 sub inc {
    my ( $self, $value ) = @_;
    return $value + 1;
 }

 sub increment {
    my ( $proto, $number ) = @_;
    return $number + 1;
 }

However, this will not match the above methods:

 sub increment {
    my ( $proto, $number ) = @_;
    return 1 + $number;
 }

=head3 Code Smell:  duplicate methods

This is frequently a sign of "cut and paste" code.  The duplication should be
removed.  You may feel OK with this if the duplicated methods are exported
"helper" subroutines such as "Carp::croak".

=cut
sub duplicate_methods {
    my $self = shift;
    my @duplicates;
    foreach my $methods ( values %{ $self->{duplicates} } ) {
        if ( @$methods > 1 ) {
            push @duplicates => $methods;
        }
    }
    return @duplicates;
}

=head2 C<long_methods> (highly experimental)

 my $num_long_methods = $sniff->long_methods;
 my %long_methods     = $sniff->long_methods;

Returns methods longer than C<method_length>.
This value defaults to 50 (lines) and
can be overridden in the constructor (but not later).

=over 4

=item * How to count the length of a method.

 my $start_line = B::svref_2object($coderef)->START->line;
 my $end_line   = B::svref_2object($coderef)->GV->LINE;
 my $method_length = $end_line - $start_line;

The C<$start_line> returns the line number of the I<first expression> in the
subroutine, not the C<sub foo { ...> declaration.  The subroutine's
declaration actually ends at the ending curly brace, so the following method
would be considered 3 lines long, even though you might count it differently:

 sub new {
     # this is our constructor
     my ( $class, $arg_for ) = @_;
     my $self = bless {} => $class;
     return $self;
 }

=cut

sub long_methods { %{ $_[0]->{long_methods} } }

=item * Exported methods

These are simply ignored because the C<B> modules think they start and end in
different packages.

=item * Where does it really start?

If you've taken a reference to a method I<prior> to the declaration of the
reference being seen, Perl might report a negative length or simply blow up.
We trap that for you and you'll never see those.

=back

Let me know how it works out :)

=head3 Code Smell:  long methods

Note that long methods may not be a code smell at all.  The research in the
topic suggests that methods longer than many experienced programmers are
comfortable with are, nonetheless, easy to write, understand, and maintain.
Take this with a grain of salt.  See the book "Code Complete 2" by Microsoft
Press for more information on the research.  That being said ...

Long methods might be doing too much and should be broken down into smaller
methods.  They're harder to follow, harder to debug, and if they're doing more
than one thing, you might find that you need that functionality elsewhere, but
now it's tightly coupled to the long method's behavior.  As always, use your
judgment.

=head2 C<parents>

 # defaults to 'target_class'
 my $num_parents = $sniff->parents;
 my @parents     = $sniff->parents;

 my $num_parents = $sniff->parents('Some::Class');
 my @parents     = $sniff->parents('Some::Class');

In scalar context, lists the number of parents a class has.

In list context, lists the parents a class has.

=head3 Code Smell:  multiple parens (multiple inheritance)

If a class has more than one parent, you may have unreachable or conflicting
methods.

=cut

sub parents {
    my ( $self, $class ) = @_;
    $class ||= $self->target_class;
    unless ( exists $self->{classes}{$class} ) {
        Carp::croak("No such class '$class' found in hierarchy");
    }
    return @{ $self->{classes}{$class}{parents} };
}

=head1 INSTANCE METHODS - REPORTING

=head2 C<report>

 print $sniff->report;

Returns a detailed, human readable report of C<Class::Sniff>'s analysis of
the class.  Returns an empty string if no issues found.  Sample:

 Report for class: Grandchild
 
 Overridden Methods
 .--------+--------------------------------------------------------------------.
 | Method | Class                                                              |
 +--------+--------------------------------------------------------------------+
 | bar    | Grandchild                                                         |
 |        | Abstract                                                           |
 |        | Child2                                                             |
 | foo    | Grandchild                                                         |
 |        | Child1                                                             |
 |        | Abstract                                                           |
 |        | Child2                                                             |
 '--------+--------------------------------------------------------------------'
 Unreachable Methods
 .--------+--------------------------------------------------------------------.
 | Method | Class                                                              |
 +--------+--------------------------------------------------------------------+
 | bar    | Child2                                                             |
 | foo    | Child2                                                             |
 '--------+--------------------------------------------------------------------'
 Multiple Inheritance
 .------------+----------------------------------------------------------------.
 | Class      | Parents                                                        |
 +------------+----------------------------------------------------------------+
 | Grandchild | Child1                                                         |
 |            | Child2                                                         |
 '------------+----------------------------------------------------------------'

=cut

sub report {
    my $self = shift;

    my $report = $self->_get_overridden_report;
    $report .= $self->_get_unreachable_report;
    $report .= $self->_get_multiple_inheritance_report;
    $report .= $self->_get_exported_report;
    $report .= $self->_get_duplicate_method_report;
    $report .= $self->_get_long_method_report;

    if ($report) {
        my $target = $self->target_class;
        $report = "Report for class: $target\n\n$report";
    }
    return $report;
}

# The fruity sorts below were me trying to work out why one test was failing;
# it was down to the random order of methods being listed in this report.
# I suspect it started failing with the hash randomization change in Perl.
# Now I know how / where to make things deterministic, I'll come back sometime
# and make this more elegant -- NEILB 2014-06-03
sub _get_duplicate_method_report {
    my $self = shift;

    my $report    = '';
    my @duplicate = $self->duplicate_methods;
    for (my $i = 0; $i < @duplicate; $i++) {
        $duplicate[$i] = [sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @{ $duplicate[$i] }];
    }
    my ( @methods, @duplicates );
    if (@duplicate) {
        foreach my $duplicate (sort { $a->[0]->[0] cmp $b->[0]->[0] || $a->[0]->[1] cmp $b->[0]->[1]} @duplicate) {
            push @methods => join '::' => @{ pop @$duplicate };
            push @duplicates => join "\n" => map { join '::' => @$_ }
              @$duplicate;
        }
        $report .= "Duplicate Methods (Experimental)\n"
          . $self->_build_report( 'Method', 'Duplicated In',
            \@methods, \@duplicates );
    }
    return $report;
}

sub _get_overridden_report {
    my $self = shift;

    my $report     = '';
    my $overridden = $self->overridden;
    if (%$overridden) {
        my @methods = sort keys %$overridden;
        my @classes;
        foreach my $method (@methods) {
            push @classes => join "\n" => @{ $overridden->{$method} };
        }
        $report .= "Overridden Methods\n"
          . $self->_build_report( 'Method', 'Class', \@methods, \@classes );
    }
    return $report;
}

sub _get_unreachable_report {
    my $self = shift;

    my $report = '';
    if ( my @unreachable = $self->unreachable ) {
        my ( @methods, @classes );
        for my $fq_method (@unreachable) {
            $fq_method =~ /^(.*)::(.*)$/;    # time to rethink the API
            push @methods => $2;
            push @classes => $1;
        }
        $report .= "Unreachable Methods\n"
          . $self->_build_report( 'Method', 'Class', \@methods, \@classes );
    }
    return $report;
}

sub _get_multiple_inheritance_report {
    my $self = shift;
    my $report .= '';
    if ( my @multis = $self->multiple_inheritance ) {
        my @classes = map { join "\n" => $self->parents($_) } @multis;
        $report .= "Multiple Inheritance\n"
          . $self->_build_report( 'Class', 'Parents', \@multis, \@classes );
    }
    return $report;
}

sub _get_exported_report {
    my $self     = shift;
    my $exported = $self->exported;
    my $report   = '';
    if ( my @classes = sort keys %$exported ) {
        my ( $longest_c, $longest_m ) = ( length('Class'), length('Method') );
        my ( @subs, @sources );
        foreach my $class (@classes) {
            my ( @temp_subs, @temp_sources );
            foreach my $sub ( sort keys %{ $exported->{$class} } ) {
                push @temp_subs    => $sub;
                push @temp_sources => $exported->{$class}{$sub};
                $longest_c = length($class) if length($class) > $longest_c;
                $longest_m = length($sub)   if length($sub) > $longest_m;
            }
            push @subs    => join "\n" => @temp_subs;
            push @sources => join "\n" => @temp_sources;
        }
        my $width = $self->width - 3;
        my $third = int( $width / 3 );
        $longest_c = $third if $longest_c > $third;
        $longest_m = $third if $longest_m > $third;
        my $rest = $width - ( $longest_c + $longest_m );
        my $text = Text::SimpleTable->new(
            [ $longest_c, 'Class' ],
            [ $longest_m, 'Method' ],
            [ $rest,      'Exported From Package' ]
        );
        for my $i ( 0 .. $#classes ) {
            $text->row( $classes[$i], $subs[$i], $sources[$i] );
        }
        $report .= "Exported Subroutines\n" . $text->draw;
    }
    return $report;
}

sub _get_long_method_report {
    my $self = shift;
    my $report .= '';
    my %long_methods = $self->long_methods;
    if ( my @methods = sort keys %long_methods ) {
        my @lengths;
        foreach my $method (@methods) {
            push @lengths => $long_methods{$method};
        }
        $report .= "Long Methods (experimental)\n"
          . $self->_build_report( 'Method', 'Approximate Length',
            \@methods, \@lengths );
    }
    return $report;
}

sub _build_report {
    my ( $self, $title1, $title2, $strings1, $strings2 ) = @_;
    unless ( @$strings1 == @$strings2 ) {
        Carp::croak("PANIC:  Attempt to build unbalanced report");
    }
    my ( $width1, $width2 ) = $self->_get_widths( $title1, @$strings1 );
    my $text =
      Text::SimpleTable->new( [ $width1, $title1 ], [ $width2, $title2 ] );
    for my $i ( 0 .. $#$strings1 ) {
        $text->row( $strings1->[$i], $strings2->[$i] );
    }
    return $text->draw;
}

sub _get_widths {
    my ( $self, $title, @strings ) = @_;

    my $width   = $self->width;
    my $longest = length($title);
    foreach my $string (@strings) {
        my $length = length $string;
        $longest = $length if $length > $longest;
    }
    $longest = int( $width / 2 ) if $longest > ( $width / 2 );
    return ( $longest, $width - $longest );
}

=head2 C<width>

 $sniff->width(80);

Set the width of the report.  Defaults to 72.

=cut

sub width {
    my $self = shift;
    return $self->{width} unless @_;
    my $number = shift;
    unless ( $number =~ /^\d+$/ && $number >= 40 ) {
        Carp::croak(
            "Argument to 'width' must be a number >= than 40, not ($number)");
    }
    $self->{width} = $number;
}

=head2 C<to_string>

 print $sniff->to_string;

For debugging, lets you print a string representation of your class hierarchy.
Internally this is created by L<Graph::Easy> and I can't figure out how to
force it to respect the order in which classes are ordered.  Thus, the
'left/right' ordering may be incorrect.

=cut

sub to_string { $_[0]->graph->as_ascii }

=head2 C<graph>

 my $graph = $sniff->graph;

Returns a C<Graph::Easy> representation of the inheritance hierarchy.  This is
exceptionally useful if you have C<GraphViz> installed.

 my $graph    = $sniff->graph;   # Graph::Easy
 my $graphviz = $graph->as_graphviz();
 open my $DOT, '|dot -Tpng -o graph.png' or die("Cannot open pipe to dot: $!");
 print $DOT $graphviz;

Visual representations of complex hierarchies are worth their weight in gold.
See L<http://pics.livejournal.com/publius_ovidius/pic/00015p9z>.

Because I cannot figure out how to force it to respect the 'left/right'
ordering of classes,
you may need to manually edit the C<$graphviz> data to get this right.

=cut

sub graph { $_[0]->{graph} }

=head2 C<combine_graphs>

 my $graph = $sniff->combine_graphs($sniff2, $sniff3);
 print $graph->as_ascii;

Allows you to create a large inheritance hierarchy graph by combining several
C<Class::Sniff> instances together.

Returns a L<Graph::Easy> object.

=cut

sub combine_graphs {
    my ( $self, @sniffs ) = @_;

    my $graph = $self->graph->copy;

    foreach my $sniff (@sniffs) {
        unless ( $sniff->isa( ref $self ) ) {
            my $bad_class = ref $sniff;
            my $class     = ref $self;
            die
"Arguments to 'combine_graphs' must '$class' objects, not '$bad_class' objects";
        }
        my $next_graph = $sniff->graph;
        foreach my $edge ( $next_graph->edges ) {
            $graph->add_edge_once( $edge->from->name, $edge->to->name );
        }
    }
    return $graph;
}

=head2 C<target_class>

 my $class = $sniff->target_class;

This is the class you originally asked to sniff.

=cut

sub target_class { $_[0]->{target} }

=head2 C<method_length>

 my $method_length = $sniff->method_length;

This is the maximum allowed length of a method before being reported as a code
smell.  See C<method_length> in the constructor.

=cut

sub method_length { $_[0]->{method_length} }

=head2 C<ignore>

 my $ignore = $sniff->ignore;

This is the regexp provided (if any) to the constructor's C<ignore> parameter.

=cut

sub ignore { $_[0]->{ignore} }

=head2 C<universal>

 my $universal = $sniff->universal;

This is the value provided (if any) to the 'universal' parameter in the
constructor.  If it's a true value, 'UNIVERSAL' will be added to the
hierarchy.  If the hierarchy is pruned via 'ignore' and we don't get down that
far in the hierarchy, the 'UNIVERSAL' class will not be added.

=cut

sub universal { $_[0]->{universal} }

=head2 C<clean>

Returns true if user requested 'clean' classes.  This attempts to remove
spurious packages from the inheritance tree.

=cut

sub clean     { $_[0]->{clean} }

=head2 C<classes>

 my $num_classes = $sniff->classes;
 my @classes     = $sniff->classes;

In scalar context, lists the number of classes in the hierarchy.

In list context, lists the classes in the hierarchy, in default search order.

=cut

sub classes { @{ $_[0]->{list_classes} } }

=head2 C<children>

 # defaults to 'target_class'
 my $num_children = $sniff->children;
 my @children     = $sniff->children;

 my $num_children = $sniff->children('Some::Class');
 my @children     = $sniff->children('Some::Class');

In scalar context, lists the number of children a class has.

In list context, lists the children a class has.

=cut

sub children {
    my ( $self, $class ) = @_;
    $class ||= $self->target_class;
    unless ( exists $self->{classes}{$class} ) {
        Carp::croak("No such class '$class' found in hierarchy");
    }
    return @{ $self->{classes}{$class}{children} };
}

=head2 C<methods>

 # defaults to 'target_class'
 my $num_methods = $sniff->methods;
 my @methods     = $sniff->methods;

 my $num_methods = $sniff->methods('Some::Class');
 my @methods     = $sniff->methods('Some::Class');

In scalar context, lists the number of methods a class has.

In list context, lists the methods a class has.

=cut

sub methods {
    my ( $self, $class ) = @_;
    $class ||= $self->target_class;
    unless ( exists $self->{classes}{$class} ) {
        Carp::croak("No such class '$class' found in hierarchy");
    }
    return @{ $self->{classes}{$class}{methods} };
}

sub _get_parents {
    my ( $self, $class ) = @_;
    return if $class eq 'UNIVERSAL' or !$self->_is_real_package($class);
    no strict 'refs';

    my @parents = List::MoreUtils::uniq( @{"$class\::ISA"} );
    if ( $self->universal && not @parents ) {
        @parents = 'UNIVERSAL';
    }
    if ( my $ignore = $self->ignore ) {
        @parents = grep { !/$ignore/ } @parents;
    }
    return @parents;
}

sub _is_real_package {
    my ( $proto, $class ) = @_;
    no strict 'refs';
    no warnings 'uninitialized';
    return 1 if 'UNIVERSAL' eq $class;
    return
      unless eval {
          my $stash = \%{"$class\::"};
          defined $stash->{ISA} && defined *{ $stash->{ISA} }{ARRAY}
            || scalar grep { defined *{$_}{CODE} } sort values %$stash;
      };
}

# This is the heart of where we set just about everything up.
sub _build_hierarchy {
    my ( $self, @classes ) = @_;
    for my $class (@classes) {
        if ( my $ignore = $self->ignore ) {
            next if $class =~ $ignore;
        }
        if ( $self->clean ) {
            next if $class =~ PSEUDO_PACKAGES;
        }
        next  unless my @parents = $self->_get_parents($class);
        $self->_register_class($_) foreach $class, @parents;
        $self->_add_children($class);
        $self->_build_paths($class);
        $self->_add_parents($class);
    }
}

# This method builds 'paths'.  These are the paths the inheritance hierarchy
# will take through the code to find a method.  This is based on Perl's
# default search order, not C3.
sub _build_paths {
    my ( $self, $class ) = @_;

    my @parents = $self->_get_parents($class);

    # XXX strictly speaking, we can skip $do_chg, but if path() get's
    # expensive (such as testing for valid classes), then we
    # need it.
    my $do_chg;
    my @paths;

    foreach my $path ( $self->paths ) {
        if ( $path->[-1] eq $class ) {
            foreach my $parent (@parents) {
                if ( grep { $parent eq $_ } @$path ) {
                    my $circular = join ' -> ' => @$path, $parent;
                    Carp::croak("Circular path found in path ($circular)");
                }
            }
            ++$do_chg;
            push @paths => map { [ @$path, $_ ] } @parents;
        }
        else {
            push @paths => $path;
        }
    }

    $self->paths(@paths) if $do_chg;
}

sub _add_parents {
    my ( $self, $class ) = @_;

    # This algorithm will follow classes in Perl's default inheritance
    # order
    foreach my $parent ( $self->_get_parents($class) ) {
        push @{ $self->{list_classes} } => $parent
          unless grep { $_ eq $parent } @{ $self->{list_classes} };
        $self->{classes}{$parent}{count}++;
        $self->_build_hierarchy($parent);
    }
}

sub _add_children {
    my ( $self, $class ) = @_;
    my @parents = $self->_get_parents($class);

    $self->{classes}{$class}{parents} = \@parents;

    foreach my $parent (@parents) {
        $self->_add_child( $parent, $class );
        $self->graph->add_edge_once( $class, $parent );
    }
    return $self;
}

sub _add_child {
    my ( $self, $class, $child ) = @_;

    my $children = $self->{classes}{$class}{children};
    unless ( grep { $child eq $_ } @$children ) {
        push @$children => $child;
    }
}

=head1 CAVEATS AND PLANS

=over 4

=item * Package Variables

User-defined package variables in OO code are a code smell, but with versions
of Perl < 5.10, any subroutine also creates a scalar glob entry of the same
name, so I've not done a package variable check yet.  This will happen in the
future (there will be exceptions, such as with @ISA).

=item * C3 Support

I'd like support for alternate method resolution orders.  If your classes use
C3, you may get erroneous results.  See L<paths> for a workaround.

=back

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-class-sniff at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Sniff>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::Sniff

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-Sniff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-Sniff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-Sniff>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-Sniff/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Class::Sniff
