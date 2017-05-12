package CGI::Expand;
$VERSION = '2.05';
use strict;
use warnings;

# NOTE: Exporter is not actually used
our @EXPORT = qw(expand_cgi);
our @EXPORT_OK = qw(expand_hash collapse_hash);
my %is_exported = map { $_ => 1 } @EXPORT, @EXPORT_OK;

use Carp qw(croak carp);

sub import {
    my $from_pkg = shift;
    my $to_pkg = caller;

    if(@_) {
        for my $sub (@_) {
            croak "Can't export symbol $sub" unless $is_exported{$sub};
        }
    } else {
        @_ = @EXPORT;
    }

    _export_curried($from_pkg, $to_pkg, @_);
}

sub _export_curried {
    my $from_pkg = shift;
    my $to_pkg   = shift;

    no strict 'refs';
    for my $sub (@_) {
        # export requested subs with class arg curried
        *{$to_pkg.'::'.$sub} = sub { $from_pkg->$sub(@_) };
        # get inherited implementation with interface backward compatibility
    }
}

sub separator { 
    if( defined $CGI::Expand::Separator ) {
        carp '$CGI::Expand::Separator is deprecated'
                        unless $CGI::Expand::BackCompat;
        return $CGI::Expand::Separator;
    }
    return '.';
}

sub max_array { 
    if( defined $CGI::Expand::Max_Array ) {
        carp '$CGI::Expand::Max_Array is deprecated'
                        unless $CGI::Expand::BackCompat;
        return $CGI::Expand::Max_Array;
    }
    return 100;
}

sub expand_cgi {
    my $class = shift;
    my $cgi = shift; # CGI or Apache::Request
    my %args;

    # permit multiple values CGI style
    for ($cgi->param) {
        next if (/\.[xy]$/); # img_submit=val & img_submit.x=20 -> clash
        my @vals = $cgi->param($_);
        $args{$_} = @vals > 1 ? \@vals : $vals[0];
    }
    return $class->expand_hash(\%args);
}

sub split_name {
    my $class = shift;
    my $name  = shift;
    my $sep = $class->separator();
    $sep = "\Q$sep";

    # These next two regexes are the escaping aware equivalent
    # to the following:
    # my ($first, @segments) = split(/\./, $name, -1);

    # m// splits on unescaped '.' chars. Can't fail b/c \G on next
    # non ./ * -> escaped anything -> non ./ *
    $name =~ m/^ ( [^\\$sep]* (?: \\(?:.|$) [^\\$sep]* )* ) /gx;
    my $first = $1;
    $first =~ s/\\(.)/$1/g; # remove escaping

    my (@segments) = $name =~ 
        # . -> ( non ./ * -> escaped anything -> non ./ * )
        m/\G (?:[$sep]) ( [^\\$sep]* (?: \\(?:.|$) [^\\$sep]* )* ) /gx;
    # Escapes removed later, can be used to avoid using as array index

    return ($first, @segments);
}

sub expand_hash {
    my $class = shift;
    my $flat = shift;
    my $deep = {};
    my $sep = $class->separator;

    for my $name (keys %$flat) {

        my ($first, @segments) = $class->split_name($name);

        my $box_ref = \$deep->{$first};
        for (@segments) {
            if($class->max_array && /^(0|[1-9]\d*)$/) { 
                croak "CGI param array limit exceeded $1 for $name=$_"
                    if($1 >= $class->max_array);
                $$box_ref = [] unless defined $$box_ref;
                croak "CGI param clash for $name=$_" 
                    unless ref $$box_ref eq 'ARRAY';
                $box_ref = \($$box_ref->[$1]);
            } else { 
                s/\\(.)/$1/g if $sep; # remove escaping
                $$box_ref = {} unless defined $$box_ref;
                croak "CGI param clash for $name=$_"
                    unless ref $$box_ref eq 'HASH';
                $box_ref = \($$box_ref->{$_});
            }   
        }
        croak "CGI param clash for $name value $flat->{$name}" 
            if defined $$box_ref;
        $$box_ref = $flat->{$name};
    }
    return $deep;
}

