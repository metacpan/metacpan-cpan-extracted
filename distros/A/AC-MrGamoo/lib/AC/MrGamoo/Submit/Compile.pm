# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Oct-27 17:39 (EDT)
# Function: compile job component
#
# $Id: Compile.pm,v 1.1 2010/11/01 18:42:00 jaw Exp $

package AC::MrGamoo::Submit::Compile;
use AC::MrGamoo::Submit::Compile::Block;
use strict;

my %COMPILE = (
    config	=> { tag => 'config',  multi => 1, },
    doc 	=> { tag => 'block',   multi => 1, },
    init	=> { tag => 'block',   multi => 0, },
    common	=> { tag => 'simple',  multi => 0, },
    map		=> { tag => 'block',   multi => 0, required => 1, },
    reduce	=> { tag => 'block',   multi => 1, required => 1, },
    final	=> { tag => 'block',   multi => 0, },
    readinput	=> { tag => 'block',   multi => 0, },
    filefilter	=> { tag => 'block',   multi => 0, },
    );

my %BLOCK = (
    init	=> 'simple',
    cleanup	=> 'simple',
    attr	=> 'config',
   );

sub new {
    my $class = shift;

    my $me = bless {
        @_,
        # file | text
    }, $class;

    if( $me->{file} ){
        open(my $fd, $me->{file}) || $me->_die("cannot open file: $!");
        local $/ = undef;
        $me->{text} = <$fd>;
        close $fd;
    }
    $me->{lines} = [ split /^/m, $me->{text} ];

    $me->_compile();
    $me->_check();

    return $me;
}

sub compile {
    my $me   = shift;
    my $name = shift;
    my $num  = shift;

    my $b = $me->{content}{$name};
    return unless $b;
    $b = $b->[$num] if defined($num) && ref($b);

    return $b->compile( $me->{content}{common} );
}

sub src {
    my $me = shift;
    return $me->{_file_content};
}

sub get_code {
    my $me   = shift;
    my $name = shift;
    my $num  = shift;

    my $prog = $me->compile( $name, $num );
    return unless $prog;

    my $c = eval $prog;
    die $@ if $@;

    return $c;
}

sub _die {
    my $me  = shift;
    my $err = shift;

    if( $me->{_lineno} ){
        die "ERROR: $err\nfile: $me->{file} line: $me->{_lineno}\n$me->{_line}\n";
    }
    die "ERROR: $err\nfile: $me->{file}\n";
}

sub _next {
    my $me = shift;

    return unless @{ $me->{lines} };
    $me->{_line} = shift @{ $me->{lines} };
    $me->{_lineno} ++;
    $me->{_file_content} .= $me->{_line};
    return $me->{_line};
}

sub _compile {
    my $me = shift;

    while(1){
        my $line = $me->_next();
        last unless defined $line;
        chomp $line;

        # white, comment, or start
        $line =~ s/^%#.*//;
        $line =~ s/#.*//;
        next if $line =~ /^\s*$/;

        my($tag) = $line =~ m|^<%(.*)>\s*$|;
        my $d    = $COMPILE{$tag};

        if( $d->{tag} eq 'block'){
            $me->_add_block($tag, $me->_compile_block($tag));
        }
        elsif( $d->{tag} eq 'simple' ){
            $me->_add_block($tag, $me->_compile_block_simple($tag));
        }
        elsif( $d->{tag} eq 'config' ){
            $me->_add_config($tag, $me->_compile_config($tag));
        }
        else{
            $me->_die("syntax error");
        }
    }

    delete $me->{_lineno};
    delete $me->{_line};
    delete $me->{_fd};

    1;
}

sub _lineno_info {
    my $me  = shift;

    # should have the number of the _next_ line
    return sprintf "#line %d $me->{file}\n", $me->{_lineno} + 1;
}

sub _compile_block {
    my $me  = shift;
    my $tag = shift;

    my $b = AC::MrGamoo::Submit::Compile::Block->new();

    $b->{code} = $me->_lineno_info();

    while(1){
        my $line = $me->_next();
        $me->_die("end of file reached looking for end of $tag section") unless defined $line;
        last if $line =~ m|^</%$tag>\s*$|;

        my($tag) = $line =~ m|^<%(.*)>\s*$|;

        if( $BLOCK{$tag} eq 'simple' ){
            $b->{$tag} .= $me->_compile_block_simple( $tag );
            $b->{code} .= $me->_lineno_info();
        }elsif( $BLOCK{$tag} eq 'config' ){
            $b->{$tag} = $me->_compile_config( $tag );
        }elsif( $tag ){
            $me->_die("syntax error");

        }else{
            $b->{code} .= $line;
        }
    }

    return $b;
}

sub _compile_block_simple {
    my $me  = shift;
    my $tag = shift;

    my $b = $me->_lineno_info();

    while(1){
        my $line = $me->_next();
        $me->_die("end of file reached looking for end of $tag section") unless defined $line;
        last if $line =~ m|^</%$tag>\s*$|;
        $b .= $line;
    }

    return $b;
}

sub _compile_config {
    my $me  = shift;
    my $tag = shift;

    my $c = {};

    while(1){
        my $line = $me->_next();
        $me->_die("end of file reached looking for end of '$tag' section") unless defined $line;
        return $c if $line =~ m|^</%$tag>\s*$|;

        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        my($k, $v) = split /\s+=>\s*/, $line, 2;
        $c->{$k} = $v;
    }
}

sub _add_block {
    my $me  = shift;
    my $tag = shift;
    my $blk = shift;

    my $d = $COMPILE{$tag};

    if( $d->{multi} ){
        push @{$me->{content}{$tag}}, $blk;
    }else{
        $me->_die("redefinition of '$tag' section") if $me->{content}{$tag};
        $me->{content}{$tag} = $blk;
    }
}

sub add_config {
    my $me  = shift;
    my $cfg = shift;

    $me->_add_config('config', $cfg);
}

sub _add_config {
    my $me  = shift;
    my $tag = shift;
    my $cfg = shift;

    my $d = $COMPILE{$tag};

    if( $d->{multi} ){
        # merge
        @{ $me->{content}{$tag} }{ keys %$cfg } = values %$cfg;
    }else{
        $me->_die("redefinition of '$tag' section") if $me->{content}{$tag};
        $me->{content}{$tag} = $cfg;
    }
}

sub set_initres {
    my $me = shift;
    my $ir = shift;

    $me->{initres} = $ir;
}

sub set_config {
    my $me  = shift;
    my $cfg = shift;

    $me->{content}{config} = $cfg;
}

sub get_config_param {
    my $me = shift;
    my $k  = shift;

    return $me->{content}{config}{$k};
}

sub set_config_param {
    my $me = shift;
    my $k  = shift;
    my $v  = shift;

    return $me->{content}{config}{$k} = $v;
}

sub _check {
    my $me = shift;

    for my $s (keys %COMPILE){
        next unless $COMPILE{$s}{required};
        next if $me->{content}{$s};
        $me->_die("missing required section '$s'");
    }
    1;
}


1;
