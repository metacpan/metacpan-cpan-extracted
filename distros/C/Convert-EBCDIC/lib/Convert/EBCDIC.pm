package Convert::EBCDIC;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK $ccsid819 $ccsid1047);


require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
             ascii2ebcdic ebcdic2ascii
);

$VERSION = '0.06';

$ccsid819 = 
'\000\001\002\003\234\011\206\177\227\215\216\013\014\015\016\017' .
'\020\021\022\023\235\205\010\207\030\031\222\217\034\035\036\037' .
'\200\201\202\203\204\012\027\033\210\211\212\213\214\005\006\007' .
'\220\221\026\223\224\225\226\004\230\231\232\233\024\025\236\032' .
'\040\240\342\344\340\341\343\345\347\361\242\056\074\050\053\174' .
'\046\351\352\353\350\355\356\357\354\337\041\044\052\051\073\254' .
'\055\057\302\304\300\301\303\305\307\321\246\054\045\137\076\077' .
'\370\311\312\313\310\315\316\317\314\140\072\043\100\047\075\042' .
'\330\141\142\143\144\145\146\147\150\151\253\273\360\375\376\261' .
'\260\152\153\154\155\156\157\160\161\162\252\272\346\270\306\244' .
'\265\176\163\164\165\166\167\170\171\172\241\277\320\335\336\256' .
'\136\243\245\267\251\247\266\274\275\276\133\135\257\250\264\327' .
'\173\101\102\103\104\105\106\107\110\111\255\364\366\362\363\365' .
'\175\112\113\114\115\116\117\120\121\122\271\373\374\371\372\377' .
'\134\367\123\124\125\126\127\130\131\132\262\324\326\322\323\325' .
'\060\061\062\063\064\065\066\067\070\071\263\333\334\331\332\237' ;

$ccsid1047 = 
'\000\001\002\003\234\011\206\177\227\215\216\013\014\015\016\017' .
'\020\021\022\023\235\012\010\207\030\031\222\217\034\035\036\037' .
'\200\201\202\203\204\205\027\033\210\211\212\213\214\005\006\007' .
'\220\221\026\223\224\225\226\004\230\231\232\233\024\025\236\032' .
'\040\240\342\344\340\341\343\345\347\361\242\056\074\050\053\174' .
'\046\351\352\353\350\355\356\357\354\337\041\044\052\051\073\136' .
'\055\057\302\304\300\301\303\305\307\321\246\054\045\137\076\077' .
'\370\311\312\313\310\315\316\317\314\140\072\043\100\047\075\042' .
'\330\141\142\143\144\145\146\147\150\151\253\273\360\375\376\261' .
'\260\152\153\154\155\156\157\160\161\162\252\272\346\270\306\244' .
'\265\176\163\164\165\166\167\170\171\172\241\277\320\133\336\256' .
'\254\243\245\267\251\247\266\274\275\276\335\250\257\135\264\327' .
'\173\101\102\103\104\105\106\107\110\111\255\364\366\362\363\365' .
'\175\112\113\114\115\116\117\120\121\122\271\373\374\371\372\377' .
'\134\367\123\124\125\126\127\130\131\132\262\324\326\322\323\325' .
'\060\061\062\063\064\065\066\067\070\071\263\333\334\331\332\237' ;


my $default = ($^O eq 'os390') ? $ccsid1047 : $ccsid819;

# Preloaded methods go here.


sub ebcdic2ascii {
    my $e = shift;

    eval '$e =~ tr/\000-\377/' . $default . '/';

    return $e;
}

sub ascii2ebcdic {
    my $a = shift;

    eval '$a =~ tr/' . $default . '/\000-\377/';

    return $a;
}

sub new {
    my $class = shift;
    my $lang  = shift || $default;
    my $self  = { };
    $$self{a2e} = eval 'sub { my $a = shift; $a =~ tr/' . $lang . '/\000-\377/; return $a; }';
    $$self{e2a} = eval 'sub { my $e = shift; $e =~ tr/\000-\377/' . $lang . '/; return $e; }';
    bless $self, $class;

    return $self;
}

sub toascii {
    my $self = shift;
    my $s = shift;

    return &{$$self{e2a}}($s);
}

sub toebcdic {
    my $self = shift;
    my $s = shift;

    return &{$$self{a2e}}($s);
}


1;
__END__

=head1 NAME

Convert::EBCDIC, ascii2ebcdic, ebcdic2ascii - Perl module for string conversion between EBCDIC and ASCII

=head1 SYNOPSIS

  use Convert::EBCDIC;
  $ascii_string = ebcdic2ascii($ebcdic_string);
  $ebcdic_string = ascci2ebcdic($ascii_string);

  $translator = new Convert::EBCDIC;
  $translator = new Convert::EBCDIC($table);
  $ascii_string = $translator->toascii($ebcdic_string);
  $ebcdic_string = $translator->toebcdic($ascii_string);

  $Convert::EBCDIC::ccsid819

=head1 DESCRIPTION

This module can be used to import then functions ascii2ebcdic and/or
ebcdic2ascii or in an Object mode.

Exported Functions:

=over 4

=item ascii2ebcdic()

takes as the first argument a EBCDIC string that is to be
converted to ASCII using default converion table.

=item ebcdic2ascii()

takes as the first argument a ASCII string that is to be
converted to EBCDIC using default converion table.

=back

Object methods:

=over 4

=item new()

creates a new translator object.
Will take an optional argument being a 256 character conversion table.

=item toascii()

takes and ASCII string and return and EBCDIC string.

=item toebcdic()

takes and EBCDIC string and return and ASCII string.

=back

Translation tables:

=over 4

=item $Convert::EBCDIC::ccsid819

Character Code Set ID 00819.
This is the default on most systems.

=item $Convert::EBCDIC::ccsid1047

Character Code Set ID 01047.
This is the default on OS390.

=back

=head1 PORTABILITY

This module should work on any system with Perl 5.
Tested under SPARC Solaris, OS390, HP-UX AS400/OS400 RISC.

=head1 AUTHOR

Chris Leach E<lt>leachcj@bp.comE<gt>.

=cut
