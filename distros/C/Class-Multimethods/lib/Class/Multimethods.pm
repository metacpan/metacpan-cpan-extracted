package Class::Multimethods;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use Carp;

our $VERSION = '1.701';

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( multimethod resolve_ambiguous resolve_no_match superclass multimethod_wrapper );

use vars qw(%dispatch %cached %hasgeneric %ambiguous_handler %no_match_handler %max_args %min_args %dispatch_installed);

%dispatch = ();                                         # THE DISPATCH TABLE
%cached   = ();                                         # THE CACHE OF PREVIOUS RESOLUTIONS OF EMPTY SLOTS
%hasgeneric  = ();          # WHETHER A GIVEN MULTIMETHOD HAS ANY GENERIC VARIANTS
%ambiguous_handler = ();  # HANDLERS FOR AMBIGUOUS CALLS
%no_match_handler = ();   # HANDLERS FOR AMBIGUOUS CALLS
%max_args = ();                     # RECORDS MAX NUM OF ARGS IN ANY VARIANT
%min_args = ();             # RECORDS MIN NUM OF ARGS IN ANY VARIANT

%dispatch_installed = (); # RECORDS DISPATCHES ALREADY INSTALLED __BY__ __US__

# THIS IS INTERPOSED BETWEEN THE CALLING PACKAGE AND Exporter TO SUPPORT THE
# use Class:Multimethods @methodnames SYNTAX

sub import
{
    my $package = (caller)[0];
    install_dispatch($package,pop @_) while $#_;
    Class::Multimethods->export_to_level(1);
}


# INSTALL A DISPATCHING SUB FOR THE NAMED MULTIMETHOD IN THE CALLING PACKAGE

sub install_dispatch
{
    my ($pkg, $name) = @_;
    # eval "sub ${pkg}::$name { Class::Multimethods::dispatch('$name',\@_) }"
    if ( ! $dispatch_installed{$pkg}{$name} )
    {
            eval(make_dispatch($pkg,$name)) || croak "internal error: $@";
            $dispatch_installed{$pkg}{$name}= 1;
    }
    #eval(make_dispatch($pkg,$name)) || croak "internal error: $@"
    #   unless eval "defined \&${pkg}::$name";
}

# REGISTER RESOLUTION FUNCTIONS FOR AMBIGUOUS AND NO-MATCH CALLS

sub resolve_ambiguous
{
    my $name = shift;
    if (@_ == 1 && ref($_[0]) eq 'CODE')
        { $ambiguous_handler{$name} = $_[0] }
    else
        { $ambiguous_handler{$name} = join ',', @_ }
}

sub resolve_no_match
{
    my $name = shift;
    if (@_ == 1 && ref($_[0]) eq 'CODE')
        { $no_match_handler{$name} = $_[0] }
    else
        { $no_match_handler{$name} = join ',', @_ }
}

# GENERATE A SPECIAL PROXY OBJECT TO INDICATE THAT THE ANCESTOR OF AN OBJECT'S
# CLASS IS REQUIRED

sub superclass
{
    my ($obj, $super) = @_;
    $super = ref($obj) || ( (~$obj&$obj) eq 0 ? '#' : '$' ) if @_ <= 1;
    bless \$obj, (@_ > 1 )
        ? "Class::Multimethods::SUPERCLASS_IS::$super"
        : "Class::Multimethods::SUPERCLASS_OF::$super";
}

sub _prettify
{
                $_[0] =~ s/Class::Multimethods::SUPERCLASS_IS:://
    or $_[0] =~ s/Class::Multimethods::SUPERCLASS_OF::(.*)/superclass($1)/;
}

# SQUIRREL AWAY THE PROFFERED SUB REF INDEXED BY THE MULTIMETHOD NAME
# AND THE TYPE NAMES SUPPLIED. CAN ALSO BE USED WITH JUST THE MULTIMETHOD
# NAME IN ORDER TO INSTALL A SUITABLE DISPATCH SUB INTO THE CALLING PACKAGE

sub multimethod
{
    my $package = (caller)[0];
    my $name  = shift;
    install_dispatch($package,$name);

    if (@_)         # NOT JUST INSTALLING A DISPATCH SUB...
    {
        my $code = pop;
        croak "multimethod: last arg must be a code reference"
            unless ref($code) eq 'CODE';

        my @types = @_;

        for ($Class::Multimethods::max_args{$name})
            { $_ = @types if !defined || @types > $_ }
        for ($Class::Multimethods::min_args{$name})
            { $_ = @types if !defined || @types < $_ }
            
        my $sig = join ',', @types;

        $Class::Multimethods::hasgeneric{$name} ||= $sig =~ /\*/;

        carp "Multimethod $name($sig) redefined"
            if $^W && exists $dispatch{$name}{$sig};
        $dispatch{$name}{$sig} = $code;

        # NOTE: ADDING A MULTIMETHOD COMPROMISES CACHING
        # THIS IS A DUMB, BUT FAST, FIX...
        $cached{$name} = {};
    }
}


# THIS IS THE ACTUAL MEAT OF THE PACKAGE -- A GENERIC DISPATCHING SUB
# WHICH EXPLORES THE %dispatch AND %cache HASHES LOOKING FOR A UNIQUE
# BEST MATCH...

