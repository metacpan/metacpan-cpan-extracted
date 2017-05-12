package Catalyst::View::ByCode::Declare;
$Catalyst::View::ByCode::Declare::VERSION = '0.28';
use strict;
use warnings;

use Devel::Declare();
use B::Hooks::EndOfScope;

###### Thanks #####################################################
#                                                                 #
# Thanks to Kang-min Liu for doing 'Markapl.pm'                   #
# most of the concepts here are 'borrowed' from this great module #
# sorry for copying instead of thinking.                          #
#                                                                 #
#################################################### /Thanks ######

# these variables will get local()'ized during a parser run
our ($Declarator, $Offset);

####################################### SCANNERs
#
# skip space symbols (if any)
#
sub skip_space {
    $Offset += Devel::Declare::toke_skipspace($Offset);
}

#
# skip the sub_name just parsed (is still in $Declarator)
#
sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

#
# skip a word and return it -- or undef if no word found
#
sub skip_word {
    skip_space;
    
    if (my $length = Devel::Declare::toke_scan_word($Offset, 1)) {
        my $linestr = Devel::Declare::get_linestr;
        $Offset += $length;
        return substr($linestr,$Offset-$length, $length);
    }
    return;
}

#
# non-destructively read next character
#
sub next_char {
    skip_space;
    my $linestr = Devel::Declare::get_linestr;
    return substr($linestr, $Offset, 1);
}

#
# non-destructively read next word (=token)
#
sub next_word {
    skip_space;
    
    if (my $length = Devel::Declare::toke_scan_word($Offset, 1)) {
        my $linestr = Devel::Declare::get_linestr;
        return substr($linestr, $Offset, $length);
    }
    return '';
}

#
# destructively read a valid name if possible
#
sub strip_name {
    skip_space;
    
    if (my $length = Devel::Declare::toke_scan_word($Offset, 1)) {
        return inject('', $length);
    }
    return;
}

#
# destructively read a possibly dash-separated name
#
sub strip_css_name {
    my $name = strip_name;
    while (next_char eq '-') {
        inject('', 1);
        $name .= '-';
        if (next_char =~ m{\A[a-zA-Z0-9_]}xms) {
            $name .= strip_name;
        }
    }
    
    return $name;
}

#
# read a prototype-like definition (looks like '(...)')
#
sub strip_proto {
    if (next_char eq '(') {
        my $length = Devel::Declare::toke_scan_str($Offset);
        my $proto = Devel::Declare::get_lex_stuff();
        Devel::Declare::clear_lex_stuff();
        inject('', $length);
        return $proto;
    }
    return;
}

#
# helper: check if a declarator is in a hash key
#
sub declarator_is_hash_key {
    my $offset_before = $Offset;
    skip_declarator;
    
    # This means that current declarator is in a hash key.
    # Don't shadow sub in this case
    return ($Offset == $offset_before);
}

#
# parse: id?   ('.' class)*   ( '(' .* ')' )?
#
sub parse_tag_declaration {
    # collect ID, class and (...) staff here...
    # for later injection into top of block
    my $extras = '';
    
    # check for an indentifier (ID)
    if (next_char =~ m{\A[a-zA-Z0-9_]}xms) {
        # looks like an ID
        my $name = strip_css_name;
        $extras .= " id => '$name',";
    }
    
    # check for '.class' as often as possible
    my @class;
    while (next_char eq '.') {
        # found '.' -- eliminate it and read name
        inject('',1);
        push @class, strip_css_name;
    }
    if (scalar(@class)) {
        $extras .= " class => '" . join(' ', @class) . "',";
    }
    
    #
    # see if we have (...) stuff
    #
    my $proto = strip_proto;
    if ($proto) {
        ###
        ### BAD HACK: multiline (...) things will otherwise fail
        ###           must be very tolerant!
        ###
        $proto =~ s{\s*[\r\n]\s*}{}xmsg;
        
        $extras .= " $proto,";
    }
    
    if ($extras) {
        if (next_char eq '{') {
            # block present -- add after block
            inject_after_block($extras);
        } else {
            # no block present -- fake a block and add after it
            inject(" {} $extras");
        }
    }
}

