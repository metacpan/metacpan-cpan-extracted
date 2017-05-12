package Acme::Machi v1.00.1 { 
  
  use v5.16.2;
  use strict;
  use warnings;
  use IO::Dir;
  use File::Spec;
  use File::Basename;
  use Data::Dumper;
  use Cwd;
  use Carp;

  #import CPAN libs
  use namespace::autoclean;

  
=head1 NAME
  
Machi -  Awesome Machi here!

=head1 VERSION

Version v1.00.1

=cut

=head1 SYNOPSIS

Quick summary of what the module does.
Exactly a little code snippet.

    use Acme::Machi;

    my $loli = Acme::Machi->new( $name );             # Give birth to a person; accept an optional argument to set the person's name.

    $loli->named( $name );                            # Name the person. Default name is 'Machi'.

    $loli->name();                                    # Get person's name.

    $loli->have_the_habit_of( $habit );               # Person gets into certain searching habit.

    $loli->habit();                                   # Get one's searching habit.

    $loli->learning( @words );                        # Teach the person saying something endearing.

    $loli->affectionate( $file_handle );              # The person shall randomly tell about what you previously teached her/him to say.

    $loli->search_file_from( $target, $dir, $RESP );  # Search file/dir from certain spcified directory using BFS or DFS.
                                                      # The third argument $RESP representing 'Responsible', which means she/he will 
                                                      # stop searching and come back in a moment when finding the target one.
                                                      # In case $RESP is in zero state or $RESP is set but the target isn't found, 
                                                      # she/he will finally print out the tree-like structure of your file system
                                                      # before coming back in despair.
    
  
=head1 METHODS

=head2 new

        Create a Machi-type instance.

=cut
  sub new {
    (ref $_[0]) &&  croak "Oops! Cannot use instance method to construt an object!";
    bless {
      Name => $_[1] // "Machi",
      Words => ["I am starving!!"], # In general, creatures always know how to express their hunger.
      SRCH_Habit => 'BFS',
    }, $_[0];
  }

=head2 named

        Assign a new value to scalar-type instance variable, 'Name', in the object.
        Return: value of assignment.

=cut
  sub named {
    (ref $_[0]) ||  croak "Oops! Cannot use class method setting the object!";
    $_[0]{Name} = $_[1];
  }

=head2 name

        Return: person's name.

=cut
  sub name {
    $_[0]{Name};
  }


=head2 have_the_habit_of

        Assign a new searching habit to scalar-type instance variable, 'SRCH_Habit'.
        Only strings 'BFS' and 'DFS' are valid, setting the others will be ignored.
        Return: value of assignment.

=cut
  sub have_the_habit_of {
    (ref $_[0]) ||  croak "Oops! Cannot use class method setting the object!";
    $_[0]{SRCH_Habit} = $_[1] if($_[1] =~ m/([DB]FS)/);
  }

=head2 habit

        Return: person's searching habit.

=cut
  sub habit {
    $_[0]{SRCH_Habit};
  }


=head2 learning

        Append a list of words to array-type instance variable, 'Words', in the object.
        Return: how many words have she/he learnt.

=cut
  sub learning {
    (ref $_[0]) ||  croak "Oops! Cannot use class method setting the object!";
    unshift (@{$_[0]{Words}}, @_[1 .. $#_]);
  }
       
=head2 affectionate

        Randomly output one of predefined words to FILE_HANDLE, which default of is STDOUT.
        Return: 1 if no problems while calling this method.

=cut
  sub affectionate {
    (ref $_[0]) ||  croak "Oops! Cannot call affectionate() using class method!";
    my $words_list = $_[0]{Words};
    ($_[1] // *STDOUT)->print( $_[0]->name(),": ", $words_list->[int(rand($#$words_list))], "\n");
  }
  
       
=head2 search_file_from

        Using BFS or DFS to search the target from certain directory.
        Return: a two-element list: 
                  the first element is boolean value denoting whether the target was found or not.
                  the second element is the result string outputed from the core module, Data::Dumper.
                    You may get to know files distribution even better after printing the string.

=cut
  sub search_file_from {
    ref $_[0] ||  croak "Oops! Cannot ask non-human to search!";
    my ($target, $dir, $RESP) = @_[1,2,3];
    my $obj = File::Spec->catfile(getcwd, $target);
    my $s_dir = File::Spec->catfile(getcwd, $dir);
    my $push_front_back = ($_[0]->habit() eq 'DFS')? 
      sub {
        unshift(@{$_[0]}, $_[1]);
      }
      : sub {
        push(@{$_[0]}, $_[1]);
      };

    my $data = {};
    my @queue = ( [$s_dir, $data] );
    my ($elm, $np, $nd, $key, $found);
    ($obj eq $s_dir) && ($found = 1);
    return 1 if $RESP;
    while($elm = shift @queue){;
      ($np, $nd) = @$elm;
      $key = basename($np);
      $nd->{$key} = (-l $np or -f _)? undef : +{};
      if (ref $nd->{$key}) {;
        my $dh = IO::Dir->new("$np");
        my $npp;
        foreach ($dh->read()) {;
          $npp = File::Spec->catfile($np,$_);
          ($obj eq $npp) && ($found = 1);
          return 1 if $RESP;
          (m/\A\.{1,2}?\z/aa) || $push_front_back->(\@queue, [ $npp, $nd->{$key} ]);
        }
      }
    }
    print Data::Dumper->Dump([\$data],[qw% *data %]);
    $found;
  }
 

=head1 AUTHOR

Machi Amayadori, C<< <Eosin at Syaro.Cafe> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-machi at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Machi>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Machi


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Machi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Machi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Machi>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Machi/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Machi Amayadori.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install


After installing, you can find documentation for this module with the
perldoc command.

    perldoc Acme::Machi

=cut
}
'END_MACHI'; # End of Acme::Machi