sub make_dispatch # ($name)
{
    my ($pkg,$name) = @_;
    my $code = q{

    sub PACKAGE::NAME
    {
    # MAP THE ARGS TO TYPE NAMES, MAP VALUES TO '#' (FOR NUMBERS)
    # OR '$' (OTHERWISE). THEN BUILD A FUNCTION TYPE SIGNATURE
    # (LIKE A "PATH" INTO THE VARIOUS TABLES)

        my $sig = "";
        my $nexttype;
        foreach ( @_ )
        {
            $nexttype = ref || ( (~$_&$_) eq 0 ? '#' : '$' );
            $sig .= $nexttype;
            $sig .= ",";
        }
        chop $sig;

        my $code = $Class::Multimethods::dispatch{'NAME'}{$sig}
            || $Class::Multimethods::cached{'NAME'}{$sig};
                
        return $code->(@_) if ($code);

        my @types = split /,/, $sig;
        for (my $i=1; $i<@types; $i++)
        {
            $_[$i] = ${$_[$i]}
                if index($types[$i],'Class::Multimethods::SUPERCLASS')==0;
        }
        my %tried = ();             # USED TO AVOID MULTIPLE MATCHES ON SAME SIG
        my @code;      # STORES LIST OF EQUALLY-CLOSE MATCHING SUBS
        my @candidates = ( [@types] );  # STORES POSSIBLE MATCHING SIGS

    # TRY AND RESOLVE TO AN TYPE-EXPLICIT SIGNATURE (USING INHERITANCE)

        1 until (Class::Multimethods::resolve('NAME',\@candidates,\@code,\%tried) || !@candidates);

    # IF THAT DOESN'T WORK, TRY A GENERIC SIGNATURE (IF THERE ARE ANY)
    # THE NESTED LOOPS GENERATE ALL POSSIBLE PERMUTATIONS OF GENERIC
    # SIGNATURES IN SUCH A WAY THAT, EACH TIME resolve IS CALLED, ALL
    # THE CANDIDATES ARE EQUALLY GENERIC (HAVE AN EQUAL NUMBER OF GENERIC
    # PLACEHOLDERS)

        if ( @code == 0 && $Class::Multimethods::hasgeneric{'NAME'} )
        {
            # TRY GENERIC VERSIONS
            my @gencandidates = ([@types]);
            GENERIC: for (0..$#types)
            {
                @candidates = ();
                for (my $gci=0; $gci<@gencandidates; $gci++)
                {
                    for (my $i=0; $i<@types; $i++)
                    {
                        push @candidates,
                                            [@{$gencandidates[$gci]}];
                        $candidates[-1][$i] = "*";
                    }
                }
                @gencandidates = @candidates;
                1 until (Class::Multimethods::resolve('NAME',\@candidates,\@code,\%tried) || !@candidates);
                last GENERIC if @code;
            }
        }

    # RESOLUTION PROCESS COMPLETED...
    # IF EXACTLY ONE BEST MATCH, CALL IT...

        if ( @code == 1 )
        {
            $Class::Multimethods::cached{'NAME'}{$sig} = $code[0];
            return $code[0]->(@_);
        }

    # TWO OR MORE EQUALLY LIKELY CANDIDATES IS AMBIGUOUS...
        elsif ( @code > 1)
        {
            my $handler = $Class::Multimethods::ambiguous_handler{'NAME'};
            if (defined $handler)
            {
                return $handler->(@_)
                    if ref $handler;
                return $Class::Multimethods::dispatch{'NAME'}{$handler}->(@_)
                    if defined $Class::Multimethods::dispatch{'NAME'}{$handler};
            }
            _prettify($sig);
            croak "Cannot resolve call to multimethod NAME($sig). " .
                                    "The multimethods:\n" .
                join("\n",
                    map { "\tNAME(" . join(',',@$_) . ")" }
                        @candidates) .
                "\nare equally viable";
        }

    # IF *NO* CANDIDATE, NO WAY TO DISPATCH THE CALL
        else
        {
            my $handler = $Class::Multimethods::no_match_handler{'NAME'};
            if (defined $handler)
            {
                return $handler->(@_)
                    if ref $handler;
                return $Class::Multimethods::dispatch{'NAME'}{$handler}->(@_)
                    if defined $Class::Multimethods::dispatch{'NAME'}{$handler};
            }
            _prettify($sig);
            croak "No viable candidate for call to multimethod NAME($sig)";
        }
    }
    1;

    };
    $code =~ s/PACKAGE/$pkg/g;
    $code =~ s/NAME/$name/g;
    return $code;
}


# THIS SUB TAKES A LIST OF EQUALLY LIKELY CANDIDATES (I.E. THE SAME NUMBER OF
# INHERITANCE STEPS AWAY FROM THE ACTUAL ARG TYPES) AND BUILDS A LIST OF
# MATCHING ONES. IF THERE AREN'T ANY MATCHES, IT BUILDS A NEW LIST OF
# CANDIDATES, BY GENERATING PERMUTATIONS OF THE SET OF PARENT TYPES FOR
# EACH ARG TYPE.

sub resolve
{
    my ($name, $candidates, $matches, $tried) = @_;
    my %newcandidates = ();
    foreach my $candidate ( @$candidates )
    {
        # print "trying @$candidate...\n";

    # BUILD THE TYPE SIGNATURE AND ENSURE IT HASN'T ALREADY BEEN CHECKED

                                my $sig = join ',', @$candidate;
        next if $tried->{$sig};
        $tried->{$sig} = 1;
    
    # LOOK FOR A MATCHING SUB REF IN THE DISPATCH TABLE AND REMEMBER IT...

        my $match = $Class::Multimethods::dispatch{$name}{$sig};
        if ($match && ref($match) eq 'CODE') 
        {
            push @$matches, $match;
            next;
        }

    # OTHERWISE, GENERATE A NEW SET OF CANDIDATES BY REPLACING EACH
    # ARGUMENT TYPE IN TURN BY EACH OF ITS IMMEDIATE PARENTS. EACH SUCH
    # NEW CANDIDATE MUST BE EXACTLY 1 DERIVATION MORE EXPENSIVE THAN
    # THE CURRENT GENERATION OF CANDIDATES. NOTE, THAT IF A MATCH HAS
    # BEEN FOUND AT THE CURRENT GENERATION, THERE IS NO NEED TO LOOK
    # ANY DEEPER...

        if (!@$matches)
        {
            for (my $i = 0; $i<@$candidate ; $i++)
            {
                next if $candidate->[$i] =~ /[^\w:#]/;
                no strict 'refs';
                my @parents;
                if ($candidate->[$i] eq '#')
                    { @parents = ('$') }
                elsif ($candidate->[$i] =~ /\AClass::Multimethods::SUPERCLASS_IS::(.+)/)
                    { @parents = ($1) }
                elsif ($candidate->[$i] =~ /\AClass::Multimethods::SUPERCLASS_OF::(.+)/)
                    { @parents = ($1 eq '#') ? '$' : @{$1."::ISA"} } 
                else
                    { @parents = @{$candidate->[$i]."::ISA"} } 
                foreach my $parent ( @parents )
                {
                    my @newcandidate = @$candidate;
                    $newcandidate[$i] = $parent;
                    $newcandidates{join ',', @newcandidate} = [@newcandidate];
                }
            }
            
        }
    }

# IF NO MATCHES AT THE CURRENT LEVEL, RESET THE CANDIDATES TO THOSE AT
# THE NEXT LEVEL...

    @$candidates = values %newcandidates unless @$matches;

    return scalar @$matches;
}

# SUPPORT FOR analyse

my %children;
my %parents;

sub build_relationships
{
    no strict "refs";
    %children = ( '$' => [ '#' ] );
    %parents  = ( '#' => [ '$' ] );
    my (@packages) = @_;
    foreach my $package (@packages)
    {
        foreach my $parent ( @{$package."::ISA"} )
        {
            push @{$children{$parent}}, $package;
            push @{$parents{$package}}, $parent;
        }
    }
}


sub list_packages
{
    no strict "refs";
    my $self = $_[0]||"main::";
    my @children = ( $self );
    foreach ( keys %{$self} )
    {
        next unless /::$/ && $_ ne $self;
        push @children, list_packages("$self$_")
    }
    @children = map { s/^main::(.+)$/$1/; s/::$//; $_ } @children
        unless $_[0];
    return @children;
}

sub list_ancestors
{
    my ($class) = @_;
    my @ancestors = ();
    foreach my $parent ( @{$parents{$class}} )
    {
        push @ancestors, list_ancestors($parent), $parent;
    }
    return @ancestors;
}

sub list_descendents
{
    my ($class) = @_;
    my @descendents = ();
    foreach my $child ( @{$children{$class}} )
    {
        push @descendents, $child, list_descendents($child);
    }
    return @descendents;
}

sub list_hierarchy
{
    my ($class) = @_;
    my @hierarchy = list_ancestors($class);
    push @hierarchy, $class;
    push @hierarchy, list_descendents($class);
    return @hierarchy;
}

@Class::Multimethods::dont_analyse = qw
(
    Exporter
    DynaLoader 
    AutoLoader
);

sub generate_argsets
{
    my ($multimethod) = @_;

    my %ignore;
    @ignore{@Class::Multimethods::dont_analyse} = ();


    return unless $min_args{$multimethod};

    my @paramlists = ();

    foreach my $typeset ( keys %{$Class::Multimethods::dispatch{$multimethod}} )
    {
        next if $typeset =~ /\Q*/;
        my @nexttypes = split /,/, $typeset;        
        for my $i (0..$#nexttypes)
        {
            for my $ancestor ( list_hierarchy $nexttypes[$i] )
            {
                $paramlists[$i]{$ancestor} = 1
                    unless exists $ignore{$ancestor};
            }
        }
    }

    my @argsets = ();

    foreach (@paramlists) { $_ = [keys %{$_}] }

    use Data::Dumper;
    # print Data::Dumper->Dump([@paramlists]);

    foreach my $argcount ($min_args{$multimethod}..$max_args{$multimethod})
    {
        push @argsets, combinations(@paramlists[0..$argcount-1]);
    }

    # print STDERR Data::Dumper->Dump([@argsets]);

    return @argsets;
}

sub combinations
{
    my (@paramlists) = @_;
    return map { [$_] } @{$paramlists[0]} if (@paramlists==1);
    my @combs = ();
    my @subcombs = combinations(@paramlists[1..$#paramlists]);
    foreach my $firstparam (@{$paramlists[0]})
    {
        foreach my $subcomb ( @subcombs )
        {
            push @combs, [$firstparam, @{$subcomb}];
        }
    }
    return @combs;
}

sub analyse
{
    my ($multimethod, @argsets) = @_;
    my ($package,$file,$line) = caller(0);
    my ($sub) = (caller(1))[3] || "main code";
    my $case_count = @argsets;
    my $ambiguous_handler = $ambiguous_handler{$multimethod};
    my $no_match_handler = $no_match_handler{$multimethod};
    $ambiguous_handler = "$multimethod($ambiguous_handler)"
        if $ambiguous_handler && ref($ambiguous_handler) ne "CODE";
    $no_match_handler = "$multimethod($no_match_handler)"
        if $no_match_handler && ref($no_match_handler) ne "CODE";
    build_relationships list_packages;
    if ($case_count)
    {
        my @newargsets;
        foreach my $argset ( @argsets )
        {
            my @argset = map { ref eq 'ARRAY' ? $_ : [$_] } @$argset;
            push @newargsets, combinations(@argset);
        }
        @argsets = @newargsets;
        $case_count = @argsets;
    }
    else
    {
        @argsets = generate_argsets($multimethod);
        $case_count = @argsets;
        unless ($case_count)
        {
            print STDERR "[No variants found for $multimethod. No analysis possible.]\n\n";
    print STDERR "="x72, "\n\n";
            return;

        }
        print STDERR "[Generated $case_count test cases for $multimethod]\n\n"
    }

    print STDERR "Analysing calls to $multimethod from $sub ($file, line $line):\n";
    my $case = 1;

    my $successes = 0;
    my @fails = ();
    my @ambigs = ();

    foreach my $argset ( @argsets )
    {
        my $callsig = "${multimethod}(".join(",",@$argset).")";
        print STDERR "\n\t[$case/$case_count] For call to $callsig:\n\n";
        $case++;
        my @ordered = sort {
                                $a->{wrong_length} - $b->{wrong_length}
                                                ||
                @{$a->{incomp}} - @{$b->{incomp}}
                                                ||
                        $a->{generic} - $b->{generic}
                                                ||
                $a->{sum_dist} <=> $b->{sum_dist}
                                                }
                evaluate($multimethod, $argset);


        if ($ordered[0] && !@{$ordered[0]->{incomp}})
        {
            my $i;
            for ($i=1; $i<@ordered; $i++)
            {
                last if @{$ordered[$i]->{incomp}} ||
                    $ordered[$i]->{wrong_length} ||
                                                $ordered[$i]->{sum_dist} >
                                                    $ordered[0]->{sum_dist} ||
                                                $ordered[$i]->{generic} !=
                                                    $ordered[0]->{generic};
            }
            $ordered[$_]->{less_viable} = 1 for ($i..$#ordered);
            if ($i>1)
            {
                $ordered[$i]->{ambig} = 1 while ($i-->0)
            }
        }

        my $first = 1;
        my $min_dist = 0;
        push @fails, "\t\t$callsig\n";  # ASSUME THE WORST

        # CHECK FOR REOLUTION IF DISPATCH FAILS

        my $winner = $ordered[0];
        if ($winner && $winner->{ambig} && $ambiguous_handler)
        {
            print STDERR "\t\t(+) $ambiguous_handler\n\t\t\t>>> Ambiguous dispatch handler invoked.\n\n";
            $first = 0;
            $successes++;
            pop @fails;
        }
        elsif ($winner
                            && (@{$winner->{incomp}} || $winner->{wrong_length})
                            && $no_match_handler )
        {
            print STDERR "\t\t(+) $no_match_handler\n\t\t\t>>> Dispatch failure handler invoked.\n\n";
            $first = 0;
            $successes++;
            pop @fails;
        }
        foreach my $variant (@ordered)
        {
            if ($variant->{ambig})
            {
                print STDERR "\t\t(?) $variant->{sig}\n\t\t\t>>> Ambiguous. Distance: $variant->{sum_dist}\n";
                push @ambigs, pop @fails if $first;
            }
            elsif (@{$variant->{incomp}} == 1)
            {
                print STDERR "\t\t(-) $variant->{sig}\n\t\t\t>>> Not viable. Incompatible argument: ", @{$variant->{incomp}}, "\n";
            }
            elsif (@{$variant->{incomp}})
            {
                print STDERR "\t\t(-) $variant->{sig}\n\t\t\t>>> Not viable. Incompatible arguments: ", join(",",@{$variant->{incomp}}), "\n";
            }
            elsif ($variant->{wrong_length})
            {
                print STDERR "\t\t(-) $variant->{sig}\n\t\t\t>>> Not viable. Wrong number of arguments\n";
            }
            elsif ($first)
            {
                print STDERR "\t\t(+) $variant->{sig}\n\t\t\t>>> Target. Distance: $variant->{sum_dist}\n\n";
                $min_dist = $variant->{sum_dist};
                $successes++;
                pop @fails;
            }
            elsif ($variant->{generic} && $variant->{sum_dist} < $min_dist)
            {
                print STDERR "\t\t(*) $variant->{sig}\n\t\t\t>>> Viable, but generic. Distance: $variant->{sum_dist} (generic)\n";
            }
            elsif ($variant->{generic})
            {
                print STDERR "\t\t(*) $variant->{sig}\n\t\t\t>>> Viable. Distance: $variant->{sum_dist} (generic)\n";
            }
            else
            {
                print STDERR "\t\t(x) $variant->{sig}\n\t\t\t>>> Viable. Distance: $variant->{sum_dist}\n";
            }
            $first = 0;
        }
        print STDERR "\n";
    }
    print STDERR "\n", "-"x72, "\nSummary for calls to $multimethod from $sub ($file, line $line):\n\n";

    printf STDERR "\tSuccessful dispatch in %2.0f%% of calls\n",
            $successes/$case_count*100;
    printf STDERR "\tDispatch ambiguous for %2.0f%% of calls\n",
            @ambigs/$case_count*100;
    printf STDERR "\tWas unable to dispatch %2.0f%% of calls\n",
            @fails/$case_count*100;

    print STDERR "\nAmbiguous calls:\n", @ambigs if @ambigs;
    print STDERR "\nUndispatchable:\n", @fails if @fails;

    print STDERR "\n", "="x72, "\n\n";

}

my %distance;
sub distance
{
    my ($from, $to) = @_;

    return 0 if $from eq $to;
    return -1 if $to eq '*';
    return $distance{$from}{$to} if defined $distance{$from}{$to};

    if ($parents{$from})
    {
        foreach my $parent ( @{$parents{$from}} )
        {
            my $distance = distance($parent,$to);
            if (defined $distance)
            {
                $distance{$from}{$to} = $distance+1;
                return $distance+1;
            }
        }
    }
    return undef;
}

sub evaluate
{
    my ($name, $types) = @_;
    my @results = ();
    my $sig = join ',', @$types;

    SET: foreach my $typeset ( keys %{$Class::Multimethods::dispatch{$name}} )
    {
        
        push @results, { sig                            => "$name($typeset)",
                    incomp              => [],
                    sum_dist    => 0,
                    wrong_length    => 0,
                    generic => 0,
                                        };
        my @nexttypes = split /,/, $typeset;        
        if (@nexttypes != @$types)
        {
            $results[-1]->{wrong_length} = 1;
            next SET;
        }

        my @dist;
        PARAM: for (my $i=0; $i<@$types; $i++)
        {
            my $nextdist = distance($types->[$i], $nexttypes[$i]);
            push @{$results[-1]->{dist}}, $nextdist;
            if (!defined $nextdist)
            {
                push @{$results[-1]->{incomp}}, $i;
            }
            elsif ($nextdist < 0)
            {
                $results[-1]->{generic} = 1;
            }
            else
            {
                $results[-1]->{sum_dist} += $nextdist
            }
        }
    }
    return @results;
}


1;
__END__

=head1 NAME

Class::Multimethods - Support multimethods and function overloading in Perl

=head1 VERSION

This document describes version 1.701 of Class::Multimethods
released April  9, 2000.

=head1 SYNOPSIS

 # IMPORT THE multimethod DECLARATION SUB...

    use Class::Multimethods;

 # DECLARE VARIOUS MULTIMETHODS CALLED find...

 # 1. DO THIS IF find IS CALLED WITH A Container REF AND A Query REF...

    multimethod find => (Container, Query) 
		     => sub { $_[0]->findquery($_[1]) };

 # 2. DO THIS IF find IS CALLED WITH A Container REF AND A Sample REF...

    multimethod find => (Container, Sample)
		     => sub { $_[0]->findlike($_[1]) };

 # 3. DO THIS IF find IS CALLED WITH AN Index REF AND A Word REF...

    multimethod find => (Index, Word)      
		     => sub { $_[0]->lookup_word($_[1]) };

 # 4. DO THIS IF find IS CALLED WITH AN Index REF AND A qr// PATTERN

    multimethod find => (Index, Regexp)    
		     => sub { $_[0]->lookup_rx($_[1]) };

 # 5. DO THIS IF find IS CALLED WITH AN Index REF AND A NUMERIC SCALAR

    multimethod find => (Index, '#')       
		     => sub { $_[0]->lookup_elem($_[1]) };

 # 6. DO THIS IF find IS CALLED WITH AN Index REF AND A NON-NUMERIC SCALAR

    multimethod find => (Index, '$')       
		     => sub { $_[0]->lookup_str($_[1]) };

 # 7. DO THIS IF find IS CALLED WITH AN Index REF AND AN UNBLESSED ARRAY REF
 #    (NOTE THE RECURSIVE CALL TO THE find MULTIMETHOD)

    multimethod find => (Index, ARRAY)     
		     => sub { map { find($_[0],$_) } @{$_[1]} };


 # SET UP SOME OBJECTS...

	my $cntr = new Container ('./datafile');
	my $indx = $cntr->get_index();

 # ...AND SOME INHERITANCE...

	@BadWord::ISA = qw( Word );
	my $badword = new BadWord("fubar");

 # ...AND EXERCISE THEM...

	print find($cntr, new Query('cpan OR Perl'));		# CALLS 1.
	print find($cntr, new Example('by a committee'));	# CALLS 2.

	print find($indx, new Word('sugar'));			# CALLS 3.
	print find($indx, $badword);				# CALLS 3.
	print find($indx, qr/another brick in the Wall/);	# CALLS 4.
	print find($indx, 7);					# CALLS 5.
	print find($indx, 'But don't do that.');		# CALLS 6.
	print find($indx, [1,"one"]);				# CALLS 7,
								# THEN 5 & 6.
								


=head1 DESCRIPTION

The Class:Multimethod module exports a subroutine (&multimethod)
that can be used to declare other subroutines that are dispatched
using a algorithm different from the normal Perl subroutine or
method dispatch mechanism.

Normal Perl subroutines are dispatched by finding the
appropriately-named subroutine in the current (or specified) package
and calling that. Normal Perl methods are dispatched by attempting to
find the appropriately-named subroutine in the package into which the
invoking object is blessed or, failing that, recursively searching for
it in the packages listed in the appropriate C<@ISA> arrays.

Class::Multimethods multimethods are dispatched quite differently. The
dispatch mechanism looks at the classes or types of each argument to
the multimethod (by calling C<ref> on each) and determines the
"closest" matching I<variant> of the multimethod, according to the
argument types specified in the variants' definitions (see L<Finding
the "nearest" multimethod> for a definition of "closest").

The result is something akin to C++'s function overloading, but more
intelligent, since multimethods take the inheritance relationships of
each argument into account. Another way of thinking of the mechanism
is that it performs polymorphic dispatch on I<every> argument of a 
method, not just the first.

=head2 Defining multimethods

The Class::Multimethods module exports a subroutine called
C<multimethod>, which can be used to specify multimethod variants with
the dispatch behaviour described above. The C<multimethod> subroutine
takes the name of the desired multimethod, a list of class names, and a
subroutine reference, and generates a corresponding multimethod variant
within the current package.

For example, the declaration:

	package LargeInt;   @ISA = (LargeNumeric);
	package LargeFloat; @ISA = (LargeNumeric);

	package LargeNumeric;
	use Class::Multimethods;

	multimethod divide => (LargeInt, LargeInt) => sub
	{
		LargeInt::divide($_[0],$_[1]);
	};

	multimethod divide => (LargeInt, LargeFloat) => sub
	{
		LargeFloat::divide($_[0]->AsLargeFloat(),$_[1]));
	};

creates a (single!) multimethod C<&LargeNumeric::divide> with two variants.
If the multimethod is called with two references to C<LargeInt> objects
as arguments, the first variant (i.e. anonymous subroutine) is invoked. If the
multimethod is called with a C<LargeInt> reference and a C<LargeFloat>
reference, the second variant is called.

Note that if you're running under C<use strict>, the list of bareword
class names in each variant definition will cause problems.
In that case you'll need to say:

	multimethod divide => ('LargeInt', 'LargeInt') => sub
	{
		LargeInt::divide($_[0],$_[1]);
	};

	multimethod divide => ('LargeInt', 'LargeFloat') => sub
	{
		LargeFloat::divide($_[0]->AsLargeFloat(),$_[1]));
	};


or better still:

	multimethod divide => qw( LargeInt LargeInt ) => sub
	{
		LargeInt::divide($_[0],$_[1]);
	};

	multimethod divide => qw( LargeInt LargeFloat ) => sub
	{
		LargeFloat::divide($_[0]->AsLargeFloat(),$_[1]));
	};

or best of all (;-):

	{
	    no strict;
	
	    multimethod divide => (LargeInt, LargeInt) => sub
	    {
		LargeInt::divide($_[0],$_[1]);
	    };

	    multimethod divide => (LargeInt, LargeFloat) => sub
	    {
		LargeFloat::divide($_[0]->AsLargeFloat(),$_[1]));
	    };
	}


Calling the multimethod with any other combination of C<LargeNumeric>
reference arguments (e.g. a reference to a C<LargeFloat> and a
reference to a C<LargeInt>, or two C<LargeFloat> referencess) results
in an exception being thrown, with the message:

	No viable candidate for call to
	multimethod LargeNumeric::divide at ...

To avoid this, we could provide a "catch-all" variant:

	multimethod divide => (LargeNumeric, LargeNumeric) => sub
	{
		LargeFloat::divide($_[0]->AsLargeFloat(),$_[1]->AsLargeFloat));
	}

Now, calling C<&LargeNumeric::divide> with either a C<LargeFloat>
reference and a C<LargeInt> reference or two C<LargeFloat> references
results in this third variant being invoked. Note that, adding this
third alternative doesn't affect calls to the other two, since
Class::Multimethods always selects the "nearest" match (see L<Finding
the "nearest" multimethod> below for details of what "nearest" means).

This "best fit" behaviour is extremely useful, because it means you can
code the specific cases you want to handle, and the one or more
"catch-all" cases to deal with any other combination of arguments.


=head2 Finding the "nearest" multimethod

Of course, the usefulness of the entire system depends on how intelligently
Class::Multimethods decides which version of a multimethod is "nearest"
to the set of arguments you provided. This decision process is called
"dispatch resolution", and Class::Multimethods does it like this:

=over 4

=item 1.

If the types of the arguments given (as determined by C<ref>) exactly
match the types specified in any variant of the multimethod, that variant
is the one called.

=item 2.

Otherwise, Class::Multimethods compiles a list of "viable targets". A
viable target is a variant of the multimethod with the correct number
of parameters, such that for each parameter the specified parameter
type is a base class of the actual type of the corresponding argument
in the actual call.

=item 3.

If there is only one viable target, it is immediately called. if there are
no viable targets, an exception is thrown indicating the fact.

=item 4.

Otherwise, Class::Multimethod examines each viable target and computes
its "distance" to the actual set of arguments. The distance of a target
is the sum of the distances of each of its parameters. The distance of
an individual parameter is the number of inheritance steps between its
class and the actual class of the corresponding argument.

Hence, if a specific argument is of the same class as the corresponding
parameter type, the distance to that parameter is zero.
If the argument is of a class that is an immediate child of the
parameter type, the distance is 1. If the argument is of a class which 
is a "grandchild" of the parameter type, the distance is 2. Et cetera.

=item 5.

Class::Multimethod then chooses the viable target with the smallest "distance"
as the "final target". If there is more than one viable target with an equally
smallest distance, an exception is thrown indicating that the call is
ambiguous. If there I<is> only a single final target
Class::Multimethod records its identity (so the distance computations don't
have to be repeated next time the same set of argument types is used),
and then calls that final target.

=back

=head2 Where to define multimethods

Class::Multimethods doesn't care which packages the individual variants
of a multimethod are defined in. Every variant of a multimethod is
visible to the underlying multimethod dispatcher, no matter where it
was defined.

For example, the three variants for the C<divide> multimethod shown
above could all be defined in the LargeNumeric package, or the
LargeFloat package or the LargeInt package, or in C<main>, or in a
separate package of their own.

Of course, to make a specific multimethod visible within a given
package you still need to tell that package about it. That can be done
by specifying the name of the multimethod only (i.e. no argument list
or variant code):

	package Some::Other::Package::That::Wants::To::Use::divide;

	use Class::Multimethods;
	multimethod "divide";

For convenience, the declaration itself can be abbreviated to:

	package Some::Other::Package::That::Wants::To::Use::divide;

	use Class::Multimethods "divide";


Similarly, Class::Multimethod doesn't actually care whether
multimethods are called as methods or as regular subroutines. This is quite
different from the behaviour of normal Perl methods and subroutines, where how
you call them, determines how they are dispatched.

With multimethods, since all arguments participate in the polymorphic
resolution of a call (instead of just the first), it make no difference
whether a multimethod is called as a subroutine:

	numref3 = divide($numref1, $numref2);

or a method:

	numref3 = $numref1->divide($numref2);

(so long as the multimethod has been I<declared> in the appropriate place:
the current package for subroutine-like calls, or the invoking object's
package for method-like calls).


In other words, Class::Multimethods also provides general subroutine
overloading. For example:

	package main;
	use IO;
	use Class::Multimethods;

	multimethod debug => (IO::File) => sub
	{
		print $_[0] "This should go in a file\n";
	}

	multimethod debug => (IO::Pipe) => sub
	{
		print $_[0] "This should go down a pipe\n";
	}

	multimethod debug => (IO::Socket) => sub
	{
		print $_[0] "This should go out a socket\n";
	}

	# and later

	debug($some_io_handle);


=head2 Non-class types as parameters

Yet another thing Class::Multimethods doesn't care about is whether the
parameter types for each multimethod variant are the names of "real"
classes or just the identifiers returned when raw Perl data types are
passed to the built-in C<ref> function. That means you could also
define multimethod variants like this:

	multimethod stringify => (ARRAY) => sub
	{
		my @arg = @{$_[0]};
		return "[" .  join(", ",@arg) . "]";
	}

	multimethod stringify => (HASH) => sub
	{
		my %arg = %{$_[0]};
		return "{" . join(", ", map("$_=>$arg{$_}",keys %arg)) . "}";
	}

	multimethod stringify => (CODE) => sub
	{
		return "sub {???}";
	}

	# and later

	print stringify( [1,2,3] ), "\n";
	print stringify( {a=>1,b=>2,c=>3} ), "\n"; 
	print stringify( $array_or_hash_ref ), "\n";

Provided you remember that the parameter types ARRAY, HASH, and CODE
really mean "reference to array", "reference to hash", and "reference
to subroutine", the names of built-in types (i.e. those returned by
C<ref>) are perfectly acceptable as multimethod parameters.

That's a nice bonus, but there's a problem. Because C<ref> returns an
empty string when given any literal string or numeric value, the
following code:

	print stringify( 2001 ), "\n";
	print stringify( "a multiple dispatch oddity" ), "\n";

will produce a nasty surprise:

	No viable candidate for call to multimethod stringify() at line 1

That's because the dispatch resolution process first calls C<ref(2001)>
to get the class name for the first argument, and therefore thinks it's
of class C<"">. Since there's no C<stringify> variant with an empty string as
its parameter type, there are no viable targets for the multimethod
call. Hence the exception.

To overcome this limitation, Class::Multimethods allows three special
pseudo-type names within the parameter lists of multimethod variants.
The first pseudo-type - C<"$"> - is the class that Class::Multimethods
pretends that any scalar value (except a reference) belongs to. Hence,
you can make the two recalcitrant stringifications of scalars work
by defining:

	multimethod stringify => ("$")
		=> sub { return qq{"$_[0]"} }

With that definition in place, the two calls:

	print stringify( 2001 ), "\n";
	print stringify( "a multiple dispatch oddity" ), "\n";

would produce:

	"2001"
	"a multiple dispatch oddity"

That solves the problem, but not as elegantly as it might. It
would be better if numeric values were left unquoted. To this end,
Class::Multimethods offers a second pseudo-type - C<"#"> - which is
the class it pretends numeric scalar values belong to (where
a scalar value is "numeric" if it's truly a numerical value (without implicit
coercions):

	$var = 0	# numeric --> '$'
	$var = 0.0	# numeric --> '$'
	$var = "0";	# string  --> '#'

Hence you could now also define:

	multimethod stringify => ("#")
		=> sub { return "+$_[0]" }
	
the two calls to C<&stringify> now
produce:

	+2001
	"a multiple dispatch oddity"

The final pseudo-type - C<"*"> - is a wild-card or "don't care" type
specifier, which matches I<any> argument type exactly. For example, we
could provide a "catch-all" C<stringify> variant (to handle "GLOB" or
"IO" references, for example):

	multimethod stringify => ("*")
		=> sub { croak "can't stringify a " . ref($_[0]) }
	

The C<"*"> pseudo-type can also be used in multiple-argument multimethods.
For example:

	# General case...

	    multimethod handle => (Window, Event, Mode)
		=> sub { ... }
	
	# Special cases...

	    multimethod handle => (MovableWindow, MoveEvent, NormalMode)
		=> sub { ... }

	    multimethod handle => (ScalableWindow, ResizeEvent, NormalMode)
		=> sub { ... }

	# Very special case
	# (ignore any event in any window in PanicMode)

	    multimethod handle => ("*", "*", PanicMode)
		=> sub { ... }


=head2 Resolving ambiguities and non-dispatchable calls

It's relatively easy to set up a multimethod such that particular
combinations of argument types cannot be correctly dispatched. For
example, consider the following variants of a multimethod called
C<put_peg>:

	multimethod put_peg => (RoundPeg,Hole) => sub
	{
		print "a round peg in any old hole\n";
	};

	multimethod put_peg => (Peg,SquareHole) => sub
	{
		print "any old peg in a square hole\n";
	};

	multimethod put_peg => (Peg,Hole) => sub
	{
		print "any old peg in any old hole\n";
	};

If C<put_peg> is called like so:

	put_peg( RoundPeg->new(), SquareHole->new() );

then Class::Multimethods can't dispatch the call, because it cannot
decide between the C<(RoundPeg,Hole)> and C<(Peg,SquareHole)> variants,
each of which is the same "distance" (i.e. 1 derivation) from the actual
arguments.

The default behaviour is to throw an exception (i.e. die) like this:

	Cannot resolve call to multimethod put_peg(RoundPeg,SquareHole).
	The multimethods:
		put_peg(RoundPeg,Hole)
		put_peg(Peg,SquareHole)
	are equally viable at ...

Sometimes, however, the more specialized variants are only
optimizations, and a more general case (e.g. the C<(Peg,Hole)> variant)
would suffice as a default where such an ambiguity exists. If that is
the case, it's possible to tell Class::Multimethods to resolve the
ambiguity by calling that variant, using the C<resolve_ambiguous>
subroutine. C<resolve_ambiguous> is automatically exported by
Class::Multimethods and is used like this:

	resolve_ambiguous put_peg => (Peg,Hole);

That is, you specify the name of the multimethod being disambiguated, and the
signature of the variant to be used in ambiguous cases. Of course, the specified
variant must actually exist at the time of the call. If it doesn't,
Class::Multimethod ignores it and throws the usual exception.

Alternatively, if no variant is suitable as a default, you can register a reference to a
subroutine that is to be called instead:

	resolve_ambiguous put_peg => \&disambiguator;

Now, whenever C<put_peg> can't dispatch a call because it's ambiguous, 
C<disambiguator> will be called instead, with the
same argument list as C<put_peg> was given.

Of course, C<resolve_ambiguous> doesn't care what subroutine it's given a 
reference to, so you can also use an anonymous subroutine:

	resolve_ambiguous put_peg
		=> sub
		   {
			print "can't put a ", ref($_[0]),
			      " into a ", ref($_[1]), "\n";
		   };


Dispatch can also fail if there are I<no> suitable variants available
to handle a particular call. For example:

	put_peg( JPEG->new(), Loophole->new() );

which would normally produce the exception:

	No viable candidate for call to
	multimethod put_peg(JPeg,Loophole) at ...

since classes JPEG and Loophole are't in the Peg and Hole hierarchies, so
there's no inheritance path back to a more general variant.

To handle cases like this, you can use the <resolve_no_match> subroutine,
which is also exported from Class::Multimethods. C<resolve_no_match>
registers a multimethod variant, or a reference to some other subroutine, 
that is then used whenever the dispatch mechanism can't find a suitable
variant for a given multimethod call.

For example:

	resolve_no_match put_peg
		=> sub
		   {
			put_jpeg(@_)
				if ref($_[0]) eq 'JPEG';
			shift()->hang(@_)
				if ref($_[0]) eq 'ClothesPeg';
			hammer(@_)
				if ref($_[0]) eq 'TentPeg';
			# etc.
				
		   };

As with C<resolve_ambiguous> the registered variant or subroutine
is called with the same set of arguments that were passed to
the original multimethod call.

=head2 Redispatching multimethod calls

Sometimes a polymorphic method in a derived class is used to add
functionality to an inherited method. For example, a derived class's
C<print_me> method might call it's base class's C<print_me>, making use
of Perl's special C<$obj->SUPER::method()> construct:

	class Base;

	sub print_me
	{	
		my ($self) = @_;
		print "Base stuff\n";
	}

	class Derived; @ISA = qw( Base );

	sub print_me
	{
		my ($self) = @_;
		$self->SUPER::print_me();	# START LOOKING IN ANCESTORS
		print "Derived stuff\n";
	}

If the C<print_me> methods are implemented as multimethods, it's still possible
to reinvoke an "ancestral" method, using the automatically exported
C<Class::Multimethods::superclass> subroutine:

	use Class::Multimethods;

	multimethod print_me => (Base) => sub
	{	
		my ($self) = @_;
		print "Base stuff\n";
	}

	multimethod print_me => (Derived) => sub
	{
		my ($self) = @_;
		print_me( superclass($self) );	# START LOOKING IN ANCESTORS
		print "Derived stuff\n";
	}
	}