{

sub collapse_hash {
    my $class = shift;
    my $deep  = shift;
    my $flat  = {};

    $class->_collapse_hash($deep, $flat, () );
    return $flat;
}

sub join_name {
    my $class = shift;
    my $sep = substr($class->separator, 0, 1);
    return join $sep, @_;
}

sub _collapse_hash {
    my $class  = shift;
    my $deep  = shift;
    my $flat  = shift;
    # @_ is now segments

    if(! ref $deep) {
        my $name = $class->join_name(@_);
        $flat->{$name} = $deep;
    } elsif(ref $deep eq 'HASH') {
        for (keys %$deep) {
            # escape \ and separator chars (once only, at this level)
            my $name = $_;
            if (defined (my $sep = $class->separator)) {
                $sep = "\Q$sep";
                $name =~ s/([\\$sep])/\\$1/g 
            }
            $class->_collapse_hash($deep->{$_}, $flat, @_, $name);
        }
    } elsif(ref $deep eq 'ARRAY') {
        croak "CGI param array limit exceeded $#$deep for ",
                                            $class->join_name(@_)
                    if($#$deep+1 >= $class->max_array);

        for (0 .. $#$deep) {
            $class->_collapse_hash($deep->[$_], $flat, @_, $_) 
                                                if defined $deep->[$_];
        }
    } else {
        croak "Unknown reference type for ",$class->join_name(@_),":",ref $deep;
    }
}

}

1;
__END__

=pod 

=head1 NAME

CGI::Expand - convert flat hash to nested data using TT2's dot convention

=head1 SYNOPSIS

    use CGI::Expand ();
    use CGI; # or Apache::Request, etc.

    $args = CGI::Expand->expand_cgi( CGI->new('a.0=3&a.2=4&b.c.0=x') );

Or, as an imported function for convenience:

    use CGI::Expand;
    use CGI; # or Apache::Request, etc.

    $args = expand_cgi( CGI->new('a.0=3&a.2=4&b.c.0=x') );
    # $args = { a => [3,undef,4], b => { c => ['x'] }, }

    # Or to catch exceptions:
    eval {
        $args = expand_cgi( CGI->new('a.0=3&a.2=4&b.c.0=x') );
    } or log_and_exit( $@ );

    #-----
    use CGI::Expand qw(expand_hash);

    $args = expand_hash({'a.0'=>77}); # $args = { a => [ 77 ] }

=head1 DESCRIPTION

Converts a CGI query into structured data using a dotted name
convention similar to TT2.  

C<expand_cgi> works with CGI.pm, Apache::Request or anything with an
appropriate "param" method.  Or you can use C<expand_hash> directly.

If you prefer to use a different flattening convention then CGI::Expand
can be subclassed.

=head1 MOTIVATION

The Common Gateway Interface restricts parameters to name=value pairs,
but often we'd like to use more structured data.  This module
uses a name encoding convention to rebuild a hash of hashes, arrays
and values.  Arrays can either be indexed explicitly or from CGI's 
multi-valued parameter handling.

The generic nature of this process means that the core components
of your system can remain CGI ignorant and operate on structured data.
Better for modularity, better for testing.

=head1 DOT CONVENTION

The key-value pair "a.b.1=hi" expands to the perl structure:

  { a => { b => [ undef, "hi" ] }

The key ("a.b.1") specifies the location at which the value
("hi") is stored.  The key is split on '.' characters, the
first segment ("a") is a key in the top level hash, 
subsequent segments may be keys in sub-hashes or 
indices in sub-arrays.  Integer segments are treated
as array indices, others as hash keys.

Array size is limited to 100 by default.  The limit can be altered
by subclassing or using the deprecated $Max_Array package variable.
See below.

The backslash '\' escapes the next character in cgi parameter names
allowing '.' , '\' and digits in hash keys.  The escaping
'\' is removed.  Values are not altered.

=head2 Key-Value Examples

  # HoHoL
  a.b.1=hi ---> { a => { b => [ undef, "hi" ] }

  # HoLoH
  a.1.b=hi ---> { a => [ undef, { b => "hi" } ] }

  # top level always a hash
  9.0=hi   ---> { "9" => [ "hi" ] }

  # can backslash escape to treat digits hash as keys
  a.\0=hi     ---> { "a" => { 0 => "hi"} }

  # or to put . and \ literals in keys
  a\\b\.c=hi  ---  { 'a\\b\.c' => "hi" }

=head1 METHODS / FUNCTIONS

The routines listed below are all methods, but can be imported to be called as
functions.  In other words, you can call C<< CGI::Expand->expand_hash(...) >>
or you can import C<expand_hash> and then call C<expand_hash(...)> without
using method invocation syntax.

C<expand_cgi> is exported by default. C<expand_hash> and C<collapse_hash> are
exported upon request.

=over 4

=item expand_cgi

    my $deep_hash = expand_cgi ( $CGI_object_or_similar );

Takes a CGI object and returns a hashref for the expanded
data structure (or dies, see L<"EXCEPTIONS">).

Wrapper around expand_hash that uses the "param" method of 
the CGI object to collect the names and values.

Handles multivalued parameters as array refs
(although they can't be mixed with indexed arrays and
will have an undefined ordering).

    $query = 'a.0=3&a.2=4&b.c.0=x&c.0=2&c.1=3&d=&e=1&e=2';

    $args = expand_cgi( CGI->new($query) );

    # result:
    # $args = {
    #   a => [3,undef,4],
    #   b => { c => ['x'] },
    #   c => ['2','3'],
    #   d => '',
    #   e => ['1','2'], # order depends on CGI/etc
    # };

=item expand_hash

    my $deep_hash = expand_hash( $flat_hash );

Expands the keys of the parameter hash according
to the dot convention (or dies, see L<"EXCEPTIONS">).

    $args = expand_hash({ 'a.b.1' => [1,2] });
    # $args = { a => { b => [undef, [1,2] ] } }

=item collapse_hash

    my $flat_hash = collapse_hash( $deep_hash );

The inverse of expand_hash.  Converts the $deep_hash data structure
back into a flat hash.

    $flat = collapse_hash({ a => { b => [undef, [1,2] ] } });
    # $flat = { 'a.b.1.0' => 1, 'a.b.1.1' => 2 }

=back

=head1 EXCEPTIONS

B<WARNING>: The I<users> of your site can cause these exceptions
so you must decide how they are handled (possibly by letting
the process die).

=over 4

=item "CGI param array limit exceeded..."

If an array index exceeds the array limit (default: 100)
then an exception is thrown.  

=item "CGI param clash for..."

A cgi query like "a=1&a.b=1" would require the value of $args->{a}
to be both 1 and { b => 1 }.  Such type inconsistencies
are reported as exceptions.  (See test.pl for for examples)

=back

=head1 SUBCLASSING

Subclassing in now the preferred way to change the behaviour and
defaults.  (Previously package variables were used, see test.pl).

The methods which may be overridden by subclasses are separator,
max_array, split_name and join_name.

=over 4

=item max_array

    $subclass->max_Array;

The limit for the array size, defaults to 100.  The value 0 can be
used to disable the use of arrays, everthing is a hash key.

=item separator

    $subclass->separator;

Returns the separator characters used to split the keys of the flat hash.
The default is '.' but multiple characters are allowed.  The default
join will use the first character.

If there is no separator then '\' escaping does not occur.
This is for use with split_name and join_name below.

=item split_name

    my @segments = $subclass->split_name($name);

The split_name method must break $name in to key segments for the
nested data structure.  The default version just splits on the
separator characters with a bit of fiddling to handle escaping.

=item join_name

    my $name = $subclass->join_name(@segments);

The inverse of split_name, joins the segments back to the key for
the flat hash.  The default version uses the first character of the
string returned by the separator method.

=back

=head1 DEPRECATIONS

$CGI::Expand::Separator and $CGI::Expand::Max_Array are deprecated.
They still work for now but emit a warning (supressed with 
$CGI::Expand::BackCompat = 1)

Using the functions by their fully qualified names ceased to work
at around version 1.04.  They're now class methods so just replace
the last :: with ->.

=head1 LIMITATIONS

The top level is always a hash.  Consequently, any digit only names
will be keys in this hash rather than array indices.

Image inputs with name.x, name.y coordinates are ignored as they 
will class with the value for name.

=head1 TODO 

Thing about ways to keep $cgi and the expanded version in sync

Glob style parameters (with SCALAR, ARRAY and HASH slots)
would resolve the type clashes, probably no fun to use.
Look at using L<Template::Plugin::StringTree> to avoid path clashes

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Rollup> - Replaces CGI.pm completely, no list ordering.

=item *

L<CGI::State> - Tied to CGI.pm, unclear error checking

=item *

L<Template::Plugin::StringTree>

=item *

L<Hash::Flatten> - Pick your delimiters

=item *

http://template-toolkit.org/pipermail/templates/2002-January/002368.html

=item *

There's a tiny and beautiful reduce solution somewhere on perlmonks.

=back

=head1 AUTHOR

Brad Bowman E<lt>cgi-expand@bereft.netE<gt>

Pod corrections: Ricardo Signes

=head1 COPYRIGHT

Copyright (C) 2004-2013, Brad Bowman.

=head1 LICENSE

CGI::Expand is free software; you can redistribute it and/or modify it under
the terms of either:

a) the L<GNU General Public License|perlgpl> as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

b) the L<"Artistic License"|perlartistic> which comes with Perl.

For more details, see the full text of the licenses at
<http://www.perlfoundation.org/artistic_license_1_0>,
and <http://www.gnu.org/licenses/gpl-1.0.html>.

=cut
