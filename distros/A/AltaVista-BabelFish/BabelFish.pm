package AltaVista::BabelFish;
   
use strict;
use warnings;
use version; our $VERSION = qv('42.0.2');

use Class::Std;
use Class::Std::Utils;
   
my %lang = (
    'zh' => {
        'name'    => 'Chinese Simplified',
        'targets' => [qw(en)],
    },
    'zt' => {
        'name'    => 'Chinese Traditional',
        'targets' => [qw(en)],
    },
    'en' => {
        'name'    => 'English',
        'targets' => [qw(es zh zt nl fr de el it ja ko pt ru)],
    },
    'nl' => {
        'name'    => 'Dutch',
        'targets' => [qw(en fr)],
        'native'  => 'Nederlands',
    },
    'fr' => {
        'name'    => 'French',
        'targets' => [qw(en nl de el it pt es)],
    },
    'de' => {
        'name'    => 'German',
        'targets' => [qw(en fr)],
    },
    'el' => {
        'name'    => 'Greek',
        'targets' => [qw(en fr)],
    },
    'it' => {
        'name'    => 'Italian',
        'targets' => [qw(en fr)],
        'native'  => 'Italiano',
    },
    'ja' => {
        'name'    => 'Japanese',
        'targets' => [qw(en)],
    },
    'ko' => {
        'name'    => 'Korean',
        'targets' => [qw(en)],
    },
    'pt' => {
        'name'    => 'Portuguese',
        'targets' => [qw(en fr)],
    },
    'ru' => {
        'name'    => 'Russian',
        'targets' => [qw(en)],
    },
    'es' => {
        'name'    => 'Spanish',
        'targets' => [qw(en fr)],
    },
);
    
# make seperator $SimpleMood::DEATHSTAR: :=-=: ?? 
my %alta = (
    'seperator'     => 'Perl_AltaVista_BabelFish_DanMuey', 
    'url'           => 'http://babelfish.altavista.com/tr',
    'form'          => {
        'doit' => 'done',
        'intl' => '1',
        'tt'   => 'urltext',
    },
    'urltext_param' => 'urltext',
    'lp_param'      => 'lp',
    'pre'           => '<!-- Target text (content) -->',
    'pst'           => '<!-- end: Target text (content) -->',
    'q_pre'         => '<div style=padding:10px;>',
    'q_pst'         => '</div>',
#   'q_pre'         => 'input type=hidden name="q" value="',
#   'q_pst'         => '"',
    'kls_pre'       => 'input type="hidden" name="kls" value="',
    'kls_pst'       => '"',
    'ienc_pre'      => 'input type="hidden" name="ienc" value="',
    'ienc_pst'      => '"',
);

