package Data::SearchReplace;

use 5.006;
use strict;
#use warnings;
#use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ( 'sr' );

our $VERSION = '1.02';

# CVS stuff
our $date = '$Date: 2007/04/26 09:37:11 $';
our $author = '$Author: steve $';
our $version = '$Revision: 1.02 $';

sub new { bless $_[1] || {}, $_[0] }

{
  my $_counter = 0;
  sub sr {
      my $class = _is_package($_[0]) ? shift : Data::SearchReplace->new();

      # we reset our counter if the caller doesn't come from us... 
      # if you decide to override the private functions _array and _hash 
      # in your own modules you might want to rethink this...
      $_counter = 0 if ((caller())[0] ne 'Data::SearchReplace');

      my $attrib = defined($_[1]) ? shift : {};
      my $var = shift;

      # what action are we taking?  
      #  (input to this function overrides class values)
      my $action = 'SEARCH';
         $action = 'REGEX' if (defined $attrib->{REGEX} && 
			       length($attrib->{REGEX}) );
         $action = 'FUNCT' if (defined $attrib->{CODE}  &&
			       length($attrib->{CODE})  );

      # did they setup their vars in class?
        $attrib->{$_} ||= $class->{$_} || ''
		  for (qw(SEARCH REPLACE REGEX CODE));
	
      if (ref($var) eq 'HASH') {
         _hash($class, $attrib, $var);
      }elsif (ref($var) eq 'ARRAY') {
         _array($class, $attrib, $var);
      }elsif (ref($var) eq 'SCALAR') {
	 if ($action eq 'SEARCH') {
            ++$_counter if ($$var =~ s/$attrib->{SEARCH}/$attrib->{REPLACE}/g);
	 }elsif ($action eq 'REGEX') {
	    eval '++$_counter if ($$var =~ '.$attrib->{REGEX}.')'; 
		 warn $@ if $@;
	 }elsif ($action eq 'FUNCT') {
	    my $oldvar = $var;
	    $$var = $attrib->{CODE}->($$oldvar);
	    ++$_counter unless $$oldvar eq $$var;
	 }
      }elsif (ref($var)){
	 return; # something we can't handle
      }

  return $_counter;
  }
}

sub _hash { sr($_[0], $_[1], ref($_[2]->{$_}) ? $_[2]->{$_} : \$_[2]->{$_}) for (keys %{$_[2]}) }
                                                                                
sub _array { sr($_[0], $_[1], ref($_) ? $_ : \$_) for (@{$_[2]}) }

sub _is_package {
    return unless (defined($_[0]) && ref($_[0]));

    for (qw(SCALAR HASH ARRAY REF GLOB CODE)) {
	next unless (ref($_[0]) eq $_);
	return;
    }

return 1; # made it through the tests so we assume it's a package
}

1;
__END__

=head1 NAME

Data::SearchReplace - perl extention for searching and replacing
entries in complex data structures

=head1 SYNOPSIS

  use Data::SearchReplace ('sr');
  sr({ SEARCH => 'searching', REPLACE => 'replacing'}, \$complex_var);

  # or OO

  use Data::SearchReplace;
  $sr = Data::SearchReplace->new({ SEARCH => 'search for this',
				   REPLACE => 'replace with this' });

  $sr->sr(\$complex_var);
  $sr->sr(\$new_complex_var);

  # if you want more control over your search/replace pattern you
  #  can pass an entire regex instead complete with attributes

  sr({ REGEX => 's/nice/great/gi' }, \$complex_var);

  # you can even use a subroutine if you'd like
  #  the input variable is the value and the return sets the new
  #  value.

  sr({ CODE => sub { uc($_[0]) } }, \$complex_var);

  # now sr has a return value for the number of variables it changed
  my $ret = sr({ SEARCH => 'searching', REPLACE => 'replacing'}, \$complex_var);

  # returns the number of variables it matched

=head1 ABSTRACT

Data::SearchReplace - run a regex on all values within a complex 
data structure.

 use Data::SearchReplace qw(sr);
 sr({SEARCH => 'find', REPLACE => 'replace'}, \@data);
 sr({REGEX  => 's/find/replace/g'}, \%data);
 sr({CODE   => sub {uc($_[0])} }, \@data);
 my $matched = sr({REGEX  => 's/find/replace/g'}, \%data);

=head1 DESCRIPTION

Data::SearchReplace is used when you want to run a regex on all the entries of
a complex data structure.

=head2 COMPLETE EXAMPLE

 use Data::SearchReplace qw(sr);
 %VAR = ( example => { drink => [ qw(wine beer kool-aid) ],
                       food  => 'and lots of it',
                       dessert => { strawberry => 'shortcake and cream',
                                    liver      => 'not on my diet',
                                    ice_cream  => 'works for me'} },
          filler  => 'naturally you can put whatever you want here',
          test    => 'this should change too' );
                                                                                
 # we'll capitalize the first character and strip off any extra words
 my $matched = sr({ REGEX => 's/(\w+).*/ucfirst($1)/e' }, \%VAR);

 print "Hey my program ", $VAR{example}->{dessert}->{ice_cream}, "!\n",
       $VAR{test}, " should work for you too!\n",
       "btw it altered $matched variables in this example.\n";
 
=head2 EXPORT

sr - however none by default

=head1 CAVEATS

This doesn't work well for CODE (subroutines) or GLOB (typeglobs).  I'm not
entirely certain how one would even go about working on these.

Also you should never pass a reference to a reference to the routine.  In
other words something like this will NOT work:

 my $complex_var = { hello => [qw(world earth)] };

  sr({ SEARCH => 'world', REPLACE => 'planet' }, \$complex_var);

  just use...

  sr({ SEARCH => 'world', REPLACE => 'planet' }, $complex_var);

=head1 AUTHOR

Stephen D. Wells, E<lt>wells@cedarnet.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2007 (C) by Stephen D. Wells.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
