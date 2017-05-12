use warnings;
use strict;

package Data::SExpression;

our $VERSION = '0.41';

=head1 NAME

Data::SExpression -- Parse Lisp S-Expressions into perl data
structures.

=head1 SYNOPSIS

    use Data::SExpression;

    my $ds = Data::SExpression->new;

    $ds->read("(foo bar baz)");          # [\*::foo, \*::bar, \*::baz]

    my @sexps;
    my $sexp;
    while(1) {
        eval {
            ($sexp, $text) = $ds->read($text);
        };
        last if $@;
        push @sexps, $sexp;
    }

    $ds = Data::SExpression->new({fold_alists => 1});

    $ds->read("((top . 4) (left . 5))");  # {\*::top => 4, \*::left => 5}

=cut

use base qw(Class::Accessor::Fast Exporter);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(parser symbol_case use_symbol_class fold_dashes fold_lists fold_alists));

our @EXPORT_OK = qw(cons consp scalarp);

use Symbol;
use Data::SExpression::Cons;
use Data::SExpression::Parser;
use Data::SExpression::Symbol;
use Carp qw(croak);


sub cons ($$);
sub consp ($);
sub scalarp ($);


=head1 METHODS

=head2 new [\%args]

Returns a new Data::SExpression object. Possibly args are:

=over 4

=item fold_lists

If true, fold lisp lists (e.g. "(1 2 3)") into Perl listrefs, e.g. [1, 2, 3]

Defaults to true.

=item fold_alists

If true, fold lisp alists into perl hashrefs. e.g.

C<"((fg . red) (bg . black) (weight . bold))">

would become

    {
        \*fg       => \*red,
        \*bg       => \*black,
        \*weight   => \*bold
    }

Alists will only be folded if they are a list of conses, all of which
have scalars as both their C<car> and C<cdr> (See
L<Data::SExpression::Cons/scalarp>)

This option implies L</fold_lists>

Defaults to false.

=item symbol_case

Can be C<"up">, C<"down">, or C<undef>, to fold symbol case to
uppercase, lowercase, or to leave as-is.

Defaults to leaving symbols alone.

=item use_symbol_class

If true, symbols become instances of L<Data::SExpression::Symbol>
instead of globrefs.

Defaults to false

=item fold_dashes

If true, dash characters in symbols (C<->) will be folded to the more
perlish underscore, C<_>. This is especially convenient when symbols
are being converted to globrefs.

Defaults to false.

=back

=cut

sub new {
    my $class = shift;
    my $args  = shift || {};

    my $parser = Data::SExpression::Parser->new;

    $args->{fold_lists} = 1 if $args->{fold_alists};

    my $self = {
        fold_lists  => 1,
        fold_alists => 0,
        symbol_case => 0,
        use_symbol_class => 0,
        fold_dashes => 0,
        %$args,
        parser      => $parser,
       };
    
    bless($self, $class);

    $parser->set_handler($self);

    return $self;
}

=head2 read STRING

Parse an SExpression from the start of STRING, or die if the parse
fails.

In scalar context, returns the expression parsed as a perl data
structure; In list context, also return the part of STRING left
unparsed. This means you can read all the expressions in a string
with:

    my @sexps;
    my $sexp;
    while(1) {
        eval {
            ($sexp, $text) = $ds->read($text);
        };
        last if $@;
        push @sexps, $sexp;
    }


This method converts Lisp SExpressions into perl data structures by
the following rules:

=over 4

=item Numbers and Strings become perl scalars

Lisp differentiates between the types; perl doesn't.

=item Symbols become globrefs in main::

This means they become something like \*main::foo, or \*::foo for
short. To convert from a string to a symbol, you can use
L<Symbol/qualify_to_ref>, with C<"main"> as the package.

But see L</use_symbol_class> if you'd prefer to get back objects.

=item Conses become Data::SExpression::Cons objects

See L<Data::SExpression::Cons> for how to deal with these. See also
the C<fold_lists> and C<fold_alists> arguments to L</new>.

If C<fold_lists> is false, the Lisp empty list C<()> becomes the perl
C<undef>. With C<fold_lists>, it turns into C<[]> as you would expect.

=item Quotation is parsed as in scheme

This means that "'foo" is parsed like "(quote foo)", "`foo" like
"(quasiquote foo)", and ",foo" like "(unquote foo)".

=back

=cut

