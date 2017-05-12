package DBIx::bind_param_inline;

use 5.008008;
use warnings;

our $VERSION = '0.03';

use Carp;


sub prepare_inline($$;$){
    my $dbh = shift;
    my $SQL = shift;
    my @EPs;
    my $attrs = shift || {};
    while($SQL =~ /[?]/){
        my $explicit_placeholder;
        push @EPs, \$explicit_placeholder;    
        $SQL =~ s/[?]/\$___explicit__wedfgh__placeholder___/;
    };
    my $pkg = caller();
    my $EPindex = 0;
    my @placeholder_refs = map {
        $_ eq '___explicit__wedfgh__placeholder___'
        ?
        $EPs[$EPindex++]
        :
        \${"$pkg\::$_"}
    } ($SQL =~ /\$(\w+)/g) ;
    $SQL =~ s/\$(\w+)/ ? /g ;
    my $sth = (
                             defined($attrs)
                                     ?
        $dbh->prepare($SQL,$attrs)   :   $dbh->prepare($SQL)
    );
   
    bless [$sth, \@EPs, @placeholder_refs]
};

sub import{
    *{caller().'::prepare_inline'} = \&prepare_inline
};

sub execute{
    my $objref = shift;
    my @obj = @$objref; # a copy, so we can shift from it nondestructively
    my $sth = shift @obj;
    my $EPref = shift @obj;
    @$EPref == @_ or
     croak "Wrong number of explicit placeholders in execute of inline-bound statement handle: ".
        "need ".@$EPref." but got ".@_." parameters" ;
    for (@$EPref){
        $$_ = shift;  # load explicit placeholders
    };
    my $pnum = 1;
    while (@obj){
        $sth->bind_param($pnum++, ${shift @obj});
    };
    $sth->execute;

};

our $AUTOLOAD;

sub AUTOLOAD{
    my $name = $AUTOLOAD;
    # uncomment the next line to see memoized autoloading in action
    # warn "AUTOLOADING $name";
    $name =~ s/.*://;   # strip fully-qualified portion
    eval 'sub '.$name.'{
        my $objref = shift;
        my $sth = $objref->[0];
        $sth->'.$name.'(@_)
    }';

    goto &$name
}

sub DESTROY{
    # autoloading this is poor form, considering it
    # is conceivable that we might have other references to the $sth
    @{$_[0]} = ();
};

1;
__END__

=head1 NAME

DBIx::bind_param_inline - list variables in $dbh->prepare method instead of calling $sth->bind_param

=head1 SYNOPSIS

Syntactic sugar allowing implied statement parameters, like in SQR.

  use DBI;
  ...
  use DBIx::bind_param_inline;
  our ($foo, $bar, $baz); # MUST be "our" not "my"
  # qq style -- escape rods of Asclepius
  my $sth = prepare_inline($dbh, <<SQL);
  SELECT * from mytable WHERE foo = \$foo AND bar = \$bar AND baz = \$baz
  SQL
  # q style -- noninterpolative
  my $sth2 = prepare_inline($dbh, <<'SQL');
  INSERT INTO mytable (foo, bar, baz) VALUES ($foo, $bar, ? )
  SQL
  ...
  $sth->execute(); #placeholders get bound for you
  $sth2->execute($something->compute_baz); # regular placeholders still work!
  

=head1 DESCRIPTION

prepare_inline identifies inlined variables and replaces them
with C<?> placeholders before calling the normal prepare.  The
resulting statement handle has some additional information in it
so bind_param will be called when it is executed, and all other
methods called on it fall through to the non-extended statement handle.

The important thing is, you get to name your variables directly within
your SQL, which means less counting question marks and more freedom
to change the order of things.

So we get to trade the tricky action-at-a-distance problem of placeholder order
for the more manageable action-at-a-distance problem of package variables.

=head2 EXPORT

C<prepare_inline>

=head1 HISTORY

=over 8

=item 0.03  2009 April 29

Changed from NullP to SQLite for testing purposes, actually creating a table and
accessing it with this new syntax.  This tool actually works now.


=back

=head2 BUGS

Doesn't work with lexical C<my> variables.  I believe this could be repaired by walking the pad instead of or in addition to looking at C<caller()."::$name">.  Patches welcome. 


=head1 SEE ALSO

L<http://perlbuzz.com/2008/12/database-access-in-perl-6-is-coming-along-nicely.html>

=head1 AUTHOR

David Nicol E<lt>davidnico@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by David Nicol

your choice of GPL 2, GPL 3, or AL.  Did I actually reserve any rights for myself?
Yes, I did.  You're not allowed to lie and say you wrote it.


=cut
