package Async::Template::Document;

#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 23.05.2013

#! This source file have functions `process_enter()` and `process_leave()`.
#! Code parts of them taken from function `process()` of template toolkit
#! library and substantially enhanced, the asynchronous processing
#! is introduced by Serguei Okladnikov <oklaspec@gmail.com>
#! Author of that original code parts is Andy Wardley <abw@wardley.org>


use strict;
use warnings;
use base 'Template::Document';
use Template::Constants;


#------------------------------------------------------------------------
# process($context)
#
# Process the document in a particular context.  Checks for recursion,
# registers the document with the context via visit(), processes itself,
# and then unwinds with a large gin and tonic.
#------------------------------------------------------------------------

sub process_enter {
    my ($self, $context) = @_;
    my $defblocks = $self->{ _DEFBLOCKS };

    # check we're not already visiting this template
    return $context->throw(Template::Constants::ERROR_FILE, 
                           "recursion into '$self->{ name }'")
        if $self->{ _HOT } && ! $context->{ RECURSION };   ## RETURN ##

    $context->visit($self, $defblocks);

    $self->{ _HOT } = 1;
    eval {
        my $block = $self->{ _BLOCK };
        &$block($context);
    };
}

sub process_leave {
    my ($self, $context) = @_;

    $self->{ _HOT } = 0;

    $context->leave();

    die $context->catch($@)
        if $@;
        
}


1;
