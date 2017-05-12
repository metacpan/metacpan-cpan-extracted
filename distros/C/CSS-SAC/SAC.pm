
###
# CSS::SAC - a SAC implementation for Perl
# Robin Berjon <robin@knowscape.com>
# 17/08/2001 - bugfixes...
# 23/04/2001 - more enhancements
# 19/03/2001 - second version, various suggestions and enhancements
# 24/02/2001 - prototype mark I of the new model
###

package CSS::SAC;
use strict;
use vars qw(
            $VERSION
            $RE_STRING
            $RE_NAME
            $RE_IDENT
            $RE_RANGE
            $RE_NUM
            %DIM_MAP
            %FUNC_MAP
           );
$VERSION = '0.08';

use CSS::SAC::ConditionFactory  qw();
use CSS::SAC::SelectorFactory   qw();
use CSS::SAC::LexicalUnit       qw(:constants);
use CSS::SAC::Selector::Sibling qw(:constants);
use CSS::SAC::SelectorList      qw();

use Text::Balanced              qw();

use constant DEBUG => 0;

#---------------------------------------------------------------------#
# build a few useful regexen and maps
#---------------------------------------------------------------------#

# matches a quoted string
$RE_STRING = Text::Balanced::gen_delimited_pat(q{'"}); #"
$RE_STRING = qr/$RE_STRING/s;

# matches a name token
$RE_NAME = qr/
             (?:(?:\\(?:(?:[a-fA-F0-9]{1,6}[\t\x20])|[\x32-\xff]))|[a-zA-Z\x80-\xff0-9-])+
             /xs;

# matches a valid CSS ident (this may be wrong, needs testing)
$RE_IDENT = qr/
             (?:(?:\\(?:(?:[a-fA-F0-9]{1,6}[\t\x20])|[ \x32-\xff]))|[a-zA-Z\x80-\xff])
             (?:(?:\\(?:(?:[a-fA-F0-9]{1,6}[\t\x20])|[ \x32-\xff]))|[a-zA-Z\x80-\xff0-9_-])*
             /xs;

# matches a unicode range
$RE_RANGE = qr/(?:
                (?:U\+)
                (?:
                  (?:[0-9a-fA-F]{1,6}-[0-9a-fA-F]{1,6})
                  |
                  (?:\?{1,6})
                  |
                  (?:[0-9a-fA-F](?:
                  (?:\?{0,5}|[0-9a-fA-F])(?:
                  (?:\?{0,4}|[0-9a-fA-F])(?:
                  (?:\?{0,3}|[0-9a-fA-F])(?:
                  (?:\?{0,2}|[0-9a-fA-F])(?:
                  (?:\?{0,1}|[0-9a-fA-F])))))))
                )
               )
              /xs;


# matches a number
$RE_NUM = qr/(?:(?:[0-9]*\.[0-9]+)|(?:[0-9]+))/;


# maps a length or assoc value to it's constant
%DIM_MAP = (
            em      => EM,
            ex      => EX,
            px      => PIXEL,
            cm      => CENTIMETER,
            mm      => MILLIMETER,
            in      => INCH,
            pt      => POINT,
            pc      => PICA,
            deg     => DEGREE,
            rad     => RADIAN,
            grad    => GRADIAN,
            ms      => MILLISECOND,
            s       => SECOND,
            hz      => HERTZ,
            khz     => KILOHERTZ,
            '%'     => PERCENTAGE,
           );

# maps a length or assoc value to it's constant
%FUNC_MAP = (
            attr        => ATTR,
            counter     => COUNTER_FUNCTION,
            counters    => COUNTERS_FUNCTION,
            rect        => RECT_FUNCTION,
            url         => URI,
            rgb         => RGBCOLOR,
           );

#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => {
                                   fields => [qw(
                                                 _cf_
                                                 _sf_
                                                 _dh_
                                                 _eh_
                                                 _dh_can_
                                                 _allow_charset_
                                                 _ns_map_
                                                 _tmp_media_
                                               )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC->new(\%options)
# creates a new sac parser
#---------------------------------------------------------------------#
sub new {
    my $class = shift;
    my $options = shift || {};

    # set our options
    my $self = bless [], $class;
    $self->[_cf_] = $options->{ConditionFactory} || CSS::SAC::ConditionFactory->new;
    $self->[_sf_] = $options->{SelectorFactory}  || CSS::SAC::SelectorFactory->new;
    $self->[_eh_] = $options->{ErrorHandler}     || CSS::SAC::DefaultErrorHandler->new;
    $self->[_dh_can_] = {};
    $self->DocumentHandler($options->{DocumentHandler}) if $options->{DocumentHandler};

    return $self;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# $sac->ParserVersion
# returns the supported CSS version
#---------------------------------------------------------------------#
sub ParserVersion {
    # IMP
    # this should perhaps return http://www.w3.org/TR/REC-CSS{1,2,3}
    # as per http://www.w3.org/TR/SAC, but it's tricky for CSS3 which
    # is modularized
    return 'CSS3';
}
#---------------------------------------------------------------------#
*CSS::SAC::getParserVersion = \&ParserVersion;


#---------------------------------------------------------------------#
# my $cf = $sac->ConditionFactory
# $sac->ConditionFactory($cf)
# get/set the ConditionFactory that we use
#---------------------------------------------------------------------#
sub ConditionFactory {
    (@_==2) ? $_[0]->[_cf_] = $_[1] :
              $_[0]->[_cf_];
}
#---------------------------------------------------------------------#
*CSS::SAC::setConditionFactory = \&ConditionFactory;


#---------------------------------------------------------------------#
# my $sf = $sac->SelectorFactory
# $sac->SelectorFactory($sf)
# get/set the SelectorFactory that we use
#---------------------------------------------------------------------#
sub SelectorFactory {
    (@_==2) ? $_[0]->[_sf_] = $_[1] :
              $_[0]->[_sf_];
}
#---------------------------------------------------------------------#
*CSS::SAC::setSelectorFactory = \&SelectorFactory;


#---------------------------------------------------------------------#
# my $dh = $sac->DocumentHandler
# $sac->DocumentHandler($dh)
# get/set the DocumentHandler that we use
#---------------------------------------------------------------------#
sub DocumentHandler {
    my $sac = shift;
    my $dh = shift;

    # set the doc handler, and see what it can do
    if ($dh) {
        $sac->[_dh_] = $dh;

        my @dh_methods = qw(
                            comment
                            charset
                            end_document
                            end_font_face
                            end_media
                            end_page
                            end_selector
                            ignorable_at_rule
                            import_style
                            namespace_declaration
                            property
                            start_document
                            start_font_face
                            start_media
                            start_page
                            start_selector
                           );
        for my $meth (@dh_methods) {
            $sac->[_dh_can_]->{$meth} = $dh->can($meth);
        }
    }

    return $sac->[_dh_];
}
#---------------------------------------------------------------------#
*CSS::SAC::setDocumentHandler = \&DocumentHandler;


#---------------------------------------------------------------------#
# my $eh = $sac->ErrorHandler
# $sac->ErrorHandler($eh)
# get/set the ErrorHandler that we use
#---------------------------------------------------------------------#
sub ErrorHandler {
    (@_==2) ? $_[0]->[_eh_] = $_[1] :
              $_[0]->[_eh_];
}
#---------------------------------------------------------------------#
*CSS::SAC::setErrorHandler = \&ErrorHandler;


#                                                                     #
#                                                                     #
### Accessors #########################################################




### Parsing Methods ###################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# $sac->parse(\%options)
# parses a style sheet
#---------------------------------------------------------------------#
sub parse {
    my $sac = shift;
    my $options = shift;

    # we always load the style sheet into memory because style sheets
    # are usually small. If this is a problem we'll change that.
    my $css;
    if ($options->{string}) {
        $css = $options->{string};
    }
    elsif ($options->{ioref}) {
        my $io = $options->{ioref};
        local $/ = undef;
        $css = <$io>;
        close $io;
    }
    elsif ($options->{filename}) {
        open CSS, "$options->{filename}" or die $!;
        local $/ = undef;
        $css = <CSS>;
        close CSS;
    }
    else {
        return undef;
    }

    ### look at the other options
    # charsets are forbidden in embedded style sheets
    if ($options->{embedded}) {
        $sac->[_allow_charset_] = 0;
    }
    else {
        $sac->[_allow_charset_] = 1;
    }



    #---> Start Parsing <---------------------------------------------#

    # start doc
    warn "[SAC] start parsing\n" if DEBUG;
    $sac->[_dh_]->start_document if $sac->[_dh_can_]->{start_document};

    # before anything else occurs there can be a charset
    warn "[SAC] parsing charset\n" if DEBUG;
    $sac->parse_charset(\$css);
    $sac->[_allow_charset_] = 0;

    # remove an eventual HTML open comment (not reported to handler)
    warn "[SAC] removing HTML comments\n" if DEBUG;
    $css =~ s/^\s*<!--//;

    # parse some possible comments
    warn "[SAC] parsing comments\n" if DEBUG;
    $sac->parse_comments(\$css);

    # parse some possible imports
    warn "[SAC] parsing imports\n" if DEBUG;
    $sac->parse_imports(\$css);

    # parse some possible ns declarations
    warn "[SAC] parsing ns decl\n" if DEBUG;
    $sac->parse_namespace_declarations(\$css);

    # enter the main parsing loop
    # what we can have right now is comments, at-rules and selectors
    while (length($css)) {

        # parse some possible comments
        warn "[SAC] parsing comments\n" if DEBUG;
        $sac->parse_comments(\$css);

        # if we've got a closing block, it's a closing @media
        if ($css =~ s/^\s*\}//) {
            warn "[SAC] closing media rule\n" if DEBUG;
            $sac->[_dh_]->end_media($sac->[_tmp_media_]) if $sac->[_dh_can_]->{end_media};
            $sac->[_tmp_media_] = undef;
        }

        # there's an at-rule coming up
        elsif ($css =~ m/^\s*\@/) {

            # @media
            if ($css =~ s/^\s*\@media\s+//i) {
                warn "[SAC] parsing media\n" if DEBUG;
                my $medialist = $sac->parse_medialist(\$css);
                $sac->[_tmp_media_] = $medialist;
                $sac->[_dh_]->start_media($medialist) if $sac->[_dh_can_]->{start_media};
                $css =~ s/^\s*{//;
            }

            # @font-face
            elsif ($css =~ s/^\s*\@font-face\s+//i) {
                warn "[SAC] parsing font-face\n" if DEBUG;
                # parse the block
                my $rule;
                ($rule,$css,undef) = Text::Balanced::extract_bracketed($css,q/{}'"/,qr/\s*/); #"
                $sac->[_dh_]->start_font_face if $sac->[_dh_can_]->{start_font_face};
                $sac->parse_rule(\$rule);
                $sac->[_dh_]->end_font_face if $sac->[_dh_can_]->{end_font_face};
            }

            # @page
            elsif ($css =~ s/^\s*\@page\s+//i) {
                warn "[SAC] parsing page\n" if DEBUG;
                # grab the name and pseudo-page if they're there
                $css =~ s/^($RE_IDENT)?\s*(?::($RE_IDENT))?//;
                my ($name,$pseudo) = ($1,$2);

                # parse the block
                my $rule;
                ($rule,$css,undef) = Text::Balanced::extract_bracketed($css,q/{}'"/,qr/\s*/); #"
                $sac->[_dh_]->start_page($name,$pseudo) if $sac->[_dh_can_]->{start_page};
                $sac->parse_rule(\$rule);
                $sac->[_dh_]->end_page($name,$pseudo) if $sac->[_dh_can_]->{end_page};
            }

            # unknown
            # this is a little harder because we have to guess what
            # at rules that we know nothing about will be like
            else {
                my $at_rule;
                warn "[SAC] parsing unknown at rule ($css)\n" if DEBUG;

                # take off the @rule first
                $css =~ s/^\s*(\@$RE_IDENT\s*)//;
                $at_rule .= $1;

                # then grab whatever is not a block
                $css =~ s/^([^;{]*)//;
                $at_rule .= $1;

                # now we either terminate, or have a block
                if ($css =~ s/^;//) {
                    $at_rule .= ';';
                }
                else {
                    my $block;
                    ($block,$css,undef) = Text::Balanced::extract_bracketed($css,q/{}'"/,qr/\s*/); #"
                    $at_rule .= $block;
                }

                $sac->[_dh_]->ignorable_at_rule($at_rule) if $sac->[_dh_can_]->{ignorable_at_rule};
            }
        }

        # html end comment
        elsif ($css =~ s/^\s*-->\s*//) {
            # we don't do anything with those presently
            warn "[SAC] removing HTML comments\n" if DEBUG;
        }

        # we have selectors
        elsif (my $sel_list = $sac->parse_selector_list(\$css)) {
            warn "[SAC] parsed selectors\n" if DEBUG;
            next unless @$sel_list;
            # callbacks
            $sac->[_dh_]->start_selector($sel_list) if $sac->[_dh_can_]->{start_selector};

            # parse the rule
            my $rule;
            warn "[SAC] parsing rule\n" if DEBUG;

            ### BUG
            # The Text::Balanced extractions below are not correct since they don't take
            # comments into account. With the first one, it'll fail on apostrophes in
            # comments, with the latter, on unbalanced apos and } in comments and
            # apos-strings. The latter is used currently because it is less likely to fail,
            # but what is needed is a real parser that steps inside the black parsing out
            # comments and property values. The good news is that we have most of the bits
            # to do that right already.

            #($rule,$css,undef) = Text::Balanced::extract_bracketed($css,q/{}'"/,qr/\s*/); #"
            ($rule,$css,undef) = Text::Balanced::extract_bracketed($css,q/{}"/,qr/\s*/); #"
            $sac->parse_rule(\$rule);

            # end of the rule
            $sac->[_dh_]->end_selector($sel_list) if $sac->[_dh_can_]->{end_selector};
        }

        # trailing whitespace, should only happen at the very end
        elsif ($css =~ s/^\s+//) {
            # do nothing
            warn "[SAC] just whitespace\n" if DEBUG;
        }

        # error
        else {
            last if ! length $css;
            $sac->[_eh_]->fatal_error('Unknown trailing tokens in style sheet: "' . $css . '"');
            last;
        }
    }

    # end doc
    warn "[SAC] end of document\n" if DEBUG;
    $sac->[_dh_]->end_document if $sac->[_dh_can_]->{end_document};

    #---> Finish Parsing <--------------------------------------------#

}
#---------------------------------------------------------------------#
*CSS::SAC::parseStyleSheet = \&parse;


#---------------------------------------------------------------------#
# $sac->parse_charset($string_ref)
# parses a charset
#---------------------------------------------------------------------#
sub parse_charset {
    my $sac = shift;
    my $css = shift;

    # we don't remove leading ws, the charset must come first
    return unless $$css =~ s/^\@charset\s+//i;

    # extract the string
    if ($$css =~ s/^($RE_STRING)\s*;//) {
        my $charset = $1;
        $charset =~ s/^(?:'|")//; #"
        $charset =~ s/(?:'|")$//; #'

        $sac->[_dh_]->charset($charset) if $sac->[_dh_can_]->{charset};
    }
    else {
        if ($$css =~ s/[^;]*;//) {
            $sac->[_eh_]->warning('Unknown token in charset declaration');
        }
        else {
            $sac->[_eh_]->fatal_error('Unknown token in charset declaration');
        }
    }
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_imports($string_ref)
# parses import rules at the beginning
#---------------------------------------------------------------------#
sub parse_imports {
    my $sac = shift;
    my $css = shift;


    # we may have several imports separated by comments
    while ($$css =~ s/^\s*\@import\s+//i) {
        # first get the uri
        my $uri;
        if ($$css =~ s/^url\(//) {
            $$css =~ s/^((?:$RE_STRING)|([^\)]*))\s*//;
            $uri = $1;
            $uri =~ s/^(?:'|")//; # "
            $uri =~ s/(?:'|")$//; # '
            $$css =~ s/^\)//;
        }
        else {
            $$css =~ s/^($RE_STRING)//;
            $uri = $1;
            $uri =~ s/^(?:'|")//; #"
            $uri =~ s/(?:'|")$//; #'
        }

        # a possible medialist
        my $medialist = $sac->parse_medialist($css);

        # we must have a terminating token now
        if ($$css =~ s/^\s*;//) {
            $sac->[_dh_]->import_style($uri,$medialist) if $sac->[_dh_can_]->{import_style};
        }
        else {
            if ($$css =~ s/[^;]*;//) {
                $sac->[_eh_]->warning('Unknown token in import rule');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in import rule');
            }
        }

        # remove comments and run again
        $sac->parse_comments($css);
    }
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_namespace_declarations($string_ref)
# parses ns declarations
#---------------------------------------------------------------------#
sub parse_namespace_declarations {
    my $sac = shift;
    my $css = shift;

    # we may have several ns decls separated by comments
    while ($$css =~ s/^\s*\@namespace\s+//i) {
        my ($prefix,$uri);
        # first get the prefix
        if ($$css !~ /^url\(/ and $$css =~ s/^($RE_IDENT)\s+//) {
            $prefix = $1;
        }

        # then get the uri
        if ($$css =~ s/^url\(//) {
            $$css =~ s/^((?:$RE_STRING)|([^\)]*))\s*//;
            $uri = $1;
            $uri =~ s/^(?:'|")//; # "
            $uri =~ s/(?:'|")$//; # '
            $$css =~ s/^\)//;
        }
        else {
            $$css =~ s/^($RE_STRING)//;
            $uri = $1;
            $uri =~ s/^(?:'|")//; #"
            $uri =~ s/(?:'|")$//; #'
        }

        # we must have a terminating token now
        if ($$css =~ s/^\s*;//) {
            # store the prefix-ns in our ns map
            my $map_prefix = $prefix;
            $map_prefix = '#default' unless $prefix;
            $sac->[_ns_map_]->{$map_prefix} = $uri;

            # throw a callback
            $prefix ||= '';
            $sac->[_dh_]->namespace_declaration($prefix,$uri) if $sac->[_dh_can_]->{namespace_declaration};
        }
        else {
            if ($$css =~ s/[^;]*;//) {
                $sac->[_eh_]->warning('Unknown token in namespace declaration');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in namespace declaration');
            }
        }

        # remove comments and run again
        $sac->parse_comments($css);
    }
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_medialist($string_ref)
# parses a list of media values
# returns that list as an arrayref
#---------------------------------------------------------------------#
sub parse_medialist {
    my $sac = shift;
    my $css = shift;

    # test for the right content and return a list if found
    return [] unless $$css =~ s/^\s*($RE_IDENT(?:\s*,\s*$RE_IDENT)*)//;
    return [map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_; } split /,/, $1];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_comments($string_ref)
# parses as many comments as there are at the beginning of the string
#---------------------------------------------------------------------#
sub parse_comments {
    my $sac = shift;
    my $css = shift;

    # we may have several comments in a row
    my $ws;
    while ($$css =~ s|^(\s*)/\*||) {
        $ws .= $1;
        if ($$css =~ s{^((?:(?:\\\\)|(?:\\[^\*])|(?:\\\*)|[^\\])*?)\*/}{}) {
            $sac->[_dh_]->comment($1) if $sac->[_dh_can_]->{comment};
        }
        else {
            if ($$css =~ s/.*\*\///) {
                $sac->[_eh_]->warning('Strange comment token, guessing the parse');
            }
            else {
                $sac->[_eh_]->fatal_error('Unterminated comment: unrecoverable');
            }
        }
    }

    # we need to keep the whitespace around for certain
    # occurences of comments, it may be significant
    $$css = $ws . $$css if defined $ws and defined $$css;
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_selector_list($string_ref)
# parses a list of selectors
# returns an array ref of selectors
#---------------------------------------------------------------------#
sub parse_selector_list {
    my $sac = shift;
    my $css = shift;

    # this is a long and hairy process
    my @sels;
    $$css =~ s/^\s*//;
    while (1) {

        # we've reached the rule, or there isn't anything left to parse
        if ($$css =~ m/^\s*\{/) {
            if (!@sels) {
                @sels = ($sac->[_sf_]->create_element_selector(undef,undef));
            }
            last;
        }

        elsif (!length $$css) {
            last;
        }

        # a simple selector
        elsif (my $sel = $sac->parse_simple_selector($css)) {
            push @sels, $sel;

            # delete the rest
            $sac->parse_comments($css);
            $$css =~ s/^\s*,\s*//;
            $sac->parse_comments($css);
            $$css =~ s/^\s*//;
        }

        # error
        else {
            # something wrong must have happened
            if ($$css =~ s/[^{]*//) {
                $sac->[_eh_]->warning('Unknown token in selector list');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in selector list');
            }
        }
    }

    return unless @sels; # this returns nothing, there were no selectors (needed for parse)
    return CSS::SAC::SelectorList->new(\@sels);
}
#---------------------------------------------------------------------#
*CSS::SAC::parseSelectors = \&parse_selector_list;


#---------------------------------------------------------------------#
# $sac->parse_simple_selector($string_ref)
# parses a simple selector
# returns the selector object
#---------------------------------------------------------------------#
sub parse_simple_selector {
    my $sac = shift;
    my $css = shift;

    $$css =~ s/^\s*//;

    ### eat the content piece by piece
    my @tokens;

    my ($attr,$func,$args);
    while (1) {

        $sac->parse_comments($css);

        # end of selector
        if ($$css =~ m/^\s*(?:,|{)/ or !length $$css) {
            last;
        }

        # element
        elsif ($$css =~ s/^(?:($RE_IDENT|\*)?(\|))?($RE_IDENT|\*)//) {
            # create element selector
            my ($ns,$lname);
            $lname = ($3 eq '*')?undef:$3;
            if (defined $2 and $2 eq '|') {
                if (!$1) {
                    $ns = ''; # |E matches elements in no namespace
                }
                elsif ($1 eq '*') {
                    $ns = undef; # undef means all, '' means default
                }
                else {
                    $ns = $sac->[_ns_map_]->{$1};
                }
            }
            else {
                # E matches elements in the default namespace or
                # any namespace if no default namespace is declared
                $ns = $sac->[_ns_map_]->{'#default'} || undef;
            }

            # push it
            push @tokens, $sac->[_sf_]->create_element_selector($ns,$lname);
        }

        # hash id
        elsif ($$css =~ s/^#($RE_NAME)//) {
            push @tokens, $sac->[_cf_]->create_id_condition($1);
        }

        # dot class
        elsif ($$css =~ s/^\.($RE_IDENT)//) {
            push @tokens, $sac->[_cf_]->create_class_condition(undef,$1);
        }

        # CSS3 pseudo-elements
        elsif ($$css =~ s/^::($RE_IDENT)//) {
            push @tokens, $sac->[_sf_]->create_pseudo_element_selector(undef,$1);
        }

        # [attr]
        elsif (
                (($attr,$$css,undef) = Text::Balanced::extract_bracketed($$css,q/[]'"/,qr/\s*/))
                and
                length $attr
              ) {
            $attr =~ s/^\[\s*//;
            $attr =~ s/\s*\]$//;

            # get the attr lname and ns
            $attr =~ s/^(?:($RE_IDENT|\*)?(\|))?($RE_IDENT|\*)//;
            my ($ns,$lname);
            $lname = ($3 eq '*')?undef:$3;
            if (defined $2 and $2 eq '|') {
                if (!$1) {
                    $ns = '' # [|a] matches attributes in no namespace;
                }
                elsif ($1 eq '*') {
                    $ns = undef; # undef means all, '' means default
                }
                else {
                    $ns = $sac->[_ns_map_]->{$1};
                }
            }
            else {
                $ns = ''; # [a] is equivalent to [|a]
            }

            # if there's more, parse on
            my ($op,$value);
            if (length $attr) {
                if ($attr =~ s/^((?:\^|\$|\*|\~|\|)?=)//) {
                    $op = $1;
                    $attr =~ s/^(?:'|")//; #"
                    $attr =~ s/(?:'|")$//; #"
                    $value = $attr;
                }
                else {
                    $sac->[_eh_]->warning('Unknown token in attribute condition');
            if ($$css =~ s/[^;]*;//) {
                $sac->[_eh_]->warning('Unknown token in import rule');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in import rule');
            }
                }
            }

            # create the right condition
            my $acond;
            if (!$op or $op eq '=') {
                my $spec = (defined $value)?1:0;
                $acond = $sac->[_cf_]->create_attribute_condition($lname,$ns,$spec,$value);
            }
            elsif ($op eq '^=') {
                $acond = $sac->[_cf_]->create_starts_with_attribute_condition($lname,$ns,1,$value);
            }
            elsif ($op eq '$=') {
                $acond = $sac->[_cf_]->create_ends_with_attribute_condition($lname,$ns,1,$value);
            }
            elsif ($op eq '*=') {
                $acond = $sac->[_cf_]->create_contains_attribute_condition($lname,$ns,1,$value);
            }
            elsif ($op eq '~=') {
                $acond = $sac->[_cf_]->create_one_of_attribute_condition($lname,$ns,1,$value);
            }
            elsif ($op eq '|=') {
                $acond = $sac->[_cf_]->create_begin_hyphen_attribute_condition($lname,$ns,1,$value);
            }

            push @tokens, $acond;
        }

        # :pseudo()
        elsif (
                ($args,$$css,$func) = Text::Balanced::extract_bracketed($$css,q/()'"/,qr/:$RE_IDENT/)
                and
                length $func
              ) {

            # cleanup the func and args
            $func =~ s/^://;
            $args =~ s/^\(\s*//;
            $args =~ s/\s*\)$//;
            $args =~ s/^(?:'|")//; #"
            $args =~ s/(?:'|")$//; #"

            # lang(lang_tag)
            if (lc ($func) eq 'lang') {
                push @tokens, $sac->[_cf_]->create_lang_condition($args);
            }

            # contains("text")
            elsif (lc ($func) eq 'contains') {
                push @tokens, $sac->[_cf_]->create_content_condition($args);
            }

            # not(selector)
            elsif (lc ($func) eq 'not') {
                my $sel = $sac->parse_simple_selector(\$args);
#                push @tokens, $sac->[_sf_]->create_negative_selector($sel);
                push @tokens, $sac->[_cf_]->create_negative_condition($sel);
            }

            # positional: nth-child, nth-last-child, nth-of-type, nth-last-of-type,
            elsif ($func =~ m/^nth-(last-)?((?:child)|(?:of-type))$/i) {
                my $pos = $args;
                my $of_type = (lc($2) eq 'of-type')?1:0;
                $pos = (lc($1) eq 'last-')?("-$pos"):($pos);
                # PositionalCondition will take care of parsing
                # the expressions, and will provide appropriate accessors
                push @tokens, $sac->[_cf_]->create_positional_condition($pos,$of_type,0);
            }

            # something else we don't know about
            else {
                push @tokens, $sac->[_cf_]->create_pseudo_class_condition(undef,$func);
            }
        }

        # :pseudo (not a function)
        elsif ($$css =~ s/^\:($RE_IDENT)//) {

            # root
            if (lc($1) eq 'root') {
                push @tokens, $sac->[_cf_]->create_is_root_condition;
            }

            # empty
            elsif (lc($1) eq 'empty') {
                push @tokens, $sac->[_cf_]->create_is_empty_condition;
            }

            # only-child
            elsif (lc($1) eq 'only-child') {
                my $fcond = $sac->[_cf_]->create_positional_condition(1,0,0);
                my $lcond = $sac->[_cf_]->create_positional_condition(-1,0,0);
                my $ocond = $sac->[_cf_]->create_and_condition($fcond,$lcond);
                push @tokens, $ocond;
            }

            # only-of-type
            elsif (lc($1) eq 'only-of-type') {
                my $fcond = $sac->[_cf_]->create_positional_condition(1,1,0);
                my $lcond = $sac->[_cf_]->create_positional_condition(-1,1,0);
                my $ocond = $sac->[_cf_]->create_and_condition($fcond,$lcond);
                push @tokens, $ocond;
            }

            # first-child
            elsif (lc($1) eq 'first-child') {
                push @tokens, $sac->[_cf_]->create_positional_condition(1,0,0);
            }

            # last-child
            elsif (lc($1) eq 'last-child') {
                push @tokens, $sac->[_cf_]->create_positional_condition(-1,0,0);
            }

            # first-of-type
            elsif (lc($1) eq 'first-of-type') {
                push @tokens, $sac->[_cf_]->create_positional_condition(1,1,0);
            }

            # last-of-type
            elsif (lc($1) eq 'last-of-type') {
                push @tokens, $sac->[_cf_]->create_positional_condition(-1,1,0);
            }

            # pseudo-elements in disguise
            elsif (
                    lc($1) eq 'first-line' or lc($1) eq 'first-letter' or
                    lc($1) eq 'selection'  or lc($1) eq 'before' or lc($1) eq 'after'
                   ) {
                push @tokens, $sac->[_sf_]->create_pseudo_element_selector(undef,lc($1));
            }

            # regular: link, visited, hover, active, focus, target, enabled, disabled,
            #          checked, indeterminate
            else {
                push @tokens, $sac->[_cf_]->create_pseudo_class_condition(undef,$1);
            }
        }

        # combinators
        elsif ($$css =~ s/^\s*((?:\+|>|~))\s*//) {
            push @tokens, $1;
        }

        # special case empty combinator
        elsif ($$css =~ s/^\s+//) {
            push @tokens, ' ';
        }

        # an error
        else {
            if (s/^.*?(,|{)/$1/) {
                $sac->[_eh_]->warning('Unknown token in simple selector');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in simple selector');
            }
        }
    }

    ### process the tokens list

    # if the first token isn't an element selector then create a *|* one
    # evaling is lame, but it's the only test I could think of
    eval { $tokens[0]->SelectorType };
    if ($@) {
        unshift @tokens, $sac->[_sf_]->create_element_selector(undef,undef);
    }

    # start looping over the tokens to reduce the list
    my $selector = shift @tokens;
    eval { $selector->SelectorType };
    if ($@) {
        # this is a serious exception
        $sac->[_eh_]->fatal_error('Really weird input in simple selector');
    }

# here we need to check whether the next token is also a selector
# if it is, we need to make an AND_CONDITION containing the two selectors
# and to attach it to a universal selector
# then we'll have to mix it into the $cond below.
    if (@tokens) {
        eval { $tokens[0]->SelectorType };
        if (!$@) {
            my $and_cond = $sac->[_cf_]->create_and_condition($selector,shift @tokens);
            $selector = $sac->[_sf_]->create_element_selector(undef,undef);
        }
    }


    # create a conditional selector with all conditions
    my $cond = $sac->build_condition(\@tokens);
    if ($cond) {
        $selector = $sac->[_sf_]->create_conditional_selector($selector,$cond);
    }

    while (@tokens) {

        # here there should be a combinator or nothing
        my $comb = shift @tokens;
        if ($comb) {
            # pretty serious error
            $sac->[_eh_]->fatal_error('Really weird input in simple selector') if ref $comb;

            # get the next selector
            my $new_selector = shift @tokens;
            eval { $new_selector->SelectorType };
            if ($@) {
#                last unless length $new_selector;
                if (ref $new_selector) {
                    unshift @tokens, $new_selector;
                    $new_selector = $sac->[_sf_]->create_element_selector(undef,undef);
                }
                else {
                    # this is a serious exception (we don't know what's here)
                    $sac->[_eh_]->fatal_error('Really weird input in simple selector: "' . $$css . '"');
                }
            }

            # create a conditional selector with all conditions
            my $cond = $sac->build_condition(\@tokens);
            if ($cond) {
                $new_selector = $sac->[_sf_]->create_conditional_selector($new_selector,$cond);
            }

            # various possible combinators
            if ($comb eq ' ') {
                $selector = $sac->[_sf_]->create_descendant_selector($selector,$new_selector);
            }
            elsif ($comb eq '>') {
                $selector = $sac->[_sf_]->create_child_selector($selector,$new_selector);
            }
            elsif ($comb eq '+') {
                $selector = $sac->[_sf_]->create_direct_adjacent_selector(
                                                                          ELEMENT_NODE,
                                                                          $selector,
                                                                          $new_selector
                                                                         );
            }
            elsif ($comb eq '~') {
                $selector = $sac->[_sf_]->create_indirect_adjacent_selector(
                                                                            ELEMENT_NODE,
                                                                            $selector,
                                                                            $new_selector
                                                                           );
            }
        }
    }

    return $selector;
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->build_condition(\@tokens)
# helper to build conditions
#---------------------------------------------------------------------#
sub build_condition {
    my $sac = shift;
    my $tokens = shift;

    # get all conditions
    my @conditions;
    while (@$tokens) {
#        eval { $tokens->[0]->SelectorType };
#        if (not $@) {
#            $sac->[_eh_]->fatal_error('Really weird input in simple selector');
#        }
        last if ! ref $tokens->[0];
        push @conditions, shift @$tokens;
    }

    # build a single condition out of the others
    my $cond;
    if (@conditions) {
        $cond = shift @conditions;
        for my $c (@conditions) {
            $cond = $sac->[_cf_]->create_and_condition($cond,$c);
        }
    }

    return $cond;
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $sac->parse_rule($string_ref)
# parses a rule (with { and })
#---------------------------------------------------------------------#
sub parse_rule {
    my $sac = shift;
    my $css = shift;
    return unless defined $$css;

    # remove { and }, and parse the content
    $$css =~ s/^\s*{//;
    $$css =~ s/}\s*$//;
    warn "[SAC] removed curlies\n" if DEBUG;
    $sac->parse_style_declaration($css);
}
#---------------------------------------------------------------------#
*CSS::SAC::parseRule = \&parse_rule;


#---------------------------------------------------------------------#
# $sac->parse_style_declaration($string_ref)
# same as parse_rule, but without the { and }. Cool for HTML, SVG...
#---------------------------------------------------------------------#
sub parse_style_declaration {
    my $sac = shift;
    my $css = shift;

    # take those prop-val one by one
    $sac->parse_comments($css);
    $$css =~ s/^\s*//;
    while (length $$css) {
        # the property
        $$css =~ s/^(-?$RE_IDENT)\s*//; # includes the - prefix
        my $prop = $1;
        $sac->parse_comments($css);

        # the separator
        $$css =~ s/^\s*:\s*//;
        $sac->parse_comments($css);

        # the value
        my $lu = $sac->parse_property_value($css);
        if (!@$lu) {
            last unless length $$css;
            if ($$css =~ s/[^;}]*(?:;|\})?//) { # this is a bit dodgy...
                $sac->[_eh_]->warning('Unknown token in style declaration');
            }
            else {
                $sac->[_eh_]->fatal_error('Unknown token in style declaration: "' . $$css . '"');
            }
            next;
        }
        $sac->parse_comments($css);

        # the priority
        my $prio = $sac->parse_priority($css);
        $sac->parse_comments($css);

        # the terminator
        $$css =~ s/^\s*;\s*//;

        # callback
        $prio ||= 0;
        $sac->[_dh_]->property($prop,$lu,$prio) if $sac->[_dh_can_]->{property};

        # remove cruft
        $sac->parse_comments($css);
        $$css =~ s/^\s*//;
    }
}
#---------------------------------------------------------------------#
*CSS::SAC::parseStyleDeclaration = \&parse_style_declaration;


#---------------------------------------------------------------------#
# $sac->parse_property_value($string_ref)
# parses a value
# returns an array ref of lexical units
#---------------------------------------------------------------------#
sub parse_property_value {
    my $sac = shift;
    my $css = shift;
    my $att = shift || 0;

    $$css =~ s/^\s*//;

    # parse it by value chunks
    my @lus;
    while (1) {
        my ($type,$text,$value);

        $sac->parse_comments($css);

        # exit conditions
        if (! length($$css) or $$css =~ m/^\s*(?:;|!)/ or ($att and $$css =~ s/^\s*(?:\))//)) {
            last;
        }

        # ops
        elsif ($$css =~ s{^\s*(,|/)\s*}{}) {
            $value = $1;
            if ($value eq ',') {
                $type = OPERATOR_COMMA;
                $text = 'comma';
            }
            else {
                $type = OPERATOR_SLASH;
                $text = 'slash';
            }
        }

        # special case empty op
        elsif ($$css =~ s{^\s+}{}) {
            next;
        }

        # inherit
        elsif ($$css =~ s/^inherit//) {
            $type = INHERIT;
            $text = 'inherit';
            $value = undef;
        }

        # lengths and assoc
        elsif ($$css =~ s/^((?:\+|-)?$RE_NUM)
                           (em|ex|px|cm|mm|in|pt|pc|deg|rad|grad|ms|s|hz|khz|%)
                         //xi) {
            $value = $1;
            $text = lc $2;
            $type = $DIM_MAP{$text};
        }

        # dimension
        elsif ($$css =~ s/^((?:\+|-)?$RE_NUM)($RE_IDENT)//) {
            $value = $1;
            $text = lc $2;
            $type = DIMENSION;
        }

        # number
        elsif ($$css =~ s/^((?:\+|-)?$RE_NUM)//) {
            $value = $1;
            $text = 'number';
            if ($value =~ m/\./) {
                $type = REAL;
            }
            else {
                $type = INTEGER;
            }
        }

        # unicode range
        elsif ($$css =~ s/^($RE_RANGE)//) {
            $value = $1;
            $text = 'unicode-range';
            $type = UNICODERANGE;
        }

        # hex rgb
        elsif ($$css =~ s/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})//) {
            $value = $1;
            $text = '#';
            $type = RGBCOLOR;
        }

        # functions
#        elsif (
#                ($value,$$css,$text) = Text::Balanced::extract_bracketed($$css,q/()'"/,qr/$RE_IDENT/)
#                and
#                length $text
#              ) {
        elsif ($$css =~ s/^($RE_IDENT)\(//) {

            # cleanup the func and args
#            $text = lc $text;
#            $value =~ s/^\(\s*//;
#            $value =~ s/\s*\)$//;
#            $value =~ s/^(?:"|')//; #"
#            $value =~ s/(?:"|')$//; #"
            $text = lc $1;
            $value = $sac->parse_property_value($css, 1);

            # get the appropriate type
            if ($FUNC_MAP{$text}) {
                $type = $FUNC_MAP{$text};
            }
            else {
                $type = FUNCTION;
            }
        }

        # ident
        elsif ($$css =~ s/^($RE_IDENT)//) {
            $value = $1;
            $text = 'ident';
            $type = IDENT;
        }

        # string
        elsif ($$css =~ s/^($RE_STRING)//) {
            $value = $1;
            $value =~ s/^(?:"|')//; #"
            $value =~ s/(?:"|')$//; #"
            $text = 'string';
            $type = STRING_VALUE;
        }

        # error
        else {
            return [];
        }

        # add a lu
        push @lus, CSS::SAC::LexicalUnit->new($type,$text,$value);
    }

    return \@lus;
}
#---------------------------------------------------------------------#
*CSS::SAC::parsePropertyValue = \&parse_property_value;


#---------------------------------------------------------------------#
# $sac->parse_priority($string_ref)
# parses a priority
# returns true if there is a priority value there
#---------------------------------------------------------------------#
sub parse_priority {
    my $sac = shift;
    my $css = shift;

    return 1 if $$css =~ s/^\s*!\s*important//i;
}
#---------------------------------------------------------------------#
*CSS::SAC::parsePriority = \&parse_priority;


#                                                                     #
#                                                                     #
### Parsing Methods ###################################################



### Default Error Handler #############################################
#                                                                     #
#                                                                     #

# This is pretty much a non package, it is just there to provide the
# default error handler.

package CSS::SAC::DefaultErrorHandler;

sub new         { return bless [], __PACKAGE__; }
sub warning     { warn "[warning] $_[1] (line " . (caller)[2] . ")";       }
sub error       { warn "[error] $_[1] (line " . (caller)[2] . ")";         }
sub fatal_error { die  "[fatal] $_[1] (line " . (caller)[2] . ")";         }


#                                                                     #
#                                                                     #
### Default Error Handler #############################################



1;

=pod

=head1 NAME

CSS::SAC - SAC CSS parser

=head1 SYNOPSIS

  use CSS::SAC qw();
  use My::SACHandler ();
  use My::SACErrors ();

  my $doc_handler = My::SACHandler->new;
  my $err_handler = My::SACErrors->new;
  my $sac = CSS::SAC->new({
                           DocumentHandler => $doc_handler,
                           ErrorHandler    => $err_handler,
                         });

  # generate a stream of events
  $sac->parse({ filename => 'foo.css' });

=head1 DESCRIPTION

SAC (Simple API for CSS) is an event-based API much like SAX for XML.
If you are familiar with the latter, you should have little trouble
getting used to SAC. More information on SAC can be found online at
http://www.w3.org/TR/SAC.

CSS having more constructs than XML, core SAC is still more complex
than core SAX. However, if you need to parse a CSS style sheet, SAC
probably remains the easiest way to get it done.

Most of the spec is presently implemented. The following interfaces
are not yet there: Locator, CSSException, CSSParseException,
ParserFactory. They may or may not be implemented at a later date
(the most likely candidates are the exception classes, for which I
still have to find an appropriate model).

Some places differ slightly from what is in the spec. I have tried to
keep those to a justified minimum and to flag them correctly.

=head2 the CSS::SAC module itself

The Parser class doesn't exist separately, it's defined in CSS::SAC.
It doesn't expose the locale interface because we don't localize
errors (yet). It also doesn't have C<parse_style_sheet> but rather
C<parse>, which is more consistent with other Perl parsing interfaces.

I have added the C<charset($charset)> callback to the DocumentHandler
interface. There are valid reasons why it wasn't there (it can be
trusted only ever so often, and one should look at the actual encoding
instead) but given that it's a token in the grammar, I believe that
there should still be a way to access it.

=head1 METHODS

=over 4

=item * CSS::SAC->new(\%options) or $sac->new(\%options)

Constructs a new parser object. The options can be:

 - ConditionFactory and SelectorFactory
    the factory classes used to build selector and condition objects.
    See CSS::SAC::{Condition,Selector}Factory for more details on the
    interfaces those classes must expose.

 - DocumentHandler and ErrorHandler
    the handler classes used as sinks for the event stream received
    from a SAC Driver. See CSS::SAC::{Document,Error}Factory for more
    details on the interfaces those classes must expose.

Methods will be called on whatever it is you pass as values to those
options. Thus, you may pass in objects as well as class names (I
haven't tested this yet, there may be a problem).

NOTE: an error handler should implement all callbacks, while a document
handler may only implement those it is interested in. There is a default
error handler (which dies and warns depending on the type of error) but
not default document handler.

=item * $sac->ParserVerion or $sac->getParserVerion

Returns the supported CSS version.

Requesting this parser's ParserVersion will return the string 'CSS3'.
While that is (modulo potential bugs of course) believed to be
generally true, several caveats apply:

To begin with, CSS3 has been modularised, and various modules are at
different stages of development. Evolving modules may require evolving
this parser. I hesitated between making ParserVersion return CSS2,
CSS3-pre, or simply CSS3. I chose the latter because I intend to
update it as I become aware of the necessity of changes to accommodate
new CSS3 stuff, and because it already supports a number of constructs
alien to CSS2 (of which namespaces is imho important enough to justify
a CSS3 tag). If you are aware of incompatibilities, please contact me.

More importantly, it is now considered wrong for a parser to return
CSSx as its version and instead it is expected to return an uri
corresponding to the uri of the CSS version that it supports. However,
there is no uri for CSS3, but instead one uri per module. While this
issue hasn't been resolved by the WG, I will stick to returning CSS3.
However, B<the behaviour of this attribute is certain to change> in
the future, so please avoid relying on it.

=item * $cf = $sac->ConditionFactory

=item * $sac->ConditionFactory($cf) or $sac->setConditionFactory($cf)

=item * $cf = $sac->SelectorFactory

=item * $sac->SelectorFactory($sf) or $sac->setSelectorFactory($sf)

=item * $cf = $sac->DocumentHandler

=item * $sac->DocumentHandler($dh) or $sac->setDocumentHandler($dh)

=item * $cf = $sac->ErrorHandler

=item * $sac->ErrorHandler($eh) or $sac->setErrorHandler($eh)

get/set the ConditionFactory, SelectorFactory, DocumentHandler,
ErrorHandler that we use

=item * $sac->parse(\%options)

=item * $sac->parseStyleSheet(\%options)

parses a style sheet and sends events to the defined handlers. The
options that you can use are:

=over 8

=item * string

=item * ioref

=item * filename

passes either a string, an open filehandle, or a filename to read the
stylesheet from

=item * embedded

tells whether the stylesheet is embedded or not. This is most of the
time useless but it will influence the interpretation of @charset
rules. The latter being forbidden in embedded style sheets they will
generate an ignorable_style_sheet event instead of a charset event if
embedded is set to a true value.

=back

=item * $sac->parse_rule($string_ref)

=item * $sac->parseRule($string_ref)

parses a rule (with { and }). You probably don't need this one. It
returns nothing, but generates the events.

=item * $sac->parse_style_declaration($string_ref)

=item * $sac->parseStyleDeclaration($string_ref)

same as parse_rule, but without the { and }. This is useful when you
want to parse style declarations embedded using style attributes in
HTML, SVG, etc... It returns nothing, but generates the events.

=item * $sac->parse_property_value($string_ref)

=item * $sac->parsePropertyValue($string_ref)

parses a property value and returns an array ref of lexical units
(see CSS::SAC::LexicalUnit)

=item * $sac->parse_priority($string_ref)

=item * $sac->parsePriority($string_ref)

parses a priority and returns true if there is a priority value there.

=item * $sac->parse_selector_list($string_ref)

=item * $sac->parseSelectors($string_ref)

parses a list of selectors and returns an array ref of selectors

=back

=head1 OTHER METHODS

Methods in this section are of relevance mostly to the internal
workings of the parser. I document them here but I don't really
consider them part of the interface, and thus may change them if need
be. If you are using them directly tell me about it and I will
"officialize" them. These have no Java style equivalent.

=over 4

=item * $sac->parse_charset($string_ref)

parses a charset. It returns nothing, but generates the events.

=item * $sac->parse_imports($string_ref)

parses import rules. It returns nothing, but generates the events.

=item * $sac->parse_namespace_declarations($string_ref)

parses ns declarations. It returns nothing, but generates the events.

=item * $sac->parse_medialist($string_ref)

parses a list of media values and returns that list as an arrayref

=item * $sac->parse_comments($string_ref)

parses as many comments as there are at the beginning of the string.
It returns nothing, but generates the events.

=item * $sac->parse_simple_selector($string_ref)

parses a simple selector and returns the selector object

=item * $sac->build_condition(\@tokens)

helper to build conditions (you probably don't want to use this at
all...)

=back

=head1 CSS::SAC::DefaultErrorHandler

This is pretty much a non package, it is just there to provide the
default error handler if you are too lazy to provide one yourself.

All it does is pretty simple. There are three error levels:
C<warning>, C<error>, and C<fatal_error>. What it does is warn on the
two first and die on the last. Yes, it ain't fancy but then you can
plug anything more intelligent into it at any moment.


=head1 CSS3 ISSUES

One problem is that I have modelled this parser after existing SAC
implementations that do not take into account as much of CSS3 as it is
possible to. Some parts of that are trivial, and I have provided
support on my own in this module. Other parts though are more
important and I believe that coordination between the SAC authors
would be beneficial on these points (once the relevant CSS3 modules
will have moved to REC).

=over 4

=item * new attribute conditions

CSS3-selectors introduces a bunch of new things, including new
attribute conditions ^= (starts with), $= (ends with) and *=
(contains). There are no corresponding constants for conditions, so I
suggested SAC_STARTS_WITH_ATTRIBUTE_CONDITION,
SAC_ENDS_WITH_ATTRIBUTE_CONDITION, SAC_CONTAINS_ATTRIBUTE_CONDITION.

Note that these constants have been added, together with the
corresponding factory methods. However, they will remain undocumented
and considered experimental until some consensus is reached on the
matter.

=item * :root condition

The :root token confuses some people because they think it is
equivalent to XPath's / root step. That is not so. XPath's root
selects "above" the document element. CSS's :root tests whether an
element is the document element, there is nothing above a document
element. Thus :root on its own is equivalent to *:root. It's a
condition, not a selector. E:root matches the E element that is also
the document element (if there is one).

Thus, SAC_ROOT_NODE_SELECTOR does not apply and we need a new
SAC_IS_ROOT_CONDITION constant.

Note that this constant has been added, together with the
corresponding factory method. However, it will remain undocumented
and considered experimental until some consensus is reached on the
matter.

=item * other new pseudo-classes

:empty definitely needs a constant too I'd say.

Note that this constant has been added, together with the
corresponding factory method. However, it will remain undocumented
and considered experimental until some consensus is reached on the
matter.

=item * an+b syntax in positional conditions

There is new syntax that allows for very customisable positional
selecting. PositionalCondition needs to be updated to deal with that.

=back

=head1 BUGS

 - the problem with attaching pseudo-elements to elements as
 coselectors. I'm not sure which is the right representation. Don't
 forget to update CSS::SAC::Writer too so that it writes it out
 properly.

 - see Bjoern's list

=head1 ACKNOWLEDGEMENTS

 - Bjoern Hoehrmann for his immediate reaction and much valuable
 feedback and suggestions. It's certainly much harder to type with all
 those fingers that all those Mafia padres have cut off, but at least
 I get work done much faster than before. And also those nasty bugs he
 kindly uncovered.

 - Steffen Goeldner for spotting bugs and providing patches.

 - Ian Hickson for very very very kind testing support, and all sorts
 of niceties.

 - Manos Batsis for starting a very long discussion on this that
 eventually deviated into other very interesting topics, and for
 giving me some really weird style sheets to feed into this module.

 - Simon St.Laurent for posting this on xmlhack.com and thus pointing a
 lot of people to this module (as seen in my referer logs).

And of course all the other people that have sent encouragement notes
and feature requests.

=head1 TODO

 - add a pointer to the SAC W3 page

 - create the Exception classes

 - update PositionalCondition to include logic that can normalize the
 an+n notation and add a method that given a position will return a
 boolean indicating whether it matches the condition.

 - add stringify overloading to all classes so that they may be
 printed directly

 - have parser version return an overloaded object that circumvents the
 current problems

 - add docs on how to write a {Document,Error}Handler, right now there
 is example code in Writer, but it isn't all clearly explained.

 - find a way to make the '-' prefix to properties optional

 - add a filter that switches events to spec names, and that can be used
 directly through an option

 - add DOM-like hasFeature support (in view of SAC 3)

 - prefix all constants with SAC_. Keep the old ones around for a few 
 versions, importable with :old-constants.

 - update docs

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut
