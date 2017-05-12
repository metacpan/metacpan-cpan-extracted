package Acme::Smirch; 
$VERSION = '0.91';

sub famous { $_[0] =~ /[A-Za-z0-9 ]/ }

sub smear {
  ($celebrity) = @_;
  open CLEAN, $celebrity or die "Could not smear the good name of $celebrity\n";
  undef $/; $_ = <CLEAN>;
  print "$celebrity already smeared\n" and exit unless famous $_;
  @dirt = qw&@- /. ~~ ;# ;; ;. ,. ); () *+ __ -( /@ .% /| ;_&; s/(.)/$dirt[ord($1)>>4].$dirt[ord($1)&15]/egs;
  open A, ">$celebrity" or print "Could not smear the good name of $celebrity\n\n" and exit;
  print A q#$==$';$;||$.|$|;$_='*$(^@(%_+&# . $_ . '&$#%^';print A <<'FILTH' and exit;;
';$__='`'&'&';$___="````"|"$[`$["|'`%",';$~=("$___$__-$[``$__"|"$___"|("$___$__-$[.%")).("'`"|"'$["|"'#").'/.*?&([^&]*)&.*/$'.++$=.("/``"|"/$[`"|"/#'").(";`/[\\`\\`$__]//`;"|";$[/[\\$[\\`$__]//`;"|";#/[\\\$\\.$__]//'").'@:=("@-","/.","~~",";#",";;",";.",",.",");","()","*+","__","-(","/@",".%","/|",";_");@:{@:}=$%..$#:;'.('`'|"$["|'#')."/(..)(..)/".("```"|"``$["|'#("').'(($:{$'.$=.'}<<'.(++$=+$=).')|($:{$'.$=.'}))/'.("```;"|"``$[;"|"%'#;").("````'$__"|"%$[``"|"%&!,").${$[};`$~$__>&$=`;
FILTH
}

1;
__END__

=head1 NAME

Acme::Smirch - For I<really> dirty programs

=head1 SYNOPSIS

	use Smirch;

	Smirch::smear("tooClean.pl");

=head1 DESCRIPTION

If you have not yet seen the most clever Acme::Bleach.pm by Damian
Conway, go see that B<now>.  The only trouble with showing off Bleach
to your friends is that it requires Bleach to be installed on their
machines.  So here is Smirch, that does the converse of Bleach -
rewrites your program using only non alphanumeric characters BUT it
does not depend on any external module!  That's right - complete perl
without numbers or letters.

After you have Smirched a program, the program continues to work as
before except now it is absolutely unreadable as the module removes
all I<sightly> characters from your source file.

The Smirched program has to sit in a file of its own - you cannot run
a smirched program by piping it to perl.

You can now reform your source to look like this:

                                          $==$'; 
                                         $;||$.| $|;$_
             ='*$ (                  ^@(%_+&~~;# ~~/.~~
         ;_);;.);;#)               ;~~~~;_,.~~,.* +,./|~
    ~;_);@-,  .;.); ~             ~,./@@-__);@-);~~,.*+,.
  /|);;;~~@-~~~~;;(),.           ;.,./@,./@,.;_~~@-););,.
  ;_);~~,./@,.;;;./@,./        |~~~~;#-(@-__@-__&$#%^';$__
   ='`'&'&';$___="````"  |"$[`$["|'`%",';$~=("$___$__-$[``$__"|
              "$___"|       ("$___$__-$[.%")).("'`"|"'$["|"'#").
        '/.*?&([^&]*)&.*/$'.++$=.("/``"|"/$[`"|"/#'").(";`/[\\`\\`$__]//`;"
        |";$[/[\\$[\\`$__]//`;"|";#/[\\\$\\.$__]//'").'@:=("@-","/.",
       "~~",";#",";;",";.",",.",");","()","*+","__","-(","/@",".%","/|",
        ";_");@:{@:}=$%..$#:;'.('`'|"$["|'#')."/(..)(..)/".("```"|"``$["|
        '#("').'(($:{$'.$=.'}<<'.(++$=+$=).')|($:{$'.$=.'}))/'.("```;"|
        "``$[;"|"%'#;").("````'$__"|"%$[``"|"%&!,").${$[};`$~$__>&$=`;$_=
       '*$(^@(%_+&@-__~~;#~~@-;.;;,.(),./.,./|,.-();;#~~@-);;;,.;_~~@-,./.,
        ./@,./@~~@-);;;,.(),.;.~~@-,.,.,.;_,./@,.-();;#~~@-,.;_,./|~~@-,.
          ,.);););@-@-__~~;#~~@-,.,.,.;_);~~~~@-);;;,.(),.*+);;# ~~@-,
           ./|,.*+,.,.);;;);*+~~@-,.*+,.;;,.;.,./.~~@-,.,.,.;_)   ;~~~
             ~@-,.;;,.;.,./@,./.);*+,.;.,.;;@-__~~;#~~@-,.;;,.*   +);;
               #);@-,./@,./.);*+~~@-~~.%~~.%~~@-;;__,. /.);;#@-   __@-
                 __   ~~;;);/@;#.%;#/.;#-(@-__~~;;;.;_ ;#.%~~~~  ;;()
                      ,.;.,./@,.  /@,.;_~~@- ););,.;_   );~~,./  @,.
                      ;;;./@,./|  ~~~~;#-(@- __,.,.,.    ;_);~~~ ~@
                       -~~());;   #);@-,./@,  .*+);;;     ~~@-~~
                       );~~);~~  *+~~@-);-(   ~~@-@-_      _~~@-
                       ~~@-);;   #,./@,.;.,    .;.);@      -~~@-;
                       #/.;#-(   ~~@-@-__      ~~@-~~       @-);@
                       -);~~,    .*+,./       |);;;~        ~@-~~
                        ;;;.;     _~~@-@     -__);.         %;#-(
                        @-__@      -__~~;#  ~~@-;;          ;#,.
                        ;_,..         %);@-,./@,            .*+,
                        ..%,           .;.,./|)             ;;;)
                        ;;#~            ~@-,.*+,.           ,.~~
                       @-);            *+,.;_);;.~         ~););
                      ~~,.;         .~~@-);~~,.;.,         ./.,.;
                      ;,.*+        ,./|,.);  ~~@-         );;;,.(
                    ),.*+);                              ;#~~/|@-
                  __~~;#~~                                $';$;;

Valid and devious perl.

=head1 TODO

Smirch currently spits out perl in one line - it would be nice to have
it reform the code automatically into pretty pictures like the above
camel.

=head1 BUGS

Yes.

Smirch does not work with windows (yet?).  Also, smirched programs are
a little flakey and sadness happens when used with Bleach or anything
too strenuous.  Use is unadvisable for anything important.

=head1 AUTHOR

Jasvir Nagra

=head1 COPYRIGHT

   Copyright (c) 2001, Jasvir Nagra. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