Applying C<superclass> to the multimethod argument tells Class::Multimethod
to start looking for parameter types amongst the ancestors of Derived.

It's also possible in regular Perl to explcitly tell the polymorphic dispacther
where to start looking, by explicitly qualifying the method name:

	sub Derived::print_me
	{
		my ($self) = @_;
		$self->Base::print_me();	# START LOOKING IN Base CLASS
		print "Derived stuff\n";
	}

The same is possible with multimethods. C<superclass> takes an optional second
argument that tells Class::Multimethods exactly where to start looking:

	multimethod print_me => (Derived) => sub
	{
		my ($self) = @_;
		print_me( superclass($self => Base) );	# START LOOKING IN Base
		print "Derived stuff\n";
	}

Note that, unlike regular method calls, with multimethods you can apply the
C<superclass> subroutine to any or all of a multimethod's arguments. For
example:

	multimethod handle => (MovableWindow, MoveEvent, NormalMode) => sub
	{
		my ($w, $e, $m) = @_;

		# Do any special stuff,
		# then redispatch to more general handler...

		handle(superclass($w), $e, superclass($m => Mode) );
	}

In this case the redispatch would start looking for variants which matched
C<(I<any of MovableWindow's ancestors>, MoveEvent, Mode)>.

It's also important to remember that, as with regular methods,
the class of the actual arguments doesn't change just because we subverted the
dispatch sequence. That means if the above redispatch called the handle variant
that takes arguments (Window, MoveEvent, Mode), the actual arguments would
still be of types (MovableWindow, MoveEvent, NormalMode).

=head1 DIAGNOSTICS

If you call C<multimethod> and forget to provide a code reference as the
last argument, it C<die>s with the message:

	"multimethod: last arg must be a code reference at %s"


If the dispatch mechanism cannot find any multimethod with a signature
matching the actual arguments, it C<die>s with the message:

	"No viable candidate for call to multimethod %s at %s"
	

If the dispatch mechanism finds two or more multimethods with signatures
equally "close" to the actual arguments
(see L<"The dispatch resolution process">), it C<die>s with the message:

	"Cannot resolve call to multimethod %s. The multimethods:
		%s
	 are equally viable at %s"

If you specify two variants with the same parameter lists, Class::Multimethods
warns:

	"Multimethod %s redefined at %s"

but only if $^W is true (i.e. under the C<-w> flag).

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS AND IRRITATIONS

There are undoubtedly serious bugs lurking somewhere in code this complex :-)
Bug reports and other feedback are most welcome.

Ongoing annoyances include:

=over 4

=item *

The module uses qr// constructs to improve performance. Hence it won't
run under Perls earlier than 5.005.

=item *

Multimethod dispatch is much slower than regular dispatch when the
resolution has to resort to the more generic cases (though it's
actually as very nearly as fast as doing the equivalent type resolution
"by hand", and certainly more reliable and maintainable)

=item *

The cache management is far too dumb. Adding any new multimethod
clobbers the entire cache, when it should only expunge those entries
"upstream" from the the new multimethod's actual parameter types.

It's unclear, however, under what circumstances the expense of a more
careful cache correction algorithm would ever be recouped by the savings in
dispatch (well, obviously, when the installion of multimethods is a
rare event and multimethod dispatching is frequent, but where is the
breakeven point?)

=back

=head1 COPYRIGHT

        Copyright (c) 1998-2000, Damian Conway. All Rights Reserved.
      This module is free software. It may be used, redistributed
      and/or modified under the terms of the Perl Artistic License
           (see http://www.perl.com/perl/misc/Artistic.html)
