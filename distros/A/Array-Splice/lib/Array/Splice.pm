package Array::Splice;

use 5.006;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
   splice_aliases push_aliases unshift_aliases	
);

our $VERSION = '0.04';

bootstrap Array::Splice $VERSION;

sub splice_aliases (\@$$@) {
    my $array = shift;
    if ( my $tied = tied @$array ) {
	return $tied->SPLICE_ALIASES(@_);
    }
    _splice($array,@_);
}

sub push_aliases (\@@) {
    splice @_, 1, 0, scalar @{$_[0]}, 0;
    &splice_aliases(@_);
    return unless defined wantarray;
    scalar @{$_[0]};
}

sub unshift_aliases (\@@) {
    splice @_, 1, 0, 0, 0;
    &splice_aliases(@_);
    return unless defined wantarray;
    scalar @{$_[0]};
}

1;
__END__

=head1 NAME

Array::Splice - Splice aliases into arrays

=head1 SYNOPSIS

  use Array::Splice qw( splice_aliases push_aliases );

  my @a = qw( foo bar );
  my $x = 'baz';
  splice_aliases @a,1,0,$x;
  $x = 'zoop'; # Changes $a[1]
  print "@a\n"; # foo zoop bar

  sub wrapped_foo {
    push_aliases my @args => @_;  # Copy @_
    some_wrapper(sub { foo @args }); # &foo called with orginal arguments
  }    

=head1 DESCRIPTION

This module does splicing of arrays for real.  That is does exactly
the same as the builtin C<splice> function except that the inserted
elements are existing scalar values not copies of them.

One possible use of this is to copy the @_ array but I'm sure
that there are others.

This module does not export anything by default.

=head2 EXPORTS

=over

=item splice_aliases ARRAY,OFFSET,LENGTH,LIST

Exactly like the builtin C<splice> except that the scalar values that
are the elements of LIST get spliced directly into ARRAY rather being
copied.  Unlike the builtin C<splice> OFFSET and LENGTH are not
optional since if you are not giving LIST then C<splice_aliases> is
just exactly the same as C<splice>.

This is unlikely to be useful for tied arrays but for the sake of
uniformity, splice_aliases() tries to call a SPLICE_ALIASES() method
on the object to which the array is tied.

=item push_aliases ARRAY, LIST

A wrapper for C<splice_aliases> that emulates the builtin C<push>
except that LIST gets spliced directly into ARRAY rather being copied.

=item unshift_aliases ARRAY, LIST

A wrapper for C<splice_aliases> that emulates the builtin C<unshift>
except that LIST gets spliced directly into ARRAY rather being copied.

=back 

=head1 KNOWN ISSUES

As of Perl 5.8.9 L<Data::Alias> works on all platforms. That largely
renders this module obsolescent. On the other hand this module does
not employ any of the deep black magic that L<Data::Alias> uses.

The value of C<$[> is ignored because it works differently in 5.10
from it did previously and since nobody should be using it anyhow
there's no point making an effort to support it.

=head1 AUTHOR

Brian McCauley, E<lt>nobull@cpan.orgE<gt>

=head1 SEE ALSO

L<perlfunc/splice>, L<Data::Alias>.

=cut