{ # start encapsulation of inside out object 

    my %source :ATTR(init_arg => 'source', get => 'source');
    my %target :ATTR(init_arg => 'target', get => 'target');
    my %errstr :ATTR(get => 'errstr');

    sub BUILD {
         my ($self, $ident, $args_ref) = @_;
         $source{ $ident } = defined $args_ref->{'source'} 
                             && exists $lang{ $args_ref->{'source'} }
                             ? $args_ref->{'source'} : 'en';
         $target{ $ident } = $args_ref->{'target'}  || ''; 
         
         $self->set_source( $source{ $ident } );
         $self->set_target( $target{ $ident } );

         $errstr{ $ident } = undef;
  
         return;
    }
    
    sub set_source {
        my ($self, $_source) = @_;
        my $ident = ident $self;
        $source{ $ident } = $_source if defined $_source 
                               && exists $lang{ $_source };
        if(!defined $target{ $ident } 
            || !grep /^\Q$target{ $ident }\E$/, 
            @{ $lang{ $source{ $ident } }->{'targets'} }) {

            $target{ $ident } = $lang{ $source{ $ident } }->{'targets'}->[0]; 
        }
        return $source{ $ident };
    }
    
    sub set_target {
        my($self, $_target) = @_;
        my $ident = ident $self;
        $target{ $ident } = $_target 
            if defined $_target &&  exists $lang{ $_target } 
            && grep /^\Q$target{ $ident }\E$/, 
                @{ $lang{ $source{ $ident } }->{'targets'} };
         return $target{ $ident };
    }
    
    sub get_english {
         my ($self, $_lang) = @_;
         my $lnx = exists $lang{ $_lang } ? $_lang : $source{ ident $self };
         return $lang{ $lnx }->{'name'};
    }

    sub get_native {
         my ($self, $_lang) = @_;
         my $name = undef;
         return $lang{ $_lang}->{'native'} if exists $lang{ $_lang}->{'native'};
         require Locales::Language; # only need it here :)
         eval {
             $name = Locales::Language->new( $_lang )->code2language( $_lang );
         }; # eval since this dies a lot...
         return $name;
         # return scalar $self->translate( $self->get_english($_lang), 'en', $_lang ); # or cache in hash native => '',
    }
    
    sub get_source_languages_arrayref {
         my ($self, $_lang) = @_;
         $_lang = defined $_lang && exists $lang{ $_lang } ? $_lang : '';
         my @target;
         if($_lang) {
             for(keys %lang) {
                 push @target, $_ if grep /^\Q$_lang\E$/, 
                      @{ $lang{$_}->{'targets'} };
             }
             # list all languages that can be translated into this lang
             return \@target;
         }
         return [keys %lang]; # list all source languages
    }
    
    sub get_target_languages_arrayref {
         my ($self, $_lang) = @_;
         $_lang = defined $_lang && exists $lang{ $_lang } 
                  ? $_lang : $source{ ident $self };
         return $lang{ $_lang }->{'targets'};
    }
    
    sub translate {
        my ($self, $text, $_source, $_target) = @_;

        my $current_source = $self->get_source();
        my $current_target = $self->get_target();
        $self->set_source( $_source ) if $_source;
        $self->set_target( $_target ) if $_target;

        if(ref $text eq 'ARRAY') {
            $alta{'seperator'} =~ s/\W//g;
            my $str = join " \n\n$alta{'seperator'}\n\n ", @{ $text };
            my ($pre,$x,$y) = $self->translate($str) or return undef;

            $self->set_source( $current_source ) if $_source;
            $self->set_target( $current_target ) if $_target; 

            return ([split / \n\n$alta{'seperator'}\n\n /, $pre], $x, $y) 
                if wantarray;
            return  [split / \n\n$alta{'seperator'}\n\n /, $pre]
        } 
        else {
            use LWP::UserAgent;
            $alta{'form'}->{ $alta{'urltext_param'} } = $text; # url encode?
            $alta{'form'}->{ $alta{'lp_param'} }      
                = "$source{ ident $self }\_$target{ ident $self }";
    
            my $agt = new LWP::UserAgent;
            $agt->agent("Perl Module: AltaVista::BabelFish/$VERSION "
                        . '(c) Dan Muey/2005');
            my $res = $agt->post($alta{url}, $alta{form});
    
            $errstr{ ident $self } = $res->status_line() 
                if !$res->is_success();
            return undef if !$res->is_success();
            my $cnt = $res->content();
    
            my ($parse_me) = $cnt      
                =~ m/\Q$alta{'pre'}\E(.*)\Q$alta{'pst'}\E/si;
            my ($tr)       = $parse_me 
                =~ m/\Q$alta{'q_pre'}\E([^\"]*)\Q$alta{'q_pst'}\E/si;
            my ($k)        = $parse_me 
                =~ m/\Q$alta{'kls_pre'}\E([^\"]*)\Q$alta{'kls_pst'}\E/si;
            my ($i)        = $parse_me 
                =~ m/\Q$alta{'ienc_pre'}\E([^\"]*)\Q$alta{'ienc_pst'}\E/si;
            # set to empty instead of undef to avoid warnings
            $tr = '' if !defined $tr;
            $k  = '' if !defined $k;
            $i  = '' if !defined $i;

            $self->set_source( $current_source ) if $_source;
            $self->set_target( $current_target ) if $_target;

            return ($tr, $k, $i) if wantarray;
            return $tr;
        }
    }
    
    sub get_languages_hashref { 
        return \%lang;
    }
    
    sub is_latest_version {
        my($self) = @_;
        my $ident = ident $self;
        my ($cpan, $ior) = ('', '');
    
        eval 'use CPAN;';
    
        if($@) { 
            $errstr{ $ident } = $@; 
            return 0; 
        }
    
        eval <<'REDIRECT_END';
            use IO::Redirect;
            $ior = IO::Redirect->new();
            $ior->redirect_stdout_stderr(\$cpan);
REDIRECT_END
    
        my $mod = CPAN::Shell->expand('Module', 'AltaVista::BabelFish');
    
        if(defined $mod) {
            if($VERSION eq $mod->cpan_version) {
                if(ref $ior) {
                    $ior->un_redirect_stdout_stderr();
                }
                return 1;
            }
            else {
                $errstr{ $ident } = "Installed Version: $VERSION\nLatest "
                                    . 'version: ' . $mod->cpan_version();
            }
        } 
        else {
            $errstr{ $ident } 
                = "Undefined CPAN Object. Here is what CPAN said:\n$cpan" 
                    if ref $ior;
            $errstr{ $ident } = "Undefined CPAN Object." if !ref $ior;
        }
    
        if(ref $ior) { 
            $ior->un_redirect_stdout_stderr();
        }
    
        return;
    }
    
    sub fishinfo {
        my($self, $use_native) = @_; 
        my $title 
            = "AltaVista::BabelFish Perl module $VERSION by Daniel Muey";
        my $url   = 'http://search.cpan.org/~dmuey/AltaVista-BabelFish-'
                  . "$VERSION/BabelFish.pm";
        my $html  = -t STDIN ? 0 : 1;
        my $fish  = AltaVista::BabelFish->new;  
        my $out   = $html 
            ? qq(<h3>$title</h3>\n)
              . qq(<p><a target="_blank" href="$url">Click here</a>)
              . " for documentation.</p>\n<ul>\n"
            : "$title\nSee `perldoc AltaVista::BabelFish` or $url"
              . " for documentation\n\n";

        for my $src (sort @{ $fish->get_source_languages_arrayref() }) {
            my $native  = $use_native && $src ne 'en' 
                          ? $fish->get_native($src) : '';
            my $english = $fish->get_english($src);
            $native = $native && $native ne $english ? "[$native] " : '';
            $out .= "  <li>" if $html;
            $out .= "$native$english ($src) translates into:\n"; 
            $out .= "     <ul>\n" if $html;
            for(sort @{ $fish->get_target_languages_arrayref($src) }) {
                $out .= "      <li>\n" if $html;
                $out .= "        " . $fish->get_english($_) . " ($_)\n";
                $out .= "      </li>\n" if $html;
            }
            $out .= "     </ul>\n" if $html;   
            $out .= "  </li>\n" if $html;
            $out .= "\n";
        } 

        $out .= "</ul>\n" if $html;

        if(!defined wantarray) {
            print $out;
        } 
        else { 
            return $out; 
        } 
    }

} # end encapsulation of inside out object
    
1; # yes I'd like to do "42;" but warnings doesn't like it :)
    
__END__
    
=head1 NAME
    
AltaVista::BabelFish - Perl OO interface to http://babelfish.altavista.com
   
=head1 SYNOPSIS
    
    use AltaVista::BabelFish;
    
    my $phish = AltaVista::BabelFish->new();
or
    my $phish = AltaVista::BabelFish->new({ source => $src });
or
    my $phish = AltaVista::BabelFish->new({ target => $trg });
or
    my $phish = AltaVista::BabelFish->new({ source => $src, target => $trg });
  
If $source and/or $target are not specified it defaults to 'en' and 'es' respectively.
    
=head1 DESCRIPTION
   
This module gives an object oriented interface to http://babelfish.altavista.com to add translation ability to your script.
    
=head1 Object methods
    
=head2 $phish->translate()
    
This communicates with babelfish.altavista.com to do the actual translating.
     
You can optionally give new source and target languages for this translation.
Setting these does not change the languages for the object it changes them only for this call.

    my $trans = $phish->translate($str,$source,$target);
    my $trans = $phish->translate($str,$source);
    my $trans = $phish->translate($str,0,$target); # 0 or '' or undef (IE false)
    my $trans = $phish->translate($str) or die $phish->get_errstr();;
    my($trans, $kls, $ienc) = $phish->translate($str) or die $phish->get_errstr();
    
$kls and $ienc are the values of the hidden fields of the same name in the "Search the web with this text" form of the results page.
    
If you have multiple strings you want translated into the same source and target languages specify them in an array ref as the first argument:
    
    my $result_array_ref = $phish->translate($string_array_ref) or die $phish->errstr();
    
The resulting array ref has the translated versions in the same positions:
    
    my $result_array_ref = $phish->translate(["hello", "goodbye", "thank you", "you are welcome"],'en','fr') or die $phish->errstr();
    print join ', ', @{ $result_array_ref }; # prints : bonjour, au revoir, merci, vous ?tes bienvenu
    
And you only have to make one HTTP call to the internet instead of one per item to translate.
    
With an array ref $kls and $ienc are still available in array context.
    
    my ($result_array_ref, $ls, $ienc) = $phish->translate(["hello", "goodbye", "thank you", "you are welcome"],'en','fr') or die $phish->errstr();
   
In all cases if $source and/or $target are not specified it uses what was previously set.
    
=head2 $phish->get_errstr()
    
Returns any errors encountered translate()ing as a string.
    
=head2 $phish->get_source()
    
Returns the current source language.
    
     my $src = $phish->get_source(); 
    
=head2 $phish->set_source()
    
Sets the source language
    
    $phish->set_source('fr');
    
sets the source langauge to 'fr'
    
If an invalid argument is specified then it is not changed and the original (IE still current) langauge is used. 
    
If the current target is not supported by the new source language the target is changed to the first target language for the source language.
    
=head2 $phish->get_target()
    
Returns the current source language.
    
    my $trg = $phish->get_target(); 
    
=head2 $phish->set_target($lang)
    
Sets the target langauge.
    
    $phish->set_target('fr');
    
sets the target langauge to 'fr'
    
If an invalid argument is specified then it is not changed and the original (IE still current) langauge is returned.  
    
=head2 $phish->get_english()
    
It returns a string that is the English version of the given language or if nothing is given (or an invalid langauage) then it returns the current source language's name.
    
    my $source_name = $phish->get_english();
    
$source_name is now "English" (or whatever you had changed the source language to of course)
    
    my $zt_name = $phish->get_english('zt');
    
$zt_name is now "Chinese Traditional"

=head2 $phish->get_native()

Like get_english() but returns the given language's name in the given language.

    my $german = $phish->get_native('de');
    # $german is 'Deutsch'
    
This gets funky for some languages/character sets. See L<Locales::Language> for more info. 

=head2 $phish->get_target_languages_arrayref()
    
Returns an array reference of the target languages for the given language or the current source language if nothing is specified.
    
    my $lang = 'it';
    print $phish->get_english($lang) . " can be translated into the following languages:\n";
    for(@{ $phish->get_target_languages_arrayref($lang) }) {
        print $phish->get_english($_), "\n"; 
    } 
   
    print $phish->get_english() . " can be translated into the following languages:\n";
    for(@{ $phish->get_target_languages_arrayref() }) {
        print $phish->get_english($_), "\n";
    }
    
=head2 $phish->get_source_languages_arrayref()
    
Returns an array reference of all the languages that can be translated into the given langauge.
If no [valid] language is given, an array ref of all available source languages is returned
    
    my $can_be_translated_into_dutch_array_ref = $phish->get_source_languages_arrayref('nl');
    my $all_source_languages_array_ref         = $phish->get_source_languages_arrayref(); 
    
    for my $src (@{ $phish->source_languages_arrayref }) {
        print $phish->get_english($src) . " can be translated into from the following languages:\n";
        for($phish->get_source_languages_arrayref($src) }) {
            print $phish->english($_),"\n";
        }
    }
    
=head2 $phish->is_latest_version()
    
Since its always possible that AltaVista could change around their site this module could need reconfigured on occasion.
    
This function will check to see if your version is the latest.
    
     die $phish->get_errstr() if !$phish->is_latest_version();
or perhaps:
     update_modules_according_to_our_policy(ref $phish) if !$phish->is_latest_version();
 
If you have L<IO::Redirect> installed, the verbose output from the L<CPAN> module is stored in $phish->get_errstr() if there is a problem.
Otherwise the L<CPAN> functions will have output that you can't control, so its recommended you install L<IO::Redirect> if its not already.
    
=head2 $phish->get_languages_hashref()
    
Returns a hashref of language info. It can be used to view all the available languages, their name, targets, and two letter code.
It is probably most usefull if you need to reference what the two letter code is for a given langauge.
        
    use Data::Dumper;
    print Dumper $phish->get_languages_hashref; # AltaVista::BabelFish->get_languages_hashref works also
    
=head2 $phish->fishinfo()
    
Returns content for an html page (no header) if called via a browser (IE !-t STDIN) and a text page if via CLI (IE -t STDIN)
In void context prints its info, otherwise it returns it.
        
    print CGI::header();
    print $htmltop;
    print $phish->fishinfo(); # AltaVista::BabelFish->fishinfo() works also
    print $htmlbot;
    
If given a true argument the language's $phish->get_native() is printed out along with it if its not the same as the english version.

$phish->get_native() results gets funky for some languages/character sets. See L<Locales::Language> for more info.

=head1 DON'T PANIC
    
Just a personal note about what this module means to me. I like it because 
it combines two of my favorite things: Perl and the world of Douglas Adams
    
So I'd like to say "print $thanks for 1..1000000;" to Mr. Wall for Perl and 
to Mr. Adams: So long and thanks for all the fish, we'll miss you buddy :)
    
=head1 SEE ALSO
    
L<LWP::UserAgent>, L<CPAN>, L<IO::Redirect>, L<Locales::Language>
    
=head1 AUTHOR
    
Daniel Muey, L<http://drmuey.com/cpan_contact.pl>
    
=head1 COPYRIGHT AND LICENSE
    
Copyright 2005 by Daniel Muey
    
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
    
=cut
