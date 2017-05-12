use strict;
use warnings;
package Comment::Block;
use Filter::Util::Call;

$Comment::Block::VERSION = "0.01";

#ABSTRACT: Comment::Block - Makes Block Comments Possible

sub import {
    my ($type) = @_;
    my (%context) = (
        _inBlock => 0,
        _filename => (caller)[1],
        _line_no => 0,
        _last_begin => 0,
    );
    filter_add(bless \%context);
}

sub error {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    die "Error: $message at $self->{_filename} line $line_no.\n"
}

sub warning {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    warn "Warning: $message at $self->{_filename} line $line_no.\n"   
}

sub filter {
    my ($self) = @_;
    my ($status);
    $status = filter_read();
    ++ $self->{LineNo};
    if ($status <= 0) {
       $self->error("EOF Reached with no Comment end.") if $self->{inBlock};
       return $status;
    }
    if ($self->{inBlock}) {
        if (/^\s*#\/\*\s*/ ) {
            $self->warn("Nested COMMENT START", $self->{line_no})
        } elsif (/^\s*#\*\/\s*/) {
            $self->{inBlock} = 0;
        }
        s/^/#/;
    } elsif ( /^\s*#\/\*\s*/ ) {
        $self->{inBlock} = 1;
        $self->{last_begin} = $self->{line_no};
    } elsif ( /^\s*#\*\/\s*/ ) {
        $self->error("Comment Start has no Comment End", $self->{line_no});
    }
    return $status;
}
1;

__END__

=head1 NAME

Comment::Block - Adds block style comments to Perl

=head1 SYNOPSIS

  use Comment::Block;
  #/*
    A block
    of commented
    things
  #*/
  ..normal execution..

=head1 DESCRIPTION

Provide a better way of doing block comments instead of using POD or
always false if blocks.

=head1 SYNTAX HIGHLIGHTING

You can add the below to ~/.vim/after/syntax/perl.vim to add Syntax Highlighting
for the comment blocks. This is only for VIM currently but if someone sends me more
for other editors I will add them here.

  syn region perlCommentBlock     start="#/\*" end="#\*/" contains=perlTodo
  if version < 508
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif
  HiLink perlCommentBlock Comment

=head1 VERSION

This documentation describes version 0.01.

=head1 AUTHOR

 Madison Koenig <pedlar AT cpan DOT org>

=head1 COPYRIGHT

Copyright (c) 2013 Madison Koenig
All rights reserved.  This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