####################################### INJECTORs
#
# inject something at current position
#  - with optional length
#  - at optional offset
# returns thing at inserted position before
#
sub inject {
    my $inject = shift;
    my $length = shift || 0;
    my $offset = shift || 0;

    my $linestr  = Devel::Declare::get_linestr;
    my $previous = substr($linestr, $Offset+$offset, $length);
    substr($linestr, $Offset+$offset, $length) = $inject;
    Devel::Declare::set_linestr($linestr);
    
    return $previous;
}

#
# inject something at top of a '{ ...}' block
# returns: boolean depending on success
#
sub inject_into_block {
    my $inject = shift;
    
    if (next_char eq '{') {
        inject($inject,0,1);
        return 1;
    }
    return 0;
}

#
# inject something before a '{ ...}' block
# returns: boolean depending on success
#
sub inject_before_block {
    my $inject = shift;
    
    if (next_char eq '{') {
        inject($inject);
        return 1;
    }
    
    return 0;
}

#
# inject something after scope as soon as '}' is reached
#
our @thing_to_inject;

sub inject_after_block { # called from a parser
    my $inject = shift;
    push @thing_to_inject, $inject;
    
    # force calling the sub below as soon as block's scope is done.
    inject_into_block(qq{ BEGIN { Catalyst::View::ByCode::Declare::post_block_inject }; });
}

sub post_block_inject { # called from a BEGIN {} block at scope start
    my $inject = pop @thing_to_inject;

    on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        my $offset = Devel::Declare::get_linestr_offset;
        
        substr($linestr, $offset, 0) = $inject;
        Devel::Declare::set_linestr($linestr);
    };
}

####################################### ADD SUBs
#
# put modified sub into requested package
#
sub install_sub {
    my $sub_name = shift;
    my $code = shift;
    my $add_to_array = shift;

    my $package = Devel::Declare::get_curstash_name;

    no strict 'refs';
    no warnings 'redefine';
    ### deleting does not warn, but aliassing is still in action
    # http://www252.pair.com/comdog/mastering_perl/Chapters/08.symbol_tables.html
    # delete ${"$package\::"}{$sub_name};
    *{"$package\::$sub_name"} = $code;
    # cannot modify: *{"$package\::$sub_name"}{CODE} = $code;
    push @{"$package\::EXPORT"}, $sub_name;
    push @{"$package\::$add_to_array"}, $sub_name if ($add_to_array);
    ### right?? push @{"$package\::$EXPORT_TAGS\{default\}"}, $sub_name;
}

####################################### PARSERs
#
# generate a tag-parser
# initiated after compiling a tag subroutine
# parses: tag   id?   ('.' class)*   ( '(' .* ')' )?
# injects some magic after the block following the declaration
#
sub tag_parser {
    return sub {
        local ($Declarator, $Offset) = @_;
        return if (declarator_is_hash_key);
        
        # parse the id.class() {} declaration
        parse_tag_declaration;
    };
}

#
# add a tag parser
#
sub add_tag_parser {
    my $sub_name = shift;
    
    my $package = Devel::Declare::get_curstash_name;
    
    Devel::Declare->setup_for($package,
                              {
                                  $sub_name => {
                                      const => tag_parser
                                  }
                              });
}

#
# generate a block-parser
# initiated after compiling 'block'
# parses: 'block' name '{'
# injects ' => sub' after name
# always installs a parser for block() calls.
#
sub block_parser {
    return sub {
        local ($Declarator, $Offset) = @_;
        return if (declarator_is_hash_key);

        my $sub_name;
        if (next_word =~ m{\A [a-zA-Z_]\w* \z}xms) {
            # skip the block_name to append a '=> sub' afterwards
            $sub_name = skip_word;
            if (next_char eq '{') {
                inject(' => sub ');
                $Offset += 8;
            }
        } else {
            # take the next string we find as sub_name
            # silently assume correct perl-syntax
            Devel::Declare::toke_scan_str($Offset);
            $sub_name = Devel::Declare::get_lex_stuff();
            Devel::Declare::clear_lex_stuff();
        }
        
        # insert a preliminary sub named $sub_name 
        # into the caller's namespace to make compiler happy
        # and to allow calling the sub without ()'s
        install_sub($sub_name => sub(;&@) {}, 'EXPORT_BLOCK');
        add_tag_parser($sub_name);
    };
}

1;