sub read {
    my $self = shift;
    my $string = shift;

    $self->get_parser->set_input($string);
    
    my $value = $self->get_parser->parse;

    $value = $self->_fold_lists($value) if $self->get_fold_lists;
    $value = $self->_fold_alists($value) if $self->get_fold_alists;

    my $unparsed = $self->get_parser->unparsed_input;

    return wantarray ? ($value, $unparsed) : $value;
}

sub _fold_lists {
    my $self = shift;
    my $thing = shift;

    if(!defined($thing)) {
        $thing = [];
    } if(consp $thing) {
        # Recursively fold the car
        $thing->set_car($self->_fold_lists($thing->car));

        # Unroll the cdr-folding, since recursing over really long
        # lists will net us warnings
        if(consp $thing->cdr || !defined($thing->cdr)) {
            my $cdr = $thing->cdr;
            my $array;
            while(consp $cdr) {
                $cdr = $cdr->cdr;
            }
            if(defined($cdr)) {
                # We hit the end of the chain, and found something other
                # than nil. This is an improper list.
                return $thing;
            }
            
            $array = [$thing->car];
            $cdr = $thing->cdr;
            while(defined $cdr) {
                push @$array, $self->_fold_lists($cdr->car);
                $cdr = $cdr->cdr;
            }
            return $array;
        }
    }

    return $thing;
}

sub for_all(&@) {$_[0]() or return 0 foreach (@_[1..$#_]); 1;}

sub _fold_alists {
    my $self = shift;
    my $thing = shift;

    #Assume $thing has already been list-folded

    if(ref($thing) eq "ARRAY") {
        if( for_all {consp $_ && scalarp $_->car && scalarp $_->cdr} @{$thing} ) {
            return {map {$_->car => $_ -> cdr} @{$thing}};
        } else {
            return [map {$self->_fold_alists($_)} @{$thing}];
        }
    } elsif(consp $thing) {
        return cons($self->_fold_alists($thing->car),
                    $self->_fold_alists($thing->cdr));
    } else {
        return $thing;
    }
}

=head1 LISP-LIKE CONVENIENCE FUNCTIONS

These are all generic methods to make operating on cons's easier in
perl. You can ask for any of these in the export list, e.g.

    use Data::SExpression qw(cons consp);

=head2 cons CAR CDR

Convenience method for Data::SExpression::Cons->new(CAR, CDR)

=cut

sub cons ($$) {
    my ($car, $cdr) = @_;
    return Data::SExpression::Cons->new($car, $cdr);
}

=head2 consp THING

Returns true iff C<THING> is a reference to a
C<Data::SExpression::Cons>

=cut

sub consp ($) {
    my $thing = shift;
    return ref($thing) && UNIVERSAL::isa($thing, 'Data::SExpression::Cons');
}

=head2 scalarp THING

Returns true iff C<THING> is a scalar -- i.e. a string, symbol, or
number

=cut

sub scalarp ($) {
    my $thing = shift;
    return !ref($thing) ||
            ref($thing) eq "GLOB" ||
            ref($thing) eq 'Data::SExpression::Symbol';;
}

=head1 Data::SExpression::Parser callbacks

These are for internal use only, and are used to generate the data
structures returned by L</read>. 

=head2 new_cons CAR CDR

Returns a new cons with the given CAR and CDR

=cut

sub new_cons {
    my ($self, $car, $cdr) = @_;
    return cons($car, $cdr);
}

=head2 new_symbol NAME

Returns a new symbol with the given name

=cut

sub new_symbol {
    my ($self, $name) = @_;
    if($self->get_symbol_case eq 'up') {
        $name = uc $name;
    } elsif($self->get_symbol_case eq 'down') {
        $name = lc $name;
    }

    if($self->get_fold_dashes) {
        $name =~ tr/-/_/;
    }

    if($self->get_use_symbol_class) {
        return Data::SExpression::Symbol->new($name);
    } else {
        return Symbol::qualify_to_ref($name, 'main');
    }
}

=head2 new_string CONTENT

Returns a new string with the given raw content

=cut

sub new_string {
    my ($self, $content) = @_;

    $content =~ s/\\"/"/g;

    return $content;
}

=head1 BUGS

None known, but there are probably a few. Please reports bugs via
rt.cpan.org by sending mail to:

L<bug-Data-SExpression@rt.cpan.org>


=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;

