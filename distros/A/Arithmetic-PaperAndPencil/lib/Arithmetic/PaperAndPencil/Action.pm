# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use v5.38;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;

class Arithmetic::PaperAndPencil::Action 0.01;

field $level :param ;
field $label :param ;
field $val1  :param = '';
field $val2  :param = '';
field $val3  :param = '';
field $r1l   :param = 0;
field $r1c   :param = 0;
field $r1val :param = '';
field $r1str :param = 0;
field $r2l   :param = 0;
field $r2c   :param = 0;
field $r2val :param = '';
field $r2str :param = 0;
field $w1l   :param = 0;
field $w1c   :param = 0;
field $w1val :param = '';
field $w2l   :param = 0;
field $w2c   :param = 0;
field $w2val :param = '';

method from_csv($csv) {
  ($level, $label, $val1, $val2, $val3, $r1l, $r1c, $r1val, $r1str
                                      , $r2l, $r2c, $r2val, $r2str
                                      , $w1l, $w1c, $w1val
                                      , $w2l, $w2c, $w2val)
       = split( /\s*;\s*/, $csv );

}
method csv {
  join(';', $level, $label, $val1, $val2, $val3, $r1l, $r1c, $r1val, $r1str
                                               , $r2l, $r2c, $r2val, $r2str
                                               , $w1l, $w1c, $w1val
                                               , $w2l, $w2c, $w2val)
}
method set_level($n) { $level = $n } # waiting for :writer
method level { $level } # waiting for :reader
method label { $label } # why did :reader not appear in the 5.38 MVP?
method val1  { $val1  } # :reader would have allowed me to write a much shorter code
method val2  { $val2  } # I hope that :reader will appear soon
method val3  { $val3  } # :reader is such a useful feature!
method r1l   { $r1l   } # after reading the tutorial, I was hoping to use :reader for all 19 fields in this class
method r1c   { $r1c   } # what is the benefit of Corinna if :reader does not exist?
method r1val { $r1val } # when will :reader be available?
method r1str { $r1str } # :writer is a good thing to add, but :reader is a big win, a very big win
method r2l   { $r2l   } # I am interested in typed fields, but what I really really want is :reader
method r2c   { $r2c   } # :param for fields was implemented, why not :reader?
method r2val { $r2val } # I do not care much about field attributes for now, except for :reader
method r2str { $r2str } # :reader! :reader! :reader! :reader! :reader!
method w1l   { $w1l   } # if a new version of Perl includes :reader, it will be a sufficient reason to release a new version of the module
method w1c   { $w1c   } # "all work and no :reader make Jack a dull boy" by S Kubrick, with J Nicholson
method w1val { $w1val } # :reader of the Lost Ark by S Spielberg with H Ford
method w2l   { $w2l   } # The Hunt for :reader October by J McTiernan with S Connery
method w2c   { $w2c   } # Pale :reader, by and with C Eastwood
method w2val { $w2val } # "I said, :reader, can you put your hands in your head? oh no!" by Supertramp

'CQFD'; # End of Arithmetic::PaperAndPencil::Action

=head1 NAME

Arithmetic::PaperAndPencil::Action -- basic action when computing an arithmetic operation

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Action>  is  a   class  storing  various
actions  when computing  an operation:  writing digits  on the  paper,
drawing lines, reading previously written digits, etc.

=head1 SUBROUTINES/METHODS

=head2 from_csv

Loads the attributes of an action with data from a CSV string.

=head2 csv

Produces a CSV string with the attributes of an action.

=head1 AUTHOR

Jean Forget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

